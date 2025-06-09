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
      # Main repository for general data
      {AriaData.Repo, []},
      
      # Specialized repositories for different services
      {AriaData.AuthRepo, []},
      {AriaData.QueueRepo, []},
      {AriaData.StorageRepo, []},
      {AriaData.MonitorRepo, []},
      {AriaData.EngineRepo, []}
    ]

    opts = [strategy: :one_for_one, name: AriaData.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
