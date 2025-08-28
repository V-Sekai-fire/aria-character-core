# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown.NPCManager do
  @moduledoc "NPC management system for Aria Town.\n\nThis is currently a stub implementation that provides the basic GenServer\nstructure needed for the supervision tree. Future development will add:\n\n- NPC lifecycle management (spawn, despawn, persistence)\n- Behavior coordination and AI planning integration\n- NPC state synchronization and updates\n- Social interaction and relationship management\n\n## Architecture Notes\n\nThe NPCManager should eventually coordinate with:\n- TimeManager for scheduled behaviors and time-based actions\n- Planner for NPC goal-directed behavior\n- KnowledgeBase for NPC knowledge and memory\n- PersistenceManager for NPC state storage\n\n## Planned Integration\n\nFuture NPCs will use AriaEngine's hybrid planner for:\n- Goal-oriented behavior planning\n- Temporal scheduling of activities\n- Social interaction planning\n- Resource and spatial reasoning\n"
  use GenServer
  require Logger
  @doc "Start the NPCManager GenServer"
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Get all NPCs (stub)"
  def list_npcs do
    GenServer.call(__MODULE__, :list_npcs)
  end

  @doc "Get specific NPC by ID (stub)"
  def get_npc(npc_id) do
    GenServer.call(__MODULE__, {:get_npc, npc_id})
  end

  @doc "Spawn new NPC (stub)"
  def spawn_npc(npc_config) do
    GenServer.call(__MODULE__, {:spawn_npc, npc_config})
  end

  @doc "Update NPC state (stub)"
  def update_npc(npc_id, updates) do
    GenServer.call(__MODULE__, {:update_npc, npc_id, updates})
  end

  @doc "Remove NPC (stub)"
  def despawn_npc(npc_id) do
    GenServer.call(__MODULE__, {:despawn_npc, npc_id})
  end

  @impl GenServer
  def init(_opts) do
    Logger.info("NPCManager started (stub implementation)")
    initial_state = %{npcs: %{}, next_id: 1}
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(:list_npcs, _from, state) do
    npcs_list = Map.values(state.npcs)
    {:reply, npcs_list, state}
  end

  @impl GenServer
  def handle_call({:get_npc, npc_id}, _from, state) do
    npc = Map.get(state.npcs, npc_id)
    {:reply, npc, state}
  end

  @impl GenServer
  def handle_call({:spawn_npc, npc_config}, _from, state) do
    npc_id = "npc_#{state.next_id}"

    npc = %{
      id: npc_id,
      name: Map.get(npc_config, :name, "NPC"),
      position: Map.get(npc_config, :position, {0, 0, 0}),
      state: :idle,
      created_at: DateTime.utc_now()
    }

    new_npcs = Map.put(state.npcs, npc_id, npc)
    new_state = %{state | npcs: new_npcs, next_id: state.next_id + 1}
    Logger.info("Spawned NPC: #{npc_id}")
    {:reply, {:ok, npc}, new_state}
  end

  @impl GenServer
  def handle_call({:update_npc, npc_id, updates}, _from, state) do
    case Map.get(state.npcs, npc_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      npc ->
        updated_npc = Map.merge(npc, updates)
        new_npcs = Map.put(state.npcs, npc_id, updated_npc)
        new_state = %{state | npcs: new_npcs}
        Logger.debug("Updated NPC #{npc_id}: #{inspect(updates)}")
        {:reply, {:ok, updated_npc}, new_state}
    end
  end

  @impl GenServer
  def handle_call({:despawn_npc, npc_id}, _from, state) do
    case Map.get(state.npcs, npc_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      _npc ->
        new_npcs = Map.delete(state.npcs, npc_id)
        new_state = %{state | npcs: new_npcs}
        Logger.info("Despawned NPC: #{npc_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_info(:tick, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("NPCManager received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
