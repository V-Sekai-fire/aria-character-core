# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.Application do
  @moduledoc """
  The AriaData Application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the database supervisor when needed
      # {AriaData.Repo, []}
    ]

    opts = [strategy: :one_for_one, name: AriaData.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
