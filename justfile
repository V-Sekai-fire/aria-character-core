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

# Depends on CockroachDB image being loaded and core services being built.
start-foundation-core: build-foundation-core load-cockroach-docker
    @echo "Starting core foundation services..."
    @echo "First, running SoftHSM setup (one-time initialization)..."
    @docker compose -f docker-compose.yml run --rm softhsm-setup
    @echo "SoftHSM setup completed. Starting persistent services (openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml up -d openbao cockroachdb

# Step 3: Wait and check health of core foundation services
check-foundation-core-health: start-foundation-core
    @echo "Waiting for core services to initialize (initial 20-second delay)..."
    @sleep 20
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb
    @echo "--- Recent logs (OpenBao) ---"
    @docker compose -f docker-compose.yml logs --tail=20 openbao
    @echo "--- Recent logs (CockroachDB) ---"
    @docker compose -f docker-compose.yml logs --tail=20 cockroachdb
    @timeout 60s bash -c \
      'until curl -sf http://localhost:8200/v1/sys/health; do \
        echo "Waiting for OpenBao health..."; \
        sleep 5; \
      done || (echo "Error: OpenBao health check failed." && exit 1)'
    @timeout 60s bash -c \
      'until curl -sf http://localhost:8080/health; do \
        echo "Waiting for CockroachDB health..."; \
        sleep 5; \
      done || (echo "Error: CockroachDB health check failed." && exit 1)'
    @echo "OpenBao and CockroachDB health checks passed."

# Main recipe to replicate the GitHub Action step for starting and checking foundation services
foundation-startup: check-foundation-core-health
    @echo "Foundation layer core services (softhsm-setup, openbao, cockroachdb) started and health checks passed."
    @echo "Extracting OpenBao root token..."
    @mkdir -p .ci
    @docker compose -f docker-compose.yml logs openbao 2>&1 | grep 'Root Token:' | awk '{print $$NF}' > .ci/openbao_root_token.txt && echo "OpenBao root token extracted to .ci/openbao_root_token.txt" || (echo "ERROR: Failed to extract OpenBao root token." && exit 1)
    @echo "You can manage these services using:"
    @echo "  just foundation-status         # Show status of these core services"
    @echo "  just foundation-logs           # Tail logs from these core services"
    @echo "  just foundation-stop           # Stop these core services"
    @echo "  just down                      # Stop and remove all services"

foundation-status:
    @echo "Status of core foundation services:"
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb

foundation-logs:
    @echo "Showing recent logs for openbao and cockroachdb..."
    @docker compose -f docker-compose.yml logs --tail=50 softhsm-setup openbao cockroachdb

foundation-stop:
    @echo "Stopping core foundation services (softhsm-setup, openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml stop softhsm-setup openbao cockroachdb
    @echo "Core foundation services stopped."

start-all: load-cockroach-docker
    @echo "Building all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml build
    @echo "Starting all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml up -d

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

install-elixir-erlang-env:
    @echo "Installing asdf in the project root..."
    @bash -c 'if [ ! -d "./.asdf" ]; then \
        echo "Cloning asdf into ./.asdf..."; \
        git clone https://github.com/asdf-vm/asdf.git ./.asdf --branch v0.14.0; \
    else \
        echo ".asdf already exists in the project root"; \
    fi'
    @echo "Sourcing asdf and setting up environment for project-specific tools..."
    @bash -c 'export ASDF_DIR="./.asdf"; \
    export PATH="./.asdf/bin:$$PATH"; \
    . ./.asdf/asdf.sh; \
    echo "Adding asdf plugins..."; \
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true; \
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true; \
    echo "Installing Erlang 26.2.5..."; \
    asdf install erlang 26.2.5; \
    echo "Installing Elixir 1.15.7-otp-26..."; \
    asdf install elixir 1.15.7-otp-26; \
    echo "Setting global versions..."; \
    asdf global erlang 26.2.5; \
    asdf global elixir 1.15.7-otp-26; \
    echo "Verification:"; \
    asdf current erlang; \
    asdf current elixir'
    @echo "asdf, Erlang and Elixir environment setup complete."

test-security-service:
    @echo "Running Security Service (AriaSecurity) tests..."
    @bash -c 'export PATH="$$HOME/.asdf/bin:$$PATH"; \
    . $$HOME/.asdf/asdf.sh || true; \
    export VAULT_ADDR="http://localhost:8200"; \
    if [ -f .ci/openbao_root_token.txt ]; then \
        export VAULT_TOKEN=`cat .ci/openbao_root_token.txt`; \
        echo "Using OpenBao token from .ci/openbao_root_token.txt"; \
    else \
        echo "No OpenBao token found, using default VAULT_ADDR only"; \
    fi; \
    if [ ! -d apps/aria_security ]; then \
        echo "ERROR: apps/aria_security directory does not exist"; \
        exit 1; \
    fi; \
    cd apps/aria_security; \
    if [ ! -f mix.exs ]; then \
        echo "ERROR: mix.exs file does not exist in apps/aria_security"; \
        exit 1; \
    fi; \
    echo "Checking Elixir version..."; \
    elixir --version || (echo "ERROR: Elixir not found" && exit 1); \
    echo "Running: mix deps.get, mix compile, mix test (in apps/aria_security)"; \
    timeout 300s mix deps.get; \
    timeout 300s mix compile --force --warnings-as-errors; \
    timeout 300s mix test'
    @echo "Security Service tests finished."
