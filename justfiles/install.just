# Installation recipes for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# === Cross-Platform Dependency Installation ===

# Install all system dependencies
install-deps:
    #!/usr/bin/env bash
    echo "📦 Installing system dependencies for {{os()}}..."
    echo ""
    
    if [ "{{os()}}" = "macos" ]; then
        just _install-macos-deps
    elif [ "{{os()}}" = "linux" ]; then
        just _install-linux-deps
    else
        echo "❌ Unsupported operating system: {{os()}}"
        echo "   Supported: macOS, Linux"
        exit 1
    fi
    
    echo ""
    echo "📥 Installing service binaries..."
    just install-cockroach
    just install-openbao  
    just install-seaweedfs
    
    echo ""
    echo "💎 Installing Elixir dependencies..."
    just install-elixir-deps
    
    echo ""
    echo "✅ All dependencies installed successfully!"

# Install only Elixir/Mix dependencies
install-elixir-deps:
    #!/usr/bin/env bash
    echo "💎 Installing Elixir dependencies..."
    
    if ! command -v mix >/dev/null 2>&1; then
        echo "❌ Elixir/Mix not found. Please install Elixir first."
        echo "   Visit: https://elixir-lang.org/install.html"
        exit 1
    fi
    
    mix deps.get
    mix deps.compile
    mix ecto.create
    mix ecto.migrate
    echo "✅ Elixir dependencies installed!"

# === Service Binary Installation ===

# Install CockroachDB binary
install-cockroach:
    #!/usr/bin/env bash
    if command -v cockroach >/dev/null 2>&1; then
        echo "✅ CockroachDB already installed: $(cockroach version | head -1)"
        exit 0
    fi
    
    echo "🗄️  Installing CockroachDB..."
    
    if [ "{{os()}}" = "macos" ]; then
        # Use Homebrew on macOS
        if command -v brew >/dev/null 2>&1; then
            brew install cockroachdb/tap/cockroach
        else
            echo "❌ Homebrew required for macOS installation"
            exit 1
        fi
    elif [ "{{os()}}" = "linux" ]; then
        # Download from Oxide Computer build
        cd /tmp
        wget -q -O cockroach.tgz \
            "https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/865aff1595e494c2ce95030c7a2f20c4370b5ff8/cockroach.tgz"
        tar -xzf cockroach.tgz
        sudo cp cockroach/cockroach /usr/local/bin/
        sudo chmod +x /usr/local/bin/cockroach
        rm -rf cockroach cockroach.tgz
    fi
    
    echo "✅ CockroachDB installed: $(cockroach version | head -1)"

# Install OpenBao binary  
install-openbao:
    #!/usr/bin/env bash
    if command -v bao >/dev/null 2>&1; then
        echo "✅ OpenBao already installed: $(bao version | head -1)"
        exit 0
    fi
    
    echo "🔐 Installing OpenBao..."
    
    if [ "{{os()}}" = "macos" ]; then
        cd /tmp
        wget -q -O bao-hsm_2.2.2_darwin_amd64.zip \
            "https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_darwin_amd64.zip"
        unzip -q bao-hsm_2.2.2_darwin_amd64.zip
        sudo cp bao /usr/local/bin/
        sudo chmod +x /usr/local/bin/bao
        rm -f bao bao-hsm_2.2.2_darwin_amd64.zip
    elif [ "{{os()}}" = "linux" ]; then
        cd /tmp
        wget -q -O bao-hsm_2.2.2_linux_amd64.deb \
            "https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb"
        sudo dpkg -i bao-hsm_2.2.2_linux_amd64.deb || sudo apt-get install -f -y
        rm -f bao-hsm_2.2.2_linux_amd64.deb
    fi
    
    echo "✅ OpenBao installed: $(bao version | head -1)"

# Install SeaweedFS binary
install-seaweedfs:
    #!/usr/bin/env bash
    if command -v weed >/dev/null 2>&1; then
        echo "✅ SeaweedFS already installed: $(weed version 2>&1 | head -1)"
        exit 0
    fi
    
    echo "💾 Installing SeaweedFS..."
    
    if [ "{{os()}}" = "macos" ]; then
        ARCH="darwin_amd64"
    elif [ "{{os()}}" = "linux" ]; then
        ARCH="linux_amd64"
    fi
    
    cd /tmp
    wget -q -O seaweedfs.tar.gz \
        "https://github.com/seaweedfs/seaweedfs/releases/download/3.81/linux_amd64.tar.gz"
    tar -xzf seaweedfs.tar.gz
    sudo cp weed /usr/local/bin/
    sudo chmod +x /usr/local/bin/weed
    rm -f weed seaweedfs.tar.gz
    
    echo "✅ SeaweedFS installed: $(weed version 2>&1 | head -1)"

# === Private Helper Recipes ===

# Install macOS-specific dependencies
_install-macos-deps:
    #!/usr/bin/env bash
    if ! command -v brew >/dev/null 2>&1; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    brew install \
        curl wget git openssl pkg-config \
        autoconf automake libtool \
        softhsm opensc jq postgresql \
        coreutils unzip elixir
    
    echo "✅ macOS dependencies installed!"

# Install Linux-specific dependencies  
_install-linux-deps:
    #!/usr/bin/env bash
    sudo apt update
    sudo apt install -y \
        curl wget git build-essential \
        pkg-config libssl-dev libpcsc-lite-dev \
        autoconf automake libtool \
        softhsm2 opensc unzip jq \
        postgresql-client systemd daemon \
        erlang elixir
    
    echo "✅ Linux dependencies installed!"

# === Cleanup Recipes ===

# Remove all installed service binaries
uninstall-services:
    #!/usr/bin/env bash
    echo "🗑️  Removing service binaries..."
    
    sudo rm -f /usr/local/bin/cockroach
    sudo rm -f /usr/local/bin/bao  
    sudo rm -f /usr/local/bin/weed
    
    echo "✅ Service binaries removed!"

# Show installation status
show-install-status:
    #!/usr/bin/env bash
    echo "📋 Installation Status"
    echo "═══════════════════════"
    echo ""
    
    echo "🗄️  CockroachDB: $(command -v cockroach >/dev/null 2>&1 && echo '✅ INSTALLED' || echo '❌ NOT FOUND')"
    if command -v cockroach >/dev/null 2>&1; then
        echo "   Version: $(cockroach version | head -1)"
    fi
    echo ""
    
    echo "🔐 OpenBao: $(command -v bao >/dev/null 2>&1 && echo '✅ INSTALLED' || echo '❌ NOT FOUND')"
    if command -v bao >/dev/null 2>&1; then
        echo "   Version: $(bao version | head -1)"
    fi
    echo ""
    
    echo "💾 SeaweedFS: $(command -v weed >/dev/null 2>&1 && echo '✅ INSTALLED' || echo '❌ NOT FOUND')"
    if command -v weed >/dev/null 2>&1; then
        echo "   Version: $(weed version 2>&1 | head -1)"
    fi
    echo ""
    
    echo "💎 Elixir: $(command -v elixir >/dev/null 2>&1 && echo '✅ INSTALLED' || echo '❌ NOT FOUND')"
    if command -v elixir >/dev/null 2>&1; then
        echo "   Version: $(elixir --version | grep Elixir)"
    fi
