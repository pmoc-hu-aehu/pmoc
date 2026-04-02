/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Equipe.gs — GESTÃO DE TÉCNICOS E ENGENHEIROS
 */

// ---------- TÉCNICOS ----------

function salvarTecnicoBD(dados) {
  var sheet = getPlanilha().getSheetByName("TECNICO");
  if (dados.id) {
    sheet.getRange(parseInt(dados.id), 1, 1, 5).setValues([[dados.nome, dados.login, dados.senha, dados.fone, dados.perfil]]);
  } else {
    sheet.appendRow([dados.nome, dados.login, dados.senha, dados.fone, dados.perfil]);
  }
  return { sucesso: true, msg: "Técnico salvo!" };
}

function getListaTecnicos() {
  var data = getPlanilha().getSheetByName("TECNICO").getDataRange().getValues();
  return data.slice(1).map(function(r, i) {
    return { id: i + 2, nome: r[0], login: r[1], senha: r[2], fone: r[3], perfil: r[4] };
  });
}

function excluirTecnicoBD(row) {
  getPlanilha().getSheetByName("TECNICO").deleteRow(parseInt(row));
  return { sucesso: true };
}

// ---------- ENGENHEIROS ----------

function salvarEngenheiroBD(dados) {
  var sheet = getPlanilha().getSheetByName("ENGENHEIRO");
  if (dados.id) {
    sheet.getRange(parseInt(dados.id), 1, 1, 6).setValues([[dados.nome, dados.crea, dados.login, dados.senha, dados.fone, dados.email]]);
  } else {
    sheet.appendRow([dados.nome, dados.crea, dados.login, dados.senha, dados.fone, dados.email]);
  }
  return { sucesso: true, msg: "Engenheiro salvo!" };
}

function getListaEngenheiros() {
  var data = getPlanilha().getSheetByName("ENGENHEIRO").getDataRange().getValues();
  return data.slice(1).map(function(r, i) {
    return { id: i + 2, nome: r[0], crea: r[1], login: r[2], senha: r[3], fone: r[4], email: r[5] };
  });
}

function excluirEngenheiroBD(row) {
  getPlanilha().getSheetByName("ENGENHEIRO").deleteRow(parseInt(row));
  return { sucesso: true };
}