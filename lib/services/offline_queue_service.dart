import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/checklist_filtro.dart';
import '../models/checklist_duto.dart';
import '../models/checklist_pendente.dart';
import 'checklist_filtro_service.dart';
import 'checklist_duto_service.dart';
import 'database_service.dart';
import 'sync_service.dart';

class OfflineQueueService {
  // ───────────────────── FILTRO ─────────────────────

  /// Salva checklist de filtro offline:
  /// move as fotos para diretório permanente e enfileira no SQLite.
  static Future<void> salvarFiltroOffline({
    required ChecklistFiltro checklist,
    required String fotoSujaPath,
    required String fotoLimpaPath,
  }) async {
    final docsDir   = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final sujaFinal  = '${docsDir.path}/pmoc_${timestamp}_filtro_suja.jpg';
    final limpaFinal = '${docsDir.path}/pmoc_${timestamp}_filtro_limpa.jpg';

    await File(fotoSujaPath).copy(sujaFinal);
    await File(fotoLimpaPath).copy(limpaFinal);

    final payload = checklist.toJson()
      ..remove('fotoSujaB64')
      ..remove('fotoLimpaB64');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo         : 'FILTRO',
        payloadJson  : jsonEncode(payload),
        fotoSujaPath : sujaFinal,
        fotoLimpaPath: limpaFinal,
        criadoEm     : DateTime.now(),
      ),
    );
  }

  // ───────────────────── DUTO ─────────────────────

  /// Salva checklist de duto offline:
  /// move as fotos para diretório permanente e enfileira no SQLite.
  static Future<void> salvarDutoOffline({
    required ChecklistDuto checklist,
    required String fotoInicialPath,
    required String fotoFinalPath,
  }) async {
    final docsDir   = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final inicialFinal = '${docsDir.path}/pmoc_${timestamp}_duto_inicial.jpg';
    final finalFinal   = '${docsDir.path}/pmoc_${timestamp}_duto_final.jpg';

    await File(fotoInicialPath).copy(inicialFinal);
    await File(fotoFinalPath).copy(finalFinal);

    final payload = checklist.toJson()
      ..remove('linkFotoInicial')
      ..remove('linkFotoFinal');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo         : 'DUTO',
        payloadJson  : jsonEncode(payload),
        fotoSujaPath : inicialFinal,
        fotoLimpaPath: finalFinal,
        criadoEm     : DateTime.now(),
      ),
    );
  }

  // ───────────────────── PROCESSAR FILA ─────────────────────

  /// Processa a fila: envia todos os checklists pendentes
  /// (FILTRO e DUTO) e apaga as fotos do celular após envio.
  /// Retorna o número de itens enviados com sucesso.
  static Future<int> processarFila() async {
    final online = await SyncService.temConexao();
    if (!online) return 0;

    final pendentes = await DatabaseService.listarPendentes();
    var enviados = 0;

    for (final p in pendentes) {
      try {
        if (p.tipo == 'FILTRO') {
          enviados += await _enviarFiltro(p);
        } else if (p.tipo == 'DUTO') {
          enviados += await _enviarDuto(p);
        } else {
          print('[OFFLINE_QUEUE] Tipo desconhecido: ${p.tipo}');
        }
      } catch (e) {
        print('[OFFLINE_QUEUE] Erro ao sincronizar id=${p.id}: $e');
      }
    }

    return enviados;
  }

  // ───────────────────── HELPERS PRIVADOS ─────────────────────

  static Future<int> _enviarFiltro(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    // Converte datas ISO 8601 para data/hora formatadas que o GAS espera
    if (payload['dataInicio'] != null) {
      final dt = DateTime.parse(payload['dataInicio'] as String);
      payload['dataInicio'] = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      payload['horaInicio'] = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    if (payload['dataFinal'] != null) {
      final dt = DateTime.parse(payload['dataFinal'] as String);
      payload['dataFinal'] = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      payload['horaFinal'] = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }

    // Transforma os campos booleanos de checklist em strings ('Sim', 'Não')
    // e substitui 'Não' pela observação se houver.
    final filtroCheckFieldsConfig = [
      {'field': 'chkDesligado',    'problemWhenTrue': false}, // Para filtros, 'Não' é sempre o problema
      {'field': 'chkLavado',       'problemWhenTrue': false},
      {'field': 'chkEscova',       'problemWhenTrue': false},
      {'field': 'chkSecagem',      'problemWhenTrue': false},
      {'field': 'chkIntegridade',  'problemWhenTrue': false},
      {'field': 'chkLimpezaExt',   'problemWhenTrue': false},
      {'field': 'chkRecolocado',   'problemWhenTrue': false},
      {'field': 'chkDry',          'problemWhenTrue': false},
      {'field': 'chkAmbiente',     'problemWhenTrue': false},
      {'field': 'chkDreno',        'problemWhenTrue': false},
    ];
    _transformChecklistPayload(payload, filtroCheckFieldsConfig);

    // Anexa fotos como base64
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['fotoSujaB64'] = base64Encode(await f.readAsBytes());
      }
    }
    if (p.fotoLimpaPath != null) {
      final f = File(p.fotoLimpaPath!);
      if (await f.exists()) {
        payload['fotoLimpaB64'] = base64Encode(await f.readAsBytes());
      }
    }

    payload['action'] = 'SALVAR_FILTRO';

    final erro = await ChecklistFiltroService.enviarPayload(payload);

    if (erro == null) {
      _apagarFoto(p.fotoSujaPath);
      _apagarFoto(p.fotoLimpaPath);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    print('[OFFLINE_QUEUE] Falha ao enviar FILTRO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarDuto(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    // Converte datas ISO 8601 para data/hora formatadas que o GAS espera
    if (payload['dataInicio'] != null) {
      final dt = DateTime.parse(payload['dataInicio'] as String);
      payload['dataInicio'] = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      payload['horaInicio'] = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    if (payload['dataFinal'] != null) {
      final dt = DateTime.parse(payload['dataFinal'] as String);
      payload['dataFinal'] = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      payload['horaFinal'] = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }

    // Transforma os campos booleanos de checklist em strings ('Sim', 'Não')
    // e substitui pela observação se houver, considerando 'problemaQuandoSim'.
    final dutoCheckFieldsConfig = [
      {'field': 'chkDanosIsolamento',  'problemWhenTrue': true},
      {'field': 'chkLimpezaRobo',      'problemWhenTrue': false},
      {'field': 'chkGrelhasDifusores', 'problemWhenTrue': false},
      {'field': 'chkSelosInspecao',    'problemWhenTrue': false},
      {'field': 'chkUmidadeMofo',      'problemWhenTrue': true},
    ];
    _transformChecklistPayload(payload, dutoCheckFieldsConfig);

    // Foto inicial (salva em fotoSujaPath)
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['linkFotoSuja'] = base64Encode(await f.readAsBytes());
      }
    }

    // Foto final (salva em fotoLimpaPath)
    if (p.fotoLimpaPath != null) {
      final f = File(p.fotoLimpaPath!);
      if (await f.exists()) {
        payload['linkFotoLimpa'] = base64Encode(await f.readAsBytes());
      }
    }

    payload['action'] = 'SALVAR_DUTO';

    final erro = await ChecklistDutoService.enviarPayload(payload);

    if (erro == null) {
      _apagarFoto(p.fotoSujaPath);
      _apagarFoto(p.fotoLimpaPath);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    print('[OFFLINE_QUEUE] Falha ao enviar DUTO id=${p.id}: $erro');
    return 0;
  }

  static void _apagarFoto(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (e) {
      print('[OFFLINE_QUEUE] Erro ao apagar foto $path: $e');
    }
  }

  /// Helper para transformar campos booleanos de checklist em strings
  /// e incluir a observação se a condição de "problema" for atendida.
  static void _transformChecklistPayload(
      Map<String, dynamic> payload, List<Map<String, dynamic>> checkFieldsConfig) {
    for (final config in checkFieldsConfig) {
      final field = config['field'] as String;
      final bool problemWhenTrue = config['problemWhenTrue'] as bool;

      final bool? chkValue = payload[field] as bool?;
      final String? obsValue = payload['obs${field.substring(3)}'] as String?;

      if (chkValue == null) {
        payload[field] = 'Não respondido'; // Caso o campo não tenha sido preenchido (embora a validação deva impedir)
      } else if ((problemWhenTrue && chkValue == true && obsValue != null && obsValue.isNotEmpty) ||
                 (!problemWhenTrue && chkValue == false && obsValue != null && obsValue.isNotEmpty)) {
        payload[field] = obsValue; // Envia o texto da observação
      } else if (chkValue == true) {
        payload[field] = 'Sim';
      } else { // chkValue == false (e a observação está vazia ou não é um problema)
        payload[field] = 'Não';
      }
      payload.remove('obs${field.substring(3)}'); // Remove o campo de observação separado
    }
  }

  // ───────────────────── CONTAGEM ─────────────────────

  static Future<int> contarPendentes() => DatabaseService.contarPendentes();
}