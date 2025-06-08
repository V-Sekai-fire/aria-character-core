#!/bin/sh
set -e

# Default values - can be overridden by environment variables
SOFTHSM2_CONF=${SOFTHSM2_CONF:-"/etc/softhsm2.conf"}
TOKEN_DIRECTORY=${TOKEN_DIRECTORY:-"/var/lib/softhsm/tokens/"}
TOKEN_LABEL=${TOKEN_LABEL:-"openbao-token"}
USER_PIN=${OPENBAO_PKCS11_PIN:-"1234"} # Default PIN, should be overridden by env var from secret
SO_PIN=${OPENBAO_PKCS11_SO_PIN:-"123456"} # Default SO PIN, should be overridden by env var from secret
KEY_LABEL=${OPENBAO_PKCS11_KEY_LABEL:-"openbao-key"}

echo "Configuring SoftHSM..."
mkdir -p $(dirname ${SOFTHSM2_CONF})
echo "objectstore.backend = file" > ${SOFTHSM2_CONF}
echo "directories.tokendir = ${TOKEN_DIRECTORY}" >> ${SOFTHSM2_CONF}
echo "log.level = INFO" >> ${SOFTHSM2_CONF}

# Check if the token already exists
if softhsm2-util --show-slots | grep -q "Slot 0 information" && softhsm2-util --show-slots | grep -q "Label: ${TOKEN_LABEL}"; then
    echo "SoftHSM token '${TOKEN_LABEL}' already initialized."
else
    echo "Initializing SoftHSM token '${TOKEN_LABEL}'..."
    softhsm2-util --init-token --slot 0 --label "${TOKEN_LABEL}" --pin "${USER_PIN}" --so-pin "${SO_PIN}"
    echo "Token '${TOKEN_LABEL}' initialized."
fi

# Placeholder for key generation - this is a critical step
# In a real scenario, you would use pkcs11-tool to generate or import keys.
# Example: Check if key exists, if not, generate RSA key pair
# if ! pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --list-objects --slot 0 --login --pin ${USER_PIN} | grep -q "label: '${KEY_LABEL}'"; then
# echo "Generating RSA key pair with label '${KEY_LABEL}'..."
# pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --slot 0 --login --pin ${USER_PIN} \
# --keypairgen --key-type rsa:2048 --label "${KEY_LABEL}" --id 01
# echo "Key pair '${KEY_LABEL}' generated."
# else
# echo "Key '${KEY_LABEL}' already exists."
# fi

echo "SoftHSM setup script finished. Key generation logic needs to be implemented or handled externally."

# Keep the container alive if needed for debugging or if it's meant to be a long-running service
# For a one-shot setup, this script can just exit.
# tail -f /dev/null
