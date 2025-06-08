#!/bin/bash
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

# Initialize the token
softhsm2-util --init-token \
  --slot $OPENBAO_PKCS11_SLOT \
  --label "OpenBao Token" \
  --so-pin $OPENBAO_PKCS11_SO_PIN \
  --pin $OPENBAO_PKCS11_PIN

echo "SoftHSM token initialized successfully on slot $OPENBAO_PKCS11_SLOT"

# List tokens to verify
echo "Available tokens:"
softhsm2-util --show-slots

echo "SoftHSM setup complete."
