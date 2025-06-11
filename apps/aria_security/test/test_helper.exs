# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Configure test environment to use mock
Application.put_env(:aria_security, :secrets_module, AriaSecurity.SecretsMock)

ExUnit.start()
