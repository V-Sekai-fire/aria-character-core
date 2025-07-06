# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AriaQcp.Worker.start_link(arg)
      # {AriaQcp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaQcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
