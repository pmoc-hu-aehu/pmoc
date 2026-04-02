/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Auth.gs — LOGIN E CONTADORES
 */

function validarLogin(loginDigitado, senhaDigitada) {
  var planilha = getPlanilha();

  var abaTecnico = planilha.getSheetByName("TECNICO");
  if (abaTecnico) {
    var dadosTec = abaTecnico.getDataRange().getValues();
    for (var i = 1; i < dadosTec.length; i++) {
      if (dadosTec[i][1] == loginDigitado && dadosTec[i][2] == senhaDigitada) {
        var perfilTecnico = dadosTec[i][4] ? dadosTec[i][4].toString().toUpperCase().trim() : "";
        if (perfilTecnico === "" && dadosTec[i][0].toString().toUpperCase().includes("ADMIN")) {
          perfilTecnico = "ADMIN";
        } else if (perfilTecnico === "") {
          perfilTecnico = "BASICO";
        }
        return { sucesso: true, nome: dadosTec[i][0], tipo: "Técnico", perfil: perfilTecnico };
      }
    }
  }

  var abaEng = planilha.getSheetByName("ENGENHEIRO");
  if (abaEng) {
    var dadosEng = abaEng.getDataRange().getValues();
    for (var j = 1; j < dadosEng.length; j++) {
      if (dadosEng[j][2] == loginDigitado && dadosEng[j][3] == senhaDigitada) {
        return { sucesso: true, nome: dadosEng[j][0], tipo: "Engenheiro", perfil: "ENGENHEIRO" };
      }
    }
  }

  return { sucesso: false, mensagem: "Usuário ou senha incorretos!" };
}

function obterContadores() {
  var planilha = getPlanilha();
  var getCount = function(abaNome) {
    var aba = planilha.getSheetByName(abaNome);
    return aba ? Math.max(0, aba.getLastRow() - 1) : 0;
  };
  return {
    maquinas    : getCount("MAQUINAS"),
    engenheiros : getCount("ENGENHEIRO"),
    tecnicos    : getCount("TECNICO")
  };
}