# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity do
  @moduledoc """
  AriaSecurity provides secure secret management and cryptographic utilities.

  This library offers:
  - OpenBao/Vault integration for secret storage
  - SoftHSM integration for hardware security modules
  - Secure secret management interfaces
  - Mock implementations for testing

  ## Main Modules

  - `AriaSecurity.Secrets` - Primary secret management interface
  - `AriaSecurity.OpenBao` - OpenBao server integration
  - `AriaSecurity.SoftHSM` - Hardware security module support
  - `AriaSecurity.SecretsMock` - Testing utilities

  ## Usage

      # Initialize secret management
      config = %{
        host: "localhost",
        port: 8200,
        scheme: "http",
        auth: %{
          method: :token,
          credentials: %{token: "your-token"}
        }
      }

      {:ok, _status} = AriaSecurity.Secrets.init(config)

      # Store and retrieve secrets
      {:ok, _} = AriaSecurity.Secrets.write("secret/myapp", %{password: "secret123"})
      {:ok, data} = AriaSecurity.Secrets.read("secret/myapp")
  """

  @doc """
  Initialize secret management with the given configuration.

  Delegates to AriaSecurity.Secrets.init/1.
  """
  defdelegate init(config), to: AriaSecurity.Secrets

  @doc """
  Store a secret at the given path.

  Delegates to AriaSecurity.Secrets.write/2.
  """
  defdelegate write(path, data), to: AriaSecurity.Secrets

  @doc """
  Retrieve a secret from the given path.

  Delegates to AriaSecurity.Secrets.read/1.
  """
  defdelegate read(path), to: AriaSecurity.Secrets
end
