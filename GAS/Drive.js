/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Drive.gs — UPLOAD DE FOTOS NO GOOGLE DRIVE
 */

function salvarFotoDrive(b64, fuel, tecnico) {
  try {
    var folder   = DriveApp.getFolderById(ID_PASTA_RAIZ);
    var pastaTec = getOrCreateFolder(folder, tecnico);
    var blob     = Utilities.newBlob(
      Utilities.base64Decode(b64),
      "image/jpeg",
      "MANUT_" + fuel + "_" + tecnico + "_" + new Date().getTime() + ".jpg"
    );
    var arquivo = pastaTec.createFile(blob);
    arquivo.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return arquivo.getUrl();
  } catch(e) {
    return "Erro foto: " + e.message;
  }
}

function getOrCreateFolder(parent, name) {
  var folders = parent.getFoldersByName(name);
  return folders.hasNext() ? folders.next() : parent.createFolder(name);
}