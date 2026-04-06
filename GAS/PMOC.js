/**
 * SISTEMA PMOC - GESTÃO HOSPITAL UNIVERSITÁRIO
 * ARQUIVO: PMOC.gs — DICIONÁRIO DE PERGUNTAS + GERAÇÃO DO DOCUMENTO
 */

// ─── DICIONÁRIO DE PERGUNTAS ─────────────────────────────────────────────────

// Fotos por tipo — embed: foto final em base64 | links: demais como URL clicável
var FOTOS_FILTRO      = { embed: { col: 16, label: "Após a limpeza"  },
                          links: [{ col: 8,  label: "Foto antes" }] };
var FOTOS_DUTO        = { embed: { col: 15, label: "Após a limpeza"  },
                          links: [{ col: 8,  label: "Foto antes" }] };
var FOTOS_PREVENTIVA  = { embed: { col: 24, label: "Foto final"      },
                          links: [{ col: 8,  label: "Foto início" },
                                  { col: 23, label: "Foto processo" }] };
var FOTOS_CORRETIVA   = { embed: { col: 21, label: "Foto final"      },
                          links: [{ col: 8,  label: "Foto início" }] };
var FOTOS_EXAUSTAO    = { embed: { col: 21, label: "Foto final"      },
                          links: [{ col: 19, label: "Foto início" },
                                  { col: 20, label: "Foto serviço" }] };
var FOTOS_PRESSAO     = { embed: { col: 8,  label: "Foto manômetro"  },
                          links: [] };
var FOTOS_QUALIDADE   = { embed: { col: 15, label: "Foto coleta"     },
                          links: [] };
var FOTOS_MOVIMENTACAO = { embed: null,
                           links: [{ col: 12, label: "Foto origem" },
                                   { col: 13, label: "Foto destino" }] };

// col = índice exato da coluna na aba da planilha (0-based)
// Colunas fixas em todas as abas: 0=DATA_INI 1=HORA_INI 2=DATA_FIM 3=HORA_FIM 4=TECNICO
//                                  5=FUEL 6=LOCAL 7=GPS 8=FOTO_INI
// A partir do índice 9 começam os campos específicos de cada tipo

var DICT_FILTRO = [
  // col 8  = LINK_FOTO_SUJA   (ignorado)
  { col: 9,  pergunta: "Equipamento desligado antes da limpeza?",  tipo: "bool"    },
  { col: 10, pergunta: "Filtro lavado com água corrente?",          tipo: "bool"    },
  { col: 11, pergunta: "Limpeza com escova realizada?",             tipo: "bool"    },
  { col: 12, pergunta: "Secagem completa antes da recolocação?",    tipo: "bool"    },
  { col: 13, pergunta: "Integridade física do filtro verificada?",  tipo: "bool"    },
  { col: 14, pergunta: "Limpeza externa do gabinete realizada?",    tipo: "bool"    },
  { col: 15, pergunta: "Filtro recolocado corretamente?",           tipo: "bool"    },
  // col 16 = LINK_FOTO_LIMPA  (ignorado)
  { col: 17, pergunta: "Operação em modo DRY verificada?",          tipo: "bool"    },
  { col: 18, pergunta: "Verificação das condições do ambiente?",    tipo: "bool"    },
  { col: 19, pergunta: "Observação sobre o dreno/bandeja",          tipo: "texto"   },
  { col: 20, pergunta: "Temperatura de entrada",                    tipo: "medicao", unidade: "°C" },
  { col: 21, pergunta: "Temperatura de insuflamento",               tipo: "medicao", unidade: "°C" }
  // col 22 = STATUS_GERAL (ignorado no documento)
];

var DICT_DUTO = [
  // col 8  = LINK_FOTO_SUJA   (ignorado)
  { col: 9,  pergunta: "Isolamento do duto sem danos visíveis?",        tipo: "bool"    },
  { col: 10, pergunta: "Limpeza interna realizada (robô/escova)?",      tipo: "bool"    },
  { col: 11, pergunta: "Grelhas e difusores limpos e alinhados?",       tipo: "bool"    },
  { col: 12, pergunta: "Selos de inspeção íntegros e fechados?",        tipo: "bool"    },
  { col: 13, pergunta: "Ausência de umidade/mofo verificada?",          tipo: "bool"    },
  { col: 14, pergunta: "Temperatura de saída do duto",                  tipo: "medicao", unidade: "°C" },
  // col 15 = LINK_FOTO_LIMPA  (ignorado)
  { col: 16, pergunta: "Observações",                                    tipo: "texto"   }
  // col 17 = STATUS_GERAL (ignorado)
];

var DICT_PREVENTIVA = [
  // col 8  = LINK_FOTO_INICIO  (ignorado)
  { col: 9,  pergunta: "Desmontagem e limpeza química realizada?",         tipo: "bool"    },
  { col: 10, pergunta: "Lavagem química da serpentina realizada?",         tipo: "bool"    },
  { col: 11, pergunta: "Dreno e bandeja limpos com bactericida?",          tipo: "bool"    },
  { col: 12, pergunta: "Aplicação de antibactericida realizada?",          tipo: "bool"    },
  { col: 13, pergunta: "Ruídos e vibrações anormais verificados?",         tipo: "bool"    },
  { col: 14, pergunta: "Ausência de vazamentos confirmada?",               tipo: "bool"    },
  { col: 15, pergunta: "Verificação elétrica (terminais/conexões)?",       tipo: "bool"    },
  { col: 16, pergunta: "Isolamento térmico das linhas OK?",                tipo: "bool"    },
  { col: 17, pergunta: "Metros de isolamento trocados",                    tipo: "medicao", unidade: "m"   },
  { col: 18, pergunta: "Tensão elétrica medida",                           tipo: "medicao", unidade: "V"   },
  { col: 19, pergunta: "Corrente elétrica medida",                         tipo: "medicao", unidade: "A"   },
  { col: 20, pergunta: "Pressão do gás",                                   tipo: "medicao", unidade: "PSI" },
  { col: 21, pergunta: "Temperatura de retorno",                           tipo: "medicao", unidade: "°C"  },
  { col: 22, pergunta: "Temperatura de insuflamento",                      tipo: "medicao", unidade: "°C"  },
  // col 23 = LINK_FOTO_PROCESSO (ignorado)
  // col 24 = LINK_FOTO_FINAL    (ignorado)
  { col: 25, pergunta: "Observações técnicas",                             tipo: "texto"   },
  { col: 26, pergunta: "Responsável que acompanhou o serviço",             tipo: "texto"   },
  { col: 27, pergunta: "Chapa funcional do responsável",                   tipo: "texto"   }
  // col 28 = LINK_ASSINATURA (ignorado)
  // col 29 = STATUS_GERAL    (ignorado)
];

var DICT_CORRETIVA = [
  // col 8  = LINK_FOTO_INICIO  (ignorado)
  { col: 9,  pergunta: "Descrição do defeito",                             tipo: "texto"   },
  { col: 10, pergunta: "Causa provável identificada",                      tipo: "texto"   },
  { col: 11, pergunta: "Serviço realizado",                                tipo: "texto"   },
  { col: 12, pergunta: "Peças trocadas/utilizadas",                        tipo: "texto"   },
  { col: 13, pergunta: "NF / Requisição",                                  tipo: "texto"   },
  { col: 14, pergunta: "Isolamento térmico verificado após serviço?",      tipo: "bool"    },
  { col: 15, pergunta: "Metros de isolamento trocados",                    tipo: "medicao", unidade: "m"   },
  { col: 16, pergunta: "Limpeza e higienização pós-serviço realizada?",    tipo: "bool"    },
  { col: 17, pergunta: "Tensão elétrica medida",                           tipo: "medicao", unidade: "V"   },
  { col: 18, pergunta: "Corrente elétrica medida",                         tipo: "medicao", unidade: "A"   },
  { col: 19, pergunta: "Pressão do gás",                                   tipo: "medicao", unidade: "PSI" },
  { col: 20, pergunta: "Temperatura de insuflamento",                      tipo: "medicao", unidade: "°C"  },
  // col 21 = LINK_FOTO_FINAL   (ignorado)
  { col: 22, pergunta: "Status operacional após serviço",                  tipo: "texto"   },
  { col: 23, pergunta: "Motivo de inoperância (se aplicável)",             tipo: "texto"   },
  { col: 24, pergunta: "Responsável que acompanhou o serviço",             tipo: "texto"   },
  { col: 25, pergunta: "Chapa funcional do responsável",                   tipo: "texto"   }
  // col 26 = LINK_ASSINATURA (ignorado)
  // col 27 = STATUS_GERAL    (ignorado)
];

var DICT_EXAUSTAO = [
  // col 8  = tipoEquipamento (texto)
  { col: 8,  pergunta: "Tipo de equipamento",                    tipo: "texto"   },
  { col: 9,  pergunta: "Limpeza do rotor realizada?",            tipo: "bool"    },
  { col: 10, pergunta: "Estado das correias",                    tipo: "texto"   },
  { col: 11, pergunta: "Lubrificação dos mancais realizada?",    tipo: "bool"    },
  { col: 12, pergunta: "Fixação e vibração verificadas?",        tipo: "bool"    },
  { col: 13, pergunta: "Sensores de acionamento OK?",            tipo: "bool"    },
  { col: 14, pergunta: "Tensão elétrica medida",                 tipo: "medicao", unidade: "V"   },
  { col: 15, pergunta: "Corrente elétrica medida",               tipo: "medicao", unidade: "A"   },
  { col: 16, pergunta: "Velocidade do ar",                       tipo: "medicao", unidade: "m/s" },
  { col: 17, pergunta: "Filtros/telas limpos e íntegros?",       tipo: "bool"    },
  { col: 18, pergunta: "Status do equipamento",                  tipo: "texto"   },
  { col: 22, pergunta: "Responsável que acompanhou o serviço",   tipo: "texto"   },
  { col: 23, pergunta: "Chapa funcional do responsável",         tipo: "texto"   }
  // col 19 = FOTO_INICIO | col 20 = FOTO_SERVICO | col 21 = FOTO_FINAL | col 24 = ASSINATURA
];

var DICT_PRESSAO = [
  // col 8  = FOTO_MANOMETRO (ignorado)
  { col: 9,  pergunta: "Pressão diferencial medida",             tipo: "medicao", unidade: "Pa"  },
  { col: 10, pergunta: "Tipo de sala",                           tipo: "texto"   },
  { col: 11, pergunta: "Sala em conformidade (pressão)?",        tipo: "bool"    },
  { col: 12, pergunta: "Vedação de portas e janelas OK?",        tipo: "bool"    },
  { col: 13, pergunta: "Mola de porta funcionando?",             tipo: "bool"    },
  { col: 14, pergunta: "Situação do filtro HEPA",                tipo: "texto"   },
  { col: 15, pergunta: "Status geral da sala",                   tipo: "texto"   },
  { col: 16, pergunta: "Observações",                            tipo: "texto"   },
  { col: 17, pergunta: "Responsável que acompanhou o serviço",   tipo: "texto"   },
  { col: 18, pergunta: "Chapa funcional do responsável",         tipo: "texto"   }
  // col 19 = ASSINATURA | col 20 = STATUS
];

var DICT_QUALIDADE_AR = [
  // cols 0-5 normais; col 6 = pontoColeta; col 7 = localizacaoTexto
  { col: 6,  pergunta: "Ponto de coleta",                        tipo: "texto"   },
  { col: 7,  pergunta: "Localização / descrição",                tipo: "texto"   },
  { col: 8,  pergunta: "Tipo de coleta",                         tipo: "texto"   },
  { col: 9,  pergunta: "CO₂ medido",                             tipo: "medicao", unidade: "ppm" },
  { col: 10, pergunta: "Umidade relativa",                       tipo: "medicao", unidade: "%"   },
  { col: 11, pergunta: "Temperatura",                            tipo: "medicao", unidade: "°C"  },
  { col: 12, pergunta: "Velocidade do ar",                       tipo: "medicao", unidade: "m/s" },
  { col: 13, pergunta: "ID da amostra microbiológica",           tipo: "texto"   },
  { col: 14, pergunta: "Status da qualidade do ar",              tipo: "texto"   },
  { col: 16, pergunta: "Observações",                            tipo: "texto"   },
  { col: 17, pergunta: "Responsável que acompanhou o serviço",   tipo: "texto"   },
  { col: 18, pergunta: "Chapa funcional do responsável",         tipo: "texto"   }
  // col 15 = FOTO_COLETA | col 19 = ASSINATURA | col 20 = STATUS
];

// MOVIMENTAÇÃO tem estrutura diferente: col0=dataHora_str, col1=tecnico, col2=fuel
var DICT_MOVIMENTACAO = [
  { col: 3,  pergunta: "Setor de origem",                        tipo: "texto"   },
  { col: 4,  pergunta: "Tipo de movimentação",                   tipo: "texto"   },
  { col: 5,  pergunta: "Motivo",                                  tipo: "texto"   },
  { col: 6,  pergunta: "Setor de destino",                       tipo: "texto"   },
  { col: 7,  pergunta: "Estado do equipamento",                  tipo: "texto"   },
  { col: 8,  pergunta: "Acessórios incluídos",                   tipo: "texto"   },
  { col: 9,  pergunta: "Proteção para transporte realizada?",    tipo: "bool"    },
  { col: 11, pergunta: "Observações",                            tipo: "texto"   },
  { col: 14, pergunta: "Responsável que acompanhou",             tipo: "texto"   },
  { col: 15, pergunta: "Chapa funcional do responsável",         tipo: "texto"   }
  // col 12 = FOTO_ORIGEM | col 13 = FOTO_DESTINO | col 16 = ASSINATURA
];

// ─── HELPERS ─────────────────────────────────────────────────────────────────

function _parsearData(dataVal) {
  if (dataVal instanceof Date) return dataVal;
  var s = String(dataVal).trim();
  var partes = s.split('/');
  if (partes.length < 3) return null;
  var dia = parseInt(partes[0]);
  var mes = parseInt(partes[1]) - 1;
  var ano = parseInt(partes[2]);
  if (ano < 100) ano += 2000;
  var d = new Date(ano, mes, dia);
  return isNaN(d.getTime()) ? null : d;
}

// Formata qualquer valor de data (Date ou string) para dd/MM/yyyy
function _formatarData(val) {
  if (!val || val === "") return "—";
  var d = (val instanceof Date) ? val : _parsearData(val);
  if (!d || isNaN(d.getTime())) return String(val);
  var dia = d.getDate();
  var mes = d.getMonth() + 1;
  var ano = d.getFullYear();
  return (dia < 10 ? '0' : '') + dia + '/' + (mes < 10 ? '0' : '') + mes + '/' + ano;
}

// Formata qualquer valor de hora (Date do Sheets ou string "HH:mm") para "HH:mm"
function _formatarHora(val) {
  if (!val || val === "") return "—";
  if (val instanceof Date) {
    var h = val.getHours();
    var m = val.getMinutes();
    return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
  }
  // String — pega só HH:mm
  var s = String(val).trim();
  var match = s.match(/(\d{1,2}):(\d{2})/);
  if (match) return (parseInt(match[1]) < 10 ? '0' : '') + match[1] + ':' + match[2];
  return s;
}

function _toMinutos(val) {
  if (!val || val === "") return null;
  if (val instanceof Date) return val.getHours() * 60 + val.getMinutes();
  var s = String(val).trim();
  var match = s.match(/(\d{1,2}):(\d{2})/);
  if (match) return parseInt(match[1]) * 60 + parseInt(match[2]);
  return null;
}

function _formatarDuracao(horaIni, horaFim) {
  var mi = _toMinutos(horaIni);
  var mf = _toMinutos(horaFim);
  if (mi === null || mf === null || isNaN(mi) || isNaN(mf)) return "—";
  var diff = mf - mi;
  if (diff < 0) diff += 1440;
  var h = Math.floor(diff / 60);
  var m = diff % 60;
  return (h > 0 ? h + 'h ' : '') + m + 'min';
}

function _formatarResposta(valor, tipo, unidade) {
  if (valor === null || valor === undefined || valor === "") return null; // null = não exibir
  var s = String(valor).toLowerCase().trim();
  if (tipo === "bool") {
    if (s === "true" || s === "sim" || s === "yes" || s === "1") return "Sim";
    if (s === "false" || s === "não" || s === "nao" || s === "no" || s === "0") return "Não";
    return String(valor);
  }
  if (tipo === "medicao") {
    if (s === "" || s === "0" || s === "null") return null;
    return String(valor) + (unidade ? " " + unidade : "");
  }
  // texto
  var v = String(valor).trim();
  return v === "" ? null : v;
}

function _buscarRegistrosMes(nomeAba, mes, ano) {
  try {
    var sheet = getPlanilha().getSheetByName(nomeAba);
    if (!sheet || sheet.getLastRow() < 1) return [];
    var dados = sheet.getDataRange().getValues();
    var resultado = [];
    for (var i = 0; i < dados.length; i++) {
      var linha = dados[i];
      var d = _parsearData(linha[0]);
      if (!d) continue; // pula cabeçalho (texto) ou linha inválida
      if (d.getMonth() !== mes || d.getFullYear() !== ano) continue;
      resultado.push(linha);
    }
    return resultado;
  } catch(e) {
    Logger.log("Erro _buscarRegistrosMes " + nomeAba + ": " + e.message);
    return [];
  }
}

// Extrai FILE_ID de URL do Drive
function _extrairFileId(urlOuId) {
  if (!urlOuId || urlOuId === "") return null;
  var s = String(urlOuId).trim();
  var m = s.match(/\/d\/([a-zA-Z0-9_-]{20,})/);
  if (m) return m[1];
  m = s.match(/[?&]id=([a-zA-Z0-9_-]{20,})/);
  if (m) return m[1];
  return null;
}

// Converte foto do Drive para base64 inline (único jeito de aparecer no PDF do GAS)
function _fotoBase64(urlOuId) {
  var id = _extrairFileId(urlOuId);
  if (!id) return null;
  try {
    var blob = DriveApp.getFileById(id).getBlob();
    var mime = blob.getContentType() || 'image/jpeg';
    var b64  = Utilities.base64Encode(blob.getBytes());
    return 'data:' + mime + ';base64,' + b64;
  } catch(e) {
    Logger.log('Erro ao carregar foto ' + id + ': ' + e.message);
    return null;
  }
}

function _filtrarPorFuel(registros, fuel) {
  var f = String(fuel).trim();
  return registros.filter(function(r) { return String(r[5]).trim() === f; });
}

// Movimentação tem fuel em col[2] (estrutura diferente das demais abas)
function _filtrarMovimentacaoPorFuel(registros, fuel) {
  var f = String(fuel).trim();
  return registros.filter(function(r) { return String(r[2]).trim() === f; });
}

// Movimentação guarda data+hora juntos em col[0] como "dd/MM/yyyy HH:mm"
function _buscarMovimentacoesMes(mes, ano) {
  try {
    var sheet = getPlanilha().getSheetByName("MOVIMENTACAO");
    if (!sheet || sheet.getLastRow() < 1) return [];
    var dados = sheet.getDataRange().getValues();
    var resultado = [];
    for (var i = 0; i < dados.length; i++) {
      var linha = dados[i];
      // col[0] = "dd/MM/yyyy HH:mm" — pega só a parte da data
      var partes = String(linha[0]).split(' ')[0].split('/');
      if (partes.length < 3) continue;
      var d = new Date(parseInt(partes[2]), parseInt(partes[1]) - 1, parseInt(partes[0]));
      if (isNaN(d.getTime())) continue;
      if (d.getMonth() !== mes || d.getFullYear() !== ano) continue;
      resultado.push(linha);
    }
    return resultado;
  } catch(e) {
    Logger.log("Erro _buscarMovimentacoesMes: " + e.message);
    return [];
  }
}

// ─── DADOS PARA PREVIEW NA TELA ──────────────────────────────────────────────

function getDadosPmocPreview(mes, ano) {
  try {
    var m = parseInt(mes) - 1;
    var a = parseInt(ano);

    // Busca todos os registros do mês uma única vez (eficiente)
    var todosFiltros     = _buscarRegistrosMes("FILTROS",      m, a);
    var todosDutos       = _buscarRegistrosMes("DUTOS",        m, a);
    var todasPreventivas = _buscarRegistrosMes("PREVENTIVAS",  m, a);
    var todasCorretivas  = _buscarRegistrosMes("CORRETIVAS",   m, a);
    var todasExaustoes   = _buscarRegistrosMes("EXAUSTAO",     m, a);
    var todasPressoes    = _buscarRegistrosMes("PRESSAO",      m, a);
    var todasQualidades  = _buscarRegistrosMes("QUALIDADE_AR", m, a);
    var todasMovimenta   = _buscarMovimentacoesMes(m, a);

    var maquinas = getListaMaquinas();
    var resumo = maquinas.map(function(maq) {
      var filtros     = _filtrarPorFuel(todosFiltros,     maq.fuel).length;
      var dutos       = _filtrarPorFuel(todosDutos,       maq.fuel).length;
      var preventivas = _filtrarPorFuel(todasPreventivas, maq.fuel).length;
      var corretivas  = _filtrarPorFuel(todasCorretivas,  maq.fuel).length;
      var exaustoes   = _filtrarPorFuel(todasExaustoes,   maq.fuel).length;
      var pressoes    = _filtrarPorFuel(todasPressoes,    maq.fuel).length;
      var qualidades  = _filtrarPorFuel(todasQualidades,  maq.fuel).length;
      var movimenta   = _filtrarMovimentacaoPorFuel(todasMovimenta, maq.fuel).length;
      return {
        fuel        : maq.fuel,
        localizacao : maq.localizacao,
        modelo      : maq.modelo,
        marca       : maq.marca,
        criticidade : maq.criticidade,
        empresaCnpj : maq.empresaCnpj || "",
        filtros     : filtros,
        dutos       : dutos,
        preventivas : preventivas,
        corretivas  : corretivas,
        exaustoes   : exaustoes,
        pressoes    : pressoes,
        qualidades  : qualidades,
        movimenta   : movimenta,
        total       : filtros + dutos + preventivas + corretivas + exaustoes + pressoes + qualidades + movimenta
      };
    });

    return { sucesso: true, resumo: resumo };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function getDicionario() {
  return {
    filtro       : DICT_FILTRO,
    duto         : DICT_DUTO,
    preventiva   : DICT_PREVENTIVA,
    corretiva    : DICT_CORRETIVA,
    exaustao     : DICT_EXAUSTAO,
    pressao      : DICT_PRESSAO,
    qualidadeAr  : DICT_QUALIDADE_AR,
    movimentacao : DICT_MOVIMENTACAO
  };
}

// ─── GERAÇÃO DO PMOC ─────────────────────────────────────────────────────────

function gerarPmocPdf(mes, ano, engenheiroId) {
  try {
    var m = parseInt(mes) - 1;
    var a = parseInt(ano);
    var nomeMes = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
                   "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"][m];

    // Busca dados do engenheiro
    var engenheiro = { nome: "", crea: "" };
    if (engenheiroId) {
      try {
        var engs = getListaEngenheiros();
        for (var i = 0; i < engs.length; i++) {
          if (String(engs[i].id) === String(engenheiroId)) {
            engenheiro = engs[i];
            break;
          }
        }
      } catch(e2) {}
    }

    // Busca mapa de empresas (CNPJ → nome)
    var mapaEmpresas = {};
    try {
      var emps = getListaEmpresas();
      emps.forEach(function(e) {
        if (e.cnpj) mapaEmpresas[String(e.cnpj).trim()] = e.nomeFantasia || e.razaoSocial || e.cnpj;
      });
    } catch(e3) {}

    // Busca todos os registros do mês
    var todosFiltros     = _buscarRegistrosMes("FILTROS",      m, a);
    var todosDutos       = _buscarRegistrosMes("DUTOS",        m, a);
    var todasPreventivas = _buscarRegistrosMes("PREVENTIVAS",  m, a);
    var todasCorretivas  = _buscarRegistrosMes("CORRETIVAS",   m, a);
    var todasExaustoes   = _buscarRegistrosMes("EXAUSTAO",     m, a);
    var todasPressoes    = _buscarRegistrosMes("PRESSAO",      m, a);
    var todasQualidades  = _buscarRegistrosMes("QUALIDADE_AR", m, a);
    var todasMovimenta   = _buscarMovimentacoesMes(m, a);

    var maquinas = getListaMaquinas();
    var html = _gerarHtmlPmoc(maquinas, m, a, nomeMes, engenheiro, mapaEmpresas,
                              todosFiltros, todosDutos, todasPreventivas, todasCorretivas,
                              todasExaustoes, todasPressoes, todasQualidades, todasMovimenta);

    var blob = Utilities.newBlob(html, 'text/html', 'pmoc.html');
    var pdf  = blob.getAs('application/pdf');
    pdf.setName("PMOC_" + nomeMes + "_" + a + ".pdf");

    var pasta   = DriveApp.getFolderById(ID_PASTA_RAIZ);
    var arquivo = pasta.createFile(pdf);
    arquivo.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    return { sucesso: true, url: arquivo.getUrl(), msg: "PMOC gerado com sucesso!" };
  } catch(e) {
    return { sucesso: false, msg: e.message };
  }
}

function _gerarHtmlPmoc(maquinas, mes, ano, nomeMes, engenheiro, mapaEmpresas,
                         todosFiltros, todosDutos, todasPreventivas, todasCorretivas,
                         todasExaustoes, todasPressoes, todasQualidades, todasMovimenta) {
  var secoes = "";
  maquinas.forEach(function(maq) {
    var filtros     = _filtrarPorFuel(todosFiltros,     maq.fuel);
    var dutos       = _filtrarPorFuel(todosDutos,       maq.fuel);
    var preventivas = _filtrarPorFuel(todasPreventivas, maq.fuel);
    var corretivas  = _filtrarPorFuel(todasCorretivas,  maq.fuel);
    var exaustoes   = _filtrarPorFuel(todasExaustoes,   maq.fuel);
    var pressoes    = _filtrarPorFuel(todasPressoes,    maq.fuel);
    var qualidades  = _filtrarPorFuel(todasQualidades,  maq.fuel);
    var movimenta   = _filtrarMovimentacaoPorFuel(todasMovimenta, maq.fuel);
    var total = filtros.length + dutos.length + preventivas.length + corretivas.length +
                exaustoes.length + pressoes.length + qualidades.length + movimenta.length;
    if (total === 0) return;
    var nomeEmpresa = mapaEmpresas[String(maq.empresaCnpj || "").trim()] || "";
    secoes += _secaoMaquina(maq, filtros, dutos, preventivas, corretivas,
                            exaustoes, pressoes, qualidades, movimenta, nomeEmpresa);
  });

  if (!secoes) secoes = '<p style="text-align:center;color:#666;padding:40px">Nenhum registro encontrado para ' + nomeMes + '/' + ano + '.</p>';

  return '<!DOCTYPE html><html><head><meta charset="UTF-8">' +
    '<style>' +
      'body{font-family:Arial,sans-serif;font-size:10px;margin:20px;color:#1a1a1a}' +
      'h1{font-size:14px;text-align:center;text-transform:uppercase;margin:0}' +
      'h2{font-size:11px;text-transform:uppercase;margin:8px 0 4px}' +
      '.capa{text-align:center;padding:10px;border:2px solid #000;margin-bottom:20px}' +
      '.secao-maquina{page-break-before:always;border:1px solid #999;padding:10px;margin-bottom:20px}' +
      'table{width:100%;border-collapse:collapse;margin-bottom:8px}' +
      'th{background:#0f172a;color:white;padding:4px 6px;text-align:left;font-size:9px}' +
      'td{padding:3px 6px;border-bottom:1px solid #e2e8f0;font-size:9px;vertical-align:middle}' +
      'tr:nth-child(even) td{background:#f8fafc}' +
      /* Tabela de dados da máquina */
      '.tbl-dados{margin-bottom:8px;border:1px solid #cbd5e1}' +
      '.tbl-dados .lbl{background:#0f172a;color:#94a3b8;font-size:8px;font-weight:700;text-transform:uppercase;padding:4px 6px;white-space:nowrap;width:1%}' +
      '.tbl-dados .val{background:#f8fafc;font-size:9px;padding:4px 8px;min-width:80px}' +
      '.tbl-dados tr{border-bottom:1px solid #cbd5e1}' +
      /* Tabela de execução */
      '.tbl-exec{margin:6px 0 4px;border:1px solid #bae6fd;background:#f0f9ff}' +
      '.tbl-exec .lbl{background:#0ea5e9;color:#fff;font-size:8px;font-weight:700;text-transform:uppercase;padding:3px 5px;white-space:nowrap;width:1%}' +
      '.tbl-exec .val{font-size:9px;padding:3px 8px;color:#0f172a;font-weight:600}' +
      /* Tipos de resposta */
      '.r-sim{color:#16a34a;font-weight:bold}' +
      '.r-nao{color:#dc2626;font-weight:bold}' +
      '.r-med{color:#2563eb}' +
      '.r-txt{color:#1a1a1a}' +
      '.tipo-bloco{background:#e0f2fe;padding:4px 8px;font-weight:bold;font-size:9px;margin-top:10px;margin-bottom:2px;border-left:4px solid #0ea5e9;letter-spacing:.3px}' +
      '.fotos-exec{display:flex;gap:10px;margin-top:6px;margin-bottom:8px;flex-wrap:wrap}' +
      '.foto-box{text-align:center}' +
      '.foto-box img{width:160px;height:120px;object-fit:cover;border:1px solid #cbd5e1;border-radius:4px;display:block}' +
      '.foto-label{font-size:8px;color:#64748b;margin-top:3px;font-weight:600}' +
      '.pag-ass{page-break-before:always;padding:20px}' +
      '.linha-ass{border-bottom:1px solid #000;width:280px;display:inline-block;margin-top:40px}' +
    '</style></head><body>' +
    '<div class="capa">' +
      '<h1>Programa de Manutenção, Operação e Controle — PMOC</h1>' +
      '<p style="margin:4px 0"><strong>Hospital Universitário de Londrina — HU/UEL</strong></p>' +
      '<p style="margin:4px 0">CNPJ: 78.640.489/0001-53 | Av. Robert Koch, 60 — Operaria, Londrina-PR</p>' +
      '<p style="margin:8px 0;font-size:12px"><strong>Período de Referência: ' + nomeMes + '/' + ano + '</strong></p>' +
    '</div>' +
    secoes +
    _paginaAssinatura(nomeMes, ano, engenheiro) +
    '</body></html>';
}

function _secaoMaquina(maq, filtros, dutos, preventivas, corretivas,
                        exaustoes, pressoes, qualidades, movimenta, nomeEmpresa) {
  var out = '<div class="secao-maquina">';

  // ── Dados do equipamento em tabela organizada ──
  out += '<table class="tbl-dados"><tbody>' +
    '<tr>' +
      '<td class="lbl">FUEL</td><td class="val"><strong>' + (maq.fuel || '—') + '</strong></td>' +
      '<td class="lbl">Localização</td><td class="val" colspan="3">' + (maq.localizacao || '—') + '</td>' +
    '</tr><tr>' +
      '<td class="lbl">Modelo</td><td class="val">' + (maq.modelo || '—') + '</td>' +
      '<td class="lbl">Marca</td><td class="val">' + (maq.marca || '—') + '</td>' +
      '<td class="lbl">Série</td><td class="val">' + (maq.serie || '—') + '</td>' +
    '</tr><tr>' +
      '<td class="lbl">Criticidade</td><td class="val">' + (maq.criticidade || '—') + '</td>' +
      '<td class="lbl">Capacidade</td><td class="val">' + (maq.capacidade || '—') + '</td>' +
      '<td class="lbl">Área (m²)</td><td class="val">' + (maq.areaM2 || '______') + '</td>' +
    '</tr><tr>' +
      '<td class="lbl">Ocup. Fixos</td><td class="val">' + (maq.ocupantesFixos || '______') + '</td>' +
      '<td class="lbl">Ocup. Variáveis</td><td class="val">' + (maq.ocupantesVariaveis || '______') + '</td>' +
      '<td class="lbl">Empresa</td><td class="val">' + (nomeEmpresa || '—') + '</td>' +
    '</tr>' +
    '</tbody></table>';

  if (filtros.length)     out += _blocoRegistros("Limpeza de Filtros",         filtros,     DICT_FILTRO,         FOTOS_FILTRO);
  if (dutos.length)       out += _blocoRegistros("Limpeza de Dutos",           dutos,       DICT_DUTO,           FOTOS_DUTO);
  if (preventivas.length) out += _blocoRegistros("Manutenção Preventiva",      preventivas, DICT_PREVENTIVA,     FOTOS_PREVENTIVA);
  if (corretivas.length)  out += _blocoRegistros("Manutenção Corretiva",       corretivas,  DICT_CORRETIVA,      FOTOS_CORRETIVA);
  if (exaustoes.length)   out += _blocoRegistros("Sistema de Exaustão",        exaustoes,   DICT_EXAUSTAO,       FOTOS_EXAUSTAO);
  if (pressoes.length)    out += _blocoRegistros("Verificação de Pressão",     pressoes,    DICT_PRESSAO,        FOTOS_PRESSAO);
  if (qualidades.length)  out += _blocoRegistros("Qualidade do Ar",            qualidades,  DICT_QUALIDADE_AR,   FOTOS_QUALIDADE);
  if (movimenta.length)   out += _blocoMovimentacao(movimenta);

  out += '</div>';
  return out;
}

function _blocoRegistros(titulo, registros, dicionario, defFotos) {
  var out = '<div class="tipo-bloco">' + titulo.toUpperCase() +
    ' — ' + registros.length + ' execução' + (registros.length > 1 ? 'ões' : '') + '</div>';

  registros.forEach(function(reg, idx) {
    var data    = _formatarData(reg[0]);
    var horaIni = _formatarHora(reg[1]);
    var horaFim = _formatarHora(reg[3]);
    var duracao = _formatarDuracao(reg[1], reg[3]);
    var tecnico = reg[4] || '—';

    // Cabeçalho da execução em mini-tabela limpa
    out += '<table class="tbl-exec"><tbody>' +
      '<tr>' +
        '<td class="lbl">Execução</td><td class="val"><strong>#' + (idx+1) + '</strong></td>' +
        '<td class="lbl">Data</td><td class="val"><strong>' + data + '</strong></td>' +
        '<td class="lbl">Hora inicial</td><td class="val">' + horaIni + '</td>' +
        '<td class="lbl">Hora final</td><td class="val">' + horaFim + '</td>' +
        '<td class="lbl">Duração</td><td class="val">' + duracao + '</td>' +
      '</tr><tr>' +
        '<td class="lbl">Técnico</td><td class="val" colspan="9"><strong>' + tecnico + '</strong></td>' +
      '</tr>' +
      '</tbody></table>';

    out += '<table><thead><tr><th>Verificação / Atividade</th><th style="width:140px">Resultado</th></tr></thead><tbody>';
    dicionario.forEach(function(item) {
      var valorBruto = reg[item.col];
      var resposta = _formatarResposta(valorBruto, item.tipo, item.unidade);
      if (resposta === null) return;
      var cls = item.tipo === "bool"
        ? (resposta === "Sim" ? "r-sim" : "r-nao")
        : (item.tipo === "medicao" ? "r-med" : "r-txt");
      out += '<tr><td>' + item.pergunta + '</td><td class="' + cls + '">' + resposta + '</td></tr>';
    });
    out += '</tbody></table>';

    // Foto final em base64 (uma por execução)
    if (defFotos && defFotos.embed) {
      var b64 = _fotoBase64(reg[defFotos.embed.col]);
      if (b64) {
        out += '<div style="margin-top:6px;margin-bottom:4px">' +
          '<img src="' + b64 + '" style="width:200px;height:150px;object-fit:cover;border:1px solid #cbd5e1;border-radius:4px;display:block">' +
          '<div style="font-size:8px;color:#64748b;margin-top:2px;font-weight:600">' + defFotos.embed.label + '</div>' +
          '</div>';
      }
    }

    // Links das demais fotos (antes, processo...) — clicáveis, sem embutir
    if (defFotos && defFotos.links && defFotos.links.length) {
      var linksHtml = defFotos.links.map(function(f) {
        var id = _extrairFileId(reg[f.col]);
        if (!id) return null;
        var url = 'https://drive.google.com/file/d/' + id + '/view';
        return '<a href="' + url + '" style="font-size:8px;color:#0369a1;margin-right:12px">' + f.label + ' ↗</a>';
      }).filter(function(l){ return l !== null; });

      if (linksHtml.length) {
        out += '<div style="margin-bottom:8px">' + linksHtml.join('') + '</div>';
      }
    }
  });
  return out;
}

// Bloco especial para Movimentação (estrutura de colunas diferente das demais)
function _blocoMovimentacao(registros) {
  var out = '<div class="tipo-bloco">MOVIMENTAÇÃO DE EQUIPAMENTO — ' +
    registros.length + ' registro' + (registros.length > 1 ? 's' : '') + '</div>';

  registros.forEach(function(reg, idx) {
    // col[0] = "dd/MM/yyyy HH:mm", col[1] = tecnico, col[2] = fuel
    var dataHora = String(reg[0] || '—');
    var partes   = dataHora.split(' ');
    var data     = partes[0] || '—';
    var hora     = partes[1] || '—';
    var tecnico  = reg[1] || '—';

    out += '<table class="tbl-exec"><tbody>' +
      '<tr>' +
        '<td class="lbl">Registro</td><td class="val"><strong>#' + (idx+1) + '</strong></td>' +
        '<td class="lbl">Data</td><td class="val"><strong>' + data + '</strong></td>' +
        '<td class="lbl">Hora</td><td class="val">' + hora + '</td>' +
      '</tr><tr>' +
        '<td class="lbl">Técnico</td><td class="val" colspan="5"><strong>' + tecnico + '</strong></td>' +
      '</tr>' +
      '</tbody></table>';

    out += '<table><thead><tr><th>Campo</th><th style="width:200px">Informação</th></tr></thead><tbody>';
    DICT_MOVIMENTACAO.forEach(function(item) {
      var resposta = _formatarResposta(reg[item.col], item.tipo, item.unidade);
      if (resposta === null) return;
      var cls = item.tipo === "bool"
        ? (resposta === "Sim" ? "r-sim" : "r-nao")
        : "r-txt";
      out += '<tr><td>' + item.pergunta + '</td><td class="' + cls + '">' + resposta + '</td></tr>';
    });
    out += '</tbody></table>';

    // Links das fotos
    var linksHtml = [];
    [[12, "Foto origem"], [13, "Foto destino"]].forEach(function(f) {
      var id = _extrairFileId(reg[f[0]]);
      if (!id) return;
      linksHtml.push('<a href="https://drive.google.com/file/d/' + id + '/view" style="font-size:8px;color:#0369a1;margin-right:12px">' + f[1] + ' ↗</a>');
    });
    if (linksHtml.length) out += '<div style="margin-bottom:8px">' + linksHtml.join('') + '</div>';
  });
  return out;
}

function _paginaAssinatura(nomeMes, ano, engenheiro) {
  return '<div class="pag-ass">' +
    '<h2 style="text-align:center;font-size:13px">Declaração de Conformidade — ' + nomeMes + '/' + ano + '</h2>' +
    '<p style="font-size:10px;margin:16px 0">Declaro que os serviços de manutenção listados neste documento foram ' +
    'executados conforme o Programa de Manutenção, Operação e Controle (PMOC), de acordo com a Resolução ' +
    'ANVISA RE-09/2003, sendo de responsabilidade técnica do profissional abaixo identificado.</p>' +
    '<br><br>' +
    '<table style="width:100%;border:none"><tr>' +
    '<td style="border:none;text-align:center;vertical-align:bottom">' +
      '<div class="linha-ass"></div><br>' +
      '<strong>' + (engenheiro.nome || '___________________________________') + '</strong><br>' +
      'Engenheiro Responsável<br>' +
      'CREA: ' + (engenheiro.crea || '________________________') + '<br>' +
      'Data: _____ / _____ / ' + ano +
    '</td>' +
    '<td style="border:none;text-align:center;vertical-align:bottom">' +
      '<div class="linha-ass"></div><br>' +
      '<strong>___________________________________</strong><br>' +
      'Responsável pelo Empreendimento<br>' +
      'Cargo: ________________________<br>' +
      'Data: _____ / _____ / ' + ano +
    '</td>' +
    '</tr></table>' +
    '</div>';
}
