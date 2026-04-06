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