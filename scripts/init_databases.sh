#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Database initialization script for aria-character-core

set -e

echo "🚀 Initializing CockroachDB databases for aria-character-core..."

# Check if CockroachDB is running
if ! docker compose ps cockroachdb | grep -q "running"; then
    echo "⚠️  CockroachDB container is not running. Starting it now..."
    docker compose up -d cockroachdb
    echo "⏳ Waiting for CockroachDB to be ready..."
    sleep 10
fi

# Wait for CockroachDB to be ready
echo "🔍 Checking CockroachDB connectivity..."
until docker compose exec cockroachdb cockroach sql --insecure --execute="SELECT 1;" > /dev/null 2>&1; do
    echo "⏳ Waiting for CockroachDB to be ready..."
    sleep 2
done

echo "✅ CockroachDB is ready!"

# Create databases
echo "🗄️  Creating databases..."
docker compose exec cockroachdb cockroach sql --insecure --file=/scripts/init_databases.sql

# Verify databases were created
echo "🔍 Verifying databases..."
docker compose exec cockroachdb cockroach sql --insecure --execute="SHOW DATABASES;"

echo "✅ Database initialization complete!"
echo ""
echo "📋 Created databases:"
echo "   Development: aria_data_dev, aria_auth_dev, aria_queue_dev, aria_storage_dev, aria_monitor_dev, aria_engine_dev"
echo "   Test: aria_data_test, aria_auth_test, aria_queue_test, aria_storage_test, aria_monitor_test, aria_engine_test"
echo "   Production: aria_data_prod, aria_auth_prod, aria_queue_prod, aria_storage_prod, aria_monitor_prod, aria_engine_prod"
echo ""
echo "🎯 Next steps:"
echo "   1. Run migrations: mix ecto.create && mix ecto.migrate"
echo "   2. Update services to use their designated repositories"
echo "   3. Test database connections"
