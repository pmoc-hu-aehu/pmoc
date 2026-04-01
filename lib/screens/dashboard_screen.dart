import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'maquinas_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String nome;
  final String perfil;

  const DashboardScreen({
    super.key,
    required this.nome,
    required this.perfil,
  });

  @override
  Widget build(BuildContext context) {
    final menus = [
      _MenuItemData(
        titulo  : 'CHECKLISTS',
        subtitulo: 'Registros de manutenção',
        icon    : Icons.checklist_rounded,
        cor     : const Color(0xFF2563eb),
        onTap   : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(nome: nome, perfil: perfil),
          ),
        ),
      ),
      _MenuItemData(
        titulo   : 'MÁQUINAS',
        subtitulo: 'Cadastro de equipamentos',
        icon     : Icons.precision_manufacturing_outlined,
        cor      : const Color(0xFF0ea5e9),
        onTap    : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MaquinasScreen(),
          ),
        ),
      ),
      _MenuItemData(
        titulo   : 'RELATÓRIOS',
        subtitulo: 'Histórico e exportação',
        icon     : Icons.bar_chart_rounded,
        cor      : const Color(0xFF10b981),
        onTap    : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content        : const Text('Tela de Relatórios em breve'),
              backgroundColor: const Color(0xFF1e293b),
              behavior       : SnackBarBehavior.floating,
              shape          : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation      : 0,
        title          : const Text(
          'PMOC DO HU LONDRINA',
          style: TextStyle(
            fontWeight   : FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon   : const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1e293b),
                  shape          : RoundedRectangleBorder(
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
                      child    : const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1d4ed8),
                        shape          : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child    : const Text('Sair'),
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
      body: SafeArea(
        child: Column(
          children: [

            // ── CABEÇALHO ────────────────────────────────────────────────
            Container(
              width  : double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF0f172a),
                  ],
                  begin: Alignment.topLeft,
                  end  : Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width : 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color : const Color(0xFF1d4ed8).withValues(alpha: 0.25),
                          shape : BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3b82f6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF3b82f6),
                          size : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $nome',
                            style: const TextStyle(
                              color     : Colors.white,
                              fontSize  : 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Perfil: $perfil',
                            style: TextStyle(
                              color   : Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color : Colors.white.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O que deseja fazer?',
                    style: TextStyle(
                      color   : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ── MENU PRINCIPAL ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: menus.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child  : _MenuItem(data: item),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── RODAPÉ ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child  : Text(
                'DMPE — HU Londrina © 2025',
                style: TextStyle(
                  color   : Colors.white.withValues(alpha: 0.18),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ITEM DE MENU ─────────────────────────────────────────────────────────────

class _MenuItemData {
  final String      titulo;
  final String      subtitulo;
  final IconData    icon;
  final Color       cor;
  final VoidCallback onTap;

  _MenuItemData({
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.cor,
    required this.onTap,
  });
}

class _MenuItem extends StatelessWidget {
  final _MenuItemData data;
  const _MenuItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap        : data.onTap,
      borderRadius : BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color       : const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(18),
          border      : Border.all(
            color: data.cor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color     : data.cor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset    : const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width : 52,
              height: 52,
              decoration: BoxDecoration(
                color       : data.cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data.icon,
                color: data.cor,
                size : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.titulo,
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitulo,
                    style: TextStyle(
                      color   : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: data.cor.withValues(alpha: 0.7),
              size : 28,
            ),
          ],
        ),
      ),
    );
  }
}