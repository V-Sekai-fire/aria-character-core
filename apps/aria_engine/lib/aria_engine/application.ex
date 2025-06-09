# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Application do
  @moduledoc """
  The AriaEngine application supervises the classical AI planning and GTPyhop services.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # GTPyhop domain registry for managing planning domains
      {Registry, keys: :unique, name: AriaEngine.DomainRegistry},
      
      # Planner supervisor for managing planning processes
      {DynamicSupervisor, strategy: :one_for_one, name: AriaEngine.PlannerSupervisor}
    ]

    opts = [strategy: :one_for_one, name: AriaEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
