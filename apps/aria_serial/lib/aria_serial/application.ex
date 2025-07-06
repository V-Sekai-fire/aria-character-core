# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial.Application do
  @moduledoc """
  Project file with serial number: R25W005APPL

  Decode: mix serial.decode R25W005APPL
  """

  @serial_number "R25W005APPL"

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AriaSerial.Worker.start_link(arg)
      # {AriaSerial.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaSerial.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
