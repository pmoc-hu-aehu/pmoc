class ChecklistMovimentacao {
  final DateTime dataInicio;
  final String   tecnico;
  final String   fuel;
  final String   origemSetor;
  final String   tipoMovimentacao;  // Instalação / Retirada / Transferência
  final String   motivo;
  final String   destinoSetor;
  final String   estadoEquipamento; // Operacional / Com Defeito / Para Manutenção
  final String   acessorios;
  final bool     chkProtecaoTransporte;
  final bool     chkIsolamentoNecessario;
  final double?  metrosEstimados;   // só se isolamento = true
  final String?  linkFotoOrigem;
  final String?  linkFotoDestino;
  final String   nomeChefSetor;
  final String   chapaFuncional;
  final String?  linkAssinatura;

  const ChecklistMovimentacao({
    required this.dataInicio,
    required this.tecnico,
    required this.fuel,
    required this.origemSetor,
    required this.tipoMovimentacao,
    required this.motivo,
    required this.destinoSetor,
    required this.estadoEquipamento,
    required this.acessorios,
    required this.chkProtecaoTransporte,
    required this.chkIsolamentoNecessario,
    this.metrosEstimados,
    this.linkFotoOrigem,
    this.linkFotoDestino,
    this.nomeChefSetor = '',
    this.chapaFuncional = '',
    this.linkAssinatura,
  });

  Map<String, dynamic> toJson() => {
    'dataInicio'             : dataInicio.toIso8601String(),
    'tecnico'                : tecnico,
    'fuel'                   : fuel,
    'origemSetor'            : origemSetor,
    'tipoMovimentacao'       : tipoMovimentacao,
    'motivo'                 : motivo,
    'destinoSetor'           : destinoSetor,
    'estadoEquipamento'      : estadoEquipamento,
    'acessorios'             : acessorios,
    'chkProtecaoTransporte'  : chkProtecaoTransporte,
    'chkIsolamentoNecessario': chkIsolamentoNecessario,
    'metrosEstimados'        : metrosEstimados,
    'linkFotoOrigem'         : linkFotoOrigem,
    'linkFotoDestino'        : linkFotoDestino,
    'nomeChefSetor'          : nomeChefSetor,
    'chapaFuncional'         : chapaFuncional,
    'linkAssinatura'         : linkAssinatura,
  };
}
