defmodule AriaSecurity.Secrets.Behaviour do
  @moduledoc "Behaviour for secret management backends."

  @callback get_secret(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found | any()}
  @callback set_secret(key :: String.t(), value :: String.t()) :: :ok | {:error, any()}
  @callback delete_secret(key :: String.t()) :: :ok | {:error, any()}
  @callback list_secrets() :: {:ok, [String.t()]} | {:error, any()}
end
