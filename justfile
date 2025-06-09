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
    @echo "  just test-security-service-dev - Quick security tests with OpenBao dev mode"
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
test-all: test-elixir-compile test-elixir-unit test-openbao-connection test-basic-secrets
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
    @echo "Building foundation core services (openbao)..."
    @docker compose -f docker-compose.yml build openbao

# Start foundation core services
start-foundation-core: build-foundation-core
    @echo "Starting core foundation services..."
    @echo "Starting persistent services (openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml up -d openbao cockroachdb

# Check health of foundation core services
check-foundation-core-health: start-foundation-core
    @echo "Waiting for foundation core services to initialize (initial 5-second delay)..."
    @sleep 5
    @echo "Checking current status of foundation services..."
    @docker compose -f docker-compose.yml ps openbao cockroachdb
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
    @docker compose -f docker-compose.yml ps openbao cockroachdb

foundation-logs: foundation-startup
    @echo "Showing recent logs for openbao and cockroachdb..."
    @docker compose -f docker-compose.yml logs --tail=50 openbao cockroachdb

foundation-stop:
    @echo "Stopping core foundation services (openbao, cockroachdb)..."
    @docker compose -f docker-compose.yml stop openbao cockroachdb
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

# === SIMPLE, FOCUSED TESTS ===

# Test 1: Basic Elixir compilation for all apps
test-elixir-compile: install-elixir-erlang-env
    #!/usr/bin/env bash
    echo "🔨 Testing Elixir compilation for all apps..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:${PATH}"
    . ./.asdf/asdf.sh || true
    
    echo "📦 Getting dependencies..."
    mix deps.get || (echo "❌ Failed to get dependencies" && exit 1)
    
    echo "🔨 Compiling all apps..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "✅ All apps compiled successfully!"

# Test 2: Run unit tests for Elixir apps (no external dependencies)
test-elixir-unit: foundation-startup test-elixir-compile
    #!/usr/bin/env bash
    echo "🧪 Running unit tests for all Elixir apps..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:${PATH}"
    . ./.asdf/asdf.sh || true
    
    echo "🧪 Running ExUnit tests..."
    mix test --exclude external_deps || (echo "❌ Unit tests failed" && exit 1)
    
    echo "✅ All unit tests passed!"

# Test 3: Test OpenBao connection (basic connectivity only)
test-openbao-connection: start-foundation-core
    #!/usr/bin/env bash
    echo "🔐 Testing basic OpenBao connection..."
    export VAULT_ADDR="http://localhost:8200"
    
    echo "⏳ Waiting for OpenBao to be ready..."
    timeout 30s bash -c 'until curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done' || (echo "❌ OpenBao not ready" && exit 1)
    
    echo "🔍 Checking OpenBao health..."
    curl -sf "$VAULT_ADDR/v1/sys/health" > /dev/null || (echo "❌ OpenBao health check failed" && exit 1)
    
    echo "✅ OpenBao connection test passed!"

# Test 4: Test basic secret operations (requires OpenBao)
test-basic-secrets: test-openbao-connection
    #!/usr/bin/env bash
    echo "🔑 Testing basic secret operations..."
    export VAULT_ADDR="http://localhost:8200"
    
    # Get token from container storage or initialize if needed
    get_vault_token() {
        # Try container storage first
        TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
        if [ -n "$TOKEN" ]; then
            echo "$TOKEN"
            return 0
        fi
        
        # Check if initialized
        INIT_STATUS=$(curl -sf "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        if echo "$INIT_STATUS" | grep -q '"initialized":false'; then
            echo "🔧 Initializing OpenBao..."
            INIT_RESPONSE=$(curl -sf -X POST -d '{"secret_shares":1,"secret_threshold":1}' "$VAULT_ADDR/v1/sys/init" 2>/dev/null)
            NEW_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
            if [ -n "$NEW_TOKEN" ]; then
                docker exec aria-character-core-openbao-1 bash -c "mkdir -p /vault/data && echo '$NEW_TOKEN' > /vault/data/root_token.txt" 2>/dev/null || true
                echo "$NEW_TOKEN"
                return 0
            fi
        fi
        
        echo "root"  # fallback
    }
    
    VAULT_TOKEN=$(get_vault_token)
    export VAULT_TOKEN
    echo "🔑 Using token: $VAULT_TOKEN"
    
    # Test basic secret write/read
    echo "📝 Testing secret write..."
    curl -sf -H "X-Vault-Token: $VAULT_TOKEN" \
         -H "Content-Type: application/json" \
         -X POST \
         -d '{"data":{"test":"value123"}}' \
         "$VAULT_ADDR/v1/secret/data/test-basic" > /dev/null || (echo "❌ Secret write failed" && exit 1)
    
    echo "📖 Testing secret read..."
    RESPONSE=$(curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/test-basic")
    if echo "$RESPONSE" | grep -q "value123"; then
        echo "✅ Basic secret operations test passed!"
    else
        echo "❌ Secret read failed or content mismatch"
        exit 1
    fi

# Test 5: Test individual app - aria_security
test-aria-security: test-elixir-compile
    #!/usr/bin/env bash
    echo "🛡️  Testing aria_security app specifically..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:${PATH}"
    . ./.asdf/asdf.sh || true
    
    if [ ! -d apps/aria_security ]; then
        echo "❌ aria_security app not found"
        exit 1
    fi
    
    cd apps/aria_security
    echo "📦 Getting dependencies for aria_security..."
    mix deps.get || (echo "❌ Failed to get deps" && exit 1)
    
    echo "🔨 Compiling aria_security..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "🧪 Running aria_security tests..."
    mix test --exclude external_deps || (echo "❌ Tests failed" && exit 1)
    
    cd ../..
    echo "✅ aria_security tests passed!"

# Test 6: Test individual app - aria_auth  
test-aria-auth: test-elixir-compile
    #!/usr/bin/env bash
    echo "🔐 Testing aria_auth app specifically..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:${PATH}"
    . ./.asdf/asdf.sh || true
    
    if [ ! -d apps/aria_auth ]; then
        echo "❌ aria_auth app not found"
        exit 1
    fi
    
    cd apps/aria_auth
    echo "📦 Getting dependencies for aria_auth..."
    mix deps.get || (echo "❌ Failed to get deps" && exit 1)
    
    echo "🔨 Compiling aria_auth..."
    mix compile --force --warnings-as-errors || (echo "❌ Compilation failed" && exit 1)
    
    echo "🧪 Running aria_auth tests..."
    mix test --exclude external_deps || (echo "❌ Tests failed" && exit 1)
    
    cd ../..
    echo "✅ aria_auth tests passed!"

# Legacy complex test (kept for reference, but not used in main workflow)
test-security-service-legacy: install-elixir-erlang-env start-foundation-core
    #!/usr/bin/env bash
    echo "🧪 Running comprehensive Security Service tests including SoftHSM rekey and destroy operations..."
    export ASDF_DIR="./.asdf"
    export PATH="./.asdf/bin:/usr/bin:/bin:/sbin:/usr/sbin:${PATH}"
    . ./.asdf/asdf.sh || true
    export VAULT_ADDR="http://localhost:8200"
    
    # Function to get OpenBao token
    get_openbao_token() {
        # Try to get the root token from container storage (HSM-sealed OpenBao)
        echo "🔑 Extracting OpenBao token from container storage..."
        PERSISTENT_TOKEN=$(docker exec aria-character-core-openbao-1 cat /vault/data/root_token.txt 2>/dev/null || echo "")
        
        if [ -n "$PERSISTENT_TOKEN" ]; then
            export VAULT_TOKEN="$PERSISTENT_TOKEN"
            echo "✅ Using OpenBao token from container storage: $VAULT_TOKEN"
        elif [ -f .ci/openbao_root_token.txt ]; then
            echo "🔍 Container token not found, trying token file..."
            TOKEN_FROM_FILE=$(grep "Root Token:" .ci/openbao_root_token.txt | head -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r')
            if [ -n "$TOKEN_FROM_FILE" ]; then
                export VAULT_TOKEN="$TOKEN_FROM_FILE"
                echo "✅ Using OpenBao token from file: $VAULT_TOKEN"
            else
                echo "⚠️  WARNING: Using fallback token"
                export VAULT_TOKEN="root"
            fi
        else
            # Fallback to extracting from logs
            echo "🔍 No persistent token sources found, trying container logs..."
            LIVE_TOKEN=$(docker logs aria-character-core-openbao-1 | grep "Root Token:" | tail -1 | sed 's/.*Root Token: //' | tr -d ' \t\n\r' || echo "")
            if [ -n "$LIVE_TOKEN" ]; then
                export VAULT_TOKEN="$LIVE_TOKEN"
                echo "✅ Using OpenBao token from logs: $VAULT_TOKEN"
            else
                echo "⚠️  WARNING: No token sources found, using fallback"
                export VAULT_TOKEN="root"
            fi
        fi
    }
    
    # Function to check if OpenBao is initialized
    check_openbao_initialization() {
        echo "🔍 Checking OpenBao initialization status..."
        INIT_STATUS=$(curl -sf "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        if [ -n "$INIT_STATUS" ]; then
            INITIALIZED=$(echo "$INIT_STATUS" | grep -o '"initialized":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            if [ "$INITIALIZED" = "true" ]; then
                echo "✅ OpenBao is already initialized"
                return 0
            else
                echo "⚠️  OpenBao is not initialized"
                return 1
            fi
        else
            echo "❌ Cannot check OpenBao initialization status"
            return 1
        fi
    }
    
    # Function to initialize OpenBao if not already initialized
    initialize_openbao() {
        echo "🔧 Initializing OpenBao..."
        
        # Initialize OpenBao with HSM seal (auto-unseal)
        INIT_RESPONSE=$(curl -sf -X POST -d '{"secret_shares":1,"secret_threshold":1}' "$VAULT_ADDR/v1/sys/init" 2>/dev/null || echo "")
        
        if [ -n "$INIT_RESPONSE" ]; then
            # Extract root token from response
            NEW_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$NEW_TOKEN" ]; then
                echo "✅ OpenBao initialized successfully"
                echo "🔑 Root token: $NEW_TOKEN"
                
                # Store token in container and file
                docker exec aria-character-core-openbao-1 bash -c "mkdir -p /vault/data && echo '$NEW_TOKEN' > /vault/data/root_token.txt" 2>/dev/null || true
                mkdir -p .ci
                echo "openbao-1  | Root Token: $NEW_TOKEN" > .ci/openbao_root_token.txt
                echo "openbao-1  | Seal Type: HSM (SoftHSM PKCS#11)" >> .ci/openbao_root_token.txt
                
                export VAULT_TOKEN="$NEW_TOKEN"
                return 0
            else
                echo "❌ Failed to extract root token from initialization response"
                return 1
            fi
        else
            echo "❌ Failed to initialize OpenBao"
            return 1
        fi
    }
    
    # Function to verify OpenBao connection
    verify_openbao_connection() {
        echo "🔐 Verifying OpenBao connection..."
        if curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" > /dev/null; then
            echo "✅ OpenBao connection verified successfully"
            return 0
        else
            echo "❌ ERROR: Cannot connect to OpenBao at $VAULT_ADDR with token $VAULT_TOKEN"
            return 1
        fi
    }
    
    # Function to run basic security tests
    run_basic_security_tests() {
        echo "🧪 Running basic security service tests..."
        
        if [ ! -d apps/aria_security ]; then
            echo "❌ ERROR: apps/aria_security directory does not exist"
            return 1
        fi
        
        cd apps/aria_security
        if [ ! -f mix.exs ]; then
            echo "❌ ERROR: mix.exs file does not exist in apps/aria_security"
            return 1
        fi
        
        echo "🔍 Checking Elixir version..."
        bash -l -c "elixir --version" || (echo "❌ ERROR: Elixir not found" && return 1)
        
        echo "📦 Running: mix deps.get, mix compile, mix test (in apps/aria_security)"
        bash -l -c "mix deps.get" && \
        bash -l -c "mix compile --force --warnings-as-errors" && \
        bash -l -c "mix test"
        
        if [ $? -eq 0 ]; then
            echo "✅ Basic security service tests passed"
            cd ../..
            return 0
        else
            echo "❌ Basic security service tests failed"
            cd ../..
            return 1
        fi
    }
    
    # Function to test SoftHSM rekey functionality
    test_softhsm_rekey() {
        echo "🔄 Testing SoftHSM rekey functionality..."
        
        # Store original state for comparison
        echo "📊 Capturing initial SoftHSM state..."
        INITIAL_SLOTS=$(docker exec aria-character-core-openbao-1 softhsm2-util --show-slots 2>/dev/null || echo "No slots available")
        echo "Initial slots: $INITIAL_SLOTS"
        
        # Test rekey operation (without waiting for user input)
        echo "🔑 Testing SoftHSM rekey operation..."
        docker compose -f docker-compose.yml stop openbao || true
        docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
        # With merged container, just restart OpenBao (which reinitializes SoftHSM internally)
        docker compose -f docker-compose.yml up -d openbao
        
        if [ $? -eq 0 ]; then
            echo "✅ SoftHSM rekey operation completed successfully"
            
            # Restart foundation services after rekey
            echo "🔄 Restarting foundation services after rekey..."
            just foundation-startup
            sleep 10  # Give services time to start
            
            # Verify new SoftHSM state
            echo "📊 Capturing post-rekey SoftHSM state..."
            NEW_SLOTS=$(docker exec aria-character-core-openbao-1 softhsm2-util --show-slots 2>/dev/null || echo "No slots available")
            echo "New slots: $NEW_SLOTS"
            
            return 0
        else
            echo "❌ SoftHSM rekey operation failed"
            return 1
        fi
    }
    
    # Function to test destroy and recovery
    test_destroy_and_recovery() {
        echo "💥 Testing destroy and recovery functionality..."
        
        # Test destroy operation (without waiting for user input)
        echo "🗑️  Testing destroy operation..."
        docker compose -f docker-compose.yml stop openbao || true
        docker compose -f docker-compose.yml rm -f openbao || true
        docker volume rm aria-character-core_openbao_data 2>/dev/null || true
        docker volume rm aria-character-core_openbao_config 2>/dev/null || true
        docker volume rm aria-character-core_softhsm_tokens 2>/dev/null || true
        rm -f .ci/openbao_root_token.txt
        
        if [ $? -eq 0 ]; then
            echo "✅ Destroy operation completed successfully"
            
            # Test recovery
            echo "🔄 Testing recovery after destroy..."
            just foundation-startup
            sleep 15  # Give services time to initialize completely
            
            # Get new token after recovery
            get_openbao_token
            
            if verify_openbao_connection; then
                echo "✅ Recovery after destroy completed successfully"
                return 0
            else
                echo "❌ Recovery after destroy failed"
                return 1
            fi
        else
            echo "❌ Destroy operation failed"
            return 1
        fi
    }
    
    # Main test execution
    echo "🚀 Starting comprehensive security service tests..."
    
    # Check if OpenBao is initialized first
    echo ""
    echo "=== INITIALIZATION CHECK ==="
    echo "🔍 Checking if OpenBao is ready and initialized..."
    
    # Check if OpenBao API is ready
    if curl -sf http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
        echo "✅ OpenBao API is ready"
        
        # Check initialization status
        if ! check_openbao_initialization; then
            echo "🔧 OpenBao ready but not initialized, performing initialization..."
            if ! initialize_openbao; then
                echo "❌ Failed to initialize OpenBao, aborting"
                exit 1
            fi
        fi
    else
        echo "❌ OpenBao API is not ready yet, aborting"
        exit 1
    fi
    
    # Test 1: Basic functionality
    echo ""
    echo "=== TEST 1: Basic Security Service Functionality ==="
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Initial connection test failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Basic security tests failed, aborting"
        exit 1
    fi
    
    # Test 2: SoftHSM Rekey functionality
    echo ""
    echo "=== TEST 2: SoftHSM Rekey Functionality ==="
    if ! test_softhsm_rekey; then
        echo "❌ SoftHSM rekey test failed, aborting"
        exit 1
    fi
    
    # Get token after rekey and verify basic tests still work
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Connection test after rekey failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Security tests after rekey failed, aborting"
        exit 1
    fi
    
    # Test 3: Destroy and recovery functionality
    echo ""
    echo "=== TEST 3: Destroy and Recovery Functionality ==="
    if ! test_destroy_and_recovery; then
        echo "❌ Destroy and recovery test failed, aborting"
        exit 1
    fi
    
    # Final verification after recovery
    get_openbao_token
    if ! verify_openbao_connection; then
        echo "❌ Final connection test failed, aborting"
        exit 1
    fi
    
    if ! run_basic_security_tests; then
        echo "❌ Final security tests failed, aborting"
        exit 1
    fi
    
    echo ""
    echo "🎉 All security service tests completed successfully!"
    echo "✅ Basic functionality: PASSED"
    echo "✅ SoftHSM rekey: PASSED"
    echo "✅ Destroy and recovery: PASSED"
    echo "✅ Post-operation functionality: PASSED"

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
    docker compose -f docker-compose.yml stop openbao || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao || true
    
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
    docker compose -f docker-compose.yml stop openbao || true
    
    # Remove containers
    echo "🗑️  Removing containers..."
    docker compose -f docker-compose.yml rm -f openbao || true
    
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
    
    echo "🔄 Restarting OpenBao (which reinitializes SoftHSM internally)..."
    docker compose -f docker-compose.yml up -d openbao
    
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
    
    echo "🔄 Restarting OpenBao (which reinitializes SoftHSM internally)..."
    docker compose -f docker-compose.yml up -d openbao
    
    echo "✅ SoftHSM tokens regenerated successfully!"
    echo "⚠️  IMPORTANT: OpenBao must be reinitialized since HSM keys changed"
    echo "📝 Run 'just destroy-bao' then 'just foundation-startup' to reinitialize OpenBao"
