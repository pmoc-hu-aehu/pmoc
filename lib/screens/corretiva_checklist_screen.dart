import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../models/maquina.dart';
import '../models/checklist_corretiva.dart';
import 'barcode_scanner_screen.dart';

class CorretivaChecklistScreen extends StatefulWidget {
  final String tecnico;

  const CorretivaChecklistScreen({
    super.key,
    required this.tecnico,
  });

  @override
  State<CorretivaChecklistScreen> createState() =>
      _CorretivaChecklistScreenState();
}

class _CorretivaChecklistScreenState extends State<CorretivaChecklistScreen> {
  final _codigoController          = TextEditingController();
  final _descDefeitoController     = TextEditingController();
  final _causaController           = TextEditingController();
  final _servicoController         = TextEditingController();
  final _pecasController           = TextEditingController();
  final _nfController              = TextEditingController();
  final _metrosController          = TextEditingController();
  final _tensaoController          = TextEditingController();
  final _correnteController        = TextEditingController();
  final _pressaoController         = TextEditingController();
  final _tempController            = TextEditingController();
  final _motivoController          = TextEditingController();
  final _nomeChefController        = TextEditingController();
  final _chapaController           = TextEditingController();

  Maquina? _maquina;
  bool _carregandoMaquina = false;
  bool _enviando          = false;

  String? _coordenadasGps;

  String?    _imagePathInicio;
  String?    _imagePathFinal;

  bool? _chkIsolamentoOk;
  bool? _chkHigienePos;
  bool? _equipamentoOperacional;

  final DateTime _dataInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
    _solicitarPermissaoCamera();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descDefeitoController.dispose();
    _causaController.dispose();
    _servicoController.dispose();
    _pecasController.dispose();
    _nfController.dispose();
    _metrosController.dispose();
    _tensaoController.dispose();
    _correnteController.dispose();
    _pressaoController.dispose();
    _tempController.dispose();
    _motivoController.dispose();
    _nomeChefController.dispose();
    _chapaController.dispose();
    super.dispose();
  }

  Future<void> _solicitarPermissaoCamera() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) await Permission.camera.request();
  }

  Future<void> _obterLocalizacao() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) setState(() => _coordenadasGps = 'Permissão negada');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() => _coordenadasGps =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
      }
    } catch (_) {
      if (mounted) setState(() => _coordenadasGps = 'Erro ao obter GPS');
    }
  }

  Future<void> _buscarMaquina() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _snack('Leia o código de barras ou informe o FUEL.', erro: true);
      return;
    }
    setState(() {
      _carregandoMaquina = true;
      _maquina = null;
    });
    final m = await DatabaseService.buscarPorFuel(codigo);
    setState(() {
      _carregandoMaquina = false;
      _maquina = m;
    });
    if (m == null) {
      _snack('Nenhuma máquina encontrada para o FUEL $codigo.', erro: true);
    }
  }

  Future<void> _abrirScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.trim().isNotEmpty) {
      setState(() => _codigoController.text = code.trim());
      await _buscarMaquina();
    }
  }

  Future<void> _tirarFoto(String tipo) async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final novo = await Permission.camera.request();
      if (!novo.isGranted) return;
    }
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null) return;
    setState(() {
      if (tipo == 'inicio') {
        _imagePathInicio = image.path;
      } else {
        _imagePathFinal = image.path;
      }
    });
    _snack('Foto ${tipo == 'inicio' ? 'inicial' : 'final'} registrada.');
  }

  bool _validar() {
    if (_maquina == null) {
      _snack('Busque a máquina antes de continuar.', erro: true);
      return false;
    }
    if (_imagePathInicio == null || _imagePathFinal == null) {
      _snack('Tire as fotos inicial e final.', erro: true);
      return false;
    }
    if (_descDefeitoController.text.trim().isEmpty ||
        _causaController.text.trim().isEmpty ||
        _servicoController.text.trim().isEmpty) {
      _snack('Preencha defeito, causa e serviço realizado.', erro: true);
      return false;
    }
    if (_chkIsolamentoOk == null || _chkHigienePos == null ||
        _equipamentoOperacional == null) {
      _snack('Responda todas as perguntas Sim/Não.', erro: true);
      return false;
    }
    if (_chkIsolamentoOk == true &&
        _metrosController.text.trim().isEmpty) {
      _snack('Informe os metros de isolamento instalados.', erro: true);
      return false;
    }
    if (_tensaoController.text.isEmpty ||
        _correnteController.text.isEmpty ||
        _pressaoController.text.isEmpty ||
        _tempController.text.isEmpty) {
      _snack('Preencha todas as medições.', erro: true);
      return false;
    }
    if (_equipamentoOperacional == false &&
        _motivoController.text.trim().isEmpty) {
      _snack('Informe o motivo da inoperância.', erro: true);
      return false;
    }
    if (_nomeChefController.text.trim().isEmpty ||
        _chapaController.text.trim().isEmpty) {
      _snack('Preencha dados do chefe de setor.', erro: true);
      return false;
    }
    return true;
  }

  Future<void> _enviar() async {
    if (!_validar()) return;
    setState(() => _enviando = true);

    final checklist = ChecklistCorretiva(
      dataInicio             : _dataInicio,
      dataFinal              : DateTime.now(),
      tecnico                : widget.tecnico,
      fuel                   : _maquina!.fuel,
      localizacao            : _maquina!.localizacao,
      coordenadasGps         : _coordenadasGps ?? '',
      linkFotoInicio         : null,
      descDefeito            : _descDefeitoController.text.trim(),
      causaProvavel          : _causaController.text.trim(),
      servicoRealizado       : _servicoController.text.trim(),
      pecasTrocadas          : _pecasController.text.trim(),
      nfRequisicao           : _nfController.text.trim(),
      chkIsolamentoOk        : _chkIsolamentoOk!,
      metrosIsolamentoTrocados: _chkIsolamentoOk == true
          ? double.tryParse(_metrosController.text)
          : null,
      chkHigienePos          : _chkHigienePos!,
      tensaoV                : double.tryParse(_tensaoController.text),
      correnteA              : double.tryParse(_correnteController.text),
      pressaoPsi             : double.tryParse(_pressaoController.text),
      tempInsuflamento       : double.tryParse(_tempController.text),
      linkFotoFinal          : null,
      equipamentoOperacional : _equipamentoOperacional!,
      motivoInoperancia      : _equipamentoOperacional == false
          ? _motivoController.text.trim()
          : null,
      nomeChefe              : _nomeChefController.text.trim(),
      chapaFuncional         : _chapaController.text.trim(),
      linkAssinatura         : null,
      statusGeral            : 'CONCLUIDO',
      modelo                 : _maquina!.modelo,
      marca                  : _maquina!.marca,
      serie                  : _maquina!.serie,
    );

    try {
      await OfflineQueueService.salvarCorretivaOffline(
        checklist      : checklist,
        fotoInicioPath : _imagePathInicio!,
        fotoFinalPath  : _imagePathFinal!,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack('Erro ao salvar: $e', erro: true);
      return;
    }

    if (!mounted) return;
    setState(() => _enviando = false);
    _snack('Checklist salvo com sucesso!', sucesso: true);
    Navigator.pop(context);
  }

  void _snack(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          erro ? Colors.redAccent : (sucesso ? Colors.green : Colors.blueGrey),
    ));
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFf97316),
        elevation: 4,
        title: const Text(
          'Checklist — Corretiva',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Identificação da Máquina
              _card(
                title: 'Identificação da Máquina',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Código de barras / FUEL'),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _codigoController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDec('Aponte a câmera ou digite o FUEL'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Ler código de barras',
                        onPressed: _abrirScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        color: const Color(0xFFf97316),
                      ),
                      IconButton.filled(
                        onPressed: _carregandoMaquina ? null : _buscarMaquina,
                        icon: _carregandoMaquina
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.search),
                        style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFf97316)),
                      ),
                    ]),
                    if (_maquina != null) ...[
                      const SizedBox(height: 14),
                      _maquinaResumo(_maquina!),
                    ],
                  ],
                ),
              ),

              // GPS
              _card(
                title: 'Técnico & Localização',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Técnico', widget.tecnico),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: _infoRow('GPS', _coordenadasGps ?? 'Obtendo…')),
                      IconButton(
                        onPressed: _obterLocalizacao,
                        icon: const Icon(Icons.my_location, size: 22),
                        color: const Color(0xFFf97316),
                      ),
                    ]),
                  ],
                ),
              ),

              // Foto inicial
              _card(
                title: 'Foto Inicial (máquina com defeito)',
                child: _fotoWidget(_imagePathInicio, () => _tirarFoto('inicio')),
              ),

              // Descrição do problema
              _card(
                title: 'Descrição do Problema',
                child: Column(children: [
                  _textArea(_descDefeitoController, 'Relato do defeito encontrado ao chegar no local'),
                  const SizedBox(height: 10),
                  _label('Causa Provável'),
                  const SizedBox(height: 4),
                  _textArea(_causaController, 'Ex: Capacitor estourado, vazamento de gás…'),
                  const SizedBox(height: 10),
                  _label('Serviço Realizado'),
                  const SizedBox(height: 4),
                  _textArea(_servicoController, 'Ex: Substituição de compressor e carga de gás'),
                  const SizedBox(height: 10),
                  _label('Peças / Componentes Trocados'),
                  const SizedBox(height: 4),
                  _textArea(_pecasController, 'Liste as peças utilizadas'),
                  const SizedBox(height: 10),
                  _label('Solicitação de Serviço'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nfController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDec('Número da solicitação'),
                  ),
                ]),
              ),

              // Isolamento
              _card(
                title: 'Isolamento Térmico',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _yesNo('Houve substituição de isolamento?', _chkIsolamentoOk,
                      (v) => setState(() => _chkIsolamentoOk = v)),
                  if (_chkIsolamentoOk == true) ...[
                    const SizedBox(height: 8),
                    _label('Metros instalados'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _metrosController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDec('Metragem de isolamento'),
                    ),
                  ],
                ]),
              ),

              // Higiene
              _card(
                title: 'Higienização Pós-Conserto',
                child: _yesNo(
                  'Máquina e área higienizadas conforme CCIH?',
                  _chkHigienePos,
                  (v) => setState(() => _chkHigienePos = v),
                ),
              ),

              // Medições
              _card(
                title: 'Medições (após o reparo)',
                child: Column(children: [
                  _medicao('Tensão (V)', _tensaoController),
                  const SizedBox(height: 10),
                  _medicao('Corrente (A)', _correnteController),
                  const SizedBox(height: 10),
                  _medicao('Pressão (PSI)', _pressaoController),
                  const SizedBox(height: 10),
                  _medicao('Temp. Insuflamento (°C)', _tempController),
                ]),
              ),

              // Foto final
              _card(
                title: 'Foto Final (máquina operando)',
                child: _fotoWidget(_imagePathFinal, () => _tirarFoto('final')),
              ),

              // Status operacional
              _card(
                title: 'Status do Equipamento',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _yesNo('Equipamento operacional?', _equipamentoOperacional,
                      (v) => setState(() => _equipamentoOperacional = v)),
                  if (_equipamentoOperacional == false) ...[
                    const SizedBox(height: 8),
                    _label('Motivo da Inoperância'),
                    const SizedBox(height: 4),
                    _textArea(_motivoController, 'Descreva o motivo'),
                  ],
                ]),
              ),

              // Chefe de setor
              _card(
                title: 'Responsável / Chefe de Setor',
                child: Column(children: [
                  TextField(
                    controller: _nomeChefController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDec('Nome do responsável'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _chapaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDec('Número funcional (chapa)'),
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('FINALIZAR CHECKLIST',
                          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.7)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS HELPERS ─────────────────────────────────────────────────────


  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _fotoWidget(String? path, VoidCallback onTap) {
    return Column(children: [
      if (path != null)
        Container(
          height: 160, width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
          ),
        ),
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.camera_alt_outlined, size: 18),
        label: Text(path == null ? 'Tirar foto' : 'Refazer foto'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFf97316),
          side: const BorderSide(color: Color(0xFFf97316)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ]);
  }

  Widget _yesNo(String pergunta, bool? valor, ValueChanged<bool?> onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(pergunta, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Sim'),
            selected: valor == true,
            onSelected: (_) => onChange(true),
            selectedColor: const Color(0xFF22c55e),
            labelStyle: TextStyle(color: valor == true ? Colors.white : Colors.grey[700]),
            backgroundColor: Colors.grey[100],
            side: BorderSide(color: valor == true ? const Color(0xFF22c55e) : Colors.grey[400]!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Não'),
            selected: valor == false,
            onSelected: (_) => onChange(false),
            selectedColor: const Color(0xFFef4444),
            labelStyle: TextStyle(color: valor == false ? Colors.white : Colors.grey[700]),
            backgroundColor: Colors.grey[100],
            side: BorderSide(color: valor == false ? const Color(0xFFef4444) : Colors.grey[400]!),
          ),
        ),
      ]),
    ]);
  }

  Widget _medicao(String label, TextEditingController ctrl) {
    return Row(children: [
      Expanded(
        flex: 2,
        child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 3,
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.black87),
          decoration: _inputDec('0.0'),
        ),
      ),
    ]);
  }

  Widget _textArea(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.done,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      style: const TextStyle(color: Colors.black87),
      decoration: _inputDec(hint),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _infoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13))),
    ]);
  }

  Widget _maquinaResumo(Maquina m) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFf97316).withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFf97316).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoRow('FUEL', m.fuel),
        _infoRow('Local', m.localizacao),
        _infoRow('Modelo', m.modelo),
        _infoRow('Marca', m.marca),
      ]),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFf97316))),
      );
}

