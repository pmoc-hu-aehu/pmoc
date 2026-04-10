import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../models/maquina.dart';
import '../models/checklist_exaustao.dart';
import 'barcode_scanner_screen.dart';

class ExaustaoChecklistScreen extends StatefulWidget {
  final String tecnico;

  const ExaustaoChecklistScreen({
    super.key,
    required this.tecnico,
  });

  @override
  State<ExaustaoChecklistScreen> createState() => _ExaustaoChecklistScreenState();
}

class _ExaustaoChecklistScreenState extends State<ExaustaoChecklistScreen> {
  // ── Controllers ──────────────────────────────────────────────────
  final _codigoController      = TextEditingController();
  final _tensaoController      = TextEditingController();
  final _correnteController    = TextEditingController();
  final _velocidadeController  = TextEditingController();
  final _obsGeraisController   = TextEditingController();
  final _nomeChefeController   = TextEditingController();
  final _chapaController       = TextEditingController();

  final Map<String, TextEditingController> _obsControllers = {
    'limpezaRotor'    : TextEditingController(),
    'correias'        : TextEditingController(),
    'lubrificacao'    : TextEditingController(),
    'vibracao'        : TextEditingController(),
    'sensAcionamento' : TextEditingController(),
    'filtrosTelas'    : TextEditingController(),
  };

  // ── Estado ────────────────────────────────────────────────────────
  Maquina? _maquina;
  bool _carregandoMaquina = false;
  bool _enviando          = false;

  String? _coordenadasGps;
  LocationPermission? _gpsPermissao;

  String _tipoEquip = 'Axial';
  static const _tiposEquip = ['Axial', 'Centrífugo', 'Inline', 'Coifas', 'Outro'];

  bool? _chkLimpezaRotor;
  bool? _chkCorreias;
  bool? _chkLubrificacao;
  bool? _chkVibracao;
  bool? _chkSensAcionamento;
  bool? _chkFiltrosTelas;

  String? _fotoInicioPath;
  String? _fotoServicopath;
  String? _fotoFinalPath;

  final List<Map<String, dynamic>> _epis = [
    {'label': 'Luvas',              'icon': Icons.back_hand_outlined},
    {'label': 'Óculos',             'icon': Icons.visibility_outlined},
    {'label': 'Máscara PFF2',       'icon': Icons.masks_outlined},
    {'label': 'Protetor auricular', 'icon': Icons.hearing_outlined},
  ];
  final Set<String> _episSelecionados = {};

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
    _solicitarPermissaoCamera();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tensaoController.dispose();
    _correnteController.dispose();
    _velocidadeController.dispose();
    _obsGeraisController.dispose();
    _nomeChefeController.dispose();
    _chapaController.dispose();
    for (final c in _obsControllers.values) { c.dispose(); }
    super.dispose();
  }

  // ── Permissões / GPS ─────────────────────────────────────────────

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

  Future<bool> _garantirPermissaoCamera() async {
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
            'Para tirar fotos, permita o acesso à câmera nas configurações do aparelho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
    return false;
  }

  // ── Busca Máquina ─────────────────────────────────────────────────

  Future<void> _buscarMaquina() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _snack('Leia o código de barras ou informe o FUEL.', erro: true);
      return;
    }
    setState(() { _carregandoMaquina = true; _maquina = null; });
    final m = await DatabaseService.buscarPorFuel(codigo);
    setState(() { _carregandoMaquina = false; _maquina = m; });
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

  // ── Fotos ─────────────────────────────────────────────────────────

  Future<void> _tirarFoto(String slot) async {
    final ok = await _garantirPermissaoCamera();
    if (!ok) return;
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null) return;
    setState(() {
      if (slot == 'inicio')   _fotoInicioPath  = image.path;
      if (slot == 'servico')  _fotoServicopath = image.path;
      if (slot == 'final')    _fotoFinalPath   = image.path;
    });
  }

  // ── Validação e Status ────────────────────────────────────────────

  String _calcularStatusGeral() {
    if (_chkSensAcionamento == false) return 'CRITICO';
    if (_chkLimpezaRotor == false ||
        _chkCorreias == false ||
        _chkLubrificacao == false ||
        _chkVibracao == true ||
        _chkFiltrosTelas == false) return 'ATENCAO';
    return 'OK';
  }

  String _calcularStatusEquip() {
    if (_chkSensAcionamento == false) return 'INOPERANTE';
    if (_chkVibracao == true) return 'PENDENTE';
    return 'OK';
  }

  bool _validar() {
    if (_maquina == null) {
      _snack('Busque a máquina pelo código de barras / FUEL.', erro: true);
      return false;
    }
    if (_fotoInicioPath == null) {
      _snack('Tire a foto inicial do equipamento.', erro: true);
      return false;
    }
    if (_fotoFinalPath == null) {
      _snack('Tire a foto final do equipamento.', erro: true);
      return false;
    }

    final checks = [
      _chkLimpezaRotor,
      _chkCorreias,
      _chkLubrificacao,
      _chkVibracao,
      _chkSensAcionamento,
      _chkFiltrosTelas,
    ];
    if (checks.any((v) => v == null)) {
      _snack('Responda todas as perguntas de Sim/Não.', erro: true);
      return false;
    }

    bool precisaObs(bool? v, TextEditingController c, {bool problemaQuandoSim = false}) {
      final temProblema = problemaQuandoSim ? v == true : v == false;
      return temProblema && c.text.trim().isEmpty;
    }

    if (precisaObs(_chkLimpezaRotor,    _obsControllers['limpezaRotor']!))    { _snack('Explique o motivo da limpeza do rotor "Não".', erro: true); return false; }
    if (precisaObs(_chkCorreias,         _obsControllers['correias']!))         { _snack('Explique o problema nas correias.', erro: true); return false; }
    if (precisaObs(_chkLubrificacao,    _obsControllers['lubrificacao']!))    { _snack('Explique o problema na lubrificação.', erro: true); return false; }
    if (precisaObs(_chkVibracao,         _obsControllers['vibracao']!, problemaQuandoSim: true)) { _snack('Descreva a vibração/ruído anormal.', erro: true); return false; }
    if (precisaObs(_chkSensAcionamento, _obsControllers['sensAcionamento']!)) { _snack('Explique o problema no sensor/acionamento.', erro: true); return false; }
    if (precisaObs(_chkFiltrosTelas,    _obsControllers['filtrosTelas']!))    { _snack('Explique o problema nos filtros/telas.', erro: true); return false; }

    if (_nomeChefeController.text.trim().isEmpty) {
      _snack('Informe o nome do chefe do setor.', erro: true);
      return false;
    }
    if (_chapaController.text.trim().isEmpty) {
      _snack('Informe a chapa funcional.', erro: true);
      return false;
    }
    return true;
  }

  // ── Envio ─────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_validar()) return;
    setState(() => _enviando = true);

    final now = DateTime.now().toUtc();

    final checklist = ChecklistExaustao(
      dataInicio          : now,
      dataFinal           : now,
      tecnico             : widget.tecnico,
      fuel                : _maquina!.fuel,
      localizacao         : _maquina!.localizacao,
      coordenadasGps      : _coordenadasGps ?? '',
      tipoEquip           : _tipoEquip,
      chkLimpezaRotor     : _chkLimpezaRotor!,
      obsLimpezaRotor     : _obsControllers['limpezaRotor']!.text.trim().isEmpty    ? null : _obsControllers['limpezaRotor']!.text.trim(),
      chkCorreias         : _chkCorreias!,
      obsCorreias         : _obsControllers['correias']!.text.trim().isEmpty         ? null : _obsControllers['correias']!.text.trim(),
      chkLubrificacao     : _chkLubrificacao!,
      obsLubrificacao     : _obsControllers['lubrificacao']!.text.trim().isEmpty    ? null : _obsControllers['lubrificacao']!.text.trim(),
      chkVibracao         : _chkVibracao!,
      obsVibracao         : _obsControllers['vibracao']!.text.trim().isEmpty         ? null : _obsControllers['vibracao']!.text.trim(),
      chkSensAcionamento  : _chkSensAcionamento!,
      obsSensAcionamento  : _obsControllers['sensAcionamento']!.text.trim().isEmpty ? null : _obsControllers['sensAcionamento']!.text.trim(),
      chkFiltrosTelas     : _chkFiltrosTelas!,
      obsFiltrosTelas     : _obsControllers['filtrosTelas']!.text.trim().isEmpty    ? null : _obsControllers['filtrosTelas']!.text.trim(),
      tensaoV             : double.tryParse(_tensaoController.text),
      correnteA           : double.tryParse(_correnteController.text),
      velocidadeArMs      : double.tryParse(_velocidadeController.text),
      statusEquip         : _calcularStatusEquip(),
      linkFotoInicio      : null,
      linkFotoServico     : null,
      linkFotoFinal       : null,
      observacoesTecnicas : _obsGeraisController.text.trim().isEmpty ? null : _obsGeraisController.text.trim(),
      nomeChefe           : _nomeChefeController.text.trim(),
      chapaFuncional      : _chapaController.text.trim(),
      linkAssinatura      : null,
      statusGeral         : _calcularStatusGeral(),
      modelo              : _maquina!.modelo,
      marca               : _maquina!.marca,
      serie               : _maquina!.serie,
    );

    await OfflineQueueService.salvarExaustaoOffline(
      checklist       : checklist,
      fotoInicioPath  : _fotoInicioPath!,
      fotoServicopath : _fotoServicopath,
      fotoFinalPath   : _fotoFinalPath!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Snackbar ──────────────────────────────────────────────────────

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.redAccent : Colors.blueGrey,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        title: const Text(
          'CHECKLIST.EXAUSTÃO',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── IDENTIFICAÇÃO DA MÁQUINA ──
              _buildCard(
                title: 'Identificação da Máquina',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Código de barras / FUEL'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codigoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: _inputDecoration('Aponte a câmera ou digite o FUEL'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 2), bottom: BorderSide(color: Colors.black, width: 2), right: BorderSide(color: Colors.black, width: 2))),
                          child: IconButton(
                            tooltip: 'Ler código de barras',
                            onPressed: _abrirScanner,
                            icon: const Icon(Icons.qr_code_scanner),
                            color: Colors.black,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFE4E4E7), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
                          child: IconButton(
                            onPressed: _carregandoMaquina ? null : _buscarMaquina,
                            icon: _carregandoMaquina
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                                : const Icon(Icons.search),
                            color: Colors.black,
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFCCFF00), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                          ),
                        ),
                      ],
                    ),
                    if (_maquina != null) ...[
                      const SizedBox(height: 16),
                      _MaquinaResumoCard(maquina: _maquina!),
                    ],
                  ],
                ),
              ),

              // ── TÉCNICO & LOCALIZAÇÃO ──
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
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => openAppSettings(),
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

              // ── EPIs ──
              _buildCard(
                title: 'EPIs Utilizados',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _epis.map((epi) {
                    final label       = epi['label'] as String;
                    final icon        = epi['icon'] as IconData;
                    final selecionado = _episSelecionados.contains(label);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selecionado) {
                          _episSelecionados.remove(label);
                        } else {
                          _episSelecionados.add(label);
                        }
                      }),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selecionado ? const Color(0xFFCCFF00) : Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Icon(icon, size: 32, color: Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── TIPO DE EQUIPAMENTO ──
              _buildCard(
                title: 'Tipo de Equipamento',
                child: DropdownButtonFormField<String>(
                  initialValue: _tipoEquip,
                  decoration: _inputDecoration('Selecione o tipo'),
                  dropdownColor: Colors.white,
                  items: _tiposEquip
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, style: const TextStyle(color: Colors.black87)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoEquip = v!),
                  style: const TextStyle(color: Colors.black87),
                ),
              ),

              // ── FOTO INICIAL ──
              _buildCard(
                title: 'Foto Inicial',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Equipamento antes da intervenção'),
                    const SizedBox(height: 6),
                    _fotoWidget(_fotoInicioPath, () => _tirarFoto('inicio')),
                  ],
                ),
              ),

              // ── VERIFICAÇÕES ──
              _buildCard(
                title: 'Verificações',
                child: Column(
                  children: [
                    _yesNo(
                      'Limpeza do rotor/hélice realizada?',
                      _chkLimpezaRotor,
                      (v) => setState(() => _chkLimpezaRotor = v),
                      _obsControllers['limpezaRotor']!,
                    ),
                    _yesNo(
                      'Correias em bom estado (sem desgaste ou folga)?',
                      _chkCorreias,
                      (v) => setState(() => _chkCorreias = v),
                      _obsControllers['correias']!,
                    ),
                    _yesNo(
                      'Lubrificação dos rolamentos realizada?',
                      _chkLubrificacao,
                      (v) => setState(() => _chkLubrificacao = v),
                      _obsControllers['lubrificacao']!,
                    ),
                    _yesNo(
                      'Vibração ou ruído anormal detectado?',
                      _chkVibracao,
                      (v) => setState(() => _chkVibracao = v),
                      _obsControllers['vibracao']!,
                      problemaQuandoSim: true,
                    ),
                    _yesNo(
                      'Sensor/acionamento funcionando corretamente?',
                      _chkSensAcionamento,
                      (v) => setState(() => _chkSensAcionamento = v),
                      _obsControllers['sensAcionamento']!,
                    ),
                    _yesNo(
                      'Filtros e telas limpos e sem obstrução?',
                      _chkFiltrosTelas,
                      (v) => setState(() => _chkFiltrosTelas = v),
                      _obsControllers['filtrosTelas']!,
                    ),
                  ],
                ),
              ),

              // ── FOTO DURANTE SERVIÇO ──
              _buildCard(
                title: 'Foto Durante o Serviço (opcional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Registro fotográfico do processo'),
                    const SizedBox(height: 6),
                    _fotoWidget(_fotoServicopath, () => _tirarFoto('servico')),
                  ],
                ),
              ),

              // ── FOTO FINAL ──
              _buildCard(
                title: 'Foto Final',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Equipamento após a intervenção'),
                    const SizedBox(height: 6),
                    _fotoWidget(_fotoFinalPath, () => _tirarFoto('final')),
                  ],
                ),
              ),

              // ── MEDIÇÕES ──
              _buildCard(
                title: 'Medições Elétricas e de Fluxo',
                child: Column(
                  children: [
                    _label('Tensão (V)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tensaoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 220'),
                    ),
                    const SizedBox(height: 12),
                    _label('Corrente (A)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _correnteController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 3.5'),
                    ),
                    const SizedBox(height: 12),
                    _label('Velocidade do ar (m/s)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _velocidadeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 4.2'),
                    ),
                  ],
                ),
              ),

              // ── OBSERVAÇÕES ──
              _buildCard(
                title: 'Observações Técnicas',
                child: TextField(
                  controller: _obsGeraisController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration('Informações relevantes não cobertas acima'),
                ),
              ),

              // ── RESPONSÁVEL ──
              _buildCard(
                title: 'Responsável pelo Setor',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nome do chefe do setor'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nomeChefeController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Nome completo'),
                    ),
                    const SizedBox(height: 12),
                    _label('Chapa funcional'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _chapaController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Número da chapa'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── BOTÃO FINALIZAR ──
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

  // ── Widgets Auxiliares ────────────────────────────────────────────

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

  Widget _fotoWidget(String? path, VoidCallback onTap) {
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
          label: Text(path == null ? 'CAPTURAR IMAGEM' : 'REFAZER FOTO',
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

  Widget _yesNo(
    String pergunta,
    bool? valor,
    ValueChanged<bool?> onChanged,
    TextEditingController obsController, {
    bool problemaQuandoSim = false,
  }) {
    final temProblema = problemaQuandoSim ? valor == true : valor == false;
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
                      color: valor == true
                          ? (problemaQuandoSim ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                          : Colors.white,
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
                      color: valor == false
                          ? (problemaQuandoSim ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                          : Colors.white,
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
          if (temProblema) ...[
            const SizedBox(height: 8),
            TextField(
              controller: obsController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration(
                  problemaQuandoSim ? 'Descreva a ocorrência' : 'Explique o motivo do "Não"'),
            ),
          ],
        ],
      ),
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

  InputDecoration _inputDecoration(String hint) {
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

// ── Card da Máquina ───────────────────────────────────────────────

class _MaquinaResumoCard extends StatelessWidget {
  final Maquina maquina;
  const _MaquinaResumoCard({required this.maquina});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.black,
                child: Text('FUEL: ${maquina.fuel}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const Spacer(),
              const Icon(Icons.air, color: Colors.black, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.check_box, color: Colors.black, size: 16),
            SizedBox(width: 6),
            Text('MÁQUINA ENCONTRADA', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10),
          Text(maquina.modelo, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.business, size: 15, color: Colors.black45),
            const SizedBox(width: 5),
            Text(maquina.marca, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 14),
            const Icon(Icons.bolt, size: 15, color: Colors.black45),
            const SizedBox(width: 5),
            Text(maquina.capacidade, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_outlined, size: 15, color: Colors.black45),
            const SizedBox(width: 5),
            Expanded(child: Text(maquina.localizacao, style: const TextStyle(color: Colors.black87, fontSize: 13))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.qr_code, size: 15, color: Colors.black45),
            const SizedBox(width: 5),
            Text('Série: ${maquina.serie}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
