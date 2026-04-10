import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'maquinas_screen.dart';
import 'relatorio_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // Deep tech black
      body: SafeArea(
        child: Stack(
          children: [
            // Massive Typographic Background (Anti-Safe Harbor)
            Positioned(
              top: -30,
              left: -15,
              child: Text(
                'PMOC',
                style: TextStyle(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.04),
                  letterSpacing: -8,
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER (Sharp & Tech) ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Indicator
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCCFF00), // Acid Green
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'SYS.ONLINE',
                                  style: TextStyle(
                                    color: Color(0xFFCCFF00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              nome.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID_ROLE // ${perfil.toUpperCase()}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontFamily: 'Courier', 
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.power_settings_new),
                        color: const Color(0xFFFF4500), // Signal Orange
                        iconSize: 28,
                        tooltip: 'Encerrar Sessão',
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // ── ACTION CARDS (Asymmetric hierarchy) ─────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                       // Primary Action (Taller card)
                      _buildActionCard(
                        context: context,
                        title: 'CHECKLISTS',
                        subtitle: 'EXECUÇÃO DE MANUTENÇÃO',
                        icon: Icons.checklist_rounded,
                        accentColor: const Color(0xFF0055FF), // Tech blue
                        height: 180, // Dominant vertical presence
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(nome: nome, perfil: perfil))),
                      ),
                      const SizedBox(height: 16),
                      
                      // Secondary Actions
                      _buildActionCard(
                        context: context,
                        title: 'MÁQUINAS',
                        subtitle: 'BASE DE EQUIPAMENTOS',
                        icon: Icons.precision_manufacturing_outlined,
                        accentColor: const Color(0xFFCCFF00), // Acid green
                        height: 140,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaquinasScreen(perfil: perfil))),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildActionCard(
                        context: context,
                        title: 'RELATÓRIOS',
                        subtitle: 'MÉTRICAS E CONTADORES',
                        icon: Icons.bar_chart_rounded,
                        accentColor: const Color(0xFFFF4500), // Signal orange
                        height: 140,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelatorioScreen(tecnico: nome))),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      Center(
                        child: Text(
                          'DMPE — HU LONDRINA © 2025\nSYS_VERSION 1.0.4',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.15),
                            fontSize: 10,
                            fontFamily: 'Courier',
                            letterSpacing: 1.5,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF13151E),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5), 
          borderRadius: BorderRadius.circular(4), // Tech Brutalist geometry (very hard edge)
        ),
        child: Stack(
          children: [
            // Background Ghost Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 130,
                color: accentColor.withOpacity(0.04),
              ),
            ),
            // Accent Strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: accentColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    icon,
                    color: accentColor,
                    size: 36,
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: 'Courier',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Interaction Chevon
            Positioned(
              right: 20,
              top: 20,
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: accentColor.withOpacity(0.5),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF090A0F),
        surfaceTintColor: Colors.transparent, // Prevents Material 3 default color shifts
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
          borderRadius: BorderRadius.circular(4), // Brutalist edges
        ),
        title: const Text(
          'SYS.LOGOUT',
          style: TextStyle(
            color: Color(0xFFFF4500), 
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'Deseja encerrar a sessão atual e retornar à tela de autenticação?',
          style: TextStyle(
            color: Colors.white70, 
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4500),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'CONFIRMAR', 
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
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
  }
}