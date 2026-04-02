class ChecklistCorretiva {
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;

  final String? linkFotoInicio;
  final String descDefeito;
  final String causaProvavel;
  final String servicoRealizado;
  final String pecasTrocadas;
  final String nfRequisicao;

  final bool chkIsolamentoOk;
  final double? metrosIsolamentoTrocados;
  final bool chkHigienePos;

  final double? tensaoV;
  final double? correnteA;
  final double? pressaoPsi;
  final double? tempInsuflamento;

  final String? linkFotoFinal;
  final bool equipamentoOperacional;
  final String? motivoInoperancia;

  final String nomeChefe;
  final String chapaFuncional;
  final String? linkAssinatura;
  final String statusGeral;

  // Dados extras da máquina
  final String modelo;
  final String marca;
  final String serie;

  const ChecklistCorretiva({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.fuel,
    required this.localizacao,
    required this.coordenadasGps,
    required this.linkFotoInicio,
    required this.descDefeito,
    required this.causaProvavel,
    required this.servicoRealizado,
    required this.pecasTrocadas,
    required this.nfRequisicao,
    required this.chkIsolamentoOk,
    required this.metrosIsolamentoTrocados,
    required this.chkHigienePos,
    required this.tensaoV,
    required this.correnteA,
    required this.pressaoPsi,
    required this.tempInsuflamento,
    required this.linkFotoFinal,
    required this.equipamentoOperacional,
    required this.motivoInoperancia,
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
      'dataInicio'               : dataInicio.toIso8601String(),
      'dataFinal'                : dataFinal.toIso8601String(),
      'tecnico'                  : tecnico,
      'fuel'                     : fuel,
      'localizacao'              : localizacao,
      'coordenadasGps'           : coordenadasGps,
      'linkFotoInicio'           : linkFotoInicio,
      'descDefeito'              : descDefeito,
      'causaProvavel'            : causaProvavel,
      'servicoRealizado'         : servicoRealizado,
      'pecasTrocadas'            : pecasTrocadas,
      'nfRequisicao'             : nfRequisicao,
      'chkIsolamentoOk'          : chkIsolamentoOk,
      'metrosIsolamentoTrocados' : metrosIsolamentoTrocados,
      'chkHigienePos'            : chkHigienePos,
      'tensaoV'                  : tensaoV,
      'correnteA'                : correnteA,
      'pressaoPsi'               : pressaoPsi,
      'tempInsuflamento'         : tempInsuflamento,
      'linkFotoFinal'            : linkFotoFinal,
      'equipamentoOperacional'   : equipamentoOperacional,
      'motivoInoperancia'        : motivoInoperancia,
      'nomeChefe'                : nomeChefe,
      'chapaFuncional'           : chapaFuncional,
      'linkAssinatura'           : linkAssinatura,
      'statusGeral'              : statusGeral,
      'modelo'                   : modelo,
      'marca'                    : marca,
      'serie'                    : serie,
    };
  }

  factory ChecklistCorretiva.fromJson(Map<String, dynamic> json) {
    return ChecklistCorretiva(
      dataInicio               : DateTime.parse(json['dataInicio'] as String),
      dataFinal                : DateTime.parse(json['dataFinal'] as String),
      tecnico                  : json['tecnico'] as String,
      fuel                     : json['fuel'] as String,
      localizacao              : json['localizacao'] as String,
      coordenadasGps           : json['coordenadasGps'] as String,
      linkFotoInicio           : json['linkFotoInicio'] as String?,
      descDefeito              : json['descDefeito'] as String,
      causaProvavel            : json['causaProvavel'] as String,
      servicoRealizado         : json['servicoRealizado'] as String,
      pecasTrocadas            : json['pecasTrocadas'] as String,
      nfRequisicao             : json['nfRequisicao'] as String,
      chkIsolamentoOk          : json['chkIsolamentoOk'] as bool,
      metrosIsolamentoTrocados : (json['metrosIsolamentoTrocados'] as num?)?.toDouble(),
      chkHigienePos            : json['chkHigienePos'] as bool,
      tensaoV                  : (json['tensaoV'] as num?)?.toDouble(),
      correnteA                : (json['correnteA'] as num?)?.toDouble(),
      pressaoPsi               : (json['pressaoPsi'] as num?)?.toDouble(),
      tempInsuflamento         : (json['tempInsuflamento'] as num?)?.toDouble(),
      linkFotoFinal            : json['linkFotoFinal'] as String?,
      equipamentoOperacional   : json['equipamentoOperacional'] as bool,
      motivoInoperancia        : json['motivoInoperancia'] as String?,
      nomeChefe                : json['nomeChefe'] as String,
      chapaFuncional           : json['chapaFuncional'] as String,
      linkAssinatura           : json['linkAssinatura'] as String?,
      statusGeral              : json['statusGeral'] as String,
      modelo                   : json['modelo'] as String,
      marca                    : json['marca'] as String,
      serie                    : json['serie'] as String,
    );
  }
}
