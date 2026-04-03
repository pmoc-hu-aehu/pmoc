import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/checklist_pressao.dart';
import '../services/offline_queue_service.dart';
import 'assinatura_screen.dart';

// ─── Cores do tema ────────────────────────────────────────────────────────────
const _kGreen  = Color(0xFF22c55e);
const _kRed    = Color(0xFFef4444);
const _kOrange = Color(0xFFf97316);
const _kAppBar = Color(0xFFfacc15);

class PressaoChecklistScreen extends StatefulWidget {
  final String tecnico;

  const PressaoChecklistScreen({super.key, required this.tecnico});

  @override
  State<PressaoChecklistScreen> createState() => _PressaoChecklistScreenState();
}

class _PressaoChecklistScreenState extends State<PressaoChecklistScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  final _localCtrl      = TextEditingController();
  final _codSalaCtrl    = TextEditingController();
  final _zonaCtrl       = TextEditingController();
  final _pressaoCtrl    = TextEditingController();
  final _obsVedacaoCtrl = TextEditingController(); // justificativa se sem foto vedação
  final _obsCtrl        = TextEditingController(); // observações técnicas
  final _nomeChefCtrl   = TextEditingController();
  final _chapaCtrl      = TextEditingController();

  // ── Estado ───────────────────────────────────────────────────────────────────
  String  _tipoInspecao = 'Rotina';
  String  _tipoSala     = 'Sala Negativa';
  String  _filtroHepa   = 'Sem Acesso';
  String  _statusSala   = 'Segura para uso';

  bool? _chkConformidade;
  bool? _chkVedacao;
  bool? _chkMola;

  String? _fotoManometroPath;
  String? _fotoVedacaoPath;

  Uint8List? _assinaturaByte;

  String?            _coordenadasGps;
  LocationPermission? _gpsPermissao;
  bool               _enviando = false;

  // ── Início ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
    _solicitarPermissaoCamera();
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _codSalaCtrl.dispose();
    _zonaCtrl.dispose();
    _pressaoCtrl.dispose();
    _obsVedacaoCtrl.dispose();
    _obsCtrl.dispose();
    _nomeChefCtrl.dispose();
    _chapaCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────

  Future<void> _solicitarPermissaoCamera() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) await Permission.camera.request();
  }

  Future<void> _obterLocalizacao() async {
    try {
      _gpsPermissao = await Geolocator.checkPermission();
      if (_gpsPermissao == LocationPermission.denied) {
        _gpsPermissao = await Geolocator.requestPermission();
      }
      if (_gpsPermissao == LocationPermission.deniedForever ||
          _gpsPermissao == LocationPermission.denied) {
        setState(() => _coordenadasGps = 'Permissão negada');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _coordenadasGps =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() => _coordenadasGps = 'Erro ao obter GPS');
    }
  }

  // ── Câmera ───────────────────────────────────────────────────────────────────

  Future<bool> _garantirCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final novo = await Permission.camera.request();
    if (novo.isGranted) return true;
    if (!mounted) return false;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissão de câmera'),
        content: const Text(
          'Para tirar fotos, permita o acesso à câmera nas configurações.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            child: const Text('Configurações'),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _tirarFoto({required bool manometro}) async {
    if (!await _garantirCamera()) return;
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() {
      if (manometro) {
        _fotoManometroPath = file.path;
      } else {
        _fotoVedacaoPath = file.path;
      }
    });
    _snack('Foto ${manometro ? "do manômetro" : "da vedação"} registrada.');
  }

  // ── Assinatura ───────────────────────────────────────────────────────────────

  Future<void> _capturarAssinatura() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const AssinaturaScreen()),
    );
    if (bytes != null) setState(() => _assinaturaByte = bytes);
  }

  // ── Status automático ────────────────────────────────────────────────────────

  String _calcularStatusSala() {
    if (_chkConformidade == false ||
        _chkVedacao == false ||
        _chkMola == false ||
        _filtroHepa == 'Danificado') {
      return 'Risco de Contaminação';
    }
    if (_filtroHepa == 'Sujo') return 'Restrita';
    return 'Segura para uso';
  }

  String _calcularStatusGeral() {
    if (_chkConformidade == false || _chkVedacao == false || _chkMola == false) {
      return 'Rejeitado';
    }
    return 'Completo';
  }

  // ── Validação ────────────────────────────────────────────────────────────────

  bool _validar() {
    if (_localCtrl.text.trim().isEmpty) {
      _snack('Informe o local/descrição da sala.', erro: true); return false;
    }
    if (_codSalaCtrl.text.trim().isEmpty) {
      _snack('Informe o código da sala.', erro: true); return false;
    }
    if (_fotoManometroPath == null) {
      _snack('Tire a foto do manômetro (obrigatório).', erro: true); return false;
    }
    if (_fotoVedacaoPath == null && _obsVedacaoCtrl.text.trim().isEmpty) {
      _snack('Sem foto da vedação: justifique no campo de observação da vedação.', erro: true);
      return false;
    }
    if (_pressaoCtrl.text.trim().isEmpty) {
      _snack('Informe o valor da pressão em Pascal.', erro: true); return false;
    }
    if (_chkConformidade == null || _chkVedacao == null || _chkMola == null) {
      _snack('Responda todos os campos Sim/Não.', erro: true); return false;
    }
    if (_nomeChefCtrl.text.trim().isEmpty) {
      _snack('Informe o nome do chefe do setor.', erro: true); return false;
    }
    if (_chapaCtrl.text.trim().isEmpty) {
      _snack('Informe a chapa funcional.', erro: true); return false;
    }
    if (_assinaturaByte == null) {
      _snack('Capture a assinatura do chefe (obrigatório).', erro: true); return false;
    }
    return true;
  }

  // ── Envio ────────────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_validar()) return;
    setState(() => _enviando = true);

    final now         = DateTime.now();
    final statusSala  = _calcularStatusSala();
    final statusGeral = _calcularStatusGeral();
    final idChecklist = 'PRESSAO_${now.millisecondsSinceEpoch}';

    final checklist = ChecklistPressao(
      dataInicio          : now,
      dataFinal           : now,
      tecnico             : widget.tecnico,
      local               : _localCtrl.text.trim(),
      codSala             : _codSalaCtrl.text.trim(),
      zona                : _zonaCtrl.text.trim(),
      coordenadasGps      : _coordenadasGps ?? '',
      tipoInspecao        : _tipoInspecao,
      pressaoPascal       : double.tryParse(_pressaoCtrl.text.trim()),
      tipoSala            : _tipoSala,
      chkConformidade     : _chkConformidade!,
      chkVedacaoPorras    : _chkVedacao!,
      chkMolaPorta        : _chkMola!,
      chkFiltroHepa       : _filtroHepa,
      statusSala          : statusSala,
      observacoesTecnicas : _obsCtrl.text.trim(),
      obsFotoVedacao      : _obsVedacaoCtrl.text.trim().isEmpty ? null : _obsVedacaoCtrl.text.trim(),
      nomeChefSetor       : _nomeChefCtrl.text.trim(),
      chapaFuncional      : _chapaCtrl.text.trim(),
      statusGeral         : statusGeral,
      idChecklist         : idChecklist,
    );

    await OfflineQueueService.salvarPressaoOffline(
      checklist      : checklist,
      fotoManometroPath: _fotoManometroPath!,
      fotoVedacaoPath  : _fotoVedacaoPath,
      assinaturaByte   : _assinaturaByte!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Snack ─────────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          erro ? Colors.redAccent : (sucesso ? Colors.green : Colors.blueGrey),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _kAppBar,
        elevation: 4,
        title: const Text(
          'Checklist – Pressão (Áreas Críticas)',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── IDENTIFICAÇÃO DA SALA ─────────────────────────────────────
              _buildCard(
                title: 'Identificação da Sala',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Local / Descrição completa *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _localCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: Sala de Isolamento A – Bloco B, 3º andar'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Código da Sala *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _codSalaCtrl,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(color: Colors.black87),
                                decoration: _inputDeco('Ex.: SIA-B3'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Zona / Setor'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _zonaCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: Colors.black87),
                                decoration: _inputDeco('Ex.: UTI, Cirurgia'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _label('Tipo de Inspeção'),
                    const SizedBox(height: 6),
                    _dropdownRow(
                      value  : _tipoInspecao,
                      items  : const ['Rotina', 'Pós-Manutenção', 'Emergencial'],
                      onChange: (v) => setState(() => _tipoInspecao = v!),
                    ),
                  ],
                ),
              ),

              // ── TÉCNICO & GPS ─────────────────────────────────────────────
              _buildCard(
                title: 'Técnico & Localização',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Técnico', widget.tecnico),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _infoRow('GPS', _coordenadasGps ?? 'Obtendo…')),
                        IconButton(
                          onPressed: _obterLocalizacao,
                          icon: const Icon(Icons.my_location, size: 22),
                          color: const Color(0xFF0ea5e9),
                        ),
                      ],
                    ),
                    if (_gpsPermissao == LocationPermission.deniedForever ||
                        _gpsPermissao == LocationPermission.denied)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Abrir configurações de permissão'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── FOTO MANÔMETRO (obrigatória) ──────────────────────────────
              _buildCard(
                title: 'Foto do Manômetro *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Foto nítida do visor (ponteiro ou display digital)'),
                    const SizedBox(height: 6),
                    _fotoWidget(
                      path  : _fotoManometroPath,
                      onTap : () => _tirarFoto(manometro: true),
                      label : 'Tirar foto do manômetro',
                    ),
                  ],
                ),
              ),

              // ── MEDIÇÕES ─────────────────────────────────────────────────
              _buildCard(
                title: 'Medições de Pressão',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Pressão Diferencial (Pa) *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pressaoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: -8  ou  +12'),
                    ),
                    const SizedBox(height: 12),
                    _label('Tipo de Sala Projetada'),
                    const SizedBox(height: 6),
                    _dropdownRow(
                      value  : _tipoSala,
                      items  : const ['Sala Negativa', 'Sala Positiva'],
                      onChange: (v) => setState(() => _tipoSala = v!),
                    ),
                  ],
                ),
              ),

              // ── CHECKLISTS ────────────────────────────────────────────────
              _buildCard(
                title: 'Inspeção de Integridade',
                child: Column(
                  children: [
                    _yesNo(
                      'Conformidade: sala mantendo a pressão correta conforme projeto?',
                      _chkConformidade,
                      (v) => setState(() => _chkConformidade = v),
                    ),
                    _yesNo(
                      'Vedação de Portas: borrachas e batentes íntegros?',
                      _chkVedacao,
                      (v) => setState(() => _chkVedacao = v),
                    ),
                    _yesNo(
                      'Fechamento Automático: mola hidráulica fechando totalmente a sala?',
                      _chkMola,
                      (v) => setState(() => _chkMola = v),
                    ),
                    const SizedBox(height: 4),
                    _label('Filtros Absolutos (HEPA) – Inspeção visual'),
                    const SizedBox(height: 8),
                    _chipSelector(
                      opcoes     : const ['OK', 'Sujo', 'Danificado', 'Sem Acesso'],
                      selecionado: _filtroHepa,
                      cores      : const {
                        'OK'         : _kGreen,
                        'Sujo'       : _kOrange,
                        'Danificado' : _kRed,
                        'Sem Acesso' : Colors.grey,
                      },
                      onChange: (v) => setState(() => _filtroHepa = v),
                    ),
                  ],
                ),
              ),

              // ── FOTO VEDAÇÃO (opcional + justificativa) ───────────────────
              _buildCard(
                title: 'Foto da Vedação (opcional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fotoWidget(
                      path  : _fotoVedacaoPath,
                      onTap : () => _tirarFoto(manometro: false),
                      label : 'Tirar foto da vedação',
                    ),
                    if (_fotoVedacaoPath == null) ...[
                      const SizedBox(height: 10),
                      _label('Justificativa (obrigatória se sem foto)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _obsVedacaoCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco('Ex.: Sem acesso à vedação neste momento'),
                      ),
                    ],
                  ],
                ),
              ),

              // ── STATUS DA SALA (automático + manual override) ─────────────
              _buildCard(
                title: 'Status da Sala',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Status calculado automaticamente (pode ajustar):'),
                    const SizedBox(height: 8),
                    _chipSelector(
                      opcoes     : const [
                        'Segura para uso',
                        'Risco de Contaminação',
                        'Restrita',
                      ],
                      selecionado: _statusSala,
                      cores      : const {
                        'Segura para uso'        : _kGreen,
                        'Risco de Contaminação'  : _kRed,
                        'Restrita'               : _kOrange,
                      },
                      onChange: (v) => setState(() => _statusSala = v),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _statusSala = _calcularStatusSala());
                        _snack('Status recalculado: $_statusSala', sucesso: true);
                      },
                      icon : const Icon(Icons.refresh, size: 16),
                      label: const Text('Recalcular automático'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ea5e9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── OBSERVAÇÕES TÉCNICAS ──────────────────────────────────────
              _buildCard(
                title: 'Observações Técnicas',
                child: TextField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDeco(
                    'Ex.: "Necessário trocar mola da porta" ou "Filtro HEPA saturado"',
                  ),
                ),
              ),

              // ── VALIDAÇÃO DO SETOR ────────────────────────────────────────
              _buildCard(
                title: 'Validação do Setor (Obrigatório)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nome do Responsável *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nomeChefCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Nome completo'),
                    ),
                    const SizedBox(height: 12),
                    _label('Chapa Funcional *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _chapaCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: 12345'),
                    ),
                  ],
                ),
              ),

              // ── ASSINATURA ────────────────────────────────────────────────
              _buildCard(
                title: 'Assinatura Digital (OBRIGATÓRIA)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _assinaturaByte == null ? Colors.grey[400]! : _kGreen,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[50],
                      ),
                      child: _assinaturaByte != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_assinaturaByte!, fit: BoxFit.contain),
                            )
                          : Center(
                              child: Text(
                                'Toque em "Capturar" para assinar',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _assinaturaByte == null ? _capturarAssinatura : null,
                            icon : const Icon(Icons.draw_outlined),
                            label: const Text('Capturar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kGreen,
                              side: const BorderSide(color: _kGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _assinaturaByte != null
                                ? () => setState(() => _assinaturaByte = null)
                                : null,
                            icon : const Icon(Icons.refresh),
                            label: const Text('Refazer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kOrange,
                              side: const BorderSide(color: _kOrange),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_assinaturaByte != null) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: _kGreen, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Assinatura capturada',
                            style: TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── BOTÃO FINALIZAR ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'FINALIZAR CHECKLIST',
                          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.7),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────────

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _fotoWidget({String? path, required VoidCallback onTap, required String label}) {
    return Column(
      children: [
        if (path != null)
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onTap,
          icon : const Icon(Icons.camera_alt_outlined, size: 18),
          label: Text(path != null ? 'Retomar foto' : label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0ea5e9),
            side: const BorderSide(color: Color(0xFF0ea5e9)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _yesNo(String pergunta, bool? valor, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sim'),
                  selected: valor == true,
                  onSelected: (_) => onChanged(true),
                  selectedColor: _kGreen,
                  labelStyle: TextStyle(color: valor == true ? Colors.white : Colors.grey[700]),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(color: valor == true ? _kGreen : Colors.grey[400]!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Não'),
                  selected: valor == false,
                  onSelected: (_) => onChanged(false),
                  selectedColor: _kRed,
                  labelStyle: TextStyle(color: valor == false ? Colors.white : Colors.grey[700]),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(color: valor == false ? _kRed : Colors.grey[400]!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipSelector({
    required List<String> opcoes,
    required String selecionado,
    required Map<String, Color> cores,
    required ValueChanged<String> onChange,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: opcoes.map((op) {
        final sel = selecionado == op;
        final cor = cores[op] ?? Colors.grey;
        return ChoiceChip(
          label: Text(op),
          selected: sel,
          onSelected: (_) => onChange(op),
          selectedColor: cor,
          labelStyle: TextStyle(
            color: sel ? Colors.white : Colors.grey[700],
            fontSize: 13,
          ),
          backgroundColor: Colors.grey[100],
          side: BorderSide(color: sel ? cor : Colors.grey[300]!),
        );
      }).toList(),
    );
  }

  Widget _dropdownRow({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChange,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChange,
      decoration: _inputDeco(''),
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      dropdownColor: Colors.white,
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
