#!/bin/bash
# CockroachDB startup script with dynamic certificate fetching
set -e

echo "Setting up CockroachDB certificates..."

# Create certs directory
mkdir -p /cockroach/certs
chmod 755 /cockroach/certs

# Fetch server certificates from OpenBao
echo "Fetching server certificates from OpenBao..."
export CERT_DIR="/cockroach/certs"
export SERVICE_TYPE="cockroachdb-server"
export COMMON_NAME="${FLY_APP_NAME}.fly.dev"
export ALT_NAMES="localhost,${FLY_APP_NAME}.internal"
export IP_SANS="127.0.0.1"

# Use the certificate fetching script
/usr/local/bin/fetch-certificates.sh

# Fetch client certificates (for administrative operations)
echo "Fetching client certificates from OpenBao..."
export SERVICE_TYPE="cockroachdb-client"
export COMMON_NAME="root"
unset ALT_NAMES IP_SANS

# Fetch client certificates
/usr/local/bin/fetch-certificates.sh

echo "Certificates fetched and configured successfully"

# Start certificate renewal daemon in background
echo "Starting certificate renewal daemon..."
/usr/local/bin/renew-certificates.sh daemon &
RENEWAL_PID=$!
echo "Certificate renewal daemon started with PID: $RENEWAL_PID"
echo "Starting CockroachDB..."

# Start CockroachDB with certificates
exec cockroach start-single-node \
  --certs-dir=/cockroach/certs \
  --listen-addr=0.0.0.0:26257 \
  --http-addr=0.0.0.0:8080 \
  --store=/cockroach/cockroach-data
