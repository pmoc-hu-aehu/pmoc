import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbyIc94AQeK-A-t4Cb6MiSH6fDJMTfngMyXRiUys8lrVIPh750AwmxhafdS9h29S4Q85XA/exec';

  static const String _keyUsuario         = 'pmoc_usuario';
  static const String _keySenha           = 'pmoc_senha';
  static const String _keyNome            = 'pmoc_nome';
  static const String _keyPerfil          = 'pmoc_perfil';
  static const String _keyUltimoLoginData = 'pmoc_ultimo_login_data';

  // ─── Verifica se hoje já teve login online ────────────────────────────────
  static Future<bool> jaLogouHoje() async {
    final prefs      = await SharedPreferences.getInstance();
    final ultimaData = prefs.getString(_keyUltimoLoginData) ?? '';
    return ultimaData == _dataHoje();
  }

  // ─── Data de hoje no formato yyyy-MM-dd ───────────────────────────────────
  static String _dataHoje() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ─── LOGIN PRINCIPAL ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String usuario,
    required String senha,
  }) async {
    final jaLogou = await jaLogouHoje();
    if (jaLogou) {
      return _loginOffline(usuario, senha);
    }
    return _loginOnline(usuario, senha);
  }

  // ─── LOGIN OFFLINE ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _loginOffline(
    String usuario,
    String senha,
  ) async {
    final prefs        = await SharedPreferences.getInstance();
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
          'action' : 'LOGIN',
          'usuario': usuario,
          'senha'  : senha,
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['sucesso'] == true) {
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
  static Future<void> logout() async {
    // Intencional: não limpa cache — mantém login offline válido
  }

  // ─── LISTAR MÁQUINAS ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listarMaquinas() async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {'action': 'LISTAR_MAQUINAS'},
      );

      print('[API] Chamando LISTAR_MAQUINAS: $uri');

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 30));

      print('[API] Status: ${response.statusCode}');
      print('[API] Body (primeiros 300 chars): ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['sucesso'] == true && data['maquinas'] != null) {
          final lista = List<Map<String, dynamic>>.from(
            (data['maquinas'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
          print('[API] Máquinas recebidas: ${lista.length}');
          return lista;
        } else {
          print('[API] Resposta sem sucesso: ${data['mensagem']}');
        }
      }
      return [];
    } catch (e) {
      print('[API] Erro em listarMaquinas: $e');
      return [];
    }
  }

  // ─── VERIFICAR LIMPEZA NO MÊS ────────────────────────────────────────────
  // Retorna: {'jaLimpa': bool, 'autorizado': bool}
  // Em caso de erro de conexão, retorna jaLimpa: false (não bloqueia offline)
  static Future<Map<String, bool>> verificarLimpezaMes(String fuel, String tipo) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {'action': 'VERIFICAR_LIMPEZA_MES', 'fuel': fuel, 'tipo': tipo},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucesso'] == true) {
          return {
            'jaLimpa'   : data['jaLimpa']   == true,
            'autorizado': data['autorizado'] == true,
          };
        }
      }
    } catch (_) {}
    return {'jaLimpa': false, 'autorizado': false};
  }
}