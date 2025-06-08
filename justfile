# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

download-cockroach-tar:
    @echo "Downloading CockroachDB tarball..."
    @curl -L -o cockroachdb.tar https://github.com/V-Sekai/cockroach/releases/download/cockroach-2/cockroachdb.tar
    @echo "Download complete: cockroachdb.tar"

load-cockroach-docker: download-cockroach-tar
    @echo "Loading cockroachdb.tar into Docker..."
    @docker load -i cockroachdb.tar
    @echo "Docker image loaded."

up: load-cockroach-docker
    @echo "Starting all services defined in docker-compose.yml..."
    # This will start all services. For specific foundation services, use 'just foundation-startup'.
    # Ensure necessary environment variables (e.g., for OpenBao PKCS#11) are set in your environment or a .env file.
    @docker compose -f docker-compose.yml up -d

down:
    @echo "Stopping and removing all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml down

# --- New recipes to replicate GitHub Actions foundation startup ---

# Note on Environment Variables for foundation services:
# The following recipes require OPENBAO_PKCS11_PIN, OPENBAO_PKCS11_SO_PIN, and OPENBAO_PKCS11_SLOT
# to be set in your environment. You can use a .env file (e.g., `just --dotenv-path .env foundation-startup`)
# or export them in your shell. Example .env content:
# OPENBAO_PKCS11_PIN="your_pin"
# OPENBAO_PKCS11_SO_PIN="your_so_pin"
# OPENBAO_PKCS11_SLOT="0"

# Step 1: Build specific core services
build-foundation-core:
    @echo "Building foundation services (softhsm-setup, openbao) using docker compose..."
    @docker compose -f docker-compose.yml build softhsm-setup openbao

# Step 2: Start specific core foundation services
# Depends on CockroachDB image being loaded and core services being built.
start-foundation-core: build-foundation-core load-cockroach-docker
    @echo "Starting core foundation services (softhsm-setup, openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml up -d softhsm-setup openbao cockroachdb

# Step 3: Wait and check health of core foundation services
check-foundation-core-health: start-foundation-core
    @echo "Waiting for services to initialize (initial 60-second delay)..."
    @sleep 60
    @echo "Current status of Docker services:"
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb
    @echo "--- Recent logs for OpenBao ---"
    @docker compose -f docker-compose.yml logs --tail=50 openbao
    @echo "--- Recent logs for CockroachDB ---"
    @docker compose -f docker-compose.yml logs --tail=50 cockroachdb
    @echo "Checking OpenBao health..."
    @timeout 120s bash -c \
      'until docker compose -f docker-compose.yml exec openbao curl -sf http://localhost:8200/v1/sys/health; do \
        echo "Waiting for OpenBao to be healthy (will retry)..."; \
        sleep 5; \
      done || (echo "Error: OpenBao health check failed or timed out." && exit 1)'
    @echo "OpenBao is healthy."
    @echo "Checking CockroachDB health..."
    @timeout 120s bash -c \
      'until docker compose -f docker-compose.yml exec cockroachdb /cockroach/cockroach node status --insecure --host=localhost:26257; do \
        echo "Waiting for CockroachDB to be healthy (will retry)..."; \
        sleep 5; \
      done || (echo "Error: CockroachDB health check failed or timed out." && exit 1)'
    @echo "CockroachDB is healthy."

# Main recipe to replicate the GitHub Action step for starting and checking foundation services
foundation-startup: check-foundation-core-health
    @echo "Foundation layer core services (softhsm-setup, openbao, cockroachdb) started and health checks passed."
    @echo "You can manage these services using:"
    @echo "  just foundation-status         # Show status of these core services"
    @echo "  just foundation-logs           # Tail logs from these core services"
    @echo "  just foundation-stop           # Stop these core services"
    @echo "  just down                      # Stop and remove all services"

# --- Helper recipes for managing the specific foundation services ---
foundation-status:
    @echo "Status of core foundation services:"
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb

foundation-logs:
    @echo "Tailing logs for openbao and cockroachdb. Press Ctrl+C to stop."
    @docker compose -f docker-compose.yml logs -f softhsm-setup openbao cockroachdb

foundation-stop:
    @echo "Stopping core foundation services (softhsm-setup, openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml stop softhsm-setup openbao cockroachdb
    @echo "Core foundation services stopped."

# Recipe to bring up all services including foundation, s3-generator, seaweedfs, and aria-placeholder
# This is a more comprehensive startup than just the 'foundation' ones.
start-all: load-cockroach-docker
    @echo "Building all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml build
    @echo "Starting all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml up -d

# Health check for all services that have one defined in docker-compose.yml
# This is a general check and might take a while.
check-all-health:
    @echo "Checking health of all running services with healthchecks..."
    @echo "This might take some time. Services are checked based on their docker-compose healthcheck definitions."
    @echo "Services and their status (based on docker ps --filter health=healthy/unhealthy):"
    @echo "Healthy services:"
    @docker ps --filter "health=healthy" --format "table {{{{.Names}}}}\\t{{{{.Status}}}}"
    @echo "Unhealthy or starting services:"
    @docker ps --filter "health=unhealthy" --filter "health=starting" --format "table {{{{.Names}}}}\\t{{{{.Status}}}}"
    # Add specific checks if needed, similar to foundation ones, for other critical services.
    @echo "Run 'docker compose ps' for detailed status of all services."

# Full stack startup and basic check
up-all-and-check: start-all
    @echo "Waiting for all services to initialize (e.g., 90 seconds)..."
    @sleep 90 # Adjust as needed
    @echo "--- Current status of all Docker services: ---"
    @docker compose -f docker-compose.yml ps
    @echo "--- Performing basic health checks for key services (OpenBao, CockroachDB, SeaweedFS S3) ---"
    @just check-foundation-core-health # Re-run to ensure foundation is still good
    @echo "Checking SeaweedFS S3 gateway health..."
    @timeout 60s bash -c \
      'until curl -sf http://localhost:8333; do \
        echo "Waiting for SeaweedFS S3 gateway to be healthy..."; \
        sleep 5; \
      done || (echo "Error: SeaweedFS S3 gateway health check failed or timed out." && exit 1)'
    @echo "SeaweedFS S3 gateway is responding."
    @echo "All key services checked. Review logs if any issues."
