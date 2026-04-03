import 'dart:convert';
import 'package:http/http.dart' as http;

class ChecklistPressaoService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbzj3kxjMABcWcaIMCoW0MLMpN7sgmy5L4Z_KN2Q7E3wknlHG-cNnjcikPxrytCQy4OjpQ/exec';

  static Future<String?> enviarPayload(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final body = await _resolveBody(response);
      final data = jsonDecode(body);
      if (data['sucesso'] == true) return null;
      return data['mensagem'] ?? data['msg'] ?? 'GAS retornou sucesso: false';
    } catch (e) {
      return 'Erro: $e';
    }
  }

  static Future<String> _resolveBody(http.Response response) async {
    if (response.statusCode == 302) {
      final location = response.headers['location'];
      if (location != null) {
        try {
          final redirected = await http
              .get(Uri.parse(location))
              .timeout(const Duration(seconds: 20));
          if (redirected.statusCode == 200 && redirected.body.trim().startsWith('{')) {
            return redirected.body;
          }
        } catch (_) {}
      }
      return '{"sucesso":true,"msg":"Salvo"}';
    }
    return response.body;
  }
}
