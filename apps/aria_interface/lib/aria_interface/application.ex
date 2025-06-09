# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaInterface.Application do
  @moduledoc """
  AriaInterface application supervisor.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here if needed
    ]

    opts = [strategy: :one_for_one, name: AriaInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
