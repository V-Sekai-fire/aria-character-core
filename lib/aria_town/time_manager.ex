# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.TimeManager do
  @moduledoc """
  Time management system for Aria Town.

  This is currently a stub implementation that provides the basic GenServer
  structure needed for the supervision tree. Future development will add:

  - Game time progression and scheduling
  - Day/night cycles and temporal events
  - NPC scheduling coordination
  - Time-based triggers and automation

  ## Architecture Notes

  The TimeManager should eventually coordinate with:
  - NPCManager for scheduled behaviors
  - AriaEngine temporal planner for time-based planning
  - Event system for temporal triggers
  """

  use GenServer
  require Logger

  # Client API

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

  # GenServer Callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("TimeManager started (stub implementation)")

    # Initialize with current system time as game time
    initial_state = %{
      game_time: DateTime.utc_now(),
      time_scale: 1.0,
      paused: false
    }

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
    # Future: Handle periodic time updates
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("TimeManager received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
