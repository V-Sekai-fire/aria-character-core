#!/usr/bin/env bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -euo pipefail

# Production deployment script for Aria Character Core
# This replaces the docker-compose.yml functionality with native setup

ARIA_USER="aria"
ARIA_HOME="/opt/aria"
ARIA_APP_DIR="$ARIA_HOME/app"
ARIA_DATA_DIR="$ARIA_HOME/data"
ARIA_CONFIG_DIR="$ARIA_HOME/config"
ARIA_LOGS_DIR="$ARIA_HOME/logs"

echo "🚀 Setting up Aria Character Core for production deployment..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root for production setup"
   exit 1
fi

# Create aria user if it doesn't exist
if ! id "$ARIA_USER" &>/dev/null; then
    echo "👤 Creating aria user..."
    useradd --system --home "$ARIA_HOME" --shell /bin/bash --create-home "$ARIA_USER"
    usermod -aG sudo "$ARIA_USER"
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$ARIA_APP_DIR" "$ARIA_DATA_DIR"/{cockroach,openbao,seaweed/{master,volume,filer}} "$ARIA_CONFIG_DIR" "$ARIA_LOGS_DIR"
mkdir -p "$ARIA_HOME"/{.asdf,softhsm}

# Set ownership
chown -R "$ARIA_USER:$ARIA_USER" "$ARIA_HOME"

# Install system dependencies
echo "📦 Installing system dependencies..."
apt update
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libpcsc-lite-dev \
    autoconf \
    automake \
    libtool \
    softhsm2 \
    opensc \
    unzip \
    jq \
    postgresql-client \
    systemd \
    daemon

# Install asdf for the aria user
echo "🔧 Setting up asdf environment for aria user..."
sudo -u "$ARIA_USER" bash -c "
    cd '$ARIA_HOME'
    if [ ! -d '.asdf' ]; then
        git clone https://github.com/asdf-vm/asdf.git .asdf --branch v0.14.0
    fi
    export ASDF_DIR='$ARIA_HOME/.asdf'
    export PATH='$ARIA_HOME/.asdf/bin:\$PATH'
    source .asdf/asdf.sh
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true
"

# Copy application code
echo "📋 Copying application code..."
if [ -d "$(pwd)/apps" ]; then
    cp -r "$(pwd)"/* "$ARIA_APP_DIR/"
    chown -R "$ARIA_USER:$ARIA_USER" "$ARIA_APP_DIR"
fi

# Install Erlang/Elixir and compile application
echo "🔨 Installing Erlang/Elixir and compiling application..."
sudo -u "$ARIA_USER" bash -c "
    cd '$ARIA_APP_DIR'
    export ASDF_DIR='$ARIA_HOME/.asdf'
    export PATH='$ARIA_HOME/.asdf/bin:\$PATH'
    source '$ARIA_HOME/.asdf/asdf.sh'
    
    # Install versions from .tool-versions if it exists
    if [ -f '.tool-versions' ]; then
        asdf install
    fi
    
    # Install hex and rebar
    mix local.hex --force
    mix local.rebar --force
    
    # Get dependencies and compile
    export MIX_ENV=prod
    mix deps.get --only prod
    mix compile
"

# Install native services
echo "🗄️ Installing CockroachDB..."
if ! command -v cockroach >/dev/null 2>&1; then
    cd /tmp
    wget -O cockroach.tgz "https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/865aff1595e494c2ce95030c7a2f20c4370b5ff8/cockroach.tgz"
    tar -xzf cockroach.tgz
    cp cockroach /usr/local/bin/
    chmod +x /usr/local/bin/cockroach
    rm -f cockroach.tgz cockroach
fi

echo "🔐 Installing OpenBao..."
if ! command -v bao >/dev/null 2>&1; then
    cd /tmp
    wget -O bao-hsm_2.2.2_linux_amd64.deb \
        "https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb"
    dpkg -i bao-hsm_2.2.2_linux_amd64.deb || apt-get install -f -y
    rm -f bao-hsm_2.2.2_linux_amd64.deb
fi

echo "🌱 Installing SeaweedFS..."
if ! command -v weed >/dev/null 2>&1; then
    cd /tmp
    SEAWEEDFS_VERSION=$(curl -s https://api.github.com/repos/seaweedfs/seaweedfs/releases/latest | jq -r .tag_name)
    wget -O seaweedfs.tar.gz \
        "https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_amd64.tar.gz"
    tar -xzf seaweedfs.tar.gz
    cp weed /usr/local/bin/
    chmod +x /usr/local/bin/weed
    rm -f seaweedfs.tar.gz weed
fi

# Configure SoftHSM
echo "🔧 Configuring SoftHSM..."
tee /etc/softhsm2.conf > /dev/null << 'EOF'
# SoftHSM v2 configuration file
directories.tokendir = /opt/aria/softhsm/tokens
objectstore.backend = file
log.level = INFO
slots.removable = false
EOF

mkdir -p /opt/aria/softhsm/tokens
chown -R "$ARIA_USER:$ARIA_USER" /opt/aria/softhsm

# Initialize SoftHSM slot
sudo -u "$ARIA_USER" bash -c "
    export SOFTHSM2_CONF=/etc/softhsm2.conf
    if ! softhsm2-util --show-slots | grep -q 'Slot 0'; then
        softhsm2-util --init-token --slot 0 --label 'aria-token' --pin 1234 --so-pin 1234
    fi
"

# Create OpenBao configuration
echo "🔐 Creating OpenBao configuration..."
tee "$ARIA_CONFIG_DIR/openbao.hcl" > /dev/null << EOF
# OpenBao configuration for production with SoftHSM seal protection
storage "file" {
  path = "$ARIA_DATA_DIR/openbao"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

# HSM seal configuration using SoftHSM PKCS#11
seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  slot = "0"
  pin = "1234"
  key_label = "aria-seal-key"
  hmac_key_label = "aria-hmac-key"
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

chown "$ARIA_USER:$ARIA_USER" "$ARIA_CONFIG_DIR/openbao.hcl"

# Install systemd services
echo "⚙️ Installing systemd services..."
cp systemd/*.service systemd/*.target /etc/systemd/system/
systemctl daemon-reload

# Enable services
echo "✅ Enabling services..."
systemctl enable aria-cockroachdb.service
systemctl enable aria-openbao.service
systemctl enable aria-seaweedfs.service
systemctl enable aria-app.service
systemctl enable aria.target

echo "🎉 Production setup complete!"
echo ""
echo "To start all services:"
echo "  sudo systemctl start aria.target"
echo ""
echo "To check status:"
echo "  sudo systemctl status aria.target"
echo "  sudo systemctl status aria-app.service"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u aria-app.service -f"
echo ""
echo "Services will be available at:"
echo "  - Aria App: http://localhost:4000"
echo "  - OpenBao: http://localhost:8200"
echo "  - CockroachDB Admin: http://localhost:8080"
echo "  - SeaweedFS S3: http://localhost:8333"
