/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Agenda.gs — MOTOR DE AGENDAMENTO
 *
 * REGRAS DE ROTA:
 *   Seg–Qui  → HU  (localização começa com "HU/")
 *   Sexta    → AEHU (começa com "AEHU/")
 *   2ª Quinta do mês (tarde) → UCC (começa com "UCC")
 *
 * REGRAS DE SERVIÇO:
 *   FILTRO     → 30 dias fixo para TODOS
 *   PREVENTIVA → Alta: 30d | Média: 90d | Baixa: 180d
 *
 * REGRA DE SUPRESSÃO:
 *   Se a máquina já tem PREVENTIVA agendada/vencida no mês corrente
 *   → NÃO gera entrada de FILTRO para ela
 */

function get2aQuintaDoMes(ano, mes) {
  var count = 0;
  var d = new Date(ano, mes, 1);
  while (true) {
    if (d.getDay() === 4) {
      count++;
      if (count === 2) return new Date(d);
    }
    d.setDate(d.getDate() + 1);
  }
}

function atualizarAgendamentoGlobal() {
  var ss       = getPlanilha();
  var abaMaq   = ss.getSheetByName("MAQUINAS");
  var abaProc  = ss.getSheetByName("PROCESSAMENTO");
  var abaFiltros = ss.getSheetByName("FILTROS");
  var abaPrevs   = ss.getSheetByName("PREVENTIVAS");

  if (!abaMaq || !abaProc) return "ERRO: abas não encontradas";

  var maquinas   = abaMaq.getDataRange().getValues();
  var histFiltros = abaFiltros ? abaFiltros.getDataRange().getValues() : [];
  var histPrev    = abaPrevs   ? abaPrevs.getDataRange().getValues()   : [];

  var hoje    = new Date();
  hoje.setHours(0, 0, 0, 0);
  var anoHoje = hoje.getFullYear();
  var mesHoje = hoje.getMonth();

  // Monta set de FUELs com PREVENTIVA pendente no mês corrente
  var fuelsComPrevNoMes = {};
  for (var m = 1; m < maquinas.length; m++) {
    var fuel = String(maquinas[m][0]).trim();
    var crit = maquinas[m][5] ? maquinas[m][5].toString() : "Baixa";
    if (!fuel) continue;

    var prazoP = getPrazoPrev(crit);
    var ultP   = buscarDataHistorico(histPrev, fuel);
    var proxP  = new Date(ultP.getTime());
    proxP.setDate(proxP.getDate() + prazoP);

    if (proxP.getFullYear() === anoHoje && proxP.getMonth() === mesHoje) {
      fuelsComPrevNoMes[fuel] = true;
    }
    if (ultP.getFullYear() === anoHoje && ultP.getMonth() === mesHoje) {
      fuelsComPrevNoMes[fuel] = true;
    }
  }

  var resultados = [];

  for (var m = 1; m < maquinas.length; m++) {
    var fuel  = String(maquinas[m][0]).trim();
    var local = maquinas[m][1] || "N/A";
    var crit  = maquinas[m][5] ? maquinas[m][5].toString() : "Baixa";
    var setor = getSetorMaquina(local);
    if (!fuel) continue;

    // PREVENTIVA
    var prazoP = getPrazoPrev(crit);
    var ultP   = buscarDataHistorico(histPrev, fuel);
    var proxP  = new Date(ultP.getTime());
    proxP.setDate(proxP.getDate() + prazoP);
    var difP   = Math.ceil((proxP.getTime() - hoje.getTime()) / 86400000);
    var statusP = difP < 0 ? "VENCIDO" : (difP === 0 ? "HOJE" : "AGENDADO");
    resultados.push([fuel, "PREVENTIVA", ultP, prazoP, proxP, statusP, difP, local, crit, setor]);

    // FILTRO (suprimido se tem preventiva no mês)
    if (fuelsComPrevNoMes[fuel]) continue;

    var ultF  = buscarDataHistorico(histFiltros, fuel);
    var proxF = new Date(ultF.getTime());
    proxF.setDate(proxF.getDate() + PRAZO_FILTRO);
    var difF  = Math.ceil((proxF.getTime() - hoje.getTime()) / 86400000);
    var statusF = difF < 0 ? "VENCIDO" : (difF === 0 ? "HOJE" : "AGENDADO");
    resultados.push([fuel, "FILTRO", ultF, PRAZO_FILTRO, proxF, statusF, difF, local, crit, setor]);
  }

  // Ordena: vencidos primeiro, depois por dias asc, depois por setor, depois por local
  resultados.sort(function(a, b) {
    if (a[6] !== b[6]) return a[6] - b[6];
    if (a[9] !== b[9]) return (a[9] || "").localeCompare(b[9] || "");
    return (a[7] || "").localeCompare(b[7] || "");
  });

  // Regrava PROCESSAMENTO
  var ultimaLinha = abaProc.getLastRow();
  if (ultimaLinha > 1) {
    abaProc.getRange(2, 1, ultimaLinha - 1, 10).clearContent();
  }
  if (resultados.length > 0) {
    abaProc.getRange(2, 1, resultados.length, 10).setValues(resultados);
  }

  return "OK:" + resultados.length;
}

function buscarDataHistorico(dados, fuel) {
  var base = new Date(2024, 0, 1);
  if (!dados || dados.length === 0) return base;

  var melhor  = null;
  var fuelStr = String(fuel).trim();

  for (var i = dados.length - 1; i >= 1; i--) {
    if (String(dados[i][5]).trim() == fuelStr) {
      var d = new Date(dados[i][0]);
      if (!isNaN(d.getTime())) {
        if (!melhor || d > melhor) melhor = d;
      }
    }
  }
  return melhor || base;
}

function getAgendamentosAdmin(tipo) {
  var ss      = getPlanilha();
  var abaProc = ss.getSheetByName("PROCESSAMENTO");
  var dados   = abaProc.getDataRange().getValues();
  var lista   = [];

  for (var i = 1; i < dados.length; i++) {
    var row = dados[i];
    if (!row[0]) continue;
    if (tipo && row[1] !== tipo) continue;

    var proxData = "";
    var ultData  = "";
    try { proxData = Utilities.formatDate(new Date(row[4]), "GMT-3", "dd/MM/yyyy"); } catch(e) {}
    try { ultData  = Utilities.formatDate(new Date(row[2]), "GMT-3", "dd/MM/yyyy"); } catch(e) {}

    lista.push({
      fuel   : row[0],
      tipo   : row[1],
      ultima : ultData,
      prazo  : row[3],
      proxima: proxData,
      status : row[5],
      dias   : row[6],
      local  : row[7],
      crit   : row[8],
      setor  : row[9]
    });
  }
  return lista;
}

function getCronogramaAutoDia() {
  var hoje = new Date();
  var dow  = hoje.getDay();
  var mes  = hoje.getMonth();
  var ano  = hoje.getFullYear();

  var segunda_quinta = get2aQuintaDoMes(ano, mes);
  var is2aQuinta = (dow === 4 &&
    hoje.getDate()  === segunda_quinta.getDate() &&
    hoje.getMonth() === segunda_quinta.getMonth());

  if (is2aQuinta) return { setor: "UCC",  tipo: "PREVENTIVA", motivo: "2ª Quinta — UCC Preventiva" };
  if (dow >= 1 && dow <= 4) return { setor: "HU",   tipo: "FILTRO", motivo: "Seg–Qui — HU Filtro" };
  if (dow === 5)            return { setor: "AEHU", tipo: "FILTRO", motivo: "Sexta — AEHU Filtro" };
  return { setor: "HU", tipo: "FILTRO", motivo: "Fora da semana útil — padrão HU" };
}