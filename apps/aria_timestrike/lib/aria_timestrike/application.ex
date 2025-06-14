# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AriaTimestrikeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AriaTimestrike.PubSub},
      # Start the Endpoint (http/https)
      AriaTimestrikeWeb.Endpoint,
      # Start the game engine supervisor
      {AriaTimestrike.GameSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaTimestrike.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AriaTimestrikeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
