#!/bin/sh
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Use less strict error handling to avoid hangs
set -eu

echo "Initializing SoftHSM tokens..."

# Default values if environment variables are not set
OPENBAO_PKCS11_PIN=${OPENBAO_PKCS11_PIN:-1234}
OPENBAO_PKCS11_SO_PIN=${OPENBAO_PKCS11_SO_PIN:-5678}
OPENBAO_PKCS11_SLOT=${OPENBAO_PKCS11_SLOT:-0}

echo "Using PKCS#11 slot: $OPENBAO_PKCS11_SLOT"

# Create the tokens directory if it doesn't exist
mkdir -p /var/lib/softhsm/tokens

# Create SoftHSM configuration file
cat > /etc/softhsm2.conf << EOF
# SoftHSM v2 configuration file
directories.tokendir = /var/lib/softhsm/tokens
objectstore.backend = file
log.level = INFO
slots.removable = false
EOF

echo "Created SoftHSM configuration:"
cat /etc/softhsm2.conf

# Check available slots first
echo "Checking available slots before initialization:"
softhsm2-util --show-slots

# Check if OpenBao Token already exists
if softhsm2-util --show-slots | grep -q "OpenBao Token"; then
    echo "OpenBao Token already exists, skipping initialization..."
    # Use a simpler method to extract slot number
    EXISTING_SLOT=$(softhsm2-util --show-slots | grep -B10 "OpenBao Token" | grep "^Slot " | tail -1 | cut -d' ' -f2 || echo "")
    if [ -n "$EXISTING_SLOT" ]; then
        echo "Existing OpenBao Token found in slot: $EXISTING_SLOT"
    else
        echo "Found OpenBao Token but could not determine slot number"
    fi
else
    # Initialize the token using --free to find the first available slot
    echo "Initializing token on first free slot..."
    softhsm2-util --init-token \
      --free \
      --label "OpenBao Token" \
      --so-pin $OPENBAO_PKCS11_SO_PIN \
      --pin $OPENBAO_PKCS11_PIN || echo "Token initialization failed or token already exists"
    echo "SoftHSM token initialization attempt completed"
fi

# List tokens to verify and show which slot was assigned
echo "Available tokens after setup:"
softhsm2-util --show-slots

# Find the slot number that was assigned to our token using a simpler method
ASSIGNED_SLOT=$(softhsm2-util --show-slots | grep -B10 "OpenBao Token" | grep "^Slot " | tail -1 | cut -d' ' -f2 || echo "unknown")
if [ "$ASSIGNED_SLOT" != "unknown" ] && [ -n "$ASSIGNED_SLOT" ]; then
    echo "OpenBao Token is available in slot: $ASSIGNED_SLOT"
    echo "Set OPENBAO_PKCS11_SLOT=$ASSIGNED_SLOT in your environment"
else
    echo "Warning: Could not determine OpenBao Token slot number"
    # Fallback: just show all slots with tokens
    echo "Available initialized tokens:"
    softhsm2-util --show-slots | grep -A1 "Initialized:.*yes" || echo "No initialized tokens found"
fi

echo "SoftHSM setup complete."

# Copy SoftHSM libraries and configuration to shared volume for OpenBao container
echo "Copying SoftHSM libraries to shared volume..."
mkdir -p /usr/lib/softhsm
# Find and copy all SoftHSM libraries
find /usr -name "*softhsm*" -type f -exec cp {} /usr/lib/softhsm/ \; 2>/dev/null || true
# Also copy from specific paths
cp -r /usr/lib/softhsm/* /usr/lib/softhsm/ 2>/dev/null || true

# Copy the SoftHSM configuration to the shared volume
echo "Copying SoftHSM configuration to shared volume..."
cp /etc/softhsm2.conf /usr/lib/softhsm/softhsm2.conf
echo "SoftHSM configuration copied to /usr/lib/softhsm/softhsm2.conf"

ls -la /usr/lib/softhsm/
echo "Library and configuration copying complete."
