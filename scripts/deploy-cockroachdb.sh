#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Deploy CockroachDB with dynamic certificate fetching from OpenBao
# Part of Aria Character Core cold boot order deployment

set -e

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

print_step "Deploying CockroachDB with dynamic certificate fetching"

# Check if machine authentication is set up
print_step "Checking machine authentication setup"
if ! flyctl secrets list --app aria-character-core-db | grep -q "VAULT_ROLE_ID"; then
    print_error "Machine authentication not configured"
    print_error "Please run ./scripts/setup-machine-auth.sh first"
    exit 1
fi

# Create CockroachDB app
print_step "Creating CockroachDB app"
flyctl apps create aria-character-core-db --org personal 2>/dev/null || echo "App may already exist"

# Create volumes
print_step "Creating persistent volumes"
flyctl volumes create cockroach_data --region ord --size 10 --app aria-character-core-db 2>/dev/null || echo "Data volume may already exist"

print_step "Deploying CockroachDB with dynamic certificate configuration"
flyctl deploy --config fly-db.toml --app aria-character-core-db

print_step "Waiting for CockroachDB to start..."
sleep 30

# Check deployment status
print_step "Checking CockroachDB status"
flyctl status --app aria-character-core-db

print_success "CockroachDB deployment complete!"

echo ""
echo "🔐 Security Configuration:"
echo "   🏢 AppRole Authentication: Enabled"
echo "   🔄 Dynamic Certificate Fetching: Configured"
echo "   ⏱️  Certificate TTL: 72 hours with auto-renewal"
echo "   🚫 No pre-shared certificate secrets required"
echo ""
echo "🔗 Connection Information:"
echo "   Database URL: postgresql://root@aria-character-core-db.fly.dev:26257/defaultdb?sslmode=require"
echo "   Admin UI: https://aria-character-core-db.fly.dev:8080"
echo ""
echo "🎯 Next Steps:"
echo "   1. Initialize databases: flyctl ssh console --app aria-character-core-db --command 'cockroach sql --certs-dir=/cockroach/certs --host=localhost'"
echo "   2. Continue with main application deployment"
