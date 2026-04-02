import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checklist_duto.dart';

class ChecklistDutoService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbyIc94AQeK-A-t4Cb6MiSH6fDJMTfngMyXRiUys8lrVIPh750AwmxhafdS9h29S4Q85XA/exec';

  // ───────────────────── ENVIO DIRETO (ONLINE) ─────────────────────

  static Future<String?> enviarChecklist(ChecklistDuto checklist) async {
    final payload = {
      'action'             : 'SALVAR_DUTO',
      'dataInicio'         : _formatarData(checklist.dataInicio),
      'horaInicio'         : _formatarHora(checklist.dataInicio),
      'dataFinal'          : _formatarData(checklist.dataFinal),
      'horaFinal'          : _formatarHora(checklist.dataFinal),
      'tecnico'            : checklist.tecnico,
      'fuel'               : checklist.fuel,
      'localizacao'        : checklist.localizacao,
      'coordenadasGps'     : checklist.coordenadasGps,
      'linkFotoSuja'       : checklist.linkFotoInicial  ?? '',
      'chkDanosIsolamento' : _chk(checklist.chkDanosIsolamento,  checklist.obsDanosIsolamento,  problemaQuandoSim: true),
      'chkLimpezaRobo'     : _chk(checklist.chkLimpezaRobo,      checklist.obsLimpezaRobo),
      'chkGrelhasDifusores': _chk(checklist.chkGrelhasDifusores,  checklist.obsGrelhasDifusores),
      'chkSelosInspecao'   : _chk(checklist.chkSelosInspecao,     checklist.obsSelosInspecao),
      'chkUmidadeMofo'     : _chk(checklist.chkUmidadeMofo,       checklist.obsUmidadeMofo,      problemaQuandoSim: true),
      'tempSaidaDuto'      : checklist.tempSaidaDuto        ?? '',
      'linkFotoLimpa'      : checklist.linkFotoFinal        ?? '',
      'observacoes'        : checklist.observacoes          ?? '',
      'statusGeral'        : checklist.statusGeral,
      'modelo'             : checklist.modelo,
      'marca'              : checklist.marca,
      'serie'              : checklist.serie,
    };

    return enviarPayload(payload);
  }

  // ───────────────────── ENVIO POR PAYLOAD (FILA OFFLINE) ─────────────────────

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

  // ───────────────────── HELPERS ─────────────────────

  static String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  static String _formatarHora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Se é problema (false para normal, true para problemaQuandoSim) e há observação, envia a observação.
  /// Caso contrário envia "SIM" ou "NÃO".
  static String _chk(bool valor, String? obs, {bool problemaQuandoSim = false}) {
    final temProblema = problemaQuandoSim ? valor : !valor;
    if (temProblema && obs != null && obs.isNotEmpty) return obs;
    return valor ? 'SIM' : 'NÃO';
  }
}