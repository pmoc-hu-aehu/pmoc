import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbx-8tvC4s9PRpml1SaQ1zsuAIEZrC7eAeVuuHJt8G56Du645tX87DW7IIUaLDFFto7lTA/exec';

  static const String _keyUsuario         = 'pmoc_usuario';
  static const String _keySenha           = 'pmoc_senha';
  static const String _keyNome            = 'pmoc_nome';
  static const String _keyPerfil          = 'pmoc_perfil';
  static const String _keyUltimoLoginData = 'pmoc_ultimo_login_data';

  // ─── Verifica se hoje já teve login online ────────────────────────────────
  static Future<bool> jaLogouHoje() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaData = prefs.getString(_keyUltimoLoginData) ?? '';
    final hoje = _dataHoje();
    return ultimaData == hoje;
  }

  // ─── Data de hoje no formato yyyy-MM-dd ───────────────────────────────────
  static String _dataHoje() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // ─── LOGIN PRINCIPAL ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String usuario,
    required String senha,
  }) async {
    final jaLogou = await jaLogouHoje();

    // ── OFFLINE: já logou online hoje ──────────────────────────────────────
    if (jaLogou) {
      return _loginOffline(usuario, senha);
    }

    // ── ONLINE: primeiro login do dia ──────────────────────────────────────
    return _loginOnline(usuario, senha);
  }

  // ─── LOGIN OFFLINE ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _loginOffline(
    String usuario,
    String senha,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioSalvo = prefs.getString(_keyUsuario) ?? '';
    final senhaSalva   = prefs.getString(_keySenha)   ?? '';
    final nomeSalvo    = prefs.getString(_keyNome)     ?? '';
    final perfilSalvo  = prefs.getString(_keyPerfil)   ?? '';

    if (usuario == usuarioSalvo && senha == senhaSalva) {
      return {
        'sucesso': true,
        'nome'   : nomeSalvo,
        'perfil' : perfilSalvo,
        'offline': true,
      };
    }

    return {
      'sucesso' : false,
      'mensagem': 'Usuário ou senha incorretos (modo offline).',
    };
  }

  // ─── LOGIN ONLINE ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _loginOnline(
    String usuario,
    String senha,
  ) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'action'  : 'LOGIN',
          'usuario' : usuario,
          'senha'   : senha,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['sucesso'] == true) {
          // Salva sessão local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUsuario,         usuario);
          await prefs.setString(_keySenha,           senha);
          await prefs.setString(_keyNome,            data['nome']   ?? '');
          await prefs.setString(_keyPerfil,          data['perfil'] ?? '');
          await prefs.setString(_keyUltimoLoginData, _dataHoje());

          return {
            'sucesso': true,
            'nome'   : data['nome']   ?? '',
            'perfil' : data['perfil'] ?? '',
            'offline': false,
          };
        }

        return {
          'sucesso' : false,
          'mensagem': data['mensagem'] ?? 'Usuário ou senha incorretos.',
        };
      }

      return {
        'sucesso' : false,
        'mensagem': 'Erro no servidor (${response.statusCode}).',
      };

    } catch (e) {
      return {
        'sucesso' : false,
        'mensagem': 'Sem conexão. Tente novamente.',
      };
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  // Não apaga os dados — apenas deixa o usuário voltar para a LoginScreen.
  // Os dados offline continuam válidos até a meia-noite.
  static Future<void> logout() async {
    // Intencional: não limpa nada, só navega de volta.
  }
}