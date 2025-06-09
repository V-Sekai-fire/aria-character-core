# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaDebugger.Application do
  @moduledoc """
  AriaDebugger application supervisor.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here if needed
    ]

    opts = [strategy: :one_for_one, name: AriaDebugger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
