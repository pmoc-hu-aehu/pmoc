import {
  Document, Packer, Paragraph, Table, TableRow, TableCell,
  TextRun, AlignmentType, WidthType, ShadingType
} from "./node_modules/docx/dist/index.mjs";
import fs from "fs";

const AZUL   = "1F4E79";
const BRANCO = "FFFFFF";
const CINZA  = "D9D9D9";
const AZUL_CLARO = "EBF3FB";

function hCell(text, span = 1) {
  return new TableCell({
    columnSpan: span,
    shading: { type: ShadingType.SOLID, color: AZUL, fill: AZUL },
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text, bold: true, color: BRANCO, size: 20 })]
    })]
  });
}

function secRow(titulo) {
  return new TableRow({ children: [new TableCell({
    columnSpan: 4,
    shading: { type: ShadingType.SOLID, color: AZUL, fill: AZUL },
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: titulo, bold: true, color: BRANCO, size: 22 })]
    })]
  })]});
}

function descRow(text) {
  return new TableRow({ children: [new TableCell({
    columnSpan: 4,
    shading: { type: ShadingType.SOLID, color: AZUL_CLARO, fill: AZUL_CLARO },
    children: [new Paragraph({
      children: [new TextRun({ text, italics: true, size: 18, color: "444444" })]
    })]
  })]});
}

function dataRow(num, campo, tipo) {
  const shade = (num % 2 === 0) ? { type: ShadingType.SOLID, color: "F2F2F2", fill: "F2F2F2" } : undefined;
  function c(t) {
    return new TableCell({ shading: shade, children: [new Paragraph({ children: [new TextRun({ text: t, size: 20 })] })] });
  }
  return new TableRow({ children: [c(String(num)), c(campo), c(tipo), c("")] });
}

function commonRows() {
  return [
    dataRow("—", "Data e Hora de Início", "Data/Hora"),
    dataRow("—", "Data e Hora de Conclusão", "Data/Hora"),
    dataRow("—", "Código do Equipamento (FUEL)", "Código alfanumérico"),
    dataRow("—", "Localização do Equipamento", "Texto livre"),
    dataRow("—", "Técnico Responsável", "Nome completo"),
    dataRow("—", "Coordenadas GPS (registradas automaticamente)", "Lat/Long automático"),
  ];
}

function fotoRows() {
  return [
    dataRow("📷", "Foto antes do serviço", "Imagem (câmera app)"),
    dataRow("📷", "Foto após o serviço", "Imagem (câmera app)"),
    dataRow("✍", "Assinatura digital do responsável do setor", "Assinatura digital"),
  ];
}

const checklists = [
  {
    titulo: "1. LIMPEZA DE FILTROS",
    desc: "Executado mensalmente em todos os equipamentos de ar-condicionado cadastrados no PMOC.",
    campos: [
      ["Equipamento desligado antes da limpeza?", "Sim / Não"],
      ["Filtro lavado com água corrente?", "Sim / Não"],
      ["Limpeza com escova realizada?", "Sim / Não"],
      ["Secagem completa antes da recolocação?", "Sim / Não"],
      ["Integridade física do filtro verificada?", "Sim / Não"],
      ["Limpeza externa do gabinete realizada?", "Sim / Não"],
      ["Filtro recolocado corretamente?", "Sim / Não"],
      ["Operação em modo DRY verificada?", "Sim / Não"],
      ["Verificação das condições do ambiente?", "Sim / Não"],
      ["Observação sobre dreno/bandeja", "Texto livre"],
      ["Temperatura de entrada (°C)", "Medição numérica"],
      ["Temperatura de insuflamento (°C)", "Medição numérica"],
    ]
  },
  {
    titulo: "2. LIMPEZA DE DUTOS",
    desc: "Verificação e limpeza de dutos de distribuição de ar, grelhas e difusores.",
    campos: [
      ["Isolamento do duto sem danos visíveis?", "Sim / Não"],
      ["Limpeza interna realizada (robô/escova)?", "Sim / Não"],
      ["Grelhas e difusores limpos e alinhados?", "Sim / Não"],
      ["Selos de inspeção íntegros e fechados?", "Sim / Não"],
      ["Ausência de umidade/mofo verificada?", "Sim / Não"],
      ["Temperatura de saída do duto (°C)", "Medição numérica"],
      ["Observações", "Texto livre"],
    ]
  },
  {
    titulo: "3. MANUTENÇÃO PREVENTIVA",
    desc: "Intervenção programada com limpeza química, verificação elétrica e medições técnicas completas.",
    campos: [
      ["Desmontagem e limpeza química realizada?", "Sim / Não"],
      ["Lavagem química da serpentina realizada?", "Sim / Não"],
      ["Dreno e bandeja limpos com bactericida?", "Sim / Não"],
      ["Aplicação de antibactericida realizada?", "Sim / Não"],
      ["Ruídos e vibrações anormais verificados?", "Sim / Não"],
      ["Ausência de vazamentos confirmada?", "Sim / Não"],
      ["Verificação elétrica (terminais/conexões)?", "Sim / Não"],
      ["Isolamento térmico das linhas OK?", "Sim / Não"],
      ["Metros de isolamento trocados (m)", "Medição numérica"],
      ["Tensão elétrica medida (V)", "Medição numérica"],
      ["Corrente elétrica medida (A)", "Medição numérica"],
      ["Pressão do gás (PSI)", "Medição numérica"],
      ["Temperatura de retorno (°C)", "Medição numérica"],
      ["Temperatura de insuflamento (°C)", "Medição numérica"],
      ["Observações técnicas", "Texto livre"],
      ["Nome do responsável que acompanhou o serviço", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  },
  {
    titulo: "4. MANUTENÇÃO CORRETIVA",
    desc: "Atendimento a falhas ou defeitos identificados, com registro de causa, serviço executado e peças utilizadas.",
    campos: [
      ["Descrição do defeito", "Texto livre"],
      ["Causa provável identificada", "Texto livre"],
      ["Serviço realizado", "Texto livre"],
      ["Peças trocadas/utilizadas", "Texto livre"],
      ["NF / Requisição", "Texto livre"],
      ["Isolamento térmico verificado após serviço?", "Sim / Não"],
      ["Metros de isolamento trocados (m)", "Medição numérica"],
      ["Limpeza e higienização pós-serviço realizada?", "Sim / Não"],
      ["Tensão elétrica medida (V)", "Medição numérica"],
      ["Corrente elétrica medida (A)", "Medição numérica"],
      ["Pressão do gás (PSI)", "Medição numérica"],
      ["Temperatura de insuflamento (°C)", "Medição numérica"],
      ["Status operacional após serviço", "Texto livre"],
      ["Motivo de inoperância (se aplicável)", "Texto livre"],
      ["Nome do responsável que acompanhou o serviço", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  },
  {
    titulo: "5. SISTEMA DE EXAUSTÃO",
    desc: "Verificação e manutenção de ventiladores, exaustores e sistemas de circulação de ar.",
    campos: [
      ["Tipo de equipamento", "Texto livre"],
      ["Limpeza do rotor realizada?", "Sim / Não"],
      ["Estado das correias", "Texto livre"],
      ["Lubrificação dos mancais realizada?", "Sim / Não"],
      ["Fixação e vibração verificadas?", "Sim / Não"],
      ["Sensores de acionamento OK?", "Sim / Não"],
      ["Tensão elétrica medida (V)", "Medição numérica"],
      ["Corrente elétrica medida (A)", "Medição numérica"],
      ["Velocidade do ar (m/s)", "Medição numérica"],
      ["Filtros/telas limpos e íntegros?", "Sim / Não"],
      ["Status do equipamento", "Texto livre"],
      ["Nome do responsável que acompanhou o serviço", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  },
  {
    titulo: "6. CONTROLE DE PRESSÃO DE SALAS",
    desc: "Medição da pressurização diferencial em salas especiais (cirúrgicas, UTI, isolamento). Referência: ANVISA RDC 50/2002.",
    campos: [
      ["Pressão diferencial medida (Pa)", "Medição numérica"],
      ["Tipo de sala", "Texto livre"],
      ["Sala em conformidade com pressão exigida?", "Sim / Não"],
      ["Vedação de portas e janelas OK?", "Sim / Não"],
      ["Mola de porta funcionando corretamente?", "Sim / Não"],
      ["Situação do filtro HEPA", "Texto livre"],
      ["Status geral da sala", "Texto livre"],
      ["Observações", "Texto livre"],
      ["Nome do responsável que acompanhou o serviço", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  },
  {
    titulo: "7. QUALIDADE DO AR",
    desc: "Coleta e análise de parâmetros ambientais e microbiológicos. Referência: ANVISA RDC 50/2002 e RE 9/2003.",
    campos: [
      ["Ponto de coleta", "Texto livre"],
      ["Localização / descrição do local", "Texto livre"],
      ["Tipo de coleta", "Texto livre"],
      ["CO2 medido (ppm)", "Medição numérica"],
      ["Umidade relativa (%)", "Medição numérica"],
      ["Temperatura (°C)", "Medição numérica"],
      ["Velocidade do ar (m/s)", "Medição numérica"],
      ["ID da amostra microbiológica", "Texto livre"],
      ["Status da qualidade do ar", "Texto livre"],
      ["Observações", "Texto livre"],
      ["Nome do responsável que acompanhou o serviço", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  },
  {
    titulo: "8. MOVIMENTACAO DE EQUIPAMENTOS",
    desc: "Registro de transferências, substituições e remanejamentos de equipamentos entre setores do hospital.",
    campos: [
      ["Setor de origem", "Texto livre"],
      ["Tipo de movimentação", "Texto livre"],
      ["Motivo da movimentação", "Texto livre"],
      ["Setor de destino", "Texto livre"],
      ["Estado do equipamento", "Texto livre"],
      ["Acessórios incluídos", "Texto livre"],
      ["Proteção para transporte realizada?", "Sim / Não"],
      ["Observações", "Texto livre"],
      ["Nome do responsável que acompanhou", "Texto livre"],
      ["Chapa funcional do responsável", "Texto livre"],
    ]
  }
];

const rows = [];

// Título
const tituloCell = new TableCell({
  columnSpan: 4,
  shading: { type: ShadingType.SOLID, color: "003366", fill: "003366" },
  children: [
    new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "HOSPITAL UNIVERSITARIO DE LONDRINA - HU/UEL", bold: true, color: BRANCO, size: 30 })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "PLANO DE MANUTENCAO, OPERACAO E CONTROLE - PMOC", bold: true, color: BRANCO, size: 26 })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Modelo de Checklists - Campos Obrigatorios por Tipo de Servico", color: "BDD7EE", size: 22, italics: true })] }),
  ],
});
rows.push(new TableRow({ children: [tituloCell] }));

// Cabeçalho colunas
rows.push(new TableRow({ children: [hCell("#"), hCell("Campo / Verificação"), hCell("Tipo de Resposta"), hCell("Valor Registrado")] }));

for (const s of checklists) {
  rows.push(secRow(s.titulo));
  rows.push(descRow(s.desc));
  for (const r of commonRows()) rows.push(r);
  s.campos.forEach(([campo, tipo], i) => rows.push(dataRow(i + 1, campo, tipo)));
  for (const r of fotoRows()) rows.push(r);
}

const table = new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  columnWidths: [600, 5200, 2200, 1800],
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
        children: [new TextRun({ text: "Documento gerado pelo Sistema PMOC Digital — " + new Date().toLocaleDateString("pt-BR"), size: 16, color: "888888", italics: true })]
      }),
    ]
  }]
});

const buf = await Packer.toBuffer(doc);
fs.writeFileSync("c:/develop/pmoc/PMOC_Checklists_Licitacao.docx", buf);
console.log("Documento gerado: PMOC_Checklists_Licitacao.docx");
