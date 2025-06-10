# Main justfile for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Import all service modules - each module is self-contained
import 'justfiles/install.just'
import 'justfiles/cockroach.just'
import 'justfiles/openbao.just'
import 'justfiles/seaweedfs.just'
# import 'justfiles/elixir_app.just' # Elixir app now managed by mix tasks
import 'justfiles/development.just'
import 'justfiles/testing.just'
import 'justfiles/production.just'
import 'justfiles/security.just'

# Default recipe - show available commands
default:
    @echo "🎯 Aria Character Core - Available Commands"
    @echo ""
    @echo "🚀 Quick Start:"
    @echo "  just setup     - Install all dependencies"
    @echo "  just start     - Start all services"
    @echo "  just status    - Check service status"
    @echo "  just stop      - Stop all services"
    @echo ""
    @echo "📋 For detailed commands: just --list"

# Quick aliases for common operations
alias setup := install-deps
alias start := start-all-services
alias stop := stop-all-services  
alias status := show-status
alias logs := show-logs

# === Core Service Orchestration ===
# These recipes coordinate multiple services

# Start all services in correct order
start-all-services:
    #!/usr/bin/env bash
    echo "🚀 Starting all Aria services..."
    echo ""
    
    # Start infrastructure services first
    echo "1️⃣ Starting CockroachDB..."
    just start-cockroach
    echo ""
    
    echo "2️⃣ Starting OpenBao..."
    just start-openbao
    echo ""
    
    echo "3️⃣ Starting SeaweedFS..."
    just start-seaweedfs
    echo ""
    
    # Start application last
    echo "4️⃣ Starting Elixir application..."
    just start-elixir
    echo ""
    
    echo "✅ All services started!"
    echo ""
    echo "🌐 Service URLs:"
    echo "  • Aria App:      http://localhost:4000"
    echo "  • CockroachDB:   http://localhost:8080"  
    echo "  • OpenBao:       http://localhost:8200"
    echo "  • SeaweedFS S3:  http://localhost:8333"

# Stop all services in reverse order
stop-all-services:
    #!/usr/bin/env bash
    echo "🛑 Stopping all Aria services..."
    echo ""
    
    # Stop application first
    echo "1️⃣ Stopping Elixir application..."
    just stop-elixir
    echo ""
    
    # Stop infrastructure services
    echo "2️⃣ Stopping SeaweedFS..."
    just stop-seaweedfs
    echo ""
    
    echo "3️⃣ Stopping OpenBao..."
    just stop-openbao
    echo ""
    
    echo "4️⃣ Stopping CockroachDB..."
    just stop-cockroach
    echo ""
    
    echo "✅ All services stopped!"

# Show status of all services
show-status:
    #!/usr/bin/env bash
    echo "📊 Aria Services Status"
    echo "══════════════════════"
    echo ""
    
    just cockroach-status
    echo ""
    just openbao-status  
    echo ""
    just seaweedfs-status
    echo ""
    just elixir-status
    echo ""
    
    echo "🔍 Health Check Summary:"
    echo "────────────────────────"
    COCKROACH_HEALTH=$(curl -sf http://localhost:8080/health >/dev/null 2>&1 && echo "✅ HEALTHY" || echo "❌ UNHEALTHY")
    OPENBAO_HEALTH=$(curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1 && echo "✅ HEALTHY" || echo "❌ UNHEALTHY") 
    SEAWEEDFS_HEALTH=$(curl -sf http://localhost:8333 >/dev/null 2>&1 && echo "✅ HEALTHY" || echo "❌ UNHEALTHY")
    ELIXIR_HEALTH=$(curl -sf http://localhost:4000/health >/dev/null 2>&1 && echo "✅ HEALTHY" || echo "❌ UNHEALTHY")
    
    echo "  CockroachDB: $COCKROACH_HEALTH"
    echo "  OpenBao:     $OPENBAO_HEALTH"
    echo "  SeaweedFS:   $SEAWEEDFS_HEALTH"
    echo "  Elixir App:  $ELIXIR_HEALTH"

# Show logs from all services  
show-logs:
    #!/usr/bin/env bash
    echo "📋 Aria Services Logs"
    echo "═══════════════════════"
    echo ""
    
    echo "🗄️  CockroachDB Logs:"
    echo "─────────────────────"
    just cockroach-logs
    echo ""
    
    echo "🔐 OpenBao Logs:"
    echo "────────────────"
    just openbao-logs
    echo ""
    
    echo "💾 SeaweedFS Logs:"
    echo "──────────────────"
    just seaweedfs-logs
    echo ""
    
    echo "⚗️  Elixir App Logs:"
    echo "───────────────────"
    just elixir-logs

# Restart all services
restart-all-services:
    #!/usr/bin/env bash
    echo "🔄 Restarting all Aria services..."
    just stop-all-services
    sleep 3
    just start-all-services

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
    just show-status
