class ChecklistPreventiva {
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;

  final String? linkFotoInicio;           // LINK_FOTO_INICIO
  final bool chkDesmontagem;              // CHK_DESMONTAGEM
  final String? obsDesmontagem;
  final bool chkLavagemQuimica;           // CHK_LAVAGEM_QUIMICA
  final String? obsLavagemQuimica;
  final bool chkDrenoBandeja;             // CHK_DRENO_BANDEJA
  final String? obsDrenoBandeja;
  final bool chkAntibactericida;          // CHK_ANTIBACTERICIDA
  final String? obsAntibactericida;
  final bool chkRuidoVibracao;            // CHK_RUIDO_VIBRACAO
  final String? obsRuidoVibracao;
  final bool chkVazamento;                // CHK_VAZAMENTO
  final String? obsVazamento;
  final bool chkEletrica;                 // CHK_ELETRICA
  final String? obsEletrica;
  final bool chkIsolamentoOk;             // CHK_ISOLAMENTO_OK
  final String? obsIsolamentoOk;
  final bool chkSubstituicaoIsolamento;   // Pergunta: "Houve necessidade de substituir?"
  final String? obsSubstituicaoIsolamento;
  final double? metrosIsolamentoTrocados; // METROS_ISOLAMENTO_TROCADOS (só se substituiu)

  final String? linkFotoProcesso;         // LINK_FOTO_PROCESSO
  final double? tensaoV;                  // TENSION_V
  final double? correnteA;                // CORRENTE_A
  final double? pressaoPsi;               // PRESSAO_PSI
  final double? tempRetorno;              // TEMP_RETORNO
  final double? tempInsuflamento;         // TEMP_INSUFLAMENTO
  final String? linkFotoFinal;            // LINK_FOTO_FINAL
  final String? observacoesTecnicas;      // OBSERVACOES
  final String nomeChefe;                 // NOME_CHEFE_SETOR
  final String chapaFuncional;            // CHAPA_FUNCIONAL
  final String? linkAssinatura;           // LINK_ASSINATURA (base64 da imagem)
  final String statusGeral;               // STATUS_GERAL

  // Dados extras da máquina
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
    required this.linkFotoInicio,
    required this.chkDesmontagem,
    required this.obsDesmontagem,
    required this.chkLavagemQuimica,
    required this.obsLavagemQuimica,
    required this.chkDrenoBandeja,
    required this.obsDrenoBandeja,
    required this.chkAntibactericida,
    required this.obsAntibactericida,
    required this.chkRuidoVibracao,
    required this.obsRuidoVibracao,
    required this.chkVazamento,
    required this.obsVazamento,
    required this.chkEletrica,
    required this.obsEletrica,
    required this.chkIsolamentoOk,
    required this.obsIsolamentoOk,
    required this.chkSubstituicaoIsolamento,
    required this.obsSubstituicaoIsolamento,
    required this.metrosIsolamentoTrocados,
    required this.linkFotoProcesso,
    required this.tensaoV,
    required this.correnteA,
    required this.pressaoPsi,
    required this.tempRetorno,
    required this.tempInsuflamento,
    required this.linkFotoFinal,
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
      'dataInicio'                  : dataInicio.toIso8601String(),
      'dataFinal'                   : dataFinal.toIso8601String(),
      'tecnico'                     : tecnico,
      'fuel'                        : fuel,
      'localizacao'                 : localizacao,
      'coordenadasGps'              : coordenadasGps,
      'linkFotoInicio'              : linkFotoInicio,
      'chkDesmontagem'              : chkDesmontagem,
      'obsDesmontagem'              : obsDesmontagem,
      'chkLavagemQuimica'           : chkLavagemQuimica,
      'obsLavagemQuimica'           : obsLavagemQuimica,
      'chkDrenoBandeja'             : chkDrenoBandeja,
      'obsDrenoBandeja'             : obsDrenoBandeja,
      'chkAntibactericida'          : chkAntibactericida,
      'obsAntibactericida'          : obsAntibactericida,
      'chkRuidoVibracao'            : chkRuidoVibracao,
      'obsRuidoVibracao'            : obsRuidoVibracao,
      'chkVazamento'                : chkVazamento,
      'obsVazamento'                : obsVazamento,
      'chkEletrica'                 : chkEletrica,
      'obsEletrica'                 : obsEletrica,
      'chkIsolamentoOk'             : chkIsolamentoOk,
      'obsIsolamentoOk'             : obsIsolamentoOk,
      'chkSubstituicaoIsolamento'   : chkSubstituicaoIsolamento,
      'obsSubstituicaoIsolamento'   : obsSubstituicaoIsolamento,
      'metrosIsolamentoTrocados'    : metrosIsolamentoTrocados,
      'linkFotoProcesso'            : linkFotoProcesso,
      'tensaoV'                     : tensaoV,
      'correnteA'                   : correnteA,
      'pressaoPsi'                  : pressaoPsi,
      'tempRetorno'                 : tempRetorno,
      'tempInsuflamento'            : tempInsuflamento,
      'linkFotoFinal'               : linkFotoFinal,
      'observacoesTecnicas'         : observacoesTecnicas,
      'nomeChefe'                   : nomeChefe,
      'chapaFuncional'              : chapaFuncional,
      'linkAssinatura'              : linkAssinatura,
      'statusGeral'                 : statusGeral,
      'modelo'                      : modelo,
      'marca'                       : marca,
      'serie'                       : serie,
    };
  }

  factory ChecklistPreventiva.fromJson(Map<String, dynamic> json) {
    return ChecklistPreventiva(
      dataInicio                  : DateTime.parse(json['dataInicio'] as String),
      dataFinal                   : DateTime.parse(json['dataFinal'] as String),
      tecnico                     : json['tecnico'] as String,
      fuel                        : json['fuel'] as String,
      localizacao                 : json['localizacao'] as String,
      coordenadasGps              : json['coordenadasGps'] as String,
      linkFotoInicio              : json['linkFotoInicio'] as String?,
      chkDesmontagem              : json['chkDesmontagem'] as bool,
      obsDesmontagem              : json['obsDesmontagem'] as String?,
      chkLavagemQuimica           : json['chkLavagemQuimica'] as bool,
      obsLavagemQuimica           : json['obsLavagemQuimica'] as String?,
      chkDrenoBandeja             : json['chkDrenoBandeja'] as bool,
      obsDrenoBandeja             : json['obsDrenoBandeja'] as String?,
      chkAntibactericida          : json['chkAntibactericida'] as bool,
      obsAntibactericida          : json['obsAntibactericida'] as String?,
      chkRuidoVibracao            : json['chkRuidoVibracao'] as bool,
      obsRuidoVibracao            : json['obsRuidoVibracao'] as String?,
      chkVazamento                : json['chkVazamento'] as bool,
      obsVazamento                : json['obsVazamento'] as String?,
      chkEletrica                 : json['chkEletrica'] as bool,
      obsEletrica                 : json['obsEletrica'] as String?,
      chkIsolamentoOk             : json['chkIsolamentoOk'] as bool,
      obsIsolamentoOk             : json['obsIsolamentoOk'] as String?,
      chkSubstituicaoIsolamento   : json['chkSubstituicaoIsolamento'] as bool,
      obsSubstituicaoIsolamento   : json['obsSubstituicaoIsolamento'] as String?,
      metrosIsolamentoTrocados    : (json['metrosIsolamentoTrocados'] as num?)?.toDouble(),
      linkFotoProcesso            : json['linkFotoProcesso'] as String?,
      tensaoV                     : (json['tensaoV'] as num?)?.toDouble(),
      correnteA                   : (json['correnteA'] as num?)?.toDouble(),
      pressaoPsi                  : (json['pressaoPsi'] as num?)?.toDouble(),
      tempRetorno                 : (json['tempRetorno'] as num?)?.toDouble(),
      tempInsuflamento            : (json['tempInsuflamento'] as num?)?.toDouble(),
      linkFotoFinal               : json['linkFotoFinal'] as String?,
      observacoesTecnicas         : json['observacoesTecnicas'] as String?,
      nomeChefe                   : json['nomeChefe'] as String,
      chapaFuncional              : json['chapaFuncional'] as String,
      linkAssinatura              : json['linkAssinatura'] as String?,
      statusGeral                 : json['statusGeral'] as String,
      modelo                      : json['modelo'] as String,
      marca                       : json['marca'] as String,
      serie                       : json['serie'] as String,
    );
  }
}