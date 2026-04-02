class ChecklistPendente {
  final int?   id;
  final String tipo;          // 'FILTRO', 'PREVENTIVA', etc.
  final String payloadJson;   // JSON dos campos do checklist (sem base64 das fotos)
  final String? fotoSujaPath; // caminho permanente da foto inicial
  final String? fotoLimpaPath;// caminho permanente da foto final
  final DateTime criadoEm;

  ChecklistPendente({
    this.id,
    required this.tipo,
    required this.payloadJson,
    this.fotoSujaPath,
    this.fotoLimpaPath,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'tipo'           : tipo,
    'payload_json'   : payloadJson,
    'foto_suja_path' : fotoSujaPath,
    'foto_limpa_path': fotoLimpaPath,
    'criado_em'      : criadoEm.toIso8601String(),
  };

  factory ChecklistPendente.fromMap(Map<String, dynamic> map) => ChecklistPendente(
    id           : map['id'] as int?,
    tipo         : map['tipo'] as String,
    payloadJson  : map['payload_json'] as String,
    fotoSujaPath : map['foto_suja_path'] as String?,
    fotoLimpaPath: map['foto_limpa_path'] as String?,
    criadoEm     : DateTime.parse(map['criado_em'] as String),
  );
}
