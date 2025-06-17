defmodule AriaTown.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Knowledge Base and Persistence
      AriaTown.KnowledgeBase,
      AriaTown.PersistenceManager,
      
      # Time and NPC Management
      AriaTown.TimeManager,
      AriaTown.NPCManager,
      
      # Phoenix Endpoint
      AriaTownWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AriaTown.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AriaTownWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
