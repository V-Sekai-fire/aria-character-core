# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.NPCManager do
  @moduledoc """
  NPC management system for Aria Town.
  
  This is currently a stub implementation that provides the basic GenServer
  structure needed for the supervision tree. Future development will add:
  
  - NPC lifecycle management (spawn, despawn, persistence)
  - Behavior coordination and AI planning integration
  - NPC state synchronization and updates
  - Social interaction and relationship management
  
  ## Architecture Notes
  
  The NPCManager should eventually coordinate with:
  - TimeManager for scheduled behaviors and time-based actions
  - AriaEngine.Planner for NPC goal-directed behavior
  - KnowledgeBase for NPC knowledge and memory
  - PersistenceManager for NPC state storage
  
  ## Planned Integration
  
  Future NPCs will use AriaEngine's hybrid planner for:
  - Goal-oriented behavior planning
  - Temporal scheduling of activities
  - Social interaction planning
  - Resource and spatial reasoning
  """

  use GenServer
  require Logger

  # Client API

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

  # GenServer Callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("NPCManager started (stub implementation)")
    
    # Initialize with empty NPC registry
    initial_state = %{
      npcs: %{},
      next_id: 1
    }
    
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
    # Future: Handle periodic NPC updates, AI processing, etc.
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("NPCManager received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
