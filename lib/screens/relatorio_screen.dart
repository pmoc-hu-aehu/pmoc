import 'package:flutter/material.dart';
import '../services/database_service.dart';

class RelatorioScreen extends StatefulWidget {
  final String tecnico;

  const RelatorioScreen({super.key, required this.tecnico});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  bool   _carregando = true;
  int    _total      = 0;
  List<Map<String, dynamic>> _lista = [];

  static const _corPrimaria = Color(0xFF10b981);

  static const _labelTipo = {
    'filtro'      : 'Filtro',
    'duto'        : 'Duto',
    'preventiva'  : 'Preventiva',
    'corretiva'   : 'Corretiva',
    'pressao'     : 'Pressão',
    'qualidadeAr' : 'Qualidade do Ar',
    'movimentacao': 'Movimentação',
    'exaustao'    : 'Exaustão',
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista  = await DatabaseService.manutencoesHoje(widget.tecnico);
    if (!mounted) return;
    setState(() {
      _lista     = lista;
      _total     = lista.length;
      _carregando = false;
    });
  }

  String _formatarHora(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation      : 0,
        title          : const Text(
          'RELATÓRIOS',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: _corPrimaria))
            : Column(
                children: [
                  _buildContadorDia(),
                  Expanded(child: _buildLista()),
                ],
              ),
      ),
    );
  }

  Widget _buildContadorDia() {
    final hoje = DateTime.now();
    final dia  = hoje.day.toString().padLeft(2, '0');
    final mes  = hoje.month.toString().padLeft(2, '0');
    final ano  = hoje.year.toString();

    return Container(
      width  : double.infinity,
      margin : const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color       : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(20),
        border      : Border.all(
          color: _corPrimaria.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color     : _corPrimaria.withValues(alpha: 0.12),
            blurRadius: 20,
            offset    : const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding   : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color       : _corPrimaria.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: _corPrimaria,
                  size : 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manutenções hoje',
                    style: TextStyle(
                      color   : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$_total',
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 52,
                      fontWeight: FontWeight.w800,
                      height    : 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dia/$mes/$ano',
                style: TextStyle(
                  color   : Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              Text(
                'Zera à meia-noite',
                style: TextStyle(
                  color   : Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size : 56,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma manutenção registrada hoje',
              style: TextStyle(
                color   : Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color      : _corPrimaria,
      onRefresh  : _carregar,
      child: ListView.builder(
        padding    : const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount  : _lista.length,
        itemBuilder: (context, index) {
          final item  = _lista[index];
          final tipo  = item['tipo'] as String? ?? '';
          final fuel  = item['fuel'] as String? ?? '';
          final hora  = _formatarHora(item['data_hora'] as String? ?? '');
          final label = _labelTipo[tipo] ?? tipo;

          return Container(
            margin : const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color       : const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(14),
              border      : Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width : 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color       : _corPrimaria.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: _corPrimaria,
                    size : 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fuel,
                        style: const TextStyle(
                          color     : Colors.white,
                          fontSize  : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          color   : Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  hora,
                  style: TextStyle(
                    color   : _corPrimaria.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
