#!/bin/sh
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -euo pipefail

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

# Initialize the token using --free-slot to find the first available slot
echo "Initializing token on first free slot..."
softhsm2-util --init-token \
  --free-slot \
  --label "OpenBao Token" \
  --so-pin $OPENBAO_PKCS11_SO_PIN \
  --pin $OPENBAO_PKCS11_PIN

echo "SoftHSM token initialized successfully"

# List tokens to verify and show which slot was assigned
echo "Available tokens after initialization:"
softhsm2-util --show-slots

# Find the slot number that was assigned to our token
ASSIGNED_SLOT=$(softhsm2-util --show-slots | grep "OpenBao Token" | grep -o "Slot [0-9]*" | cut -d' ' -f2)
if [ -n "$ASSIGNED_SLOT" ]; then
    echo "Token was assigned to slot: $ASSIGNED_SLOT"
    echo "Set OPENBAO_PKCS11_SLOT=$ASSIGNED_SLOT in your environment"
else
    echo "Warning: Could not determine assigned slot number"
fi

echo "SoftHSM setup complete."
