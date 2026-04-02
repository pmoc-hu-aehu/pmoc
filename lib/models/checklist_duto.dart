class ChecklistDuto {
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;

  final String? linkFotoInicial;      // LINK_FOTO_SUJA na planilha
  final bool chkDanosIsolamento;      // CHK_DANOS_ISOLAMENTO
  final String? obsDanosIsolamento;

  final bool chkLimpezaRobo;          // CHK_LIMPEZA_ROBO
  final String? obsLimpezaRobo;

  final bool chkGrelhasDifusores;     // CHK_GRELHAS_DIFUSORES
  final String? obsGrelhasDifusores;

  final bool chkSelosInspecao;        // CHK_SELOS_INSPECAO
  final String? obsSelosInspecao;

  final bool chkUmidadeMofo;          // CHK_UMIDADE_MOFO
  final String? obsUmidadeMofo;

  final double? tempSaidaDuto;        // TEMP_SAIDA_DUTO
  final String? linkFotoFinal;        // LINK_FOTO_LIMPA na planilha
  final String? observacoes;          // OBSERVACOES
  final String statusGeral;           // STATUS_GERAL

  // Dados extras da máquina
  final String modelo;
  final String marca;
  final String serie;

  const ChecklistDuto({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.fuel,
    required this.localizacao,
    required this.coordenadasGps,
    required this.linkFotoInicial,
    required this.chkDanosIsolamento,
    required this.obsDanosIsolamento,
    required this.chkLimpezaRobo,
    required this.obsLimpezaRobo,
    required this.chkGrelhasDifusores,
    required this.obsGrelhasDifusores,
    required this.chkSelosInspecao,
    required this.obsSelosInspecao,
    required this.chkUmidadeMofo,
    required this.obsUmidadeMofo,
    required this.tempSaidaDuto,
    required this.linkFotoFinal,
    required this.observacoes,
    required this.statusGeral,
    required this.modelo,
    required this.marca,
    required this.serie,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataInicio'         : dataInicio.toIso8601String(),
      'dataFinal'          : dataFinal.toIso8601String(),
      'tecnico'            : tecnico,
      'fuel'               : fuel,
      'localizacao'        : localizacao,
      'coordenadasGps'     : coordenadasGps,
      'linkFotoInicial'    : linkFotoInicial,
      'chkDanosIsolamento' : chkDanosIsolamento,
      'obsDanosIsolamento' : obsDanosIsolamento,
      'chkLimpezaRobo'     : chkLimpezaRobo,
      'obsLimpezaRobo'     : obsLimpezaRobo,
      'chkGrelhasDifusores': chkGrelhasDifusores,
      'obsGrelhasDifusores': obsGrelhasDifusores,
      'chkSelosInspecao'   : chkSelosInspecao,
      'obsSelosInspecao'   : obsSelosInspecao,
      'chkUmidadeMofo'     : chkUmidadeMofo,
      'obsUmidadeMofo'     : obsUmidadeMofo,
      'tempSaidaDuto'      : tempSaidaDuto,
      'linkFotoFinal'      : linkFotoFinal,
      'observacoes'        : observacoes,
      'statusGeral'        : statusGeral,
      'modelo'             : modelo,
      'marca'              : marca,
      'serie'              : serie,
    };
  }

  factory ChecklistDuto.fromJson(Map<String, dynamic> json) {
    return ChecklistDuto(
      dataInicio          : DateTime.parse(json['dataInicio'] as String),
      dataFinal           : DateTime.parse(json['dataFinal'] as String),
      tecnico             : json['tecnico'] as String,
      fuel                : json['fuel'] as String,
      localizacao         : json['localizacao'] as String,
      coordenadasGps      : json['coordenadasGps'] as String,
      linkFotoInicial     : json['linkFotoInicial'] as String?,
      chkDanosIsolamento  : json['chkDanosIsolamento'] as bool,
      obsDanosIsolamento  : json['obsDanosIsolamento'] as String?,
      chkLimpezaRobo      : json['chkLimpezaRobo'] as bool,
      obsLimpezaRobo      : json['obsLimpezaRobo'] as String?,
      chkGrelhasDifusores : json['chkGrelhasDifusores'] as bool,
      obsGrelhasDifusores : json['obsGrelhasDifusores'] as String?,
      chkSelosInspecao    : json['chkSelosInspecao'] as bool,
      obsSelosInspecao    : json['obsSelosInspecao'] as String?,
      chkUmidadeMofo      : json['chkUmidadeMofo'] as bool,
      obsUmidadeMofo      : json['obsUmidadeMofo'] as String?,
      tempSaidaDuto       : (json['tempSaidaDuto'] as num?)?.toDouble(),
      linkFotoFinal       : json['linkFotoFinal'] as String?,
      observacoes         : json['observacoes'] as String?,
      statusGeral         : json['statusGeral'] as String,
      modelo              : json['modelo'] as String,
      marca               : json['marca'] as String,
      serie               : json['serie'] as String,
    );
  }
}