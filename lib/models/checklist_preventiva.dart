class ChecklistPreventiva {
  // ── Cabeçalho ──────────────────────────────────────────────────
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;

  // ── EVAPORADORA ────────────────────────────────────────────────
  final String? linkFotoEvapSuja;       // LINK_FOTO_INICIO
  final bool chkDesmontagemEvap;        // CHK_DESMONTAGEM
  final String? obsDesmontagemEvap;
  final bool chkLavagemEvap;            // CHK_LAVAGEM_QUIMICA
  final String? obsLavagemEvap;
  final bool chkDrenoBandeja;           // CHK_DRENO_BANDEJA
  final String? obsDrenoBandeja;
  final bool chkAntibactericida;        // CHK_ANTIBACTERICIDA
  final String? obsAntibactericida;
  final bool chkRuidoEvap;              // CHK_RUIDO_VIBRACAO
  final String? obsRuidoEvap;
  final String? linkFotoEvapLimpa;      // LINK_FOTO_PROCESSO

  // ── CONDENSADORA ───────────────────────────────────────────────
  final String? linkFotoCondSuja;
  final bool chkDesmontagemCond;
  final String? obsDesmontagemCond;
  final bool chkLavagemCond;
  final String? obsLavagemCond;
  final bool chkRuidoCond;
  final String? obsRuidoCond;
  final bool chkVazamento;              // CHK_VAZAMENTO
  final String? obsVazamento;
  final bool chkEletrica;               // CHK_ELETRICA
  final String? obsEletrica;
  final bool chkIsolamentoOk;           // CHK_ISOLAMENTO_OK
  final String? obsIsolamentoOk;
  final double? metrosIsolamento;       // METROS_ISOLAMENTO_TROCADOS
  final String? linkFotoCondLimpa;      // LINK_FOTO_FINAL
  final double? tensaoV;                // TENSAO_V
  final double? correnteA;              // CORRENTE_A
  final double? pressaoPsi;             // PRESSAO_PSI
  final double? tempRetorno;            // TEMP_RETORNO
  final double? tempInsuflamento;       // TEMP_INSUFLAMENTO

  // ── Seção Final ────────────────────────────────────────────────
  final String? observacoesTecnicas;    // OBSERVACOES
  final String nomeChefe;               // NOME_CHEFE_SETOR
  final String chapaFuncional;          // CHAPA_FUNCIONAL
  final String? linkAssinatura;         // LINK_ASSINATURA
  final String statusGeral;             // STATUS_GERAL

  // ── Dados da máquina ───────────────────────────────────────────
  final String modelo;
  final String marca;
  final String serie;

  const ChecklistPreventiva({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.fuel,
    required this.localizacao,
    required this.coordenadasGps,
    required this.linkFotoEvapSuja,
    required this.chkDesmontagemEvap,
    required this.obsDesmontagemEvap,
    required this.chkLavagemEvap,
    required this.obsLavagemEvap,
    required this.chkDrenoBandeja,
    required this.obsDrenoBandeja,
    required this.chkAntibactericida,
    required this.obsAntibactericida,
    required this.chkRuidoEvap,
    required this.obsRuidoEvap,
    required this.linkFotoEvapLimpa,
    required this.linkFotoCondSuja,
    required this.chkDesmontagemCond,
    required this.obsDesmontagemCond,
    required this.chkLavagemCond,
    required this.obsLavagemCond,
    required this.chkRuidoCond,
    required this.obsRuidoCond,
    required this.chkVazamento,
    required this.obsVazamento,
    required this.chkEletrica,
    required this.obsEletrica,
    required this.chkIsolamentoOk,
    required this.obsIsolamentoOk,
    required this.metrosIsolamento,
    required this.linkFotoCondLimpa,
    required this.tensaoV,
    required this.correnteA,
    required this.pressaoPsi,
    required this.tempRetorno,
    required this.tempInsuflamento,
    required this.observacoesTecnicas,
    required this.nomeChefe,
    required this.chapaFuncional,
    required this.linkAssinatura,
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
      'linkFotoEvapSuja'    : linkFotoEvapSuja,
      'chkDesmontagemEvap'  : chkDesmontagemEvap,
      'obsDesmontagemEvap'  : obsDesmontagemEvap,
      'chkLavagemEvap'      : chkLavagemEvap,
      'obsLavagemEvap'      : obsLavagemEvap,
      'chkDrenoBandeja'     : chkDrenoBandeja,
      'obsDrenoBandeja'     : obsDrenoBandeja,
      'chkAntibactericida'  : chkAntibactericida,
      'obsAntibactericida'  : obsAntibactericida,
      'chkRuidoEvap'        : chkRuidoEvap,
      'obsRuidoEvap'        : obsRuidoEvap,
      'linkFotoEvapLimpa'   : linkFotoEvapLimpa,
      'linkFotoCondSuja'    : linkFotoCondSuja,
      'chkDesmontagemCond'  : chkDesmontagemCond,
      'obsDesmontagemCond'  : obsDesmontagemCond,
      'chkLavagemCond'      : chkLavagemCond,
      'obsLavagemCond'      : obsLavagemCond,
      'chkRuidoCond'        : chkRuidoCond,
      'obsRuidoCond'        : obsRuidoCond,
      'chkVazamento'        : chkVazamento,
      'obsVazamento'        : obsVazamento,
      'chkEletrica'         : chkEletrica,
      'obsEletrica'         : obsEletrica,
      'chkIsolamentoOk'     : chkIsolamentoOk,
      'obsIsolamentoOk'     : obsIsolamentoOk,
      'metrosIsolamento'    : metrosIsolamento,
      'linkFotoCondLimpa'   : linkFotoCondLimpa,
      'tensaoV'             : tensaoV,
      'correnteA'           : correnteA,
      'pressaoPsi'          : pressaoPsi,
      'tempRetorno'         : tempRetorno,
      'tempInsuflamento'    : tempInsuflamento,
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

  factory ChecklistPreventiva.fromJson(Map<String, dynamic> json) {
    return ChecklistPreventiva(
      dataInicio          : DateTime.parse(json['dataInicio'] as String),
      dataFinal           : DateTime.parse(json['dataFinal'] as String),
      tecnico             : json['tecnico'] as String,
      fuel                : json['fuel'] as String,
      localizacao         : json['localizacao'] as String,
      coordenadasGps      : json['coordenadasGps'] as String,
      linkFotoEvapSuja    : json['linkFotoEvapSuja'] as String?,
      chkDesmontagemEvap  : json['chkDesmontagemEvap'] as bool,
      obsDesmontagemEvap  : json['obsDesmontagemEvap'] as String?,
      chkLavagemEvap      : json['chkLavagemEvap'] as bool,
      obsLavagemEvap      : json['obsLavagemEvap'] as String?,
      chkDrenoBandeja     : json['chkDrenoBandeja'] as bool,
      obsDrenoBandeja     : json['obsDrenoBandeja'] as String?,
      chkAntibactericida  : json['chkAntibactericida'] as bool,
      obsAntibactericida  : json['obsAntibactericida'] as String?,
      chkRuidoEvap        : json['chkRuidoEvap'] as bool,
      obsRuidoEvap        : json['obsRuidoEvap'] as String?,
      linkFotoEvapLimpa   : json['linkFotoEvapLimpa'] as String?,
      linkFotoCondSuja    : json['linkFotoCondSuja'] as String?,
      chkDesmontagemCond  : json['chkDesmontagemCond'] as bool,
      obsDesmontagemCond  : json['obsDesmontagemCond'] as String?,
      chkLavagemCond      : json['chkLavagemCond'] as bool,
      obsLavagemCond      : json['obsLavagemCond'] as String?,
      chkRuidoCond        : json['chkRuidoCond'] as bool,
      obsRuidoCond        : json['obsRuidoCond'] as String?,
      chkVazamento        : json['chkVazamento'] as bool,
      obsVazamento        : json['obsVazamento'] as String?,
      chkEletrica         : json['chkEletrica'] as bool,
      obsEletrica         : json['obsEletrica'] as String?,
      chkIsolamentoOk     : json['chkIsolamentoOk'] as bool,
      obsIsolamentoOk     : json['obsIsolamentoOk'] as String?,
      metrosIsolamento    : (json['metrosIsolamento'] as num?)?.toDouble(),
      linkFotoCondLimpa   : json['linkFotoCondLimpa'] as String?,
      tensaoV             : (json['tensaoV'] as num?)?.toDouble(),
      correnteA           : (json['correnteA'] as num?)?.toDouble(),
      pressaoPsi          : (json['pressaoPsi'] as num?)?.toDouble(),
      tempRetorno         : (json['tempRetorno'] as num?)?.toDouble(),
      tempInsuflamento    : (json['tempInsuflamento'] as num?)?.toDouble(),
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
