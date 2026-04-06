/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Maquina.gs — GESTÃO DE MÁQUINAS (CRUD)
 */

function _garantirCabecalhosMaquinas(sheet) {
  var cab = sheet.getRange(1, 1, 1, 11).getValues()[0];
  var esperado = ["FUEL","LOCALIZACAO","MODELO","MARCA","SERIE","CRITICIDADE","CAPACIDADE",
                  "EMPRESA_CNPJ","OCUPANTES_FIXOS","OCUPANTES_VARIAVEIS","AREA_M2"];
  for (var c = 0; c < esperado.length; c++) {
    if (!cab[c] || cab[c] === "") {
      sheet.getRange(1, c + 1).setValue(esperado[c]);
    }
  }
}

function salvarMaquinaBD(dados) {
  try {
    var ss = getPlanilha();
    var sheet = ss.getSheetByName("MAQUINAS");
    _garantirCabecalhosMaquinas(sheet);
    var data = sheet.getDataRange().getValues();

    var isNew    = (dados.id === "" || dados.id === null || dados.id === undefined);
    var updateRow = isNew ? -1 : parseInt(dados.id);
    var fuelNovo  = dados.fuel.toString().trim();

    for (var i = 1; i < data.length; i++) {
      if (!isNew && (i + 1) === updateRow) continue;
      var fuelBanco = data[i][0] ? data[i][0].toString().trim() : "";
      if (fuelBanco === fuelNovo) return { sucesso: false, msg: "ERRO: Já existe este FUEL!" };
    }

    if (isNew) {
      sheet.appendRow([dados.fuel, dados.localizacao, dados.modelo, dados.marca, dados.serie, dados.criticidade, dados.capacidade, dados.empresaCnpj || "", dados.ocupantesFixos || "", dados.ocupantesVariaveis || "", dados.areaM2 || ""]);
    } else {
      sheet.getRange(updateRow, 1, 1, 11).setValues([[dados.fuel, dados.localizacao, dados.modelo, dados.marca, dados.serie, dados.criticidade, dados.capacidade, dados.empresaCnpj || "", dados.ocupantesFixos || "", dados.ocupantesVariaveis || "", dados.areaM2 || ""]]);
    }

    atualizarAgendamentoGlobal();
    return { sucesso: true, msg: "Máquina salva e agenda atualizada!" };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function getListaMaquinas() {
  try {
    var data = getPlanilha().getSheetByName("MAQUINAS").getDataRange().getValues();
    var lista = [];
    for (var i = 1; i < data.length; i++) {
      if (data[i][0]) {
        lista.push({
          id                : i + 1,
          fuel              : data[i][0],
          localizacao       : data[i][1],
          modelo            : data[i][2],
          marca             : data[i][3],
          serie             : data[i][4],
          criticidade       : data[i][5],
          capacidade        : data[i][6],
          empresaCnpj       : data[i][7]  || "",
          ocupantesFixos    : data[i][8]  || "",
          ocupantesVariaveis: data[i][9]  || "",
          areaM2            : data[i][10] || ""
        });
      }
    }
    return lista;
  } catch(e) { return []; }
}

function listarMaquinasApp() {
  try {
    var lista = getListaMaquinas();
    return { sucesso: true, maquinas: lista };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function excluirMaquinaBD(row) {
  try {
    getPlanilha().getSheetByName("MAQUINAS").deleteRow(parseInt(row));
    atualizarAgendamentoGlobal();
    return { sucesso: true, msg: "Máquina excluída!" };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function buscarMaquinaPorFuel(fuel) {
  try {
    var ss     = getPlanilha();
    var sheet  = ss.getSheetByName("MAQUINAS");
    var dados  = sheet.getDataRange().getValues();
    var fuelBusca = String(fuel).trim();

    for (var i = 1; i < dados.length; i++) {
      var fuelPlanilha = String(dados[i][0]).trim();
      if (fuelPlanilha === fuelBusca) {
        return {
          sucesso: true,
          maquina: {
            fuel               : fuelPlanilha,
            localizacao        : dados[i][1]  || "",
            modelo             : dados[i][2]  || "",
            marca              : dados[i][3]  || "",
            serie              : dados[i][4]  || "",
            criticidade        : dados[i][5]  || "",
            capacidade         : dados[i][6]  || "",
            empresaCnpj        : dados[i][7]  || "",
            ocupantesFixos     : dados[i][8]  || "",
            ocupantesVariaveis : dados[i][9]  || "",
            areaM2             : dados[i][10] || ""
          }
        };
      }
    }
    return { sucesso: false, mensagem: "Máquina não encontrada!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

// ─── VERIFICAR SE MÁQUINA JÁ FOI LIMPA NO MÊS ───────────────────────────────
function verificarLimpezaMes(fuel, tipo) {
  try {
    var ss    = getPlanilha();
    var nomeAba = (tipo === 'DUTO') ? 'DUTOS' : 'FILTROS';
    var sheet = ss.getSheetByName(nomeAba);
    if (!sheet || sheet.getLastRow() < 2) return { sucesso: true, jaLimpa: false };

    var agora   = new Date();
    var mesAtual = agora.getMonth();
    var anoAtual = agora.getFullYear();
    var fuelBusca = String(fuel).trim();

    var dados = sheet.getDataRange().getValues();
    for (var i = 1; i < dados.length; i++) {
      var fuelLinha = String(dados[i][5]).trim(); // coluna F = FUEL
      if (fuelLinha !== fuelBusca) continue;

      // Tenta parsear a data (coluna A = DATA_INICIO, formato dd/MM/yyyy)
      var dataVal = dados[i][0];
      var d;
      if (dataVal instanceof Date) {
        d = dataVal;
      } else {
        var partes = String(dataVal).split('/');
        if (partes.length < 3) continue;
        d = new Date(parseInt(partes[2]), parseInt(partes[1]) - 1, parseInt(partes[0]));
      }
      if (isNaN(d.getTime())) continue;

      if (d.getMonth() === mesAtual && d.getFullYear() === anoAtual) {
        // Encontrou limpeza no mês — verifica se há autorização
        var autorizado = verificarAutorizacao(fuelBusca, tipo, mesAtual, anoAtual);
        return { sucesso: true, jaLimpa: true, autorizado: autorizado };
      }
    }

    return { sucesso: true, jaLimpa: false };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

// ─── VERIFICAR SE HÁ AUTORIZAÇÃO PARA RELIMPEZA ──────────────────────────────
function verificarAutorizacao(fuel, tipo, mes, ano) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName('AUTORIZACOES');
    if (!sheet || sheet.getLastRow() < 2) return false;

    var dados = sheet.getDataRange().getValues();
    for (var i = 1; i < dados.length; i++) {
      if (String(dados[i][0]).trim() !== String(fuel).trim()) continue;
      if (String(dados[i][1]).trim().toUpperCase() !== tipo.toUpperCase()) continue;
      var mesAuth = parseInt(dados[i][2]);
      var anoAuth = parseInt(dados[i][3]);
      var usada   = dados[i][4];
      if (mesAuth === mes && anoAuth === ano && !usada) return true;
    }
    return false;
  } catch(e) {
    return false;
  }
}

// ─── AUTORIZAR RELIMPEZA (chamado pelo admin no painel web) ──────────────────
function autorizarRelimpeza(fuel, tipo) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName('AUTORIZACOES');
    if (!sheet) {
      sheet = ss.insertSheet('AUTORIZACOES');
      sheet.appendRow(['FUEL', 'TIPO', 'MES', 'ANO', 'USADA', 'AUTORIZADO_POR', 'DATA_AUTORIZACAO']);
    }

    var agora = new Date();
    sheet.appendRow([
      fuel,
      tipo,
      agora.getMonth(),
      agora.getFullYear(),
      false,
      Session.getActiveUser().getEmail(),
      Utilities.formatDate(agora, 'GMT-3', 'dd/MM/yyyy HH:mm')
    ]);
    return { sucesso: true, msg: 'Relimpeza autorizada para FUEL ' + fuel + ' (' + tipo + ')' };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

// ─── MARCAR AUTORIZAÇÃO COMO USADA ───────────────────────────────────────────
function marcarAutorizacaoUsada(fuel, tipo) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName('AUTORIZACOES');
    if (!sheet || sheet.getLastRow() < 2) return;

    var agora    = new Date();
    var mesAtual = agora.getMonth();
    var anoAtual = agora.getFullYear();
    var dados    = sheet.getDataRange().getValues();

    for (var i = 1; i < dados.length; i++) {
      if (String(dados[i][0]).trim() !== String(fuel).trim()) continue;
      if (String(dados[i][1]).trim().toUpperCase() !== tipo.toUpperCase()) continue;
      if (parseInt(dados[i][2]) !== mesAtual || parseInt(dados[i][3]) !== anoAtual) continue;
      if (dados[i][4]) continue; // já usada
      sheet.getRange(i + 1, 5).setValue(true);
      return;
    }
  } catch(e) {}
}