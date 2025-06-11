#!/bin/bash
# Certificate fetching script for Aria services
# Authenticates to OpenBao using AppRole and fetches certificates
# This script runs on each machine at startup

set -e

# Configuration from environment
VAULT_ADDR="${VAULT_ADDR:-http://aria-character-core-bao.fly.dev:8200}"
VAULT_ROLE_ID="${VAULT_ROLE_ID:-}"
VAULT_SECRET_ID="${VAULT_SECRET_ID:-}"
SERVICE_TYPE="${SERVICE_TYPE:-cockroachdb-server}"
CERT_DIR="${CERT_DIR:-/certs}"
COMMON_NAME="${COMMON_NAME:-}"
ALT_NAMES="${ALT_NAMES:-}"
IP_SANS="${IP_SANS:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate required environment variables
if [ -z "$VAULT_ROLE_ID" ] || [ -z "$VAULT_SECRET_ID" ]; then
    log_error "VAULT_ROLE_ID and VAULT_SECRET_ID must be set"
    exit 1
fi

if [ -z "$COMMON_NAME" ]; then
    log_error "COMMON_NAME must be set for certificate generation"
    exit 1
fi

log_info "Starting certificate fetch for service type: $SERVICE_TYPE"
log_info "Common Name: $COMMON_NAME"

# Create certificate directory
mkdir -p "$CERT_DIR"
chmod 755 "$CERT_DIR"

# Step 1: Authenticate to OpenBao using AppRole
log_info "Authenticating to OpenBao using AppRole..."

AUTH_RESPONSE=$(curl -s -X POST \
    -d "{
        \"role_id\": \"$VAULT_ROLE_ID\",
        \"secret_id\": \"$VAULT_SECRET_ID\"
    }" \
    "$VAULT_ADDR/v1/auth/approle/login")

if [ $? -ne 0 ]; then
    log_error "Failed to authenticate to OpenBao"
    exit 1
fi

# Extract token from response
VAULT_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.auth.client_token')

if [ "$VAULT_TOKEN" = "null" ] || [ -z "$VAULT_TOKEN" ]; then
    log_error "Failed to extract authentication token"
    log_error "Response: $AUTH_RESPONSE"
    exit 1
fi

log_success "Successfully authenticated to OpenBao"

# Step 2: Fetch CA certificate
log_info "Fetching CA certificate..."

CA_RESPONSE=$(curl -s -X GET \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/pki/cert/ca")

if [ $? -ne 0 ]; then
    log_error "Failed to fetch CA certificate"
    exit 1
fi

echo "$CA_RESPONSE" > "$CERT_DIR/ca.crt"
log_success "CA certificate saved to $CERT_DIR/ca.crt"

# Step 3: Generate service certificate
log_info "Generating $SERVICE_TYPE certificate..."

# Build certificate request payload
CERT_PAYLOAD="{\"common_name\": \"$COMMON_NAME\", \"ttl\": \"72h\""

if [ -n "$ALT_NAMES" ]; then
    CERT_PAYLOAD="$CERT_PAYLOAD, \"alt_names\": \"$ALT_NAMES\""
fi

if [ -n "$IP_SANS" ]; then
    CERT_PAYLOAD="$CERT_PAYLOAD, \"ip_sans\": \"$IP_SANS\""
fi

CERT_PAYLOAD="$CERT_PAYLOAD}"

# Determine the correct role based on service type
case "$SERVICE_TYPE" in
    "cockroachdb-server")
        ROLE_NAME="cockroachdb-server"
        ;;
    "cockroachdb-client")
        ROLE_NAME="cockroachdb-client"
        ;;
    *)
        log_error "Unknown service type: $SERVICE_TYPE"
        exit 1
        ;;
esac

# Generate certificate
CERT_RESPONSE=$(curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d "$CERT_PAYLOAD" \
    "$VAULT_ADDR/v1/pki/issue/$ROLE_NAME")

if [ $? -ne 0 ]; then
    log_error "Failed to generate certificate"
    exit 1
fi

# Extract certificate components
CERTIFICATE=$(echo "$CERT_RESPONSE" | jq -r '.data.certificate')
PRIVATE_KEY=$(echo "$CERT_RESPONSE" | jq -r '.data.private_key')
CA_CHAIN=$(echo "$CERT_RESPONSE" | jq -r '.data.ca_chain[]')

if [ "$CERTIFICATE" = "null" ] || [ "$PRIVATE_KEY" = "null" ]; then
    log_error "Failed to extract certificate data"
    log_error "Response: $CERT_RESPONSE"
    exit 1
fi

# Step 4: Save certificates with proper permissions
log_info "Saving certificates..."

# Save individual certificate
echo "$CERTIFICATE" > "$CERT_DIR/${SERVICE_TYPE}.crt"
chmod 644 "$CERT_DIR/${SERVICE_TYPE}.crt"

# Save private key
echo "$PRIVATE_KEY" > "$CERT_DIR/${SERVICE_TYPE}.key"
chmod 600 "$CERT_DIR/${SERVICE_TYPE}.key"

# Create certificate chain file (cert + CA)
{
    echo "$CERTIFICATE"
    echo "$CA_CHAIN"
} > "$CERT_DIR/${SERVICE_TYPE}-chain.crt"
chmod 644 "$CERT_DIR/${SERVICE_TYPE}-chain.crt"

# For CockroachDB compatibility, create standard named files
if [[ "$SERVICE_TYPE" == cockroachdb-* ]]; then
    case "$SERVICE_TYPE" in
        "cockroachdb-server")
            cp "$CERT_DIR/${SERVICE_TYPE}.crt" "$CERT_DIR/node.crt"
            cp "$CERT_DIR/${SERVICE_TYPE}.key" "$CERT_DIR/node.key"
            chmod 644 "$CERT_DIR/node.crt"
            chmod 600 "$CERT_DIR/node.key"
            ;;
        "cockroachdb-client")
            cp "$CERT_DIR/${SERVICE_TYPE}.crt" "$CERT_DIR/client.root.crt"
            cp "$CERT_DIR/${SERVICE_TYPE}.key" "$CERT_DIR/client.root.key"
            chmod 644 "$CERT_DIR/client.root.crt"
            chmod 600 "$CERT_DIR/client.root.key"
            ;;
    esac
fi

# Step 5: Clean up authentication token (security best practice)
curl -s -X POST \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/auth/token/revoke-self" > /dev/null

log_success "Certificates fetched and saved successfully!"

echo ""
echo "📁 Certificate Files:"
echo "   🔐 CA Certificate: $CERT_DIR/ca.crt"
echo "   🔐 Service Certificate: $CERT_DIR/${SERVICE_TYPE}.crt"
echo "   🔑 Private Key: $CERT_DIR/${SERVICE_TYPE}.key"
echo "   🔗 Certificate Chain: $CERT_DIR/${SERVICE_TYPE}-chain.crt"

if [[ "$SERVICE_TYPE" == cockroachdb-* ]]; then
    echo "   📋 CockroachDB Compatible:"
    case "$SERVICE_TYPE" in
        "cockroachdb-server")
            echo "      🔐 node.crt"
            echo "      🔑 node.key"
            ;;
        "cockroachdb-client")
            echo "      🔐 client.root.crt"
            echo "      🔑 client.root.key"
            ;;
    esac
fi

echo ""
echo "✅ Certificate fetch completed successfully"
