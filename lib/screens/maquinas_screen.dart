import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../models/maquina.dart';

class MaquinasScreen extends StatefulWidget {
  const MaquinasScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _verificarConexao();
  }

  Future<void> _verificarConexao() async {
    final online = await SyncService.temConexao();
    setState(() => _online = online);
  }

  Future<void> _carregarDados() async {
    final ultima = await SyncService.ultimaSincronizacao();
    final total  = await DatabaseService.totalMaquinas();
    final lista  = await DatabaseService.todasMaquinas();
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.sucesso
              ? '✓ ${result.total} máquinas sincronizadas!'
              : '✗ ${result.mensagem}',
        ),
        backgroundColor: result.sucesso
            ? const Color(0xFF10b981)
            : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    if (result.sucesso) _carregarDados();
  }

  // ── Filtro usando campos corretos do GAS ──────────────────────────────────
  List<Maquina> get _filtradas {
    if (_busca.isEmpty) return _maquinas;
    final q = _busca.toLowerCase();
    return _maquinas.where((m) =>
      m.fuel.contains(q)                       ||
      m.modelo.toLowerCase().contains(q)       ||
      m.localizacao.toLowerCase().contains(q)  ||
      m.marca.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation      : 0,
        leading        : IconButton(
          icon     : const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MÁQUINAS',
          style: TextStyle(
            fontWeight   : FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            // ── CARD SINCRONIZAÇÃO ───────────────────────────────────────
            Container(
              margin : const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color       : const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border      : Border.all(
                  color: const Color(0xFF0ea5e9).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color       : const Color(0xFF0ea5e9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFF0ea5e9),
                          size : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sincronizar Máquinas',
                              style: TextStyle(
                                color     : Colors.white,
                                fontSize  : 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atualiza a base local com a planilha',
                              style: TextStyle(
                                color   : Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ── BOTÃO ────────────────────────────────────────
                      _online
                          ? ElevatedButton(
                              onPressed: _sincronizando ? null : _sincronizar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0ea5e9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical  : 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _sincronizando
                                  ? const SizedBox(
                                      width : 16,
                                      height: 16,
                                      child : CircularProgressIndicator(
                                        color      : Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'SINCRONIZAR',
                                      style: TextStyle(
                                        fontSize  : 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical  : 8,
                              ),
                              decoration: BoxDecoration(
                                color       : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border      : Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    color: Colors.redAccent,
                                    size : 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'OFFLINE',
                                    style: TextStyle(
                                      color     : Colors.redAccent,
                                      fontSize  : 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color : Colors.white.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 14),

                  // ── CHIPS DE INFO ────────────────────────────────────
                  Row(
                    children: [
                      _InfoChip(
                        icon : Icons.precision_manufacturing_outlined,
                        label: '$_total máquinas',
                        cor  : const Color(0xFF0ea5e9),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: _InfoChip(
                          icon : Icons.schedule_rounded,
                          label: _ultimaSync,
                          cor  : const Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── BUSCA ────────────────────────────────────────────────────
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style    : const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _busca = v),
                  decoration: InputDecoration(
                    hintText : 'Buscar por FUEL, modelo, local ou marca...',
                    hintStyle: TextStyle(
                      color   : Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0ea5e9),
                    ),
                    filled      : true,
                    fillColor   : const Color(0xFF1e293b),
                    border      : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide  : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide  : const BorderSide(
                        color: Color(0xFF0ea5e9),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical  : 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── LISTA ────────────────────────────────────────────────────
            Expanded(
              child: _total == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.precision_manufacturing_outlined,
                            size : 72,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma máquina sincronizada',
                            style: TextStyle(
                              color   : Colors.white.withValues(alpha: 0.4),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Conecte-se à internet e toque em SINCRONIZAR',
                            style: TextStyle(
                              color   : Colors.white.withValues(alpha: 0.25),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.symmetric(horizontal: 16),
                      itemCount  : _filtradas.length,
                      itemBuilder: (context, index) {
                        final m = _filtradas[index];
                        return _MaquinaCard(maquina: m);
                      },
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
  final Maquina maquina;
  const _MaquinaCard({required this.maquina});

  Color get _corCriticidade {
    switch (maquina.criticidade.toLowerCase()) {
      case 'alta'  : return const Color(0xFFef4444);
      case 'média' :
      case 'media' : return const Color(0xFFf97316);
      default      : return const Color(0xFF10b981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin     : const EdgeInsets.only(bottom: 10),
      padding    : const EdgeInsets.all(14),
      decoration : BoxDecoration(
        color       : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [

          // ── FUEL ────────────────────────────────────────────────────
          Container(
            width : 52,
            height: 52,
            decoration: BoxDecoration(
              color       : const Color(0xFF0ea5e9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                maquina.fuel,
                style: const TextStyle(
                  color     : Color(0xFF0ea5e9),
                  fontSize  : 12,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── DADOS ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maquina.modelo,
                  style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  maquina.marca,
                  style: TextStyle(
                    color   : Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  maquina.localizacao,
                  style: TextStyle(
                    color   : Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── CRITICIDADE ────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical  : 4,
                ),
                decoration: BoxDecoration(
                  color       : _corCriticidade.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border      : Border.all(
                    color: _corCriticidade.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  maquina.criticidade,
                  style: TextStyle(
                    color     : _corCriticidade,
                    fontSize  : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                maquina.capacidade,
                style: TextStyle(
                  color   : Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
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
        color       : cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color     : cor,
              fontSize  : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}