import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/checklist_pressao.dart';
import '../services/offline_queue_service.dart';

// ─── Cores do tema ────────────────────────────────────────────────────────────
const _kGreen  = Color(0xFF22c55e);
const _kRed    = Color(0xFFef4444);
const _kOrange = Color(0xFFf97316);

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
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        title: const Text(
          'CHECKLIST.PRESSÃO',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
                          color: Colors.black,
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
                          label: const Text('ABRIR CONFIGURAÇÕES'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 2),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
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
                      label: const Text('RECALCULAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

              const SizedBox(height: 8),

              // ── BOTÃO FINALIZAR ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCCFF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                        )
                      : const Text(
                          'FINALIZAR CHECKLIST',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 2)),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black,
            alignment: Alignment.centerLeft,
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _fotoWidget({String? path, required VoidCallback onTap, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (path != null)
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
            ),
          ),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: Text(path == null ? label.toUpperCase() : 'REFAZER FOTO',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE4E4E7),
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 2),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _yesNo(String pergunta, bool? valor, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta.toUpperCase(),
            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: valor == true ? const Color(0xFF22C55E) : Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Center(
                      child: Text('SIM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: valor == false ? const Color(0xFFEF4444) : Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Center(
                      child: Text('NÃO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
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
      runSpacing: 8,
      children: opcoes.map((op) {
        final sel = selecionado == op;
        final cor = cores[op] ?? Colors.grey;
        return GestureDetector(
          onTap: () => onChange(op),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? cor : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              op.toUpperCase(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
            ),
          ),
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
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
          '${label.toUpperCase()}: ',
          style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black, width: 2)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0055FF), width: 3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
