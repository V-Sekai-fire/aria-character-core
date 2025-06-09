# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.Application do
  @moduledoc """
  AriaWorkflow application supervisor.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here if needed
    ]

    opts = [strategy: :one_for_one, name: AriaWorkflow.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
