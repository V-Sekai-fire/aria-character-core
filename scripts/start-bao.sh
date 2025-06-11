#!/bin/bash
# OpenBao startup script without hardcoded tokens
# Initializes OpenBao with proper HSM configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[BAO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[BAO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[BAO]${NC} $1"
}

log_error() {
    echo -e "${RED}[BAO]${NC} $1"
}

# Initialize SoftHSM if not already done
init_softhsm() {
    log_info "Initializing SoftHSM configuration..."
    
    # Create necessary directories
    mkdir -p /vault/data
    mkdir -p /vault/softhsm/tokens
    mkdir -p /vault/logs
    
    # Create SoftHSM configuration
    cat > /vault/softhsm/softhsm2.conf << EOF
directories.tokendir = /vault/softhsm/tokens
objectstore.backend = file
log.level = INFO
EOF

    # Create token directory
    mkdir -p /vault/softhsm/tokens
    
    # Initialize token if it doesn't exist
    if [ ! -f /vault/softhsm/tokens/token_* ]; then
        log_info "Creating new SoftHSM token..."
        softhsm2-util --init-token \
            --free \
            --label "aria-hsm-token" \
            --pin 1234 \
            --so-pin 1234
        log_success "SoftHSM token initialized"
    else
        log_info "SoftHSM token already exists"
    fi
}

# Start OpenBao server
start_bao() {
    log_info "Starting OpenBao server..."
    
    # Set environment variables
    export SOFTHSM2_CONF="/vault/softhsm/softhsm2.conf"
    export VAULT_ADDR="http://0.0.0.0:8200"
    export OPENBAO_ADDR="http://0.0.0.0:8200"
    
    # Initialize SoftHSM
    init_softhsm
    
    # Start OpenBao with HSM configuration
    log_info "OpenBao starting with HSM seal configuration"
    exec bao server -config=/vault-hsm.hcl
}

# Handle signals for graceful shutdown
trap 'log_info "Received shutdown signal, stopping OpenBao..."; exit 0' SIGTERM SIGINT

# Main execution
log_info "Aria Character Core - OpenBao Security Service"
log_info "Starting without hardcoded tokens - proper HSM initialization"

start_bao
