class ChecklistQualidadeAr {
  // ── Cabeçalho ──────────────────────────────────────────────────
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String   tecnico;
  final String   codSala;        // → FUEL (código da sala)
  final String   pontoColeta;    // → LOCALIZACAO (descrição do ponto/sala)
  final String   coordenadasGps; // → COORDENADAS_GPS

  // ── Tipo de coleta ─────────────────────────────────────────────
  final String tipoColeta; // Semestral de Rotina / Pós-Obras / Suspeita de Surto

  // ── Medições ───────────────────────────────────────────────────
  final double? co2Ppm;
  final double? umidadeRelativa;
  final double? temperatura;
  final double? velocidadeAr;

  // ── Outros campos ──────────────────────────────────────────────
  final String  materialParticulado;     // Limpo / Poeira em suspensão
  final String  idAmostraMicrobiologica; // Número do lacre/tubo
  final String? dataProximaAnalise;      // Data calculada ou inserida
  final String  statusQualidade;         // Dentro dos Padrões RE 09 / Acima do Limite

  // ── Foto ───────────────────────────────────────────────────────
  final String? linkFotoColeta;

  // ── Seção Final ────────────────────────────────────────────────
  final String  observacoes;
  final String  nomeChefSetor;
  final String  chapaFuncional;
  final String? linkAssinatura;

  const ChecklistQualidadeAr({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.codSala,
    required this.pontoColeta,
    required this.coordenadasGps,
    required this.tipoColeta,
    this.co2Ppm,
    this.umidadeRelativa,
    this.temperatura,
    this.velocidadeAr,
    required this.materialParticulado,
    required this.idAmostraMicrobiologica,
    this.dataProximaAnalise,
    required this.statusQualidade,
    this.linkFotoColeta,
    required this.observacoes,
    required this.nomeChefSetor,
    required this.chapaFuncional,
    this.linkAssinatura,
  });

  Map<String, dynamic> toJson() => {
    'dataInicio'             : dataInicio.toIso8601String(),
    'dataFinal'              : dataFinal.toIso8601String(),
    'tecnico'                : tecnico,
    'codSala'                : codSala,
    'pontoColeta'            : pontoColeta,
    'coordenadasGps'         : coordenadasGps,
    'tipoColeta'             : tipoColeta,
    'co2Ppm'                 : co2Ppm,
    'umidadeRelativa'        : umidadeRelativa,
    'temperatura'            : temperatura,
    'velocidadeAr'           : velocidadeAr,
    'materialParticulado'    : materialParticulado,
    'idAmostraMicrobiologica': idAmostraMicrobiologica,
    'dataProximaAnalise'     : dataProximaAnalise,
    'statusQualidade'        : statusQualidade,
    'linkFotoColeta'         : linkFotoColeta,
    'observacoes'            : observacoes,
    'nomeChefSetor'          : nomeChefSetor,
    'chapaFuncional'         : chapaFuncional,
    'linkAssinatura'         : linkAssinatura,
  };
}
