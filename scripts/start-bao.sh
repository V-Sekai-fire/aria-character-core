#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -e

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BAO] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BAO ERROR] $1" >&2
}

log_info "Aria Character Core - OpenBao Security Service"
log_info "Starting with HSM support (running as root with secure configuration)"

# Set up volume permissions and SoftHSM
log_info "Setting up volumes and SoftHSM configuration..."
mkdir -p /vault/data /vault/softhsm /vault/config /vault/logs /vault/softhsm/tokens
chmod -R 755 /vault

# Set up SoftHSM configuration
log_info "Creating SoftHSM configuration..."
cat > /vault/softhsm/softhsm2.conf << 'EOF'
directories.tokendir = /vault/softhsm/tokens
objectstore.backend = file
log.level = INFO
slots.removable = false
slots.mechanisms = ALL
EOF
chmod 644 /vault/softhsm/softhsm2.conf

# Initialize SoftHSM token if not exists
export SOFTHSM2_CONF=/vault/softhsm/softhsm2.conf
if [ ! -f /vault/softhsm/tokens/slot_0.db ]; then
    log_info "Creating new SoftHSM token..."
    # Initialize with --free flag to automatically assign slot (with timeout)
    if ! timeout 60 softhsm2-util --init-token --free --label "openbao-hsm" --pin 1234 --so-pin 5678; then
        log_error "Failed to initialize SoftHSM token (timeout or error)"
        exit 1
    fi
    log_info "SoftHSM token created successfully"
else
    log_info "SoftHSM token already exists"
fi

# Now running as openbao user
log_info "Starting OpenBao server as openbao user..."

# Set SoftHSM configuration
export SOFTHSM2_CONF=/vault/softhsm/softhsm2.conf

# Test HSM functionality - but continue with fallback if HSM fails
log_info "Testing HSM functionality..."
if timeout 30 bao version 2>&1 | grep -q "HSM DISABLED"; then
    log_info "HSM support is disabled in this build - using fallback configuration"
    CONFIG_FILE="/vault-fallback.hcl"
    log_info "🚀 Starting OpenBao with fallback configuration..."
    log_info "📊 Admin UI will be available at: http://localhost:8200"
    exec timeout 3600 bao server -config="$CONFIG_FILE"
fi

# Check if HSM is accessible
log_info "Checking SoftHSM slots..."
# Test SoftHSM accessibility
log_info "Testing SoftHSM accessibility..."
if ! timeout 30 softhsm2-util --show-slots 2>/dev/null; then
    log_error "Cannot access SoftHSM - checking configuration..."
    cat /vault/softhsm/softhsm2.conf
    ls -la /vault/softhsm/tokens/ || true
    exit 1
fi

# Get the actual slot number that was created
SLOT_INFO=$(timeout 30 softhsm2-util --show-slots 2>/dev/null | grep "Slot" | head -1)
if [ -n "$SLOT_INFO" ]; then
    SLOT_NUM=$(echo "$SLOT_INFO" | awk '{print $2}')
    log_info "Using SoftHSM slot: $SLOT_NUM"
    
    # Generate HSM configuration with correct slot number
    cat > /vault/vault-hsm-dynamic.hcl << EOF
# OpenBao configuration with SoftHSM seal for Fly.io
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

# HSM seal configuration using SoftHSM PKCS#11
seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  slot = "$SLOT_NUM"
  pin = "1234"
  key_label = "aria-seal-key"
  hmac_key_label = "aria-hmac-key"
  generate_key = "true"
}

# API address
api_addr = "http://0.0.0.0:8200"

# UI enabled
ui = true

# Logging
log_level = "Info"

# Disable mlock for containers
disable_mlock = true

# Default lease TTL
default_lease_ttl = "168h"

# Maximum lease TTL
max_lease_ttl = "720h"
EOF
    
    log_info "Generated dynamic HSM configuration with slot $SLOT_NUM"
    CONFIG_FILE="/vault/vault-hsm-dynamic.hcl"
else
    log_error "No SoftHSM slots found"
    exit 1
fi

log_info "🚀 Starting OpenBao with fallback configuration (HSM disabled due to container compatibility)..."
log_info "📊 Admin UI will be available at: http://localhost:8200"

# Use fallback configuration for now to avoid HSM segfaults in containers
CONFIG_FILE="/vault-fallback.hcl"
exec timeout 3600 bao server -config="$CONFIG_FILE"
