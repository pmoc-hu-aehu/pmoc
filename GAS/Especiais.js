/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Especiais.gs — PRESSÃO, QUALIDADE AR, RETIRADA, EXAUSTÃO
 */

function salvarPressaoMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("PRESSAO");
    if (!sheet) sheet = ss.insertSheet("PRESSAO");

    var linkManometro  = "";
    var linkAssinatura = "";
    if (payload.fotoManometroB64) linkManometro  = salvarFotoDrive(payload.fotoManometroB64, "PRES_MAN_" + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64)    linkAssinatura = salvarFotoDrive(payload.assinaturaB64,    "PRES_ASS_" + payload.fuel, payload.tecnico);

    var linha = Array(21).fill("");
    linha[0]  = new Date(payload.dataInicio);
    linha[1]  = Utilities.formatDate(new Date(payload.dataInicio), "GMT-3", "HH:mm:ss");
    linha[2]  = payload.dataFinal ? new Date(payload.dataFinal) : "";
    linha[3]  = payload.dataFinal ? Utilities.formatDate(new Date(payload.dataFinal), "GMT-3", "HH:mm:ss") : "";
    linha[4]  = payload.tecnico;
    linha[5]  = payload.fuel;
    linha[6]  = payload.local || "";
    linha[7]  = (payload.latitude && payload.longitude) ? payload.latitude + "," + payload.longitude : "";
    linha[8]  = linkManometro;
    linha[9]  = payload.pressaoPascal  || "";
    linha[10] = payload.tipoSala       || "";
    linha[11] = payload.conformidade   ? "SIM" : "NÃO";
    linha[12] = payload.vedacaoPortas  ? "SIM" : "NÃO";
    linha[13] = payload.molaporta      ? "SIM" : "NÃO";
    linha[14] = payload.filtroHepa     || "";
    linha[15] = payload.statusSala     || "";
    linha[16] = payload.observacoes    || "";
    linha[17] = payload.nomeChefe      || "";
    linha[18] = payload.chapaFuncional || "";
    linha[19] = linkAssinatura;
    linha[20] = "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Checklist Pressão salvo!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarQualidadeArMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("QUALIDADE_AR");
    if (!sheet) sheet = ss.insertSheet("QUALIDADE_AR");

    var linkColeta     = "";
    var linkAssinatura = "";
    if (payload.fotoColetaB64) linkColeta     = salvarFotoDrive(payload.fotoColetaB64, "QAR_COL_" + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64) linkAssinatura = salvarFotoDrive(payload.assinaturaB64, "QAR_ASS_" + payload.fuel, payload.tecnico);

    var obs = [];
    if (payload.materialParticulado) obs.push("Particulado: " + payload.materialParticulado);
    if (payload.dataProximaAnalise)  obs.push("Próx. Análise: " + payload.dataProximaAnalise);
    if (payload.observacoes)         obs.push("Obs: " + payload.observacoes);

    var linha = Array(21).fill("");
    linha[0]  = new Date(payload.dataInicio);
    linha[1]  = Utilities.formatDate(new Date(payload.dataInicio), "GMT-3", "HH:mm:ss");
    linha[2]  = payload.dataFinal ? new Date(payload.dataFinal) : "";
    linha[3]  = payload.dataFinal ? Utilities.formatDate(new Date(payload.dataFinal), "GMT-3", "HH:mm:ss") : "";
    linha[4]  = payload.tecnico;
    linha[5]  = payload.fuel;
    linha[6]  = payload.pontoColeta       || "";
    linha[7]  = payload.localizacaoTexto  || "";
    linha[8]  = payload.tipoColeta        || "";
    linha[9]  = payload.co2Ppm            || "";
    linha[10] = payload.umidadeRelativa   || "";
    linha[11] = payload.temperatura       || "";
    linha[12] = payload.velocidadeAr      || "";
    linha[13] = payload.idAmostraMicrobiologica || "";
    linha[14] = payload.statusQualidade   || "";
    linha[15] = linkColeta;
    linha[16] = obs.join(" | ");
    linha[17] = payload.nomeChefe         || "";
    linha[18] = payload.chapaFuncional    || "";
    linha[19] = linkAssinatura;
    linha[20] = "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Checklist Qualidade do Ar salvo!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarRetiradaMaquinaMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("MOVIMENTACAO");
    if (!sheet) sheet = ss.insertSheet("MOVIMENTACAO");

    var linkOrigem     = "";
    var linkDestino    = "";
    var linkAssinatura = "";
    if (payload.fotoOrigemB64)   linkOrigem     = salvarFotoDrive(payload.fotoOrigemB64,   "MOV_ORIGEM_"  + payload.fuel, payload.tecnico);
    if (payload.fotoDestinoB64)  linkDestino    = salvarFotoDrive(payload.fotoDestinoB64,  "MOV_DESTINO_" + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64)   linkAssinatura = salvarFotoDrive(payload.assinaturaB64,   "MOV_ASS_"     + payload.fuel, payload.tecnico);

    var dataHora = payload.dataInicio ?
      Utilities.formatDate(new Date(payload.dataInicio), "GMT-3", "dd/MM/yyyy HH:mm") : "";

    var obs = [];
    if (payload.chkIsolamentoNecessario !== undefined) {
      obs.push("Isolamento: " + (payload.chkIsolamentoNecessario ? "SIM (" + (payload.metrosEstimados || "N/A") + "m)" : "NÃO"));
    }

    var linha = Array(18).fill("");
    linha[0]  = dataHora;
    linha[1]  = payload.tecnico             || "";
    linha[2]  = payload.fuel                || "";
    linha[3]  = payload.origemSetor         || "";
    linha[4]  = payload.tipoMovimentacao    || "";
    linha[5]  = payload.motivo              || "";
    linha[6]  = payload.destinoSetor        || "";
    linha[7]  = payload.estadoEquipamento   || "";
    linha[8]  = payload.acessorios          || "";
    linha[9]  = payload.chkProtecaoTransporte ? "SIM" : "NÃO";
    linha[10] = "";
    linha[11] = obs.join(" | ");
    linha[12] = linkOrigem;
    linha[13] = linkDestino;
    linha[14] = payload.nomeChefe           || "";
    linha[15] = payload.chapaFuncional      || "";
    linha[16] = linkAssinatura;
    linha[17] = "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Movimentação de Máquina salva!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarExaustaoMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("EXAUSTAO");
    if (!sheet) sheet = ss.insertSheet("EXAUSTAO");

    var linkIni        = "";
    var linkServico    = "";
    var linkFim        = "";
    var linkAssinatura = "";
    if (payload.fotoInicialB64)  linkIni        = salvarFotoDrive(payload.fotoInicialB64,  "EXA_INI_"  + payload.fuel, payload.tecnico);
    if (payload.fotoServicoB64)  linkServico    = salvarFotoDrive(payload.fotoServicoB64,  "EXA_SERV_" + payload.fuel, payload.tecnico);
    if (payload.fotoFinalB64)    linkFim        = salvarFotoDrive(payload.fotoFinalB64,    "EXA_FIM_"  + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64)   linkAssinatura = salvarFotoDrive(payload.assinaturaB64,   "EXA_ASS_"  + payload.fuel, payload.tecnico);

    var dataInicio = payload.dataInicio ? new Date(payload.dataInicio) : new Date();
    var dataFinal  = payload.dataFinal  ? new Date(payload.dataFinal)  : new Date();
    if (isNaN(dataInicio.getTime())) dataInicio = new Date();
    if (isNaN(dataFinal.getTime()))  dataFinal  = new Date();

    var linha = Array(26).fill("");
    linha[0]  = dataInicio;
    linha[1]  = Utilities.formatDate(dataInicio, "GMT-3", "HH:mm:ss");
    linha[2]  = dataFinal;
    linha[3]  = Utilities.formatDate(dataFinal,  "GMT-3", "HH:mm:ss");
    linha[4]  = payload.tecnico           || "";
    linha[5]  = payload.fuel              || "";
    linha[6]  = payload.local             || "";
    linha[7]  = (payload.latitude && payload.longitude) ? payload.latitude + "," + payload.longitude : "";
    linha[8]  = payload.tipoEquipamento   || "";
    linha[9]  = payload.limpezaRotor      ? "SIM" : "NÃO";
    linha[10] = payload.correias          || "";
    linha[11] = payload.lubrificacao      ? "SIM" : "NÃO";
    linha[12] = payload.fixacaoVibracao   ? "SIM" : "NÃO";
    linha[13] = payload.sensoresAcionamento? "SIM" : "NÃO";
    linha[14] = payload.tensaoV           || "";
    linha[15] = payload.correnteA         || "";
    linha[16] = payload.velocidadeAr      || "";
    linha[17] = payload.filtrosTelas      ? "SIM" : "NÃO";
    linha[18] = payload.statusEquipamento || "";
    linha[19] = linkIni;
    linha[20] = linkServico;
    linha[21] = linkFim;
    linha[22] = payload.nomeChefe         || "";
    linha[23] = payload.chapaFuncional    || "";
    linha[24] = linkAssinatura;
    linha[25] = "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Checklist Exaustão salvo!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}