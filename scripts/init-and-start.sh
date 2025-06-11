#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

set -e

# Initialize SoftHSM token (if not already initialized)
softhsm --init-token --slot 0 --label "OpenBao" --pin 1234 --so-pin 1234 || true

# Start OpenBao in development mode with the specified config
bao server -dev -config=/etc/vault/vault-dev-persistent.hcl
