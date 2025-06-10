# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.Secrets do
  @moduledoc "Public interface for secret management."

  @behaviour AriaSecurity.Secrets.Behaviour

  alias AriaSecurity.Secrets.EctoBackend

  @impl true
  def get_secret(key), do: EctoBackend.get_secret(key)

  @impl true
  def set_secret(key, value), do: EctoBackend.set_secret(key, value)

  @impl true
  def delete_secret(key), do: EctoBackend.delete_secret(key)

  @impl true
  def list_secrets(), do: EctoBackend.list_secrets()
end