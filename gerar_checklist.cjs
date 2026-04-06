const fs = require('fs');
const {
  Document, Packer, Paragraph, Table, TableRow, TableCell,
  TextRun, AlignmentType, WidthType, ShadingType
} = require('./node_modules/docx/dist/index.umd.cjs');

const AZUL      = "1F4E79";
const AZUL_ESC  = "003366";
const BRANCO    = "FFFFFF";
const AZUL_CLR  = "EBF3FB";
const CINZA     = "F2F2F2";

function cell(text, opts) {
  const shade = opts && opts.shade
    ? { type: ShadingType.SOLID, color: opts.shade, fill: opts.shade }
    : undefined;
  return new TableCell({
    columnSpan: (opts && opts.span) || 1,
    shading: shade,
    children: [new Paragraph({
      alignment: (opts && opts.center) ? AlignmentType.CENTER : AlignmentType.LEFT,
      children: [new TextRun({
        text: String(text),
        bold:    !!(opts && opts.bold),
        italics: !!(opts && opts.italic),
        color:   (opts && opts.color) || "000000",
        size:    (opts && opts.size)  || 20,
      })]
    })]
  });
}

function secaoRow(titulo) {
  return new TableRow({ children: [
    cell(titulo, { span: 4, shade: AZUL, bold: true, color: BRANCO, size: 22, center: true })
  ]});
}

function descRow(texto) {
  return new TableRow({ children: [
    cell(texto, { span: 4, shade: AZUL_CLR, italic: true, size: 18, color: "444444" })
  ]});
}

function campoRow(num, campo, tipo, par) {
  const shade = par ? CINZA : "FFFFFF";
  return new TableRow({ children: [
    cell(String(num), { shade }),
    cell(campo,       { shade }),
    cell(tipo,        { shade }),
    cell("",          { shade }),
  ]});
}

function camposComuns(par) {
  return [
    campoRow("—", "Data e Hora de Inicio",                          "Data/Hora",          par),
    campoRow("—", "Data e Hora de Conclusao",                       "Data/Hora",          !par),
    campoRow("—", "Codigo do Equipamento (FUEL)",                   "Codigo",             par),
    campoRow("—", "Localizacao do Equipamento",                     "Texto livre",        !par),
    campoRow("—", "Tecnico Responsavel",                            "Nome completo",      par),
    campoRow("—", "Coordenadas GPS (automatico)",                   "Lat/Long",           !par),
  ];
}

function fotoRows() {
  return [
    campoRow("Foto", "Foto antes do servico",                       "Imagem (camera app)", true),
    campoRow("Foto", "Foto apos o servico",                        "Imagem (camera app)", false),
    campoRow("Ass.", "Assinatura digital do responsavel do setor",  "Assinatura digital",  true),
  ];
}

const checklists = [
  {
    titulo: "1. LIMPEZA DE FILTROS",
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
    titulo: "2. LIMPEZA DE DUTOS",
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
    titulo: "3. MANUTENCAO PREVENTIVA",
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
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    titulo: "4. MANUTENCAO CORRETIVA",
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
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    titulo: "5. SISTEMA DE EXAUSTAO",
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
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    titulo: "6. CONTROLE DE PRESSAO DE SALAS",
    desc: "Medicao da pressurizacao diferencial em salas especiais (cirurgicas, UTI, isolamento). Ref: ANVISA RDC 50/2002.",
    campos: [
      ["Pressao diferencial medida (Pa)",             "Medicao numerica"],
      ["Tipo de sala",                                "Texto livre"],
      ["Sala em conformidade com pressao exigida?",   "Sim / Nao"],
      ["Vedacao de portas e janelas OK?",             "Sim / Nao"],
      ["Mola de porta funcionando corretamente?",     "Sim / Nao"],
      ["Situacao do filtro HEPA",                     "Texto livre"],
      ["Status geral da sala",                        "Texto livre"],
      ["Observacoes",                                 "Texto livre"],
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    titulo: "7. QUALIDADE DO AR",
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
      ["Nome do responsavel que acompanhou",          "Texto livre"],
      ["Chapa funcional do responsavel",              "Texto livre"],
    ]
  },
  {
    titulo: "8. MOVIMENTACAO DE EQUIPAMENTOS",
    desc: "Registro de transferencias, substituicoes e remanejamentos de equipamentos entre setores do hospital.",
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

// ---- Montar tabela ----
const rows = [];

// Cabeçalho principal
rows.push(new TableRow({ children: [
  cell("HOSPITAL UNIVERSITARIO DE LONDRINA - HU/UEL\nPLANO DE MANUTENCAO, OPERACAO E CONTROLE - PMOC\nModelo de Checklists - Campos Obrigatorios por Tipo de Servico",
    { span: 4, shade: AZUL_ESC, bold: true, color: BRANCO, size: 24, center: true })
]}));

// Cabeçalho de colunas
rows.push(new TableRow({ children: [
  cell("#",                  { shade: AZUL, bold: true, color: BRANCO, size: 20, center: true }),
  cell("Campo / Verificacao",{ shade: AZUL, bold: true, color: BRANCO, size: 20 }),
  cell("Tipo de Resposta",   { shade: AZUL, bold: true, color: BRANCO, size: 20 }),
  cell("Valor Registrado",   { shade: AZUL, bold: true, color: BRANCO, size: 20 }),
]}));

for (const s of checklists) {
  rows.push(secaoRow(s.titulo));
  rows.push(descRow(s.desc));
  for (const r of camposComuns(true)) rows.push(r);
  s.campos.forEach(([campo, tipo], i) => rows.push(campoRow(i + 1, campo, tipo, i % 2 === 0)));
  for (const r of fotoRows()) rows.push(r);
}

const table = new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  columnWidths: [700, 5100, 2200, 1800],
  rows,
});

const doc = new Document({
  sections: [{
    properties: { page: { margin: { top: 720, bottom: 720, left: 900, right: 900 } } },
    children: [
      table,
      new Paragraph({ children: [new TextRun({ text: "" })] }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({
          text: "Documento gerado pelo Sistema PMOC Digital - " + new Date().toLocaleDateString("pt-BR"),
          size: 16, color: "888888", italics: true
        })]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('PMOC_Checklists_Licitacao.docx', buf);
  console.log('Arquivo gerado: PMOC_Checklists_Licitacao.docx');
}).catch(e => {
  console.error('Erro:', e.message);
});
