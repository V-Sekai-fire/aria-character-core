# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

download-cockroach-tar:
    @echo "Downloading CockroachDB tarball..."
    @curl -L -o cockroachdb.tar https://github.com/V-Sekai/cockroach/releases/download/cockroach-2/cockroachdb.tar
    @echo "Download complete: cockroachdb.tar"

load-cockroach-docker:
    @echo "Loading CockroachDB image..."
    @if [ ! -f cockroachdb.tar ]; then \
        echo "CockroachDB tar file not found, downloading..."; \
        just download-cockroach-tar; \
    fi
    @echo "Loading CockroachDB image from tar file..."
    @docker load -i cockroachdb.tar
    @echo "CockroachDB image loaded successfully"

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

# Build all services
build:
    @echo "Building all services defined in docker-compose.yml..."
    @docker compose -f docker-compose.yml build

# Build only foundation core services
build-foundation-core: load-cockroach-docker
    @echo "Building foundation core services (softhsm-setup, openbao)..."
    @docker compose -f docker-compose.yml build softhsm-setup openbao

# Start foundation core services
start-foundation-core: build-foundation-core
    @echo "Starting core foundation services..."
    @echo "First, running SoftHSM setup (one-time initialization)..."
    @docker compose -f docker-compose.yml run --rm softhsm-setup
    @echo "SoftHSM setup completed. Starting persistent services (openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml up -d openbao cockroachdb

# Check health of foundation core services
check-foundation-core-health:
    @echo "Waiting for foundation core services to initialize (initial 20-second delay)..."
    @sleep 20
    @echo "Checking current status of foundation services..."
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb
    @echo "--- Recent logs (OpenBao) ---"
    @docker compose -f docker-compose.yml logs --tail=20 openbao
    @echo "--- Recent logs (CockroachDB) ---"
    @docker compose -f docker-compose.yml logs --tail=20 cockroachdb
    @echo "Checking OpenBao health..."
    @curl -sf http://localhost:8200/v1/sys/health > /dev/null && echo "OpenBao is healthy" || (echo "Error: OpenBao health check failed." && exit 1)
    @echo "Checking CockroachDB health..."
    @curl -sf http://localhost:8080/health > /dev/null && echo "CockroachDB is healthy" || (echo "Error: CockroachDB health check failed." && exit 1)
    @echo "OpenBao and CockroachDB health checks passed."

# Foundation startup: build, start, and check health
foundation-startup: start-foundation-core check-foundation-core-health
    @echo "Foundation startup completed."

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

start-all: build
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
    #!/usr/bin/env bash
    @echo "Installing asdf in the project root..."
    @if [ ! -d "./.asdf" ]; then \
        echo "Cloning asdf into ./.asdf..."; \
        git clone https://github.com/asdf-vm/asdf.git ./.asdf --branch v0.14.0; \
    else \
        echo ".asdf already exists in the project root"; \
    fi
    @echo "Sourcing asdf and setting up environment for project-specific tools..."
    @export ASDF_DIR="./.asdf"; \
    export PATH="./.asdf/bin:${PATH}"; \
    . ./.asdf/asdf.sh; \
    echo "Adding asdf plugins..."; \
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true; \
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true; \
    echo "Installing Erlang and Elixir versions (as per .tool-versions)..."
    asdf install

test-security-service: foundation-startup
    #!/usr/bin/env bash
    echo "Running Security Service (AriaSecurity) tests..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:/usr/bin:/bin:/sbin:/usr/sbin:$${PATH}"
    . ./.asdf/asdf.sh || true
    export VAULT_ADDR="http://localhost:8200"
    
    # Extract the root token dynamically from OpenBao logs or token file
    if [ -f .ci/openbao_root_token.txt ]; then
        TOKEN_FROM_FILE=`grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r'`
        if [ -n "$$TOKEN_FROM_FILE" ]; then
            export VAULT_TOKEN="$$TOKEN_FROM_FILE"
            echo "Using OpenBao token from file: $$VAULT_TOKEN"
        else
            echo "Could not extract token from file, checking OpenBao logs..."
            LIVE_TOKEN=`docker compose logs openbao 2>/dev/null | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' || echo ""`
            if [ -n "$$LIVE_TOKEN" ]; then
                export VAULT_TOKEN="$$LIVE_TOKEN"
                echo "Using OpenBao token from logs: $$VAULT_TOKEN"
            else
                echo "WARNING: Could not extract token, using fallback"
                export VAULT_TOKEN="root"
            fi
        fi
    else
        echo "Token file not found, checking OpenBao logs..."
        LIVE_TOKEN=`docker compose logs openbao 2>/dev/null | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' || echo ""`
        if [ -n "$$LIVE_TOKEN" ]; then
            export VAULT_TOKEN="$$LIVE_TOKEN"
            echo "Using OpenBao token from logs: $$VAULT_TOKEN"
        else
            echo "WARNING: Could not extract token, using fallback"
            export VAULT_TOKEN="root"
        fi
    fi
    
    echo "Verifying OpenBao connection..."
    curl -sf -H "X-Vault-Token: $$VAULT_TOKEN" "$$VAULT_ADDR/v1/sys/health" > /dev/null || \
    (echo "ERROR: Cannot connect to OpenBao at $$VAULT_ADDR with token $$VAULT_TOKEN" && exit 1)
    
    if [ ! -d apps/aria_security ]; then
        echo "ERROR: apps/aria_security directory does not exist"
        exit 1
    fi
    cd apps/aria_security
    if [ ! -f mix.exs ]; then
        echo "ERROR: mix.exs file does not exist in apps/aria_security"
        exit 1
    fi
    echo "Checking Elixir version..."
    elixir --version || (echo "ERROR: Elixir not found" && exit 1)
    echo "Running: mix deps.get, mix compile, mix test (in apps/aria_security)"
    mix deps.get && \
    mix compile --force --warnings-as-errors && \
    mix test
    echo "Security Service tests finished."

# Generate a new varying root token for OpenBao
generate-new-root-token:
    #!/usr/bin/env bash
    echo "Generating a new varying root token for OpenBao..."
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:$$PATH"
    
    # First, get the current token to use for authentication
    CURRENT_TOKEN=""
    if [ -f .ci/openbao_root_token.txt ]; then
        grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' > /tmp/current_token
        CURRENT_TOKEN=`cat /tmp/current_token`
    fi
    
    if [ -z "$$CURRENT_TOKEN" ]; then
        echo "Getting token from OpenBao logs..."
        docker compose logs openbao 2>/dev/null | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' > /tmp/current_token || echo "root" > /tmp/current_token
        CURRENT_TOKEN=`cat /tmp/current_token`
    fi
    
    echo "Using current token for authentication: $$CURRENT_TOKEN"
    
    # Generate new root token
    docker exec -e BAO_ADDR="$$BAO_ADDR" -e VAULT_TOKEN="$$CURRENT_TOKEN" aria-character-core-openbao-1 bao token create -policy=root -format=json > /tmp/new_token_response
    NEW_TOKEN=`cat /tmp/new_token_response | grep '"token"' | cut -d'"' -f4`
    
    if [ -n "$$NEW_TOKEN" ]; then
        echo "Generated new root token: $$NEW_TOKEN"
        
        # Update the token file with new token, preserving unseal key
        grep "Unseal Key:" .ci/openbao_root_token.txt | sed 's/.*Unseal Key: //' | tr -d ' \t\n\r' > /tmp/unseal_key || echo "" > /tmp/unseal_key
        UNSEAL_KEY=`cat /tmp/unseal_key`
        
        echo "openbao-1  | Root Token: $$NEW_TOKEN" > .ci/openbao_root_token.txt
        if [ -n "$$UNSEAL_KEY" ]; then
            echo "openbao-1  | Unseal Key: $$UNSEAL_KEY" >> .ci/openbao_root_token.txt
        fi
        
        echo "Token file updated with new varying root token"
        echo "New token: $$NEW_TOKEN"
        
        # Clean up temp files
        rm -f /tmp/current_token /tmp/new_token_response /tmp/unseal_key
    else
        echo "ERROR: Failed to generate new root token"
        exit 1
    fi
