# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.Application do
  @moduledoc """
  AriaFlow application supervisor.
  
  Manages the Flow-based processing infrastructure including
  pipeline registry and element supervision.
  """
  
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      # Registry for Flow pipelines and elements
      {Registry, keys: :unique, name: AriaFlow.Registry}
      # Note: AriaFlow.Backflow processes are started on-demand per pipeline/element
    ]
    
    opts = [strategy: :one_for_one, name: AriaFlow.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
