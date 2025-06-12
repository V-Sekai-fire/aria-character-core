# OpenBao configuration for Fly.io (Standard Build)
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
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
