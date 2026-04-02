import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/maquina.dart';
import '../models/checklist_pendente.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'pmoc.db');
    print('[DB] Inicializando banco em: $path');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _criarTabelas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Adiciona tabela de fila offline sem apagar dados existentes
          await _criarTabelaPendentes(db);
        }
      },
      onOpen: (db) async {
        print('[DB] Banco aberto. Verificando tabelas...');
        // Garante que as tabelas existem mesmo se algo deu errado antes
        await _criarTabelas(db);
      },
    );
  }

  static Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maquinas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        fuel        TEXT NOT NULL UNIQUE,
        localizacao TEXT,
        modelo      TEXT,
        marca       TEXT,
        serie       TEXT,
        criticidade TEXT,
        capacidade  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        chave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''');

    await _criarTabelaPendentes(db);
  }

  static Future<void> _criarTabelaPendentes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklist_pendente (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo           TEXT NOT NULL,
        payload_json   TEXT NOT NULL,
        foto_suja_path TEXT,
        foto_limpa_path TEXT,
        criado_em      TEXT NOT NULL
      )
    ''');
  }

  // ─── FILA OFFLINE ─────────────────────────────────────────────────────────
  static Future<int> salvarPendente(ChecklistPendente p) async {
    final database = await db;
    return database.insert('checklist_pendente', p.toMap());
  }

  static Future<List<ChecklistPendente>> listarPendentes() async {
    final database = await db;
    final rows = await database.query('checklist_pendente', orderBy: 'criado_em ASC');
    return rows.map(ChecklistPendente.fromMap).toList();
  }

  static Future<int> contarPendentes() async {
    final database = await db;
    final result = await database.rawQuery('SELECT COUNT(*) as total FROM checklist_pendente');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> removerPendente(int id) async {
    final database = await db;
    await database.delete('checklist_pendente', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SALVAR MÁQUINAS ──────────────────────────────────────────────────────
  static Future<void> salvarMaquinas(List<Maquina> maquinas) async {
    final database = await db;
    print('[DB] Salvando ${maquinas.length} máquinas...');

    final batch = database.batch();
    batch.delete('maquinas');

    for (final m in maquinas) {
      batch.insert(
        'maquinas',
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('[DB] Máquinas salvas com sucesso');
  }

  // ─── BUSCAR POR FUEL ──────────────────────────────────────────────────────
  static Future<Maquina?> buscarPorFuel(String fuel) async {
    final database = await db;
    final result   = await database.query(
      'maquinas',
      where    : 'fuel = ?',
      whereArgs: [fuel.trim()],
      limit    : 1,
    );

    if (result.isEmpty) return null;
    return Maquina.fromMap(result.first);
  }

  // ─── TODAS AS MÁQUINAS ────────────────────────────────────────────────────
  static Future<List<Maquina>> todasMaquinas() async {
    final database = await db;
    final result   = await database.query(
      'maquinas',
      orderBy: 'localizacao, modelo',
    );
    return result.map((m) => Maquina.fromMap(m)).toList();
  }

  // ─── TOTAL DE MÁQUINAS ────────────────────────────────────────────────────
  static Future<int> totalMaquinas() async {
    final database = await db;
    final result   = await database.rawQuery(
      'SELECT COUNT(*) as total FROM maquinas',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── CONFIG ───────────────────────────────────────────────────────────────
  static Future<void> salvarConfig(String chave, String valor) async {
    final database = await db;
    await database.insert(
      'config',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> lerConfig(String chave) async {
    final database = await db;
    final result   = await database.query(
      'config',
      where    : 'chave = ?',
      whereArgs: [chave],
      limit    : 1,
    );
    if (result.isEmpty) return null;
    return result.first['valor'] as String?;
  }
}