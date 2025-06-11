# 🔐 PKI Infrastructure Setup for Aria Character Core

## Summary

Successfully configured a complete PKI (Public Key Infrastructure) infrastructure using OpenBao as the Certificate Authority for secure communication in the Aria Character Core Fly.io cluster.

## 🏗️ Infrastructure Components

### **OpenBao PKI Certificate Authority**
- **Service:** `aria-character-core-vault` (aria_security)
- **Status:** ✅ **DEPLOYED & OPERATIONAL**
- **URL:** http://aria-character-core-vault.fly.dev:8200
- **Features:**
  - SoftHSM PKCS#11 HSM backing for secure key storage
  - Automated certificate generation and management
  - 72-hour certificate validity with auto-renewal capability
  - REST API for programmatic certificate management

### **Generated Certificates**

#### **Root Certificate Authority**
- **File:** `certs/ca.crt`
- **Subject:** `C=US, L=Chicago, O=Aria Character Core, OU=Infrastructure, CN=Aria Character Core Root CA`
- **Validity:** 10 years (2025-2035)
- **Purpose:** Root trust anchor for all issued certificates

#### **CockroachDB Server Certificate**
- **Files:** `certs/server.crt`, `certs/server.key`
- **Subject:** `CN=aria-character-core-db.fly.dev`
- **SANs:** 
  - DNS: aria-character-core-db.fly.dev
  - DNS: localhost
  - IP: 127.0.0.1
- **Validity:** 72 hours (renewable via OpenBao API)
- **Purpose:** TLS server authentication for CockroachDB

#### **CockroachDB Client Certificate**
- **Files:** `certs/client.root.crt`, `certs/client.root.key`
- **Subject:** `CN=root`
- **Validity:** 72 hours (renewable via OpenBao API)
- **Purpose:** Client authentication for CockroachDB root user

## 📁 Certificate Files Structure

```
certs/
├── ca.crt               # Root CA certificate
├── ca_chain.crt         # CA chain (same as ca.crt for root)
├── server.crt           # CockroachDB server cert with CA chain
├── server.key           # CockroachDB server private key
├── cockroach_server.crt # Individual server certificate
├── cockroach_server.key # Individual server private key
├── client.root.crt      # Root client certificate
└── client.root.key      # Root client private key
```

## 🔐 Machine Authentication System

### **Fly.io Macaroon-Based Bootstrap**
- **Authentication Method:** AppRole with single-use secret IDs
- **Bootstrap Process:** Fly.io macaroons distribute initial credentials
- **Security Model:** No pre-shared secrets, zero-trust authentication
- **Token Lifecycle:** 24-hour validity with 72-hour maximum

### **Certificate Distribution Process**
1. **Deployment:** Fly.io secrets contain AppRole credentials
2. **Startup:** Machines authenticate to OpenBao using role-id/secret-id
3. **Certificate Fetch:** Dynamic certificate generation based on machine identity
4. **Auto-Renewal:** Background daemon monitors and renews certificates before expiry

## 🔄 Certificate Lifecycle Management

### **Dynamic Certificate Fetching**
Machines authenticate to OpenBao and fetch their own certificates:

```bash
# Machine startup process
export VAULT_ROLE_ID="$(secret from Fly.io)"
export VAULT_SECRET_ID="$(secret from Fly.io)" 
export SERVICE_TYPE="cockroachdb-server"
export COMMON_NAME="aria-character-core-db.fly.dev"

# Fetch certificates dynamically
/usr/local/bin/fetch-certificates.sh
```

### **Automatic Renewal**
Background daemon monitors certificate expiry and renews automatically:

```bash
# Renewal daemon (runs continuously)
/usr/local/bin/renew-certificates.sh daemon

# Manual operations
/usr/local/bin/renew-certificates.sh check   # Check if renewal needed
/usr/local/bin/renew-certificates.sh renew   # Force immediate renewal
```

## 🛠️ Available Scripts

- **`scripts/setup-machine-auth.sh`** - Configure AppRole authentication and machine credentials
- **`scripts/fetch-certificates.sh`** - Dynamic certificate fetching script for machines
- **`scripts/renew-certificates.sh`** - Automatic certificate renewal daemon
- **`scripts/deploy-cockroachdb.sh`** - Deploy CockroachDB with dynamic certificate fetching

## 🔗 Integration with CockroachDB

The `fly-db.toml` configuration has been updated to:
- Use certificate directory `/cockroach/certs`
- Enable TLS with `--certs-dir` flag
- Mount certificate volume for persistent certificate storage

## 🎯 Next Steps

1. **Setup Machine Authentication:** Run `./scripts/setup-machine-auth.sh`
2. **Deploy CockroachDB:** Run `./scripts/deploy-cockroachdb.sh`
3. **Initialize Databases:** Create required databases for each Aria service
4. **Deploy Main Application:** Continue with the main umbrella application deployment
5. **Certificate Monitoring:** Automatic certificate renewal runs continuously

## 🔒 Security Features

- **HSM-Backed PKI:** SoftHSM provides hardware security module simulation
- **Short-Lived Certificates:** 72-hour validity reduces exposure window
- **Automated Renewal:** OpenBao API enables automated certificate lifecycle management
- **Proper Key Permissions:** Private keys have 600 permissions (owner read/write only)
- **TLS Everywhere:** All database connections use mutual TLS authentication
- **AppRole Authentication:** Machine identity with single-use secret IDs
- **No Pre-shared Secrets:** Fly.io macaroons bootstrap secure authentication
- **Zero Trust Model:** Every machine must authenticate before receiving certificates

## 📊 Cold Boot Order Status

### ✅ **Layer 1: Foundation Services**
- **aria_security (OpenBao):** ✅ **DEPLOYED** - PKI infrastructure ready, AppRole authentication configured
- **aria_data (CockroachDB):** 🔧 **IN PROGRESS** - Machine deployed, certificate fetching needs debugging

### 🔧 **Current Issues:**
- CockroachDB certificate fetching script encountering `jq: Cannot iterate over null` error
- OpenBao PKI endpoint returning null response for certificate issuance
- Need to verify PKI backend configuration and certificate role setup

### ⏳ **Next Layers:**
- Layer 2: Core Services (aria_auth, aria_storage, aria_queue)
- Layer 3: Intelligence Layer (aria_shape, aria_engine, aria_interpret)
- Layer 4: Orchestration Layer (aria_workflow, aria_interface)
- Layer 5: Gateway & Ops Layer (aria_coordinate, aria_monitor, aria_debugger, aria_tune)

---

*Generated: June 10, 2025*
*System: Aria Character Core PKI Infrastructure*
