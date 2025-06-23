# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCharacterCore.Application do
  @moduledoc false
  use Application
  @impl true
  def start(_type, _args) do
    children = [
      AriaEngine.Membrane.PipelineManager,
      AriaTown.PersistenceManager,
      AriaTown.TimeManager,
      AriaTown.NPCManager
    ]

    opts = [strategy: :one_for_one, name: AriaCharacterCore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end

  @impl true
  def config_change(_changed, _new, _removed) do
    :ok
  end
end