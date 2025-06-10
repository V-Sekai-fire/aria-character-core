# CockroachDB service management for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import "install.just"

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

# Restart CockroachDB (stop then start)
restart-cockroach:
    #!/usr/bin/env bash
    echo "🔄 Restarting CockroachDB..."
    just stop-cockroach
    sleep 2
    just start-cockroach

# Initialize the database with default schema
cockroach-init:
    #!/usr/bin/env bash
    echo "🗄️  Initializing CockroachDB database..."
    
    # Wait for CockroachDB to be ready
    if ! curl -sf http://localhost:8080/health >/dev/null 2>&1; then
        echo "❌ CockroachDB is not running. Start it first with: just start-cockroach"
        exit 1
    fi
    
    # Create default database
    echo "📝 Creating default database 'aria_character_core'..."
    cockroach sql --insecure --host=localhost:26257 --execute="CREATE DATABASE IF NOT EXISTS aria_character_core;" || {
        echo "❌ Failed to create database"
        exit 1
    }
    
    echo "✅ Database initialized successfully"
    echo "🔗 Connect with: postgresql://root@localhost:26257/aria_character_core?sslmode=disable"
