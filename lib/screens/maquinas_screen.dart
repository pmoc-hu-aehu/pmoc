import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../models/maquina.dart';

class MaquinasScreen extends StatefulWidget {
  final String perfil;

  const MaquinasScreen({super.key, required this.perfil});

  @override
  State<MaquinasScreen> createState() => _MaquinasScreenState();
}

class _MaquinasScreenState extends State<MaquinasScreen> {
  bool          _sincronizando = false;
  bool          _online        = false;
  String        _ultimaSync    = 'Carregando...';
  int           _total         = 0;
  List<Maquina> _maquinas      = [];
  String        _busca         = '';

  bool get _podeEditar =>
      widget.perfil.toLowerCase() == 'admin' ||
      widget.perfil.toLowerCase() == 'pleno';

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _verificarConexao();
    _autoSyncSeNecessario();
  }

  Future<void> _autoSyncSeNecessario() async {
    final online = await SyncService.temConexao();
    if (!online) return;

    final hoje       = _dataHoje();
    final ultimaAuto = await DatabaseService.lerConfig('maquinas_auto_sync_data');
    if (ultimaAuto == hoje) return; // já sincronizou hoje

    await DatabaseService.salvarConfig('maquinas_auto_sync_data', hoje);
    if (!mounted) return;
    setState(() => _sincronizando = true);
    final result = await SyncService.sincronizarMaquinas();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    if (result.sucesso) _carregarDados();
  }

  String _dataHoje() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _verificarConexao() async {
    final online = await SyncService.temConexao();
    if (mounted) setState(() => _online = online);
  }

  Future<void> _carregarDados() async {
    final ultima = await SyncService.ultimaSincronizacao();
    final total  = await DatabaseService.totalMaquinas();
    final lista  = await DatabaseService.todasMaquinas();
    if (!mounted) return;
    setState(() {
      _ultimaSync = ultima;
      _total      = total;
      _maquinas   = lista;
    });
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    final result = await SyncService.sincronizarMaquinas();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.sucesso
          ? '✓ ${result.total} máquinas sincronizadas!'
          : '✗ ${result.mensagem}'),
      backgroundColor:
          result.sucesso ? const Color(0xFF10b981) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (result.sucesso) _carregarDados();
  }

  Future<void> _abrirForm({Maquina? maquina}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormMaquina(maquina: maquina),
    );
    if (ok == true) _carregarDados();
  }

  List<Maquina> get _filtradas {
    if (_busca.isEmpty) return _maquinas;
    final q = _busca.toLowerCase();
    return _maquinas.where((m) =>
      m.fuel.toLowerCase().contains(q)        ||
      m.modelo.toLowerCase().contains(q)      ||
      m.localizacao.toLowerCase().contains(q) ||
      m.marca.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MÁQUINAS',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      floatingActionButton: _podeEditar
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              backgroundColor: const Color(0xFF0ea5e9),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADICIONAR',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [

            // ── CARD SINCRONIZAÇÃO ────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF0ea5e9).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha 1: ícone + título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0ea5e9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sync_rounded,
                            color: Color(0xFF0ea5e9), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sincronizar Máquinas',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('Atualiza a base local com a planilha',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Linha 2: chips de info + botão (lado a lado só se couber, senão empilha)
                  Row(
                    children: [
                      // ── CHIPS ──────────────────────────────────────
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              icon: Icons.precision_manufacturing_outlined,
                              label: '$_total máquinas',
                              cor: const Color(0xFF0ea5e9),
                            ),
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: _ultimaSync,
                              cor: const Color(0xFF10b981),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── BOTÃO SINCRONIZAR / OFFLINE ────────────────
                      _online
                          ? ElevatedButton(
                              onPressed: _sincronizando ? null : _sincronizar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0ea5e9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: _sincronizando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('SINCRONIZAR',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wifi_off_rounded,
                                      color: Colors.redAccent, size: 14),
                                  SizedBox(width: 6),
                                  Text('OFFLINE',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),

            // ── BUSCA ─────────────────────────────────────────────────
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (v) => setState(() => _busca = v),
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por FUEL, modelo, local ou marca...',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF0ea5e9), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1e293b),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0ea5e9), width: 1.2)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── LISTA ─────────────────────────────────────────────────
            Expanded(
              child: _total == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.precision_manufacturing_outlined,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.08)),
                          const SizedBox(height: 16),
                          Text('Nenhuma máquina cadastrada',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(
                            _podeEditar
                                ? 'Sincronize ou toque em ADICIONAR'
                                : 'Conecte-se e toque em SINCRONIZAR',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _filtradas.length,
                      itemBuilder: (_, i) => _MaquinaCard(
                        maquina: _filtradas[i],
                        podeEditar: _podeEditar,
                        onEditar: () => _abrirForm(maquina: _filtradas[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CARD DE MÁQUINA ──────────────────────────────────────────────────────────

class _MaquinaCard extends StatelessWidget {
  final Maquina    maquina;
  final bool       podeEditar;
  final VoidCallback onEditar;

  const _MaquinaCard({
    required this.maquina,
    required this.podeEditar,
    required this.onEditar,
  });

  Color get _corCrit {
    switch (maquina.criticidade.toLowerCase()) {
      case 'alta':  return const Color(0xFFef4444);
      case 'média':
      case 'media': return const Color(0xFFf97316);
      default:      return const Color(0xFF10b981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── FUEL ────────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0ea5e9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    maquina.fuel,
                    style: const TextStyle(
                        color: Color(0xFF0ea5e9),
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── DADOS ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(maquina.modelo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(maquina.marca,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(maquina.localizacao,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (maquina.capacidade.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(maquina.capacidade,
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── CRITICIDADE ─────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _corCrit.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _corCrit.withValues(alpha: 0.4)),
                ),
                child: Text(maquina.criticidade,
                    style: TextStyle(
                        color: _corCrit,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          // ── BOTÃO EDITAR (pleno/admin) ─────────────────────────────
          if (podeEditar) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Editar',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0ea5e9),
                  side: BorderSide(
                      color: const Color(0xFF0ea5e9).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── FORMULÁRIO ADICIONAR / EDITAR MÁQUINA ────────────────────────────────────

class _FormMaquina extends StatefulWidget {
  final Maquina? maquina; // null = adicionar, não-null = editar

  const _FormMaquina({this.maquina});

  @override
  State<_FormMaquina> createState() => _FormMaquinaState();
}

class _FormMaquinaState extends State<_FormMaquina> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _fuelCtrl;
  late final TextEditingController _localCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _serieCtrl;
  late final TextEditingController _capCtrl;
  late String _criticidade;
  bool _salvando = false;

  bool get _editando => widget.maquina != null;

  @override
  void initState() {
    super.initState();
    final m = widget.maquina;
    _fuelCtrl    = TextEditingController(text: m?.fuel        ?? '');
    _localCtrl   = TextEditingController(text: m?.localizacao ?? '');
    _modeloCtrl  = TextEditingController(text: m?.modelo      ?? '');
    _marcaCtrl   = TextEditingController(text: m?.marca       ?? '');
    _serieCtrl   = TextEditingController(text: m?.serie       ?? '');
    _capCtrl     = TextEditingController(text: m?.capacidade  ?? '');
    _criticidade = m?.criticidade ?? 'Baixa';
  }

  @override
  void dispose() {
    _fuelCtrl.dispose();
    _localCtrl.dispose();
    _modeloCtrl.dispose();
    _marcaCtrl.dispose();
    _serieCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final maquina = Maquina(
      id         : widget.maquina?.id,
      fuel       : _fuelCtrl.text.trim(),
      localizacao: _localCtrl.text.trim(),
      modelo     : _modeloCtrl.text.trim(),
      marca      : _marcaCtrl.text.trim(),
      serie      : _serieCtrl.text.trim(),
      criticidade: _criticidade,
      capacidade : _capCtrl.text.trim(),
    );

    await DatabaseService.inserirMaquina(maquina);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1e293b),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _editando ? 'Editar Máquina' : 'Adicionar Máquina',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              _campo(_fuelCtrl,   'FUEL *',        'Número do FUEL',      TextInputType.number),
              _campo(_localCtrl,  'Localização *', 'Ex.: Bloco A - Sala 101'),
              _campo(_modeloCtrl, 'Modelo *',      'Ex.: Split 12000 BTU'),
              _campo(_marcaCtrl,  'Marca *',       'Ex.: Springer'),
              _campo(_serieCtrl,  'Série',         'Número de série', null, false),
              _campo(_capCtrl,    'Capacidade',    'Ex.: 12.000 BTU',  null, false),

              const SizedBox(height: 4),
              const Text('Criticidade',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _criticidade,
                dropdownColor: const Color(0xFF1e293b),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDeco(''),
                items: ['Baixa', 'Média', 'Alta']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style:
                                  const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _criticidade = v!),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_editando ? 'SALVAR ALTERAÇÕES' : 'SALVAR',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    String hint, [
    TextInputType? tipo,
    bool obrigatorio = true,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            keyboardType: tipo,
            // FUEL não editável quando estiver editando
            readOnly: _editando && label.startsWith('FUEL'),
            style: TextStyle(
                color: (_editando && label.startsWith('FUEL'))
                    ? Colors.white38
                    : Colors.white,
                fontSize: 14),
            decoration: _inputDeco(hint),
            validator: obrigatorio
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF0f172a),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0ea5e9), width: 1.2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ── CHIP DE INFO ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    cor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: cor, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
