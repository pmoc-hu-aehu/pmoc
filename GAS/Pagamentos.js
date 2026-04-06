/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Pagamentos.gs — TABELA DE PREÇOS + FECHAMENTO MENSAL
 *
 * Aba TABELA_PRECOS: [0]Tipo | [1]Valor | [2]Empresa | [3]Ativo
 *
 * Tabelas de checklists e coluna da data (índice 0 = dataInicio):
 *   FILTROS, DUTOS, CORRETIVAS, PREVENTIVAS, PRESSAO, QUALIDADE_AR,
 *   RETIRADA_MAQUINA, EXAUSTAO
 */

// ─── Mapeamento: tipo de serviço → aba + nome exibido ───────────────────────
var MAPA_ABAS = [
  { tipo: "Filtro",        aba: "FILTROS"        },
  { tipo: "Duto",          aba: "DUTOS"          },
  { tipo: "Corretiva",     aba: "CORRETIVAS"     },
  { tipo: "Preventiva",    aba: "PREVENTIVAS"    },
  { tipo: "Pressão",       aba: "PRESSAO"        },
  { tipo: "Qualidade Ar",  aba: "QUALIDADE_AR"   },
  { tipo: "Movimentação",  aba: "RETIRADA_MAQUINA"},
  { tipo: "Exaustão",      aba: "EXAUSTAO"       }
];

// ─── TABELA DE PREÇOS ────────────────────────────────────────────────────────

function getTabPrecos() {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("TABELA_PRECOS");
    if (!sheet) return [];
    var data  = sheet.getDataRange().getValues();
    var lista = [];
    for (var i = 1; i < data.length; i++) {
      if (!data[i][0]) continue;
      lista.push({
        id      : i + 1,
        tipo    : data[i][0] || "",
        valor   : parseFloat(data[i][1]) || 0,
        empresa : data[i][2] || "",
        ativo   : data[i][3] !== false && data[i][3] !== "Não"
      });
    }
    return lista;
  } catch(e) {
    Logger.log("Erro getTabPrecos: " + e.message);
    return [];
  }
}

function salvarPreco(dados) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("TABELA_PRECOS");
    if (!sheet) {
      sheet = ss.insertSheet("TABELA_PRECOS");
      sheet.appendRow(["Tipo de Serviço","Valor Unitário (R$)","Empresa","Ativo"]);
      sheet.getRange(1,1,1,4).setFontWeight("bold").setBackground("#0f172a").setFontColor("white");
    }

    var isNew = (!dados.id || dados.id === "" || dados.id === 0);
    var linha = [
      dados.tipo    || "",
      parseFloat((dados.valor || "0").toString().replace(",",".")) || 0,
      dados.empresa || "",
      dados.ativo === false ? "Não" : "Sim"
    ];

    if (isNew) {
      sheet.appendRow(linha);
    } else {
      sheet.getRange(parseInt(dados.id), 1, 1, 4).setValues([linha]);
    }
    return { sucesso: true, msg: "Preço salvo!" };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function excluirPreco(row) {
  try {
    var sheet = getPlanilha().getSheetByName("TABELA_PRECOS");
    if (!sheet) return { sucesso: false, msg: "Aba não encontrada." };
    sheet.deleteRow(parseInt(row));
    return { sucesso: true };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

// ─── FECHAMENTO MENSAL ───────────────────────────────────────────────────────

function getFechamentoMensal(mes, ano) {
  try {
    var ss      = getPlanilha();
    var precos  = getTabPrecos();
    var empresas = getListaEmpresas();

    // Limites do mês
    var dtIni = new Date(parseInt(ano), parseInt(mes) - 1, 1, 0, 0, 0);
    var dtFim = new Date(parseInt(ano), parseInt(mes),     0, 23, 59, 59);

    // Mapa tipo → { valor, empresa }
    var mapaPreco = {};
    precos.forEach(function(p) {
      if (p.ativo) mapaPreco[p.tipo] = { valor: p.valor, empresa: p.empresa };
    });

    // Detalhes de cada checklist executado
    var detalhes = [];

    MAPA_ABAS.forEach(function(m) {
      var sheet = ss.getSheetByName(m.aba);
      if (!sheet) return;
      var data = sheet.getDataRange().getValues();
      for (var i = 1; i < data.length; i++) {
        if (!data[i][0]) continue;
        var dtRaw = data[i][0];
        var dt = null;
        if (dtRaw instanceof Date) {
          dt = dtRaw;
        } else {
          // Tenta parsear string "dd/MM/yyyy" ou "yyyy-MM-dd"
          var partes = dtRaw.toString().split('/');
          if (partes.length === 3) {
            dt = new Date(parseInt(partes[2]), parseInt(partes[1]) - 1, parseInt(partes[0]));
          } else {
            dt = new Date(dtRaw);
          }
        }
        if (isNaN(dt.getTime())) continue;
        if (dt < dtIni || dt > dtFim) continue;

        var preco = mapaPreco[m.tipo] || { valor: 0, empresa: "" };
        // Estrutura padrão de todos os checklists:
        // col[0]=dataInicio, col[1]=horaIni, col[2]=dataFim, col[3]=horaFim,
        // col[4]=tecnico, col[5]=fuel, col[6]=localizacao
        detalhes.push({
          tipo    : m.tipo,
          data    : Utilities.formatDate(dt, "America/Sao_Paulo", "dd/MM/yyyy"),
          fuel    : (data[i][5] || "").toString().trim(),
          local   : (data[i][6] || "").toString().trim(),
          tecnico : (data[i][4] || "").toString().trim(),
          valor   : preco.valor,
          empresa : preco.empresa
        });
      }
    });

    // Agrupa por empresa
    var porEmpresa = {};
    detalhes.forEach(function(d) {
      var emp = d.empresa || "Sem empresa definida";
      if (!porEmpresa[emp]) porEmpresa[emp] = { empresa: emp, itens: [], total: 0 };
      porEmpresa[emp].itens.push(d);
      porEmpresa[emp].total += d.valor;
    });

    var resumo = Object.keys(porEmpresa).map(function(k) { return porEmpresa[k]; });

    // Total geral
    var totalGeral = detalhes.reduce(function(acc, d) { return acc + d.valor; }, 0);

    return {
      sucesso     : true,
      mes         : parseInt(mes),
      ano         : parseInt(ano),
      totalItens  : detalhes.length,
      totalGeral  : totalGeral,
      resumo      : resumo,
      detalhes    : detalhes
    };
  } catch(e) {
    Logger.log("Erro getFechamentoMensal: " + e.message);
    return { sucesso: false, msg: e.message };
  }
}
