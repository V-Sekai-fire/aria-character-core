# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.SecretsInterface do
  @moduledoc "Interface module for secrets management that can switch between\nreal OpenBao implementation and mock for testing.\n"
  @doc "Get the configured secrets module (real or mock).\n"
  def secrets_module do
    Application.get_env(:aria_security, :secrets_module, AriaSecurity.Secrets)
  end

  @doc "Initialize connection to the secrets backend.\n"
  def init(config) do
    secrets_module().init(config)
  end

  @doc "Store a secret.\n"
  def write(path, data) do
    secrets_module().write(path, data)
  end

  @doc "Retrieve a secret.\n"
  def read(path) do
    secrets_module().read(path)
  end

  @doc "Delete a secret.\n"
  def delete(path) do
    secrets_module().delete(path)
  end

  @doc "List secrets with optional path prefix.\n"
  def list(path_prefix \\ "") do
    secrets_module().list(path_prefix)
  end
end
