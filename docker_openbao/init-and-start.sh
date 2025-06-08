#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# OpenBao initialization script for production mode with persistence

set -e

export BAO_ADDR="http://0.0.0.0:8200"
TOKEN_FILE="/vault/data/root_token.txt"
UNSEAL_KEY_FILE="/vault/data/unseal_key.txt"
INIT_FILE="/vault/data/vault_initialized"

echo "Starting OpenBao initialization script..."

# Start OpenBao in the background
echo "Starting OpenBao server in production mode..."
bao server -config=/vault/config/vault-dev-persistent.hcl &
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

if [ "$IS_INITIALIZED" = "true" ] && [ -f "$TOKEN_FILE" ] && [ -f "$UNSEAL_KEY_FILE" ]; then
    echo "OpenBao already initialized, using existing credentials..."
    ROOT_TOKEN=$(cat "$TOKEN_FILE")
    UNSEAL_KEY=$(cat "$UNSEAL_KEY_FILE")
    
    # Check if sealed and unseal if needed
    IS_SEALED=$(echo "$STATUS_RESPONSE" | grep -o '"sealed":[^,]*' | cut -d':' -f2)
    if [ "$IS_SEALED" = "true" ]; then
        echo "OpenBao is sealed, unsealing..."
        bao operator unseal "$UNSEAL_KEY"
    fi
    
    echo "Root Token: $ROOT_TOKEN"
    echo "OpenBao is ready!"
else
    echo "Initializing OpenBao for the first time..."
    
    # Initialize OpenBao
    INIT_RESPONSE=$(bao operator init -key-shares=1 -key-threshold=1 -format=json)
    
    # Extract keys and token
    UNSEAL_KEY=$(echo "$INIT_RESPONSE" | grep -o '"keys":\["[^"]*"' | cut -d'"' -f4)
    ROOT_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
    
    # Save the credentials
    echo "$ROOT_TOKEN" > "$TOKEN_FILE"
    echo "$UNSEAL_KEY" > "$UNSEAL_KEY_FILE"
    
    # Mark as initialized
    echo "initialized" > "$INIT_FILE"
    
    # Unseal OpenBao
    echo "Unsealing OpenBao..."
    bao operator unseal "$UNSEAL_KEY"
    
    echo "Root Token: $ROOT_TOKEN"
    echo "Unseal Key: $UNSEAL_KEY"
    echo "OpenBao initialized and unsealed successfully!"
    
    # Enable KV secrets engine
    echo "Enabling KV secrets engine..."
    export VAULT_TOKEN="$ROOT_TOKEN"
    bao secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine already enabled"
fi

# Keep the process running
wait $BAO_PID
    bao operator unseal "$UNSEAL_KEY"
    
    echo "OpenBao initialized successfully!"
    echo "Root Token: $ROOT_TOKEN"
    echo "Unseal Key: $UNSEAL_KEY"
    
    # Enable KV secrets engine
    export VAULT_TOKEN="$ROOT_TOKEN"
    bao secrets enable -path=secret kv
    echo "KV secrets engine enabled at path: secret"
fi

# Keep the process running
wait $BAO_PID
