#!/bin/bash
# Deploy OpenBao (renamed from vault) without hardcoded tokens
# Part of Aria Character Core secure infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_step "Deploying OpenBao Security Service"

# Create certs directory if it doesn't exist
mkdir -p ./certs

# Destroy old vault service if it exists
print_step "Cleaning up old vault service"
flyctl apps destroy aria-character-core-vault --yes 2>/dev/null || echo "Old vault app not found"

# Create OpenBao app
print_step "Creating OpenBao app"
flyctl apps create aria-character-core-bao --org personal 2>/dev/null || echo "App may already exist"

# Create volumes for OpenBao
print_step "Creating persistent volumes"
flyctl volumes create bao_data --region ord --size 5 --app aria-character-core-bao 2>/dev/null || echo "Data volume may already exist"
flyctl volumes create bao_softhsm --region ord --size 1 --app aria-character-core-bao 2>/dev/null || echo "HSM volume may already exist"

# Deploy OpenBao
print_step "Deploying OpenBao with HSM configuration"
flyctl deploy --config fly-bao.toml --app aria-character-core-bao

print_step "Waiting for OpenBao to start..."
sleep 30

# Check deployment status
print_step "Checking OpenBao status"
flyctl status --app aria-character-core-bao

print_success "OpenBao deployment complete!"

echo ""
echo "🔐 OpenBao Security Service:"
echo "   🌐 URL: http://aria-character-core-bao.fly.dev:8200"
echo "   🛡️  HSM: SoftHSM PKCS#11 backing"
echo "   🚫 No hardcoded tokens"
echo ""
echo "🎯 Next Steps:"
echo "   1. Initialize PKI: ./scripts/init-bao-pki.sh"
echo "   2. Set up machine auth: ./scripts/setup-machine-auth.sh"
echo "   3. Deploy CockroachDB: ./scripts/deploy-cockroachdb.sh"
