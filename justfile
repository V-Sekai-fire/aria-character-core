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
dev-setup: install-elixir-erlang-env foundation-startup
    @echo "Development environment setup complete!"

# Testing workflow entry point  
test-all: test-security-service
    @echo "All tests completed!"

# Production deployment workflow
prod-deploy: up-all-and-check
    @echo "Production deployment complete!"

# Status check workflow
status: foundation-status
    @echo "Status check complete!"

# Clean up workflow
clean: down foundation-stop
    @echo "Cleanup complete!"

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
check-foundation-core-health: start-foundation-core
    @echo "Waiting for foundation core services to initialize (initial 10-second delay)..."
    @sleep 10
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

foundation-status: foundation-startup
    @echo "Status of core foundation services:"
    @docker compose -f docker-compose.yml ps softhsm-setup openbao cockroachdb

foundation-logs: foundation-startup
    @echo "Showing recent logs for openbao and cockroachdb..."
    @docker compose -f docker-compose.yml logs --tail=50 softhsm-setup openbao cockroachdb

foundation-stop:
    @echo "Stopping core foundation services (softhsm-setup, openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml stop softhsm-setup openbao cockroachdb
    @echo "Core foundation services stopped."

start-all: build
    @docker compose -f docker-compose.yml up -d

check-all-health: up-all-and-check
    @echo "Checking health of all running services with healthchecks..."
    @echo "This might take some time. Services are checked based on their docker-compose healthcheck definitions."
    @echo "Services and their status (based on docker ps --filter health=healthy/unhealthy):"
    @echo "Healthy services:"
    @docker ps --filter "health=healthy" --format "table {{{{.Names}}}}\\t{{{{.Status}}}}"
    @echo "Unhealthy or starting services:"
    @docker ps --filter "health=unhealthy" --filter "health=starting" --format "table {{{{.Names}}}}\\t{{{{.Status}}}}"
    # Add specific checks if needed, similar to foundation ones, for other critical services.
    @echo "Run 'docker compose ps' for detailed status of all services."

up-all-and-check: start-all check-foundation-core-health
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
    if [ ! -d "./.asdf" ]; then
        echo "Cloning asdf into ./.asdf..."
        git clone https://github.com/asdf-vm/asdf.git ./.asdf --branch v0.14.0
    else
        echo ".asdf already exists in the project root"
    fi
    echo "Sourcing asdf and setting up environment for project-specific tools..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:${PATH}"
    . ./.asdf/asdf.sh
    echo "Adding asdf plugins..."
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || true
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || true
    echo "Installing Erlang and Elixir versions (as per .tool-versions)..."
    asdf install

test-security-service: install-elixir-erlang-env foundation-startup
    #!/usr/bin/env bash
    echo "Running Security Service (AriaSecurity) tests..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    . ./.asdf/asdf.sh || true
    export VAULT_ADDR="http://localhost:8200"
    
    # Try to get the root token from container storage (HSM-sealed OpenBao)
    echo "Extracting OpenBao token from container storage..."
    PERSISTENT_TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
    
    if [ -n "$PERSISTENT_TOKEN" ]; then
        export VAULT_TOKEN="$PERSISTENT_TOKEN"
        echo "Using OpenBao token from container storage: $VAULT_TOKEN"
    elif [ -f .ci/openbao_root_token.txt ]; then
        echo "Container token not found, trying token file..."
        TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
        if [ -n "$TOKEN_FROM_FILE" ]; then
            export VAULT_TOKEN="$TOKEN_FROM_FILE"
            echo "Using OpenBao token from file: $VAULT_TOKEN"
        else
            echo "WARNING: Using fallback token"
            export VAULT_TOKEN="root"
        fi
    else
        echo "WARNING: No token sources found, using fallback"
        export VAULT_TOKEN="root"
    fi
    
    echo "Verifying OpenBao connection..."
    curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" > /dev/null || \
    (echo "ERROR: Cannot connect to OpenBao at $VAULT_ADDR with token $VAULT_TOKEN" && exit 1)
    
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
    bash -l -c "elixir --version" || (echo "ERROR: Elixir not found" && exit 1)
    echo "Running: mix deps.get, mix compile, mix test (in apps/aria_security)"
    bash -l -c "mix deps.get" && \
    bash -l -c "mix compile --force --warnings-as-errors" && \
    bash -l -c "mix test"
    echo "Security Service tests finished."
    export PATH="./.asdf/bin:/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    . ./.asdf/asdf.sh || true
    export VAULT_ADDR="http://localhost:8200"
    
    # Try to get the persistent token from container storage first
    echo "Extracting OpenBao token from container storage..."
    PERSISTENT_TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
    
    if [ -n "$PERSISTENT_TOKEN" ]; then
        export VAULT_TOKEN="$PERSISTENT_TOKEN"
        echo "Using OpenBao token from container storage: $VAULT_TOKEN"
    elif [ -f .ci/openbao_root_token.txt ]; then
        echo "Container token not found, trying token file..."
        TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
        if [ -n "$TOKEN_FROM_FILE" ]; then
            export VAULT_TOKEN="$TOKEN_FROM_FILE"
            echo "Using OpenBao token from file: $VAULT_TOKEN"
        else
            echo "WARNING: Using fallback token"
            export VAULT_TOKEN="root"
        fi
    else
        # Fallback to extracting from logs
        echo "No persistent token sources found, trying container logs..."
        LIVE_TOKEN=$(docker logs aria-character-core-openbao-1 | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' || echo "")
        if [ -n "$LIVE_TOKEN" ]; then
            export VAULT_TOKEN="$LIVE_TOKEN"
            echo "Using OpenBao token from logs: $VAULT_TOKEN"
        else
            echo "WARNING: No token sources found, using fallback"
            export VAULT_TOKEN="root"
        fi
    fi
    
    echo "Verifying OpenBao connection..."
    curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" > /dev/null || \
    (echo "ERROR: Cannot connect to OpenBao at $VAULT_ADDR with token $VAULT_TOKEN" && exit 1)
    
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
    bash -l -c "elixir --version" || (echo "ERROR: Elixir not found" && exit 1)
    echo "Running: mix deps.get, mix compile, mix test (in apps/aria_security)"
    bash -l -c "mix deps.get" && \
    bash -l -c "mix compile --force --warnings-as-errors" && \
    bash -l -c "mix test"
    echo "Security Service tests finished."

# Generate a new varying root token for OpenBao
generate-new-root-token: foundation-startup
    #!/usr/bin/env bash
    echo "Generating a new varying root token for OpenBao..."
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    
    # Get the current token to use for authentication
    CURRENT_TOKEN=""
    
    # Try to get token from container's persistent storage first
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
    
    echo "Using current token for authentication: $CURRENT_TOKEN"
    
    # Generate new root token
    echo "🔄 Generating new root token..."
    docker exec -e BAO_ADDR="$BAO_ADDR" -e VAULT_TOKEN="$CURRENT_TOKEN" aria-character-core-openbao-1 bao token create -policy=root -format=json > /tmp/new_token_response
    NEW_TOKEN=$(cat /tmp/new_token_response | grep '"token"' | cut -d'"' -f4)
    
    if [ -n "$NEW_TOKEN" ]; then
        echo "✅ Generated new root token: $NEW_TOKEN"
        
        # Update container's token file
        docker exec aria-character-core-openbao-1 bash -c "echo '$NEW_TOKEN' > /vault/data/root_token.txt"
        
        # Update the token file (no unseal keys with HSM seal)
        echo "openbao-1  | Root Token: $NEW_TOKEN" > .ci/openbao_root_token.txt
        echo "openbao-1  | Seal Type: HSM (SoftHSM PKCS#11)" >> .ci/openbao_root_token.txt
        
        echo "📝 Token file updated with new varying root token"
        echo "🔑 New token: $NEW_TOKEN"
        echo "🔐 Seal keys are securely stored in SoftHSM"
        
        # Clean up temp files
        rm -f /tmp/new_token_response
    else
        echo "❌ ERROR: Failed to generate new root token"
        exit 1
    fi
    #!/usr/bin/env bash
    echo "Generating a new varying root token for OpenBao..."
    export BAO_ADDR="http://localhost:8200"
    export PATH="/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    
    # First, get the current token to use for authentication
    CURRENT_TOKEN=""
    
    # Try to get token from container's persistent storage first
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
    
    echo "Using current token for authentication: $CURRENT_TOKEN"
    
    # Generate new root token
    echo "🔄 Generating new root token..."
    docker exec -e BAO_ADDR="$BAO_ADDR" -e VAULT_TOKEN="$CURRENT_TOKEN" aria-character-core-openbao-1 bao token create -policy=root -format=json > /tmp/new_token_response
    NEW_TOKEN=$(cat /tmp/new_token_response | grep '"token"' | cut -d'"' -f4)
    
    if [ -n "$NEW_TOKEN" ]; then
        echo "✅ Generated new root token: $NEW_TOKEN"
        
        # Update container's token file
        docker exec aria-character-core-openbao-1 bash -c "echo '$NEW_TOKEN' > /vault/data/root_token.txt"
        
        # Update the token file with new token, preserving unseal key
        UNSEAL_KEY=$(docker exec aria-character-core-openbao-1 cat /vault/data/unseal_key.txt 2>/dev/null || echo "")
        
        echo "openbao-1  | Root Token: $NEW_TOKEN" > .ci/openbao_root_token.txt
        if [ -n "$UNSEAL_KEY" ]; then
            echo "openbao-1  | Unseal Key: $UNSEAL_KEY" >> .ci/openbao_root_token.txt
        fi
        
        echo "📝 Token file updated with new varying root token"
        echo "🔑 New token: $NEW_TOKEN"
        
        # Clean up temp files
        rm -f /tmp/new_token_response
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
    docker compose -f docker-compose.yml stop openbao softhsm-setup || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao softhsm-setup || true
    
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
    docker compose -f docker-compose.yml stop openbao softhsm-setup || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao softhsm-setup || true
    
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
    
    echo "🔄 Recreating SoftHSM tokens..."
    docker compose -f docker-compose.yml run --rm softhsm-setup
    
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
    
    echo "🔄 Recreating SoftHSM tokens..."
    docker compose -f docker-compose.yml run --rm softhsm-setup
    
    echo "✅ SoftHSM tokens regenerated successfully!"
    echo "⚠️  IMPORTANT: OpenBao must be reinitialized since HSM keys changed"
    echo "📝 Run 'just destroy-bao' then 'just foundation-startup' to reinitialize OpenBao"
