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
      setState(() => _erro = resultado['mensagem'] ?? 'Erro ao fazer login.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end  : Alignment.bottomCenter,
            colors: [
              Color(0xFF020617),
              Color(0xFF0f172a),
              Color(0xFF1e293b),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── BANNER PRIMEIRO LOGIN ──────────────────────
                  if (_primeiroLogin)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1d4ed8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3b82f6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_outlined,
                            color: Color(0xFF3b82f6),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Primeira conexão do dia — login online obrigatório.',
                              style: TextStyle(
                                color     : Color(0xFF93c5fd),
                                fontSize  : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── ÍCONE ──────────────────────────────────────
                  Container(
                    width : 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color : const Color(0xFF1d4ed8).withOpacity(0.2),
                      shape : BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3b82f6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size : 48,
                      color: Color(0xFF3b82f6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── TÍTULO ─────────────────────────────────────
                  const Text(
                    'PMOC DO HU LONDRINA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color      : Colors.white,
                      fontSize   : 22,
                      fontWeight : FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Manutenção, Operação e Controle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color    : Colors.white.withOpacity(0.45),
                      fontSize : 13,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── CARD DE LOGIN ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color        : const Color(0xFF0f172a),
                      borderRadius : BorderRadius.circular(20),
                      border       : Border.all(
                        color: const Color(0xFF1e3a5f),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color : Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        // ── CAMPO USUÁRIO ────────────────────────
                        TextField(
                          controller: _usuarioController,
                          style     : const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText : 'Usuário',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF3b82f6),
                            ),
                            filled     : true,
                            fillColor  : const Color(0xFF1e293b),
                            border     : OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide  : BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide  : const BorderSide(
                                color: Color(0xFF3b82f6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── CAMPO SENHA ──────────────────────────
                        TextField(
                          controller : _senhaController,
                          obscureText: !_senhaVisivel,
                          style      : const TextStyle(color: Colors.white),
                          decoration : InputDecoration(
                            hintText : 'Senha',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF3b82f6),
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
                            fillColor : const Color(0xFF1e293b),
                            border    : OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide  : BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide  : const BorderSide(
                                color: Color(0xFF3b82f6),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _fazerLogin(),
                        ),

                        const SizedBox(height: 12),

                        // ── MENSAGEM DE ERRO ─────────────────────
                        if (_erro != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical  : 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size : 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _erro!,
                                    style: const TextStyle(
                                      color   : Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // ── BOTÃO ENTRAR ─────────────────────────
                        SizedBox(
                          width : double.infinity,
                          height: 52,
                          child : ElevatedButton(
                            onPressed: _loading ? null : _fazerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1d4ed8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width : 22,
                                    height: 22,
                                    child : CircularProgressIndicator(
                                      color      : Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      fontSize     : 15,
                                      fontWeight   : FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── RODAPÉ ─────────────────────────────────────
                  Text(
                    'DMPE — HU Londrina © 2025',
                    style: TextStyle(
                      color   : Colors.white.withOpacity(0.2),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}