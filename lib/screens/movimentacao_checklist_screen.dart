import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/maquina.dart';
import '../models/checklist_movimentacao.dart';
import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import 'barcode_scanner_screen.dart';

const _kGreen  = Color(0xFF22c55e);
const _kRed    = Color(0xFFef4444);
const _kOrange = Color(0xFFf97316);

class MovimentacaoChecklistScreen extends StatefulWidget {
  final String tecnico;
  final String perfil;

  const MovimentacaoChecklistScreen({
    super.key,
    required this.tecnico,
    required this.perfil,
  });

  @override
  State<MovimentacaoChecklistScreen> createState() =>
      _MovimentacaoChecklistScreenState();
}

class _MovimentacaoChecklistScreenState
    extends State<MovimentacaoChecklistScreen> {

  // ── Busca de máquina ──────────────────────────────────────────────────────
  final _fuelCtrl = TextEditingController();
  Maquina? _maquina;
  bool _carregandoMaquina = false;

  // ── Cadastro inline (pleno/admin) ─────────────────────────────────────────
  bool _mostrarCadastroInline = false;
  final _modeloCtrl      = TextEditingController();
  final _marcaCtrl       = TextEditingController();
  final _serieCtrl       = TextEditingController();
  final _capacidadeCtrl  = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  String _criticidade = 'Baixa';
  bool _salvandoMaquina = false;

  // ── Movimentação ──────────────────────────────────────────────────────────
  String _tipoMovimentacao  = 'Instalação';
  String _estadoEquipamento = 'Operacional';
  final _origemCtrl    = TextEditingController();
  final _destinoCtrl   = TextEditingController();
  final _motivoCtrl    = TextEditingController();
  final _acessoriosCtrl = TextEditingController();
  bool? _chkProtecao;
  bool? _chkIsolamento;
  final _metrosCtrl = TextEditingController();

  // ── Fotos ─────────────────────────────────────────────────────────────────
  String? _fotoOrigemPath;
  String? _fotoDestinoPath;

  // ── Validação & assinatura ────────────────────────────────────────────────
  final _nomeChefCtrl = TextEditingController();
  final _chapaCtrl    = TextEditingController();

  bool _enviando = false;

  // ── Permissão de perfil ───────────────────────────────────────────────────
  bool get _podeCadastrar {
    final p = widget.perfil.toUpperCase();
    return p == 'PLENO' || p == 'ADMIN' || p == 'ENGENHEIRO';
  }

  // ── Init / Dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _solicitarPermissaoCamera();
  }

  @override
  void dispose() {
    _fuelCtrl.dispose();
    _modeloCtrl.dispose();
    _marcaCtrl.dispose();
    _serieCtrl.dispose();
    _capacidadeCtrl.dispose();
    _localizacaoCtrl.dispose();
    _origemCtrl.dispose();
    _destinoCtrl.dispose();
    _motivoCtrl.dispose();
    _acessoriosCtrl.dispose();
    _metrosCtrl.dispose();
    _nomeChefCtrl.dispose();
    _chapaCtrl.dispose();
    super.dispose();
  }

  // ── Câmera ────────────────────────────────────────────────────────────────

  Future<void> _solicitarPermissaoCamera() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) await Permission.camera.request();
  }

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
        content: const Text('Permita o acesso à câmera nas configurações.'),
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

  Future<void> _tirarFoto({required bool origem}) async {
    if (!await _garantirCamera()) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() {
      if (origem) {
        _fotoOrigemPath = file.path;
      } else {
        _fotoDestinoPath = file.path;
      }
    });
    _snack('Foto do local de ${origem ? "origem" : "destino"} registrada.');
  }

  // ── Scanner ───────────────────────────────────────────────────────────────

  Future<void> _abrirScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.trim().isNotEmpty) {
      setState(() => _fuelCtrl.text = code.trim());
      await _buscarMaquina();
    }
  }

  // ── Busca máquina ─────────────────────────────────────────────────────────

  Future<void> _buscarMaquina() async {
    final fuel = _fuelCtrl.text.trim();
    if (fuel.isEmpty) {
      _snack('Leia o código de barras ou informe o FUEL.', erro: true);
      return;
    }

    setState(() {
      _carregandoMaquina    = true;
      _maquina              = null;
      _mostrarCadastroInline = false;
    });

    final m = await DatabaseService.buscarPorFuel(fuel);

    setState(() {
      _carregandoMaquina = false;
      _maquina           = m;
    });

    if (m == null) {
      if (_podeCadastrar) {
        setState(() => _mostrarCadastroInline = true);
        _snack('Máquina não cadastrada. Preencha os dados abaixo para cadastrar.');
      } else {
        _snack(
          'Máquina não encontrada. Solicite o cadastro ao técnico pleno ou administrador.',
          erro: true,
        );
      }
      return;
    }

    // Pré-preenche setor de origem com localização atual da máquina
    _origemCtrl.text = m.localizacao;
    setState(() => _mostrarCadastroInline = false);
  }

  // ── Cadastro inline ───────────────────────────────────────────────────────

  Future<void> _salvarMaquinaInline() async {
    if (_modeloCtrl.text.trim().isEmpty ||
        _marcaCtrl.text.trim().isEmpty ||
        _localizacaoCtrl.text.trim().isEmpty) {
      _snack('Preencha ao menos Modelo, Marca e Localização.', erro: true);
      return;
    }

    setState(() => _salvandoMaquina = true);

    final nova = Maquina(
      fuel       : _fuelCtrl.text.trim(),
      localizacao: _localizacaoCtrl.text.trim(),
      modelo     : _modeloCtrl.text.trim(),
      marca      : _marcaCtrl.text.trim(),
      serie      : _serieCtrl.text.trim(),
      criticidade: _criticidade,
      capacidade : _capacidadeCtrl.text.trim(),
    );

    await DatabaseService.inserirMaquina(nova);

    setState(() {
      _salvandoMaquina       = false;
      _maquina               = nova;
      _mostrarCadastroInline = false;
      _origemCtrl.text       = nova.localizacao;
    });

    _snack('Máquina cadastrada com sucesso!', sucesso: true);
  }

  // ── Assinatura ────────────────────────────────────────────────────────────

  // ── Validação ─────────────────────────────────────────────────────────────

  bool _validar() {
    if (_maquina == null) {
      _snack('Busque e vincule a máquina antes de continuar.', erro: true);
      return false;
    }
    if (_origemCtrl.text.trim().isEmpty) {
      _snack('Informe o setor de origem.', erro: true); return false;
    }
    if (_destinoCtrl.text.trim().isEmpty) {
      _snack('Informe o setor de destino.', erro: true); return false;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      _snack('Informe o motivo da movimentação.', erro: true); return false;
    }
    if (_chkProtecao == null) {
      _snack('Responda: proteção para transporte?', erro: true); return false;
    }
    if (_chkIsolamento == null) {
      _snack('Responda: isolamento necessário?', erro: true); return false;
    }
    if (_fotoOrigemPath == null) {
      _snack('Tire a foto do local de origem (obrigatória).', erro: true); return false;
    }
    if (_fotoDestinoPath == null) {
      _snack('Tire a foto do local de destino (obrigatória).', erro: true); return false;
    }
    if (_nomeChefCtrl.text.trim().isEmpty) {
      _snack('Informe o nome do responsável.', erro: true); return false;
    }
    if (_chapaCtrl.text.trim().isEmpty) {
      _snack('Informe a chapa funcional.', erro: true); return false;
    }
    return true;
  }

  // ── Envio ─────────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_validar()) return;
    setState(() => _enviando = true);

    final checklist = ChecklistMovimentacao(
      dataInicio            : DateTime.now(),
      tecnico               : widget.tecnico,
      fuel                  : _maquina!.fuel,
      origemSetor           : _origemCtrl.text.trim(),
      tipoMovimentacao      : _tipoMovimentacao,
      motivo                : _motivoCtrl.text.trim(),
      destinoSetor          : _destinoCtrl.text.trim(),
      estadoEquipamento     : _estadoEquipamento,
      acessorios            : _acessoriosCtrl.text.trim(),
      chkProtecaoTransporte : _chkProtecao!,
      chkIsolamentoNecessario: _chkIsolamento!,
      metrosEstimados       : _chkIsolamento! ? double.tryParse(_metrosCtrl.text.trim()) : null,
      nomeChefSetor         : _nomeChefCtrl.text.trim(),
      chapaFuncional        : _chapaCtrl.text.trim(),
    );

    await OfflineQueueService.salvarMovimentacaoOffline(
      checklist        : checklist,
      fotoOrigemPath   : _fotoOrigemPath!,
      fotoDestinoPath  : _fotoDestinoPath!,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Snack ─────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          erro ? Colors.redAccent : (sucesso ? Colors.green : Colors.blueGrey),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        title: const Text(
          'CHECKLIST.MOVIMENTAÇÃO',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── IDENTIFICAÇÃO DA MÁQUINA ──────────────────────────
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
                            controller: _fuelCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: _inputDeco('Aponte a câmera ou digite o FUEL'),
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

                    // Card máquina encontrada
                    if (_maquina != null) ...[
                      const SizedBox(height: 16),
                      _MaquinaResumoCard(maquina: _maquina!),
                    ],

                    // Bloqueio para perfil básico
                    if (_maquina == null &&
                        _fuelCtrl.text.isNotEmpty &&
                        !_carregandoMaquina &&
                        !_mostrarCadastroInline)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.block, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Máquina não encontrada. Solicite o cadastro ao técnico pleno ou administrador.',
                                  style: TextStyle(color: Colors.black, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Formulário inline de cadastro (pleno/admin)
                    if (_mostrarCadastroInline) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kOrange, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.add_box_outlined, color: _kOrange, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Cadastrar nova máquina',
                                  style: TextStyle(
                                    color: _kOrange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _label('Localização atual *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _localizacaoCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _inputDeco('Ex.: UTI – Bloco B'),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Modelo *'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _modeloCtrl,
                                        textCapitalization: TextCapitalization.characters,
                                        style: const TextStyle(color: Colors.black87),
                                        decoration: _inputDeco('Ex.: SPLIT-12000'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Marca *'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _marcaCtrl,
                                        textCapitalization: TextCapitalization.words,
                                        style: const TextStyle(color: Colors.black87),
                                        decoration: _inputDeco('Ex.: Carrier'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Série'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _serieCtrl,
                                        style: const TextStyle(color: Colors.black87),
                                        decoration: _inputDeco('Nº série'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _label('Capacidade'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _capacidadeCtrl,
                                        style: const TextStyle(color: Colors.black87),
                                        decoration: _inputDeco('Ex.: 12000 BTU'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _label('Criticidade'),
                            const SizedBox(height: 6),
                            _chipSelector(
                              opcoes     : const ['Baixa', 'Média', 'Alta', 'Crítica'],
                              selecionado: _criticidade,
                              cores      : const {
                                'Baixa'  : _kGreen,
                                'Média'  : Color(0xFF0ea5e9),
                                'Alta'   : _kOrange,
                                'Crítica': _kRed,
                              },
                              onChange: (v) => setState(() => _criticidade = v),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _salvandoMaquina ? null : _salvarMaquinaInline,
                                icon : _salvandoMaquina
                                    ? const SizedBox(width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Salvar e continuar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kOrange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── DETALHES DA MOVIMENTAÇÃO ──────────────────────────
              _buildCard(
                title: 'Detalhes da Movimentação',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tipo de Movimentação'),
                    const SizedBox(height: 6),
                    _chipSelector(
                      opcoes     : const ['Instalação', 'Retirada', 'Transferência'],
                      selecionado: _tipoMovimentacao,
                      cores      : const {
                        'Instalação'   : _kGreen,
                        'Retirada'     : _kRed,
                        'Transferência': Color(0xFF0ea5e9),
                      },
                      onChange: (v) => setState(() => _tipoMovimentacao = v),
                    ),
                    const SizedBox(height: 12),
                    _label('Setor de Origem *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _origemCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: UTI – Bloco A'),
                    ),
                    const SizedBox(height: 12),
                    _label('Setor de Destino *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _destinoCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: Sala de Cirurgia – Bloco C'),
                    ),
                    const SizedBox(height: 12),
                    _label('Motivo *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _motivoCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: Equipamento solicitado pela chefia de enfermagem'),
                    ),
                    const SizedBox(height: 12),
                    _label('Estado do Equipamento'),
                    const SizedBox(height: 6),
                    _chipSelector(
                      opcoes     : const ['Operacional', 'Com Defeito', 'Para Manutenção'],
                      selecionado: _estadoEquipamento,
                      cores      : const {
                        'Operacional'     : _kGreen,
                        'Com Defeito'     : _kRed,
                        'Para Manutenção' : _kOrange,
                      },
                      onChange: (v) => setState(() => _estadoEquipamento = v),
                    ),
                    const SizedBox(height: 12),
                    _label('Acessórios transportados'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _acessoriosCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _inputDeco('Ex.: Controle remoto, suporte de parede, cabo'),
                    ),
                  ],
                ),
              ),

              // ── PROTEÇÃO & ISOLAMENTO ─────────────────────────────
              _buildCard(
                title: 'Proteção & Isolamento',
                child: Column(
                  children: [
                    _yesNo(
                      'Equipamento protegido para transporte (embalagem/plástico)?',
                      _chkProtecao,
                      (v) => setState(() => _chkProtecao = v),
                    ),
                    _yesNo(
                      'Isolamento térmico necessário?',
                      _chkIsolamento,
                      (v) => setState(() => _chkIsolamento = v),
                    ),
                    if (_chkIsolamento == true) ...[
                      const SizedBox(height: 4),
                      _label('Metros estimados de isolamento'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _metrosCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco('Ex.: 2.5'),
                      ),
                    ],
                  ],
                ),
              ),

              // ── FOTO ORIGEM ───────────────────────────────────────
              _buildCard(
                title: 'Foto do Local de Origem *',
                child: _fotoWidget(
                  path : _fotoOrigemPath,
                  onTap: () => _tirarFoto(origem: true),
                  label: 'Tirar foto da origem',
                ),
              ),

              // ── FOTO DESTINO ──────────────────────────────────────
              _buildCard(
                title: 'Foto do Local de Destino *',
                child: _fotoWidget(
                  path : _fotoDestinoPath,
                  onTap: () => _tirarFoto(origem: false),
                  label: 'Tirar foto do destino',
                ),
              ),

              // ── VALIDAÇÃO DO SETOR ────────────────────────────────
              _buildCard(
                title: 'Validação do Responsável (Obrigatório)',
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

              // ── BOTÃO FINALIZAR ───────────────────────────────────
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
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                        )
                      : const Text(
                          'FINALIZAR CHECKLIST',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
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

  // ── Widgets auxiliares ────────────────────────────────────────────────────

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
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
        final cor = cores[op] ?? Colors.black;
        return GestureDetector(
          onTap: () => onChange(op),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? cor : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              op.toUpperCase(),
              style: TextStyle(
                color: sel ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }).toList(),
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
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 2)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ── Card resumo da máquina ────────────────────────────────────────────────────

class _MaquinaResumoCard extends StatelessWidget {
  final Maquina maquina;
  const _MaquinaResumoCard({required this.maquina});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.black,
            child: Text(
              'FUEL: ${maquina.fuel}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 10),
          _row('Modelo', maquina.modelo),
          _row('Marca', maquina.marca),
          _row('Local atual', maquina.localizacao),
          _row('Capacidade', maquina.capacidade),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${label.toUpperCase()}: ',
            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.black87, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
