# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true
  alias AriaSecurity.SecretsMock

  setup do
    case GenServer.whereis(SecretsMock) do
      nil -> SecretsMock.start_link()
      _pid -> :ok
    end

    SecretsMock.clear_all()

    on_exit(fn ->
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
