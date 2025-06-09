# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# OpenBao configuration for production with SoftHSM seal protection
# Keys are protected by SoftHSM, only authentication tokens stored in clear

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

# HSM seal configuration using SoftHSM PKCS#11
seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  slot = "${OPENBAO_PKCS11_SLOT}"
  pin = "${OPENBAO_PKCS11_PIN}"
  key_label = "openbao-seal-key"
  hmac_key_label = "openbao-hmac-key"
  generate_key = "true"
}

# API address
api_addr = "http://0.0.0.0:8200"

# Cluster address
cluster_addr = "http://0.0.0.0:8201"

# UI enabled
ui = true

# Logging
log_level = "Info"

# Disable mlock for development
disable_mlock = true

# Default lease TTL
default_lease_ttl = "168h"

# Maximum lease TTL
max_lease_ttl = "720h"
