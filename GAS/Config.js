/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Config.gs — CONSTANTES E CONFIGURAÇÕES GLOBAIS
 */

var ID_PLANILHA   = "1jHgqD0f7t-0OHex6BJe8SnLYcd8xf0CzrzlLoaWVfkc";
var ID_PASTA_RAIZ = "1OljDAPJZ5uv1Q66NWY3pvgVoTpBkjUwc";
var PRAZO_FILTRO  = 30;

// ID da foto de fundo da tela de login (arquivo no Google Drive - deve ser público)
// Para atualizar: faça upload da foto no Drive, compartilhe publicamente,
// copie o FILE_ID da URL e cole aqui.
var BG_FOTO_ID = "1QDdt_Zishx06iJ4kAFrlR1We7EIMmTP7"; // ar condicionado.png

// ID do APK no Google Drive para distribuição
var APK_FILE_ID = "1sH3zB1iOw1T54VO-xk8IiIBZbswSg-Zc";
var APK_VERSAO  = "1.0.0";

function getBgUrl() {
  if (!BG_FOTO_ID || BG_FOTO_ID === "") {
    return "https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=1600&q=80";
  }
  try {
    var f = DriveApp.getFileById(BG_FOTO_ID);
    f.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    // Retorna a imagem como base64 inline — garante que aparece sem CORS
    var blob  = f.getBlob().getAs('image/jpeg');
    var b64   = Utilities.base64Encode(blob.getBytes());
    return "data:image/jpeg;base64," + b64;
  } catch(e) {
    return "https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=1600&q=80";
  }
}

function listarArquivosPasta(pastaId) {
  try {
    var pasta   = DriveApp.getFolderById(pastaId || "1Bv1P5WU9d2stbmEQfgAm4L-Ra57SSDSy");
    var files   = pasta.getFiles();
    var result  = [];
    while (files.hasNext()) {
      var f = files.next();
      result.push({ nome: f.getName(), id: f.getId(), tipo: f.getMimeType(), tamanho: f.getSize() });
    }
    return { sucesso: true, arquivos: result };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function salvarFotoFundoDrive(base64Data, mimeType) {
  try {
    var pasta    = DriveApp.getFolderById(ID_PASTA_RAIZ);
    var decoded  = Utilities.base64Decode(base64Data.split(',')[1] || base64Data);
    var blob     = Utilities.newBlob(decoded, mimeType || 'image/jpeg', 'bg_login.jpg');
    // Remove arquivo anterior se existir
    var files = pasta.getFilesByName('bg_login.jpg');
    while (files.hasNext()) { files.next().setTrashed(true); }
    var arquivo = pasta.createFile(blob);
    arquivo.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return { sucesso: true, fileId: arquivo.getId(), url: "https://drive.google.com/uc?export=view&id=" + arquivo.getId() };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function getPlanilha() {
  return SpreadsheetApp.openById(ID_PLANILHA);
}

function getPrazoPrev(criticidade) {
  var c = (criticidade || "").toString().toUpperCase().trim()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (c === "ALTA")  return 30;
  if (c === "MEDIA") return 90;
  return 180;
}

function getSetorMaquina(local) {
  var l = (local || "").toString().toUpperCase().trim();
  if (l.indexOf("UCC")  === 0) return "UCC";
  if (l.indexOf("AEHU") === 0) return "AEHU";
  if (l.indexOf("HU/")  === 0) return "HU";
  return "HU";
}

// ─── SETORES ─────────────────────────────────────────────────────────────────

// Extrai o setor de uma localizacao completa: "HU/CME/SECRETARIA" → "HU/CME"
function _extrairSetor(localizacao) {
  var s = String(localizacao || "").trim();
  var partes = s.split('/');
  // setor = primeiras 2 partes (ex: HU + CME), resto é local específico
  if (partes.length >= 2) return (partes[0] + '/' + partes[1]).trim();
  return s; // sem barra: usa o valor inteiro como setor
}

function _getAbaSetores() {
  var ss = getPlanilha();
  var sheet = ss.getSheetByName("SETORES");
  if (!sheet) {
    sheet = ss.insertSheet("SETORES");
    sheet.appendRow(["NOME"]);
    var maqSheet = ss.getSheetByName("MAQUINAS");
    if (maqSheet && maqSheet.getLastRow() > 1) {
      var dados = maqSheet.getRange(2, 2, maqSheet.getLastRow()-1, 1).getValues();
      var vistos = {};
      dados.forEach(function(r) {
        var setor = _extrairSetor(r[0]);
        if (setor && !vistos[setor]) { vistos[setor] = true; sheet.appendRow([setor]); }
      });
    }
  }
  return sheet;
}

// Corrige aba SETORES existente que tenha valores com local específico embutido
function corrigirSetores() {
  var ss = getPlanilha();
  var sheet = ss.getSheetByName("SETORES");
  if (!sheet || sheet.getLastRow() < 2) return;
  var dados = sheet.getRange(2, 1, sheet.getLastRow()-1, 1).getValues();
  var vistos = {};
  // reconstrói a aba com valores corrigidos
  var corretos = [];
  dados.forEach(function(r) {
    var setor = _extrairSetor(r[0]);
    if (setor && !vistos[setor]) { vistos[setor] = true; corretos.push([setor]); }
  });
  // limpa e reescreve
  if (sheet.getLastRow() > 1) sheet.deleteRows(2, sheet.getLastRow()-1);
  if (corretos.length > 0) sheet.getRange(2, 1, corretos.length, 1).setValues(corretos);
}

function getListaSetores() {
  try {
    var sheet = _getAbaSetores();
    if (sheet.getLastRow() < 2) return [];
    // corrige automaticamente se ainda houver valores com local específico embutido
    var dados = sheet.getRange(2, 1, sheet.getLastRow()-1, 1).getValues();
    var temErro = dados.some(function(r){ return String(r[0]).split('/').length > 2; });
    if (temErro) corrigirSetores();
    // relê após possível correção
    sheet = _getAbaSetores();
    if (sheet.getLastRow() < 2) return [];
    return sheet.getRange(2, 1, sheet.getLastRow()-1, 1).getValues()
      .map(function(r){ return String(r[0]).trim(); })
      .filter(Boolean)
      .sort();
  } catch(e) { return []; }
}

function salvarSetor(nome, nomeAntigo) {
  try {
    nome = String(nome || "").trim();
    if (!nome) return { sucesso: false, msg: "Nome inválido." };
    var sheet = _getAbaSetores();
    var dados = sheet.getLastRow() > 1
      ? sheet.getRange(2, 1, sheet.getLastRow()-1, 1).getValues()
      : [];

    // edição: nomeAntigo definido
    if (nomeAntigo) {
      nomeAntigo = String(nomeAntigo).trim();
      for (var i = 0; i < dados.length; i++) {
        if (String(dados[i][0]).trim() === nomeAntigo) {
          sheet.getRange(i+2, 1).setValue(nome);
          // atualiza MAQUINAS
          _renomearSetorMaquinas(nomeAntigo, nome);
          return { sucesso: true, msg: "Setor renomeado!" };
        }
      }
      return { sucesso: false, msg: "Setor não encontrado." };
    }

    // novo — verifica duplicata
    for (var j = 0; j < dados.length; j++) {
      if (String(dados[j][0]).trim().toLowerCase() === nome.toLowerCase()) {
        return { sucesso: false, msg: "Já existe setor com este nome." };
      }
    }
    sheet.appendRow([nome]);
    return { sucesso: true, msg: "Setor adicionado!" };
  } catch(e) { return { sucesso: false, msg: e.message }; }
}

function excluirSetor(nome) {
  try {
    nome = String(nome || "").trim();
    var sheet = _getAbaSetores();
    if (sheet.getLastRow() < 2) return { sucesso: false, msg: "Setor não encontrado." };
    var dados = sheet.getRange(2, 1, sheet.getLastRow()-1, 1).getValues();
    for (var i = 0; i < dados.length; i++) {
      if (String(dados[i][0]).trim() === nome) {
        sheet.deleteRow(i+2);
        return { sucesso: true, msg: "Setor excluído!" };
      }
    }
    return { sucesso: false, msg: "Setor não encontrado." };
  } catch(e) { return { sucesso: false, msg: e.message }; }
}

function _renomearSetorMaquinas(antigo, novo) {
  try {
    var sheet = getPlanilha().getSheetByName("MAQUINAS");
    if (!sheet || sheet.getLastRow() < 2) return;
    var dados = sheet.getRange(2, 2, sheet.getLastRow()-1, 1).getValues();
    dados.forEach(function(r, i) {
      if (String(r[0]).trim() === antigo) {
        sheet.getRange(i+2, 2).setValue(novo);
      }
    });
  } catch(e) {}
}