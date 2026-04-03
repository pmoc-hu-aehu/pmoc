import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checklist_preventiva.dart';

class ChecklistPreventivaService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbzj3kxjMABcWcaIMCoW0MLMpN7sgmy5L4Z_KN2Q7E3wknlHG-cNnjcikPxrytCQy4OjpQ/exec';

  // ───────────────────── ENVIO DIRETO (ONLINE) ─────────────────────

  /// Envia o checklist de preventiva para o Apps Script.
  /// Retorna null em caso de sucesso ou uma String com a mensagem de erro.
  static Future<String?> enviarChecklist(ChecklistPreventiva checklist) async {
    final payload = {
      'action'                      : 'SALVAR_PREVENTIVA',
      'dataInicio'                  : _formatarData(checklist.dataInicio),
      'horaInicio'                  : _formatarHora(checklist.dataInicio),
      'dataFinal'                   : _formatarData(checklist.dataFinal),
      'horaFinal'                   : _formatarHora(checklist.dataFinal),
      'tecnico'                     : checklist.tecnico,
      'fuel'                        : checklist.fuel,
      'localizacao'                 : checklist.localizacao,
      'coordenadasGps'              : checklist.coordenadasGps,
      // EVAPORADORA — chaves alinhadas com os cabeçalhos da planilha (GAS)
      'linkFotoInicio'              : checklist.linkFotoEvapSuja ?? '',
      'chkDesmontagem'              : _chk(checklist.chkDesmontagemEvap, checklist.obsDesmontagemEvap),
      'chkLavagemQuimica'           : _chk(checklist.chkLavagemEvap, checklist.obsLavagemEvap),
      'chkDrenoBandeja'             : _chk(checklist.chkDrenoBandeja, checklist.obsDrenoBandeja),
      'chkAntibactericida'          : _chk(checklist.chkAntibactericida, checklist.obsAntibactericida),
      'chkRuidoVibracao'            : _chk(checklist.chkRuidoEvap, checklist.obsRuidoEvap, problemaQuandoSim: true),
      'chkVazamento'                : _chk(checklist.chkVazamento, checklist.obsVazamento, problemaQuandoSim: true),
      'chkEletrica'                 : _chk(checklist.chkEletrica, checklist.obsEletrica),
      'chkIsolamentoOk'             : _chk(checklist.chkIsolamentoOk, checklist.obsIsolamentoOk),
      'metrosIsolamentoTrocados'    : checklist.metrosIsolamento ?? '',
      // FOTOS (3 slots da planilha)
      'linkFotoProcesso'            : checklist.linkFotoEvapLimpa ?? '',
      'linkFotoFinal'               : checklist.linkFotoCondLimpa ?? '',
      // CONDENSADORA — medições elétricas
      'tensaoV'                     : checklist.tensaoV ?? '',
      'correnteA'                   : checklist.correnteA ?? '',
      'pressaoPsi'                  : checklist.pressaoPsi ?? '',
      'tempRetorno'                 : checklist.tempRetorno ?? '',
      'tempInsuflamento'            : checklist.tempInsuflamento ?? '',
      // FINAL
      'observacoes'                 : checklist.observacoesTecnicas ?? '',
      'nomeChefe'                   : checklist.nomeChefe,
      'chapaFuncional'              : checklist.chapaFuncional,
      'linkAssinatura'              : checklist.linkAssinatura ?? '',
      'statusGeral'                 : checklist.statusGeral,
      'modelo'                      : checklist.modelo,
      'marca'                       : checklist.marca,
      'serie'                       : checklist.serie,
    };

    return enviarPayload(payload);
  }

  // ───────────────────── ENVIO POR PAYLOAD (FILA OFFLINE) ─────────────────────

  /// Envia um payload já montado (usado pela fila offline).
  /// O payload já deve conter `action`, fotos em base64 e todos os campos.
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

  /// Se há problema (false para normal, true para problemaQuandoSim) e há observação, envia a observação.
  /// Caso contrário envia "SIM" ou "NÃO".
  static String _chk(bool valor, String? obs, {bool problemaQuandoSim = false}) {
    final temProblema = problemaQuandoSim ? valor : !valor;
    if (temProblema && obs != null && obs.isNotEmpty) return obs;
    return valor ? 'SIM' : 'NÃO';
  }
}