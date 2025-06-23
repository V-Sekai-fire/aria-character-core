Application.put_env(:aria_security, :secrets_module, AriaSecurity.SecretsMock)
ExUnit.start()