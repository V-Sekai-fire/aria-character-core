# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Default recipe - main entry point for development workflow
default: dev-setup
    @echo "Development environment ready! Available commands:"
    @echo ""
    @echo "Main Workflows:"
    @echo "  just dev-setup        - Set up development environment"
    @echo "  just full-dev-setup   - Complete development setup including environment"
    @echo "  just test-all         - Run all tests"
    @echo "  just prod-deploy      - Deploy production environment"
    @echo ""
    @echo "Status & Monitoring:"
    @echo "  just status           - Check foundation service status"
    @echo "  just extended-status  - Extended status including all services"
    @echo "  just logs             - View service logs"
    @echo ""
    @echo "Management:"
    @echo "  just setup-env        - Set up Elixir/Erlang environment"
    @echo "  just manage-tokens    - Generate new OpenBao tokens"
    @echo "  just destroy-bao      - Destroy and reinitialize OpenBao and SoftHSM (DESTRUCTIVE)"
    @echo "  just rekey-bao        - Rekey OpenBao unseal keys and optionally SoftHSM"
    @echo "  just rekey-softhsm    - Regenerate SoftHSM tokens (DESTRUCTIVE)"
    @echo "  just clean            - Clean up all services"
    @echo ""
    @echo "Low-level:"
    @echo "  just foundation-startup    - Start foundation services only"
    @echo "  just up-all-and-check     - Start and verify all services"

# Development workflow entry point
dev-setup: install-ubuntu-deps install-elixir-erlang-env foundation-startup
    @echo "Development environment setup complete!"

# Testing workflow entry point  
test-all: test-elixir-compile test-elixir-unit test-openbao-connection test-basic-secrets
    @echo "All tests completed!"

# Production deployment workflow
prod-deploy: up-all-and-check
    @echo "Production deployment complete!"

# Status check workflow
status: foundation-status
    @echo "Status check complete!"

# Clean up workflow
clean: stop-all-services
    @echo "Cleanup complete!"

# Install Ubuntu dependencies for native setup
install-ubuntu-deps:
    #!/usr/bin/env bash
    echo "📦 Installing Ubuntu dependencies for native setup..."
    
    # Update package lists
    sudo apt update
    
    # Install essential packages
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

# Download and install CockroachDB natively
install-cockroach:
    #!/usr/bin/env bash
    echo "🗄️  Installing CockroachDB natively..."
    
    if command -v cockroach >/dev/null 2>&1; then
        echo "✅ CockroachDB already installed"
        cockroach version
        exit 0
    fi
    
    # Download CockroachDB from Oxide Computer
    echo "📥 Downloading CockroachDB from Oxide Computer..."
    cd /tmp
    wget -O cockroach.tgz "https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/865aff1595e494c2ce95030c7a2f20c4370b5ff8/cockroach.tgz"
    
    # Extract and install (one layer)
    tar -xzf cockroach.tgz
    sudo cp cockroach/cockroach /usr/local/bin/
    sudo chmod +x /usr/local/bin/cockroach

    # Create cockroach user and directories
    sudo useradd --system --home /var/lib/cockroach --shell /bin/false cockroach || true
    sudo mkdir -p /var/lib/cockroach /var/log/cockroach
    sudo chown cockroach:cockroach /var/lib/cockroach /var/log/cockroach

    # Clean up
    rm -rf cockroach cockroach.tgz

    echo "✅ CockroachDB installed!"
    cockroach version

# Download and install OpenBao HSM natively
install-openbao:
    #!/usr/bin/env bash
    echo "🔐 Installing OpenBao HSM natively..."
    
    if command -v bao >/dev/null 2>&1; then
        echo "✅ OpenBao already installed"
        bao version
        exit 0
    fi
    
    # Check if the .deb file already exists
    if [ -f bao-hsm_2.2.2_linux_amd64.deb ]; then
        echo "📦 Using existing OpenBao .deb file..."
    else
        echo "📥 Downloading OpenBao HSM..."
        wget -O bao-hsm_2.2.2_linux_amd64.deb \
            "https://github.com/openbao/openbao/releases/download/v2.2.2/bao-hsm_2.2.2_linux_amd64.deb"
    fi
    
    # Install the .deb package
    sudo dpkg -i bao-hsm_2.2.2_linux_amd64.deb || sudo apt-get install -f -y
    
    # Create bao user and directories
    sudo useradd --system --home /opt/bao --shell /bin/false bao || true
    sudo mkdir -p /opt/bao/data /opt/bao/config /opt/bao/logs /var/lib/softhsm/tokens
    sudo chown -R bao:bao /opt/bao /var/lib/softhsm
    
    echo "✅ OpenBao HSM installed!"
    bao version

# Download and install SeaweedFS natively
install-seaweedfs:
    #!/usr/bin/env bash
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

# Configure SoftHSM for OpenBao
configure-softhsm:
    #!/usr/bin/env bash
    echo "🔧 Configuring SoftHSM for OpenBao..."
    
    # Create SoftHSM configuration
    sudo sh -c 'echo "# SoftHSM v2 configuration file" > /etc/softhsm2.conf'
    sudo sh -c 'echo "directories.tokendir = /var/lib/softhsm/tokens" >> /etc/softhsm2.conf'
    sudo sh -c 'echo "objectstore.backend = file" >> /etc/softhsm2.conf'
    sudo sh -c 'echo "log.level = INFO" >> /etc/softhsm2.conf'
    sudo sh -c 'echo "slots.removable = false" >> /etc/softhsm2.conf'
    
    # Set environment variable for SoftHSM config
    export SOFTHSM2_CONF=/etc/softhsm2.conf
    
    # Initialize SoftHSM slot if it doesn't exist
    if ! softhsm2-util --show-slots | grep -q "Slot 0"; then
        echo "🔑 Initializing SoftHSM slot 0..."
        softhsm2-util --init-token --slot 0 --label "openbao-token" --pin 1234 --so-pin 1234
    else
        echo "✅ SoftHSM slot 0 already initialized"
    fi
    
    echo "✅ SoftHSM configured successfully!"

# Initialize SoftHSM using Elixir module for better integration
init-softhsm-elixir: install-elixir-erlang-env configure-softhsm
    #!/usr/bin/env bash
    echo "🔧 Initializing SoftHSM using AriaSecurity.SoftHSM module..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    # Set SoftHSM environment
    export SOFTHSM2_CONF=/etc/softhsm2.conf
    export MIX_ENV=dev
    
    # Use Elixir module to initialize SoftHSM
    echo "🔑 Using AriaSecurity.SoftHSM to initialize token..."
    
    mix run -e '
    config = %{
      slot_id: 0,
      token_label: "openbao-token", 
      user_pin: "1234",
      so_pin: "1234"
    }
    
    case AriaSecurity.SoftHSM.initialize_token(config) do
      {:ok, _} -> 
        IO.puts("✅ SoftHSM token initialized successfully via Elixir module")
        
        # List slots to verify
        case AriaSecurity.SoftHSM.list_slots(config) do
          {:ok, slots} -> 
            IO.puts("📋 Available slots:")
            IO.inspect(slots)
          {:error, reason} -> 
            IO.puts("⚠️  Could not list slots: #{inspect(reason)}")
        end
        
      {:error, reason} -> 
        IO.puts("❌ Failed to initialize SoftHSM token: #{inspect(reason)}")
        System.halt(1)
    end
    '
    
    echo "✅ SoftHSM initialized via Elixir module!"

# Start CockroachDB natively
start-cockroach: install-cockroach
    #!/usr/bin/env bash
    echo "🗄️  Starting CockroachDB..."
    
    # Check if CockroachDB is already running
    if pgrep -f "cockroach start" > /dev/null; then
        echo "✅ CockroachDB is already running"
        exit 0
    fi
    
    # Create data directory
    sudo mkdir -p /var/lib/cockroach/data
    sudo chown cockroach:cockroach /var/lib/cockroach/data
    
    # Start CockroachDB in the background
    echo "🚀 Starting CockroachDB in single-node mode..."
    sudo -u cockroach nohup cockroach start-single-node \
        --insecure \
        --store=/var/lib/cockroach/data \
        --listen-addr=localhost:26257 \
        --http-addr=localhost:8080 \
        --background \
        --log-config-file=""
    
    # Wait for CockroachDB to be ready
    echo "⏳ Waiting for CockroachDB to be ready..."
    timeout 30s bash -c 'until curl -sf http://localhost:8080/health >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ CockroachDB failed to start" && exit 1)
    
    echo "✅ CockroachDB started successfully!"

# Start OpenBao natively
start-openbao: install-openbao init-softhsm-elixir
    #!/usr/bin/env bash
    echo "🔐 Starting OpenBao with SoftHSM..."
    
    # Check if OpenBao is already running
    if pgrep -f "bao server" > /dev/null; then
        echo "✅ OpenBao is already running"
        exit 0
    fi
    
    # Set environment variables
    export SOFTHSM2_CONF=/etc/softhsm2.conf
    export OPENBAO_PKCS11_PIN=${OPENBAO_PKCS11_PIN:-1234}
    export OPENBAO_PKCS11_SO_PIN=${OPENBAO_PKCS11_SO_PIN:-1234}
    export OPENBAO_PKCS11_SLOT=${OPENBAO_PKCS11_SLOT:-0}
    
    # Create OpenBao configuration
    sudo mkdir -p /opt/bao/config
    sudo sh -c 'echo "# OpenBao configuration for production with SoftHSM seal protection" > /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "storage \"file\" {" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  path = \"/opt/bao/data\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "}" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "listener \"tcp\" {" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  address = \"0.0.0.0:8200\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  tls_disable = 1" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "}" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# HSM seal configuration using SoftHSM PKCS#11" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "seal \"pkcs11\" {" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  lib = \"/usr/lib/softhsm/libsofthsm2.so\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  slot = \"${OPENBAO_PKCS11_SLOT}\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  pin = \"${OPENBAO_PKCS11_PIN}\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  key_label = \"openbao-seal-key\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  hmac_key_label = \"openbao-hmac-key\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "  generate_key = \"true\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "}" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# API address" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "api_addr = \"http://0.0.0.0:8200\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# Cluster address" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "cluster_addr = \"http://0.0.0.0:8201\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# UI enabled" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "ui = true" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# Logging" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "log_level = \"Info\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# Disable mlock for development" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "disable_mlock = true" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# Default lease TTL" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "default_lease_ttl = \"168h\"" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "# Maximum lease TTL" >> /opt/bao/config/openbao.hcl'
    sudo sh -c 'echo "max_lease_ttl = \"720h\"" >> /opt/bao/config/openbao.hcl'
    
    sudo chown bao:bao /opt/bao/config/openbao.hcl
    
    # Start OpenBao in the background
    echo "🚀 Starting OpenBao with PKCS#11 seal..."
    sudo -u bao nohup bao server -config=/opt/bao/config/openbao.hcl > /opt/bao/logs/openbao.log 2>&1 &
    
    # Wait for OpenBao to be ready
    echo "⏳ Waiting for OpenBao to be ready..."
    timeout 30s bash -c 'until curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ OpenBao failed to start" && exit 1)
    
    echo "✅ OpenBao started successfully!"

# Start SeaweedFS natively
start-seaweedfs: install-seaweedfs
    #!/usr/bin/env bash
    echo "🌱 Starting SeaweedFS..."
    
    # Check if SeaweedFS is already running
    if pgrep -f "weed" > /dev/null; then
        echo "✅ SeaweedFS is already running"
        exit 0
    fi
    
    # Start SeaweedFS master
    echo "🚀 Starting SeaweedFS master..."
    sudo -u seaweedfs nohup weed master \
        -dir=/var/lib/seaweedfs/master \
        -port=9333 \
        > /var/log/seaweedfs/master.log 2>&1 &
    
    # Start SeaweedFS volume server
    echo "🚀 Starting SeaweedFS volume server..."
    sudo -u seaweedfs nohup weed volume \
        -dir=/var/lib/seaweedfs/volume \
        -port=8080 \
        -mserver=localhost:9333 \
        > /var/log/seaweedfs/volume.log 2>&1 &
    
    # Start SeaweedFS filer
    echo "🚀 Starting SeaweedFS filer..."
    sudo -u seaweedfs nohup weed filer \
        -dir=/var/lib/seaweedfs/filer \
        -port=8888 \
        -master=localhost:9333 \
        > /var/log/seaweedfs/filer.log 2>&1 &
    
    # Start SeaweedFS S3 gateway
    echo "🚀 Starting SeaweedFS S3 gateway..."
    sudo -u seaweedfs nohup weed s3 \
        -dir=/var/lib/seaweedfs/s3 \
        -port=8333 \
        -filer=localhost:8888 \
        > /var/log/seaweedfs/s3.log 2>&1 &
    
    # Wait for S3 gateway to be ready
    echo "⏳ Waiting for SeaweedFS S3 gateway to be ready..."
    timeout 30s bash -c 'until curl -sf http://localhost:8333 >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ SeaweedFS S3 gateway failed to start" && exit 1)
    
    echo "✅ SeaweedFS started successfully!"

# Start Elixir application
start-elixir-app: install-elixir-erlang-env
    #!/usr/bin/env bash
    echo "🚀 Starting Elixir application..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    # Set environment variables for production
    export MIX_ENV=prod
    export PHX_SERVER=true
    export DATABASE_URL="postgresql://root@localhost:26257/aria_character_core?sslmode=disable"
    export VAULT_ADDR="http://localhost:8200"
    
    # Get dependencies and compile
    echo "📦 Getting dependencies..."
    mix deps.get --only prod
    
    echo "🔨 Compiling application..."
    mix compile
    
    # Run database migrations
    echo "🗄️  Running database migrations..."
    mix ecto.create || true
    mix ecto.migrate
    
    # Start the application in the background
    echo "🚀 Starting Phoenix application..."
    nohup mix phx.server > aria_app.log 2>&1 &
    
    # Wait for the application to be ready
    echo "⏳ Waiting for Aria App to be ready..."
    timeout 60s bash -c 'until curl -sf http://localhost:4000/health >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ Aria App failed to start" && exit 1)
    
    echo "✅ Elixir application started successfully!"

# Stop all native services
stop-all-services:
    #!/usr/bin/env bash
    echo "🛑 Stopping all native services..."
    
    echo "Stopping Elixir application..."
    pkill -f "mix phx.server" 2>/dev/null || true
    
    echo "Stopping SeaweedFS services..."
    pkill -f "weed s3" 2>/dev/null || true
    pkill -f "weed filer" 2>/dev/null || true
    pkill -f "weed volume" 2>/dev/null || true
    pkill -f "weed master" 2>/dev/null || true
    
    echo "Stopping OpenBao..."
    pkill -f "bao server" 2>/dev/null || true
    
    echo "Stopping CockroachDB..."
    pkill -f "cockroach start" 2>/dev/null || true
    
    echo "✅ All native services stopped!"

# === PRODUCTION SYSTEMD SERVICE MANAGEMENT ===

# Setup production environment with systemd services
setup-production:
    #!/usr/bin/env bash
    echo "🚀 Setting up production environment with systemd services..."
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run with sudo for production setup"
        exit 1
    fi
    ./scripts/setup-production.sh

# Start all services via systemd
start-production:
    #!/usr/bin/env bash
    echo "🚀 Starting all Aria services via systemd..."
    sudo systemctl start aria.target
    echo "✅ All services started! Use 'just status-production' to check status"

# Stop all services via systemd  
stop-production:
    #!/usr/bin/env bash
    echo "🛑 Stopping all Aria services via systemd..."
    sudo systemctl stop aria.target
    echo "✅ All services stopped!"

# Check production service status
status-production:
    #!/usr/bin/env bash
    echo "📊 Checking production service status..."
    echo ""
    echo "=== Aria Stack Status ==="
    sudo systemctl status aria.target --no-pager -l
    echo ""
    echo "=== Individual Services ==="
    for service in aria-cockroachdb aria-openbao aria-seaweedfs aria-app; do
        echo "--- $service ---"
        sudo systemctl status $service.service --no-pager -l | head -10
        echo ""
    done

# View production logs
logs-production:
    #!/usr/bin/env bash
    echo "📋 Viewing Aria application logs..."
    sudo journalctl -u aria-app.service -f

# View all production logs
logs-all-production:
    #!/usr/bin/env bash
    echo "📋 Viewing all Aria service logs..."
    sudo journalctl -u aria-cockroachdb.service -u aria-openbao.service -u aria-seaweedfs.service -u aria-app.service -f

# Restart production services
restart-production:
    #!/usr/bin/env bash
    echo "🔄 Restarting all Aria services..."
    sudo systemctl restart aria.target
    echo "✅ All services restarted!"

# Enable services to start on boot
enable-production:
    #!/usr/bin/env bash
    echo "⚡ Enabling services to start on boot..."
    sudo systemctl enable aria.target
    echo "✅ Services will start automatically on boot"

# Disable services from starting on boot
disable-production:
    #!/usr/bin/env bash
    echo "⚡ Disabling services from starting on boot..."
    sudo systemctl disable aria.target
    echo "✅ Services will not start automatically on boot"

# Show status of all native services
show-services-status:
    #!/usr/bin/env bash
    echo "📊 Native Services Status:"
    echo ""
    echo "CockroachDB: $(pgrep -f 'cockroach start' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "OpenBao: $(pgrep -f 'bao server' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "SeaweedFS Master: $(pgrep -f 'weed master' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "SeaweedFS Volume: $(pgrep -f 'weed volume' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "SeaweedFS Filer: $(pgrep -f 'weed filer' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "SeaweedFS S3: $(pgrep -f 'weed s3' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo "Elixir App: $(pgrep -f 'mix phx.server' >/dev/null && echo '✅ RUNNING' || echo '❌ STOPPED')"
    echo ""
    echo "🔍 Health Check Results:"
    echo "CockroachDB Health: $(curl -sf http://localhost:8080/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "OpenBao Health: $(curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "SeaweedFS S3 Health: $(curl -sf http://localhost:8333 >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "Elixir App Health: $(curl -sf http://localhost:4000/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"

# Show logs for all native services
show-all-logs:
    #!/usr/bin/env bash
    echo "📋 Native Services Logs:"
    echo ""
    echo "=== CockroachDB Logs ==="
    tail -30 /var/log/cockroach/cockroach.log 2>/dev/null || echo "No CockroachDB logs available"
    echo ""
    echo "=== OpenBao Logs ==="
    tail -30 /opt/bao/logs/openbao.log 2>/dev/null || echo "No OpenBao logs available"
    echo ""
    echo "=== SeaweedFS Master Logs ==="
    tail -30 /var/log/seaweedfs/master.log 2>/dev/null || echo "No SeaweedFS master logs available"
    echo ""
    echo "=== SeaweedFS S3 Logs ==="
    tail -30 /var/log/seaweedfs/s3.log 2>/dev/null || echo "No SeaweedFS S3 logs available"
    echo ""
    echo "=== Elixir Application Logs ==="
    tail -30 aria_app.log 2>/dev/null || echo "No Elixir app logs available"

# Check health of foundation core services
check-foundation-core-health: start-foundation-core
    #!/usr/bin/env bash
    echo "Waiting for foundation core services to initialize (initial 5-second delay)..."
    sleep 5
    echo "Checking current status of foundation services..."
    echo "--- Foundation Services Status ---"
    echo "CockroachDB: $(pgrep -f 'cockroach start' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "OpenBao: $(pgrep -f 'bao server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "Elixir App: $(pgrep -f 'mix phx.server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    
    echo "--- Recent logs (CockroachDB) ---"
    tail -20 /var/log/cockroach/cockroach.log 2>/dev/null || echo "No CockroachDB logs available"
    
    echo "--- Recent logs (OpenBao) ---"
    tail -20 /opt/bao/logs/openbao.log 2>/dev/null || echo "No OpenBao logs available"
    
    echo "--- Recent logs (Elixir App) ---"
    tail -20 aria_app.log 2>/dev/null || echo "No Elixir app logs available"
    
    echo "Checking Aria App health..."
    curl -sf http://localhost:4000/health > /dev/null && echo "Aria App is healthy" || (echo "Error: Aria App health check failed." && exit 1)
    echo "Checking OpenBao health..."
    curl -sf http://localhost:8200/v1/sys/health > /dev/null && echo "OpenBao is healthy" || (echo "Error: OpenBao health check failed." && exit 1)
    echo "Checking CockroachDB health..."
    curl -sf http://localhost:8080/health > /dev/null && echo "CockroachDB is healthy" || (echo "Error: CockroachDB health check failed." && exit 1)
    echo "OpenBao and CockroachDB health checks passed."

# Foundation startup: build, start, and check health
foundation-startup: start-foundation-core check-foundation-core-health
    @echo "Foundation startup completed."

# Start foundation core services natively
start-foundation-core: start-cockroach start-openbao start-elixir-app
    @echo "Foundation core services started."

foundation-status: foundation-startup
    #!/usr/bin/env bash
    echo "Status of core foundation services:"
    echo "CockroachDB: $(pgrep -f 'cockroach start' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "OpenBao: $(pgrep -f 'bao server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "Elixir App: $(pgrep -f 'mix phx.server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"

foundation-logs: foundation-startup
    #!/usr/bin/env bash
    echo "Showing recent logs for foundation services..."
    echo "--- CockroachDB logs ---"
    tail -50 /var/log/cockroach/cockroach.log 2>/dev/null || echo "No CockroachDB logs available"
    echo ""
    echo "--- OpenBao logs ---"
    tail -50 /opt/bao/logs/openbao.log 2>/dev/null || echo "No OpenBao logs available"
    echo ""
    echo "--- Elixir App logs ---"
    tail -50 aria_app.log 2>/dev/null || echo "No Elixir app logs available"

foundation-stop:
    #!/usr/bin/env bash
    echo "Stopping core foundation services..."
    pkill -f "mix phx.server" 2>/dev/null || true
    pkill -f "bao server" 2>/dev/null || true
    pkill -f "cockroach start" 2>/dev/null || true
    echo "Core foundation services stopped."

# Start all services natively
start-all: start-cockroach start-openbao start-seaweedfs start-elixir-app
    @echo "All services started natively."

# Check health of all services
check-all-health: up-all-and-check
    #!/usr/bin/env bash
    echo "Checking health of all running services..."
    echo "This might take some time. Services are checked based on their native status."
    echo ""
    echo "Service Status:"
    echo "CockroachDB: $(pgrep -f 'cockroach start' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "OpenBao: $(pgrep -f 'bao server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "SeaweedFS Master: $(pgrep -f 'weed master' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "SeaweedFS Volume: $(pgrep -f 'weed volume' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "SeaweedFS Filer: $(pgrep -f 'weed filer' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "SeaweedFS S3: $(pgrep -f 'weed s3' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "Elixir App: $(pgrep -f 'mix phx.server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo ""
    echo "Health Check Results:"
    echo "CockroachDB Health: $(curl -sf http://localhost:8080/health >/dev/null 2>&1 && echo 'HEALTHY' || echo 'UNHEALTHY')"
    echo "OpenBao Health: $(curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1 && echo 'HEALTHY' || echo 'UNHEALTHY')"
    echo "SeaweedFS S3 Health: $(curl -sf http://localhost:8333 >/dev/null 2>&1 && echo 'HEALTHY' || echo 'UNHEALTHY')"
    echo "Elixir App Health: $(curl -sf http://localhost:4000/health >/dev/null 2>&1 && echo 'HEALTHY' || echo 'UNHEALTHY')"

up-all-and-check: start-all check-foundation-core-health
    #!/usr/bin/env bash
    echo "Waiting for all services to initialize (90 seconds)..."
    sleep 90
    echo "--- Current status of all native services: ---"
    echo "CockroachDB: $(pgrep -f 'cockroach start' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "OpenBao: $(pgrep -f 'bao server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "SeaweedFS: $(pgrep -f 'weed' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "Elixir App: $(pgrep -f 'mix phx.server' >/dev/null && echo 'RUNNING' || echo 'STOPPED')"
    echo "--- Performing basic health checks for key services (OpenBao, CockroachDB, SeaweedFS S3) ---"
    just check-foundation-core-health
    echo "Checking SeaweedFS S3 gateway health..."
    timeout 60s bash -c \
      'until curl -sf http://localhost:8333 >/dev/null 2>&1; do \
        echo "Waiting for SeaweedFS S3 gateway to be healthy..."; \
        sleep 5; \
      done || (echo "Error: SeaweedFS S3 gateway health check failed or timed out." && exit 1)'
    echo "SeaweedFS S3 gateway is responding."
    echo "All key services checked. Review logs if any issues."

# Environment setup and management
setup-env: install-elixir-erlang-env
    @echo "Environment setup complete!"

# Token management workflow
manage-tokens: generate-new-root-token
    @echo "Token management complete!"

# Complete development workflow
full-dev-setup: setup-env dev-setup
    @echo "Full development setup complete!"

# Logs workflow
logs: foundation-logs
    @echo "Logs displayed!"

# Extended status workflow
extended-status: status check-all-health
    @echo "Extended status check complete!"

install-elixir-erlang-env:
    #!/usr/bin/env bash
    echo "Installing asdf in the project root..."
    
    # Ensure we're in the project directory (just sets cwd to the justfile directory)
    cd "$(dirname "$0")" || exit 1
    if [ ! -d "./.asdf" ]; then
        echo "Cloning asdf into ./.asdf..."
        git clone https://github.com/asdf-vm/asdf.git ./.asdf --branch v0.14.0
    else
        echo ".asdf already exists in the project root"
    fi
    
    echo "Setting up project-local asdf environment..."
    # Unset any global asdf environment
    unset ASDF_DIR ASDF_DATA_DIR
    
    # Set project-local asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    
    echo "Sourcing asdf from project directory: $ASDF_DIR"
    . ./.asdf/asdf.sh
    
    echo "Adding asdf plugins..."
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true
    
    # Check if versions are already installed
    if asdf current erlang 2>/dev/null && asdf current elixir 2>/dev/null; then
        echo "Erlang and Elixir are already installed!"
        asdf current
    else
        echo "Installing Erlang and Elixir versions (as per .tool-versions)..."
        asdf install
    fi

# Test 1: Basic Elixir compilation for all apps
test-elixir-compile: install-elixir-erlang-env
    #!/usr/bin/env bash
    echo "🔨 Testing Elixir compilation for all apps..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    echo "📦 Getting dependencies..."
    mix deps.get || (echo "❌ Failed to get dependencies" && exit 1)
    
    echo "🔨 Compiling all apps..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "✅ All apps compiled successfully!"

# Test 2: Run unit tests for Elixir apps (no external dependencies)
test-elixir-unit: start-cockroach test-elixir-compile
    #!/usr/bin/env bash
    echo "🧪 Running unit tests for all Elixir apps..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    # Set environment variables for testing
    export MIX_ENV=test
    export DATABASE_URL="postgresql://root@localhost:26257/aria_character_core_test?sslmode=disable"
    
    echo "🧪 Running ExUnit tests..."
    mix test --exclude external_deps || (echo "❌ Unit tests failed" && exit 1)
    
    echo "✅ All unit tests passed!"

# Test 3: Test OpenBao connection (basic connectivity only)
test-openbao-connection: start-cockroach start-openbao
    #!/usr/bin/env bash
    echo "🔐 Testing basic OpenBao connection..."
    export VAULT_ADDR="http://localhost:8200"
    
    echo "⏳ Waiting for OpenBao to be ready..."
    timeout 30s bash -c 'until curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ OpenBao not ready" && exit 1)
    
    echo "🔍 Checking OpenBao health..."
    curl -sf "$VAULT_ADDR/v1/sys/health" > /dev/null || (echo "❌ OpenBao health check failed" && exit 1)
    
    echo "✅ OpenBao connection test passed!"

# Test 4: Test basic secret operations (requires OpenBao)
test-basic-secrets: test-openbao-connection
    #!/usr/bin/env bash
    echo "🔑 Testing basic secret operations..."
    export VAULT_ADDR="http://localhost:8200"
    
    # Get token from native storage or initialize if needed
    get_vault_token() {
        # Try native storage first
        if [ -f /opt/bao/data/root_token.txt ]; then
            TOKEN=$(cat /opt/bao/data/root_token.txt 2>/dev/null || echo "")
            if [ -n "$TOKEN" ]; then
                echo "$TOKEN"
                return 0
            fi
        fi
        
        # Check if initialized
        INIT_STATUS=$(curl -sf "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        if echo "$INIT_STATUS" | grep -q '"initialized":false'; then
            echo "🔧 Initializing OpenBao..."
            INIT_RESPONSE=$(curl -sf -X POST -d '{"secret_shares":1,"secret_threshold":1}' "$VAULT_ADDR/v1/sys/init" 2>/dev/null)
            NEW_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
            if [ -n "$NEW_TOKEN" ]; then
                sudo mkdir -p /opt/bao/data
                echo "$NEW_TOKEN" | sudo tee /opt/bao/data/root_token.txt >/dev/null
                sudo chown bao:bao /opt/bao/data/root_token.txt
                echo "$NEW_TOKEN"
                return 0
            fi
        fi
        
        echo "root"  # fallback
    }
    
    VAULT_TOKEN=$(get_vault_token)
    export VAULT_TOKEN
    echo "🔑 Using token: $VAULT_TOKEN"
    
    # Test basic secret write/read
    echo "📝 Testing secret write..."
    curl -sf -H "X-Vault-Token: $VAULT_TOKEN" \
         -H "Content-Type: application/json" \
         -X POST \
         -d '{"data":{"test":"value123"}}' \
         "$VAULT_ADDR/v1/secret/data/test-basic" > /dev/null || (echo "❌ Secret write failed" && exit 1)
    
    echo "📖 Testing secret read..."
    RESPONSE=$(curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/test-basic")
    if echo "$RESPONSE" | grep -q "value123"; then
        echo "✅ Basic secret operations test passed!"
    else
        echo "❌ Secret read failed or content mismatch"
        exit 1
    fi

# Test 5: Test individual app - aria_security
test-aria-security: test-elixir-compile
    #!/usr/bin/env bash
    echo "🛡️  Testing aria_security app specifically..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    if [ ! -d apps/aria_security ]; then
        echo "❌ aria_security app not found"
        exit 1
    fi
    
    cd apps/aria_security
    echo "📦 Getting dependencies for aria_security..."
    mix deps.get || (echo "❌ Failed to get deps" && exit 1)
    
    echo "🔨 Compiling aria_security..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "🧪 Running aria_security tests..."
    mix test --exclude external_deps || (echo "❌ Tests failed" && exit 1)
    
    cd ../..
    echo "✅ aria_security tests passed!"

# Test 6: Test individual app - aria_auth  
test-aria-auth: test-elixir-compile
    #!/usr/bin/env bash
    echo "🔐 Testing aria_auth app specifically..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    if [ ! -d apps/aria_auth ]; then
        echo "❌ aria_auth app not found"
        exit 1
    fi
    
    cd apps/aria_auth
    echo "📦 Getting dependencies for aria_auth..."
    mix deps.get || (echo "❌ Failed to get deps" && exit 1)
    
    echo "🔨 Compiling aria_auth..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "🧪 Running aria_auth tests..."
    mix test --exclude external_deps || (echo "❌ Tests failed" && exit 1)
    
    cd ../..
    echo "✅ aria_auth tests passed!"

# Test 7: Test SoftHSM integration using Elixir module
test-softhsm-elixir: init-softhsm-elixir
    #!/usr/bin/env bash
    echo "🔧 Testing SoftHSM integration via AriaSecurity.SoftHSM module..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:${PATH}"
    . ./.asdf/asdf.sh || true
    
    # Set SoftHSM environment
    export SOFTHSM2_CONF=/etc/softhsm2.conf
    export MIX_ENV=test
    
    echo "🔑 Testing SoftHSM operations via Elixir..."
    mix run -e '
    config = %{
      slot_id: 0,
      token_label: "openbao-token", 
      user_pin: "1234",
      so_pin: "1234"
    }
    
    # Test 1: List slots
    IO.puts("📋 Testing slot listing...")
    case AriaSecurity.SoftHSM.list_slots(config) do
      {:ok, slots} -> 
        IO.puts("✅ Successfully listed #{length(slots)} slots")
        IO.inspect(slots, label: "Available slots")
      {:error, reason} -> 
        IO.puts("❌ Failed to list slots: #{inspect(reason)}")
        System.halt(1)
    end
    
    # Test 2: Generate RSA keypair
    IO.puts("🔐 Testing RSA keypair generation...")
    case AriaSecurity.SoftHSM.generate_rsa_keypair(config, "test-key") do
      {:ok, result} -> 
        IO.puts("✅ Successfully generated RSA keypair")
        IO.inspect(result, label: "Keypair result")
      {:error, reason} -> 
        IO.puts("❌ Failed to generate keypair: #{inspect(reason)}")
        System.halt(1)
    end
    
    # Test 3: List objects
    IO.puts("📦 Testing object listing...")
    case AriaSecurity.SoftHSM.list_objects(config) do
      {:ok, objects} -> 
        IO.puts("✅ Successfully listed #{length(objects)} objects")
        IO.inspect(objects, label: "HSM objects")
      {:error, reason} -> 
        IO.puts("❌ Failed to list objects: #{inspect(reason)}")
        System.halt(1)
    end
    
    IO.puts("✅ All SoftHSM tests passed!")
    '
    
    echo "✅ SoftHSM Elixir integration tests completed successfully!"

# Legacy complex test (kept for reference, but not used in main workflow)
test-security-service-legacy: install-elixir-erlang-env start-foundation-core
    #!/usr/bin/env bash
    echo "🧪 Running comprehensive Security Service tests including SoftHSM rekey and destroy operations..."
    
    # Setup asdf environment
    export ASDF_DIR="$(pwd)/.asdf"
    export ASDF_DATA_DIR="$(pwd)/.asdf"
    export PATH="$(pwd)/.asdf/bin:$(pwd)/.asdf/shims:/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    . ./.asdf/asdf.sh || true
    export VAULT_ADDR="http://localhost:8200"
    
    # Function to get OpenBao token
    get_openbao_token() {
        # Try to get the root token from container storage (HSM-sealed OpenBao)
        echo "🔑 Extracting OpenBao token from container storage..."
        PERSISTENT_TOKEN=$(docker exec aria-character-core-aria-app-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
        
        if [ -n "$PERSISTENT_TOKEN" ]; then
            export VAULT_TOKEN="$PERSISTENT_TOKEN"
            echo "✅ Using OpenBao token from container storage: $VAULT_TOKEN"
        elif [ -f .ci/openbao_root_token.txt ]; then
            echo "🔍 Container token not found, trying token file..."
            TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
            if [ -n "$TOKEN_FROM_FILE" ]; then
                export VAULT_TOKEN="$TOKEN_FROM_FILE"
                echo "✅ Using OpenBao token from file: $VAULT_TOKEN"
            else
                echo "⚠️  WARNING: Using fallback token"
                export VAULT_TOKEN="root"
            fi
        else
            # Fallback to extracting from logs
            echo "🔍 No persistent token sources found, trying container logs..."
            LIVE_TOKEN=$(docker logs aria-character-core-aria-app-1 | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' || echo "")
            if [ -n "$LIVE_TOKEN" ]; then
                export VAULT_TOKEN="$LIVE_TOKEN"
                echo "✅ Using OpenBao token from logs: $VAULT_TOKEN"
            else
                echo "⚠️  WARNING: No token sources found, using fallback"
                export VAULT_TOKEN="root"
            fi
        fi
    }
    
    # Function to check if OpenBao is initialized
    check_openbao_initialization() {
        echo "🔍 Checking OpenBao initialization status..."
        INIT_STATUS=$(curl -sf "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        if [ -n "$INIT_STATUS" ]; then
            INITIALIZED=$(echo "$INIT_STATUS" | grep -o '"initialized":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            if [ "$INITIALIZED" = "true" ]; then
                echo "✅ OpenBao is already initialized"
                return 0
            else
                echo "⚠️  OpenBao is not initialized"
                return 1
            fi
        else
            echo "❌ Cannot check OpenBao initialization status"
            return 1
        fi
    }
    
    # Function to initialize OpenBao if not already initialized
    initialize_openbao() {
        echo "🔧 Initializing OpenBao..."
        
        # Initialize OpenBao with HSM seal (auto-unseal)
        INIT_RESPONSE=$(curl -sf -X POST -d '{"secret_shares":1,"secret_threshold":1}' "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        
        if [ -n "$INIT_RESPONSE" ]; then
            # Extract root token from response
            NEW_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$NEW_TOKEN" ]; then
                echo "✅ OpenBao initialized successfully"
                echo "🔑 Root token: $NEW_TOKEN"
                
                # Store token in container and file
                docker exec aria-character-core-aria-app-1 bash -c "mkdir -p /vault/data && echo '$NEW_TOKEN' > /vault/data/root_token.txt" 2>/dev/null || true
                mkdir -p .ci
                echo "aria-app-1  | Root Token: $NEW_TOKEN" > .ci/openbao_root_token.txt
                echo "aria-app-1  | Seal Type: HSM (SoftHSM PKCS#11)" >> .ci/openbao_root_token.txt
                
                export VAULT_TOKEN="$NEW_TOKEN"
                return 0
            else
                echo "❌ Failed to extract root token from initialization response"
                return 1
            fi
        else
            echo "❌ Failed to initialize OpenBao"
            return 1
        fi
    }
    
    # Function to verify OpenBao connection
    verify_openbao_connection() {
        echo "🔐 Verifying OpenBao connection..."
        if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" > /dev/null; then
            echo "✅ OpenBao connection verified successfully"
            return 0
        else
            echo "❌ ERROR: Cannot connect to OpenBao at $VAULT_ADDR with token $VAULT_TOKEN"
            return 1
        fi
    }
    
    # Function to run basic security tests
    run_basic_security_tests() {
        echo "🧪 Running basic security service tests..."
        
        if [ ! -d apps/aria_security ]; then
            echo "❌ ERROR: apps/aria_security directory does not exist"
            return 1
        fi
        
        cd apps/aria_security
        if [ ! -f mix.exs ]; then
            echo "❌ ERROR: mix.exs file does not exist in apps/aria_security"
            return 1
        fi
        
        echo "🔍 Checking Elixir version..."
        bash -l -c "elixir --version" || (echo "❌ ERROR: Elixir not found" && return 1)
        
        echo "📦 Running: mix deps.get, mix compile, mix test (in apps/aria_security)"
        bash -l -c "mix deps.get" && \
        bash -l -c "mix compile --force --warnings-as-errors" && \
        bash -l -c "mix test"
        
        if [ $? -eq 0 ]; then
            echo "✅ Basic security service tests passed"
            cd ../..
            return 0
        else
            echo "❌ Basic security service tests failed"
            cd ../..
            return 1
        fi
    }
    
    # Function to test SoftHSM rekey functionality
    test_softhsm_rekey() {
        echo "🔄 Testing SoftHSM rekey functionality..."
        
        # Store original state for comparison
        echo "📊 Capturing initial SoftHSM state..."
        INITIAL_SLOTS=$(docker exec aria-character-core-aria-app-1 softhsm2-util --show-slots 2>/dev/null || echo "No slots available")
        echo "Initial slots: $INITIAL_SLOTS"
        
        # Test rekey operation (without waiting for user input)
        echo "🔑 Testing SoftHSM rekey operation..."
        docker compose -f docker-compose.yml stop aria-app || true
        docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
        # With integrated container, restart aria-app (which reinitializes SoftHSM internally)
        docker compose -f docker-compose.yml up -d aria-app
        
        if [ $? -eq 0 ]; then
            echo "✅ SoftHSM rekey operation completed successfully"
            
            # Restart foundation services after rekey
            echo "🔄 Restarting foundation services after rekey..."
            just foundation-startup
            sleep 10  # Give services time to start
            
            # Verify new SoftHSM state
            echo "📊 Capturing post-rekey SoftHSM state..."
            NEW_SLOTS=$(docker exec aria-character-core-aria-app-1 softhsm2-util --show-slots 2>/dev/null || echo "No slots available")
            echo "New slots: $NEW_SLOTS"
            
            return 0
        else
            echo "❌ SoftHSM rekey operation failed"
            return 1
        fi
    }
    
    # Function to test destroy and recovery
    test_destroy_and_recovery() {
        echo "💥 Testing destroy and recovery functionality..."
        
        # Test destroy operation (without waiting for user input)
        echo "🗑️  Testing destroy operation..."
        docker compose -f docker-compose.yml stop aria-app || true
        docker compose -f docker-compose.yml rm -f aria-app || true
        docker volume rm aria-character-core_openbao_data 2>/dev/null || true
        docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
        rm -f .ci/openbao_root_token.txt
        
        if [ $? -eq 0 ]; then
            echo "✅ Destroy operation completed successfully"
            
            # Test recovery
            echo "🔄 Testing recovery after destroy..."
            just foundation-startup
            sleep 15  # Give services time to initialize completely
            
            # Get new token after recovery
            get_openbao_token
            
            if verify_openbao_connection; then
                echo "✅ Recovery after destroy completed successfully"
                return 0
            else
                echo "❌ Recovery after destroy failed"
                return 1
            fi
        else
            echo "❌ Destroy operation failed"
            return 1
        fi
    }
    
    # Main test execution
    echo "🚀 Starting comprehensive security service tests..."
    
    # Check if OpenBao is initialized first
    echo ""
    echo "=== INITIALIZATION CHECK ==="
    echo "🔍 Checking if OpenBao is ready and initialized..."
    
    # Check if OpenBao API is ready
    if curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
        echo "✅ OpenBao API is ready"
        
        # Check initialization status
        if ! check_openbao_initialization; then
            echo "🔧 OpenBao ready but not initialized, performing initialization..."
            if ! initialize_openbao; then
                echo "❌ Failed to initialize OpenBao, aborting"
                exit 1
            fi
        fi
    else
        echo "❌ OpenBao API is not ready yet, aborting"
        exit 1
    fi
    
    # Test 1: Basic functionality
    echo ""
    echo "=== TEST 1: Basic Security Service Functionality ==="
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Initial connection test failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Basic security tests failed, aborting"
        exit 1
    fi
    
    # Test 2: SoftHSM Rekey functionality
    echo ""
    echo "=== TEST 2: SoftHSM Rekey Functionality ==="
    if ! test_softhsm_rekey; then
        echo "❌ SoftHSM rekey test failed, aborting"
        exit 1
    fi
    
    # Get token after rekey and verify basic tests still work
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Connection test after rekey failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Security tests after rekey failed, aborting"
        exit 1
    fi
    
    # Test 3: Destroy and recovery functionality
    echo ""
    echo "=== TEST 3: Destroy and Recovery Functionality ==="
    if ! test_destroy_and_recovery; then
        echo "❌ Destroy and recovery test failed, aborting"
        exit 1
    fi
    
    # Final verification after recovery
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Final connection test failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Final security tests failed, aborting"
        exit 1
    fi
    
    echo ""
    echo "🎉 All security service tests completed successfully!"
    echo "✅ Basic functionality: PASSED"
    echo "✅ SoftHSM rekey: PASSED"
    echo "✅ Destroy and recovery: PASSED"
    echo "✅ Post-operation functionality: PASSED"

# Generate a new varying root token for OpenBao
generate-new-root-token: start-openbao
    #!/usr/bin/env bash
    echo "Generating a new varying root token for OpenBao..."
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    
    # Get the current token to use for authentication
    CURRENT_TOKEN=""
    
    # Try to get token from native storage first
    if [ -f /opt/bao/data/root_token.txt ]; then
        CURRENT_TOKEN=$(cat /opt/bao/data/root_token.txt 2>/dev/null || echo "")
        if [ -n "$CURRENT_TOKEN" ]; then
            echo "Using token from native storage: $CURRENT_TOKEN"
        fi
    fi
    
    if [ -z "$CURRENT_TOKEN" ] && [ -f .ci/openbao_root_token.txt ]; then
        TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
        if [ -n "$TOKEN_FROM_FILE" ]; then
            CURRENT_TOKEN="$TOKEN_FROM_FILE"
            echo "Using token from file: $CURRENT_TOKEN"
        fi
    fi
    
    if [ -z "$CURRENT_TOKEN" ]; then
        echo "❌ ERROR: Could not find valid OpenBao token"
        exit 1
    fi
    
    echo "Using current token for authentication: $CURRENT_TOKEN"
    
    # Generate new root token
    echo "🔄 Generating new root token..."
    NEW_TOKEN_RESPONSE=$(VAULT_TOKEN="$CURRENT_TOKEN" bao token create -address="$BAO_ADDR" -policy=root -format=json 2>/dev/null || echo "")
    NEW_TOKEN=$(echo "$NEW_TOKEN_RESPONSE" | jq -r '.auth.client_token' 2>/dev/null || echo "")
    
    if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
        echo "✅ Generated new root token: $NEW_TOKEN"
        
        # Update native token file
        sudo mkdir -p /opt/bao/data
        echo "$NEW_TOKEN" | sudo tee /opt/bao/data/root_token.txt >/dev/null
        sudo chown bao:bao /opt/bao/data/root_token.txt
        
        # Update the token file (no unseal keys with HSM seal)
        mkdir -p .ci
        echo "Root Token: $NEW_TOKEN" > .ci/openbao_root_token.txt
        echo "Seal Type: HSM (SoftHSM PKCS#11)" >> .ci/openbao_root_token.txt
        
        echo "📝 Token file updated with new varying root token"
        echo "🔑 New token: $NEW_TOKEN"
        echo "🔐 Seal keys are securely stored in SoftHSM"
    else
        echo "❌ ERROR: Failed to generate new root token"
        exit 1
    fi

# Destroy and reinitialize OpenBao and SoftHSM (DESTRUCTIVE OPERATION)
destroy-bao:
    #!/usr/bin/env bash
    echo "⚠️  WARNING: This will DESTROY all OpenBao data, secrets, and SoftHSM tokens!"
    echo "⚠️  This operation is IRREVERSIBLE!"
    echo "⚠️  All HSM keys and OpenBao data will be permanently lost!"
    echo ""
    echo "🔥 Proceeding with destruction in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    echo "🔥 Destroying OpenBao and SoftHSM..."
    
    # Stop all foundation services
    echo "🛑 Stopping foundation services..."
    docker compose -f docker-compose.yml stop openbao || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao || true
    
    # Remove OpenBao data volumes
    echo "💾 Removing OpenBao volumes..."
    docker volume rm aria-character-core_openbao_data 2>/dev/null || true
    docker volume rm aria-character-core_openbao_config 2>/dev/null || true
    
    # Remove SoftHSM token volume (this destroys all HSM keys including seal keys)
    echo "🔑 Removing SoftHSM tokens volume..."
    docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
    
    # Remove token files
    echo "📄 Removing token files..."
    rm -f .ci/openbao_root_token.txt
    
    echo "💥 OpenBao and SoftHSM destroyed successfully!"
    echo "🔐 All seal keys have been securely destroyed in SoftHSM"
    echo "📝 Run 'just foundation-startup' to reinitialize with completely new HSM and OpenBao setup"
    #!/usr/bin/env bash
    echo "⚠️  WARNING: This will DESTROY all OpenBao data, secrets, and SoftHSM tokens!"
    echo "⚠️  This operation is IRREVERSIBLE!"
    echo "⚠️  All HSM keys and OpenBao data will be permanently lost!"
    echo ""
    echo "🔥 Proceeding with destruction in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    echo "🔥 Destroying OpenBao and SoftHSM..."
    
    # Stop all foundation services
    echo "🛑 Stopping foundation services..."
    docker compose -f docker-compose.yml stop openbao || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao || true
    
    # Remove OpenBao data volumes
    echo "💾 Removing OpenBao volumes..."
    docker volume rm aria-character-core_openbao_data 2>/dev/null || true
    docker volume rm aria-character-core_openbao_config 2>/dev/null || true
    
    # Remove SoftHSM token volume (this destroys all HSM keys)
    echo "🔑 Removing SoftHSM tokens volume..."
    docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
    
    # Remove token files
    echo "📄 Removing token files..."
    rm -f .ci/openbao_root_token.txt
    
    echo "💥 OpenBao and SoftHSM destroyed successfully!"
    echo "📝 Run 'just foundation-startup' to reinitialize with completely new HSM and OpenBao setup"

# Rekey OpenBao unseal keys and optionally regenerate SoftHSM tokens
rekey-bao: foundation-startup
    #!/usr/bin/env bash
    echo "🔐 Rekeying OpenBao with HSM seal..."
    echo "ℹ️  With HSM seal, the seal keys are securely managed by SoftHSM"
    echo "ℹ️  Only root tokens are managed outside the HSM"
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    
    # Get current token
    CURRENT_TOKEN=""
    
    # Try to get token from container's persistent storage
    CONTAINER_TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
    if [ -n "$CONTAINER_TOKEN" ]; then
        CURRENT_TOKEN="$CONTAINER_TOKEN"
        echo "Using token from container storage: $CURRENT_TOKEN"
    elif [ -f .ci/openbao_root_token.txt ]; then
        TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
        if [ -n "$TOKEN_FROM_FILE" ]; then
            CURRENT_TOKEN="$TOKEN_FROM_FILE"
            echo "Using token from file: $CURRENT_TOKEN"
        fi
    fi
    
    if [ -z "$CURRENT_TOKEN" ]; then
        echo "❌ ERROR: Could not find valid OpenBao token"
        exit 1
    fi
    
    echo "⚠️  WARNING: With HSM seal, traditional rekeying is handled by the HSM"
    echo "⚠️  To rekey the HSM tokens, use 'just rekey-softhsm'"
    echo "⚠️  This command will generate a new root token only"
    echo ""
    echo "🔄 Starting root token regeneration in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    # Generate new root token (HSM seal keys don't change)
    echo "🔄 Generating new root token..."
    just generate-new-root-token
    
    echo "✅ Root token regenerated successfully!"
    echo "🔐 HSM seal keys remain securely protected in SoftHSM"
    #!/usr/bin/env bash
    echo "🔐 Rekeying OpenBao unseal keys..."
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    
    # Get current token
    CURRENT_TOKEN=""
    
    # Try to get token from container's persistent storage
    CONTAINER_TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
    if [ -n "$CONTAINER_TOKEN" ]; then
        CURRENT_TOKEN="$CONTAINER_TOKEN"
        echo "Using token from container storage: $CURRENT_TOKEN"
    elif [ -f .ci/openbao_root_token.txt ]; then
        TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
        if [ -n "$TOKEN_FROM_FILE" ]; then
            CURRENT_TOKEN="$TOKEN_FROM_FILE"
            echo "Using token from file: $CURRENT_TOKEN"
        fi
    fi
    
    if [ -z "$CURRENT_TOKEN" ]; then
        echo "❌ ERROR: Could not find valid OpenBao token"
        exit 1
    fi
    
    echo "⚠️  WARNING: Rekeying will generate new unseal keys!"
    echo "⚠️  You must save the new unseal keys securely!"
    echo ""
    echo "🔄 Starting rekey process in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    # Initialize rekey
    echo "🔄 Initializing OpenBao rekey process..."
    REKEY_INIT=$(docker exec -e BAO_ADDR="$BAO_ADDR" -e VAULT_TOKEN="$CURRENT_TOKEN" aria-character-core-openbao-1 bao operator rekey -init -key-shares=1 -key-threshold=1 -format=json)
    REKEY_NONCE=$(echo "$REKEY_INIT" | grep -o '"nonce":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$REKEY_NONCE" ]; then
        echo "❌ ERROR: Failed to initialize rekey"
        exit 1
    fi
    
    echo "📋 Rekey initialized with nonce: $REKEY_NONCE"
    
    # Get current unseal key
    CURRENT_UNSEAL_KEY=$(docker exec aria-character-core-openbao-1 cat /vault/data/unseal_key.txt 2>/dev/null || echo "")
    if [ -z "$CURRENT_UNSEAL_KEY" ]; then
        echo "❌ ERROR: Could not find current unseal key"
        exit 1
    fi
    
    # Provide the current unseal key for rekeying
    echo "🔑 Providing current unseal key for rekey..."
    REKEY_RESULT=$(docker exec -e BAO_ADDR="$BAO_ADDR" -e VAULT_TOKEN="$CURRENT_TOKEN" aria-character-core-openbao-1 bao operator rekey -nonce="$REKEY_NONCE" -format=json "$CURRENT_UNSEAL_KEY")
    
    # Extract new keys
    NEW_UNSEAL_KEY=$(echo "$REKEY_RESULT" | grep -o '"keys":\["[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$NEW_UNSEAL_KEY" ]; then
        echo "✅ Rekey completed successfully!"
        echo "🔑 New unseal key: $NEW_UNSEAL_KEY"
        
        # Update the container's unseal key file
        docker exec aria-character-core-openbao-1 bash -c "echo '$NEW_UNSEAL_KEY' > /vault/data/unseal_key.txt"
        
        # Update token file with new unseal key
        echo "openbao-1  | Root Token: $CURRENT_TOKEN" > .ci/openbao_root_token.txt
        echo "openbao-1  | Unseal Key: $NEW_UNSEAL_KEY" >> .ci/openbao_root_token.txt
        
        echo "📝 Token file updated with new unseal key"
        echo "⚠️  IMPORTANT: Save the new unseal key securely: $NEW_UNSEAL_KEY"
    else
        echo "❌ ERROR: Failed to complete rekey operation"
        exit 1
    fi

# Regenerate SoftHSM tokens (DESTRUCTIVE for HSM keys)
rekey-softhsm:
    #!/usr/bin/env bash
    echo "🔐 Regenerating SoftHSM tokens..."
    echo "⚠️  WARNING: This will destroy all existing SoftHSM tokens and HSM seal keys!"
    echo "⚠️  OpenBao will need to be completely reinitialized after this operation!"
    echo "⚠️  All seal keys will be regenerated in the HSM!"
    echo ""
    echo "🔥 Starting SoftHSM regeneration in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    echo "🛑 Stopping services that use SoftHSM..."
    docker compose -f docker-compose.yml stop openbao || true
    
    echo "🗑️  Removing existing SoftHSM tokens (destroys all HSM seal keys)..."
    docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
    
    echo "🔄 Restarting OpenBao (which reinitializes SoftHSM internally)..."
    docker compose -f docker-compose.yml up -d openbao
    
    echo "✅ SoftHSM tokens regenerated successfully!"
    echo "🔐 New HSM seal keys will be generated automatically"
    echo "⚠️  IMPORTANT: OpenBao must be reinitialized since HSM seal keys changed"
    echo "📝 Run 'just destroy-bao' then 'just foundation-startup' to reinitialize OpenBao"
    #!/usr/bin/env bash
    echo "🔐 Regenerating SoftHSM tokens..."
    echo "⚠️  WARNING: This will destroy all existing SoftHSM tokens and keys!"
    echo "⚠️  OpenBao will need to be reinitialized after this operation!"
    echo ""
    echo "🔥 Starting SoftHSM regeneration in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    
    echo "🛑 Stopping services that use SoftHSM..."
    docker compose -f docker-compose.yml stop openbao || true
    
    echo "🗑️  Removing existing SoftHSM tokens..."
    docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
    
    echo "🔄 Restarting OpenBao (which reinitializes SoftHSM internally)..."
    docker compose -f docker-compose.yml up -d openbao
    
    echo "✅ SoftHSM tokens regenerated successfully!"
    echo "⚠️  IMPORTANT: OpenBao must be reinitialized since HSM keys changed"
    echo "📝 Run 'just destroy-bao' then 'just foundation-startup' to reinitialize OpenBao"
