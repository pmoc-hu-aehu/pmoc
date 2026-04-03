class ChecklistExaustao {
  // ── Cabeçalho ──────────────────────────────────────────────────
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;

  // ── Identificação do Equipamento ───────────────────────────────
  final String tipoEquip;             // TIPO_EQUIP (axial, centrífugo, etc.)

  // ── Itens de Verificação ───────────────────────────────────────
  final bool chkLimpezaRotor;         // CHK_LIMPEZA_ROTOR
  final String? obsLimpezaRotor;
  final bool chkCorreias;             // CHK_CORREIAS
  final String? obsCorreias;
  final bool chkLubrificacao;         // CHK_LUBRIFICACAO
  final String? obsLubrificacao;
  final bool chkVibracao;             // CHK_VIBRACAO (problema quando true)
  final String? obsVibracao;
  final bool chkSensAcionamento;      // CHK_SENS_ACIONAMENTO
  final String? obsSensAcionamento;
  final bool chkFiltrosTelas;         // CHK_FILTROS_TELAS
  final String? obsFiltrosTelas;

  // ── Medições ───────────────────────────────────────────────────
  final double? tensaoV;              // TENSION_V
  final double? correnteA;            // CORRENTE_A
  final double? velocidadeArMs;       // VELOCIDADE_AR_MS

  // ── Status do Equipamento ──────────────────────────────────────
  final String statusEquip;           // STATUS_EQUIP (OK, PENDENTE, INOPERANTE)

  // ── Fotos ──────────────────────────────────────────────────────
  final String? linkFotoInicio;       // LINK_FOTO_INICIO
  final String? linkFotoServico;      // LINK_FOTO_SERVICO
  final String? linkFotoFinal;        // LINK_FOTO_FINAL

  // ── Seção Final ────────────────────────────────────────────────
  final String? observacoesTecnicas;
  final String nomeChefe;             // NOME_CHEFE_SETOR
  final String chapaFuncional;        // CHAPA_FUNCIONAL
  final String? linkAssinatura;       // LINK_ASSINATURA
  final String statusGeral;           // STATUS_GERAL

  // ── Dados da máquina ───────────────────────────────────────────
  final String modelo;
  final String marca;
  final String serie;

  const ChecklistExaustao({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.fuel,
    required this.localizacao,
    required this.coordenadasGps,
    required this.tipoEquip,
    required this.chkLimpezaRotor,
    this.obsLimpezaRotor,
    required this.chkCorreias,
    this.obsCorreias,
    required this.chkLubrificacao,
    this.obsLubrificacao,
    required this.chkVibracao,
    this.obsVibracao,
    required this.chkSensAcionamento,
    this.obsSensAcionamento,
    required this.chkFiltrosTelas,
    this.obsFiltrosTelas,
    this.tensaoV,
    this.correnteA,
    this.velocidadeArMs,
    required this.statusEquip,
    this.linkFotoInicio,
    this.linkFotoServico,
    this.linkFotoFinal,
    this.observacoesTecnicas,
    required this.nomeChefe,
    required this.chapaFuncional,
    this.linkAssinatura,
    required this.statusGeral,
    required this.modelo,
    required this.marca,
    required this.serie,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataInicio'          : dataInicio.toIso8601String(),
      'dataFinal'           : dataFinal.toIso8601String(),
      'tecnico'             : tecnico,
      'fuel'                : fuel,
      'localizacao'         : localizacao,
      'coordenadasGps'      : coordenadasGps,
      'tipoEquip'           : tipoEquip,
      'chkLimpezaRotor'     : chkLimpezaRotor,
      'obsLimpezaRotor'     : obsLimpezaRotor,
      'chkCorreias'         : chkCorreias,
      'obsCorreias'         : obsCorreias,
      'chkLubrificacao'     : chkLubrificacao,
      'obsLubrificacao'     : obsLubrificacao,
      'chkVibracao'         : chkVibracao,
      'obsVibracao'         : obsVibracao,
      'chkSensAcionamento'  : chkSensAcionamento,
      'obsSensAcionamento'  : obsSensAcionamento,
      'chkFiltrosTelas'     : chkFiltrosTelas,
      'obsFiltrosTelas'     : obsFiltrosTelas,
      'tensaoV'             : tensaoV,
      'correnteA'           : correnteA,
      'velocidadeArMs'      : velocidadeArMs,
      'statusEquip'         : statusEquip,
      'linkFotoInicio'      : linkFotoInicio,
      'linkFotoServico'     : linkFotoServico,
      'linkFotoFinal'       : linkFotoFinal,
      'observacoesTecnicas' : observacoesTecnicas,
      'nomeChefe'           : nomeChefe,
      'chapaFuncional'      : chapaFuncional,
      'linkAssinatura'      : linkAssinatura,
      'statusGeral'         : statusGeral,
      'modelo'              : modelo,
      'marca'               : marca,
      'serie'               : serie,
    };
  }

  factory ChecklistExaustao.fromJson(Map<String, dynamic> json) {
    return ChecklistExaustao(
      dataInicio          : DateTime.parse(json['dataInicio'] as String),
      dataFinal           : DateTime.parse(json['dataFinal'] as String),
      tecnico             : json['tecnico'] as String,
      fuel                : json['fuel'] as String,
      localizacao         : json['localizacao'] as String,
      coordenadasGps      : json['coordenadasGps'] as String,
      tipoEquip           : json['tipoEquip'] as String,
      chkLimpezaRotor     : json['chkLimpezaRotor'] as bool,
      obsLimpezaRotor     : json['obsLimpezaRotor'] as String?,
      chkCorreias         : json['chkCorreias'] as bool,
      obsCorreias         : json['obsCorreias'] as String?,
      chkLubrificacao     : json['chkLubrificacao'] as bool,
      obsLubrificacao     : json['obsLubrificacao'] as String?,
      chkVibracao         : json['chkVibracao'] as bool,
      obsVibracao         : json['obsVibracao'] as String?,
      chkSensAcionamento  : json['chkSensAcionamento'] as bool,
      obsSensAcionamento  : json['obsSensAcionamento'] as String?,
      chkFiltrosTelas     : json['chkFiltrosTelas'] as bool,
      obsFiltrosTelas     : json['obsFiltrosTelas'] as String?,
      tensaoV             : (json['tensaoV'] as num?)?.toDouble(),
      correnteA           : (json['correnteA'] as num?)?.toDouble(),
      velocidadeArMs      : (json['velocidadeArMs'] as num?)?.toDouble(),
      statusEquip         : json['statusEquip'] as String,
      linkFotoInicio      : json['linkFotoInicio'] as String?,
      linkFotoServico     : json['linkFotoServico'] as String?,
      linkFotoFinal       : json['linkFotoFinal'] as String?,
      observacoesTecnicas : json['observacoesTecnicas'] as String?,
      nomeChefe           : json['nomeChefe'] as String,
      chapaFuncional      : json['chapaFuncional'] as String,
      linkAssinatura      : json['linkAssinatura'] as String?,
      statusGeral         : json['statusGeral'] as String,
      modelo              : json['modelo'] as String,
      marca               : json['marca'] as String,
      serie               : json['serie'] as String,
    );
  }
}
