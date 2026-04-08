import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../models/maquina.dart';
import '../models/checklist_preventiva.dart';
import 'barcode_scanner_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cores
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue   = Color(0xFF2563eb);
const _kGreen  = Color(0xFF22c55e);
const _kRed    = Color(0xFFef4444);
const _kOrange = Color(0xFFf97316);

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

class _PreventivaChecklistScreenState extends State<PreventivaChecklistScreen>
    with SingleTickerProviderStateMixin {

  // ── Tab ──────────────────────────────────────────────────────────────────
  late final TabController _tabController;
  bool _evapSalva = false;
  bool _condSalva = false;

  // ── Identificação ────────────────────────────────────────────────────────
  final _codigoController = TextEditingController();
  Maquina? _maquina;
  bool _carregandoMaquina = false;
  bool _enviando = false;

  // ── GPS ──────────────────────────────────────────────────────────────────
  String? _coordenadasGps;
  LocationPermission? _gpsPermissao;

  // ── EPIs ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _epis = [
    {'label': 'Luvas',              'icon': Icons.back_hand_outlined},
    {'label': 'Óculos',             'icon': Icons.visibility_outlined},
    {'label': 'Máscara PFF2',       'icon': Icons.masks_outlined},
    {'label': 'Protetor auricular', 'icon': Icons.hearing_outlined},
  ];
  final Set<String> _episSelecionados = {};

  // ── EVAPORADORA ──────────────────────────────────────────────────────────
  String? _fotoEvapSuja;
  bool? _chkDesmontagemEvap;
  bool? _chkLavagemEvap;
  bool? _chkDrenoBandeja;
  bool? _chkAntibactericida;
  bool? _chkRuidoEvap;
  String? _fotoEvapLimpa;

  final _obsDesmontagemEvapCtrl  = TextEditingController();
  final _obsLavagemEvapCtrl      = TextEditingController();
  final _obsDrenoBandejaCtrl     = TextEditingController();
  final _obsAntibactericidaCtrl  = TextEditingController();
  final _obsRuidoEvapCtrl        = TextEditingController();

  // ── CONDENSADORA ─────────────────────────────────────────────────────────
  String? _fotoCondSuja;
  bool? _chkDesmontagemCond;
  bool? _chkLavagemCond;
  bool? _chkRuidoCond;
  bool? _chkVazamento;
  bool? _chkEletrica;
  bool? _chkIsolamentoOk;
  String? _fotoCondLimpa;

  final _obsDesmontagemCondCtrl = TextEditingController();
  final _obsLavagemCondCtrl     = TextEditingController();
  final _obsRuidoCondCtrl       = TextEditingController();
  final _obsVazamentoCtrl       = TextEditingController();
  final _obsEletricaCtrl        = TextEditingController();
  final _obsIsolamentoOkCtrl    = TextEditingController();
  final _metrosIsolamentoCtrl   = TextEditingController();
  final _tensaoVCtrl            = TextEditingController();
  final _correnteACtrl          = TextEditingController();
  final _pressaoPsiCtrl         = TextEditingController();
  final _tempRetornoCtrl        = TextEditingController();
  final _tempInsuflamentoCtrl   = TextEditingController();

  // ── Seção Final ──────────────────────────────────────────────────────────
  final _observacoesCtrl   = TextEditingController();
  final _nomeChefeCtr      = TextEditingController();
  final _chapaFuncionalCtrl = TextEditingController();
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _obterLocalizacao();
    _solicitarPermissaoCamera();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codigoController.dispose();
    _obsDesmontagemEvapCtrl.dispose();
    _obsLavagemEvapCtrl.dispose();
    _obsDrenoBandejaCtrl.dispose();
    _obsAntibactericidaCtrl.dispose();
    _obsRuidoEvapCtrl.dispose();
    _obsDesmontagemCondCtrl.dispose();
    _obsLavagemCondCtrl.dispose();
    _obsRuidoCondCtrl.dispose();
    _obsVazamentoCtrl.dispose();
    _obsEletricaCtrl.dispose();
    _obsIsolamentoOkCtrl.dispose();
    _metrosIsolamentoCtrl.dispose();
    _tensaoVCtrl.dispose();
    _correnteACtrl.dispose();
    _pressaoPsiCtrl.dispose();
    _tempRetornoCtrl.dispose();
    _tempInsuflamentoCtrl.dispose();
    _observacoesCtrl.dispose();
    _nomeChefeCtr.dispose();
    _chapaFuncionalCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

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

  // ── Câmera ───────────────────────────────────────────────────────────────

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

  Future<void> _tirarFoto(String slot) async {
    if (!await _garantirCamera()) return;
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img == null) return;
    setState(() {
      switch (slot) {
        case 'evapSuja':  _fotoEvapSuja  = img.path; break;
        case 'evapLimpa': _fotoEvapLimpa = img.path; break;
        case 'condSuja':  _fotoCondSuja  = img.path; break;
        case 'condLimpa': _fotoCondLimpa = img.path; break;
      }
    });
  }

  // ── Máquina ──────────────────────────────────────────────────────────────

  Future<void> _buscarMaquina() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _snack('Informe o FUEL.', erro: true);
      return;
    }
    setState(() { _carregandoMaquina = true; _maquina = null; });
    final m = await DatabaseService.buscarPorFuel(codigo);
    setState(() { _carregandoMaquina = false; _maquina = m; });
    if (m == null) _snack('Nenhuma máquina encontrada para $codigo.', erro: true);
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

  // ── Assinatura ───────────────────────────────────────────────────────────

  // ── Validações ───────────────────────────────────────────────────────────

  bool _validarEvap() {
    if (_maquina == null) {
      _snack('Busque a máquina antes de continuar.', erro: true);
      return false;
    }
    if (_fotoEvapSuja == null) {
      _snack('Tire a foto inicial da evaporadora.', erro: true);
      return false;
    }
    if (_fotoEvapLimpa == null) {
      _snack('Tire a foto final da evaporadora limpa.', erro: true);
      return false;
    }
    final checkboxes = [
      _chkDesmontagemEvap, _chkLavagemEvap, _chkDrenoBandeja,
      _chkAntibactericida, _chkRuidoEvap,
    ];
    if (checkboxes.any((v) => v == null)) {
      _snack('Responda todas as perguntas da evaporadora.', erro: true);
      return false;
    }
    if (_chkDesmontagemEvap == false && _obsDesmontagemEvapCtrl.text.trim().isEmpty) {
      _snack('Explique por que a desmontagem não foi realizada.', erro: true);
      return false;
    }
    if (_chkLavagemEvap == false && _obsLavagemEvapCtrl.text.trim().isEmpty) {
      _snack('Explique por que a lavagem química não foi realizada.', erro: true);
      return false;
    }
    if (_chkDrenoBandeja == false && _obsDrenoBandejaCtrl.text.trim().isEmpty) {
      _snack('Explique o problema no dreno/bandeja.', erro: true);
      return false;
    }
    if (_chkAntibactericida == false && _obsAntibactericidaCtrl.text.trim().isEmpty) {
      _snack('Explique por que o antibactericida não foi aplicado.', erro: true);
      return false;
    }
    if (_chkRuidoEvap == true && _obsRuidoEvapCtrl.text.trim().isEmpty) {
      _snack('Descreva o ruído/vibração detectado na evaporadora.', erro: true);
      return false;
    }
    if (_tempRetornoCtrl.text.isEmpty || _tempInsuflamentoCtrl.text.isEmpty) {
      _snack('Preencha as temperaturas de retorno e insuflamento.', erro: true);
      return false;
    }
    return true;
  }

  bool _validarCond() {
    if (_fotoCondSuja == null) {
      _snack('Tire a foto inicial da condensadora.', erro: true);
      return false;
    }
    if (_fotoCondLimpa == null) {
      _snack('Tire a foto final da condensadora limpa.', erro: true);
      return false;
    }
    final checkboxes = [
      _chkDesmontagemCond, _chkLavagemCond, _chkRuidoCond,
      _chkVazamento, _chkEletrica, _chkIsolamentoOk,
    ];
    if (checkboxes.any((v) => v == null)) {
      _snack('Responda todas as perguntas da condensadora.', erro: true);
      return false;
    }
    if (_chkDesmontagemCond == false && _obsDesmontagemCondCtrl.text.trim().isEmpty) {
      _snack('Explique por que a desmontagem não foi realizada.', erro: true);
      return false;
    }
    if (_chkLavagemCond == false && _obsLavagemCondCtrl.text.trim().isEmpty) {
      _snack('Explique por que a lavagem química não foi realizada.', erro: true);
      return false;
    }
    if (_chkRuidoCond == true && _obsRuidoCondCtrl.text.trim().isEmpty) {
      _snack('Descreva o ruído/vibração detectado na condensadora.', erro: true);
      return false;
    }
    if (_chkVazamento == true && _obsVazamentoCtrl.text.trim().isEmpty) {
      _snack('Descreva o vazamento de óleo detectado.', erro: true);
      return false;
    }
    if (_chkEletrica == false && _obsEletricaCtrl.text.trim().isEmpty) {
      _snack('Descreva o problema elétrico detectado.', erro: true);
      return false;
    }
    if (_chkIsolamentoOk == false && _obsIsolamentoOkCtrl.text.trim().isEmpty) {
      _snack('Descreva o problema no isolamento.', erro: true);
      return false;
    }
    if (_chkIsolamentoOk == false && _metrosIsolamentoCtrl.text.trim().isEmpty) {
      _snack('Informe os metros de isolamento trocados.', erro: true);
      return false;
    }
    if (_tensaoVCtrl.text.isEmpty || _correnteACtrl.text.isEmpty ||
        _pressaoPsiCtrl.text.isEmpty) {
      _snack('Preencha todas as medições da condensadora.', erro: true);
      return false;
    }
    return true;
  }

  bool _validarFinal() {
    if (_nomeChefeCtr.text.trim().isEmpty) {
      _snack('Informe o nome do chefe do setor.', erro: true);
      return false;
    }
    if (_chapaFuncionalCtrl.text.trim().isEmpty) {
      _snack('Informe a chapa funcional.', erro: true);
      return false;
    }
    return true;
  }

  // ── Status geral ─────────────────────────────────────────────────────────

  String _calcularStatus() {
    // CRITICO: apenas falhas elétricas ou vazamento de óleo
    if (_chkVazamento == true || _chkEletrica == false) return 'CRITICO';
    // ATENCAO: isolamento trocado, desmontagem/lavagem não realizadas, ruído
    if (_chkIsolamentoOk == false ||
        _chkDesmontagemEvap == false || _chkLavagemEvap == false ||
        _chkDesmontagemCond == false || _chkLavagemCond == false ||
        _chkRuidoEvap == true || _chkRuidoCond == true) return 'ATENCAO';
    return 'OK';
  }

  // ── Salvar abas ──────────────────────────────────────────────────────────

  void _salvarEvap() {
    if (!_validarEvap()) return;
    setState(() => _evapSalva = true);
    _snack('Evaporadora salva! Preencha a condensadora.', sucesso: true);
    _tabController.animateTo(1);
  }

  void _salvarCond() {
    if (!_validarCond()) return;
    setState(() => _condSalva = true);
    _snack('Condensadora salva! Preencha a seção final.', sucesso: true);
  }

  // ── Finalizar ────────────────────────────────────────────────────────────

  Future<void> _finalizar() async {
    if (!_validarFinal()) return;
    setState(() => _enviando = true);

    final now = DateTime.now();
    final checklist = ChecklistPreventiva(
      dataInicio          : now,
      dataFinal           : now,
      tecnico             : widget.tecnico,
      fuel                : _maquina!.fuel,
      localizacao         : _maquina!.localizacao,
      coordenadasGps      : _coordenadasGps ?? '',
      linkFotoEvapSuja    : null,
      chkDesmontagemEvap  : _chkDesmontagemEvap!,
      obsDesmontagemEvap  : _txt(_obsDesmontagemEvapCtrl),
      chkLavagemEvap      : _chkLavagemEvap!,
      obsLavagemEvap      : _txt(_obsLavagemEvapCtrl),
      chkDrenoBandeja     : _chkDrenoBandeja!,
      obsDrenoBandeja     : _txt(_obsDrenoBandejaCtrl),
      chkAntibactericida  : _chkAntibactericida!,
      obsAntibactericida  : _txt(_obsAntibactericidaCtrl),
      chkRuidoEvap        : _chkRuidoEvap!,
      obsRuidoEvap        : _txt(_obsRuidoEvapCtrl),
      linkFotoEvapLimpa   : null,
      linkFotoCondSuja    : null,
      chkDesmontagemCond  : _chkDesmontagemCond!,
      obsDesmontagemCond  : _txt(_obsDesmontagemCondCtrl),
      chkLavagemCond      : _chkLavagemCond!,
      obsLavagemCond      : _txt(_obsLavagemCondCtrl),
      chkRuidoCond        : _chkRuidoCond!,
      obsRuidoCond        : _txt(_obsRuidoCondCtrl),
      chkVazamento        : _chkVazamento!,
      obsVazamento        : _txt(_obsVazamentoCtrl),
      chkEletrica         : _chkEletrica!,
      obsEletrica         : _txt(_obsEletricaCtrl),
      chkIsolamentoOk     : _chkIsolamentoOk!,
      obsIsolamentoOk     : _txt(_obsIsolamentoOkCtrl),
      metrosIsolamento    : _chkIsolamentoOk == false
          ? double.tryParse(_metrosIsolamentoCtrl.text)
          : null,
      linkFotoCondLimpa   : null,
      tensaoV             : double.tryParse(_tensaoVCtrl.text),
      correnteA           : double.tryParse(_correnteACtrl.text),
      pressaoPsi          : double.tryParse(_pressaoPsiCtrl.text),
      tempRetorno         : double.tryParse(_tempRetornoCtrl.text),
      tempInsuflamento    : double.tryParse(_tempInsuflamentoCtrl.text),
      observacoesTecnicas : _txt(_observacoesCtrl),
      nomeChefe           : _nomeChefeCtr.text.trim(),
      chapaFuncional      : _chapaFuncionalCtrl.text.trim(),
      linkAssinatura      : null,
      statusGeral         : _calcularStatus(),
      modelo              : _maquina!.modelo,
      marca               : _maquina!.marca,
      serie               : _maquina!.serie,
    );

    await OfflineQueueService.salvarPreventivaOffline(
      checklist        : checklist,
      fotoEvapSujaPath : _fotoEvapSuja!,
      fotoEvapLimpaPath: _fotoEvapLimpa!,
      fotoCondSujaPath : _fotoCondSuja!,
      fotoCondLimpaPath: _fotoCondLimpa!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  String? _txt(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _snack(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          erro ? Colors.redAccent : (sucesso ? Colors.green : Colors.blueGrey),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 4,
        title: Text(
          _maquina != null
              ? 'Preventiva — FUEL ${_maquina!.fuel}'
              : 'Checklist Preventiva',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Identificação ──
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
                            decoration: _inputDeco('Aponte a câmera ou digite o FUEL'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Ler código de barras',
                          onPressed: _abrirScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          color: _kBlue,
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          onPressed: _carregandoMaquina ? null : _buscarMaquina,
                          icon: _carregandoMaquina
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.search),
                          style: IconButton.styleFrom(backgroundColor: _kBlue),
                        ),
                      ],
                    ),
                    if (_maquina != null) ...[
                      const SizedBox(height: 16),
                      _MaquinaCard(maquina: _maquina!),
                    ],
                  ],
                ),
              ),

              // ── Técnico & GPS ──
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
                          color: _kBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── EPIs ──
              _buildCard(
                title: 'EPIs Utilizados',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _epis.map((epi) {
                    final label      = epi['label'] as String;
                    final icon       = epi['icon'] as IconData;
                    final sel        = _episSelecionados.contains(label);
                    return GestureDetector(
                      onTap: () => setState(() {
                        sel ? _episSelecionados.remove(label) : _episSelecionados.add(label);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: sel ? _kBlue.withOpacity(0.12) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? _kBlue : Colors.grey[300]!,
                            width: sel ? 2.0 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(icon, size: 32,
                              color: sel ? _kBlue : Colors.grey[400]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Abas ──
              _buildCard(
                title: 'Procedimentos',
                child: Column(
                  children: [
                    // Cabeçalho das abas
                    Row(
                      children: [
                        _tabBtn(0, 'EVAPORADORA', Icons.air, _evapSalva),
                        const SizedBox(width: 8),
                        _tabBtn(1, 'CONDENSADORA', Icons.device_thermostat,
                            _condSalva, bloqueada: !_evapSalva),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Conteúdo da aba ativa
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _tabController.index == 0
                          ? _buildEvap()
                          : _buildCond(),
                    ),
                  ],
                ),
              ),

              // ── Seção Final (aparece após condensadora salva) ──
              if (_condSalva) ...[
                _buildCard(
                  title: 'Observações Técnicas',
                  child: TextField(
                    controller: _observacoesCtrl,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDeco('Peças a comprar ou anomalias encontradas'),
                  ),
                ),
                _buildCard(
                  title: 'Responsável / Chefe do Setor',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Nome do Chefe'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nomeChefeCtr,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco('Nome completo'),
                      ),
                      const SizedBox(height: 12),
                      _label('Chapa Funcional'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _chapaFuncionalCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco('Ex.: 12345'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _finalizar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'FINALIZAR CHECKLIST',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 0.7),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA EVAPORADORA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEvap() {
    return Column(
      key: const ValueKey('evap'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto suja
        _label('Foto inicial (unidade antes da limpeza)'),
        const SizedBox(height: 6),
        _fotoWidget(_fotoEvapSuja, () => _tirarFoto('evapSuja')),
        const SizedBox(height: 16),

        // Perguntas
        _yesNo('Desmontagem realizada?', _chkDesmontagemEvap,
            (v) => setState(() => _chkDesmontagemEvap = v), _obsDesmontagemEvapCtrl),
        _yesNo('Lavagem química realizada?', _chkLavagemEvap,
            (v) => setState(() => _chkLavagemEvap = v), _obsLavagemEvapCtrl),
        _yesNo('Dreno/bandeja desobstruído e limpo?', _chkDrenoBandeja,
            (v) => setState(() => _chkDrenoBandeja = v), _obsDrenoBandejaCtrl),
        _yesNo('Antibactericida aplicado?', _chkAntibactericida,
            (v) => setState(() => _chkAntibactericida = v), _obsAntibactericidaCtrl),
        _yesNo('Ruído/vibração detectado?', _chkRuidoEvap,
            (v) => setState(() => _chkRuidoEvap = v), _obsRuidoEvapCtrl,
            problemaQuandoSim: true),

        // Foto limpa
        _label('Foto final (evaporadora limpa)'),
        const SizedBox(height: 6),
        _fotoWidget(_fotoEvapLimpa, () => _tirarFoto('evapLimpa')),
        const SizedBox(height: 16),

        // Medições de temperatura (evaporadora)
        _label('Temperatura Retorno (°C)'),
        const SizedBox(height: 6),
        _numField(_tempRetornoCtrl, 'Ex.: 28.5'),
        const SizedBox(height: 10),
        _label('Temperatura Insuflamento (°C)'),
        const SizedBox(height: 6),
        _numField(_tempInsuflamentoCtrl, 'Ex.: 18.5'),
        const SizedBox(height: 16),

        // Status da aba
        if (_evapSalva)
          _badgeOk('Evaporadora salva'),

        // Botão salvar
        if (!_evapSalva)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _salvarEvap,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('SALVAR EVAPORADORA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA CONDENSADORA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCond() {
    return Column(
      key: const ValueKey('cond'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto suja
        _label('Foto inicial (condensadora antes da limpeza)'),
        const SizedBox(height: 6),
        _fotoWidget(_fotoCondSuja, () => _tirarFoto('condSuja')),
        const SizedBox(height: 16),

        // Perguntas
        _yesNo('Desmontagem realizada?', _chkDesmontagemCond,
            (v) => setState(() => _chkDesmontagemCond = v), _obsDesmontagemCondCtrl),
        _yesNo('Lavagem química realizada?', _chkLavagemCond,
            (v) => setState(() => _chkLavagemCond = v), _obsLavagemCondCtrl),
        _yesNo('Ruído/vibração detectado?', _chkRuidoCond,
            (v) => setState(() => _chkRuidoCond = v), _obsRuidoCondCtrl,
            problemaQuandoSim: true),
        _yesNo('Vazamento de óleo detectado?', _chkVazamento,
            (v) => setState(() => _chkVazamento = v), _obsVazamentoCtrl,
            problemaQuandoSim: true),
        _yesNo('Parte elétrica OK?', _chkEletrica,
            (v) => setState(() => _chkEletrica = v), _obsEletricaCtrl,
            problemaQuandoNao: true),
        _yesNo('Isolamento térmico íntegro?', _chkIsolamentoOk,
            (v) => setState(() => _chkIsolamentoOk = v), _obsIsolamentoOkCtrl,
            problemaQuandoNao: true),

        // Metros de isolamento (só quando isolamento = Não)
        if (_chkIsolamentoOk == false) ...[
          const SizedBox(height: 4),
          _label('Metros de isolamento substituídos'),
          const SizedBox(height: 6),
          TextField(
            controller: _metrosIsolamentoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDeco('Ex.: 2.5'),
          ),
          const SizedBox(height: 10),
        ],

        // Foto limpa
        _label('Foto final (condensadora limpa)'),
        const SizedBox(height: 6),
        _fotoWidget(_fotoCondLimpa, () => _tirarFoto('condLimpa')),
        const SizedBox(height: 16),

        // Medições
        _label('Tensão (V)'),
        const SizedBox(height: 6),
        _numField(_tensaoVCtrl, 'Ex.: 220.5'),
        const SizedBox(height: 10),
        _label('Corrente (A)'),
        const SizedBox(height: 6),
        _numField(_correnteACtrl, 'Ex.: 8.5'),
        const SizedBox(height: 10),
        _label('Pressão (PSI)'),
        const SizedBox(height: 6),
        _numField(_pressaoPsiCtrl, 'Ex.: 350.0'),
        const SizedBox(height: 16),

        // Status da aba
        if (_condSalva)
          _badgeOk('Condensadora salva'),

        // Botão salvar
        if (!_condSalva)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _salvarCond,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('SALVAR CONDENSADORA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS AUXILIARES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _tabBtn(int index, String label, IconData icon, bool salvo,
      {bool bloqueada = false}) {
    final ativo = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: bloqueada
            ? () => _snack('Salve a evaporadora primeiro.', erro: true)
            : () => setState(() => _tabController.index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bloqueada
                ? Colors.grey[200]
                : ativo
                    ? (index == 0 ? _kBlue : _kOrange)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: bloqueada
                  ? Colors.grey[300]!
                  : ativo
                      ? (index == 0 ? _kBlue : _kOrange)
                      : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                salvo ? Icons.check_circle : icon,
                size: 18,
                color: bloqueada
                    ? Colors.grey[400]
                    : ativo
                        ? Colors.white
                        : (index == 0 ? _kBlue : _kOrange),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: bloqueada
                      ? Colors.grey[400]
                      : ativo
                          ? Colors.white
                          : (index == 0 ? _kBlue : _kOrange),
                ),
              ),
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
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
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
                  image: FileImage(File(path)), fit: BoxFit.cover),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: Text(path == null ? 'Tirar foto' : 'Trocar foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: _kBlue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _yesNo(
    String pergunta,
    bool? valor,
    ValueChanged<bool?> onChanged,
    TextEditingController obsCtrl, {
    bool problemaQuandoSim = false,
    bool problemaQuandoNao = false,
  }) {
    final mostrarObs = (problemaQuandoSim && valor == true) ||
        (problemaQuandoNao && valor == false) ||
        (!problemaQuandoSim && !problemaQuandoNao && valor == false);

    final corSim  = problemaQuandoSim ? _kRed   : _kGreen;
    final corNao  = problemaQuandoNao ? _kRed   : _kGreen;
    final grey400 = Colors.grey[400]!;
    final grey700 = Colors.grey[700]!;
    final grey100 = Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pergunta,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sim'),
                  selected: valor == true,
                  onSelected: (_) => onChanged(true),
                  selectedColor: corSim,
                  labelStyle: TextStyle(color: valor == true ? Colors.white : grey700),
                  backgroundColor: grey100,
                  side: BorderSide(color: valor == true ? corSim : grey400),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Não'),
                  selected: valor == false,
                  onSelected: (_) => onChanged(false),
                  selectedColor: corNao,
                  labelStyle: TextStyle(color: valor == false ? Colors.white : grey700),
                  backgroundColor: grey100,
                  side: BorderSide(color: valor == false ? corNao : grey400),
                ),
              ),
            ],
          ),
          if (mostrarObs) ...[
            const SizedBox(height: 6),
            TextField(
              controller: obsCtrl,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.black87),
              decoration: _inputDeco('Explique o motivo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.black87),
      decoration: _inputDeco(hint),
    );
  }

  Widget _badgeOk(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _kGreen, size: 16),
          const SizedBox(width: 8),
          Text(msg,
              style: const TextStyle(
                  color: Color(0xFF16a34a),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600));
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

// ─────────────────────────────────────────────────────────────────────────────
// Card resumo da máquina
// ─────────────────────────────────────────────────────────────────────────────

class _MaquinaCard extends StatelessWidget {
  final Maquina maquina;
  const _MaquinaCard({required this.maquina});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe0f2fe),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0ea5e9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _kBlue, borderRadius: BorderRadius.circular(20)),
                child: Text('FUEL: ${maquina.fuel}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              const Icon(Icons.ac_unit, color: _kBlue, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(maquina.modelo,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.business, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(maquina.marca,
                  style: const TextStyle(color: Colors.black87, fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.bolt, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(maquina.capacidade,
                  style: const TextStyle(color: Colors.black87, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(
                child: Text(maquina.localizacao,
                    style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
