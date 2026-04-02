/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Config.gs — CONSTANTES E CONFIGURAÇÕES GLOBAIS
 */

var ID_PLANILHA   = "1jHgqD0f7t-0OHex6BJe8SnLYcd8xf0CzrzlLoaWVfkc";
var ID_PASTA_RAIZ = "1OljDAPJZ5uv1Q66NWY3pvgVoTpBkjUwc";
var PRAZO_FILTRO  = 30;

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