# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true

  alias AriaSecurity.SecretsMock

  setup do
    # Start the mock for each test if not already running
    case GenServer.whereis(SecretsMock) do
      nil -> SecretsMock.start_link()
      _pid -> :ok
    end

    # Clear any existing data
    SecretsMock.clear_all()

    on_exit(fn ->
      # Only stop if the process exists and is alive
      case GenServer.whereis(SecretsMock) do
        nil ->
          :ok

        pid when is_pid(pid) ->
          if Process.alive?(pid) do
            SecretsMock.stop()
          end

        _ ->
          :ok
      end
    end)

    :ok
  end
end
