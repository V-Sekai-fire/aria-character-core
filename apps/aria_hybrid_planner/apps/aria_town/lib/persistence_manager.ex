# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.PersistenceManager do
  @moduledoc "Stub implementation for NPC persistence management.\nRDF/JSON-LD functionality has been removed.\n"
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("PersistenceManager started (stub implementation)")
    {:ok, state}
  end

  def trigger_save() do
    GenServer.cast(__MODULE__, :immediate_save)
  end

  def handle_cast(:immediate_save, state) do
    Logger.debug("PersistenceManager: Save triggered (stub - no action taken)")
    {:noreply, state}
  end
end
