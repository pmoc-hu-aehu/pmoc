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
  List<Map<String, dynamic>> _lista = [];

  static const _corPrimaria = Color(0xFF10b981);

  static const _tiposInfo = [
    {'tipo': 'filtro',       'label': 'Filtros',         'icon': Icons.filter_alt_outlined,           'cor': Color(0xFF0ea5e9)},
    {'tipo': 'duto',         'label': 'Dutos',           'icon': Icons.air_outlined,                  'cor': Color(0xFF10b981)},
    {'tipo': 'preventiva',   'label': 'Preventivas',     'icon': Icons.verified_outlined,             'cor': Color(0xFF2563eb)},
    {'tipo': 'corretiva',    'label': 'Corretivas',      'icon': Icons.build_outlined,                'cor': Color(0xFFf97316)},
    {'tipo': 'pressao',      'label': 'Pressão',         'icon': Icons.compress_outlined,             'cor': Color(0xFFe11d48)},
    {'tipo': 'qualidadeAr',  'label': 'Qualidade do Ar', 'icon': Icons.air,                           'cor': Color(0xFF8b5cf6)},
    {'tipo': 'movimentacao', 'label': 'Movimentação',    'icon': Icons.swap_horiz_outlined,           'cor': Color(0xFFf59e0b)},
    {'tipo': 'exaustao',     'label': 'Exaustão',        'icon': Icons.cyclone_outlined,              'cor': Color(0xFF7c3aed)},
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await DatabaseService.manutencoesHoje(widget.tecnico);
    if (!mounted) return;
    setState(() {
      _lista     = lista;
      _carregando = false;
    });
  }

  int _contarTipo(String tipo) =>
      _lista.where((e) => e['tipo'] == tipo).length;

  String _formatarHora(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            : RefreshIndicator(
                color    : _corPrimaria,
                onRefresh: _carregar,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildContadorTotal(),
                    const SizedBox(height: 20),
                    _buildGridTipos(),
                    const SizedBox(height: 24),
                    if (_lista.isNotEmpty) ...[
                      Text(
                        'Histórico do dia',
                        style: TextStyle(
                          color     : Colors.white.withValues(alpha: 0.6),
                          fontSize  : 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._lista.map(_buildItemLista),
                    ] else
                      _buildVazio(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContadorTotal() {
    final hoje = DateTime.now();
    final data = '${hoje.day.toString().padLeft(2, '0')}/'
        '${hoje.month.toString().padLeft(2, '0')}/'
        '${hoje.year}';

    return Container(
      width  : double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color       : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(20),
        border      : Border.all(color: _corPrimaria.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: _corPrimaria.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
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
                child: const Icon(Icons.build_circle_outlined, color: _corPrimaria, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manutenções hoje', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    '${_lista.length}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 56,
                      fontWeight: FontWeight.w800, height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              Text('Zera à meia-noite', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridTipos() {
    return Column(
      children: List.generate((_tiposInfo.length / 2).ceil(), (rowIndex) {
        final a = rowIndex * 2;
        final b = a + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: _buildTipoCard(_tiposInfo[a])),
              const SizedBox(width: 10),
              if (b < _tiposInfo.length)
                Expanded(child: _buildTipoCard(_tiposInfo[b]))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTipoCard(Map<String, Object> info) {
    final tipo  = info['tipo'] as String;
    final label = info['label'] as String;
    final icon  = info['icon'] as IconData;
    final cor   = info['cor'] as Color;
    final count = _contarTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color       : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(
          color: count > 0 ? cor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
          width: count > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding   : const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color       : cor.withValues(alpha: count > 0 ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: count > 0 ? cor : cor.withValues(alpha: 0.4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color   : count > 0 ? Colors.white70 : Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                    height  : 1.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color     : count > 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
              fontSize  : 22,
              fontWeight: FontWeight.w800,
              height    : 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLista(Map<String, dynamic> item) {
    final tipo  = item['tipo'] as String? ?? '';
    final fuel  = item['fuel'] as String? ?? '';
    final hora  = _formatarHora(item['data_hora'] as String? ?? '');

    final info  = _tiposInfo.firstWhere(
      (e) => e['tipo'] == tipo,
      orElse: () => {'label': tipo, 'icon': Icons.check_circle_outline, 'cor': _corPrimaria},
    );
    final label = info['label'] as String;
    final cor   = info['cor'] as Color;
    final icon  = info['icon'] as IconData;

    return Container(
      margin : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color       : const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width : 38,
            height: 38,
            decoration: BoxDecoration(
              color       : cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fuel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
              ],
            ),
          ),
          Text(hora, style: TextStyle(color: cor.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.assignment_outlined, size: 52, color: Colors.white.withValues(alpha: 0.12)),
        const SizedBox(height: 10),
        Text(
          'Nenhuma manutenção registrada hoje',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        ),
      ],
    );
  }
}
