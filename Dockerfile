# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Multi-stage Dockerfile for Aria Character Core with integrated OpenBao and SoftHSM

# Build stage
FROM hexpm/elixir:1.16.3-erlang-26.2.5-alpine-3.19.1 AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    curl \
    wget \
    bash \
    openssl-dev \
    pcsc-lite-dev \
    automake \
    autoconf \
    libtool \
    pkgconfig

# Install SoftHSM2 from Alpine package
RUN apk add --no-cache softhsm

# Set up working directory
WORKDIR /app

# Copy mix files for dependency resolution
COPY mix.exs mix.lock ./

# Copy individual app mix.exs files to preserve Docker cache layers
COPY apps/aria_auth/mix.exs apps/aria_auth/
COPY apps/aria_coordinate/mix.exs apps/aria_coordinate/
COPY apps/aria_data/mix.exs apps/aria_data/
COPY apps/aria_debugger/mix.exs apps/aria_debugger/
COPY apps/aria_engine/mix.exs apps/aria_engine/
COPY apps/aria_interface/mix.exs apps/aria_interface/
COPY apps/aria_interpret/mix.exs apps/aria_interpret/
COPY apps/aria_monitor/mix.exs apps/aria_monitor/
COPY apps/aria_queue/mix.exs apps/aria_queue/
COPY apps/aria_security/mix.exs apps/aria_security/
COPY apps/aria_shape/mix.exs apps/aria_shape/
COPY apps/aria_storage/mix.exs apps/aria_storage/
COPY apps/aria_tune/mix.exs apps/aria_tune/
COPY apps/aria_workflow/mix.exs apps/aria_workflow/

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
ENV MIX_ENV=prod
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source code
COPY . .

# Compile the application
RUN mix compile

# Build release
RUN mix release

# Runtime stage
FROM quay.io/openbao/openbao:2.2.2 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    openssl \
    ncurses \
    sqlite \
    botan \
    pcsc-lite \
    opensc \
    ca-certificates \
    dumb-init \
    rust \
    cargo \
    su-exec

# Install SoftHSM2 from Alpine package
RUN apk add --no-cache softhsm

# Create application user (avoiding conflicts with existing groups)
RUN addgroup -g 1001 aria && \
    adduser -u 1001 -G aria -s /bin/bash -D aria

# Create necessary directories
RUN mkdir -p /app && \
    chown -R aria:aria /app

# Set environment variables
ENV SOFTHSM2_CONF=/etc/softhsm2.conf
ENV MIX_ENV=prod
ENV REPLACE_OS_VARS=true
ENV VAULT_ADDR=http://localhost:8200
ENV PHX_SERVER=true

# Copy built application from builder stage
COPY --from=builder --chown=aria:aria /app/_build/prod/rel/aria_character_core /app/

# Copy OpenBao configuration
COPY --chown=aria:aria docker_openbao/vault-config.hcl /vault/config/
COPY --chown=aria:aria docker_openbao/vault-dev-persistent.hcl /vault/config/

# Create initialization and startup script
COPY --chown=aria:aria --chmod=755 <<'EOF' /app/entrypoint.sh
#!/bin/bash
set -e

echo "🚀 Starting Aria Character Core with integrated OpenBao and SoftHSM..."

# Function to initialize SoftHSM
init_softhsm() {
    echo "🔐 Initializing SoftHSM..."
    
    # Clean up any existing tokens first
    rm -rf /var/lib/softhsm/tokens/*
    
    # Create fresh token with automatic slot assignment
    INIT_OUTPUT=$(softhsm2-util --init-token --free --label "OpenBao Token" --so-pin 1234 --pin 1234 2>&1)
    echo "$INIT_OUTPUT"
    
    # Extract the actual assigned slot number
    ASSIGNED_SLOT=$(echo "$INIT_OUTPUT" | grep -o "reassigned to slot [0-9]\+" | grep -o "[0-9]\+" | tail -1)
    
    if [ -z "$ASSIGNED_SLOT" ]; then
        ASSIGNED_SLOT=$(echo "$INIT_OUTPUT" | grep -o "slot [0-9]\+" | grep -o "[0-9]\+" | tail -1)
    fi
    
    if [ -z "$ASSIGNED_SLOT" ]; then
        echo "❌ ERROR: Could not determine assigned slot number"
        exit 1
    fi
    
    echo "✅ SoftHSM token initialized in slot $ASSIGNED_SLOT"
    export OPENBAO_SLOT="$ASSIGNED_SLOT"
    
    # Generate RSA key pair for OpenBao seal
    echo "🔑 Generating RSA-2048 key pair for OpenBao seal..."
    pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --login --pin 1234 --slot $ASSIGNED_SLOT --keypairgen --key-type rsa:2048 --label "openbao-seal-key"
    
    # Create OpenBao configuration with the actual slot number
    cat > /vault/config/openbao.hcl << EOC
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  slot = "$ASSIGNED_SLOT"
  pin = "1234"
  key_label = "openbao-seal-key"
  mechanism = "0x00000009"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"
ui = true
EOC
    
    echo "✅ SoftHSM initialization complete"
}

# Function to start OpenBao
start_openbao() {
    echo "🛡️ Starting OpenBao server..."
    bao server -config=/vault/config/openbao.hcl &
    OPENBAO_PID=$!
    
    # Wait for OpenBao to be ready
    echo "⏳ Waiting for OpenBao to be ready..."
    for i in {1..30}; do
        if curl -sf http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
            echo "✅ OpenBao is ready"
            break
        fi
        echo "🔄 Waiting for OpenBao... ($i/30)"
        sleep 2
    done
    
    # Check if OpenBao needs initialization
    INIT_STATUS=$(curl -sf http://localhost:8200/v1/sys/init 2>/dev/null || echo '{"initialized":false}')
    INITIALIZED=$(echo "$INIT_STATUS" | grep -o '"initialized":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    
    if [ "$INITIALIZED" != "true" ]; then
        echo "🔧 Initializing OpenBao..."
        INIT_RESPONSE=$(curl -sf -X POST http://localhost:8200/v1/sys/init \
            -H "Content-Type: application/json" \
            -d '{"secret_shares": 1, "secret_threshold": 1}')
        
        ROOT_TOKEN=$(echo "$INIT_RESPONSE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
        UNSEAL_KEY=$(echo "$INIT_RESPONSE" | grep -o '"keys":\["[^"]*"' | cut -d'"' -f4)
        
        echo "🔑 Root Token: $ROOT_TOKEN"
        echo "🗝️ Unseal Key: $UNSEAL_KEY"
        
        # Save tokens for persistence
        echo "$ROOT_TOKEN" > /vault/data/root_token.txt
        echo "$UNSEAL_KEY" > /vault/data/unseal_key.txt
        
        # Unseal OpenBao
        curl -sf -X POST http://localhost:8200/v1/sys/unseal \
            -H "Content-Type: application/json" \
            -d "{\"key\": \"$UNSEAL_KEY\"}"
        
        echo "✅ OpenBao initialized and unsealed"
    else
        echo "✅ OpenBao is already initialized"
    fi
    
    echo "OPENBAO_PID=$OPENBAO_PID" > /tmp/openbao.pid
}

# Function to start Elixir application
start_elixir() {
    echo "🧪 Starting Elixir application..."
    cd /app
    exec ./bin/aria_character_core start
}

# Trap signals to ensure graceful shutdown
trap 'echo "🛑 Shutting down..."; kill $OPENBAO_PID 2>/dev/null || true; exit 0' TERM INT

# Initialize SoftHSM
init_softhsm

# Start OpenBao in background
start_openbao

# Start Elixir application (this will run in foreground)
start_elixir
EOF

# Expose ports
EXPOSE 4000 8200

# Set working directory
WORKDIR /app

# Switch to aria user
USER aria

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:4000/health && curl -f http://localhost:8200/v1/sys/health || exit 1

# Start the application
ENTRYPOINT ["dumb-init", "--"]
CMD ["/app/entrypoint.sh"]
