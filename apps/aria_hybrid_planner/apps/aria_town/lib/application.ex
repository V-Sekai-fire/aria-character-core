# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.Application do
  @moduledoc false
  use Application
  require AriaTown.JSONEncoders
  @impl true
  def start(_type, _args) do
    children = [AriaTown.PersistenceManager, AriaTown.TimeManager, AriaTown.NPCManager]
    opts = [strategy: :one_for_one, name: AriaTown.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
