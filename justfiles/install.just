# Installation recipes for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Cross-platform dependency installation for macOS and Linux
install-deps:
    #!/usr/bin/env bash
    if [ "{{os()}}" = "macos" ]; then
        echo "📦 Installing dependencies for macOS..."
        if ! command -v brew >/dev/null 2>&1; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew update
        brew install \
            curl \
            wget \
            git \
            openssl \
            pkg-config \
            autoconf \
            automake \
            libtool \
            softhsm \
            opensc \
            jq \
            postgresql \
            coreutils \
            unzip
        echo "✅ macOS dependencies installed!"
    elif [ "{{os()}}" = "linux" ]; then
        echo "📦 Installing Ubuntu dependencies for native setup..."
        sudo apt update
        sudo apt install -y \
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
        echo "✅ Ubuntu dependencies installed!"
    else
        echo "❌ Unsupported OS: {{os()}}"
        exit 1
    fi

install-cockroach:
    #!/usr/bin/env bash
    if [ "{{os()}}" = "macos" ]; then
        echo "🗄️  Installing CockroachDB natively on macOS..."
        if command -v cockroach >/dev/null 2>&1; then
            echo "✅ CockroachDB already installed"
            cockroach version
            exit 0
        fi
        echo "📥 Downloading CockroachDB for macOS..."
        cd /tmp
        ARCH=$(uname -m)
        if [ "$ARCH" = "arm64" ]; then
            URL="https://binaries.cockroachdb.com/cockroach-v23.1.11.darwin-arm64.tgz"
            DIR="cockroach-v23.1.11.darwin-arm64"
        else
            URL="https://binaries.cockroachdb.com/cockroach-v23.1.11.darwin-amd64.tgz"
            DIR="cockroach-v23.1.11.darwin-amd64"
        fi
        curl -L -o cockroach.tgz "$URL"
        tar -xzf cockroach.tgz
        sudo cp "$DIR/cockroach" /usr/local/bin/
        sudo chmod +x /usr/local/bin/cockroach
        rm -rf "$DIR" cockroach.tgz
        echo "✅ CockroachDB installed!"
        cockroach version
    elif [ "{{os()}}" = "linux" ]; then
        echo "🗄️  Installing CockroachDB natively on Linux..."
        if command -v cockroach >/dev/null 2>&1; then
            echo "✅ CockroachDB already installed"
            cockroach version
            exit 0
        fi
        echo "📥 Downloading CockroachDB from Oxide Computer..."
        cd /tmp
        wget -O cockroach.tgz "https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/865aff1595e494c2ce95030c7a2f20c4370b5ff8/cockroach.tgz"
        tar -xzf cockroach.tgz
        sudo cp cockroach/cockroach /usr/local/bin/
        sudo chmod +x /usr/local/bin/cockroach
        rm -rf cockroach cockroach.tgz
        echo "✅ CockroachDB installed!"
        cockroach version
    else
        echo "❌ Unsupported OS: {{os()}}"
        exit 1
    fi

install-openbao:
    #!/usr/bin/env bash
    echo "🔐 Installing OpenBao..."
    
    if command -v bao >/dev/null 2>&1; then
        echo "✅ OpenBao is already installed"
        bao version
        exit 0
    fi
    
    if [ "{{os()}}" = "macos" ]; then
        echo "🍎 Installing OpenBao for macOS..."
        
        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "arm64" ]; then
            OPENBAO_ARCH="arm64"
        elif [ "$ARCH" = "x86_64" ]; then
            OPENBAO_ARCH="x86_64"
        else
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
        fi
        
        OPENBAO_VERSION="2.2.2"
        DOWNLOAD_URL="https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/bao_${OPENBAO_VERSION}_Darwin_${OPENBAO_ARCH}.tar.gz"
        
        echo "📥 Downloading OpenBao v${OPENBAO_VERSION} for Darwin ${OPENBAO_ARCH}..."
        cd /tmp
        
        # Download the binary
        curl -L -o "openbao.tar.gz" "$DOWNLOAD_URL"
        
        # Extract the binary
        tar -xzf openbao.tar.gz
        
        # Install to /usr/local/bin
        sudo cp bao /usr/local/bin/
        sudo chmod +x /usr/local/bin/bao
        
        # Create necessary directories
        sudo mkdir -p /opt/bao/{data,config,logs}
        sudo mkdir -p /var/lib/softhsm/tokens
        
        # Set proper ownership (use current user since we're on macOS)
        current_user=$(whoami)
        sudo chown -R "$current_user:staff" /opt/bao /var/lib/softhsm
        
        # Clean up
        rm -f openbao.tar.gz bao
        
        echo "✅ OpenBao installed successfully!"
        bao version
        
    elif [ "{{os()}}" = "linux" ]; then
        echo "🐧 Installing OpenBao for Linux..."
        cd /tmp
        wget -O bao-hsm_2.2.2_linux_amd64.deb \
            "https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb"
        sudo dpkg -i bao-hsm_2.2.2_linux_amd64.deb || sudo apt-get install -f -y
        rm -f bao-hsm_2.2.2_linux_amd64.deb
        
        echo "✅ OpenBao installed successfully!"
        bao version
        
    else
        echo "❌ Unsupported operating system: {{os()}}"
        echo "   OpenBao installation only supported on Linux and macOS"
        exit 1
    fi

install-seaweedfs:
    #!/usr/bin/env bash
    if [ "{{os()}}" = "linux" ]; then
        echo "🌱 Installing SeaweedFS natively..."
        
        if command -v weed >/dev/null 2>&1; then
            echo "✅ SeaweedFS already installed"
            weed version
            exit 0
        fi
        
        # Download SeaweedFS
        echo "📥 Downloading SeaweedFS..."
        cd /tmp
        
        # Get the latest version
        SEAWEEDFS_VERSION=$(curl -s https://api.github.com/repos/seaweedfs/seaweedfs/releases/latest | jq -r .tag_name)
        echo "📦 Downloading SeaweedFS $SEAWEEDFS_VERSION..."
        
        wget -O seaweedfs.tar.gz \
            "https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_amd64.tar.gz"
        
        # Extract and install
        tar -xzf seaweedfs.tar.gz
        sudo cp weed /usr/local/bin/
        sudo chmod +x /usr/local/bin/weed
        
        # Create seaweedfs user and directories
        sudo useradd --system --home /var/lib/seaweedfs --shell /bin/false seaweedfs || true
        sudo mkdir -p /var/lib/seaweedfs/{master,volume,filer,s3} /var/log/seaweedfs
        sudo chown -R seaweedfs:seaweedfs /var/lib/seaweedfs /var/log/seaweedfs
        
        # Clean up
        rm -f seaweedfs.tar.gz weed
        
        echo "✅ SeaweedFS installed!"
        weed version
    else
        echo "⚠️  SeaweedFS installation only supported on Linux"
        echo "   On macOS, consider using Docker or alternative solutions"
        exit 1
    fi

install-softhsm:
    #!/usr/bin/env bash
    echo "🔧 Installing SoftHSM..."
    
    if [ "{{os()}}" = "macos" ]; then
        echo "🍎 Installing SoftHSM for macOS..."
        
        # Check if Homebrew is installed
        if ! command -v brew >/dev/null 2>&1; then
            echo "❌ Homebrew is required but not installed"
            echo "   Please install Homebrew first: https://brew.sh"
            exit 1
        fi
        
        # Install SoftHSM using Homebrew
        echo "📥 Installing SoftHSM via Homebrew..."
        brew install softhsm
        
        # Create SoftHSM configuration directory and file
        mkdir -p ~/.config/softhsm2
        echo "# SoftHSM v2 configuration file for macOS" > ~/.config/softhsm2/softhsm2.conf
        echo "directories.tokendir = $HOME/.config/softhsm2/tokens" >> ~/.config/softhsm2/softhsm2.conf
        echo "objectstore.backend = file" >> ~/.config/softhsm2/softhsm2.conf
        echo "log.level = INFO" >> ~/.config/softhsm2/softhsm2.conf
        echo "slots.removable = false" >> ~/.config/softhsm2/softhsm2.conf
        
        # Create tokens directory
        mkdir -p ~/.config/softhsm2/tokens
        
        # Set environment variable
        export SOFTHSM2_CONF="$HOME/.config/softhsm2/softhsm2.conf"
        
        echo "✅ SoftHSM installed and configured for macOS!"
        echo "🔧 Configuration file: ~/.config/softhsm2/softhsm2.conf"
        echo "🗂️  Tokens directory: ~/.config/softhsm2/tokens"
        echo ""
        echo "📝 To use SoftHSM, export this environment variable:"
        echo "   export SOFTHSM2_CONF=\"$HOME/.config/softhsm2/softhsm2.conf\""
        
    elif [ "{{os()}}" = "linux" ]; then
        echo "🐧 Installing SoftHSM for Linux..."
        sudo apt-get update
        sudo apt-get install -y softhsm2
        
        # Create configuration
        sudo mkdir -p /var/lib/softhsm/tokens
        sudo sh -c 'echo "# SoftHSM v2 configuration file" > /etc/softhsm2.conf'
        sudo sh -c 'echo "directories.tokendir = /var/lib/softhsm/tokens" >> /etc/softhsm2.conf'
        sudo sh -c 'echo "objectstore.backend = file" >> /etc/softhsm2.conf'
        sudo sh -c 'echo "log.level = INFO" >> /etc/softhsm2.conf'
        sudo sh -c 'echo "slots.removable = false" >> /etc/softhsm2.conf'
        
        echo "✅ SoftHSM installed and configured for Linux!"
        
    else
        echo "❌ Unsupported operating system: {{os()}}"
        echo "   SoftHSM installation only supported on Linux and macOS"
        exit 1
    fi

install-elixir-erlang-env:
    ./scripts/install-elixir-erlang.sh
