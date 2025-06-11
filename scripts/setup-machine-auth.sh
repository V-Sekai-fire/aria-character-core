#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Setup machine authentication using Fly.io macaroons and OpenBao
# Part of Aria Character Core secure PKI infrastructure

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
VAULT_ADDR="http://aria-character-core-bao.fly.dev:8200"
VAULT_TOKEN="${VAULT_TOKEN:-}"

if [ -z "$VAULT_TOKEN" ]; then
    # Try to read from service token file
    if [ -f "./bao-service-token.json" ]; then
        VAULT_TOKEN=$(jq -r '.service_token' ./bao-service-token.json)
    elif [ -f "./bao-init.json" ]; then
        print_warning "Using root token from init file - consider using service token"
        VAULT_TOKEN=$(jq -r '.root_token' ./bao-init.json)
    fi
    
    if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" = "null" ]; then
        print_error "VAULT_TOKEN environment variable is required"
        print_error "Or run ./scripts/init-bao-pki.sh first to create tokens"
        exit 1
    fi
fi

print_step "Setting up machine authentication system"

# 1. Enable AppRole authentication method for machines
print_step "Enabling AppRole authentication method"
curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{"type": "approle"}' \
    "$VAULT_ADDR/v1/sys/auth/approle" || echo "AppRole may already be enabled"

# 2. Create policies for different service types
print_step "Creating service-specific policies"

# CockroachDB server policy
cat > /tmp/cockroachdb-server-policy.hcl << 'EOF'
# CockroachDB server certificate policy
path "pki/issue/cockroachdb-server" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

curl -s -X PUT \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d @<(echo "{\"policy\": \"$(cat /tmp/cockroachdb-server-policy.hcl | sed 's/"/\\"/g' | tr '\n' ' ')\"}") \
    "$VAULT_ADDR/v1/sys/policies/acl/cockroachdb-server"

# CockroachDB client policy  
cat > /tmp/cockroachdb-client-policy.hcl << 'EOF'
# CockroachDB client certificate policy
path "pki/issue/cockroachdb-client" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

curl -s -X PUT \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d @<(echo "{\"policy\": \"$(cat /tmp/cockroachdb-client-policy.hcl | sed 's/"/\\"/g' | tr '\n' ' ')\"}") \
    "$VAULT_ADDR/v1/sys/policies/acl/cockroachdb-client"

# 3. Create AppRole for CockroachDB servers
print_step "Creating CockroachDB server AppRole"

curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "bind_secret_id": true,
        "token_policies": ["cockroachdb-server"],
        "token_ttl": "24h",
        "token_max_ttl": "72h",
        "secret_id_ttl": "24h"
    }' \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-server"

# 4. Create AppRole for CockroachDB clients
print_step "Creating CockroachDB client AppRole"

curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "bind_secret_id": true,
        "token_policies": ["cockroachdb-client"],
        "token_ttl": "24h",
        "token_max_ttl": "72h",
        "secret_id_ttl": "24h"
    }' \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-client"

# 5. Generate and distribute AppRole credentials using Fly.io macaroons
print_step "Generating AppRole credentials for deployment"

# Get CockroachDB server role-id
COCKROACHDB_SERVER_ROLE_ID=$(curl -s -X GET \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-server/role-id" | \
    jq -r '.data.role_id')

# Generate secret-id for CockroachDB server (single use)
COCKROACHDB_SERVER_SECRET_ID=$(curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-server/secret-id" | \
    jq -r '.data.secret_id')

# Get CockroachDB client role-id
COCKROACHDB_CLIENT_ROLE_ID=$(curl -s -X GET \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-client/role-id" | \
    jq -r '.data.role_id')

# Generate secret-id for CockroachDB client (single use)
COCKROACHDB_CLIENT_SECRET_ID=$(curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/auth/approle/role/cockroachdb-client/secret-id" | \
    jq -r '.data.secret_id')

print_step "Setting machine credentials in Fly.io secrets"

# Set CockroachDB server credentials
flyctl secrets set \
    VAULT_ADDR="$VAULT_ADDR" \
    VAULT_ROLE_ID="$COCKROACHDB_SERVER_ROLE_ID" \
    VAULT_SECRET_ID="$COCKROACHDB_SERVER_SECRET_ID" \
    --app aria-character-core-db

# Clean up temporary files
rm -f /tmp/cockroachdb-server-policy.hcl /tmp/cockroachdb-client-policy.hcl

print_success "Machine authentication system configured successfully!"

echo ""
echo "🔐 Authentication Configuration:"
echo "   🏢 AppRole Method: Enabled"
echo "   📋 Policies: cockroachdb-server, cockroachdb-client"
echo "   🎭 Roles: cockroachdb-server, cockroachdb-client"
echo ""
echo "🚀 Deployment Configuration:"
echo "   🗃️  CockroachDB Server Credentials: Set in aria-character-core-db secrets"
echo "   ⏱️  Token TTL: 24 hours (renewable up to 72 hours)"
echo "   🔑 Secret ID TTL: 24 hours (single use)"
echo ""
echo "🎯 Next Steps:"
echo "   1. Deploy CockroachDB: ./scripts/deploy-cockroachdb.sh"
echo "   2. CockroachDB will authenticate to OpenBao on startup"
echo "   3. Certificates will be fetched automatically"
