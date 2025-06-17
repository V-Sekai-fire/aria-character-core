defmodule AriaTownDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Knowledge Base and Persistence
      AriaTownDemo.KnowledgeBase,
      AriaTownDemo.PersistenceManager,
      
      # Time and NPC Management
      AriaTownDemo.TimeManager,
      AriaTownDemo.NPCManager,
      
      # Phoenix Endpoint
      AriaTownDemoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AriaTownDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AriaTownDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
