import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _senhaController   = TextEditingController();
  bool _loading       = false;
  bool _senhaVisivel  = false;
  bool _primeiroLogin = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _verificarPrimeiroLogin();
  }

  Future<void> _verificarPrimeiroLogin() async {
    final jaLogou = await ApiService.jaLogouHoje();
    setState(() => _primeiroLogin = !jaLogou);
  }

  Future<void> _fazerLogin() async {
    setState(() {
      _loading = true;
      _erro    = null;
    });

    final resultado = await ApiService.login(
      usuario: _usuarioController.text.trim(),
      senha  : _senhaController.text.trim(),
    );

    setState(() => _loading = false);

    if (resultado['sucesso'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            nome  : resultado['nome']   ?? '',
            perfil: resultado['perfil'] ?? '',
          ),
        ),
      );
    } else {
      setState(() => _erro = resultado['mensagem'] ?? 'ERRO INESPERADO. TENTE NOVAMENTE.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // Deep tech black
      body: Stack(
        children: [
          // Watermark Anti-Safe Harbor
          Positioned(
            top: -20,
            left: -15,
            child: Text(
              'AUTH',
              style: TextStyle(
                fontSize: 180,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.04),
                letterSpacing: -10,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── BANNER PRIMEIRO LOGIN (TECH STYLE) ──────────────────────
                    if (_primeiroLogin)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0055FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF0055FF),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              color: Color(0xFF0055FF),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'PRIMEIRA CONEXÃO DO DIA\nLOGIN ONLINE OBRIGATÓRIO.',
                                style: TextStyle(
                                  color     : Color(0xFF0055FF),
                                  fontSize  : 12,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── ÍCONE BRUTALIST ──────────────────────────────────────
                    Container(
                      width : 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color : const Color(0xFFCCFF00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFCCFF00),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        size : 40,
                        color: Color(0xFFCCFF00),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── TÍTULO ─────────────────────────────────────
                    const Text(
                      'PMOC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color      : Colors.white,
                        fontSize   : 48,
                        fontWeight : FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'SYS.MANUTENÇÃO E CONTROLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color    : Colors.white.withOpacity(0.5),
                        fontSize : 12,
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── CARD DE LOGIN (HARD EDGES) ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color        : const Color(0xFF13151E),
                        borderRadius : BorderRadius.circular(4),
                        border       : Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 0,
                            offset: Offset(4, 4), // Hard drop shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [

                          // ── CAMPO USUÁRIO ────────────────────────
                          TextField(
                            controller: _usuarioController,
                            style     : const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText : 'MATRÍCULA / USUÁRIO',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: Colors.white54,
                              ),
                              filled     : true,
                              fillColor  : const Color(0xFF090A0F),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0), // Sharp
                                borderSide  : BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide  : const BorderSide(
                                  color: Color(0xFFCCFF00),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── CAMPO SENHA ──────────────────────────
                          TextField(
                            controller : _senhaController,
                            obscureText: !_senhaVisivel,
                            style      : const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration : InputDecoration(
                              labelText : 'SENHA DE ACESSO',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              prefixIcon: const Icon(
                                Icons.password_rounded,
                                color: Colors.white54,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel,
                                ),
                              ),
                              filled    : true,
                              fillColor : const Color(0xFF090A0F),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide  : BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide  : const BorderSide(
                                  color: Color(0xFFCCFF00),
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _fazerLogin(),
                          ),

                          const SizedBox(height: 16),

                          // ── MENSAGEM DE ERRO ─────────────────────
                          if (_erro != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical  : 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color : const Color(0xFFFF4500).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(0),
                                border: Border.all(
                                  color: const Color(0xFFFF4500),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFFF4500),
                                    size : 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _erro!.toUpperCase(),
                                      style: const TextStyle(
                                        color   : Color(0xFFFF4500),
                                        fontSize: 12,
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // ── BOTÃO ENTRAR ─────────────────────────
                          SizedBox(
                            width : double.infinity,
                            height: 56,
                            child : ElevatedButton(
                              onPressed: _loading ? null : _fazerLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00), // Acid green
                                foregroundColor: Colors.black, // Dark text on bright button
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                elevation: 0,
                                disabledBackgroundColor: const Color(0xFFCCFF00).withOpacity(0.5),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width : 22,
                                      height: 22,
                                      child : CircularProgressIndicator(
                                        color      : Colors.black,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'AUTENTICAR',
                                      style: TextStyle(
                                        fontSize     : 16,
                                        fontWeight   : FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── RODAPÉ ─────────────────────────────────────
                    Text(
                      'DMPE — HU LONDRINA © 2025\nSYS_VERSION 1.0.4',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color   : Colors.white.withOpacity(0.15),
                        fontSize: 10,
                        fontFamily: 'Courier',
                        letterSpacing: 1.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}