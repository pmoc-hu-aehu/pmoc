import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'database_service.dart';
// import 'package:logger/logger.dart'; // Adicione ao pubspec.yaml
// final _logger = Logger();
import '../models/maquina.dart';

class SyncService {
  static const String _keyUltimaSync = 'pmoc_ultima_sync_maquinas';

  // ─── Verifica conexão ─────────────────────────────────────────────────────
  static Future<bool> temConexao() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final online  = results.any((r) => r != ConnectivityResult.none);
      print('[SYNC] Conexão: $online ($results)');
      return online;
    } catch (e) {
      print('[SYNC] Erro ao verificar conexão: $e');
      return false;
    }
  }

  // ─── Sincroniza máquinas GAS → banco local ────────────────────────────────
  static Future<SyncResult> sincronizarMaquinas() async {
    final online = await temConexao();
    if (!online) {
      print('[SYNC] Sem conexão — abortando sync');
      return SyncResult(
        sucesso : false,
        mensagem: 'Sem conexão com a internet.',
        total   : 0,
      );
    }

    try {
      print('[SYNC] Iniciando sincronização de máquinas...');
      final lista = await ApiService.listarMaquinas();
      print('[SYNC] Lista recebida com ${lista.length} itens');

      if (lista.isEmpty) {
        return SyncResult(
          sucesso : false,
          mensagem: 'Nenhuma máquina retornada pelo servidor.',
          total   : 0,
        );
      }

      final maquinas = lista.map((m) => Maquina.fromMap(m)).toList();
      await DatabaseService.salvarMaquinas(maquinas);
      print('[SYNC] Máquinas salvas no banco local: ${maquinas.length}');

      // Salva data/hora da última sync
      final agora    = DateTime.now();
      final dataHora =
          '${agora.day.toString().padLeft(2, '0')}/'
          '${agora.month.toString().padLeft(2, '0')}/'
          '${agora.year} '
          '${agora.hour.toString().padLeft(2, '0')}:'
          '${agora.minute.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUltimaSync, dataHora);
      print('[SYNC] Última sync salva: $dataHora');

      return SyncResult(
        sucesso : true,
        mensagem: 'Sincronização concluída.',
        total   : maquinas.length,
      );
    } catch (e) {
      print('[SYNC] Erro na sincronização: $e');
      return SyncResult(
        sucesso : false,
        mensagem: 'Erro: $e',
        total   : 0,
      );
    }
  }

  // ─── Última sincronização ─────────────────────────────────────────────────
  static Future<String> ultimaSincronizacao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUltimaSync) ?? 'Nunca sincronizado';
  }
}

class SyncResult {
  final bool   sucesso;
  final String mensagem;
  final int    total;

  SyncResult({
    required this.sucesso,
    required this.mensagem,
    required this.total,
  });
}