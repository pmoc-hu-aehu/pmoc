/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Code.gs — ROTEADOR CENTRAL
 * ATENÇÃO: ID_PLANILHA, ID_PASTA_RAIZ e PRAZO_FILTRO estão em Config.gs
 */

function doGet(e) {
  // Se vier o parâmetro action, é chamada do app mobile — retorna JSON
  if (e.parameter && e.parameter.action) {
    try {
      var acao = e.parameter.action;
      var rotas = {
        "LOGIN": function() {
          return jsonOut(validarLogin(e.parameter.usuario, e.parameter.senha));
        },
        "LISTAR_MAQUINAS": function() {
          return jsonOut(listarMaquinasApp());
        },
        "BUSCAR_MAQUINA": function() {
          return jsonOut(buscarMaquinaPorFuel(e.parameter.fuel));
        },
        "VERIFICAR_LIMPEZA_MES": function() {
          return jsonOut(verificarLimpezaMes(e.parameter.fuel, e.parameter.tipo));
        },
        "LISTAR_PASTA": function() {
          return jsonOut(listarArquivosPasta(e.parameter.pastaId));
        }
      };

      if (rotas[acao]) return rotas[acao]();
      return jsonOut({ sucesso: false, mensagem: "Acao nao reconhecida: " + acao });

    } catch(err) {
      return jsonOut({ sucesso: false, mensagem: err.message });
    }
  }

  // Sem parâmetro action = painel web normal
  return HtmlService.createTemplateFromFile('Index')
    .evaluate()
    .setTitle('PMOC - Gestão HU')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

function doPost(e) {
  try {
    var payload = JSON.parse(e.postData.contents);
    var acao = payload.action || payload.acao || e.parameter.acao;

    var rotas = {
      "LOGIN"                  : function() { return jsonOut(validarLogin(payload.usuario, payload.senha)); },
      "BAIXAR_CRONOGRAMA"      : function() { return jsonOut(getAgendamentosAdmin(payload.equipe)); },
      "SALVAR_EXECUCAO"        : function() { return registrarManutencaoNativa(payload); },
      "BUSCAR_MAQUINA"         : function() { return jsonOut(buscarMaquinaPorFuel(payload.fuel)); },
      "LISTAR_MAQUINAS"        : function() { return jsonOut(listarMaquinasApp()); },
      "SALVAR_MAQUINA"         : function() { return jsonOut(salvarMaquinaBD(payload)); },
      "EXCLUIR_MAQUINA"        : function() { return jsonOut(excluirMaquinaBD(payload.row)); },
      "SALVAR_FILTRO"          : function() { return jsonOut(salvarFiltroMobile(payload)); },
      "SALVAR_DUTO"            : function() { return jsonOut(salvarDutoMobile(payload)); },
      "SALVAR_CORRETIVA"       : function() { return jsonOut(salvarCorretivaMobile(payload)); },
      "SALVAR_PREVENTIVA"      : function() { return jsonOut(salvarPreventivaMobile(payload)); },
      "SALVAR_PRESSAO"         : function() { return jsonOut(salvarPressaoMobile(payload)); },
      "SALVAR_QUALIDADE_AR"    : function() { return jsonOut(salvarQualidadeArMobile(payload)); },
      "SALVAR_RETIRADA_MAQUINA": function() { return jsonOut(salvarRetiradaMaquinaMobile(payload)); },
      "SALVAR_EXAUSTAO"        : function() { return jsonOut(salvarExaustaoMobile(payload)); },
      "GET_REPORTS"            : function() { return jsonOut(getRelatorio(payload)); },
      "AUTORIZAR_RELIMPEZA"    : function() { return jsonOut(autorizarRelimpeza(payload.fuel, payload.tipo)); },
      "MARCAR_AUTH_USADA"      : function() { return jsonOut(marcarAutorizacaoUsada(payload.fuel, payload.tipo)); },
      // Empresas
      "GET_EMPRESAS"           : function() { return jsonOut(getListaEmpresas()); },
      "SALVAR_EMPRESA"         : function() { return jsonOut(salvarEmpresa(payload)); },
      "EXCLUIR_EMPRESA"        : function() { return jsonOut(excluirEmpresa(payload.row)); },
      // Pagamentos
      "GET_TAB_PRECOS"         : function() { return jsonOut(getTabPrecos()); },
      "SALVAR_PRECO"           : function() { return jsonOut(salvarPreco(payload)); },
      "EXCLUIR_PRECO"          : function() { return jsonOut(excluirPreco(payload.row)); },
      "GET_FECHAMENTO_MENSAL"  : function() { return jsonOut(getFechamentoMensal(payload.mes, payload.ano)); },
      "UPLOAD_BG_FOTO"         : function() { return jsonOut(salvarFotoFundoDrive(payload.base64, payload.mimeType)); }
    };

    if (rotas[acao]) return rotas[acao]();
    return jsonOut({ sucesso: false, mensagem: "Acao nao reconhecida: " + acao });

  } catch (err) {
    return jsonOut({ sucesso: false, mensagem: err.message });
  }
}

function jsonOut(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}