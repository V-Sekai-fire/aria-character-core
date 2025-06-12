# OpenBao configuration with SoftHSM seal for Fly.io
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
  slot = "0"
  pin = "1234"
  key_label = "aria-seal-key"
  hmac_key_label = "aria-hmac-key"
  generate_key = "true"
}

# API address
api_addr = "http://0.0.0.0:8200"

# UI enabled
ui = true

# Logging
log_level = "Info"

# Disable mlock for containers
disable_mlock = true

# Default lease TTL
default_lease_ttl = "168h"

# Maximum lease TTL
max_lease_ttl = "720h"
