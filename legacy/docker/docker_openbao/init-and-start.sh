#!/bin/bash

set -e

echo "Starting OpenBao with PKCS#11 HSM seal integration..."

# Clean up any existing tokens first
echo "Cleaning up any existing SoftHSM tokens..."
rm -rf /var/lib/softhsm/tokens/*

# Wait for SoftHSM to be ready
sleep 2

# Always create a fresh token using --free flag to let SoftHSM assign the slot
echo "Creating fresh OpenBao Token with automatic slot assignment..."
INIT_OUTPUT=$(softhsm2-util --init-token --free --label "OpenBao Token" --so-pin 1234 --pin 1234 2>&1)
echo "$INIT_OUTPUT"

# Extract the actual assigned slot number from the output
ASSIGNED_SLOT=$(echo "$INIT_OUTPUT" | grep -o "reassigned to slot [0-9]\+" | grep -o "[0-9]\+" | tail -1)

if [ -z "$ASSIGNED_SLOT" ]; then
    # Fallback: check for direct slot assignment in output
    ASSIGNED_SLOT=$(echo "$INIT_OUTPUT" | grep -o "slot [0-9]\+" | grep -o "[0-9]\+" | tail -1)
fi

if [ -z "$ASSIGNED_SLOT" ]; then
    echo "ERROR: Could not determine assigned slot number from SoftHSM output"
    echo "SoftHSM output was: $INIT_OUTPUT"
    exit 1
fi

echo "Fresh OpenBao Token initialized and assigned to slot $ASSIGNED_SLOT"
OPENBAO_SLOT="$ASSIGNED_SLOT"

# List all available slots for verification
echo "Available PKCS#11 slots:"
softhsm2-util --show-slots

# Generate an RSA-2048 key pair for the seal
echo "Generating RSA-2048 key pair for OpenBao seal..."
pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so --login --pin 1234 --slot $OPENBAO_SLOT --keypairgen --key-type rsa:2048 --label "openbao-seal-key"

# List objects to confirm key creation
echo "PKCS#11 objects in slot $OPENBAO_SLOT:"
pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so --login --pin 1234 --slot $OPENBAO_SLOT --list-objects

# Create the OpenBao configuration file with the actual slot number
echo "Creating OpenBao configuration with slot $OPENBAO_SLOT..."
cat > /vault/config/openbao.hcl << EOF
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

seal "pkcs11" {
  lib = "/usr/lib64/pkcs11/libsofthsm2.so"
  slot = "$OPENBAO_SLOT"
  pin = "1234"
  key_label = "openbao-seal-key"
  mechanism = "0x00000009"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"
ui = true
EOF

# Verify the configuration file
echo "OpenBao configuration:"
cat /vault/config/openbao.hcl

# Export the slot for use by the OpenBao process
export OPENBAO_PKCS11_SLOT="$OPENBAO_SLOT"

# Start OpenBao
echo "Starting OpenBao with PKCS#11 seal..."
exec bao server -config=/vault/config/openbao.hcl