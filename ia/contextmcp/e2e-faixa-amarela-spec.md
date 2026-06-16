# Spec: Testes End-to-End Faixa Amarela (App + NestJS)

## 1. Objetivo

Garantir que os fluxos de autenticação e sessão do app Flutter funcionem de ponta a ponta contra o backend NestJS, capturando logs do servidor em tempo real e evitando regressões no comportamento de login/sessão.

## 2. Escopo

- **App Flutter** (`app_faixa_amarela/`)
  - Login de responsável (parent)
  - Login de motorista (driver)
  - Refresh automático de token
  - Logout (local e remoto)
  - Recuperação de sessão após reinício do app
- **Backend NestJS** (`nestjs/`)
  - Endpoints de auth (`/auth/user/login`, `/auth/driver/login`, `/auth/refresh`, `/auth/logout`)
  - Geração e rotação de refresh tokens
  - Guards JWT e ActiveAccount

## 3. Ambiente de teste

- Backend deployado em `/opt/nest-js-faixa-amarela` no servidor `contabro` (acesso SSH via Tabby)
- App Flutter executado em emulador/device local
- Variável de ambiente apontando para a API de produção: `--dart-define=API_BASE_URL=https://api.faixaamarela.com.br`

## 4. Comandos autorizados no servidor

> **Restrição:** nenhuma alteração no servidor é permitida, exceto o fluxo de deploy do código.

```bash
su ubuntu
cd /opt/nest-js-faixa-amarela
pm2 log 0                         # visualizar logs em tempo real
git pull                          # após commit/push das correções
nvm use 24
npm run build
pm2 restart 0
```

## 5. Cenários de teste E2E

### 5.1 Login de responsável bem-sucedido

**Dado** que o app está na tela de login  
**Quando** o usuário informar e-mail/senha válidos de responsável e selecionar "Pais"  
**Então** deve navegar para a home do responsável  
**E** o backend deve registrar o `device_token` (log `POST /auth/user/login 200`)

### 5.2 Login de motorista bem-sucedido

**Dado** que o app está na tela de login  
**Quando** o usuário informar e-mail/senha válidos de motorista e selecionar "Tio da Van"  
**Então** deve navegar para a home do motorista  
**E** o backend deve registrar o `device_token` (log `POST /auth/driver/login 200`)

### 5.3 Sessão recuperada após reinício do app

**Dado** que o usuário está logado  
**Quando** o app é fechado e reaberto  
**Então** deve carregar a sessão do secure storage/Hive  
**E** redirecionar diretamente para a home correspondente ao perfil

### 5.4 Refresh automático de access token

**Dado** que o usuário está logado e o access token expirou  
**Quando** o app faz uma requisição autenticada  
**Então** deve chamar `POST /auth/refresh` automaticamente  
**E** a requisição original deve ser repetida com sucesso  
**E** o refresh token antigo deve ser invalidado (rotação)

### 5.5 Logout local e remoto

**Dado** que o usuário está logado  
**Quando** toca em "Sair"  
**Então** deve limpar o storage local  
**E** chamar `POST /auth/logout` invalidando o refresh token no backend  
**E** redirecionar para a tela de login

### 5.6 Mensagem coerente em credenciais inválidas

**Dado** que o usuário está na tela de login  
**Quando** informar credenciais inválidas  
**Então** deve exibir a mensagem do backend (ex: "Credenciais inválidas.")  
**E** não deve exibir "Sessão expirada"

## 6. Checklist de correções já identificadas

- [x] `AuthInterceptor`: evitar loop infinito de refresh quando o backend rejeita o novo access token.
- [x] `PushRegistrationService`: usar o auth header atual no listener `onTokenRefresh` em vez de capturar o valor do momento do login.
- [x] `SessionStorage.load()`: tornar o parse do `userId` robusto (aceitar `num` ou `String`).
- [x] `ApiException`: priorizar mensagem da API; usar "Sessão expirada" apenas como fallback para 401 sem mensagem do backend.

## 7. Captura de logs

Durante a execução dos testes E2E:

1. Abrir a aba `contabro` no Tabby.
2. Executar `su ubuntu` e `cd /opt/nest-js-faixa-amarela`.
3. Rodar `pm2 log 0` em paralelo aos testes.
4. Observar erros 401/403/500 nos endpoints de auth.
5. Se identificado erro no código:
   - Corrigir no projeto local
   - Commit/push
   - `git pull`, `nvm use 24`, `npm run build`, `pm2 restart 0` no servidor
   - Reexecutar os testes

## 8. Comandos para rodar os testes

### App Flutter (E2E de widget/integration)

```bash
cd app_faixa_amarela
flutter test integration_test/auth_flow_test.dart -d "iPhone 16e" --dart-define=API_BASE_URL=https://api.faixaamarela.com.br
flutter test integration_test/e2e_pai_motorista_test.dart -d "iPhone 16e" --dart-define=API_BASE_URL=https://api.faixaamarela.com.br
```

### Backend NestJS (E2E local)

```bash
cd nestjs
npm run test:e2e:infra   # sobe Postgres/Redis de teste
npm run test:e2e:run     # roda os testes e2e
```

## 9. Critérios de aceitação

- Login de responsável e motorista funcionam sem mensagem de "sessão expirada".
- App recupera sessão após reinício sem pedir login novamente.
- Refresh token funciona sem logout inesperado.
- Nenhum erro 500 nos endpoints de auth nos logs do servidor durante os testes.
- Todos os testes E2E do app passam.
