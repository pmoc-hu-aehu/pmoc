# PMOC HU Londrina

Sistema para execucao, controle e documentacao do PMOC - Plano de Manutencao, Operacao e Controle de sistemas de ar condicionado do HU Londrina.

O projeto combina um aplicativo movel Flutter para tecnicos em campo com um backend/painel administrativo em Google Apps Script. Os dados operacionais ficam em Google Sheets e as evidencias fotograficas/documentos ficam em Google Drive.

Repositorio:

```text
git@github.com:pmoc-hu-aehu/pmoc.git
```

## O que o sistema faz

- Autenticacao de tecnicos, administradores e engenheiros.
- App movel para checklists de manutencao.
- Operacao offline com fila local e sincronizacao automatica.
- Cadastro e consulta de maquinas por FUEL.
- Captura de fotos, GPS e assinaturas.
- Bloqueio de duplicidade mensal para filtros/dutos, com autorizacao de relimpeza.
- Agenda automatica de filtros e preventivas.
- Painel web administrativo em Apps Script.
- Relatorios por periodo, tecnico, setor, FUEL e tipo de servico.
- Geracao de PDF mensal do PMOC.
- Cadastro de empresas, tabela de precos e fechamento mensal.
- Pagina de distribuicao do APK via Google Drive.

## Arquitetura

```text
App Flutter
  - UI mobile
  - SQLite local
  - fila offline
  - fotos temporarias
        |
        | HTTP JSON
        v
Google Apps Script Web App
  - API do app
  - painel HTML
  - regras de agenda/relatorio/PMOC
        |
        +--> Google Sheets: base operacional
        +--> Google Drive: fotos, APKs e PDFs
```

## Estrutura do repositorio

```text
lib/
  main.dart
  models/       Modelos de maquinas, checklists e fila offline
  screens/      Telas Flutter
  services/     API, SQLite, sincronizacao e envio de checklists

GAS/
  Code.js       Roteador do Apps Script
  Config.js     IDs, prazos e helpers globais
  Auth.js       Login
  Maquina.js    CRUD de maquinas e relimpeza
  Checklists.js Checklists principais
  Especiais.js  Pressao, qualidade do ar, movimentacao e exaustao
  Drive.js      Upload de fotos
  Agenda.js     Motor de agendamento
  Relatorios.js Relatorios e dashboard
  PMOC.js       Geracao do documento PMOC
  *.html        Painel web

android/        Projeto Android Flutter
ios/            Projeto iOS Flutter
test/           Testes Flutter
```

## Stack

- Flutter / Dart
- SQLite local via `sqflite`
- Google Apps Script V8
- Google Sheets
- Google Drive
- clasp para deploy do Apps Script
- Node.js apenas para utilitarios de geracao de checklist/planilhas

## Requisitos de ambiente

- Flutter SDK `>=3.3.0 <4.0.0`
- Dart compativel com o Flutter instalado
- Android SDK para build Android
- Node.js e npm, se for usar scripts auxiliares
- clasp autenticado, se for publicar o Apps Script
- Acesso ao projeto Google Apps Script configurado em `.clasp.json`

## Como rodar o app Flutter

Instale as dependencias:

```powershell
flutter pub get
```

Analise o projeto:

```powershell
flutter analyze
```

Rode testes:

```powershell
flutter test
```

Execute em um dispositivo/emulador:

```powershell
flutter run
```

Gere APK de release:

```powershell
flutter build apk --release
```

## Como publicar o Apps Script

O Apps Script usa o diretorio `GAS/` como raiz, definido em `.clasp.json`.

Enviar arquivos:

```powershell
clasp.cmd push
```

Listar deployments:

```powershell
clasp.cmd deployments
```

Criar novo deployment:

```powershell
clasp.cmd deploy
```

Depois de publicar um novo Web App, revise a URL hardcoded em `lib/services/api_service.dart` e nos servicos de checklist em `lib/services/checklist_*_service.dart`.

## Fluxo de login

O primeiro login do dia precisa ser online. Quando o servidor valida o usuario, o app salva os dados em `SharedPreferences`. Logins posteriores no mesmo dia podem usar cache local, permitindo operacao offline em campo.

As credenciais sao validadas no Apps Script pelas abas:

- `TECNICO`
- `ENGENHEIRO`

## Fluxo offline

Quando o tecnico envia um checklist sem conexao:

1. O app copia as fotos para armazenamento persistente local.
2. Salva o payload na tabela SQLite `checklist_pendente`.
3. Registra historico local em `historico_manutencao`.
4. Mostra contador de pendencias.
5. Quando a conexao volta, envia cada item para o Apps Script.
6. Em sucesso, remove o item da fila e apaga fotos locais.

Esse fluxo fica concentrado em:

- `lib/services/offline_queue_service.dart`
- `lib/services/database_service.dart`
- `lib/services/sync_service.dart`

## Tipos de checklist

Tipos suportados no app:

- Filtros
- Dutos
- Preventivas
- Corretivas
- Pressao diferencial
- Qualidade do ar
- Movimentacao de equipamento
- Exaustao

Cada tipo possui modelo em `lib/models`, tela em `lib/screens` e rota de salvamento no GAS.

## Abas principais da planilha

O backend usa Google Sheets como banco operacional. As abas mais importantes sao:

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

Importante: muitas leituras e escritas usam indices fixos de coluna. Ao alterar uma aba, atualize tambem `Checklists.js`, `Especiais.js`, `Relatorios.js`, `PMOC.js` e as transformacoes em `OfflineQueueService`.

## Regras de agenda

O motor em `GAS/Agenda.js` calcula a aba `PROCESSAMENTO`.

- Filtro: 30 dias.
- Preventiva alta criticidade: 30 dias.
- Preventiva media criticidade: 90 dias.
- Preventiva baixa criticidade: 180 dias.
- Se ha preventiva agendada/executada no mes, o filtro do mesmo equipamento e suprimido.
- Segunda a quinta: HU.
- Sexta: AEHU.
- Segunda quinta-feira do mes: UCC preventiva.

## Documentacao complementar

- `mem.md`: memoria tecnica do projeto, contratos, arquitetura e pontos de atencao.
- `prd.md`: documento de produto com objetivos, usuarios, requisitos e roadmap.

## Pontos de atencao para desenvolvimento

- Centralizar a URL do Apps Script reduziria risco em novos deploys.
- O web app esta configurado como `ANYONE_ANONYMOUS`; a seguranca depende das validacoes internas.
- O app armazena senha em `SharedPreferences` para login offline; avaliar armazenamento seguro nativo.
- `Pagamentos.js` referencia `RETIRADA_MAQUINA`, enquanto o restante do sistema usa `MOVIMENTACAO`.
- Padronize arquivos como UTF-8 antes de grandes edicoes, pois alguns textos podem aparecer com caracteres quebrados em terminals Windows.

## Checklist antes de publicar

```powershell
flutter analyze
flutter test
clasp.cmd push
```

Tambem teste manualmente:

- Login online.
- Login offline no mesmo dia.
- Sincronizacao de maquinas.
- Envio online de pelo menos um checklist.
- Envio offline com posterior sincronizacao.
- Relatorio no painel.
- Geracao do PDF PMOC.
