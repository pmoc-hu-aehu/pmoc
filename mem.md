# Memoria tecnica do projeto PMOC

Este documento registra o entendimento tecnico atual do projeto `pmoc`, hospedado em `git@github.com:pmoc-hu-aehu/pmoc.git`. Ele serve como guia rapido para manutencao, evolucao e onboarding de novos desenvolvedores.

## Visao geral

O sistema PMOC apoia a execucao, registro, auditoria e consolidacao documental do Plano de Manutencao, Operacao e Controle de ar condicionado do HU Londrina.

A solucao tem duas frentes principais:

- Aplicativo movel Flutter para tecnicos executarem checklists em campo, com suporte offline.
- Backend e painel administrativo em Google Apps Script, usando Google Sheets como base operacional e Google Drive como repositorio de fotos, APKs e PDFs.

## Arquitetura

```text
Flutter app
  -> HTTP JSON
Google Apps Script Web App
  -> Google Sheets
  -> Google Drive
```

### App Flutter

Codigo principal em `lib/`.

- `lib/main.dart`: inicializa o app e abre `LoginScreen`.
- `lib/screens/`: telas de login, dashboard, checklists, maquinas e relatorios.
- `lib/models/`: modelos de maquinas, checklists e fila pendente.
- `lib/services/`: servicos de API, SQLite, sincronizacao, fila offline e envio de cada checklist.

Dependencias principais:

- `http`: comunicacao com o Apps Script.
- `shared_preferences`: cache de login e dados simples de sessao.
- `sqflite`: banco local.
- `connectivity_plus`: deteccao de conectividade.
- `image_picker`: captura de fotos.
- `geolocator`: coordenadas GPS.
- `permission_handler`: permissoes de camera/GPS.
- `path_provider`: armazenamento persistente de fotos pendentes.
- `mobile_scanner`: leitura de codigo de barras/QR Code.
- `hand_signature`: captura de assinatura.

### Apps Script

Codigo em `GAS/`, com configuracao do clasp em `.clasp.json`.

Arquivos centrais:

- `Code.js`: roteador HTTP (`doGet`, `doPost`) e saida JSON.
- `Config.js`: IDs de planilha/pasta, prazos e funcoes globais.
- `Auth.js`: validacao de login por abas `TECNICO` e `ENGENHEIRO`.
- `Maquina.js`: CRUD de maquinas, busca por FUEL e autorizacao de relimpeza.
- `Checklists.js`: salvamento de Filtro, Duto, Corretiva e Preventiva.
- `Especiais.js`: salvamento de Pressao, Qualidade do Ar, Movimentacao e Exaustao.
- `Drive.js`: upload de fotos em base64 para Drive.
- `Agenda.js`: motor de agenda em `PROCESSAMENTO`.
- `Relatorios.js`: consultas consolidadas e contadores.
- `PMOC.js`: dicionario de perguntas e geracao de PDF PMOC mensal.
- `Empresas.js`: cadastro de empresas prestadoras.
- `Pagamentos.js`: tabela de precos e fechamento mensal.
- `Apk.js`: distribuicao de APK via Drive.

Arquivos `.html` em `GAS/` compoem o painel web do Apps Script.

## Fluxos principais

### Login

1. O usuario informa login e senha no app.
2. `ApiService.login()` verifica se ja houve login online no dia.
3. No primeiro login diario, o app chama o Apps Script com `action=LOGIN`.
4. Se validado, salva usuario, senha, nome, perfil e data do login em `SharedPreferences`.
5. Logins posteriores no mesmo dia podem usar cache local.

Observacao: o logout atual nao limpa o cache, para preservar login offline.

### Sincronizacao de maquinas

1. `MaquinasScreen` tenta sincronizar automaticamente uma vez ao dia quando ha conexao.
2. `SyncService.sincronizarMaquinas()` chama `LISTAR_MAQUINAS`.
3. O GAS le a aba `MAQUINAS`.
4. O app grava a base local na tabela SQLite `maquinas`.
5. A tela permite buscar por FUEL, modelo, marca e localizacao.

Perfis `admin` e `pleno` podem inserir/editar maquinas localmente no app. O fluxo atual de edicao local nao sincroniza automaticamente alteracoes de maquinas de volta para a planilha; o CRUD servidor existe no GAS para o painel web.

### Checklists offline-first

O app tenta preservar o trabalho em campo mesmo sem internet.

1. O tecnico preenche um checklist.
2. Fotos sao copiadas para o diretorio persistente do app.
3. O payload sem base64 e salvo em SQLite na tabela `checklist_pendente`.
4. O historico local e atualizado em `historico_manutencao`.
5. Quando a conexao volta, `OfflineQueueService.processarFila()` envia os pendentes.
6. Cada item e transformado para o contrato esperado pelo GAS.
7. Em sucesso, o item e removido da fila e fotos locais sao apagadas.

Tipos de fila definidos em `ChecklistType`:

- `filtro`
- `duto`
- `preventiva`
- `corretiva`
- `pressao`
- `qualidadeAr`
- `movimentacao`
- `exaustao`

### Registro no backend

Cada envio `POST` inclui uma `action`:

- `SALVAR_FILTRO`
- `SALVAR_DUTO`
- `SALVAR_CORRETIVA`
- `SALVAR_PREVENTIVA`
- `SALVAR_PRESSAO`
- `SALVAR_QUALIDADE_AR`
- `SALVAR_RETIRADA_MAQUINA`
- `SALVAR_EXAUSTAO`

O GAS salva fotos no Drive via `salvarFotoDrive()` e grava links nas abas correspondentes.

### Bloqueio de duplicidade mensal

Filtro e Duto possuem protecao contra duplicidade mensal:

- O app consulta `VERIFICAR_LIMPEZA_MES`.
- O GAS tambem valida no servidor antes de salvar.
- Caso o FUEL ja tenha sido limpo no mes, exige autorizacao em `AUTORIZACOES`.
- O painel web possui fluxo de autorizacao de relimpeza.

### Agenda

`Agenda.js` recalcula a aba `PROCESSAMENTO`.

Regras atuais:

- Filtro: prazo fixo de 30 dias.
- Preventiva: `Alta = 30 dias`, `Media = 90 dias`, `Baixa = 180 dias`.
- Segunda a quinta: rota padrao HU.
- Sexta: AEHU.
- Segunda quinta-feira do mes: UCC preventiva.
- Se a maquina ja tem preventiva pendente/executada no mes, o filtro do mes e suprimido.

### Relatorios e PMOC PDF

`Relatorios.js` agrega registros das abas operacionais por periodo, tipo, tecnico, FUEL e setor.

`PMOC.js` gera:

- Previa mensal por maquinas e setores.
- Dicionario de perguntas por tipo de checklist.
- PDF PMOC mensal no Drive, com fotos embutidas ou links para evidencias.

## Dados persistidos

### SQLite local

Banco: `pmoc.db`.

Tabelas:

- `maquinas`: base offline de equipamentos.
- `config`: pares chave/valor locais.
- `checklist_pendente`: fila de sincronizacao offline.
- `historico_manutencao`: historico local por tecnico, FUEL/tipo e data.

Versao atual do banco: `5`.

### Google Sheets

Abas usadas pelo GAS:

- `MAQUINAS`
- `TECNICO`
- `ENGENHEIRO`
- `FILTROS`
- `DUTOS`
- `PREVENTIVAS`
- `CORRETIVAS`
- `PRESSAO`
- `QUALIDADE_AR`
- `MOVIMENTACAO`
- `EXAUSTAO`
- `PROCESSAMENTO`
- `AUTORIZACOES`
- `SETORES`
- `EMPRESAS`
- `TABELA_PRECOS`

As colunas das abas de checklist sao posicionais. Alterar a ordem exige ajustar:

- Escrita em `Checklists.js` e `Especiais.js`.
- Leitura em `Relatorios.js`.
- Dicionarios/fotos em `PMOC.js`.
- Transformacoes em `OfflineQueueService`.

## Pontos de atencao

- O endpoint do Apps Script esta hardcoded em `ApiService` e nos servicos de checklist. Ao publicar novo deploy, atualizar todos os pontos ou centralizar a URL.
- Varias transformacoes de payload ficam em `OfflineQueueService`; qualquer mudanca de coluna no GAS precisa refletir ali.
- Alguns comentarios/textos no codigo aparecem com caracteres quebrados em determinadas leituras de terminal. Manter arquivos em UTF-8 e revisar encoding ao editar.
- `Pagamentos.js` referencia `RETIRADA_MAQUINA`, enquanto o restante do sistema usa `MOVIMENTACAO`. Esse desalinhamento pode afetar fechamento mensal de movimentacoes.
- A permissao do web app Apps Script esta configurada como `ANYONE_ANONYMOUS`; a autenticacao da aplicacao depende das rotas internas e planilhas de usuarios.
- Login offline armazena senha em `SharedPreferences`. Para maior seguranca, avaliar armazenamento seguro nativo.
- A fila offline remove itens rejeitados como duplicidade para evitar tentativas infinitas; revisar mensagens em caso de alteracao no texto retornado pelo GAS.

## Comandos uteis

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
clasp.cmd push
clasp.cmd deployments
clasp.cmd deploy
```

## Como evoluir com menor risco

1. Para novo tipo de checklist, criar modelo em `lib/models`, tela em `lib/screens`, servico de envio em `lib/services`, entrada em `ChecklistType`, salvamento offline e rota GAS.
2. Atualizar as abas da planilha e documentar indices de coluna.
3. Atualizar `Relatorios.js`, `PMOC.js` e `Pagamentos.js` quando o novo tipo entrar em relatorios/fechamento.
4. Testar envio online, envio offline, retomada de conexao e geracao de relatorio.
5. Fazer `flutter analyze` antes de publicar APK.
