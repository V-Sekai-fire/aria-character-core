# Service orchestration recipes for Aria Character Core
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

import "cockroach.just"
import "openbao.just"
import "seaweedfs.just"
# import "elixir_app.just" # Elixir app now managed by mix tasks

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
    mix app.status # Placeholder for new mix task
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
    mix app.logs # Placeholder for new mix task

health: start-all show-services-status
