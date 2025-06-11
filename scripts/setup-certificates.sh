#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Certificate Authority and CockroachDB Certificate Setup
# Uses OpenBao PKI engine to generate root CA and server certificates

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

# Export OpenBao environment variables
export BAO_ADDR="$VAULT_ADDR"
export BAO_TOKEN="$VAULT_TOKEN"

print_step "Setting up PKI infrastructure in OpenBao"

# Install OpenBao CLI if not present
if ! command -v bao &> /dev/null; then
    print_step "Installing OpenBao CLI"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command -v brew &> /dev/null; then
            brew tap openbao/tap
            brew install openbao/tap/openbao
        else
            print_error "Homebrew not found. Please install OpenBao CLI manually from: https://github.com/openbao/openbao/releases"
            exit 1
        fi
    else
        # Linux installation
        BAO_VERSION="2.2.2"
        wget -O- "https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_linux_amd64.zip" | funzip > /usr/local/bin/bao
        chmod +x /usr/local/bin/bao
    fi
    print_success "OpenBao CLI installed"
fi

# Test connection to OpenBao
print_step "Testing OpenBao connection"
if ! bao status &> /dev/null; then
    print_error "Cannot connect to OpenBao at $VAULT_ADDR"
    print_error "Make sure OpenBao is running and accessible"
    exit 1
fi
print_success "Connected to OpenBao successfully"

# Enable PKI secrets engine
print_step "Enabling PKI secrets engine"
bao secrets enable -path=pki pki || echo "PKI engine may already be enabled"

# Set max lease TTL for the PKI engine
bao secrets tune -max-lease-ttl=87600h pki

# Generate root CA certificate
print_step "Generating root CA certificate"
bao write -field=certificate pki/root/generate/internal \
    common_name="Aria Character Core Root CA" \
    country="US" \
    locality="Chicago" \
    organization="Aria Character Core" \
    ou="Infrastructure" \
    ttl=87600h > "$CERT_DIR/ca.crt"

print_success "Root CA certificate generated: $CERT_DIR/ca.crt"

# Configure PKI URLs
print_step "Configuring PKI certificate URLs"
bao write pki/config/urls \
    issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
    crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

# Create a role for CockroachDB certificates
print_step "Creating CockroachDB certificate role"
bao write pki/roles/cockroachdb-server \
    allowed_domains="aria-character-core-db.fly.dev,localhost,127.0.0.1,*.fly.dev,*.internal" \
    allow_subdomains=true \
    allow_ip_sans=true \
    max_ttl=72h \
    generate_lease=true

# Generate CockroachDB server certificate
print_step "Generating CockroachDB server certificate"
bao write -format=json pki/issue/cockroachdb-server \
    common_name="aria-character-core-db.fly.dev" \
    alt_names="localhost,aria-character-core-db.internal" \
    ip_sans="127.0.0.1" \
    ttl=72h > "$CERT_DIR/cockroach_server_cert.json"

# Extract certificate and private key
jq -r '.data.certificate' "$CERT_DIR/cockroach_server_cert.json" > "$CERT_DIR/cockroach_server.crt"
jq -r '.data.private_key' "$CERT_DIR/cockroach_server_cert.json" > "$CERT_DIR/cockroach_server.key"
jq -r '.data.issuing_ca' "$CERT_DIR/cockroach_server_cert.json" > "$CERT_DIR/ca_chain.crt"

print_success "CockroachDB server certificate generated: $CERT_DIR/cockroach_server.crt"
print_success "CockroachDB server private key generated: $CERT_DIR/cockroach_server.key"

# Set proper permissions
chmod 600 "$CERT_DIR/cockroach_server.key"
chmod 644 "$CERT_DIR/cockroach_server.crt"
chmod 644 "$CERT_DIR/ca.crt"
chmod 644 "$CERT_DIR/ca_chain.crt"

# Generate client certificate for root user
print_step "Creating CockroachDB client certificate role"
bao write pki/roles/cockroachdb-client \
    allowed_domains="root,aria_user" \
    allow_bare_domains=true \
    allow_subdomains=false \
    max_ttl=72h \
    client_flag=true \
    server_flag=false

print_step "Generating CockroachDB client certificate for root user"
bao write -format=json pki/issue/cockroachdb-client \
    common_name="root" \
    ttl=72h > "$CERT_DIR/cockroach_client_cert.json"

# Extract client certificate and private key
jq -r '.data.certificate' "$CERT_DIR/cockroach_client_cert.json" > "$CERT_DIR/client.root.crt"
jq -r '.data.private_key' "$CERT_DIR/cockroach_client_cert.json" > "$CERT_DIR/client.root.key"

chmod 600 "$CERT_DIR/client.root.key"
chmod 644 "$CERT_DIR/client.root.crt"

print_success "CockroachDB client certificate generated: $CERT_DIR/client.root.crt"
print_success "CockroachDB client private key generated: $CERT_DIR/client.root.key"

# Create combined certificate bundle for CockroachDB
print_step "Creating certificate bundle for CockroachDB"
cat "$CERT_DIR/cockroach_server.crt" "$CERT_DIR/ca_chain.crt" > "$CERT_DIR/server.crt"
cp "$CERT_DIR/cockroach_server.key" "$CERT_DIR/server.key"

print_success "Combined server certificate created: $CERT_DIR/server.crt"

# Clean up temporary JSON files
rm -f "$CERT_DIR/cockroach_server_cert.json" "$CERT_DIR/cockroach_client_cert.json"

print_step "Certificate Summary"
echo "📁 Certificate files created in $CERT_DIR:"
echo "   🔐 ca.crt               - Root CA certificate"
echo "   🔐 server.crt           - CockroachDB server certificate (with CA chain)"
echo "   🔑 server.key           - CockroachDB server private key"
echo "   🔐 client.root.crt      - CockroachDB root client certificate"
echo "   🔑 client.root.key      - CockroachDB root client private key"
echo ""
echo "🔧 Next steps:"
echo "   1. Update fly-db.toml to use these certificates"
echo "   2. Mount certificates as secrets in Fly.io"
echo "   3. Configure CockroachDB to use TLS"
echo ""
echo "🎯 Certificate rotation:"
echo "   Certificates are valid for 72 hours and can be renewed via OpenBao"
echo "   Use 'bao write pki/issue/cockroachdb-server ...' to generate new certificates"

print_success "Certificate setup complete!"
