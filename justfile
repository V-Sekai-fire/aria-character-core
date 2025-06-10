# Main justfile for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Default recipe - show available commands
default:
    @echo "🎯 Aria Character Core - Available Commands"
    @echo ""
    @echo "🚀 Quick Start:"
    @echo "  just setup-all-dependencies - Install all dependencies"
    @echo "  just start-all            - Start all services"
    @echo "  just show-services-status - Check service status"
    @echo "  just stop-all-services    - Stop all services"
    @echo ""
    @echo "📋 For detailed commands: just --list"

# Quick aliases for common operations
alias setup := setup-all-dependencies
alias start := start-all-services
alias stop := stop-all-services
alias status := show-services-status
alias logs := show-all-logs

# --- Consolidated Installation Recipes (from justfiles/install.just) ---

setup-all-dependencies: install-elixir-erlang-env install-cockroach install-openbao install-seaweedfs
    @echo "All dependencies installed."

install-elixir-erlang-env:
    #!/usr/bin/env bash
    echo "Installing Elixir and Erlang environment..."
    # Add your Elixir/Erlang installation commands here
    # Example for Ubuntu:
    # sudo apt-get update
    # sudo apt-get install -y elixir erlang
    # Example for macOS (using asdf or Homebrew):
    # brew install elixir
    echo "Elixir and Erlang environment installed."

install-cockroach:
    #!/usr/bin/env bash
    echo "Installing CockroachDB..."
    # Add your CockroachDB installation commands here
    # Example for macOS:
    # brew install cockroachdb
    echo "CockroachDB installed."

install-openbao:
    #!/usr/bin/env bash
    echo "Installing OpenBao..."
    # Add your OpenBao installation commands here
    # Example for macOS:
    # brew install openbao
    echo "OpenBao installed."

install-seaweedfs:
    #!/usr/bin/env bash
    echo "Installing SeaweedFS..."
    # Add your SeaweedFS installation commands here
    # Example for macOS:
    # brew install seaweedfs
    echo "SeaweedFS installed."

# --- Consolidated CockroachDB Service Management (from justfiles/cockroach.just) ---

start-cockroach: install-cockroach
    #!/usr/bin/env bash
    echo "🗄️  Starting CockroachDB..."
    
    # Check if CockroachDB is already running
    if pgrep -f "cockroach start" > /dev/null; then
        echo "✅ CockroachDB is already running"
        exit 0
    fi
    
    # Create data directory based on OS
    if [ "{{os()}}" = "linux" ]; then
        DATA_DIR="/var/lib/cockroach/data"
        LOG_DIR="/var/log/cockroach"
        
        # Create directories with proper permissions
        sudo mkdir -p "$DATA_DIR" "$LOG_DIR"
        
        # Create cockroach user if it doesn't exist
        if ! id cockroach >/dev/null 2>&1; then
            sudo useradd -r -s /bin/false cockroach
        fi
        
        sudo chown -R cockroach:cockroach "$DATA_DIR" "$LOG_DIR"
        
        # Start CockroachDB as cockroach user
        echo "🚀 Starting CockroachDB in single-node mode (Linux)..."
        sudo -u cockroach nohup cockroach start-single-node \
            --insecure \
            --store="$DATA_DIR" \
            --listen-addr=localhost:26257 \
            --http-addr=localhost:8080 \
            --log-dir="$LOG_DIR" \
            --background > /dev/null 2>&1
    else
        # macOS/other systems
        DATA_DIR="$HOME/.local/share/cockroach/data"
        LOG_DIR="$HOME/.local/share/cockroach/logs"
        
        # Create directories
        mkdir -p "$DATA_DIR" "$LOG_DIR"
        
        echo "🚀 Starting CockroachDB in single-node mode (macOS)..."
        nohup cockroach start-single-node \
            --insecure \
            --store="$DATA_DIR" \
            --listen-addr=localhost:26257 \
            --http-addr=localhost:8080 \
            --log-dir="$LOG_DIR" \
            --background > /dev/null 2>&1
    fi
    
    # Wait for CockroachDB to be ready
    echo "⏳ Waiting for CockroachDB to be ready..."
    for i in {1..30}; do
        if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
            echo "✅ CockroachDB started successfully!"
            echo "🌐 Admin UI: http://localhost:8080"
            echo "🔗 SQL: postgresql://root@localhost:26257/defaultdb?sslmode=disable"
            exit 0
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    echo "❌ CockroachDB failed to start within 60 seconds"
    exit 1

stop-cockroach:
    #!/usr/bin/env bash
    echo "🛑 Stopping CockroachDB..."
    
    # Try graceful shutdown first
    if pgrep -f "cockroach start" > /dev/null; then
        echo "📨 Attempting graceful shutdown..."
        cockroach quit --insecure --host=localhost:26257 2>/dev/null || true
        
        # Wait up to 10 seconds for graceful shutdown
        for i in {1..10}; do
            if ! pgrep -f "cockroach start" > /dev/null; then
                echo "✅ CockroachDB stopped gracefully"
                exit 0
            fi
            sleep 1
        done
        
        # Force kill if graceful shutdown failed
        echo "⚠️  Graceful shutdown failed, force killing..."
        pkill -f "cockroach start" 2>/dev/null || true
        
        # Final check
        sleep 2
        if pgrep -f "cockroach start" > /dev/null; then
            echo "❌ Failed to stop CockroachDB"
            exit 1
        else
            echo "✅ CockroachDB force stopped"
        fi
    else
        echo "✅ CockroachDB is not running"
    fi

cockroach-status:
    #!/usr/bin/env bash
    echo "📊 CockroachDB Status:"
    
    # Check if process is running
    if pgrep -f 'cockroach start' >/dev/null; then
        echo "Process: ✅ RUNNING (PID: $(pgrep -f 'cockroach start'))"
    else
        echo "Process: ❌ STOPPED"
        exit 0
    fi
    
    # Check health endpoint
    if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
        echo "Health: ✅ HEALTHY"
        echo "🌐 Admin UI: http://localhost:8080"
        echo "🔗 SQL: postgresql://root@localhost:26257/defaultdb?sslmode=disable"
        
        # Show basic cluster info
        echo ""
        echo "📈 Cluster Info:"
        cockroach sql --insecure --host=localhost:26257 --execute="SELECT version();" 2>/dev/null | grep -v "Time:" || echo "  Failed to connect to SQL interface"
    else
        echo "Health: ❌ UNHEALTHY"
        echo "⚠️  Process is running but health check failed"
    fi

cockroach-logs:
    #!/usr/bin/env bash
    echo "📋 CockroachDB Logs:"
    
    if [ "{{os()}}" = "linux" ]; then
        LOG_DIR="/var/log/cockroach"
    else
        LOG_DIR="$HOME/.local/share/cockroach/logs"
    fi
    
    if [ -d "$LOG_DIR" ]; then
        # Find the most recent log file
        LATEST_LOG=$(find "$LOG_DIR" -name "cockroach.log" -o -name "*.log" 2>/dev/null | head -1)
        if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
            echo "📄 Showing last 30 lines from: $LATEST_LOG"
            tail -30 "$LATEST_LOG"
        else
            echo "⚠️  No log files found in $LOG_DIR"
        fi
    else
        echo "⚠️  Log directory $LOG_DIR does not exist"
        echo "   Make sure CockroachDB has been started at least once"
    fi

# --- Consolidated Service Orchestration (from justfiles/orchestration.just) ---

# Define recipes for starting all services
start-all:
    #!/usr/bin/env bash
    echo "🚀 Starting all services (CockroachDB + OpenBao + SeaweedFS + Elixir app)..."
    just start-cockroach
    just start-openbao
    just start-seaweedfs
    mix app.start # Call the new mix task for Elixir app
    echo "✅ All services started natively!"

stop-all-services:
    #!/usr/bin/env bash
    echo "🛑 Stopping all native services..."
    
    mix app.stop # Call the new mix task for Elixir app
    just stop-seaweedfs
    just stop-openbao
    just stop-cockroach
    
    echo "✅ All native services stopped!"

show-services-status:
    #!/usr/bin/env bash
    echo "📊 Native Services Status:"
    echo ""
    just cockroach-status
    just openbao-status
    just seaweedfs-status
    mix app.status # Call the new mix task for Elixir app
    echo ""
    echo "🔍 Health Check Results:"
    echo "CockroachDB Health: $(curl -sf http://localhost:8080/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "OpenBao Health: $(curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "SeaweedFS S3 Health: $(curl -sf http://localhost:8333 >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"
    echo "Elixir App Health: $(curl -sf http://localhost:4000/health >/dev/null 2>&1 && echo '✅ HEALTHY' || echo '❌ UNHEALTHY')"

show-all-logs:
    #!/usr/bin/env bash
    echo "📋 Native Services Logs:"
    echo ""
    just cockroach-logs
    just openbao-logs
    just seaweedfs-logs
    mix app.logs # Call the new mix task for Elixir app

# Health check with startup if needed
health:
    #!/usr/bin/env bash
    echo "🏥 Aria Services Health Check"
    echo "════════════════════════════"
    echo ""

    # Check if core services are running, start if needed
    if ! curl -sf http://localhost:8080/health >/dev/null 2>&1; then
        echo "⚠️  CockroachDB not healthy, starting..."
        just start-cockroach
    fi

    if ! curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
        echo "⚠️  OpenBao not healthy, starting..."
        just start-openbao
    fi

    if ! curl -sf http://localhost:8333 >/dev/null 2>&1; then
        echo "⚠️  SeaweedFS not healthy, starting..."
        just start-seaweedfs
    fi

    # Show final status
    just show-services-status

# --- Consolidated Environment-Specific Recipes (from justfiles/dev.just, production.just, test.just, security.just) ---

# Development specific recipes
dev-start:
    @echo "Starting development environment..."
    just start-all # Start all services defined in orchestration.just
    # Add any other dev-specific startup commands here

dev-stop:
    @echo "Stopping development environment..."
    just stop-all-services # Stop all services defined in orchestration.just
    # Add any other dev-specific shutdown commands here

# Production specific recipes
prod-start:
    @echo "Starting production environment..."
    just start-all # Start all services defined in orchestration.just
    # Add any other production-specific startup commands here

prod-stop:
    @echo "Stopping production environment..."
    just stop-all-services # Stop all services defined in orchestration.just
    # Add any other production-specific shutdown commands here

# Test specific recipes
test-all:
    @echo "Running all tests..."
    just start-all # Ensure services are running for integration tests
    # Add commands to run all tests (e.g., mix test.all)
    just stop-all-services # Clean up after tests

test-unit:
    @echo "Running unit tests..."
    # Add commands to run unit tests (e.g., mix test --only unit)

test-integration:
    @echo "Running integration tests..."
    just start-all # Ensure services are running for integration tests
    # Add commands to run integration tests
    just stop-all-services # Clean up after tests

# Security specific recipes
rekey-bao:
    @echo "Rekeying OpenBao..."
    just openbao-init # Assuming openbao-init is defined in openbao.just
    # Add any other rekeying steps here
