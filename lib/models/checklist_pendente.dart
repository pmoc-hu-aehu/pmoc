class ChecklistPendente {
  final int?   id;
  final String tipo;          // 'FILTRO', 'PREVENTIVA', etc.
  final String payloadJson;   // JSON dos campos do checklist (sem base64 das fotos)
  final String? fotoSujaPath;     // caminho permanente da foto inicial (ou foto de início)
  final String? fotoLimpaPath;    // caminho permanente da foto final (ou foto de processo para preventiva)
  final String? fotoProcessoPath; // NOVO: caminho permanente da foto de processo (para preventiva)
  final String? fotoFinalPath;    // NOVO: caminho permanente da foto final (para preventiva/corretiva)
  final String? assinaturaPath;   // NOVO: caminho permanente da assinatura
  final DateTime criadoEm;

  ChecklistPendente({
    this.id,
    required this.tipo,
    required this.payloadJson,
    this.fotoSujaPath,
    this.fotoLimpaPath, // Para filtro/duto é a foto final, para preventiva é a foto de processo
    this.fotoProcessoPath, // Para preventiva, a foto de processo
    this.fotoFinalPath,    // Para preventiva/corretiva, a foto final
    this.assinaturaPath,   // Para preventiva/corretiva, a assinatura
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'tipo'           : tipo,
    'payload_json'   : payloadJson,
    'foto_suja_path' : fotoSujaPath,
    'foto_limpa_path': fotoLimpaPath, // Mantido para compatibilidade com filtro/duto
    'foto_processo_path': fotoProcessoPath, // Novo campo para SQLite
    'foto_final_path': fotoFinalPath,      // Novo campo para SQLite
    'assinatura_path': assinaturaPath,     // Novo campo para SQLite
    'criado_em'      : criadoEm.toIso8601String(),
  };

  factory ChecklistPendente.fromMap(Map<String, dynamic> map) => ChecklistPendente(
    id           : map['id'] as int?,
    tipo         : map['tipo'] as String,
    payloadJson  : map['payload_json'] as String,
    fotoSujaPath : map['foto_suja_path'] as String?,
    fotoLimpaPath: map['foto_limpa_path'] as String?, // Mantido para compatibilidade
    fotoProcessoPath: map['foto_processo_path'] as String?, // Novo campo
    fotoFinalPath: map['foto_final_path'] as String?,      // Novo campo
    assinaturaPath: map['assinatura_path'] as String?,     // Novo campo
    criadoEm     : DateTime.parse(map['criado_em'] as String),
  );
}
