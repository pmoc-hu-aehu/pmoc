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
    marcarAutorizacaoUsada(payload.fuel, "FILTRO");
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
    limparLinhaProcessamento(payload.fuel, "DUTO");
    marcarAutorizacaoUsada(payload.fuel, "DUTO");
    return { sucesso: true, msg: "Checklist Duto salvo!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}

function salvarCorretivaMobile(payload) {
  try {
    var ss    = getPlanilha();
    var sheet = ss.getSheetByName("CORRETIVAS");

    var linkIni        = "";
    var linkFim        = "";
    var linkAssinatura = "";
    if (payload.linkFotoInicio)  linkIni        = salvarFotoDrive(payload.linkFotoInicio,  "COR_INI_" + payload.fuel, payload.tecnico);
    if (payload.linkFotoFinal)   linkFim        = salvarFotoDrive(payload.linkFotoFinal,   "COR_FIM_" + payload.fuel, payload.tecnico);
    if (payload.linkAssinatura)  linkAssinatura = salvarFotoDrive(payload.linkAssinatura,  "COR_ASS_" + payload.fuel, payload.tecnico);

    var linha = Array(28).fill("");
    linha[0]  = payload.dataInicio              || "";
    linha[1]  = payload.horaInicio              || "";
    linha[2]  = payload.dataFinal               || "";
    linha[3]  = payload.horaFinal               || "";
    linha[4]  = payload.tecnico                 || "";
    linha[5]  = payload.fuel                    || "";
    linha[6]  = payload.localizacao             || "";
    linha[7]  = payload.coordenadasGps          || "";
    linha[8]  = linkIni;
    linha[9]  = payload.descDefeito             || "";
    linha[10] = payload.causaProvavel           || "";
    linha[11] = payload.servicoRealizado        || "";
    linha[12] = payload.pecasTrocadas           || "";
    linha[13] = payload.nfRequisicao            || "";
    linha[14] = payload.chkIsolamentoOk         || "";
    linha[15] = payload.metrosIsolamentoTrocados || "";
    linha[16] = payload.chkHigienePos           || "";
    linha[17] = payload.tensaoV                 || "";
    linha[18] = payload.correnteA               || "";
    linha[19] = payload.pressaoPsi              || "";
    linha[20] = payload.tempInsuflamento        || "";
    linha[21] = linkFim;
    linha[22] = payload.statusOperacional       || "";
    linha[23] = payload.motivoInoperancia       || "";
    linha[24] = payload.nomeChefe               || "";
    linha[25] = payload.chapaFuncional          || "";
    linha[26] = linkAssinatura;
    linha[27] = payload.statusGeral             || "CONCLUIDO";

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
    if (payload.linkFotoInicio)   linkIni        = salvarFotoDrive(payload.linkFotoInicio,   "PREV_INI_"  + payload.fuel, payload.tecnico);
    if (payload.linkFotoProcesso) linkProcesso   = salvarFotoDrive(payload.linkFotoProcesso, "PREV_PROC_" + payload.fuel, payload.tecnico);
    if (payload.linkFotoFinal)    linkFim        = salvarFotoDrive(payload.linkFotoFinal,    "PREV_FIM_"  + payload.fuel, payload.tecnico);
    if (payload.linkAssinatura)   linkAssinatura = salvarFotoDrive(payload.linkAssinatura,   "PREV_ASS_"  + payload.fuel, payload.tecnico);

    var linha = Array(30).fill("");
    linha[0]  = payload.dataInicio            || "";
    linha[1]  = payload.horaInicio            || "";
    linha[2]  = payload.dataFinal             || "";
    linha[3]  = payload.horaFinal             || "";
    linha[4]  = payload.tecnico               || "";
    linha[5]  = payload.fuel                  || "";
    linha[6]  = payload.localizacao           || "";
    linha[7]  = payload.coordenadasGps        || "";
    linha[8]  = linkIni;
    linha[9]  = payload.chkDesmontagem        || "";
    linha[10] = payload.chkLavagemQuimica     || "";
    linha[11] = payload.chkDrenoBandeja       || "";
    linha[12] = payload.chkAntibactericida    || "";
    linha[13] = payload.chkRuidoVibracao      || "";
    linha[14] = payload.chkVazamento          || "";
    linha[15] = payload.chkEletrica           || "";
    linha[16] = payload.chkIsolamentoOk       || "";
    linha[17] = payload.metrosIsolamentoTrocados || "";
    linha[18] = payload.tensaoV               || "";
    linha[19] = payload.correnteA             || "";
    linha[20] = payload.pressaoPsi            || "";
    linha[21] = payload.tempRetorno           || "";
    linha[22] = payload.tempInsuflamento      || "";
    linha[23] = linkProcesso;
    linha[24] = linkFim;
    linha[25] = payload.observacoesTecnicas   || "";
    linha[26] = payload.nomeChefe             || "";
    linha[27] = payload.chapaFuncional        || "";
    linha[28] = linkAssinatura;
    linha[29] = payload.statusGeral           || "CONCLUIDO";

    sheet.appendRow(linha);
    limparLinhaProcessamento(payload.fuel, "PREVENTIVA");
    return { sucesso: true, msg: "Preventiva salva!" };
  } catch(e) {
    return { sucesso: false, mensagem: e.message };
  }
}