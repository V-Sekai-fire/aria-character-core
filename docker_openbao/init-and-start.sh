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
export SOFTHSM2_CONF="/etc/softhsm2.conf"
echo "SoftHSM configuration set to: $SOFTHSM2_CONF"

# Initialize SoftHSM if needed
echo "Setting up SoftHSM..."

# Fix permissions while running as root
if [ "$(id -u)" = "0" ]; then
    echo "Running as root - fixing permissions..."
    
    # Ensure vault user owns the vault directories
    chown -R vault:vault /vault 2>/dev/null || true
    
    # Fix SoftHSM permissions - critical for PKCS#11 access
    echo "Fixing SoftHSM permissions..."
    chown -R vault:vault /var/lib/softhsm 2>/dev/null || true
    chown -R vault:vault /etc/softhsm2.conf 2>/dev/null || true
    
    # Ensure the tokens directory is accessible
    chmod -R 755 /var/lib/softhsm 2>/dev/null || true
    chmod -R 777 /var/lib/softhsm/tokens 2>/dev/null || true  # Make tokens fully writable
    
    echo "Permissions fixed. Switching to vault user..."
    exec su vault -c "$0 $*"
fi

# Verify SoftHSM library is available
if [ ! -f "/usr/lib64/libsofthsm2.so" ]; then
    echo "ERROR: SoftHSM library not found at /usr/lib64/libsofthsm2.so"
    exit 1
fi
echo "SoftHSM library found!"

# Initialize SoftHSM token if it doesn't exist
echo "Checking for existing OpenBao Token..."
EXISTING_TOKEN=$(softhsm2-util --show-slots 2>/dev/null | grep -A 10 "Label:" | grep "OpenBao Token" || echo "")

if [ -z "$EXISTING_TOKEN" ]; then
    echo "No existing OpenBao Token found - initializing new token..."
    
    # Initialize a new token with label "OpenBao Token"
    softhsm2-util --init-token --slot 0 --label "OpenBao Token" --so-pin 1234 --pin 1234
    echo "OpenBao Token initialized in slot 0"
    OPENBAO_SLOT="0"
else
    echo "Found existing OpenBao Token"
    # Find the slot number for the existing token
    OPENBAO_SLOT=$(softhsm2-util --show-slots 2>/dev/null | grep -B 20 "OpenBao Token" | grep "^Slot [0-9]" | tail -1 | grep -o "[0-9]\+")
    echo "OpenBao Token found in slot: $OPENBAO_SLOT"
fi

# Validate that the slot number is numeric
if ! echo "$OPENBAO_SLOT" | grep -q "^[0-9][0-9]*$"; then
    echo "ERROR: Invalid slot number detected: '$OPENBAO_SLOT'"
    exit 1
fi

echo "Successfully detected OpenBao Token slot: $OPENBAO_SLOT"

# Check if we need to clean up existing keys
if [ "$RESET_HSM_KEYS" = "true" ]; then
    echo "RESET_HSM_KEYS flag detected - cleaning up existing keys..."
    
    # Delete any existing OpenBao keys to start fresh
    softhsm2-util --delete-object --slot "$OPENBAO_SLOT" --label "openbao-seal-key" --pin 1234 2>/dev/null || echo "No existing seal key to delete"
    softhsm2-util --delete-object --slot "$OPENBAO_SLOT" --label "openbao-hmac-key" --pin 1234 2>/dev/null || echo "No existing HMAC key to delete"
    
    # Also remove the OpenBao storage to force complete reinitialization
    rm -rf /vault/data/core 2>/dev/null || true
    rm -rf /vault/data/vault 2>/dev/null || true
    rm -f /vault/data/root_token.txt /vault/data/vault_initialized 2>/dev/null || true
    rm -f /vault/data/hsm_seal_issue 2>/dev/null || true
    
    echo "Existing keys and storage cleaned up for fresh start"
fi

# Set the slot environment variable for the configuration
export OPENBAO_PKCS11_SLOT="$OPENBAO_SLOT"
export OPENBAO_PKCS11_PIN="${OPENBAO_PKCS11_PIN:-1234}"

echo "Using PKCS#11 slot: $OPENBAO_PKCS11_SLOT"
echo "Using PKCS#11 pin: $OPENBAO_PKCS11_PIN"

# Generate the configuration file with the correct slot
cat > /tmp/vault-runtime.hcl << EOF
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
  lib = "/usr/lib64/libsofthsm2.so"
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

# Copy the config file to the proper location
cp /tmp/vault-runtime.hcl /vault/config/vault-runtime.hcl 2>/dev/null || {
    echo "Warning: Cannot write to /vault/config, using temporary config file"
    CONFIG_FILE="/tmp/vault-runtime.hcl"
}

# Use the appropriate config file
CONFIG_FILE="${CONFIG_FILE:-/vault/config/vault-runtime.hcl}"

# Start OpenBao in the background
echo "Starting OpenBao server with HSM seal protection..."
bao server -config="$CONFIG_FILE" &
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
        echo "OpenBao is sealed - this indicates HSM auto-unseal is not working"
        echo "This often happens when keys exist but cannot be found with the configured labels"
        
        # Check if we should force reset the HSM keys
        echo "Attempting to diagnose the HSM seal issue..."
        
        # Try to list objects in the HSM to see what keys exist
        echo "Checking what objects exist in HSM slot $OPENBAO_SLOT:"
        softhsm2-util --show-slots
        echo "Attempting to list objects in slot:"
        pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --slot $OPENBAO_SLOT --list-objects --pin 1234 2>/dev/null || echo "Cannot list objects with pkcs11-tool"
        softhsm2-util --list-objects --slot "$OPENBAO_SLOT" --pin 1234 2>/dev/null || echo "Cannot list HSM objects with softhsm2-util"
        
        # Check if this is a persistent seal issue
        if [ -f "/vault/data/hsm_seal_issue" ]; then
            echo "Persistent HSM seal issue detected. Cleaning up keys and forcing regeneration..."
            # Force cleanup of existing keys
            softhsm2-util --delete-object --slot "$OPENBAO_SLOT" --label "openbao-seal-key" --pin 1234 2>/dev/null || echo "No seal key to delete"
            softhsm2-util --delete-object --slot "$OPENBAO_SLOT" --label "openbao-hmac-key" --pin 1234 2>/dev/null || echo "No HMAC key to delete"
            # Also remove the OpenBao storage to force reinitialization
            rm -rf /vault/data/core 2>/dev/null || true
            rm -rf /vault/data/vault 2>/dev/null || true
            rm -f /vault/data/root_token.txt /vault/data/vault_initialized 2>/dev/null || true
            rm -f /vault/data/hsm_seal_issue 2>/dev/null || true
            echo "Storage cleared. Restarting OpenBao process to reinitialize..."
            kill $BAO_PID 2>/dev/null || true
            sleep 2
            # Restart OpenBao
            bao server -config="$CONFIG_FILE" &
            BAO_PID=$!
            sleep 5
            # Mark that we've attempted this fix
            rm -f /vault/data/hsm_seal_issue
        else
            # Mark this as a seal issue for next restart if it persists
            echo "marking_seal_issue" > /vault/data/hsm_seal_issue
            echo "HSM auto-unseal is not working. You may need to:"
            echo "1. Restart the container with RESET_HSM_KEYS=true environment variable"
            echo "2. Check that the SoftHSM keys match the configured labels"
            echo "Status: $STATUS_RESPONSE"
        fi
    else
        echo "OpenBao is unsealed (HSM auto-unseal working)"
        # Remove any previous seal issue marker
        rm -f /vault/data/hsm_seal_issue 2>/dev/null || true
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
    
    # Enable KV secrets engine for testing
    echo "Enabling KV secrets engine..."
    export VAULT_TOKEN="$ROOT_TOKEN"
    bao secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine already enabled"
    
    echo "OpenBao is ready for security service testing!"
fi

echo "OpenBao setup complete - HSM seal protection is active and read-write capable"
echo "The system is ready for end-to-end security service tests"

# Keep the process running
wait $BAO_PID
