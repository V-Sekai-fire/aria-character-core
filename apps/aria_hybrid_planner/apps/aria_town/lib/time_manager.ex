# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.TimeManager do
  @moduledoc "Time management system for Aria Town.\n\nThis is currently a stub implementation that provides the basic GenServer\nstructure needed for the supervision tree. Future development will add:\n\n- Game time progression and scheduling\n- Day/night cycles and temporal events\n- NPC scheduling coordination\n- Time-based triggers and automation\n\n## Architecture Notes\n\nThe TimeManager should eventually coordinate with:\n- NPCManager for scheduled behaviors\n- AriaEngine temporal planner for time-based planning\n- Event system for temporal triggers\n"
  use GenServer
  require Logger
  @doc "Start the TimeManager GenServer"
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Get current game time (stub)"
  def current_time do
    GenServer.call(__MODULE__, :current_time)
  end

  @doc "Advance time by specified amount (stub)"
  def advance_time(delta) do
    GenServer.call(__MODULE__, {:advance_time, delta})
  end

  @impl GenServer
  def init(_opts) do
    Logger.info("TimeManager started (stub implementation)")
    initial_state = %{game_time: DateTime.utc_now(), time_scale: 1.0, paused: false}
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(:current_time, _from, state) do
    {:reply, state.game_time, state}
  end

  @impl GenServer
  def handle_call({:advance_time, delta}, _from, state) do
    new_time = DateTime.add(state.game_time, delta, :second)
    new_state = %{state | game_time: new_time}
    Logger.debug("Time advanced by #{delta} seconds to #{new_time}")
    {:reply, new_time, new_state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("TimeManager received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
