# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Membrane-based job processor to replace Oban
      {AriaQueue.MembraneJobProcessor, []}
    ]

    opts = [strategy: :one_for_one, name: AriaQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
