defmodule AriaMiniZinc.Application do
  @moduledoc """
  Application supervisor for AriaMiniZinc.

  Starts the supervision tree for the MiniZinc constraint solver integration.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here if needed
      # For now, this is a simple application without persistent processes
    ]

    opts = [strategy: :one_for_one, name: AriaMiniZinc.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
