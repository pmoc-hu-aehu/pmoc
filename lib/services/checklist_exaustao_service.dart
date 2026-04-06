import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checklist_exaustao.dart';

class ChecklistExaustaoService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbzaIeuS9NH8oluMTUiMmpFBpTWprh87RfER2GeDQc04fWWsx9Ci8ltGfLEfo0wnRNvy1g/exec';

  // ───────────────────── ENVIO DIRETO (ONLINE) ─────────────────────

  static Future<String?> enviarChecklist(ChecklistExaustao checklist) async {
    // Split GPS "lat, lon" em campos separados que o GAS espera
    final gpsParts = checklist.coordenadasGps.split(',');
    final lat = gpsParts.isNotEmpty ? gpsParts[0].trim() : '';
    final lon = gpsParts.length > 1 ? gpsParts[1].trim() : '';

    final payload = {
      'action'              : 'SALVAR_EXAUSTAO',
      // Datas como ISO UTC — GAS usa new Date() para calcular hora
      'dataInicio'          : checklist.dataInicio.toUtc().toIso8601String(),
      'dataFinal'           : checklist.dataFinal.toUtc().toIso8601String(),
      'tecnico'             : checklist.tecnico,
      'fuel'                : checklist.fuel,
      'local'               : checklist.localizacao,       // GAS: payload.local
      'latitude'            : lat,                          // GAS: payload.latitude
      'longitude'           : lon,                          // GAS: payload.longitude
      'tipoEquipamento'     : checklist.tipoEquip,         // GAS: payload.tipoEquipamento
      // Booleans — GAS converte para SIM/NÃO internamente
      'limpezaRotor'        : checklist.chkLimpezaRotor,
      // correias = string já processada (GAS usa || "" sem ternário)
      'correias'            : _chkStr(checklist.chkCorreias, checklist.obsCorreias),
      'lubrificacao'        : checklist.chkLubrificacao,
      'fixacaoVibracao'     : checklist.chkVibracao,
      'sensoresAcionamento' : checklist.chkSensAcionamento,
      'tensaoV'             : checklist.tensaoV     ?? '',
      'correnteA'           : checklist.correnteA   ?? '',
      'velocidadeAr'        : checklist.velocidadeArMs ?? '', // GAS: payload.velocidadeAr
      'filtrosTelas'        : checklist.chkFiltrosTelas,
      'statusEquipamento'   : checklist.statusEquip,       // GAS: payload.statusEquipamento
      // Fotos serão vazias no envio direto (offline queue envia base64)
      'fotoInicialB64'      : '',
      'fotoServicoB64'      : '',
      'fotoFinalB64'        : '',
      'nomeChefe'           : checklist.nomeChefe,
      'chapaFuncional'      : checklist.chapaFuncional,
      'assinaturaB64'       : '',
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

  /// correias é tratado como string pelo GAS (usa || "" não ternário)
  static String _chkStr(bool valor, String? obs) {
    if (!valor && obs != null && obs.isNotEmpty) return obs;
    return valor ? 'SIM' : 'NÃO';
  }
}
