import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';

import '../models/checklist_filtro.dart';
import '../models/checklist_duto.dart';
import '../models/checklist_preventiva.dart';
import '../models/checklist_corretiva.dart';
import '../models/checklist_pressao.dart';
import '../models/checklist_qualidade_ar.dart';
import '../models/checklist_movimentacao.dart';
import '../models/checklist_exaustao.dart';
import '../models/checklist_pendente.dart';
import '../models/checklist_tipo.dart'; // Assuming you have a ChecklistType enum or similar
import 'checklist_filtro_service.dart';
import 'checklist_duto_service.dart';
import 'checklist_preventiva_service.dart';
import 'checklist_corretiva_service.dart';
import 'checklist_pressao_service.dart';
import 'checklist_exaustao_service.dart';
import 'database_service.dart';
import 'sync_service.dart';

class OfflineQueueService {
  // ───────────────────── FILTRO ─────────────────────

  /// Salva checklist de filtro offline:
  /// move as fotos para diretório permanente e enfileira no SQLite.
  static Future<void> salvarFiltroOffline({
    // Refatoração: Criar um helper genérico para salvar offline
    // que lida com a cópia de fotos e salvamento no DB.
    // Isso reduziria a duplicação entre os métodos salvar*Offline.
    // Por enquanto, focando na correção do modelo.
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
        tipo         : ChecklistType.filtro.name,
        payloadJson  : jsonEncode(payload),
        fotoSujaPath : sujaFinal,
        fotoLimpaPath: limpaFinal,
        criadoEm     : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.filtro.name);
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
        tipo         : ChecklistType.duto.name,
        payloadJson  : jsonEncode(payload),
        fotoSujaPath : inicialFinal,
        fotoLimpaPath: finalFinal,
        criadoEm     : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.duto.name);
  }

  // ───────────────────── PREVENTIVA ─────────────────────

  /// Salva checklist de preventiva offline:
  /// move as fotos para diretório permanente e enfileira no SQLite.
  static Future<void> salvarPreventivaOffline({
    required ChecklistPreventiva checklist,
    required String fotoEvapSujaPath,
    required String fotoEvapLimpaPath,
    required String fotoCondSujaPath,
    required String fotoCondLimpaPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir   = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final evapSujaFinal   = '${docsDir.path}/pmoc_${timestamp}_prev_evap_suja.jpg';
    final evapLimpaFinal  = '${docsDir.path}/pmoc_${timestamp}_prev_evap_limpa.jpg';
    final condSujaFinal   = '${docsDir.path}/pmoc_${timestamp}_prev_cond_suja.jpg';
    final condLimpaFinal  = '${docsDir.path}/pmoc_${timestamp}_prev_cond_limpa.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_prev_assinatura.png';

    await File(fotoEvapSujaPath).copy(evapSujaFinal);
    await File(fotoEvapLimpaPath).copy(evapLimpaFinal);
    await File(fotoCondSujaPath).copy(condSujaFinal);
    await File(fotoCondLimpaPath).copy(condLimpaFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    final payload = checklist.toJson()
      ..remove('linkFotoEvapSuja')
      ..remove('linkFotoEvapLimpa')
      ..remove('linkFotoCondSuja')
      ..remove('linkFotoCondLimpa')
      ..remove('linkAssinatura');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo          : ChecklistType.preventiva.name,
        payloadJson   : jsonEncode(payload),
        fotoSujaPath  : evapSujaFinal,
        fotoLimpaPath : evapLimpaFinal,
        fotoProcessoPath: condSujaFinal,
        fotoFinalPath : condLimpaFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm      : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.preventiva.name);
  }

  // ───────────────────── CORRETIVA ─────────────────────

  static Future<void> salvarCorretivaOffline({
    required ChecklistCorretiva checklist,
    required String fotoInicioPath,
    required String fotoFinalPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir   = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final inicioFinal    = '${docsDir.path}/pmoc_${timestamp}_corretiva_inicio.jpg';
    final finalFinal     = '${docsDir.path}/pmoc_${timestamp}_corretiva_final.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_corretiva_assinatura.png';

    await File(fotoInicioPath).copy(inicioFinal);
    await File(fotoFinalPath).copy(finalFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    // Remover links do payload, pois serão enviados como base64
    final payload = checklist.toJson()
      ..remove('linkFotoInicio')
      ..remove('linkFotoFinal')
      ..remove('linkAssinatura');

    // Salvar todos os caminhos no ChecklistPendente
    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo: ChecklistType.corretiva.name,
        payloadJson: jsonEncode(payload),
        fotoSujaPath: inicioFinal,
        fotoLimpaPath: finalFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm: DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.corretiva.name);
  }

  // ───────────────────── MOVIMENTAÇÃO ─────────────────────

  static Future<void> salvarMovimentacaoOffline({
    required ChecklistMovimentacao checklist,
    required String fotoOrigemPath,
    required String fotoDestinoPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir    = await getApplicationDocumentsDirectory();
    final timestamp  = DateTime.now().millisecondsSinceEpoch;

    final origemFinal    = '${docsDir.path}/pmoc_${timestamp}_mov_origem.jpg';
    final destinoFinal   = '${docsDir.path}/pmoc_${timestamp}_mov_destino.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_mov_assinatura.png';

    await File(fotoOrigemPath).copy(origemFinal);
    await File(fotoDestinoPath).copy(destinoFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    final payload = checklist.toJson()
      ..remove('linkFotoOrigem')
      ..remove('linkFotoDestino')
      ..remove('linkAssinatura');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo          : ChecklistType.movimentacao.name,
        payloadJson   : jsonEncode(payload),
        fotoSujaPath  : origemFinal,
        fotoLimpaPath : destinoFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm      : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.movimentacao.name);
  }

  // ───────────────────── QUALIDADE DO AR ─────────────────────

  static Future<void> salvarQualidadeArOffline({
    required ChecklistQualidadeAr checklist,
    required String fotoColetaPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir    = await getApplicationDocumentsDirectory();
    final timestamp  = DateTime.now().millisecondsSinceEpoch;

    final coletaFinal    = '${docsDir.path}/pmoc_${timestamp}_qar_coleta.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_qar_assinatura.png';

    await File(fotoColetaPath).copy(coletaFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    final payload = checklist.toJson()
      ..remove('linkFotoColeta')
      ..remove('linkAssinatura');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo          : ChecklistType.qualidadeAr.name,
        payloadJson   : jsonEncode(payload),
        fotoSujaPath  : coletaFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm      : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.codSala, ChecklistType.qualidadeAr.name);
  }

  // ───────────────────── EXAUSTÃO ─────────────────────

  static Future<void> salvarExaustaoOffline({
    required ChecklistExaustao checklist,
    required String fotoInicioPath,
    String? fotoServicopath,
    required String fotoFinalPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir   = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final inicioFinal     = '${docsDir.path}/pmoc_${timestamp}_exaustao_inicio.jpg';
    final finalFinal      = '${docsDir.path}/pmoc_${timestamp}_exaustao_final.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_exaustao_assinatura.png';

    await File(fotoInicioPath).copy(inicioFinal);
    await File(fotoFinalPath).copy(finalFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    String? servicoFinal;
    if (fotoServicopath != null) {
      servicoFinal = '${docsDir.path}/pmoc_${timestamp}_exaustao_servico.jpg';
      await File(fotoServicopath).copy(servicoFinal);
    }

    final payload = checklist.toJson()
      ..remove('linkFotoInicio')
      ..remove('linkFotoServico')
      ..remove('linkFotoFinal')
      ..remove('linkAssinatura');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo          : ChecklistType.exaustao.name,
        payloadJson   : jsonEncode(payload),
        fotoSujaPath  : inicioFinal,
        fotoLimpaPath : servicoFinal,
        fotoFinalPath : finalFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm      : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.fuel, ChecklistType.exaustao.name);
  }

  // ───────────────────── PRESSÃO ─────────────────────

  static Future<void> salvarPressaoOffline({
    required ChecklistPressao checklist,
    required String fotoManometroPath,
    String? fotoVedacaoPath,
    required Uint8List assinaturaByte,
  }) async {
    final docsDir    = await getApplicationDocumentsDirectory();
    final timestamp  = DateTime.now().millisecondsSinceEpoch;

    final manometroFinal  = '${docsDir.path}/pmoc_${timestamp}_pressao_manometro.jpg';
    final assinaturaSalva = '${docsDir.path}/pmoc_${timestamp}_pressao_assinatura.png';

    await File(fotoManometroPath).copy(manometroFinal);
    await File(assinaturaSalva).writeAsBytes(assinaturaByte);

    String? vedacaoFinal;
    if (fotoVedacaoPath != null) {
      vedacaoFinal = '${docsDir.path}/pmoc_${timestamp}_pressao_vedacao.jpg';
      await File(fotoVedacaoPath).copy(vedacaoFinal);
    }

    final payload = checklist.toJson()
      ..remove('linkFotoManometro')
      ..remove('linkFotoVedacao')
      ..remove('linkAssinatura');

    await DatabaseService.salvarPendente(
      ChecklistPendente(
        tipo          : ChecklistType.pressao.name,
        payloadJson   : jsonEncode(payload),
        fotoSujaPath  : manometroFinal,
        fotoLimpaPath : vedacaoFinal,
        assinaturaPath: assinaturaSalva,
        criadoEm      : DateTime.now(),
      ),
    );
    await DatabaseService.registrarManutencao(checklist.tecnico, checklist.codSala, ChecklistType.pressao.name);
  }

  // ───────────────────── PROCESSAR FILA ─────────────────────

  /// Processa a fila: envia todos os checklists pendentes
  /// (FILTRO, DUTO e PREVENTIVA) e apaga as fotos do celular após envio.
  /// Retorna o número de itens enviados com sucesso.
  static Future<int> processarFila() async {
    final online = await SyncService.temConexao();
    if (!online) return 0;

    final pendentes = await DatabaseService.listarPendentes();
    var enviados = 0;

    for (final p in pendentes) {
      try {
        if (p.tipo == ChecklistType.filtro.name) {
          enviados += await _enviarFiltro(p);
        } else if (p.tipo == ChecklistType.duto.name) {
          enviados += await _enviarDuto(p);
        } else if (p.tipo == ChecklistType.preventiva.name) {
          enviados += await _enviarPreventiva(p);
        } else if (p.tipo == ChecklistType.corretiva.name) {
          enviados += await _enviarCorretiva(p);
        } else if (p.tipo == ChecklistType.pressao.name) {
          enviados += await _enviarPressao(p);
        } else if (p.tipo == ChecklistType.qualidadeAr.name) {
          enviados += await _enviarQualidadeAr(p);
        } else if (p.tipo == ChecklistType.movimentacao.name) {
          enviados += await _enviarMovimentacao(p);
        } else if (p.tipo == ChecklistType.exaustao.name) {
          enviados += await _enviarExaustao(p);
        } else {
          debugPrint('[OFFLINE_QUEUE] Tipo desconhecido: ${p.tipo}');
        }
      } catch (e) {
        debugPrint('[OFFLINE_QUEUE] Erro ao sincronizar id=${p.id}: $e');
      }
    }

    return enviados;
  }

  // ───────────────────── HELPERS PRIVADOS ─────────────────────

  static Future<int> _enviarFiltro(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    _formatAndTransformPayload(payload, [
      {'field': 'chkDesligado',    'problemWhenTrue': false},
      {'field': 'chkLavado',       'problemWhenTrue': false},
      {'field': 'chkEscova',       'problemWhenTrue': false},
      {'field': 'chkSecagem',      'problemWhenTrue': false},
      {'field': 'chkIntegridade',  'problemWhenTrue': false},
      {'field': 'chkLimpezaExt',   'problemWhenTrue': false},
      {'field': 'chkRecolocado',   'problemWhenTrue': false},
      {'field': 'chkDry',          'problemWhenTrue': false},
      {'field': 'chkAmbiente',     'problemWhenTrue': false},
      {'field': 'chkDreno',        'problemWhenTrue': false},
    ]);

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
      // Apagar todas as fotos associadas a este pendente
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar FILTRO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarDuto(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    _formatAndTransformPayload(payload, [
      {'field': 'chkDanosIsolamento', 'problemWhenTrue': true},
      {'field': 'chkLimpezaRobo',      'problemWhenTrue': false},
      {'field': 'chkGrelhasDifusores', 'problemWhenTrue': false},
      {'field': 'chkSelosInspecao',    'problemWhenTrue': false},
      {'field': 'chkUmidadeMofo',      'problemWhenTrue': true},
    ]); // <-- Parêntese de fechamento adicionado aqui

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
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar DUTO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarPreventiva(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    _formatAndTransformPayload(payload, [
      {'field': 'chkDesmontagemEvap', 'problemWhenTrue': false},
      {'field': 'chkLavagemEvap',     'problemWhenTrue': false},
      {'field': 'chkDrenoBandeja',    'problemWhenTrue': false},
      {'field': 'chkAntibactericida', 'problemWhenTrue': false},
      {'field': 'chkRuidoEvap',       'problemWhenTrue': true},
      {'field': 'chkIsolamentoOk',    'problemWhenTrue': false},
      {'field': 'chkDesmontagemCond', 'problemWhenTrue': false},
      {'field': 'chkLavagemCond',     'problemWhenTrue': false},
      {'field': 'chkRuidoCond',       'problemWhenTrue': true},
      {'field': 'chkVazamento',       'problemWhenTrue': true},
      {'field': 'chkEletrica',        'problemWhenTrue': false},
      {'field': 'chkIsolamentoOk',    'problemWhenTrue': false},
    ]);

    // Renomeia chaves para bater com os cabeçalhos da planilha (GAS)
    void renomear(String de, String para) {
      if (payload.containsKey(de)) {
        payload[para] = payload.remove(de);
      }
    }
    renomear('chkDesmontagemEvap', 'chkDesmontagem');
    renomear('chkLavagemEvap',     'chkLavagemQuimica');
    renomear('chkRuidoEvap',       'chkRuidoVibracao');
    renomear('metrosIsolamento',   'metrosIsolamentoTrocados');
    // Remove campos da condensadora sem coluna na planilha
    payload.remove('chkDesmontagemCond');
    payload.remove('obsDesmontagemCond');
    payload.remove('chkLavagemCond');
    payload.remove('obsLavagemCond');
    payload.remove('chkRuidoCond');
    payload.remove('obsRuidoCond');

    // Anexa fotos como base64 com as chaves esperadas pela planilha
    // linkFotoInicio   = evap suja
    // linkFotoProcesso = evap limpa
    // linkFotoFinal    = cond limpa
    Future<void> anexar(String? path, String campo) async {
      if (path == null) return;
      final f = File(path);
      if (await f.exists()) {
        payload[campo] = base64Encode(await f.readAsBytes());
      }
    }

    await anexar(p.fotoSujaPath,     'linkFotoInicio');
    await anexar(p.fotoLimpaPath,    'linkFotoProcesso');
    await anexar(p.fotoFinalPath,    'linkFotoFinal');
    await anexar(p.assinaturaPath,   'linkAssinatura');

    payload['action'] = 'SALVAR_PREVENTIVA';

    final erro = await ChecklistPreventivaService.enviarPayload(payload);

    if (erro == null) {
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar PREVENTIVA id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarCorretiva(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    _formatAndTransformPayload(payload, []); // Corretiva tem lógica de transformação diferente

    // Foto inicial
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['linkFotoInicio'] = base64Encode(await f.readAsBytes());
      }
    }
    // Foto final
    if (p.fotoLimpaPath != null) {
      final f = File(p.fotoLimpaPath!);
      if (await f.exists()) {
        payload['linkFotoFinal'] = base64Encode(await f.readAsBytes());
      }
    }

    // Carrega assinatura do novo campo em ChecklistPendente
    if (p.assinaturaPath != null) {
      final assinatura = File(p.assinaturaPath!);
      if (await assinatura.exists()) {
        payload['linkAssinatura'] = base64Encode(await assinatura.readAsBytes());
      } else {
        debugPrint('[OFFLINE_QUEUE] Assinatura não encontrada: ${p.assinaturaPath}');
      }
    }

    payload['action'] = 'SALVAR_CORRETIVA';
    // Lógica de transformação específica para Corretiva (mantida aqui por enquanto)
    _transformCorretivaPayloadSpecifics(payload);


    final erro = await ChecklistCorretivaService.enviarPayload(payload);

    if (erro == null) {
      _apagarFoto(p.fotoSujaPath);
      _apagarFoto(p.fotoLimpaPath);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar CORRETIVA id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarPressao(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    // ── Datas: mantém ISO 8601 — o GAS faz new Date(payload.dataInicio)
    // NÃO chamar _formatAndTransformPayload pois converteria para dd/MM/yyyy
    // e new Date("04/03/2026") retorna meia-noite (hora errada).

    // ── Remapeia chaves para o padrão do GAS (Especiais.js) ─────────
    payload['fuel']       = payload['codSala'] ?? '';
    // GAS usa 'local' diretamente para LOCALIZACAO — mantém como está
    payload['conformidade']  = payload['chkConformidade'];
    payload['vedacaoPortas'] = payload['chkVedacaoPorras'];
    payload['molaporta']     = payload['chkMolaPorta'];
    payload['filtroHepa']    = payload['chkFiltroHepa'] ?? '';
    payload['nomeChefe']     = payload['nomeChefSetor'] ?? '';
    payload['observacoes']   = payload['observacoesTecnicas'] ?? '';

    // Separa coordenadasGps em latitude e longitude para o GAS
    final gps = (payload['coordenadasGps'] as String?) ?? '';
    if (gps.contains(',')) {
      final parts = gps.split(',');
      payload['latitude']  = parts[0].trim();
      payload['longitude'] = parts[1].trim();
    }

    // Remove chaves que o GAS não usa
    payload.remove('codSala');
    payload.remove('zona');
    payload.remove('tipoInspecao');
    payload.remove('chkConformidade');
    payload.remove('chkVedacaoPorras');
    payload.remove('chkMolaPorta');
    payload.remove('chkFiltroHepa');
    payload.remove('nomeChefSetor');
    payload.remove('observacoesTecnicas');
    payload.remove('coordenadasGps');
    payload.remove('obsFotoVedacao');
    payload.remove('versaoChecklist');
    payload.remove('idChecklist');

    // ── Fotos em base64 com as chaves que o GAS espera ──────────────
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['fotoManometroB64'] = base64Encode(await f.readAsBytes());
      }
    }
    if (p.assinaturaPath != null) {
      final f = File(p.assinaturaPath!);
      if (await f.exists()) {
        payload['assinaturaB64'] = base64Encode(await f.readAsBytes());
      }
    }
    // Foto vedação não é usada pelo GAS atual — ignora

    payload['action'] = 'SALVAR_PRESSAO';

    final erro = await ChecklistPressaoService.enviarPayload(payload);

    if (erro == null) {
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar PRESSAO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarMovimentacao(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    // ── Remapeia chaves para o padrão do GAS (Especiais.js) ─────────
    payload['nomeChefe'] = payload['nomeChefSetor'] ?? '';

    // Monta obs com isolamento igual ao GAS
    final isolamento = payload['chkIsolamentoNecessario'] as bool? ?? false;
    final metros     = payload['metrosEstimados'];
    payload['chkIsolamentoNecessario'] = isolamento;
    payload['metrosEstimados']         = metros ?? '';

    payload.remove('nomeChefSetor');
    payload.remove('linkFotoOrigem');
    payload.remove('linkFotoDestino');
    payload.remove('linkAssinatura');

    // ── Fotos em base64 ─────────────────────────────────────────────
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['fotoOrigemB64'] = base64Encode(await f.readAsBytes());
      }
    }
    if (p.fotoLimpaPath != null) {
      final f = File(p.fotoLimpaPath!);
      if (await f.exists()) {
        payload['fotoDestinoB64'] = base64Encode(await f.readAsBytes());
      }
    }
    if (p.assinaturaPath != null) {
      final f = File(p.assinaturaPath!);
      if (await f.exists()) {
        payload['assinaturaB64'] = base64Encode(await f.readAsBytes());
      }
    }

    payload['action'] = 'SALVAR_RETIRADA_MAQUINA';

    final erro = await ChecklistPressaoService.enviarPayload(payload);

    if (erro == null) {
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar MOVIMENTACAO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarExaustao(ChecklistPendente p) async {
    final raw = Map<String, dynamic>.from(jsonDecode(p.payloadJson) as Map);

    // ── GPS: split "lat, lon" em campos separados ──────────────────
    final gps   = (raw['coordenadasGps'] as String?) ?? '';
    final parts = gps.split(',');
    final lat   = parts.isNotEmpty ? parts[0].trim() : '';
    final lon   = parts.length > 1 ? parts[1].trim() : '';

    // ── correias: único campo tratado como string pelo GAS ─────────
    final chkCorreias = raw['chkCorreias'] as bool? ?? false;
    final obsCorreias = raw['obsCorreias'] as String?;
    final correias    = (!chkCorreias && obsCorreias != null && obsCorreias.isNotEmpty)
        ? obsCorreias
        : (chkCorreias ? 'SIM' : 'NÃO');

    // ── Monta payload com chaves que o GAS espera ──────────────────
    final payload = <String, dynamic>{
      'action'              : 'SALVAR_EXAUSTAO',
      // Datas como ISO UTC — GAS usa new Date() para calcular hora
      'dataInicio'          : raw['dataInicio']          ?? '',
      'dataFinal'           : raw['dataFinal']           ?? '',
      'tecnico'             : raw['tecnico']             ?? '',
      'fuel'                : raw['fuel']                ?? '',
      'local'               : raw['localizacao']         ?? '',
      'latitude'            : lat,
      'longitude'           : lon,
      'tipoEquipamento'     : raw['tipoEquip']           ?? '',
      // Booleans — GAS converte para SIM/NÃO com ternário
      'limpezaRotor'        : raw['chkLimpezaRotor']     ?? false,
      'correias'            : correias,
      'lubrificacao'        : raw['chkLubrificacao']     ?? false,
      'fixacaoVibracao'     : raw['chkVibracao']         ?? false,
      'sensoresAcionamento' : raw['chkSensAcionamento']  ?? false,
      'tensaoV'             : raw['tensaoV']             ?? '',
      'correnteA'           : raw['correnteA']           ?? '',
      'velocidadeAr'        : raw['velocidadeArMs']      ?? '',
      'filtrosTelas'        : raw['chkFiltrosTelas']     ?? false,
      'statusEquipamento'   : raw['statusEquip']         ?? '',
      'nomeChefe'           : raw['nomeChefe']           ?? '',
      'chapaFuncional'      : raw['chapaFuncional']      ?? '',
    };

    // ── Fotos em base64 ────────────────────────────────────────────
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) payload['fotoInicialB64'] = base64Encode(await f.readAsBytes());
    }
    if (p.fotoLimpaPath != null) {
      final f = File(p.fotoLimpaPath!);
      if (await f.exists()) payload['fotoServicoB64'] = base64Encode(await f.readAsBytes());
    }
    if (p.fotoFinalPath != null) {
      final f = File(p.fotoFinalPath!);
      if (await f.exists()) payload['fotoFinalB64'] = base64Encode(await f.readAsBytes());
    }
    if (p.assinaturaPath != null) {
      final f = File(p.assinaturaPath!);
      if (await f.exists()) payload['assinaturaB64'] = base64Encode(await f.readAsBytes());
    }

    payload['action'] = 'SALVAR_EXAUSTAO';

    final erro = await ChecklistExaustaoService.enviarPayload(payload);

    if (erro == null) {
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar EXAUSTAO id=${p.id}: $erro');
    return 0;
  }

  static Future<int> _enviarQualidadeAr(ChecklistPendente p) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(p.payloadJson) as Map,
    );

    // ── Remapeia chaves para o padrão do GAS (Especiais.js) ─────────
    // GAS linha[5] = fuel → usa pontoColeta como identificador do local
    payload['fuel']             = payload['pontoColeta'] ?? '';
    // GAS linha[7] = localizacaoTexto → coordenadas GPS como string
    payload['localizacaoTexto'] = payload['coordenadasGps'] ?? '';
    payload['nomeChefe']        = payload['nomeChefSetor'] ?? '';

    // Monta campo obs[] igual ao GAS: junta particulado + próx. análise + obs
    final List<String> obs = [];
    if ((payload['materialParticulado'] as String?)?.isNotEmpty == true) {
      obs.add('Particulado: ${payload['materialParticulado']}');
    }
    if ((payload['dataProximaAnalise'] as String?)?.isNotEmpty == true) {
      obs.add('Próx. Análise: ${payload['dataProximaAnalise']}');
    }
    if ((payload['observacoes'] as String?)?.isNotEmpty == true) {
      obs.add('Obs: ${payload['observacoes']}');
    }
    payload['observacoes'] = obs.join(' | ');

    // Remove chaves que o GAS não usa
    payload.remove('codSala');
    payload.remove('coordenadasGps');
    payload.remove('nomeChefSetor');
    payload.remove('materialParticulado');
    payload.remove('dataProximaAnalise');
    payload.remove('linkFotoColeta');
    payload.remove('linkAssinatura');

    // ── Fotos em base64 ─────────────────────────────────────────────
    if (p.fotoSujaPath != null) {
      final f = File(p.fotoSujaPath!);
      if (await f.exists()) {
        payload['fotoColetaB64'] = base64Encode(await f.readAsBytes());
      }
    }
    if (p.assinaturaPath != null) {
      final f = File(p.assinaturaPath!);
      if (await f.exists()) {
        payload['assinaturaB64'] = base64Encode(await f.readAsBytes());
      }
    }

    payload['action'] = 'SALVAR_QUALIDADE_AR';

    final erro = await ChecklistPressaoService.enviarPayload(payload);

    if (erro == null) {
      _apagarFotosPendente(p);
      await DatabaseService.removerPendente(p.id!);
      return 1;
    }

    debugPrint('[OFFLINE_QUEUE] Falha ao enviar QUALIDADE_AR id=${p.id}: $erro');
    return 0;
  }

  /// Apaga todas as fotos associadas a um ChecklistPendente.
  static void _apagarFotosPendente(ChecklistPendente p) {
    _apagarFoto(p.fotoSujaPath);
    _apagarFoto(p.fotoLimpaPath);
    _apagarFoto(p.fotoProcessoPath); // Novo campo
    _apagarFoto(p.fotoFinalPath);     // Novo campo
    _apagarFoto(p.assinaturaPath);    // Novo campo
    // Se houver outros arquivos (e.g., metadados antigos), apagar aqui também
    // Mas a ideia é que com a mudança, não haverá mais arquivos de metadados separados.
    // Exemplo para apagar metadados antigos (se ainda existirem):
    // if (p.metadataPath != null) _apagarFoto(p.metadataPath);
  }

  /// Apaga um arquivo de foto se o caminho for válido e o arquivo existir.
  static void _apagarFoto(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (e) {
      debugPrint('[OFFLINE_QUEUE] Erro ao apagar foto $path: $e');
    }
  }

  /// Helper para transformar campos booleanos de checklist em strings
  /// e formatar datas.
  static void _formatAndTransformPayload(
      Map<String, dynamic> payload, List<Map<String, dynamic>> checkFieldsConfig) {
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
    _transformChecklistPayload(payload, checkFieldsConfig);
  }

  /// Lógica de transformação específica para ChecklistCorretiva
  static void _transformCorretivaPayloadSpecifics(Map<String, dynamic> payload) {
    // Converte booleanos em SIM/NÃO
    if (payload['chkIsolamentoOk'] is bool) {
      payload['chkIsolamentoOk'] = (payload['chkIsolamentoOk'] as bool) ? 'SIM' : 'NÃO';
    }
    if (payload['chkHigienePos'] is bool) {
      payload['chkHigienePos'] = (payload['chkHigienePos'] as bool) ? 'SIM' : 'NÃO';
    }
    if (payload['equipamentoOperacional'] is bool) {
      payload['statusOperacional'] = (payload['equipamentoOperacional'] as bool) ? 'OPERACIONAL' : 'INOPERANTE';
      payload.remove('equipamentoOperacional');
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
        payload[field] = 'Não respondido';
      } else if ((problemWhenTrue && chkValue == true && obsValue != null && obsValue.isNotEmpty) ||
                 (!problemWhenTrue && chkValue == false && obsValue != null && obsValue.isNotEmpty)) {
        payload[field] = obsValue;
      } else if (chkValue == true) {
        payload[field] = 'Sim';
      } else {
        payload[field] = 'Não';
      }
      payload.remove('obs${field.substring(3)}');
    }
  }

  // ───────────────────── CONTAGEM ─────────────────────

  static Future<int> contarPendentes() => DatabaseService.contarPendentes();
}