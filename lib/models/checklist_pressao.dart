class ChecklistPressao {
  // ── Cabeçalho ──────────────────────────────────────────────────
  final DateTime dataInicio;
  final DateTime dataFinal;
  final String   tecnico;
  final String   local;          // Descrição completa do local
  final String   codSala;        // Código curto da sala (ex.: SIA-B3)
  final String   zona;           // Setor/bloco (ex.: UTI, Emergência)
  final String   coordenadasGps;
  final String   tipoInspecao;   // Rotina / Pós-Manutenção / Emergencial

  // ── Fotos ──────────────────────────────────────────────────────
  final String? linkFotoManometro; // Foto obrigatória do visor
  final String? linkFotoVedacao;   // Foto opcional da vedação (obs obrigatória se null)
  final String? obsFotoVedacao;    // Justificativa se foto vedação ausente

  // ── Medições ───────────────────────────────────────────────────
  final double? pressaoPascal;   // Valor em Pa
  final String  tipoSala;        // Sala Positiva / Sala Negativa

  // ── Checklists ─────────────────────────────────────────────────
  final bool   chkConformidade;
  final bool   chkVedacaoPorras;
  final bool   chkMolaPorta;
  final String chkFiltroHepa;   // OK / Sujo / Danificado / Sem Acesso
  final String statusSala;      // Segura para uso / Risco de Contaminação / Restrita

  // ── Seção Final ────────────────────────────────────────────────
  final String  observacoesTecnicas;
  final String  nomeChefSetor;
  final String  chapaFuncional;
  final String? linkAssinatura;
  final String  statusGeral;    // Completo / Pendente / Rejeitado
  final String  versaoChecklist;
  final String  idChecklist;

  const ChecklistPressao({
    required this.dataInicio,
    required this.dataFinal,
    required this.tecnico,
    required this.local,
    required this.codSala,
    required this.zona,
    required this.coordenadasGps,
    required this.tipoInspecao,
    this.linkFotoManometro,
    this.linkFotoVedacao,
    this.obsFotoVedacao,
    this.pressaoPascal,
    required this.tipoSala,
    required this.chkConformidade,
    required this.chkVedacaoPorras,
    required this.chkMolaPorta,
    required this.chkFiltroHepa,
    required this.statusSala,
    required this.observacoesTecnicas,
    required this.nomeChefSetor,
    required this.chapaFuncional,
    this.linkAssinatura,
    required this.statusGeral,
    this.versaoChecklist = 'PRESSAO_v1.0',
    required this.idChecklist,
  });

  Map<String, dynamic> toJson() => {
    'dataInicio'          : dataInicio.toIso8601String(),
    'dataFinal'           : dataFinal.toIso8601String(),
    'tecnico'             : tecnico,
    'local'               : local,
    'codSala'             : codSala,
    'zona'                : zona,
    'coordenadasGps'      : coordenadasGps,
    'tipoInspecao'        : tipoInspecao,
    'linkFotoManometro'   : linkFotoManometro,
    'linkFotoVedacao'     : linkFotoVedacao,
    'obsFotoVedacao'      : obsFotoVedacao,
    'pressaoPascal'       : pressaoPascal,
    'tipoSala'            : tipoSala,
    'chkConformidade'     : chkConformidade,
    'chkVedacaoPorras'    : chkVedacaoPorras,
    'chkMolaPorta'        : chkMolaPorta,
    'chkFiltroHepa'       : chkFiltroHepa,
    'statusSala'          : statusSala,
    'observacoesTecnicas' : observacoesTecnicas,
    'nomeChefSetor'       : nomeChefSetor,
    'chapaFuncional'      : chapaFuncional,
    'linkAssinatura'      : linkAssinatura,
    'statusGeral'         : statusGeral,
    'versaoChecklist'     : versaoChecklist,
    'idChecklist'         : idChecklist,
  };
}
