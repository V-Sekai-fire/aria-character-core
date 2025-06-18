# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCharacterCore.Application do
  @moduledoc false

  use Application


  @impl true
  def start(_type, _args) do
    children = [
      # AriaEngine components (planning and AI core)
      # Worker can be added here when needed
      
      # AriaTown components (knowledge base and NPC management)
      AriaTown.KnowledgeBase,
      AriaTown.PersistenceManager,
      AriaTown.TimeManager,
      AriaTown.NPCManager,
      
      # AriaAuth components
      # Authentication supervisors can be added here as needed
      
      # AriaSecurity components
      # Security supervisors can be added here as needed
      
      # AriaStorage components
      # Storage supervisors can be added here as needed
      
      # AriaMonitor components
      # Monitoring supervisors can be added here as needed
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AriaCharacterCore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(_changed, _new, _removed) do
    # AriaCoordinateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
