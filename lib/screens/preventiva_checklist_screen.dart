import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'assinatura_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../services/checklist_preventiva_service.dart';
import '../models/maquina.dart';
import '../models/checklist_preventiva.dart';
import 'barcode_scanner_screen.dart';

class PreventivaChecklistScreen extends StatefulWidget {
  final String tecnico;

  const PreventivaChecklistScreen({
    super.key,
    required this.tecnico,
  });

  @override
  State<PreventivaChecklistScreen> createState() =>
      _PreventivaChecklistScreenState();
}

class _PreventivaChecklistScreenState extends State<PreventivaChecklistScreen> {
  final _codigoController = TextEditingController();
  final _tensaoVController = TextEditingController();
  final _correnteAController = TextEditingController();
  final _pressaoPsiController = TextEditingController();
  final _tempRetornoController = TextEditingController();
  final _tempInsuflamentoController = TextEditingController();
  final _metrosIsolamentoController = TextEditingController();
  final _observacoesTecnicasController = TextEditingController();
  final _nomeChefeSectorController = TextEditingController();
  final _chapaFuncionalController = TextEditingController();

  final Map<String, TextEditingController> _obsControllers = {
    'desmontagem': TextEditingController(),
    'lavagemQuimica': TextEditingController(),
    'drenoBandeja': TextEditingController(),
    'antibactericida': TextEditingController(),
    'ruidoVibracao': TextEditingController(),
    'vazamento': TextEditingController(),
    'eletrica': TextEditingController(),
    'isolamentoOk': TextEditingController(),
    'substituicaoIsolamento': TextEditingController(),
  };

  Maquina? _maquina;
  bool _carregandoMaquina = false;
  bool _enviando = false;

  String? _coordenadasGps;
  LocationPermission? _gpsPermissao;

  String? _imagePathInicio;
  String? _imagePathProcesso;
  String? _imagePathFinal;
  Uint8List? _assinaturaByte;

  bool? _chkDesmontagem;
  bool? _chkLavagemQuimica;
  bool? _chkDrenoBandeja;
  bool? _chkAntibactericida;
  bool? _chkRuidoVibracao;
  bool? _chkVazamento;
  bool? _chkEletrica;
  bool? _chkIsolamentoOk;
  bool? _chkSubstituicaoIsolamento;

  final List<Map<String, dynamic>> _epis = [
    {'label': 'Luvas', 'icon': Icons.back_hand_outlined},
    {'label': 'Óculos', 'icon': Icons.visibility_outlined},
    {'label': 'Máscara PFF2', 'icon': Icons.masks_outlined},
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
    _tensaoVController.dispose();
    _correnteAController.dispose();
    _pressaoPsiController.dispose();
    _tempRetornoController.dispose();
    _tempInsuflamentoController.dispose();
    _metrosIsolamentoController.dispose();
    _observacoesTecnicasController.dispose();
    _nomeChefeSectorController.dispose();
    _chapaFuncionalController.dispose();
    for (final c in _obsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

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

    if (!mounted) return false;
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
      _snack('Nenhuma máquina encontrada para o código/FUEL $codigo.',
          erro: true);
    }
  }

  Future<void> _abrirScanner() async {
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

  Future<void> _tirarFoto({required String tipo}) async {
    final ok = await _garantirPermissaoCamera();
    if (!ok) return;

    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image == null) return;

    setState(() {
      if (tipo == 'inicio') {
        _imagePathInicio = image.path;
      } else if (tipo == 'processo') {
        _imagePathProcesso = image.path;
      } else if (tipo == 'final') {
        _imagePathFinal = image.path;
      }
    });

    _snack('Foto de $tipo registrada.');
  }

  Future<void> _salvarAssinatura() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const AssinaturaScreen()),
    );
    if (bytes != null) setState(() => _assinaturaByte = bytes);
  }

  void _limparAssinatura() {
    setState(() {
      _assinaturaByte = null;
    });
  }

  String _calcularStatusGeral() {
    if (_chkVazamento == true ||
        _chkEletrica == false ||
        _chkIsolamentoOk == false) {
      return 'CRITICO';
    }

    if (_chkDesmontagem == false ||
        _chkLavagemQuimica == false ||
        _chkDrenoBandeja == false ||
        _chkAntibactericida == false ||
        _chkRuidoVibracao == true) {
      return 'ATENCAO';
    }

    return 'OK';
  }

  bool _validar() {
    if (_maquina == null) {
      _snack('Busque a máquina antes de continuar.', erro: true);
      return false;
    }

    if (_imagePathInicio == null || _imagePathProcesso == null || _imagePathFinal == null) {
      _snack('Tire as 3 fotos obrigatórias.', erro: true);
      return false;
    }

    final checks = [
      _chkDesmontagem,
      _chkLavagemQuimica,
      _chkDrenoBandeja,
      _chkAntibactericida,
      _chkRuidoVibracao,
      _chkVazamento,
      _chkEletrica,
      _chkIsolamentoOk,
      _chkSubstituicaoIsolamento,
    ];

    if (checks.any((v) => v == null)) {
      _snack('Responda todas as perguntas.', erro: true);
      return false;
    }

    bool precisaObs(bool? v, TextEditingController c) =>
        v == false && c.text.trim().isEmpty;

    if (precisaObs(_chkDesmontagem, _obsControllers['desmontagem']!)) {
      _snack('Explique a desmontagem.', erro: true);
      return false;
    }
    if (precisaObs(_chkLavagemQuimica, _obsControllers['lavagemQuimica']!)) {
      _snack('Explique a lavagem.', erro: true);
      return false;
    }
    if (precisaObs(_chkDrenoBandeja, _obsControllers['drenoBandeja']!)) {
      _snack('Explique o dreno.', erro: true);
      return false;
    }
    if (precisaObs(_chkAntibactericida, _obsControllers['antibactericida']!)) {
      _snack('Explique o antibactericida.', erro: true);
      return false;
    }
    if (_chkRuidoVibracao == true && _obsControllers['ruidoVibracao']!.text.trim().isEmpty) {
      _snack('Descreva o ruído.', erro: true);
      return false;
    }
    if (_chkVazamento == true && _obsControllers['vazamento']!.text.trim().isEmpty) {
      _snack('Descreva o vazamento.', erro: true);
      return false;
    }
    if (precisaObs(_chkEletrica, _obsControllers['eletrica']!)) {
      _snack('Explique o problema elétrico.', erro: true);
      return false;
    }
    if (precisaObs(_chkIsolamentoOk, _obsControllers['isolamentoOk']!)) {
      _snack('Descreva o isolamento.', erro: true);
      return false;
    }

    if (_chkSubstituicaoIsolamento == true &&
        _metrosIsolamentoController.text.trim().isEmpty) {
      _snack('Informe metragem de isolamento.', erro: true);
      return false;
    }

    if (_tensaoVController.text.isEmpty ||
        _correnteAController.text.isEmpty ||
        _pressaoPsiController.text.isEmpty ||
        _tempRetornoController.text.isEmpty ||
        _tempInsuflamentoController.text.isEmpty) {
      _snack('Preencha todas as medições.', erro: true);
      return false;
    }

    if (_nomeChefeSectorController.text.trim().isEmpty ||
        _chapaFuncionalController.text.trim().isEmpty) {
      _snack('Preencha dados do chefe.', erro: true);
      return false;
    }

    if (_assinaturaByte == null) {
      _snack('Assinatura obrigatória.', erro: true);
      return false;
    }

    return true;
  }

  Future<void> _enviar() async {
    if (!_validar()) return;

    setState(() => _enviando = true);

    final statusGeral = _calcularStatusGeral();
    final now = DateTime.now();

    final checklist = ChecklistPreventiva(
      dataInicio: now,
      dataFinal: now,
      tecnico: widget.tecnico,
      fuel: _maquina!.fuel,
      localizacao: _maquina!.localizacao,
      coordenadasGps: _coordenadasGps ?? '',
      linkFotoInicio: null,
      chkDesmontagem: _chkDesmontagem!,
      obsDesmontagem: _obsControllers['desmontagem']!.text.trim().isEmpty
          ? null
          : _obsControllers['desmontagem']!.text.trim(),
      chkLavagemQuimica: _chkLavagemQuimica!,
      obsLavagemQuimica: _obsControllers['lavagemQuimica']!.text.trim().isEmpty
          ? null
          : _obsControllers['lavagemQuimica']!.text.trim(),
      chkDrenoBandeja: _chkDrenoBandeja!,
      obsDrenoBandeja: _obsControllers['drenoBandeja']!.text.trim().isEmpty
          ? null
          : _obsControllers['drenoBandeja']!.text.trim(),
      chkAntibactericida: _chkAntibactericida!,
      obsAntibactericida: _obsControllers['antibactericida']!.text.trim().isEmpty
          ? null
          : _obsControllers['antibactericida']!.text.trim(),
      chkRuidoVibracao: _chkRuidoVibracao!,
      obsRuidoVibracao: _obsControllers['ruidoVibracao']!.text.trim().isEmpty
          ? null
          : _obsControllers['ruidoVibracao']!.text.trim(),
      chkVazamento: _chkVazamento!,
      obsVazamento: _obsControllers['vazamento']!.text.trim().isEmpty
          ? null
          : _obsControllers['vazamento']!.text.trim(),
      chkEletrica: _chkEletrica!,
      obsEletrica: _obsControllers['eletrica']!.text.trim().isEmpty
          ? null
          : _obsControllers['eletrica']!.text.trim(),
      chkIsolamentoOk: _chkIsolamentoOk!,
      obsIsolamentoOk: _obsControllers['isolamentoOk']!.text.trim().isEmpty
          ? null
          : _obsControllers['isolamentoOk']!.text.trim(),
      chkSubstituicaoIsolamento: _chkSubstituicaoIsolamento!,
      obsSubstituicaoIsolamento: null,
      metrosIsolamentoTrocados: _chkSubstituicaoIsolamento == true
          ? double.tryParse(_metrosIsolamentoController.text)
          : null,
      linkFotoProcesso: null,
      tensaoV: double.tryParse(_tensaoVController.text),
      correnteA: double.tryParse(_correnteAController.text),
      pressaoPsi: double.tryParse(_pressaoPsiController.text),
      tempRetorno: double.tryParse(_tempRetornoController.text),
      tempInsuflamento: double.tryParse(_tempInsuflamentoController.text),
      linkFotoFinal: null,
      observacoesTecnicas: _observacoesTecnicasController.text.trim().isEmpty
          ? null
          : _observacoesTecnicasController.text.trim(),
      nomeChefe: _nomeChefeSectorController.text.trim(),
      chapaFuncional: _chapaFuncionalController.text.trim(),
      linkAssinatura: null,
      statusGeral: statusGeral,
      modelo: _maquina!.modelo,
      marca: _maquina!.marca,
      serie: _maquina!.serie,
    );

    await OfflineQueueService.salvarPreventivaOffline(
      checklist: checklist,
      fotoInicioPath: _imagePathInicio!,
      fotoProcessoPath: _imagePathProcesso!,
      fotoFinalPath: _imagePathFinal!,
      assinaturaByte: _assinaturaByte!,
    );

    if (!mounted) return;
    setState(() => _enviando = false);
    _snack('Checklist salvo com sucesso!', sucesso: true);
    Navigator.pop(context);
  }

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        elevation: 4,
        title: const Text(
          'Checklist - Preventiva',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                            decoration: _inputDecoration(
                                'Aponte a câmera ou digite o FUEL'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Ler código de barras',
                          onPressed: _abrirScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          color: const Color(0xFF2563eb),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          onPressed:
                              _carregandoMaquina ? null : _buscarMaquina,
                          icon: _carregandoMaquina
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2563eb),
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
                          color: const Color(0xFF2563eb),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'EPIs Utilizados',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _epis.map((epi) {
                    final label = epi['label'] as String;
                    final icon = epi['icon'] as IconData;
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? const Color(0xFF2563eb).withOpacity(0.15)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selecionado
                                ? const Color(0xFF2563eb)
                                : Colors.grey[300]!,
                            width: selecionado ? 2.0 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 32,
                            color: selecionado
                                ? const Color(0xFF1e40af)
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildCard(
                title: 'Foto Inicial',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unidade antes de iniciar'),
                    const SizedBox(height: 6),
                    _fotoWidget(_imagePathInicio,
                        () => _tirarFoto(tipo: 'inicio')),
                  ],
                ),
              ),
              _buildCard(
                title: 'Procedimentos de Limpeza',
                child: Column(
                  children: [
                    _yesNo(
                      'Desmontagem realizada?',
                      _chkDesmontagem,
                      (v) => setState(() => _chkDesmontagem = v),
                      _obsControllers['desmontagem']!,
                    ),
                    _yesNo(
                      'Lavagem química realizada?',
                      _chkLavagemQuimica,
                      (v) => setState(() => _chkLavagemQuimica = v),
                      _obsControllers['lavagemQuimica']!,
                    ),
                    _yesNo(
                      'Dreno/bandeja desobstruído?',
                      _chkDrenoBandeja,
                      (v) => setState(() => _chkDrenoBandeja = v),
                      _obsControllers['drenoBandeja']!,
                    ),
                    _yesNo(
                      'Antibactericida aplicado?',
                      _chkAntibactericida,
                      (v) => setState(() => _chkAntibactericida = v),
                      _obsControllers['antibactericida']!,
                    ),
                    _yesNo(
                      'Ruído/vibração detectado?',
                      _chkRuidoVibracao,
                      (v) => setState(() => _chkRuidoVibracao = v),
                      _obsControllers['ruidoVibracao']!,
                      problemaQuandoSim: true,
                    ),
                    _yesNo(
                      'Vazamento detectado?',
                      _chkVazamento,
                      (v) => setState(() => _chkVazamento = v),
                      _obsControllers['vazamento']!,
                      problemaQuandoSim: true,
                    ),
                    _yesNo(
                      'Contatos elétricos OK?',
                      _chkEletrica,
                      (v) => setState(() => _chkEletrica = v),
                      _obsControllers['eletrica']!,
                    ),
                    _yesNo(
                      'Isolamento íntegro?',
                      _chkIsolamentoOk,
                      (v) => setState(() => _chkIsolamentoOk = v),
                      _obsControllers['isolamentoOk']!,
                    ),
                    _yesNo(
                      'Substituição de isolamento?',
                      _chkSubstituicaoIsolamento,
                      (v) => setState(() => _chkSubstituicaoIsolamento = v),
                      _obsControllers['substituicaoIsolamento']!,
                    ),
                  ],
                ),
              ),
              if (_chkSubstituicaoIsolamento == true)
                _buildCard(
                  title: 'Metragem de Isolamento',
                  child: TextField(
                    controller: _metrosIsolamentoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDecoration('Metros instalados'),
                  ),
                ),
              _buildCard(
                title: 'Foto do Processo',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Máquina em limpeza'),
                    const SizedBox(height: 6),
                    _fotoWidget(_imagePathProcesso,
                        () => _tirarFoto(tipo: 'processo')),
                  ],
                ),
              ),
              _buildCard(
                title: 'Medições',
                child: Column(
                  children: [
                    _label('Tensão (V)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tensaoVController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 220.5'),
                    ),
                    const SizedBox(height: 12),
                    _label('Corrente (A)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _correnteAController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 8.5'),
                    ),
                    const SizedBox(height: 12),
                    _label('Pressão (PSI)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pressaoPsiController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 350.0'),
                    ),
                    const SizedBox(height: 12),
                    _label('Temp. Retorno (°C)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tempRetornoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 28.5'),
                    ),
                    const SizedBox(height: 12),
                    _label('Temp. Insuflamento (°C)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tempInsuflamentoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 18.5'),
                    ),
                  ],
                ),
              ),
                            _buildCard(
                title: 'Foto Final',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Máquina montada e organizada'),
                    const SizedBox(height: 6),
                    _fotoWidget(_imagePathFinal,
                        () => _tirarFoto(tipo: 'final')),
                  ],
                ),
              ),
              _buildCard(
                title: 'Observações Técnicas',
                child: TextField(
                  controller: _observacoesTecnicasController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration(
                    'Peças a comprar ou anomalias encontradas',
                  ),
                ),
              ),
              _buildCard(
                title: 'Responsável / Chefe do Setor',
                child: Column(
                  children: [
                    _label('Nome do Chefe'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nomeChefeSectorController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Nome completo'),
                    ),
                    const SizedBox(height: 12),
                    _label('Número Funcional / Chapa'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _chapaFuncionalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDecoration('Ex.: 12345'),
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Assinatura do Chefe (OBRIGATÓRIA)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _assinaturaByte == null
                              ? Colors.grey[400]!
                              : const Color(0xFF22c55e),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[50],
                      ),
                      child: _assinaturaByte != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _assinaturaByte!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Center(
                              child: Text(
                                'Toque em "Capturar" para assinar',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _assinaturaByte == null
                                ? _salvarAssinatura
                                : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Capturar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF22c55e),
                              side: const BorderSide(
                                  color: Color(0xFF22c55e)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _assinaturaByte != null
                                ? _limparAssinatura
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Limpar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_assinaturaByte != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22c55e).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF22c55e),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF22c55e), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Assinatura capturada',
                              style: TextStyle(
                                color: Color(0xFF16a34a),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22c55e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'FINALIZAR CHECKLIST',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
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
            color: Colors.grey.withOpacity(0.2),
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

  Widget _fotoWidget(String? path, VoidCallback onTap) {
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
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: const Text('Tirar foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563eb),
            side: const BorderSide(color: Color(0xFF2563eb)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sim'),
                  selected: valor == true,
                  onSelected: (_) => onChanged(true),
                  selectedColor: const Color(0xFF22c55e),
                  labelStyle: TextStyle(
                    color: valor == true ? Colors.white : Colors.grey[700],
                  ),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(
                    color: valor == true
                        ? const Color(0xFF22c55e)
                        : Colors.grey[400]!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Não'),
                  selected: valor == false,
                  onSelected: (_) => onChanged(false),
                  selectedColor: const Color(0xFFef4444),
                  labelStyle: TextStyle(
                    color: valor == false ? Colors.white : Colors.grey[700],
                  ),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(
                    color: valor == false
                        ? const Color(0xFFef4444)
                        : Colors.grey[400]!,
                  ),
                ),
              ),
            ],
          ),
          if ((problemaQuandoSim && valor == true) ||
              (!problemaQuandoSim && valor == false)) ...[
            const SizedBox(height: 6),
            TextField(
              controller: obsController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.black87),
              decoration: _inputDecoration('Explique o motivo'),
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
          '$label: ',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
    );
  }
}

class _MaquinaResumoCard extends StatelessWidget {
  final Maquina maquina;

  const _MaquinaResumoCard({required this.maquina});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFdbeafe),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563eb),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563eb),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FUEL: ${maquina.fuel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.ac_unit,
                color: Color(0xFF2563eb),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF22c55e), size: 16),
              SizedBox(width: 6),
              Text(
                'Máquina encontrada',
                style: TextStyle(
                  color: Color(0xFF16a34a),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            maquina.modelo,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
