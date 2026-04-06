/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Apk.gs — GERENCIAMENTO DO APK DE DISTRIBUIÇÃO
 */

// ─── CONFIGURAR APK ──────────────────────────────────────────────────────────

/**
 * Chame esta função UMA VEZ depois de subir o APK no Google Drive.
 * Cole o FILE ID do arquivo no Drive (não a URL completa).
 * Ex: setApkDriveId("1aBcDeFgHiJkLmNoPqRsTuVwXyZ")
 */
function setApkDriveId(fileId, versao) {
  var props = PropertiesService.getScriptProperties();
  props.setProperty('APK_FILE_ID', fileId || '');
  props.setProperty('APK_VERSAO',  versao  || '1.0.0');
  props.setProperty('APK_DATA',    Utilities.formatDate(new Date(), 'GMT-3', 'dd/MM/yyyy'));
  return { sucesso: true, msg: 'APK configurado! File ID: ' + fileId };
}

// ─── LER INFORMAÇÕES DO APK ──────────────────────────────────────────────────

function getInfoApk() {
  try {
    var props  = PropertiesService.getScriptProperties();
    var fileId = props.getProperty('APK_FILE_ID') || '';
    var versao = props.getProperty('APK_VERSAO')  || '1.0.0';
    var data   = props.getProperty('APK_DATA')    || '—';

    var url = '';
    if (fileId) {
      // Garante que o arquivo está público (qualquer pessoa com o link)
      try {
        var file = DriveApp.getFileById(fileId);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        // Link de download direto (força download sem abrir preview)
        url = 'https://drive.google.com/uc?export=download&id=' + fileId;
      } catch(e2) {
        url = '';
      }
    }

    return { sucesso: true, url: url, versao: versao, dataApk: data };
  } catch(e) {
    return { sucesso: false, url: '', versao: '—', dataApk: '—' };
  }
}

// ─── SUBIR APK NOVO (chame do editor GAS após upload manual no Drive) ────────

/**
 * Utilitário: lista arquivos APK na pasta raiz do projeto para achar o ID.
 * Execute no editor GAS e veja o Log para pegar o file ID.
 */
function listarApksNaPasta() {
  var pasta = DriveApp.getFolderById(ID_PASTA_RAIZ);
  var files = pasta.getFiles();
  while (files.hasNext()) {
    var f = files.next();
    if (f.getName().toLowerCase().indexOf('.apk') >= 0) {
      Logger.log('Nome: ' + f.getName() + ' | ID: ' + f.getId() + ' | Data: ' +
        Utilities.formatDate(f.getDateCreated(), 'GMT-3', 'dd/MM/yyyy HH:mm'));
    }
  }
}
