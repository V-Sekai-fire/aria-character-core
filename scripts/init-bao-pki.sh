#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# OpenBao initialization script for PKI setup
# Run this after OpenBao is deployed to set up PKI infrastructure

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

# Configuration
BAO_ADDR="http://aria-character-core-bao.fly.dev:8200"
INIT_FILE="./bao-init.json"

print_step "Initializing OpenBao PKI Infrastructure"

# Check if OpenBao is running
print_step "Checking OpenBao status"
if ! curl -s "$BAO_ADDR/v1/sys/health" > /dev/null; then
    print_error "OpenBao is not accessible at $BAO_ADDR"
    print_error "Please ensure OpenBao is deployed and running"
    exit 1
fi

# Check if already initialized
if curl -s "$BAO_ADDR/v1/sys/init" | jq -r '.initialized' | grep -q true; then
    print_warning "OpenBao is already initialized"
    
    if [ ! -f "$INIT_FILE" ]; then
        print_error "OpenBao is initialized but no init file found"
        print_error "Cannot proceed without root token"
        exit 1
    fi
    
    ROOT_TOKEN=$(jq -r '.root_token' "$INIT_FILE")
    print_info "Using existing root token from $INIT_FILE"
else
    # Initialize OpenBao
    print_step "Initializing OpenBao with HSM seal"
    
    INIT_RESPONSE=$(curl -s -X PUT \
        -d '{
            "recovery_shares": 5,
            "recovery_threshold": 3
        }' \
        "$BAO_ADDR/v1/sys/init")
    
    # Save initialization data
    echo "$INIT_RESPONSE" > "$INIT_FILE"
    chmod 600 "$INIT_FILE"
    
    ROOT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r '.root_token')
    
    print_success "OpenBao initialized successfully"
    print_success "Root token and recovery keys saved to $INIT_FILE"
fi

# Set up PKI backend
print_step "Setting up PKI backend"

# Enable PKI secrets engine
curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{"type": "pki"}' \
    "$BAO_ADDR/v1/sys/mounts/pki" || echo "PKI backend may already be enabled"

# Configure PKI backend
curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "ttl": "87600h",
        "max_ttl": "87600h"
    }' \
    "$BAO_ADDR/v1/pki/config/urls"

# Generate root CA
print_step "Generating root CA certificate"

ROOT_CA_RESPONSE=$(curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "common_name": "Aria Character Core Root CA",
        "country": "US",
        "locality": "Chicago",
        "organization": "Aria Character Core",
        "ou": "Infrastructure",
        "ttl": "87600h"
    }' \
    "$BAO_ADDR/v1/pki/root/generate/internal")

# Save CA certificate
echo "$ROOT_CA_RESPONSE" | jq -r '.data.certificate' > ./certs/ca.crt
print_success "Root CA certificate saved to ./certs/ca.crt"

# Create certificate roles for services
print_step "Creating certificate roles"

# CockroachDB server role
curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "allowed_domains": ["fly.dev", "localhost"],
        "allow_subdomains": true,
        "allow_localhost": true,
        "allow_ip_sans": true,
        "max_ttl": "72h",
        "ttl": "72h"
    }' \
    "$BAO_ADDR/v1/pki/roles/cockroachdb-server"

# CockroachDB client role
curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "allowed_domains": ["root", "aria_user"],
        "allow_bare_domains": true,
        "max_ttl": "72h",
        "ttl": "72h"
    }' \
    "$BAO_ADDR/v1/pki/roles/cockroachdb-client"

print_success "Certificate roles created"

# Create a service token for certificate operations (non-root)
print_step "Creating service token for certificate operations"

SERVICE_TOKEN_RESPONSE=$(curl -s -X POST \
    -H "X-Vault-Token: $ROOT_TOKEN" \
    -d '{
        "policies": ["default"],
        "ttl": "720h",
        "renewable": true
    }' \
    "$BAO_ADDR/v1/auth/token/create")

SERVICE_TOKEN=$(echo "$SERVICE_TOKEN_RESPONSE" | jq -r '.auth.client_token')

# Save service token
echo "{\"service_token\": \"$SERVICE_TOKEN\"}" > ./bao-service-token.json
chmod 600 ./bao-service-token.json

print_success "PKI infrastructure setup complete!"

echo ""
echo "🔐 Security Files Created:"
echo "   📄 $INIT_FILE - Root token and recovery keys (KEEP SECURE)"
echo "   📄 ./bao-service-token.json - Service token for operations"
echo "   🔐 ./certs/ca.crt - Root CA certificate"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "   • Store $INIT_FILE in a secure location"
echo "   • Never commit tokens to version control"
echo "   • Root token should only be used for initial setup"
echo "   • Use service tokens for routine operations"
echo ""
echo "🎯 Next Steps:"
echo "   1. Set up machine authentication: ./scripts/setup-machine-auth.sh"
echo "   2. Deploy CockroachDB: ./scripts/deploy-cockroachdb.sh"
