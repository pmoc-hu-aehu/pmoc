import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checklist_corretiva.dart';

class ChecklistCorretivaService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbzj3kxjMABcWcaIMCoW0MLMpN7sgmy5L4Z_KN2Q7E3wknlHG-cNnjcikPxrytCQy4OjpQ/exec';

  static Future<String?> enviarChecklist(ChecklistCorretiva c) async {
    final payload = {
      'action'                   : 'SALVAR_CORRETIVA',
      'dataInicio'               : _fmt(c.dataInicio),
      'horaInicio'               : _hora(c.dataInicio),
      'dataFinal'                : _fmt(c.dataFinal),
      'horaFinal'                : _hora(c.dataFinal),
      'tecnico'                  : c.tecnico,
      'fuel'                     : c.fuel,
      'localizacao'              : c.localizacao,
      'coordenadasGps'           : c.coordenadasGps,
      'linkFotoInicio'           : c.linkFotoInicio ?? '',
      'descDefeito'              : c.descDefeito,
      'causaProvavel'            : c.causaProvavel,
      'servicoRealizado'         : c.servicoRealizado,
      'pecasTrocadas'            : c.pecasTrocadas,
      'nfRequisicao'             : c.nfRequisicao,
      'chkIsolamentoOk'          : c.chkIsolamentoOk ? 'SIM' : 'NÃO',
      'metrosIsolamentoTrocados' : c.metrosIsolamentoTrocados ?? '',
      'chkHigienePos'            : c.chkHigienePos ? 'SIM' : 'NÃO',
      'tensaoV'                  : c.tensaoV ?? '',
      'correnteA'                : c.correnteA ?? '',
      'pressaoPsi'               : c.pressaoPsi ?? '',
      'tempInsuflamento'         : c.tempInsuflamento ?? '',
      'linkFotoFinal'            : c.linkFotoFinal ?? '',
      'statusOperacional'        : c.equipamentoOperacional ? 'OPERACIONAL' : 'INOPERANTE',
      'motivoInoperancia'        : c.motivoInoperancia ?? '',
      'nomeChefe'                : c.nomeChefe,
      'chapaFuncional'           : c.chapaFuncional,
      'linkAssinatura'           : c.linkAssinatura ?? '',
      'statusGeral'              : c.statusGeral,
    };
    return enviarPayload(payload);
  }

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
          if (redirected.statusCode == 200 &&
              redirected.body.trim().startsWith('{')) {
            return redirected.body;
          }
        } catch (_) {}
      }
      return '{"sucesso":true,"msg":"Salvo"}';
    }
    return response.body;
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  static String _hora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
