import 'package:flutter/material.dart';
import '../checklists/filtro_checklist.dart';
import '../checklists/duto_checklist.dart';
import '../checklists/preventiva_checklist.dart';
import '../checklists/corretiva_checklist.dart';
import '../checklists/movimentacao_checklist.dart';
import '../checklists/pressao_checklist.dart';
import '../checklists/qualidade_ar_checklist.dart';
import '../checklists/exaustao_checklist.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nome;
  final String perfil;

  const HomeScreen({
    super.key,
    required this.nome,
    required this.perfil,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ChecklistCardData(
        titulo: 'FILTROS',
        cor: const Color(0xFF0ea5e9),
        icon: Icons.filter_alt_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FiltroChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'DUTOS',
        cor: const Color(0xFF10b981),
        icon: Icons.air_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DutoChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'PREVENTIVAS',
        cor: const Color(0xFF2563eb),
        icon: Icons.verified_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PreventivaChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'CORRETIVAS',
        cor: const Color(0xFFf97316),
        icon: Icons.build_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CorretivaChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'MOVIMENTAÇÃO',
        cor: const Color(0xFF7c3aed),
        icon: Icons.swap_horiz_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MovimentacaoChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'PRESSÃO',
        cor: const Color(0xFFfacc15),
        icon: Icons.speed_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PressaoChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'QUALIDADE AR',
        cor: const Color(0xFF14b8a6),
        icon: Icons.cloud_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QualidadeArChecklistScreen()),
        ),
      ),
      _ChecklistCardData(
        titulo: 'EXAUSTÃO',
        cor: const Color(0xFFef4444),
        icon: Icons.air_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExaustaoChecklistScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Text(
          'PMOC DO HU LONDRINA',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1e293b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Deseja realmente sair?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1d4ed8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
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
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF0f172a),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $nome',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfil: $perfil',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selecione o tipo de checklist',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = cards[index];
                    return _ChecklistCard(data: item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              child: Icon(
                data.icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    data.icon,
                    size: 26,
                    color: Colors.white,
                  ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
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