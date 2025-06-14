# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add temporal planner supervisors here
    ]

    opts = [strategy: :one_for_one, name: AriaTimestrike.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
