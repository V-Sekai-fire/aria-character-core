#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# OpenBao initialization script for production mode with HSM seal protection

set -e

export BAO_ADDR="http://0.0.0.0:8200"
TOKEN_FILE="/vault/data/root_token.txt"
INIT_FILE="/vault/data/vault_initialized"

echo "Starting OpenBao initialization script..."

# Set up SoftHSM configuration
export SOFTHSM2_CONF="/usr/lib/softhsm/softhsm2.conf"
echo "SoftHSM configuration set to: $SOFTHSM2_CONF"

# Wait for SoftHSM configuration to be available
echo "Waiting for SoftHSM configuration..."
while [ ! -f "$SOFTHSM2_CONF" ]; do
    echo "Waiting for SoftHSM configuration file..."
    sleep 2
done
echo "SoftHSM configuration found!"

# Verify SoftHSM library is available
if [ ! -f "/usr/lib/softhsm/libsofthsm2.so" ]; then
    echo "ERROR: SoftHSM library not found at /usr/lib/softhsm/libsofthsm2.so"
    exit 1
fi
echo "SoftHSM library found!"

# List available slots to determine the correct slot number
echo "Checking available SoftHSM slots..."
/usr/lib/softhsm/softhsm2-util --show-slots || echo "Cannot list slots yet"

# Try to find the OpenBao Token slot dynamically
OPENBAO_SLOT=""
if /usr/lib/softhsm/softhsm2-util --show-slots 2>/dev/null | grep -q "OpenBao Token"; then
    # Extract slot number from the output
    OPENBAO_SLOT=$(/usr/lib/softhsm/softhsm2-util --show-slots | grep -B10 "OpenBao Token" | grep "^Slot " | tail -1 | cut -d' ' -f2 || echo "")
    echo "Found OpenBao Token in slot: $OPENBAO_SLOT"
else
    echo "OpenBao Token not found, using environment variable or default"
    OPENBAO_SLOT="${OPENBAO_PKCS11_SLOT:-0}"
fi

# Set the slot environment variable for the configuration
export OPENBAO_PKCS11_SLOT="$OPENBAO_SLOT"
export OPENBAO_PKCS11_PIN="${OPENBAO_PKCS11_PIN:-1234}"

echo "Using PKCS#11 slot: $OPENBAO_PKCS11_SLOT"
echo "Using PKCS#11 pin: $OPENBAO_PKCS11_PIN"

# Generate the configuration file with the correct slot
cat > /vault/config/vault-runtime.hcl << EOF
# OpenBao configuration for production with SoftHSM seal protection
# Generated at runtime with correct slot number

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
  slot = "$OPENBAO_PKCS11_SLOT"
  pin = "$OPENBAO_PKCS11_PIN"
  key_label = "openbao-seal-key"
  hmac_key_label = "openbao-hmac-key"
  generate_key = "true"
}

# API address
api_addr = "http://0.0.0.0:8200"

# Cluster address
cluster_addr = "http://0.0.0.0:8201"

# UI enabled
ui = true

# Logging
log_level = "Info"

# Disable mlock for development
disable_mlock = true

# Default lease TTL
default_lease_ttl = "168h"

# Maximum lease TTL
max_lease_ttl = "720h"
EOF

echo "Generated runtime configuration with slot $OPENBAO_PKCS11_SLOT"

# Start OpenBao in the background
echo "Starting OpenBao server with HSM seal protection..."
bao server -config=/vault/config/vault-runtime.hcl &
BAO_PID=$!

# Wait for OpenBao to start
echo "Waiting for OpenBao to start..."
until curl -sf $BAO_ADDR/v1/sys/health 2>/dev/null || curl -sf $BAO_ADDR/v1/sys/seal-status 2>/dev/null; do
    echo "Waiting for OpenBao..."
    sleep 2
done

echo "OpenBao is running, checking initialization status..."

# Check if OpenBao is already initialized
STATUS_RESPONSE=$(curl -sf $BAO_ADDR/v1/sys/health 2>/dev/null || curl -sf $BAO_ADDR/v1/sys/seal-status)
IS_INITIALIZED=$(echo "$STATUS_RESPONSE" | grep -o '"initialized":[^,]*' | cut -d':' -f2)

if [ "$IS_INITIALIZED" = "true" ]; then
    echo "OpenBao already initialized with HSM seal protection"
    
    # Try to load existing root token (only thing stored in clear)
    if [ -f "$TOKEN_FILE" ]; then
        ROOT_TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n\r')
        
        if [ -n "$ROOT_TOKEN" ]; then
            echo "Root token loaded from persistent storage"
            echo "Root Token: $ROOT_TOKEN"
        else
            echo "WARNING: Root token file is empty. You may need to generate a new one."
        fi
    else
        echo "WARNING: No root token file found. You may need to generate one manually."
    fi
    
    # With HSM seal, OpenBao should unseal automatically
    IS_SEALED=$(echo "$STATUS_RESPONSE" | grep -o '"sealed":[^,]*' | cut -d':' -f2)
    if [ "$IS_SEALED" = "true" ]; then
        echo "OpenBao is sealed - this is unexpected with HSM auto-unseal"
        echo "HSM may not be properly configured"
        exit 1
    else
        echo "OpenBao is unsealed (HSM auto-unseal working)"
    fi
    
    echo "OpenBao is ready!"
    
else
    echo "Initializing OpenBao for the first time with HSM seal..."
    
    # Initialize OpenBao (with HSM seal, no unseal keys are returned)
    INIT_RESPONSE=$(bao operator init -format=json)
    
    # Extract root token (no unseal keys with HSM seal)
    ROOT_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$ROOT_TOKEN" ]; then
        echo "ERROR: Failed to extract root token from initialization response"
        exit 1
    fi
    
    # Save only the root token (seal keys are in HSM)
    echo "$ROOT_TOKEN" > "$TOKEN_FILE"
    
    # Mark as initialized
    echo "initialized" > "$INIT_FILE"
    
    echo "Root Token: $ROOT_TOKEN"
    echo "OpenBao initialized successfully with HSM seal protection!"
    echo "Seal keys are securely stored in SoftHSM"
    
    # Enable KV secrets engine
    echo "Enabling KV secrets engine..."
    export VAULT_TOKEN="$ROOT_TOKEN"
    bao secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine already enabled"
fi

# Keep the process running
wait $BAO_PID
