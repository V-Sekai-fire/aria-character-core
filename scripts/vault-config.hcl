# Generic OpenBao configuration
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

storage "file" {
  path = "/vault/data"
}

# PKCS#11 Seal
seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  slot = "${OPENBAO_PKCS11_SLOT}"
  pin = "${OPENBAO_PKCS11_PIN}"
  key_label = "openbao-key"
  hmac_key_label = "openbao-hmac-key"
  # Optional: if you want to reset the HSM keys on startup
  # force_reset = "${RESET_HSM_KEYS}"
}
