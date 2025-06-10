# Use the official Elixir image as a base
FROM elixir:1.16.0-alpine

# Set the working directory inside the container
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install runtime dependencies for Elixir, OpenBao, SoftHSM, and CockroachDB client
RUN apk add --no-cache openssl libstdc++ curl bash \
    && apk add --no-cache softhsm nss-tools \
    && apk add --no-cache postgresql-client \
    && rm -rf /var/cache/apk/*

# Download and install CockroachDB client for ARM64 Linux from Oxide's Buildomat
RUN ARCH=arm64 && \
    COMMIT_HASH=865aff1595e494c2ce95030c7a2f20c4370b5ff8 && \
    wget -qO- "https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-${ARCH}/${COMMIT_HASH}/cockroach.tgz" | tar  xvz -C /usr/local --strip-components 1 cockroach && \
    chmod +x /usr/local/bin/cockroach

# Download and install OpenBao for ARM64 Linux
RUN BAO_VERSION=2.2.2 && \
    ARCH=arm64 && \
    wget -qO- "https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_linux_${ARCH}.pkg.tar.zst" | tar -I zstd -xvz -C /usr/local/bin bao && \
    chmod +x /usr/local/bin/bao

# Set environment variables
ENV VAULT_ADDR=http://127.0.0.1:8200 \
    VAULT_API_ADDR=http://127.0.0.1:8200 \
    VAULT_CLUSTER_ADDR=http://127.0.0.1:8201 \
    VAULT_SKIP_VERIFY=true \
    VAULT_LOG_LEVEL=debug \
    VAULT_STORAGE_PATH=/vault/data \
    VAULT_CONFIG_PATH=/etc/vault \
    VAULT_DEV_ROOT_TOKEN_ID=root \
    VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
    VAULT_DEV_STANDBY_ADDRESS=0.0.0.1:8201 \
    VAULT_DEV_CLUSTER_ADDRESS=0.0.0.1:8201 \
    VAULT_DEV_TLS_DISABLE=true \
    VAULT_DEV_MAX_LEASE_TTL=0 \
    VAULT_DEV_DEFAULT_LEASE_TTL=0 \
    VAULT_DEV_UI=true \
    VAULT_DEV_LOG_LEVEL=debug \
    VAULT_DEV_SEAL_TYPE=shamir \
    VAULT_DEV_SEAL_SHARDS=1 \
    VAULT_DEV_SEAL_THRESHOLD=1 \
    VAULT_DEV_SEAL_RECOVERY_KEY_SHARES=1 \
    VAULT_DEV_SEAL_RECOVERY_KEY_THRESHOLD=1 \
    VAULT_DEV_SEAL_RECOVERY_KEY_TYPE=shamir

# Copy the application code
COPY . .

# Install dependencies
RUN mix deps.get --only prod
RUN mix compile

# Build the release
RUN mix release --overwrite

# Expose the port your Phoenix app runs on (e.g., 4000)
EXPOSE 4000

# Command to run the application
CMD ["/app/_build/prod/rel/aria_queue/bin/aria_queue", "start"]
