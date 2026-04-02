class ChecklistFiltro {
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String tecnico;
  final String fuel;
  final String localizacao;
  final String coordenadasGps;
  final String? linkFotoSuja; // URL da foto no Drive
  final bool chkDesligado;
  final String? obsDesligado;
  final bool chkLavado;
  final String? obsLavado;
  final bool chkEscova;
  final String? obsEscova;
  final bool chkSecagem;
  final String? obsSecagem;
  final bool chkIntegridade;
  final String? obsIntegridade;
  final bool chkLimpezaExt;
  final String? obsLimpezaExt;
  final bool chkRecolocado;
  final String? obsRecolocado;
  final String? linkFotoLimpa; // URL da foto no Drive
  final bool chkDry;
  final String? obsDry;
  final bool chkAmbiente;
  final String? obsAmbiente;
  final bool chkDreno;
  final String? obsDreno;
  final double? tempEntrada;
  final double? tempInsuflamento;
  final String statusGeral; // OK, PENDENTE, REPROVADO

  // Dados da máquina (snap da hora do checklist)
  final String modelo;
  final String marca;
  final String serie; // Adicionado para consistência, se disponível

  ChecklistFiltro({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.fuel,
    required this.localizacao,
    required this.coordenadasGps,
    this.linkFotoSuja,
    required this.chkDesligado,
    this.obsDesligado,
    required this.chkLavado,
    this.obsLavado,
    required this.chkEscova,
    this.obsEscova,
    required this.chkSecagem,
    this.obsSecagem,
    required this.chkIntegridade,
    this.obsIntegridade,
    required this.chkLimpezaExt,
    this.obsLimpezaExt,
    required this.chkRecolocado,
    this.obsRecolocado,
    this.linkFotoLimpa,
    required this.chkDry,
    this.obsDry,
    required this.chkAmbiente,
    this.obsAmbiente,
    required this.chkDreno,
    this.obsDreno,
    this.tempEntrada,
    this.tempInsuflamento,
    required this.statusGeral,
    required this.modelo,
    required this.marca,
    required this.serie, // Adicionado aqui
  });

  Map<String, dynamic> toJson() {
    return {
      'dataInicio'      : dataInicio.toIso8601String(),
      'dataFinal'       : dataFinal.toIso8601String(),
      'tecnico'         : tecnico,
      'fuel'            : fuel,
      'localizacao'     : localizacao,
      'coordenadasGps'  : coordenadasGps,
      'fotoSujaB64'     : linkFotoSuja,
      'chkDesligado'    : chkDesligado,
      'obsDesligado'    : obsDesligado,
      'chkLavado'       : chkLavado,
      'obsLavado'       : obsLavado,
      'chkEscova'       : chkEscova,
      'obsEscova'       : obsEscova,
      'chkSecagem'      : chkSecagem,
      'obsSecagem'      : obsSecagem,
      'chkIntegridade'  : chkIntegridade,
      'obsIntegridade'  : obsIntegridade,
      'chkLimpezaExt'   : chkLimpezaExt,
      'obsLimpezaExt'   : obsLimpezaExt,
      'chkRecolocado'   : chkRecolocado,
      'obsRecolocado'   : obsRecolocado,
      'fotoLimpaB64'    : linkFotoLimpa,
      'chkDry'          : chkDry,
      'obsDry'          : obsDry,
      'chkAmbiente'     : chkAmbiente,
      'obsAmbiente'     : obsAmbiente,
      'chkDreno'        : chkDreno,
      'obsDreno'        : obsDreno,
      'tempEntrada'     : tempEntrada,
      'tempInsuflamento': tempInsuflamento,
      'statusGeral'     : statusGeral,
    };
  }
}