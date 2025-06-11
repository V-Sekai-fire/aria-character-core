#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Database migration script for Fly.io deployment

set -e

echo "Starting database migrations..."

# Wait for database to be ready
echo "Waiting for database to be ready..."
until pg_isready -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USER; do
  echo "Waiting for database..."
  sleep 2
done

echo "Database is ready. Running migrations..."

# Run migrations for all repositories
echo "Running AriaData.Repo migrations..."
/app/bin/aria_queue eval "AriaData.Repo.migrate()"

echo "Running AriaData.AuthRepo migrations..."
/app/bin/aria_queue eval "AriaData.AuthRepo.migrate()"

echo "Running AriaData.QueueRepo migrations..."
/app/bin/aria_queue eval "AriaData.QueueRepo.migrate()"

echo "Running AriaData.StorageRepo migrations..."
/app/bin/aria_queue eval "AriaData.StorageRepo.migrate()"

echo "Running AriaData.MonitorRepo migrations..."
/app/bin/aria_queue eval "AriaData.MonitorRepo.migrate()"

echo "Running AriaData.EngineRepo migrations..."
/app/bin/aria_queue eval "AriaData.EngineRepo.migrate()"

echo "All migrations completed successfully!"
