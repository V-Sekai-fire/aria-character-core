# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Registry for job processors
      {Registry, keys: :unique, name: AriaQueue.Registry},
      
      # Membrane-based job processor to replace Oban
      {AriaQueue.MembraneJobProcessor, []}
      
      # Note: AriaQueue.FlowProcessor now delegates to AriaFlow and doesn't need supervision
    ]

    opts = [strategy: :one_for_one, name: AriaQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
