import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../services/api_service.dart';
import '../models/maquina.dart';
import '../models/checklist_filtro.dart';
import 'barcode_scanner_screen.dart';

class FiltrosChecklistScreen extends StatefulWidget {
  final String tecnico;

  const FiltrosChecklistScreen({
    super.key,
    required this.tecnico,
  });

  @override
  State<FiltrosChecklistScreen> createState() => _FiltrosChecklistScreenState();
}

class _FiltrosChecklistScreenState extends State<FiltrosChecklistScreen> {
  // CONTROLLERS
  final _codigoController      = TextEditingController(); // código de barras / FUEL
  final _tempEntradaController = TextEditingController();
  final _tempSaidaController   = TextEditingController();
  final _obsDrenoController    = TextEditingController();
  final _obsGeraisController   = TextEditingController();

  final Map<String, TextEditingController> _obsControllers = {
    'desligado'   : TextEditingController(),
    'lavado'      : TextEditingController(),
    'escova'      : TextEditingController(),
    'secagem'     : TextEditingController(),
    'integridade' : TextEditingController(),
    'limpezaExt'  : TextEditingController(),
    'recolocado'  : TextEditingController(),
    'dry'         : TextEditingController(),
    'ambiente'    : TextEditingController(),
  };

  // ESTADO
  Maquina? _maquina;
  bool _carregandoMaquina = false;
  bool _enviando          = false;

  String? _coordenadasGps;
  LocationPermission? _gpsPermissao;

  String? _imagePathSuja;
  String? _imagePathLimpa;

  bool? _chkDesligado;
  bool? _chkLavado;
  bool? _chkEscova;
  bool? _chkSecagem;
  bool? _chkIntegridade;
  bool? _chkLimpezaExt;
  bool? _chkRecolocado;
  bool? _chkDry;
  bool? _chkAmbiente;
  bool? _chkDreno;

  // EPIs: só ícone, sem label
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

  Future<void> _solicitarPermissaoCamera() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tempEntradaController.dispose();
    _tempSaidaController.dispose();
    _obsDrenoController.dispose();
    _obsGeraisController.dispose();
    for (final c in _obsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────── PERMISSÕES / GPS ─────────────────────

  Future<void> _obterLocalizacao() async {
    try {
      _gpsPermissao = await Geolocator.checkPermission();

      if (_gpsPermissao == LocationPermission.denied) {
        _gpsPermissao = await Geolocator.requestPermission();
      }

      if (_gpsPermissao == LocationPermission.deniedForever ||
          _gpsPermissao == LocationPermission.denied) {
        setState(() {
          _coordenadasGps = 'Permissão negada';
        });
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
      debugPrint('[GPS] Erro: $e');
    }
  }

  Future<bool> _garantirPermissaoCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final novoStatus = await Permission.camera.request();
    if (novoStatus.isGranted) return true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissão de câmera'),
        content: const Text(
          'Para tirar fotos, é preciso permitir o acesso à câmera nas configurações do aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
    return false;
  }

  // ───────────────────── BUSCA MÁQUINA ─────────────────────

  Future<void> _buscarMaquina() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _snack('Leia o código de barras ou informe o FUEL.', erro: true);
      return;
    }

    setState(() {
      _carregandoMaquina = true;
      _maquina           = null;
    });

    // Por enquanto usamos o código como FUEL (pode mudar no futuro)
    final m = await DatabaseService.buscarPorFuel(codigo);

    setState(() {
      _carregandoMaquina = false;
      _maquina           = m;
    });

    if (m == null) {
      _snack('Nenhuma máquina encontrada para o código/FUEL $codigo.', erro: true);
      return;
    }

    // Verifica localmente (fila offline) e no servidor
    final localLimpa  = await DatabaseService.pendenteMesAtual(m.fuel, 'FILTRO');
    final servidor    = await ApiService.verificarLimpezaMes(m.fuel, 'FILTRO');
    final jaLimpa     = localLimpa || servidor['jaLimpa'] == true;
    final autorizado  = servidor['autorizado'] == true;

    if (!mounted) return;
    if (jaLimpa && !autorizado) {
      setState(() => _maquina = null);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Máquina já limpa', style: TextStyle(color: Colors.white)),
          content: Text(
            'O filtro FUEL ${m.fuel} (${m.localizacao}) já foi limpo este mês.\n\nPara realizar nova limpeza solicite autorização ao administrador.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1d4ed8)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _abrirScanner() async {
    // Abre a tela de scanner e espera o código
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (code != null && code.trim().isNotEmpty) {
      setState(() {
        _codigoController.text = code.trim();
      });
      await _buscarMaquina();
    }
  }

  // ───────────────────── FOTOS ─────────────────────

  Future<void> _tirarFoto({required bool suja}) async {
    final ok = await _garantirPermissaoCamera();
    if (!ok) return;

    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image == null) return;

    setState(() {
      if (suja) {
        _imagePathSuja = image.path;
      } else {
        _imagePathLimpa = image.path;
      }
    });

    _snack('Foto ${suja ? "inicial" : "final"} registrada.');
  }

  // ───────────────────── STATUS / VALIDAÇÃO ─────────────────────

  String _calcularStatusGeral() {
    if (_chkDesligado == false ||
        _chkIntegridade == false ||
        _chkRecolocado == false) {
      return 'CRITICO';
    }
    if (_chkLavado == false ||
        _chkEscova == false ||
        _chkSecagem == false ||
        _chkLimpezaExt == false ||
        _chkDry == false ||
        _chkAmbiente == false ||
        _chkDreno == false) {
      return 'ATENCAO';
    }
    return 'OK';
  }

  bool _validar() {
    if (_maquina == null) {
      _snack('Busque a máquina pelo código de barras / FUEL antes de continuar.', erro: true);
      return false;
    }
    if (_imagePathSuja == null) {
      _snack('Tire a foto inicial da unidade antes da limpeza.', erro: true);
      return false;
    }
    if (_imagePathLimpa == null) {
      _snack('Tire a foto do filtro limpo.', erro: true);
      return false;
    }

    final checks = [
      _chkDesligado,
      _chkLavado,
      _chkEscova,
      _chkSecagem,
      _chkIntegridade,
      _chkLimpezaExt,
      _chkRecolocado,
      _chkDry,
      _chkAmbiente,
      _chkDreno,
    ];

    if (checks.any((v) => v == null)) {
      _snack('Responda todas as perguntas de Sim/Não.', erro: true);
      return false;
    }

    if (_tempEntradaController.text.isEmpty ||
        _tempSaidaController.text.isEmpty) {
      _snack('Informe as temperaturas de entrada e insuflamento.', erro: true);
      return false;
    }

    bool precisaObs(bool? v, TextEditingController c) =>
        v == false && c.text.trim().isEmpty;

    if (precisaObs(_chkDesligado, _obsControllers['desligado']!)) {
      _snack('Explique o motivo do "Não" no desligamento.', erro: true);
      return false;
    }
    if (precisaObs(_chkLavado, _obsControllers['lavado']!)) {
      _snack('Explique o motivo do filtro NÃO lavado.', erro: true);
      return false;
    }
    if (precisaObs(_chkEscova, _obsControllers['escova']!)) {
      _snack('Explique o motivo de NÃO usar escova adequada.', erro: true);
      return false;
    }
    if (precisaObs(_chkSecagem, _obsControllers['secagem']!)) {
      _snack('Explique a forma de secagem do filtro.', erro: true);
      return false;
    }
    if (precisaObs(_chkIntegridade, _obsControllers['integridade']!)) {
      _snack('Descreva o dano na malha do filtro.', erro: true);
      return false;
    }
    if (precisaObs(_chkLimpezaExt, _obsControllers['limpezaExt']!)) {
      _snack('Explique por que a limpeza externa não foi feita.', erro: true);
      return false;
    }
    if (precisaObs(_chkRecolocado, _obsControllers['recolocado']!)) {
      _snack('Explique por que o filtro não foi recolocado corretamente.', erro: true);
      return false;
    }
    if (precisaObs(_chkDry, _obsControllers['dry']!)) {
      _snack('Explique por que a função DRY não foi usada.', erro: true);
      return false;
    }
    if (precisaObs(_chkAmbiente, _obsControllers['ambiente']!)) {
      _snack('Explique por que o ambiente não estava desocupado/protegido.', erro: true);
      return false;
    }
    if (_chkDreno == false && _obsDrenoController.text.trim().isEmpty) {
      _snack('Explique o problema no dreno.', erro: true);
      return false;
    }

    return true;
  }

  // ───────────────────── ENVIO ─────────────────────

  Future<void> _enviar() async {
    if (!_validar()) return;

    setState(() => _enviando = true);

    final statusGeral = _calcularStatusGeral();
    final now         = DateTime.now();

    final checklist = ChecklistFiltro(
      dataInicio      : now,
      dataFinal       : now,
      tecnico         : widget.tecnico,
      fuel            : _maquina!.fuel,
      localizacao     : _maquina!.localizacao,
      coordenadasGps  : _coordenadasGps ?? '',
      linkFotoSuja    : null,
      chkDesligado    : _chkDesligado!,
      obsDesligado    : _obsControllers['desligado']!.text.trim().isEmpty    ? null : _obsControllers['desligado']!.text.trim(),
      chkLavado       : _chkLavado!,
      obsLavado       : _obsControllers['lavado']!.text.trim().isEmpty       ? null : _obsControllers['lavado']!.text.trim(),
      chkEscova       : _chkEscova!,
      obsEscova       : _obsControllers['escova']!.text.trim().isEmpty       ? null : _obsControllers['escova']!.text.trim(),
      chkSecagem      : _chkSecagem!,
      obsSecagem      : _obsControllers['secagem']!.text.trim().isEmpty      ? null : _obsControllers['secagem']!.text.trim(),
      chkIntegridade  : _chkIntegridade!,
      obsIntegridade  : _obsControllers['integridade']!.text.trim().isEmpty  ? null : _obsControllers['integridade']!.text.trim(),
      chkLimpezaExt   : _chkLimpezaExt!,
      obsLimpezaExt   : _obsControllers['limpezaExt']!.text.trim().isEmpty   ? null : _obsControllers['limpezaExt']!.text.trim(),
      chkRecolocado   : _chkRecolocado!,
      obsRecolocado   : _obsControllers['recolocado']!.text.trim().isEmpty   ? null : _obsControllers['recolocado']!.text.trim(),
      linkFotoLimpa   : null,
      chkDry          : _chkDry!,
      obsDry          : _obsControllers['dry']!.text.trim().isEmpty          ? null : _obsControllers['dry']!.text.trim(),
      chkAmbiente     : _chkAmbiente!,
      obsAmbiente     : _obsControllers['ambiente']!.text.trim().isEmpty     ? null : _obsControllers['ambiente']!.text.trim(),
      chkDreno        : _chkDreno!,
      obsDreno        : _obsDrenoController.text.trim().isEmpty              ? null : _obsDrenoController.text.trim(),
      tempEntrada     : double.tryParse(_tempEntradaController.text),
      tempInsuflamento: double.tryParse(_tempSaidaController.text),
      statusGeral     : statusGeral,
      modelo          : _maquina!.modelo,
      marca           : _maquina!.marca,
      serie           : _maquina!.serie,
    );

    // Salva sempre na fila offline — fecha a tela imediatamente
    await OfflineQueueService.salvarFiltroOffline(
      checklist    : checklist,
      fotoSujaPath : _imagePathSuja!,
      fotoLimpaPath: _imagePathLimpa!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ───────────────────── UI ─────────────────────

  void _snack(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            erro ? Colors.redAccent : (sucesso ? Colors.green : Colors.blueGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        title: const Text(
          'CHECKLIST.FILTROS',
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
                        // Botão scanner
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
                        // Botão buscar (manual)
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
                          child: IconButton(
                            onPressed: _carregandoMaquina ? null : _buscarMaquina,
                            icon: _carregandoMaquina
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            color: Colors.black,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFCCFF00),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
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
                        Expanded(
                          child: _infoRow(
                            'GPS',
                            _coordenadasGps ?? 'Obtendo…',
                          ),
                        ),
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

              // ── EPIs — só ícones, linha única ──
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
                      onTap: () {
                        setState(() {
                          if (selecionado) {
                            _episSelecionados.remove(label);
                          } else {
                            _episSelecionados.add(label);
                          }
                        });
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? const Color(0xFFCCFF00)
                              : Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── FOTO INICIAL ──
              _buildCard(
                title: 'Foto Inicial',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Foto da unidade evaporadora antes da intervenção'),
                    const SizedBox(height: 6),
                    _fotoWidget(_imagePathSuja, () => _tirarFoto(suja: true)),
                  ],
                ),
              ),

              // ── PROCEDIMENTOS ──
              _buildCard(
                title: 'Procedimentos de Limpeza',
                child: Column(
                  children: [
                    _yesNo(
                      'Desligamento: equipamento e disjuntor desligados antes do início?',
                      _chkDesligado,
                      (v) => setState(() => _chkDesligado = v),
                      _obsControllers['desligado']!,
                    ),
                    _yesNo(
                      'Lavagem do filtro com água corrente e sabão neutro?',
                      _chkLavado,
                      (v) => setState(() => _chkLavado = v),
                      _obsControllers['lavado']!,
                    ),
                    _yesNo(
                      'Utilizou escova macia (sem danificar a malha)?',
                      _chkEscova,
                      (v) => setState(() => _chkEscova = v),
                      _obsControllers['escova']!,
                    ),
                    _yesNo(
                      'Secagem natural (sem álcool ou calor)?',
                      _chkSecagem,
                      (v) => setState(() => _chkSecagem = v),
                      _obsControllers['secagem']!,
                    ),
                    _yesNo(
                      'Malha do filtro íntegra (sem furos/rasgos)?',
                      _chkIntegridade,
                      (v) => setState(() => _chkIntegridade = v),
                      _obsControllers['integridade']!,
                    ),
                    _yesNo(
                      'Limpeza da face externa e grelhas com pano úmido?',
                      _chkLimpezaExt,
                      (v) => setState(() => _chkLimpezaExt = v),
                      _obsControllers['limpezaExt']!,
                    ),
                    _yesNo(
                      'Após secar, filtro recolocado corretamente?',
                      _chkRecolocado,
                      (v) => setState(() => _chkRecolocado = v),
                      _obsControllers['recolocado']!,
                    ),
                    _yesNo(
                      'Função DRY (se existente) acionada por 10 min após limpeza?',
                      _chkDry,
                      (v) => setState(() => _chkDry = v),
                      _obsControllers['dry']!,
                    ),
                    _yesNo(
                      'Ambiente desocupado ou com proteção adequada?',
                      _chkAmbiente,
                      (v) => setState(() => _chkAmbiente = v),
                      _obsControllers['ambiente']!,
                    ),
                    _yesNo(
                      'Dreno desobstruído?',
                      _chkDreno,
                      (v) => setState(() => _chkDreno = v),
                      _obsDrenoController,
                    ),
                  ],
                ),
              ),

              // ── FOTO FINAL ──
              _buildCard(
                title: 'Foto Final',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Foto Maquina Limpa'),
                    const SizedBox(height: 6),
                    _fotoWidget(_imagePathLimpa, () => _tirarFoto(suja: false)),
                  ],
                ),
              ),

              // ── TEMPERATURAS ──
              _buildCard(
                title: 'Medições de Temperatura',
                child: Column(
                  children: [
                    _label('Temperatura de entrada do ar (°C)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tempEntradaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 26.5'),
                    ),
                    const SizedBox(height: 12),
                    _label('Temperatura de insuflamento (°C)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tempSaidaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 18.2'),
                    ),
                  ],
                ),
              ),

              // ── OBSERVAÇÕES GERAIS ──
              _buildCard(
                title: 'Observações gerais',
                child: TextField(
                  controller: _obsGeraisController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration(
                    'Algo relevante que não entrou nas perguntas acima',
                  ),
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
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'FINALIZAR CHECKLIST',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
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

  // ───────────────────── WIDGETS AUXILIARES ─────────────────────

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
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
              image: DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: Text(path == null ? 'CAPTURAR IMAGEM' : 'REFAZER FOTO', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
    TextEditingController obsController,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
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
                    child: Center(
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
                    child: Center(
                      child: Text('NÃO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (valor == false) ...[
            const SizedBox(height: 8),
            TextField(
              controller: obsController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration('Explique o motivo do "Não"'),
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
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
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
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 2)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ───────────────────── CARD DA MÁQUINA ─────────────────────

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
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge FUEL + ícone ar condicionado
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Text(
                  'FUEL: ${maquina.fuel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.ac_unit,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Linha verde "Máquina encontrada"
          Row(
            children: const [
              Icon(Icons.check_box, color: Colors.black, size: 16),
              SizedBox(width: 6),
              Text(
                'MÁQUINA ENCONTRADA',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Modelo em destaque
          Text(
            maquina.modelo,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          // Marca + capacidade
          Row(
            children: [
              const Icon(Icons.business, size: 15, color: Colors.black45),
              const SizedBox(width: 5),
              Text(
                maquina.marca,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.bolt, size: 15, color: Colors.black45),
              const SizedBox(width: 5),
              Text(
                maquina.capacidade,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Localização
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Colors.black45),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  maquina.localizacao,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Série
          Row(
            children: [
              const Icon(Icons.qr_code, size: 15, color: Colors.black45),
              const SizedBox(width: 5),
              Text(
                'Série: ${maquina.serie}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}