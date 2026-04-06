/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Registro.gs — REGISTRO DE MANUTENÇÃO E LIMPEZA DE PROCESSAMENTO
 */

function limparLinhaProcessamento(fuel, tipo) {
  var ss      = getPlanilha();
  var abaProc = ss.getSheetByName("PROCESSAMENTO");
  var dados   = abaProc.getDataRange().getValues();

  for (var i = dados.length - 1; i >= 1; i--) {
    if (dados[i][0] == fuel && dados[i][1] == tipo) {
      abaProc.deleteRow(i + 1);
      break;
    }
  }
}

function registrarManutencaoNativa(dados) {
  try {
    var ss      = getPlanilha();
    var nomeAba = (dados.tipo === "FILTRO") ? "FILTROS" : "PREVENTIVAS";
    var sheet   = ss.getSheetByName(nomeAba);

    if (!sheet) {
      return jsonOut({ sucesso: false, msg: "Aba não encontrada" });
    }

    var hoje     = new Date();
    var linkFoto = "";

    if (dados.fotoB64 && dados.fotoB64 !== "") {
      linkFoto = salvarFotoDrive(dados.fotoB64, dados.fuel, dados.tecnico);
    }

    var novaLinha;

    if (dados.tipo === "FILTRO") {
      novaLinha     = Array(23).fill("");
      novaLinha[0]  = hoje;
      novaLinha[1]  = dados.tecnico;
      novaLinha[2]  = "Executado via APK Android";
      novaLinha[3]  = linkFoto;
      novaLinha[4]  = dados.gps;
      novaLinha[5]  = dados.fuel;
      novaLinha[6]  = dados.local;
      novaLinha[22] = "CONCLUIDO";
    } else {
      novaLinha     = Array(30).fill("");
      novaLinha[0]  = hoje;
      novaLinha[1]  = dados.tecnico;
      novaLinha[2]  = "Executado via APK Android";
      novaLinha[3]  = linkFoto;
      novaLinha[4]  = dados.gps;
      novaLinha[5]  = dados.fuel;
      novaLinha[6]  = dados.local;
      novaLinha[29] = "CONCLUIDO";
    }

    sheet.appendRow(novaLinha);
    limparLinhaProcessamento(dados.fuel, dados.tipo);

    return jsonOut({ sucesso: true, msg: "Sincronizado!", fuel: dados.fuel });

  } catch (e) {
    return jsonOut({ sucesso: false, msg: e.message });
  }
}