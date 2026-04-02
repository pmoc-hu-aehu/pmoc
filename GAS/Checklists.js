/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Checklists.gs — FILTRO, DUTO, CORRETIVA, PREVENTIVA
 */

function salvarFiltroMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("FILTROS");

    var linkIni = "";
    var linkFim = "";
    if (payload.fotoSujaB64)  linkIni = salvarFotoDrive(payload.fotoSujaB64,  "FILT_INI_" + payload.fuel, payload.tecnico);
    if (payload.fotoLimpaB64) linkFim = salvarFotoDrive(payload.fotoLimpaB64, "FILT_FIM_" + payload.fuel, payload.tecnico);

    var linha = Array(23).fill("");
    linha[0]  = payload.dataInicio  || "";
    linha[1]  = payload.horaInicio  || "";
    linha[2]  = payload.dataFinal   || "";
    linha[3]  = payload.horaFinal   || "";
    linha[4]  = payload.tecnico || "";
    linha[5]  = payload.fuel || "";
    linha[6]  = payload.localizacao || "";
    linha[7]  = payload.coordenadasGps || "";
    linha[8]  = linkIni;
    linha[9]  = payload.chkDesligado; // Já vem como "Sim", "Não" ou a observação
    linha[10] = payload.chkLavado;    // Idem
    linha[11] = payload.chkEscova;    // Idem
    linha[12] = payload.chkSecagem;   // Idem
    linha[13] = payload.chkIntegridade; // Idem
    linha[14] = payload.chkLimpezaExt;  // Idem
    linha[15] = payload.chkRecolocado;  // Idem
    linha[16] = linkFim;
    linha[17] = payload.chkDry;       // Idem
    linha[18] = payload.chkAmbiente;  // Idem
    linha[19] = payload.chkDreno;     // Idem
    linha[20] = payload.tempEntrada || "";
    linha[21] = payload.tempInsuflamento || "";
    linha[22] = payload.statusGeral || "OK";

    sheet.appendRow(linha);
    limparLinhaProcessamento(payload.fuel, "FILTRO");
    Logger.log("Checklist Filtro salvo com sucesso para FUEL: " + payload.fuel);
    return { sucesso: true, msg: "Checklist Filtro salvo com sucesso!" };
  } catch(e) {
    Logger.log("Erro em salvarFiltroMobile: " + e.message);
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarDutoMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("DUTOS");

    var linkIni = "";
    var linkFim = "";
    if (payload.linkFotoSuja)  linkIni = salvarFotoDrive(payload.linkFotoSuja,  "DUTO_INI_" + payload.fuel, payload.tecnico);
    if (payload.linkFotoLimpa) linkFim = salvarFotoDrive(payload.linkFotoLimpa, "DUTO_FIM_" + payload.fuel, payload.tecnico);

    var linha = Array(18).fill("");
    linha[0]  = payload.dataInicio     || "";
    linha[1]  = payload.horaInicio     || "";
    linha[2]  = payload.dataFinal      || "";
    linha[3]  = payload.horaFinal      || "";
    linha[4]  = payload.tecnico        || "";
    linha[5]  = payload.fuel           || "";
    linha[6]  = payload.localizacao    || "";
    linha[7]  = payload.coordenadasGps || "";
    linha[8]  = linkIni;
    linha[9]  = payload.chkDanosIsolamento;  // Já vem como "Sim", "Não" ou a observação
    linha[10] = payload.chkLimpezaRobo;      // Idem
    linha[11] = payload.chkGrelhasDifusores; // Idem
    linha[12] = payload.chkSelosInspecao;    // Idem
    linha[13] = payload.chkUmidadeMofo;      // Idem
    linha[14] = payload.tempSaidaDuto       || "";
    linha[15] = linkFim;
    linha[16] = payload.observacoes         || "";
    linha[17] = payload.statusGeral         || "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Checklist Duto salvo!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarCorretivaMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("CORRETIVAS");

    var linkIni       = "";
    var linkServico   = "";
    var linkFim       = "";
    var linkAssinatura = "";
    if (payload.fotoInicialB64)  linkIni        = salvarFotoDrive(payload.fotoInicialB64,  "COR_INI_"  + payload.fuel, payload.tecnico);
    if (payload.fotoServicoB64)  linkServico    = salvarFotoDrive(payload.fotoServicoB64,  "COR_SERV_" + payload.fuel, payload.tecnico);
    if (payload.fotoFinalB64)    linkFim        = salvarFotoDrive(payload.fotoFinalB64,    "COR_FIM_"  + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64)   linkAssinatura = salvarFotoDrive(payload.assinaturaB64,   "COR_ASS_"  + payload.fuel, payload.tecnico);

    var linha = Array(29).fill("");
    linha[0]  = new Date(payload.dataInicio);
    linha[1]  = Utilities.formatDate(new Date(payload.dataInicio), "GMT-3", "HH:mm:ss");
    linha[2]  = payload.dataFinal ? new Date(payload.dataFinal) : "";
    linha[3]  = payload.dataFinal ? Utilities.formatDate(new Date(payload.dataFinal), "GMT-3", "HH:mm:ss") : "";
    linha[4]  = payload.tecnico;
    linha[5]  = payload.fuel;
    linha[6]  = payload.local || "";
    linha[7]  = (payload.latitude && payload.longitude) ? payload.latitude + "," + payload.longitude : "";
    linha[8]  = linkIni;
    linha[9]  = payload.descDefeito         || "";
    linha[10] = payload.causaProvavel       || "";
    linha[11] = payload.servicoRealizado    || "";
    linha[12] = payload.pecasTrocadas       || "";
    linha[13] = payload.nfRequisicao        || "";
    linha[14] = payload.isolamentoOk        ? "SIM" : "NÃO";
    linha[15] = payload.metrosIsolamento    || "";
    linha[16] = payload.higienePos          ? "SIM" : "NÃO";
    linha[17] = payload.tensaoV             || "";
    linha[18] = payload.correnteA           || "";
    linha[19] = payload.pressaoPsi          || "";
    linha[20] = payload.tempInsuflamento    || "";
    linha[21] = linkServico;
    linha[22] = linkFim;
    linha[23] = payload.equipamentoOperacional ? "OPERACIONAL" : "INOPERANTE";
    linha[24] = payload.motivoInoperancia   || "";
    linha[25] = payload.nomeChefe           || "";
    linha[26] = payload.chapaFuncional      || "";
    linha[27] = linkAssinatura;
    linha[28] = "CONCLUIDO";

    sheet.appendRow(linha);
    return { sucesso: true, msg: "Corretiva salva!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarPreventivaMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("PREVENTIVAS");

    var linkIni        = "";
    var linkProcesso   = "";
    var linkFim        = "";
    var linkAssinatura = "";
    if (payload.fotoInicialB64)  linkIni        = salvarFotoDrive(payload.fotoInicialB64,  "PREV_INI_"  + payload.fuel, payload.tecnico);
    if (payload.fotoProcessoB64) linkProcesso   = salvarFotoDrive(payload.fotoProcessoB64, "PREV_PROC_" + payload.fuel, payload.tecnico);
    if (payload.fotoFinalB64)    linkFim        = salvarFotoDrive(payload.fotoFinalB64,    "PREV_FIM_"  + payload.fuel, payload.tecnico);
    if (payload.assinaturaB64)   linkAssinatura = salvarFotoDrive(payload.assinaturaB64,   "PREV_ASS_"  + payload.fuel, payload.tecnico);

    var linha = Array(30).fill("");
    linha[0]  = new Date(payload.dataInicio);
    linha[1]  = Utilities.formatDate(new Date(payload.dataInicio), "GMT-3", "HH:mm:ss");
    linha[2]  = payload.dataFinal ? new Date(payload.dataFinal) : "";
    linha[3]  = payload.dataFinal ? Utilities.formatDate(new Date(payload.dataFinal), "GMT-3", "HH:mm:ss") : "";
    linha[4]  = payload.tecnico;
    linha[5]  = payload.fuel;
    linha[6]  = payload.local || "";
    linha[7]  = (payload.latitude && payload.longitude) ? payload.latitude + "," + payload.longitude : "";
    linha[8]  = linkIni;
    linha[9]  = payload.desmontagem      ? "SIM" : "NÃO";
    linha[10] = payload.lavagemQuimica   ? "SIM" : "NÃO";
    linha[11] = payload.drenoBandeja     ? "SIM" : "NÃO";
    linha[12] = payload.antibactericida  ? "SIM" : "NÃO";
    linha[13] = payload.ruidoVibracao    ? "SIM" : "NÃO";
    linha[14] = payload.vazamento        ? "SIM" : "NÃO";
    linha[15] = payload.eletrica         ? "SIM" : "NÃO";
    linha[16] = payload.isolamentoOk     ? "SIM" : "NÃO";
    linha[17] = payload.metrosIsolamento || "";
    linha[18] = payload.tensaoV          || "";
    linha[19] = payload.correnteA        || "";
    linha[20] = payload.pressaoPsi       || "";
    linha[21] = payload.tempRetorno      || "";
    linha[22] = payload.tempInsuflamento || "";
    linha[23] = linkProcesso;
    linha[24] = linkFim;
    linha[25] = payload.observacoes    || "";
    linha[26] = payload.nomeChefe      || "";
    linha[27] = payload.chapaFuncional || "";
    linha[28] = linkAssinatura;
    linha[29] = "CONCLUIDO";

    sheet.appendRow(linha);
    limparLinhaProcessamento(payload.fuel, "PREVENTIVA");
    return { sucesso: true, msg: "Preventiva salva!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}