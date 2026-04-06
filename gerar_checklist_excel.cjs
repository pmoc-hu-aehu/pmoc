const XLSX = require('./node_modules/xlsx');

const CHECKLISTS = [
  {
    aba: "1 - Filtros",
    titulo: "LIMPEZA DE FILTROS",
    desc: "Executado mensalmente em todos os equipamentos de ar-condicionado cadastrados no PMOC.",
    campos: [
      ["Equipamento desligado antes da limpeza?",     "Sim / Nao"],
      ["Filtro lavado com agua corrente?",            "Sim / Nao"],
      ["Limpeza com escova realizada?",               "Sim / Nao"],
      ["Secagem completa antes da recolocacao?",      "Sim / Nao"],
      ["Integridade fisica do filtro verificada?",    "Sim / Nao"],
      ["Limpeza externa do gabinete realizada?",      "Sim / Nao"],
      ["Filtro recolocado corretamente?",             "Sim / Nao"],
      ["Operacao em modo DRY verificada?",            "Sim / Nao"],
      ["Verificacao das condicoes do ambiente?",      "Sim / Nao"],
      ["Observacao sobre dreno/bandeja",              "Texto livre"],
      ["Temperatura de entrada (graus C)",            "Medicao numerica"],
      ["Temperatura de insuflamento (graus C)",       "Medicao numerica"],
    ]
  },
  {
    aba: "2 - Dutos",
    titulo: "LIMPEZA DE DUTOS",
    desc: "Verificacao e limpeza de dutos de distribuicao de ar, grelhas e difusores.",
    campos: [
      ["Isolamento do duto sem danos visiveis?",      "Sim / Nao"],
      ["Limpeza interna realizada (robo/escova)?",    "Sim / Nao"],
      ["Grelhas e difusores limpos e alinhados?",     "Sim / Nao"],
      ["Selos de inspecao integros e fechados?",      "Sim / Nao"],
      ["Ausencia de umidade/mofo verificada?",        "Sim / Nao"],
      ["Temperatura de saida do duto (graus C)",      "Medicao numerica"],
      ["Observacoes",                                 "Texto livre"],
    ]
  },
  {
    aba: "3 - Preventiva",
    titulo: "MANUTENCAO PREVENTIVA",
    desc: "Intervencao programada com limpeza quimica, verificacao eletrica e medicoes tecnicas completas.",
    campos: [
      ["Desmontagem e limpeza quimica realizada?",    "Sim / Nao"],
      ["Lavagem quimica da serpentina realizada?",    "Sim / Nao"],
      ["Dreno e bandeja limpos com bactericida?",     "Sim / Nao"],
      ["Aplicacao de antibactericida realizada?",     "Sim / Nao"],
      ["Ruidos e vibracoes anormais verificados?",    "Sim / Nao"],
      ["Ausencia de vazamentos confirmada?",          "Sim / Nao"],
      ["Verificacao eletrica (terminais/conexoes)?",  "Sim / Nao"],
      ["Isolamento termico das linhas OK?",           "Sim / Nao"],
      ["Metros de isolamento trocados (m)",           "Medicao numerica"],
      ["Tensao eletrica medida (V)",                  "Medicao numerica"],
      ["Corrente eletrica medida (A)",                "Medicao numerica"],
      ["Pressao do gas (PSI)",                        "Medicao numerica"],
      ["Temperatura de retorno (graus C)",            "Medicao numerica"],
      ["Temperatura de insuflamento (graus C)",       "Medicao numerica"],
      ["Observacoes tecnicas",                        "Texto livre"],
      ["Nome do responsavel que acompanhou o servico","Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    aba: "4 - Corretiva",
    titulo: "MANUTENCAO CORRETIVA",
    desc: "Atendimento a falhas ou defeitos, com registro de causa, servico executado e pecas utilizadas.",
    campos: [
      ["Descricao do defeito",                        "Texto livre"],
      ["Causa provavel identificada",                 "Texto livre"],
      ["Servico realizado",                           "Texto livre"],
      ["Pecas trocadas/utilizadas",                   "Texto livre"],
      ["NF / Requisicao",                             "Texto livre"],
      ["Isolamento termico verificado apos servico?", "Sim / Nao"],
      ["Metros de isolamento trocados (m)",           "Medicao numerica"],
      ["Limpeza e higienizacao pos-servico?",         "Sim / Nao"],
      ["Tensao eletrica medida (V)",                  "Medicao numerica"],
      ["Corrente eletrica medida (A)",                "Medicao numerica"],
      ["Pressao do gas (PSI)",                        "Medicao numerica"],
      ["Temperatura de insuflamento (graus C)",       "Medicao numerica"],
      ["Status operacional apos servico",             "Texto livre"],
      ["Motivo de inoperancia (se aplicavel)",        "Texto livre"],
      ["Nome do responsavel que acompanhou o servico","Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    aba: "5 - Exaustao",
    titulo: "SISTEMA DE EXAUSTAO",
    desc: "Verificacao e manutencao de ventiladores, exaustores e sistemas de circulacao de ar.",
    campos: [
      ["Tipo de equipamento",                         "Texto livre"],
      ["Limpeza do rotor realizada?",                 "Sim / Nao"],
      ["Estado das correias",                         "Texto livre"],
      ["Lubrificacao dos mancais realizada?",         "Sim / Nao"],
      ["Fixacao e vibracao verificadas?",             "Sim / Nao"],
      ["Sensores de acionamento OK?",                 "Sim / Nao"],
      ["Tensao eletrica medida (V)",                  "Medicao numerica"],
      ["Corrente eletrica medida (A)",                "Medicao numerica"],
      ["Velocidade do ar (m/s)",                      "Medicao numerica"],
      ["Filtros/telas limpos e integros?",            "Sim / Nao"],
      ["Status do equipamento",                       "Texto livre"],
      ["Nome do responsavel que acompanhou o servico","Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    aba: "6 - Pressao Salas",
    titulo: "CONTROLE DE PRESSAO DE SALAS",
    desc: "Medicao da pressurizacao diferencial em salas especiais. Ref: ANVISA RDC 50/2002.",
    campos: [
      ["Pressao diferencial medida (Pa)",             "Medicao numerica"],
      ["Tipo de sala",                                "Texto livre"],
      ["Sala em conformidade com pressao exigida?",   "Sim / Nao"],
      ["Vedacao de portas e janelas OK?",             "Sim / Nao"],
      ["Mola de porta funcionando corretamente?",     "Sim / Nao"],
      ["Situacao do filtro HEPA",                     "Texto livre"],
      ["Status geral da sala",                        "Texto livre"],
      ["Observacoes",                                 "Texto livre"],
      ["Nome do responsavel que acompanhou o servico","Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    aba: "7 - Qualidade Ar",
    titulo: "QUALIDADE DO AR",
    desc: "Coleta e analise de parametros ambientais e microbiologicos. Ref: ANVISA RDC 50/2002 e RE 9/2003.",
    campos: [
      ["Ponto de coleta",                             "Texto livre"],
      ["Localizacao / descricao do local",            "Texto livre"],
      ["Tipo de coleta",                              "Texto livre"],
      ["CO2 medido (ppm)",                            "Medicao numerica"],
      ["Umidade relativa (%)",                        "Medicao numerica"],
      ["Temperatura (graus C)",                       "Medicao numerica"],
      ["Velocidade do ar (m/s)",                      "Medicao numerica"],
      ["ID da amostra microbiologica",                "Texto livre"],
      ["Status da qualidade do ar",                   "Texto livre"],
      ["Observacoes",                                 "Texto livre"],
      ["Nome do responsavel que acompanhou o servico","Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    aba: "8 - Movimentacao",
    titulo: "MOVIMENTACAO DE EQUIPAMENTOS",
    desc: "Registro de transferencias e remanejamentos de equipamentos entre setores do hospital.",
    campos: [
      ["Setor de origem",                             "Texto livre"],
      ["Tipo de movimentacao",                        "Texto livre"],
      ["Motivo da movimentacao",                      "Texto livre"],
      ["Setor de destino",                            "Texto livre"],
      ["Estado do equipamento",                       "Texto livre"],
      ["Acessorios incluidos",                        "Texto livre"],
      ["Protecao para transporte realizada?",         "Sim / Nao"],
      ["Observacoes",                                 "Texto livre"],
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  }
];

const COMUNS = [
  ["Data e Hora de Inicio",                 "Data/Hora"],
  ["Data e Hora de Conclusao",              "Data/Hora"],
  ["Codigo do Equipamento (FUEL)",          "Codigo alfanumerico"],
  ["Localizacao do Equipamento",            "Texto livre"],
  ["Tecnico Responsavel",                   "Nome completo"],
  ["Coordenadas GPS (automatico pelo app)", "Lat/Long automatico"],
];

const FOTOS = [
  ["Foto antes do servico",                 "Imagem (camera app)"],
  ["Foto apos o servico",                   "Imagem (camera app)"],
  ["Assinatura digital do responsavel",     "Assinatura digital"],
];

// Estilos
const sCabecalho = { font: { bold: true, color: { rgb: "FFFFFF" }, sz: 12 }, fill: { fgColor: { rgb: "1F4E79" } }, alignment: { horizontal: "center", wrapText: true } };
const sTitulo    = { font: { bold: true, color: { rgb: "FFFFFF" }, sz: 14 }, fill: { fgColor: { rgb: "003366" } }, alignment: { horizontal: "center", wrapText: true } };
const sDesc      = { font: { italic: true, color: { rgb: "444444" }, sz: 10 }, fill: { fgColor: { rgb: "EBF3FB" } }, alignment: { wrapText: true } };
const sComum     = { font: { italic: true, color: { rgb: "555555" }, sz: 10 }, fill: { fgColor: { rgb: "F2F2F2" } }, alignment: { wrapText: true } };
const sItem      = { font: { sz: 11 }, fill: { fgColor: { rgb: "FFFFFF" } }, alignment: { wrapText: true } };
const sItemAlt   = { font: { sz: 11 }, fill: { fgColor: { rgb: "DEEAF1" } }, alignment: { wrapText: true } };
const sFoto      = { font: { italic: true, color: { rgb: "888888" }, sz: 10 }, fill: { fgColor: { rgb: "FFF2CC" } }, alignment: { wrapText: true } };
const sNr        = { font: { bold: true, sz: 11 }, alignment: { horizontal: "center" } };
const sNrAlt     = { font: { bold: true, sz: 11 }, fill: { fgColor: { rgb: "DEEAF1" } }, alignment: { horizontal: "center" } };

function c(v, s) {
  return { v: v == null ? "" : v, t: "s", s };
}

const wb = XLSX.utils.book_new();

// ---- Aba de capa / resumo ----
const capaData = [
  [c("HOSPITAL UNIVERSITARIO DE LONDRINA - HU/UEL", sTitulo), c("",""), c("",""), c("","")],
  [c("PLANO DE MANUTENCAO, OPERACAO E CONTROLE - PMOC", sTitulo), c("",""), c("",""), c("","")],
  [c("Modelo de Checklists - Campos Obrigatorios por Tipo de Servico", sDesc), c("",""), c("",""), c("","")],
  [c("",""), c("",""), c("",""), c("","")],
  [c("Checklist", sCabecalho), c("Campos especificos", sCabecalho), c("Campos comuns", sCabecalho), c("Total", sCabecalho)],
];
CHECKLISTS.forEach((ch, i) => {
  const s = i % 2 === 0 ? sItem : sItemAlt;
  capaData.push([
    c(ch.titulo, s),
    c(ch.campos.length, s),
    c(COMUNS.length + FOTOS.length, s),
    c(ch.campos.length + COMUNS.length + FOTOS.length, s),
  ]);
});
const capaWs = XLSX.utils.aoa_to_sheet(capaData);
capaWs['!merges'] = [
  { s: { r: 0, c: 0 }, e: { r: 0, c: 3 } },
  { s: { r: 1, c: 0 }, e: { r: 1, c: 3 } },
  { s: { r: 2, c: 0 }, e: { r: 2, c: 3 } },
];
capaWs['!cols'] = [{ wch: 45 }, { wch: 20 }, { wch: 15 }, { wch: 10 }];
XLSX.utils.book_append_sheet(wb, capaWs, "Resumo");

// ---- Uma aba por checklist ----
for (const ch of CHECKLISTS) {
  const rows = [];

  // Titulo
  rows.push([c("HOSPITAL UNIVERSITARIO DE LONDRINA - HU/UEL - PMOC", sTitulo), c("",""), c("",""), c("","")]);
  rows.push([c(ch.titulo, sTitulo), c("",""), c("",""), c("","")]);
  rows.push([c(ch.desc, sDesc), c("",""), c("",""), c("","")]);
  rows.push([c("",""), c("",""), c("",""), c("","")]);

  // Header colunas
  rows.push([
    c("Nr",                  sCabecalho),
    c("Campo / Verificacao", sCabecalho),
    c("Tipo de Resposta",    sCabecalho),
    c("Valor Registrado",    sCabecalho),
  ]);

  // Campos comuns
  COMUNS.forEach(([campo, tipo]) => {
    rows.push([c("—", sComum), c(campo, sComum), c(tipo, sComum), c("", sComum)]);
  });

  // Separador
  rows.push([c("",""), c("--- Campos especificos do servico ---", sDesc), c("",""), c("","")]);

  // Campos especificos
  ch.campos.forEach(([campo, tipo], i) => {
    const s  = i % 2 === 0 ? sItem    : sItemAlt;
    const sn = i % 2 === 0 ? sNr      : sNrAlt;
    rows.push([c(i + 1, sn), c(campo, s), c(tipo, s), c("", s)]);
  });

  // Fotos e assinatura
  FOTOS.forEach(([campo, tipo]) => {
    rows.push([c("", sFoto), c(campo, sFoto), c(tipo, sFoto), c("", sFoto)]);
  });

  const ws = XLSX.utils.aoa_to_sheet(rows);

  // Merge titulo
  ws['!merges'] = [
    { s: { r: 0, c: 0 }, e: { r: 0, c: 3 } },
    { s: { r: 1, c: 0 }, e: { r: 1, c: 3 } },
    { s: { r: 2, c: 0 }, e: { r: 2, c: 3 } },
  ];

  ws['!cols'] = [{ wch: 6 }, { wch: 52 }, { wch: 22 }, { wch: 28 }];

  XLSX.utils.book_append_sheet(wb, ws, ch.aba);
}

XLSX.writeFile(wb, "PMOC_Checklists_Licitacao.xlsx");
console.log("Arquivo gerado: PMOC_Checklists_Licitacao.xlsx");
