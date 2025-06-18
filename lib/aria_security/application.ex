# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Define your supervisor children here
      # For example:
      # {AriaSecurity.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: AriaSecurity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end