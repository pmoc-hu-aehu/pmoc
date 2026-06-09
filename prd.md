# PRD - Sistema PMOC HU Londrina

## 1. Resumo

O Sistema PMOC HU Londrina e uma plataforma operacional para registrar, controlar e auditar atividades de manutencao de climatizacao hospitalar. O produto combina aplicativo movel para tecnicos em campo, painel web administrativo, base de equipamentos, agenda automatica, evidencias fotograficas, relatorios e geracao de PDF mensal do PMOC.

## 2. Problema

A manutencao de sistemas de climatizacao hospitalar exige rastreabilidade, padronizacao tecnica, evidencias e controle de periodicidade. Processos manuais em papel ou planilhas isoladas dificultam:

- Garantir que maquinas sejam atendidas no prazo correto.
- Evitar duplicidade ou retrabalho sem autorizacao.
- Registrar fotos, GPS, horarios e responsaveis.
- Consolidar evidencias para auditoria e documento PMOC mensal.
- Operar em locais com conectividade instavel.

## 3. Objetivos

- Permitir que tecnicos executem checklists padronizados pelo celular.
- Funcionar em campo mesmo sem internet, com sincronizacao posterior.
- Manter base unica de maquinas, tecnicos, engenheiros e empresas.
- Controlar periodicidade de filtros e preventivas por criticidade.
- Registrar evidencias fotograficas no Google Drive.
- Consolidar dados em Google Sheets para auditoria e relatorios.
- Gerar documento PMOC mensal por mes/ano/setor e responsavel tecnico.
- Apoiar fechamento financeiro por tipo de servico e empresa.

## 4. Usuarios

### Tecnico

Executa checklists em campo, captura fotos, GPS e assinaturas, consulta maquinas e trabalha em modo offline quando necessario.

### Administrador

Gerencia maquinas, tecnicos, engenheiros, setores, empresas, autorizacoes de relimpeza, relatorios, precos e fechamentos.

### Engenheiro/responsavel tecnico

Consulta evidencias, valida registros e assina/acompanha o documento PMOC mensal.

### Gestao/contratante

Acompanha produtividade, historico, custos e conformidade operacional.

## 5. Escopo funcional atual

### App movel

- Login com usuario/senha.
- Login online obrigatorio no primeiro acesso do dia.
- Cache de login para operacao offline no mesmo dia.
- Dashboard com acesso a checklists, maquinas e relatorios.
- Inatividade com logout automatico apos 1 hora.
- Cadastro/consulta local de maquinas.
- Sincronizacao da base de maquinas com Google Sheets.
- Execucao dos checklists:
  - Filtros
  - Dutos
  - Preventivas
  - Corretivas
  - Pressao diferencial
  - Qualidade do ar
  - Movimentacao de equipamento
  - Exaustao
- Captura de fotos por camera.
- Captura de GPS.
- Registro de assinatura em fluxos que exigem responsavel.
- Fila offline com envio automatico ao recuperar conexao.

### Backend/painel Apps Script

- Roteamento de API JSON para app movel.
- Painel HTML administrativo.
- Login por abas `TECNICO` e `ENGENHEIRO`.
- CRUD de maquinas.
- CRUD de tecnicos e engenheiros.
- CRUD de empresas prestadoras.
- Controle de setores.
- Tabela de precos.
- Fechamento mensal.
- Relatorios por periodo, tipo, tecnico, setor e FUEL.
- Controle de relimpeza autorizada.
- Agenda automatica em `PROCESSAMENTO`.
- Upload de fotos para Google Drive.
- Geracao de PDF PMOC mensal.
- Pagina de download do APK.

## 6. Requisitos funcionais

### RF01 - Autenticacao

O sistema deve validar login online no primeiro acesso diario e permitir login offline no mesmo dia com credenciais previamente armazenadas.

### RF02 - Base de maquinas

O sistema deve manter uma lista de equipamentos com FUEL, localizacao, modelo, marca, serie, criticidade e capacidade. A base deve ser sincronizavel para uso offline.

### RF03 - Checklists

O app deve oferecer checklists separados por tipo de servico, com campos obrigatorios, fotos, leituras tecnicas, status e responsavel quando aplicavel.

### RF04 - Operacao offline

Quando nao houver internet, o app deve salvar payload e fotos localmente, mostrar pendencias e sincronizar automaticamente quando a conectividade voltar.

### RF05 - Evidencias

O backend deve receber imagens em base64, salvar no Drive e registrar links nas abas operacionais.

### RF06 - Duplicidade mensal

O sistema deve bloquear filtro ou duto duplicado no mesmo FUEL/mes sem autorizacao administrativa.

### RF07 - Agenda

O sistema deve calcular proximas manutencoes com base em historico e criticidade.

### RF08 - Relatorios

O painel deve consultar registros consolidados por data, tecnico, FUEL, setor e tipo.

### RF09 - PMOC mensal

O painel deve gerar PDF mensal consolidado, incluindo maquinas, checklists, evidencias e pagina de assinatura do engenheiro.

### RF10 - Fechamento mensal

O painel deve calcular fechamento por tipo de servico, empresa e valores cadastrados.

## 7. Requisitos nao funcionais

- Disponibilidade offline para execucao de campo.
- Baixa friccao operacional para tecnico em celular.
- Rastreabilidade por data, hora, tecnico, local, FUEL e evidencias.
- Persistencia de fotos pendentes ate sincronizacao bem-sucedida.
- Compatibilidade com Google Apps Script V8.
- Uso de Google Sheets como base auditavel.
- Uso de Google Drive para armazenamento de arquivos.
- Tempo limite de chamadas HTTP no app para evitar travamentos.
- Sincronizacao idempotente o suficiente para nao repetir pendencias em sucesso.

## 8. Indicadores de sucesso

- Percentual de checklists sincronizados sem intervencao manual.
- Quantidade de pendencias offline acumuladas por tecnico.
- Tempo medio entre execucao e sincronizacao.
- Quantidade de equipamentos vencidos, do dia e agendados.
- Cobertura mensal de filtros e preventivas.
- Quantidade de relimpezas autorizadas.
- Tempo para gerar PMOC mensal.
- Divergencias entre planilha, relatorio e PDF gerado.

## 9. Fora de escopo atual

- Backend dedicado fora do Google Apps Script.
- Multi-tenant formal.
- Controle granular de permissao por modulo no app movel.
- Criptografia forte de credenciais locais.
- Sincronizacao bidirecional completa de edicoes locais de maquinas.
- Assinatura digital com certificado ICP-Brasil.
- Notificacoes push nativas.

## 10. Riscos e dependencias

- Limites de execucao e tamanho de payload do Google Apps Script podem impactar fotos grandes.
- Mudancas nas colunas das planilhas quebram contratos posicionais.
- Endpoint do Apps Script hardcoded aumenta custo de troca de deploy.
- Web app anonimo depende de validacoes internas.
- Conectividade instavel pode gerar filas longas em dispositivos.
- Encodings inconsistentes podem prejudicar manutencao de textos.

## 11. Roadmap sugerido

### Curto prazo

- Centralizar URL do Apps Script em uma unica configuracao.
- Documentar contrato de colunas por aba.
- Corrigir desalinhamento `MOVIMENTACAO` vs `RETIRADA_MAQUINA` no fechamento.
- Revisar armazenamento local de senha.
- Padronizar encoding UTF-8.

### Medio prazo

- Criar testes unitarios para transformacoes de payload offline.
- Adicionar tela de diagnostico de fila offline.
- Melhorar sincronizacao de maquinas com origem clara: local vs servidor.
- Criar versionamento de schema das planilhas.

### Longo prazo

- Avaliar backend dedicado para API, autenticacao e armazenamento de anexos.
- Implementar permissoes por perfil/modulo.
- Adicionar notificacoes de vencimentos.
- Criar dashboard gerencial com indicadores historicos.
