#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Certificate Authority and CockroachDB Certificate Setup via REST API
# Uses OpenBao REST API to generate root CA and server certificates

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
VAULT_ADDR="http://aria-character-core-vault.fly.dev:8200"
VAULT_TOKEN="aria-dev-token"
CERT_DIR="./certs"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

print_step "Setting up PKI infrastructure in OpenBao via REST API"

# Test connection to OpenBao
print_step "Testing OpenBao connection"
if ! curl -s -f "$VAULT_ADDR/v1/sys/health" > /dev/null; then
    print_error "Cannot connect to OpenBao at $VAULT_ADDR"
    exit 1
fi
print_success "Connected to OpenBao successfully"

# Enable PKI secrets engine
print_step "Enabling PKI secrets engine"
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{"type": "pki"}' \
    "$VAULT_ADDR/v1/sys/mounts/pki" || echo "PKI engine may already be enabled"

# Set max lease TTL for the PKI engine
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{"max_lease_ttl": "87600h"}' \
    "$VAULT_ADDR/v1/sys/mounts/pki/tune"

# Generate root CA certificate
print_step "Generating root CA certificate"
ROOT_CA_RESPONSE=$(curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "common_name": "Aria Character Core Root CA",
        "country": "US",
        "locality": "Chicago", 
        "organization": "Aria Character Core",
        "ou": "Infrastructure",
        "ttl": "87600h"
    }' \
    "$VAULT_ADDR/v1/pki/root/generate/internal")

echo "$ROOT_CA_RESPONSE" | jq -r '.data.certificate' > "$CERT_DIR/ca.crt"
print_success "Root CA certificate generated: $CERT_DIR/ca.crt"

# Configure PKI URLs
print_step "Configuring PKI certificate URLs"
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d "{
        \"issuing_certificates\": \"$VAULT_ADDR/v1/pki/ca\",
        \"crl_distribution_points\": \"$VAULT_ADDR/v1/pki/crl\"
    }" \
    "$VAULT_ADDR/v1/pki/config/urls"

# Create a role for CockroachDB certificates
print_step "Creating CockroachDB certificate role"
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "allowed_domains": "aria-character-core-db.fly.dev,localhost,127.0.0.1,*.fly.dev,*.internal",
        "allow_subdomains": true,
        "allow_ip_sans": true,
        "max_ttl": "72h",
        "generate_lease": true
    }' \
    "$VAULT_ADDR/v1/pki/roles/cockroachdb-server"

# Generate CockroachDB server certificate
print_step "Generating CockroachDB server certificate"
SERVER_CERT_RESPONSE=$(curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "common_name": "aria-character-core-db.fly.dev",
        "alt_names": "localhost,aria-character-core-db.internal",
        "ip_sans": "127.0.0.1",
        "ttl": "72h"
    }' \
    "$VAULT_ADDR/v1/pki/issue/cockroachdb-server")

# Extract certificate and private key
echo "$SERVER_CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_DIR/cockroach_server.crt"
echo "$SERVER_CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_DIR/cockroach_server.key"
echo "$SERVER_CERT_RESPONSE" | jq -r '.data.issuing_ca' > "$CERT_DIR/ca_chain.crt"

print_success "CockroachDB server certificate generated: $CERT_DIR/cockroach_server.crt"
print_success "CockroachDB server private key generated: $CERT_DIR/cockroach_server.key"

# Set proper permissions
chmod 600 "$CERT_DIR/cockroach_server.key"
chmod 644 "$CERT_DIR/cockroach_server.crt"
chmod 644 "$CERT_DIR/ca.crt"
chmod 644 "$CERT_DIR/ca_chain.crt"

# Create a role for CockroachDB client certificates
print_step "Creating CockroachDB client certificate role"
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "allowed_domains": "root,aria_user",
        "allow_bare_domains": true,
        "allow_subdomains": false,
        "max_ttl": "72h",
        "client_flag": true,
        "server_flag": false
    }' \
    "$VAULT_ADDR/v1/pki/roles/cockroachdb-client"

# Generate CockroachDB client certificate for root user
print_step "Generating CockroachDB client certificate for root user"
CLIENT_CERT_RESPONSE=$(curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
        "common_name": "root",
        "ttl": "72h"
    }' \
    "$VAULT_ADDR/v1/pki/issue/cockroachdb-client")

# Extract client certificate and private key
echo "$CLIENT_CERT_RESPONSE" | jq -r '.data.certificate' > "$CERT_DIR/client.root.crt"
echo "$CLIENT_CERT_RESPONSE" | jq -r '.data.private_key' > "$CERT_DIR/client.root.key"

chmod 600 "$CERT_DIR/client.root.key"
chmod 644 "$CERT_DIR/client.root.crt"

print_success "CockroachDB client certificate generated: $CERT_DIR/client.root.crt"
print_success "CockroachDB client private key generated: $CERT_DIR/client.root.key"

# Create combined certificate bundle for CockroachDB
print_step "Creating certificate bundle for CockroachDB"
cat "$CERT_DIR/cockroach_server.crt" "$CERT_DIR/ca_chain.crt" > "$CERT_DIR/server.crt"
cp "$CERT_DIR/cockroach_server.key" "$CERT_DIR/server.key"

print_success "Combined server certificate created: $CERT_DIR/server.crt"

print_step "Certificate Summary"
echo "📁 Certificate files created in $CERT_DIR:"
echo "   🔐 ca.crt               - Root CA certificate"
echo "   🔐 server.crt           - CockroachDB server certificate (with CA chain)"
echo "   🔑 server.key           - CockroachDB server private key"
echo "   🔐 client.root.crt      - CockroachDB root client certificate"
echo "   🔑 client.root.key      - CockroachDB root client private key"
echo ""

# Display certificate information
print_step "Certificate Details"
echo "🔍 Root CA Certificate:"
openssl x509 -in "$CERT_DIR/ca.crt" -text -noout | grep -E "(Subject:|Not Before|Not After|Serial Number)"

echo ""
echo "🔍 Server Certificate:"
openssl x509 -in "$CERT_DIR/cockroach_server.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:|IP Address)"

echo ""
echo "🔧 Next steps:"
echo "   1. Update fly-db.toml to use these certificates"
echo "   2. Mount certificates as secrets in Fly.io"
echo "   3. Configure CockroachDB to use TLS"
echo ""
echo "🎯 Certificate rotation:"
echo "   Certificates are valid for 72 hours and can be renewed via OpenBao API"

print_success "Certificate setup complete!"
