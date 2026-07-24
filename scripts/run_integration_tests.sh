#!/bin/bash
set -e

# Roda o teste de integração Flutter (host) contra o backend NestJS local.
# O script executa `e2e-setup.sh` no backend, captura as credenciais geradas
# e as passa para o Flutter via --dart-define.
#
# Pré-requisitos:
#   - Backend rodando em http://localhost:3000
#   - Banco de testes em localhost:5433 com roles e pelo menos um turno ativo seedados
#   - flutter no PATH
#
# Uso:
#   cd app_faixa_amarela
#   bash scripts/run_integration_tests.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NESTJS_DIR="$(cd "$PROJECT_DIR/../nestjs" && pwd)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-faixa_amarela_test}"
DB_SCHEMA="${DB_SCHEMA:-faixaamarela_prod}"
DB_PASS="${DB_PASS:-secret}"

if ! command -v flutter &> /dev/null; then
  echo "ERRO: flutter não encontrado no PATH."
  exit 1
fi

echo "==> Rodando setup de dados de teste no backend..."
cd "$NESTJS_DIR"
SETUP_OUTPUT=$(
  DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
  DB_NAME="$DB_NAME" DB_SCHEMA="$DB_SCHEMA" DB_PASS="$DB_PASS" \
  bash scripts/e2e-setup.sh
)

PARENT_EMAIL=$(echo "$SETUP_OUTPUT" | grep -A1 "^PAI:" | grep "E-mail:" | sed -E 's/^[^:]*:[[:space:]]*//' | sed -E 's/[[:space:]]*$//')
DRIVER_EMAIL=$(echo "$SETUP_OUTPUT" | grep -A1 "^MOTORISTA:" | grep "E-mail:" | sed -E 's/^[^:]*:[[:space:]]*//' | sed -E 's/[[:space:]]*$//')
TEST_PASSWORD=$(echo "$SETUP_OUTPUT" | grep "Senha:" | head -1 | sed -E 's/^[^:]*:[[:space:]]*//' | sed -E 's/[[:space:]]*$//')

if [ -z "$PARENT_EMAIL" ] || [ -z "$DRIVER_EMAIL" ] || [ -z "$TEST_PASSWORD" ]; then
  echo "ERRO: não foi possível extrair credenciais do e2e-setup.sh."
  echo "$SETUP_OUTPUT"
  exit 1
fi

echo ""
echo "==> Credenciais capturadas:"
echo "    Pai:       $PARENT_EMAIL"
echo "    Motorista: $DRIVER_EMAIL"
echo ""

cd "$PROJECT_DIR"

echo "==> Rodando teste de integração Flutter (host)..."
flutter test test/integration/api_flow_local_test.dart \
  --dart-define=PARENT_EMAIL="$PARENT_EMAIL" \
  --dart-define=PARENT_PASSWORD="$TEST_PASSWORD" \
  --dart-define=DRIVER_EMAIL="$DRIVER_EMAIL" \
  --dart-define=DRIVER_PASSWORD="$TEST_PASSWORD" \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000
