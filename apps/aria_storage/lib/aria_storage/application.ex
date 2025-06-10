# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add any aria_storage specific processes here
      # Note: AriaData.StorageRepo is started by AriaData.Application
    ]

    opts = [strategy: :one_for_one, name: AriaStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
