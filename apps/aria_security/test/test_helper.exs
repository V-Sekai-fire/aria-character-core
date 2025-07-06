# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Application.put_env(:aria_security, :secrets_module, AriaSecurity.SecretsMock)
ExUnit.start()
