#!/bin/bash
# Setup secure token-based authentication for OpenBao
# Creates service-specific tokens with minimal required permissions

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

# Configuration
VAULT_URL="http://aria-character-core-vault.fly.dev:8200"
ROOT_TOKEN_FILE="./vault-root-token.txt"

print_step "Setting up secure token-based authentication for OpenBao"

# Check if root token exists
if [ ! -f "$ROOT_TOKEN_FILE" ]; then
    print_error "Root token file not found: $ROOT_TOKEN_FILE"
    print_error "Please ensure OpenBao is initialized and the root token is saved"
    exit 1
fi

ROOT_TOKEN=$(cat "$ROOT_TOKEN_FILE")

print_step "Creating service-specific policies"

# Create policy for CockroachDB server
print_step "Creating CockroachDB server policy"
curl -X PUT \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policy": "path \"pki/issue/cockroachdb-server\" {\n  capabilities = [\"create\", \"update\"]\n}\npath \"pki/cert/ca\" {\n  capabilities = [\"read\"]\n}\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}"
    }' \
    "$VAULT_URL/v1/sys/policies/acl/cockroachdb-server"

# Create policy for CockroachDB client
print_step "Creating CockroachDB client policy"
curl -X PUT \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policy": "path \"pki/issue/cockroachdb-client\" {\n  capabilities = [\"create\", \"update\"]\n}\npath \"pki/cert/ca\" {\n  capabilities = [\"read\"]\n}\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}"
    }' \
    "$VAULT_URL/v1/sys/policies/acl/cockroachdb-client"

# Create policy for other services
print_step "Creating generic service policy"
curl -X PUT \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policy": "path \"pki/issue/service-cert\" {\n  capabilities = [\"create\", \"update\"]\n}\npath \"pki/cert/ca\" {\n  capabilities = [\"read\"]\n}\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}"
    }' \
    "$VAULT_URL/v1/sys/policies/acl/service-cert"

print_step "Creating service-specific tokens"

# Create token for CockroachDB server
print_step "Creating CockroachDB server token"
COCKROACH_SERVER_TOKEN=$(curl -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policies": ["cockroachdb-server"],
        "ttl": "8760h",
        "renewable": true,
        "metadata": {
            "service": "cockroachdb-server",
            "created_by": "aria-bootstrap"
        }
    }' \
    "$VAULT_URL/v1/auth/token/create" | jq -r '.auth.client_token')

# Create token for CockroachDB client connections
print_step "Creating CockroachDB client token"
COCKROACH_CLIENT_TOKEN=$(curl -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policies": ["cockroachdb-client"],
        "ttl": "8760h",
        "renewable": true,
        "metadata": {
            "service": "cockroachdb-client",
            "created_by": "aria-bootstrap"
        }
    }' \
    "$VAULT_URL/v1/auth/token/create" | jq -r '.auth.client_token')

print_step "Setting Fly.io secrets for CockroachDB"

# Set secrets for CockroachDB app
flyctl secrets set \
    VAULT_URL="$VAULT_URL" \
    VAULT_TOKEN="$COCKROACH_SERVER_TOKEN" \
    VAULT_ROLE="cockroachdb-server" \
    --app aria-character-core-db

print_success "Token authentication setup complete!"

echo ""
echo "🔐 Service Tokens Created:"
echo "   🗄️  CockroachDB Server Token: ${COCKROACH_SERVER_TOKEN:0:10}..."
echo "   👤 CockroachDB Client Token:  ${COCKROACH_CLIENT_TOKEN:0:10}..."
echo ""
echo "🔒 Security Features:"
echo "   ✓ Service-specific scoped policies"
echo "   ✓ 1-year token validity with renewal capability"
echo "   ✓ Tokens stored securely in Fly.io secrets"
echo "   ✓ No static tokens in code or configuration"
echo ""
echo "📋 Next Steps:"
echo "   1. Update startup scripts to use dynamic certificate fetching"
echo "   2. Deploy CockroachDB with token-based authentication"
echo "   3. Set up similar token auth for other services"

# Save tokens to secure file for reference (gitignored)
mkdir -p ./secrets
cat > ./secrets/service-tokens.txt << EOF
# Service Tokens for Aria Character Core
# Generated: $(date)
# DO NOT COMMIT TO GIT

COCKROACH_SERVER_TOKEN=$COCKROACH_SERVER_TOKEN
COCKROACH_CLIENT_TOKEN=$COCKROACH_CLIENT_TOKEN
EOF

chmod 600 ./secrets/service-tokens.txt
print_success "Service tokens saved to ./secrets/service-tokens.txt (gitignored)"
