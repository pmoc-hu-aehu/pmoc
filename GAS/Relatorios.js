/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Relatorios.gs — RELATÓRIOS E DASHBOARD
 */

function getRelatorio(filtros) {
  var ss = getPlanilha();

  var abas = [
    { nome: "FILTROS",      tipo: "Filtro",       colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto: 16, colStatus: 22 },
    { nome: "PREVENTIVAS",  tipo: "Preventiva",   colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto: 24, colStatus: 29 },
    { nome: "CORRETIVAS",   tipo: "Corretiva",    colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto:  8, colStatus: 27 },
    { nome: "DUTOS",        tipo: "Duto",         colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto:  8, colStatus: 17 },
    { nome: "EXAUSTAO",     tipo: "Exaustão",     colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto: 21, colStatus: 25 },
    { nome: "MOVIMENTACAO", tipo: "Movimentação", colFuel: 2, colTec: 1, colDataIni: 0, colDataFim: 0, colLocal: 3, colFoto: 13, colStatus: 17 },
    { nome: "PRESSAO",      tipo: "Pressão",      colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto: 19, colStatus: 20 },
    { nome: "QUALIDADE_AR", tipo: "Qualidade Ar", colFuel: 5, colTec: 4, colDataIni: 0, colDataFim: 2, colLocal: 6, colFoto: 15, colStatus: 20 }
  ];

  var dataIni   = filtros.dataIni   ? new Date(filtros.dataIni)   : null;
  var dataFim   = filtros.dataFim   ? new Date(filtros.dataFim)   : null;
  if (dataFim) dataFim.setHours(23, 59, 59);

  var fuelFiltro = filtros.fuel     ? filtros.fuel.toString().trim().toUpperCase()     : "";
  var tecFiltro  = filtros.tecnico  ? filtros.tecnico.toString().trim().toUpperCase()  : "";
  var tipoFiltro = filtros.tipo     ? filtros.tipo.toString().trim()                   : "";

  var resultado = [];

  abas.forEach(function(aba) {
    if (tipoFiltro && tipoFiltro !== "TODOS" && tipoFiltro !== aba.tipo) return;

    var sheet = ss.getSheetByName(aba.nome);
    if (!sheet || sheet.getLastRow() < 2) return;

    var dados = sheet.getDataRange().getValues();

    for (var i = 1; i < dados.length; i++) {
      var row        = dados[i];
      var fuel       = String(row[aba.colFuel]  || "").trim();
      var tec        = String(row[aba.colTec]   || "").trim();
      var local      = String(row[aba.colLocal] || "").trim();
      var foto       = String(row[aba.colFoto]  || "").trim();
      var dataIniRow = row[aba.colDataIni] ? new Date(row[aba.colDataIni]) : null;
      var dataFimRow = row[aba.colDataFim] ? new Date(row[aba.colDataFim]) : null;

      if (!fuel || !dataIniRow || isNaN(dataIniRow.getTime())) continue;
      if (dataIni && dataIniRow < dataIni) continue;
      if (dataFim && dataIniRow > dataFim) continue;
      if (fuelFiltro && !fuel.toUpperCase().includes(fuelFiltro)) continue;
      if (tecFiltro  && !tec.toUpperCase().includes(tecFiltro))   continue;

      var horaIni = "";
      var horaFim = "";
      var dataFmt = "";
      try { horaIni = Utilities.formatDate(dataIniRow, "GMT-3", "HH:mm"); } catch(e) {}
      try { if (dataFimRow && !isNaN(dataFimRow.getTime())) horaFim = Utilities.formatDate(dataFimRow, "GMT-3", "HH:mm"); } catch(e) {}
      try { dataFmt = Utilities.formatDate(dataIniRow, "GMT-3", "dd/MM/yyyy"); } catch(e) {}

      resultado.push({
        tipo   : aba.tipo,
        fuel   : fuel,
        local  : local,
        tecnico: tec,
        data   : dataFmt,
        horaIni: horaIni,
        horaFim: horaFim,
        foto   : foto,
        ts     : dataIniRow.getTime()
      });
    }
  });

  resultado.sort(function(a, b) { return b.ts - a.ts; });
  return resultado;
}

function getListaTecnicosRelatorio() {
  try {
    var data = getPlanilha().getSheetByName("TECNICO").getDataRange().getValues();
    return data.slice(1).map(function(r) { return r[0]; }).filter(Boolean);
  } catch(e) { return []; }
}

function obterContadoresDashboard() {
  try {
    var ss       = getPlanilha();
    var agora    = new Date();
    var hoje     = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate());
    var inicioMes = new Date(agora.getFullYear(), agora.getMonth(), 1);
    var inicioAno = new Date(agora.getFullYear(), 0, 1);

    function contarAba(nomeAba, colData) {
      var aba = ss.getSheetByName(nomeAba);
      if (!aba || aba.getLastRow() < 2) return { hoje: 0, mes: 0, ano: 0 };
      var dados = aba.getRange(2, colData + 1, aba.getLastRow() - 1, 1).getValues();
      var cHoje = 0, cMes = 0, cAno = 0;
      dados.forEach(function(row) {
        var d = new Date(row[0]);
        if (isNaN(d.getTime())) return;
        var dSoData = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        if (dSoData >= inicioAno) cAno++;
        if (dSoData >= inicioMes) cMes++;
        if (dSoData.getTime() === hoje.getTime()) cHoje++;
      });
      return { hoje: cHoje, mes: cMes, ano: cAno };
    }

    function contarMovimentacao() {
      var aba = ss.getSheetByName("MOVIMENTACAO");
      if (!aba || aba.getLastRow() < 2) return { hoje: 0, mes: 0, ano: 0 };
      var dados = aba.getRange(2, 1, aba.getLastRow() - 1, 1).getValues();
      var cHoje = 0, cMes = 0, cAno = 0;
      dados.forEach(function(row) {
        var val = row[0];
        var d;
        if (val instanceof Date) {
          d = val;
        } else {
          var partes = String(val).split(" ");
          if (partes.length < 1) return;
          var dp = partes[0].split("/");
          if (dp.length < 3) return;
          d = new Date(parseInt(dp[2]), parseInt(dp[1]) - 1, parseInt(dp[0]));
        }
        if (isNaN(d.getTime())) return;
        var dSoData = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        if (dSoData >= inicioAno) cAno++;
        if (dSoData >= inicioMes) cMes++;
        if (dSoData.getTime() === hoje.getTime()) cHoje++;
      });
      return { hoje: cHoje, mes: cMes, ano: cAno };
    }

    return {
      filtros     : contarAba("FILTROS",     0),
      preventivas : contarAba("PREVENTIVAS", 0),
      corretivas  : contarAba("CORRETIVAS",  0),
      movimentacao: contarMovimentacao(),
      dutos       : contarAba("DUTOS",       0),
      pressao     : contarAba("PRESSAO",     0),
      qualidadeAr : contarAba("QUALIDADE_AR",0),
      exaustao    : contarAba("EXAUSTAO",    0)
    };
  } catch(e) {
    return null;
  }
}