#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# CockroachDB startup script with dynamic certificate fetching
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate required environment variables
if [ -z "$VAULT_ROLE_ID" ] || [ -z "$VAULT_SECRET_ID" ]; then
    log_error "VAULT_ROLE_ID and VAULT_SECRET_ID must be set for certificate fetching"
    exit 1
fi

log_info "🚀 Starting CockroachDB with OpenBao certificate integration"
log_info "🔐 Vault Address: ${VAULT_ADDR}"
log_info "📁 Certificate Directory: /cockroach/certs"

log_info "⚙️  Setting up CockroachDB certificates..."

# Create certs directory
mkdir -p /cockroach/certs
chmod 755 /cockroach/certs

# Fetch server certificates from OpenBao
log_info "📡 Fetching server certificates from OpenBao..."
export CERT_DIR="/cockroach/certs"
export SERVICE_TYPE="cockroachdb-server"
export COMMON_NAME="${FLY_APP_NAME:-cockroachdb}.fly.dev"
export ALT_NAMES="localhost,${FLY_APP_NAME:-cockroachdb}.internal,*.${FLY_APP_NAME:-cockroachdb}.internal"
export IP_SANS="127.0.0.1,::1"

# Use the certificate fetching script
if ! /usr/local/bin/fetch-certificates.sh; then
    log_error "Failed to fetch server certificates"
    exit 1
fi

# Fetch client certificates (for administrative operations)
log_info "👤 Fetching client certificates from OpenBao..."
export SERVICE_TYPE="cockroachdb-client"
export COMMON_NAME="root"
unset ALT_NAMES IP_SANS

# Fetch client certificates
if ! /usr/local/bin/fetch-certificates.sh; then
    log_error "Failed to fetch client certificates"
    exit 1
fi

# Validate certificates
log_info "🔍 Validating certificates..."
for cert_file in ca.crt node.crt client.root.crt; do
    if [ ! -f "/cockroach/certs/$cert_file" ]; then
        log_error "Required certificate file missing: $cert_file"
        exit 1
    fi
    
    # Check certificate validity
    if ! openssl x509 -in "/cockroach/certs/$cert_file" -noout -checkend 3600; then
        log_error "Certificate $cert_file expires within 1 hour or is invalid"
        exit 1
    fi
done

log_success "✅ Certificates fetched and validated successfully"

# Start certificate renewal daemon in background
log_info "🔄 Starting certificate renewal daemon..."
export SERVICE_TYPE="cockroachdb-server"
export CERT_DIR="/cockroach/certs"
/usr/local/bin/renew-certificates.sh daemon &
RENEWAL_PID=$!
log_info "Certificate renewal daemon started with PID: $RENEWAL_PID"

# Setup graceful shutdown handler
cleanup() {
    log_info "🛑 Shutting down CockroachDB and certificate renewal daemon..."
    if [ ! -z "$RENEWAL_PID" ]; then
        kill $RENEWAL_PID 2>/dev/null || true
        log_info "Certificate renewal daemon stopped"
    fi
    # CockroachDB will be stopped by Docker
}
trap cleanup SIGTERM SIGINT

log_info "🚀 Starting CockroachDB with TLS certificates..."
log_info "📊 Admin UI will be available at: https://localhost:8080"
log_info "🔌 SQL interface available at: postgresql://root@localhost:26257/defaultdb?sslmode=require"

# Start CockroachDB with certificates and enhanced security settings
exec cockroach start-single-node \
  --certs-dir=/cockroach/certs \
  --listen-addr=0.0.0.0:26257 \
  --http-addr=0.0.0.0:8080 \
  --store=/cockroach/cockroach-data \
  --cluster-name="aria-character-core" \
  --cache=1GB \
  --max-sql-memory=1GB
