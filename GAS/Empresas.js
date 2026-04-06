/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: Empresas.gs — CRUD DE EMPRESAS PRESTADORAS
 *
 * Aba EMPRESAS — colunas:
 * [0]  Razão Social
 * [1]  Nome Fantasia
 * [2]  CNPJ
 * [3]  Situação Cadastral (Ativo/Irregular/etc)
 * [4]  Endereço
 * [5]  Número
 * [6]  Complemento
 * [7]  Bairro
 * [8]  Cidade
 * [9]  UF
 * [10] CEP
 * [11] Representante Legal (Nome)
 * [12] Representante CPF
 * [13] Representante RG
 * [14] Responsável / Contato
 * [15] Telefone
 * [16] Email
 * [17] Serviços
 * [18] Status (Ativa/Inativa)
 * [19] Observações
 * [20] Data Cadastro
 */

function _getEmpresasSheet() {
  var ss    = getPlanilha();
  var sheet = ss.getSheetByName("EMPRESAS");
  if (!sheet) {
    sheet = ss.insertSheet("EMPRESAS");
    var cab = ["Razão Social","Nome Fantasia","CNPJ","Situação Cadastral",
               "Endereço","Número","Complemento","Bairro","Cidade","UF","CEP",
               "Representante Legal","CPF Representante","RG Representante",
               "Responsável/Contato","Telefone","Email",
               "Serviços","Status","Observações","Data Cadastro"];
    sheet.appendRow(cab);
    sheet.getRange(1,1,1,cab.length).setFontWeight("bold")
         .setBackground("#0f172a").setFontColor("white");
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function getListaEmpresas() {
  try {
    var sheet = _getEmpresasSheet();
    var data  = sheet.getDataRange().getValues();
    var lista = [];
    for (var i = 1; i < data.length; i++) {
      if (!data[i][0]) continue;
      lista.push({
        id             : i + 1,
        razaoSocial    : data[i][0]  || "",
        nomeFantasia   : data[i][1]  || "",
        cnpj           : data[i][2]  || "",
        situacaoCadastral: data[i][3]|| "",
        endereco       : data[i][4]  || "",
        numero         : data[i][5]  || "",
        complemento    : data[i][6]  || "",
        bairro         : data[i][7]  || "",
        cidade         : data[i][8]  || "",
        uf             : data[i][9]  || "",
        cep            : data[i][10] || "",
        repNome        : data[i][11] || "",
        repCpf         : data[i][12] || "",
        repRg          : data[i][13] || "",
        responsavel    : data[i][14] || "",
        telefone       : data[i][15] || "",
        email          : data[i][16] || "",
        servicos       : data[i][17] || "",
        status         : data[i][18] || "Ativa",
        obs            : data[i][19] || "",
        dataCadastro   : data[i][20] ? Utilities.formatDate(new Date(data[i][20]), "America/Sao_Paulo", "dd/MM/yyyy") : ""
      });
    }
    return lista;
  } catch(e) {
    Logger.log("Erro em getListaEmpresas: " + e.message);
    return [];
  }
}

function salvarEmpresa(dados) {
  try {
    var sheet = _getEmpresasSheet();
    var isNew = (!dados.id || dados.id === "" || dados.id === 0);

    // Validar CNPJ duplicado
    var cnpjNovo = (dados.cnpj || "").toString().replace(/\D/g,"");
    if (cnpjNovo) {
      var data = sheet.getDataRange().getValues();
      for (var i = 1; i < data.length; i++) {
        if (!isNew && (i + 1) === parseInt(dados.id)) continue;
        var cnpjBanco = (data[i][2] || "").toString().replace(/\D/g,"");
        if (cnpjBanco && cnpjBanco === cnpjNovo) {
          return { sucesso: false, msg: "Já existe uma empresa com este CNPJ!" };
        }
      }
    }

    var dataExistente = "";
    if (!isNew) {
      var allData = sheet.getDataRange().getValues();
      dataExistente = allData[parseInt(dados.id) - 1][20] || "";
    }

    var linha = [
      dados.razaoSocial      || "",
      dados.nomeFantasia     || "",
      dados.cnpj             || "",
      dados.situacaoCadastral|| "Ativo",
      dados.endereco         || "",
      dados.numero           || "",
      dados.complemento      || "",
      dados.bairro           || "",
      dados.cidade           || "",
      dados.uf               || "",
      dados.cep              || "",
      dados.repNome          || "",
      dados.repCpf           || "",
      dados.repRg            || "",
      dados.responsavel      || "",
      dados.telefone         || "",
      dados.email            || "",
      dados.servicos         || "",
      dados.status           || "Ativa",
      dados.obs              || "",
      isNew ? new Date() : (dataExistente || new Date())
    ];

    if (isNew) {
      sheet.appendRow(linha);
    } else {
      sheet.getRange(parseInt(dados.id), 1, 1, linha.length).setValues([linha]);
    }
    return { sucesso: true, msg: isNew ? "Empresa cadastrada!" : "Empresa atualizada!" };
  } catch(e) {
    Logger.log("Erro em salvarEmpresa: " + e.message);
    return { sucesso: false, msg: e.message };
  }
}

function excluirEmpresa(row) {
  try {
    var sheet = getPlanilha().getSheetByName("EMPRESAS");
    if (!sheet) return { sucesso: false, msg: "Aba EMPRESAS não encontrada." };
    sheet.deleteRow(parseInt(row));
    return { sucesso: true, msg: "Empresa removida." };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}
