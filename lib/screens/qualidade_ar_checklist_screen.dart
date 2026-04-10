import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/checklist_qualidade_ar.dart';
import '../services/offline_queue_service.dart';

const _kGreen  = Color(0xFF22c55e);
const _kOrange = Color(0xFFf97316);

class QualidadeArChecklistScreen extends StatefulWidget {
  final String tecnico;
  const QualidadeArChecklistScreen({super.key, required this.tecnico});

  @override
  State<QualidadeArChecklistScreen> createState() => _QualidadeArChecklistScreenState();
}

class _QualidadeArChecklistScreenState extends State<QualidadeArChecklistScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  final _codSalaCtrl     = TextEditingController();
  final _pontoColetaCtrl = TextEditingController();
  final _co2Ctrl         = TextEditingController();
  final _umidadeCtrl     = TextEditingController();
  final _tempCtrl        = TextEditingController();
  final _velArCtrl       = TextEditingController();
  final _idAmostraCtrl   = TextEditingController();
  final _obsCtrl         = TextEditingController();
  final _nomeChefCtrl    = TextEditingController();
  final _chapaCtrl       = TextEditingController();

  // ── Estado ───────────────────────────────────────────────────────────────────
  String _tipoColeta          = 'Semestral de Rotina';
  String _materialParticulado = 'Limpo';
  String _statusQualidade     = 'Dentro dos Padrões RE 09';
  DateTime? _dataProximaAnalise;

  String? _fotoColetaPath;

  String?             _coordenadasGps;
  LocationPermission? _gpsPermissao;
  bool                _enviando = false;

  // ── Início ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
    _solicitarPermissaoCamera();
    // Sugere data da próxima análise: 6 meses à frente
    _dataProximaAnalise = DateTime.now().add(const Duration(days: 183));
  }

  @override
  void dispose() {
    _codSalaCtrl.dispose();
    _pontoColetaCtrl.dispose();
    _co2Ctrl.dispose();
    _umidadeCtrl.dispose();
    _tempCtrl.dispose();
    _velArCtrl.dispose();
    _idAmostraCtrl.dispose();
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

  Future<void> _tirarFoto() async {
    if (!await _garantirCamera()) return;
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() => _fotoColetaPath = file.path);
    _snack('Foto da coleta registrada.');
  }

  // ── Assinatura ───────────────────────────────────────────────────────────────

  // ── Data próxima análise ─────────────────────────────────────────────────────

  Future<void> _selecionarDataProxima() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataProximaAnalise ?? DateTime.now().add(const Duration(days: 183)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dataProximaAnalise = picked);
  }

  String _formatarData(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  // ── Validação ────────────────────────────────────────────────────────────────

  bool _validar() {
    if (_pontoColetaCtrl.text.trim().isEmpty) {
      _snack('Informe o ponto de coleta.', erro: true); return false;
    }
    if (_codSalaCtrl.text.trim().isEmpty) {
      _snack('Informe o código da sala.', erro: true); return false;
    }
    if (_fotoColetaPath == null) {
      _snack('Tire a foto do local da coleta (obrigatório).', erro: true); return false;
    }
    if (_idAmostraCtrl.text.trim().isEmpty) {
      _snack('Informe a identificação da amostra microbiológica.', erro: true); return false;
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

    final now = DateTime.now();

    final checklist = ChecklistQualidadeAr(
      dataInicio            : now,
      dataFinal             : now,
      tecnico               : widget.tecnico,
      codSala               : _codSalaCtrl.text.trim(),
      pontoColeta           : _pontoColetaCtrl.text.trim(),
      coordenadasGps        : _coordenadasGps ?? '',
      tipoColeta            : _tipoColeta,
      co2Ppm                : double.tryParse(_co2Ctrl.text.trim()),
      umidadeRelativa       : double.tryParse(_umidadeCtrl.text.trim()),
      temperatura           : double.tryParse(_tempCtrl.text.trim()),
      velocidadeAr          : double.tryParse(_velArCtrl.text.trim()),
      materialParticulado   : _materialParticulado,
      idAmostraMicrobiologica: _idAmostraCtrl.text.trim(),
      dataProximaAnalise    : _dataProximaAnalise != null
          ? _formatarData(_dataProximaAnalise!)
          : null,
      statusQualidade       : _statusQualidade,
      observacoes           : _obsCtrl.text.trim(),
      nomeChefSetor         : _nomeChefCtrl.text.trim(),
      chapaFuncional        : _chapaCtrl.text.trim(),
    );

    await OfflineQueueService.salvarQualidadeArOffline(
      checklist     : checklist,
      fotoColetaPath: _fotoColetaPath!,
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
          'CHECKLIST.QUALIDADE DO AR',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── IDENTIFICAÇÃO ─────────────────────────────────────────
              _buildCard(
                title: 'Identificação do Local',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ponto de Coleta / Descrição *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pontoColetaCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: Sala de Espera – Bloco A, 1º andar'),
                    ),
                    const SizedBox(height: 12),
                    _label('Código da Sala *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _codSalaCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: UTI-01'),
                    ),
                    const SizedBox(height: 12),
                    _label('Tipo de Coleta'),
                    const SizedBox(height: 6),
                    _dropdownRow(
                      value   : _tipoColeta,
                      items   : const [
                        'Semestral de Rotina',
                        'Pós-Obras',
                        'Suspeita de Surto',
                      ],
                      onChange: (v) => setState(() => _tipoColeta = v!),
                    ),
                  ],
                ),
              ),

              // ── TÉCNICO & GPS ─────────────────────────────────────────
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

              // ── FOTO DA COLETA (obrigatória) ──────────────────────────
              _buildCard(
                title: 'Foto do Local da Coleta *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Foto do técnico realizando a amostragem ou do equipamento'),
                    const SizedBox(height: 6),
                    _fotoWidget(
                      path : _fotoColetaPath,
                      onTap: _tirarFoto,
                      label: 'Tirar foto da coleta',
                    ),
                  ],
                ),
              ),

              // ── MEDIÇÕES ─────────────────────────────────────────────
              _buildCard(
                title: 'Medições Ambientais',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _medicaoRow('CO₂ (ppm)', _co2Ctrl, 'Ex.: 800'),
                    const SizedBox(height: 12),
                    _medicaoRow('Umidade Relativa (%)', _umidadeCtrl, 'Ex.: 55'),
                    const SizedBox(height: 12),
                    _medicaoRow('Temperatura (°C)', _tempCtrl, 'Ex.: 23.5'),
                    const SizedBox(height: 12),
                    _medicaoRow('Velocidade do Ar (m/s)', _velArCtrl, 'Ex.: 0.3'),
                    const SizedBox(height: 12),
                    _label('Material Particulado (inspeção visual)'),
                    const SizedBox(height: 6),
                    _chipSelector(
                      opcoes     : const ['Limpo', 'Poeira em suspensão'],
                      selecionado: _materialParticulado,
                      cores      : const {
                        'Limpo'               : _kGreen,
                        'Poeira em suspensão' : _kOrange,
                      },
                      onChange: (v) => setState(() => _materialParticulado = v),
                    ),
                  ],
                ),
              ),

              // ── AMOSTRA MICROBIOLÓGICA ────────────────────────────────
              _buildCard(
                title: 'Amostra Microbiológica',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Identificação da Amostra (lacre/tubo) *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _idAmostraCtrl,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: LAB-2026-0042'),
                    ),
                    const SizedBox(height: 12),
                    _label('Data da Próxima Análise'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _selecionarDataProxima,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              _dataProximaAnalise != null
                                  ? _formatarData(_dataProximaAnalise!)
                                  : 'SELECIONAR DATA',
                              style: TextStyle(
                                color: _dataProximaAnalise != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── STATUS DE QUALIDADE ───────────────────────────────────
              _buildCard(
                title: 'Status de Conformidade (RE 09)',
                child: _chipSelector(
                  opcoes     : const [
                    'Dentro dos Padrões RE 09',
                    'Acima do Limite',
                  ],
                  selecionado: _statusQualidade,
                  cores      : const {
                    'Dentro dos Padrões RE 09': _kGreen,
                    'Acima do Limite'         : Color(0xFFef4444),
                  },
                  onChange: (v) => setState(() => _statusQualidade = v),
                ),
              ),

              // ── OBSERVAÇÕES ───────────────────────────────────────────
              _buildCard(
                title: 'Observações',
                child: TextField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDeco(
                    'Ex.: "Setor em reforma, muita poeira externa"',
                  ),
                ),
              ),

              // ── VALIDAÇÃO DO SETOR ────────────────────────────────────
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

              // ── BOTÃO FINALIZAR ───────────────────────────────────────
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

  Widget _medicaoRow(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDeco(hint),
        ),
      ],
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
