# Debugging Commands for Certificate Fetching Issue

## Current Issue
CockroachDB certificate fetching failing with:
```
jq: Cannot iterate over null (null)
```

## Debug Commands

### 1. Check OpenBao PKI Configuration
```bash
# Connect to OpenBao instance
flyctl ssh console --app aria-character-core-vault

# Inside OpenBao container, check PKI status
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="aria-dev-token"

# Check if PKI backend is mounted
vault secrets list

# Check PKI CA
vault read pki/cert/ca

# List certificate roles
vault list pki/roles

# Check specific role configuration
vault read pki/roles/cockroachdb-server
vault read pki/roles/cockroachdb-client
```

### 2. Test AppRole Authentication
```bash
# Test AppRole authentication from CockroachDB
flyctl ssh console --app aria-character-core-db

# Check environment variables
env | grep VAULT

# Test authentication manually
curl -X POST \
    -d "{\"role_id\": \"$VAULT_ROLE_ID\", \"secret_id\": \"$VAULT_SECRET_ID\"}" \
    "$VAULT_ADDR/v1/auth/approle/login"
```

### 3. Test Certificate Issuance
```bash
# Test certificate generation directly
curl -X POST \
    -H "X-Vault-Token: TOKEN_FROM_AUTH" \
    -d '{"common_name": "test.fly.dev", "ttl": "72h"}' \
    "http://aria-character-core-vault.fly.dev:8200/v1/pki/issue/cockroachdb-server"
```

### 4. Check Machine Logs
```bash
# View CockroachDB startup logs
flyctl logs --app aria-character-core-db

# View OpenBao logs
flyctl logs --app aria-character-core-vault
```

## Expected Next Actions

1. Verify PKI backend configuration in OpenBao
2. Fix any missing certificate roles or policies
3. Test certificate issuance manually
4. Update scripts if API endpoints or formats changed
5. Redeploy CockroachDB once certificate fetching works
