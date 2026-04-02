import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'filtros_checklist_screen.dart';
import 'dutos_checklist_screen.dart';
import '../services/api_service.dart';
import '../services/offline_queue_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nome;
  final String perfil;

  const HomeScreen({
    super.key,
    required this.nome,
    required this.perfil,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pendentes = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _atualizarPendentes();
    _sincronizarSeOnline();

    // Tenta sincronizar toda vez que a conexão voltar
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _sincronizarSeOnline();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _atualizarPendentes() async {
    final total = await OfflineQueueService.contarPendentes();
    if (mounted) setState(() => _pendentes = total);
  }

  Future<void> _sincronizarSeOnline() async {
    final enviados = await OfflineQueueService.processarFila();
    if (enviados > 0 && mounted) {
      _atualizarPendentes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$enviados checklist(s) pendente(s) enviado(s) com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ChecklistCardData(
        titulo: 'FILTROS',
        cor: const Color(0xFF0ea5e9),
        icon: Icons.filter_alt_outlined,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FiltrosChecklistScreen(tecnico: widget.nome),
            ),
          );
          // Ao voltar, atualiza badge e tenta sync
          _atualizarPendentes();
          _sincronizarSeOnline();
        },
      ),
      _ChecklistCardData(
        titulo: 'DUTOS',
        cor: const Color(0xFF10b981),
        icon: Icons.air_outlined,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DutosChecklistScreen(tecnico: widget.nome),
            ),
          );
          // Ao voltar, atualiza badge e tenta sync
          _atualizarPendentes();
          _sincronizarSeOnline();
        },
      ),
      _ChecklistCardData(
        titulo: 'PREVENTIVAS',
        cor: const Color(0xFF2563eb),
        icon: Icons.verified_outlined,
        onTap: () => _emBreve(context, 'Preventivas'),
      ),
      _ChecklistCardData(
        titulo: 'CORRETIVAS',
        cor: const Color(0xFFf97316),
        icon: Icons.build_outlined,
        onTap: () => _emBreve(context, 'Corretivas'),
      ),
      _ChecklistCardData(
        titulo: 'MOVIMENTAÇÃO',
        cor: const Color(0xFF7c3aed),
        icon: Icons.swap_horiz_rounded,
        onTap: () => _emBreve(context, 'Movimentação'),
      ),
      _ChecklistCardData(
        titulo: 'PRESSÃO',
        cor: const Color(0xFFfacc15),
        icon: Icons.speed_outlined,
        onTap: () => _emBreve(context, 'Pressão'),
      ),
      _ChecklistCardData(
        titulo: 'QUALIDADE AR',
        cor: const Color(0xFF14b8a6),
        icon: Icons.cloud_outlined,
        onTap: () => _emBreve(context, 'Qualidade do Ar'),
      ),
      _ChecklistCardData(
        titulo: 'EXAUSTÃO',
        cor: const Color(0xFFef4444),
        icon: Icons.air_rounded,
        onTap: () => _emBreve(context, 'Exaustão'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Text(
          'PMOC DO HU LONDRINA',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        actions: [
          if (_pendentes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: _BadgePendentes(total: _pendentes),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1e293b),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Sair', style: TextStyle(color: Colors.white)),
                  content: const Text('Deseja realmente sair?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1d4ed8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await ApiService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF020617), Color(0xFF0f172a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${widget.nome}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfil: ${widget.perfil}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selecione o tipo de checklist',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) => _ChecklistCard(data: cards[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _emBreve(BuildContext ctx, String nome) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Checklist de $nome em breve'),
        backgroundColor: const Color(0xFF1e293b),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Badge de pendentes ───────────────────────────────────────────────────────

class _BadgePendentes extends StatelessWidget {
  final int total;
  const _BadgePendentes({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$total pendente${total > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _ChecklistCardData {
  final String titulo;
  final Color cor;
  final IconData icon;
  final VoidCallback onTap;

  _ChecklistCardData({
    required this.titulo,
    required this.cor,
    required this.icon,
    required this.onTap,
  });
}

class _ChecklistCard extends StatelessWidget {
  final _ChecklistCardData data;
  const _ChecklistCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: data.cor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: data.cor.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -8,
              child: Icon(data.icon, size: 64, color: Colors.white.withValues(alpha: 0.24)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(data.icon, size: 26, color: Colors.white),
                  const Spacer(),
                  Text(
                    data.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checklist',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}