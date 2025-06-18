# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Application do
  @moduledoc false

  use Application

  alias AriaEngine.DomainProvider

  @impl true
  def start(_type, _args) do
    # Validate that at least one domain provider is configured
    case DomainProvider.get_configured_providers() do
      [] ->
        require Logger
        Logger.warning("No domain providers configured for AriaEngine")
      providers ->
        require Logger
        Logger.info("AriaEngine initialized with #{length(providers)} domain providers")
    end

    children = [
      # Starts a worker by calling: AriaEngine.Worker.start_link(arg)
      # {AriaEngine.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end
end
