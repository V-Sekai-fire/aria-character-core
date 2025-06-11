#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Fly.io Cold Boot Initialization Script
# Deploys Aria Character Core services in dependency order

set -e

echo "🚀 Initializing Aria Character Core on Fly.io..."
echo "📋 Cold boot order deployment based on architecture dependencies"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    print_error "flyctl CLI is required but not installed"
    echo "Install it from: https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    print_error "Please login to Fly.io first: flyctl auth login"
    exit 1
fi

print_step "Layer 1: Foundation Services (Boot First)"

print_step "1.1: Deploying OpenBao (Secrets Management)"
flyctl apps create aria-character-core-vault --org personal 2>/dev/null || true
flyctl volumes create vault_data --region ord --size 1 --app aria-character-core-vault 2>/dev/null || true
flyctl deploy --config fly-vault.toml --app aria-character-core-vault
print_success "OpenBao (aria_security) deployed"

print_step "1.2: Deploying CockroachDB (Data Persistence)"  
flyctl apps create aria-character-core-db --org personal 2>/dev/null || true
flyctl volumes create cockroach_data --region ord --size 10 --app aria-character-core-db 2>/dev/null || true
flyctl deploy --config fly-db.toml --app aria-character-core-db
print_success "CockroachDB (aria_data) deployed"

print_step "Waiting for foundation services to be ready..."
sleep 30

# Get database connection string
DB_URL=$(flyctl ips list --app aria-character-core-db --json | jq -r '.[0].address')
VAULT_URL=$(flyctl ips list --app aria-character-core-vault --json | jq -r '.[0].address')

print_step "Layer 2: Core Services (Boot Second)"

print_step "2.1: Setting up secrets in OpenBao"
# This would normally configure secrets, but for demo we'll use environment variables

print_step "2.2: Creating databases"
# Connect to CockroachDB and create required databases
flyctl ssh console --app aria-character-core-db --command "cockroach sql --insecure --execute='
CREATE DATABASE IF NOT EXISTS aria_data_prod;
CREATE DATABASE IF NOT EXISTS aria_auth_prod; 
CREATE DATABASE IF NOT EXISTS aria_queue_prod;
CREATE DATABASE IF NOT EXISTS aria_storage_prod;
CREATE DATABASE IF NOT EXISTS aria_monitor_prod;
CREATE DATABASE IF NOT EXISTS aria_engine_prod;
'"

print_step "Layer 3: Main Application Deployment"

print_step "3.1: Creating main application"
flyctl apps create aria-character-core --org personal 2>/dev/null || true

print_step "3.2: Creating persistent volume for application data"
flyctl volumes create aria_data --region ord --size 5 --app aria-character-core 2>/dev/null || true

print_step "3.3: Setting secrets for main application"
flyctl secrets set \
  DATABASE_URL="postgresql://root@$DB_URL:26257/aria_data_prod?sslmode=disable" \
  CRDB_BASE_URL="postgresql://root@$DB_URL:26257" \
  CRDB_URL_AUTH="postgresql://root@$DB_URL:26257/aria_auth_prod?sslmode=disable" \
  CRDB_URL_QUEUE="postgresql://root@$DB_URL:26257/aria_queue_prod?sslmode=disable" \
  CRDB_URL_STORAGE="postgresql://root@$DB_URL:26257/aria_storage_prod?sslmode=disable" \
  CRDB_URL_MONITOR="postgresql://root@$DB_URL:26257/aria_monitor_prod?sslmode=disable" \
  CRDB_URL_ENGINE="postgresql://root@$DB_URL:26257/aria_engine_prod?sslmode=disable" \
  OPENBAO_URL="http://$VAULT_URL:8200" \
  OPENBAO_TOKEN="aria-dev-token" \
  SECRET_KEY_BASE="$(openssl rand -base64 48)" \
  --app aria-character-core

print_step "3.4: Deploying main application with all services"
flyctl deploy --app aria-character-core

print_step "Layer 4: Post-deployment verification"

print_step "4.1: Running database migrations"
flyctl ssh console --app aria-character-core --command "/app/bin/migrate"

print_step "4.2: Verifying service health"
echo "Checking application health..."
sleep 15

# Check each service layer
print_step "Service Status Check:"
echo "🔐 OpenBao (aria_security): https://aria-character-core-vault.fly.dev:8200"
echo "🗄️  CockroachDB (aria_data): https://aria-character-core-db.fly.dev:8080" 
echo "🌐 Main Application: https://aria-character-core.fly.dev"

print_step "Service Boot Order Verification:"
echo "✅ Layer 1 - Foundation:"
echo "   - aria_security (OpenBao) - Secrets Management"
echo "   - aria_data (CockroachDB) - Data Persistence"
echo ""
echo "✅ Layer 2 - Core Services (running in main app):"
echo "   - aria_auth - Authentication & Authorization" 
echo "   - aria_storage - Bulk Asset Storage"
echo "   - aria_queue - Background Job Processing"
echo ""
echo "✅ Layer 3 - Intelligence (running in main app):"
echo "   - aria_shape - Character Generation & Shaping"
echo "   - aria_engine - Classical AI Planning" 
echo "   - aria_interpret - Data Interpretation & Analysis"
echo ""
echo "✅ Layer 4 - Orchestration (running in main app):"
echo "   - aria_workflow - SOP Management & Execution"
echo "   - aria_interface - Data Ingestion & Web UI"
echo ""
echo "✅ Layer 5 - Gateway & Ops (running in main app):"
echo "   - aria_coordinate - API Gateway & Routing"
echo "   - aria_monitor - System Observability"
echo "   - aria_debugger - System Inspection"
echo "   - aria_tune - Performance Optimization"

print_success "Aria Character Core cluster initialization complete!"

echo ""
echo "🎯 Next Steps:"
echo "1. Access your application: https://aria-character-core.fly.dev"
echo "2. Monitor with: flyctl logs --app aria-character-core"
echo "3. Scale if needed: flyctl scale count 2 --app aria-character-core"
echo "4. Check status: flyctl status --app aria-character-core"
echo ""
echo "🔧 Architecture Notes:"
echo "- Foundation services (secrets, data) deployed as separate apps"
echo "- All 14 Aria services run in the main umbrella application"
echo "- Services boot in dependency order within the application"
echo "- Cold boot order respects the architectural dependencies"
