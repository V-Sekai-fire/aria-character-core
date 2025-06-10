#!/usr/bin/env bash

echo "🍎 Starting OpenBao on macOS..."

# Set SoftHSM environment for macOS
export SOFTHSM2_CONF="$HOME/.config/softhsm2/softhsm2.conf"

# Ensure directories exist
mkdir -p /opt/bao/{data,config,logs}
mkdir -p ~/.config/softhsm2/tokens

# Create OpenBao configuration for macOS
cat > /opt/bao/config/openbao.hcl << 'EOF'
# OpenBao configuration for macOS development with SoftHSM seal protection
storage "file" {
  path = "/opt/bao/data"
}

listener "tcp" {
  address = "localhost:8200"
  tls_disable = true
}

seal "pkcs11" {
  lib = "/opt/homebrew/lib/softhsm/libsofthsm2.so"
  slot = "0"
  pin = "1234"
  key_label = "openbao-seal-key"
  hmac_key_label = "openbao-seal-hmac-key"
  generate_key = "true"
}

api_addr = "http://localhost:8200"
cluster_addr = "http://localhost:8201"
ui = true
disable_mlock = true

log_level = "INFO"
log_file = "/opt/bao/logs/"
log_rotate_duration = "24h"
log_rotate_max_files = "30"
EOF

# Initialize SoftHSM token if needed
echo "🔑 Checking SoftHSM slot..."
softhsm2-util --init-token --slot 0 --label "openbao-token" --pin 1234 --so-pin 1234 2>/dev/null || true

# Start OpenBao in the background
echo "🚀 Starting OpenBao server..."
nohup bao server -config=/opt/bao/config/openbao.hcl > /opt/bao/logs/openbao.log 2>&1 &

# Wait a moment for startup
sleep 3

# Check if it's running
if pgrep -f "bao server" > /dev/null; then
    echo "✅ OpenBao started successfully!"
    echo "🌐 Web UI: http://localhost:8200"
    echo "📋 Logs: /opt/bao/logs/openbao.log"
else
    echo "❌ Failed to start OpenBao"
    echo "📋 Check logs: tail -f /opt/bao/logs/openbao.log"
    exit 1
fi
