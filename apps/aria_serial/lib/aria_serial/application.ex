# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSerial.Application do
  @serial_number "R25W005APPL"

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @doc "Returns the serial number for this module"
  def serial_number, do: @serial_number

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
