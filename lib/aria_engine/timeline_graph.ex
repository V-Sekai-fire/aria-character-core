# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph do
  @moduledoc """
  Manages timeline integration with the Entity Timeline Graph Architecture (ADR-087).

  This module connects the existing Timeline.AgentEntity system with 
  auto-growing timelines, implementing the core concept that every entity owns
  a timeline that grows automatically based on their capabilities and interactions.

  ## Core Concepts

  - **Every Entity has a Timeline**: Created automatically when entities are instantiated
  - **Timeline Growth**: Automatic based on entity capabilities and interactions
  - **LOD Management**: Level of Detail scaling based on relevance and proximity
  - **Bridge Management**: Inter-timeline connections for coordination

  ## Specialized Modules

  This module delegates to specialized sub-modules for different aspects of functionality:

  - `TimelineGraph.EntityManager` - Entity creation, capabilities, and basic timeline operations
  - `TimelineGraph.LODManager` - Level of Detail management and promotion
  - `TimelineGraph.Scheduler` - Scheduling and routine management
  - `TimelineGraph.EnvironmentalProcesses` - Multi-entity environmental effects
  - `TimelineGraph.TimeConverter` - Time format conversion utilities

  ## Usage

  ```elixir
  # Create entity with automatic timeline attachment
  {:ok, entity_id} = TimelineGraph.create_entity("chair1", "Wooden Chair", %{type: "furniture"})

  # Promote to agent with timeline growth triggers
  {:ok, updated_entity} = TimelineGraph.add_capabilities(entity_id, [:autonomous_operation])

  # Timeline automatically grows when entity becomes agent
  TimelineGraph.is_agent_timeline?(entity_id) # => true
  ```
  """

  alias Timeline.AgentEntity
  alias Timeline
  alias AriaEngine.StateV2
  alias TimelineGraph.EntityManager
  alias TimelineGraph.LODManager
  alias TimelineGraph.Scheduler
  alias TimelineGraph.EnvironmentalProcesses

  @type entity_id :: String.t()
  @type timeline_id :: String.t()
  @type lod_level :: :very_low | :low | :medium | :high | :ultra_high
  @type bridge_type ::
          :proximity | :memory | :communication | :conversation | :causal | :coordination

  @type entity_timeline :: %{
          entity: AgentEntity.participant(),
          timeline: Timeline.t(),
          lod: lod_level(),
          last_growth: DateTime.t(),
          bridges: %{entity_id() => bridge_type()}
        }

  @type t :: %__MODULE__{
          entities: %{entity_id() => entity_timeline()},
          state: StateV2.t(),
          bridge_strength: %{{entity_id(), entity_id()} => float()},
          lod_promotion_queue: [entity_id()],
          growth_triggers: %{entity_id() => [atom()]}
        }

  defstruct entities: %{},
            state: %StateV2{},
            bridge_strength: %{},
            lod_promotion_queue: [],
            growth_triggers: %{}

  @doc """
  Creates a new TimelineGraph with empty entity and timeline registry.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      state: StateV2.new()
    }
  end

  # Entity Management Functions (delegated to EntityManager)

  @doc """
  Creates a new entity with automatic timeline attachment.

  Delegates to `TimelineGraph.EntityManager.create_entity/5`.
  """
  defdelegate create_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []),
    to: EntityManager

  @doc """
  Adds capabilities to an entity, potentially transitioning it to agent status.

  Delegates to `TimelineGraph.EntityManager.add_capabilities/3`.
  """
  defdelegate add_capabilities(timeline_graph, entity_id, new_capabilities), to: EntityManager

  @doc """
  Checks if an entity is currently acting as an agent.

  Delegates to `TimelineGraph.EntityManager.is_currently_agent?/2`.
  """
  defdelegate is_currently_agent?(timeline_graph, entity_id), to: EntityManager

  @doc """
  Gets entity properties using entity-first StateV2 API.

  Delegates to `TimelineGraph.EntityManager.get_entity_properties/2`.
  """
  defdelegate get_entity_properties(timeline_graph, entity_id), to: EntityManager

  @doc """
  Sets an entity property and triggers timeline growth if appropriate.

  Delegates to `TimelineGraph.EntityManager.set_entity_property/4`.
  """
  defdelegate set_entity_property(timeline_graph, entity_id, predicate, value), to: EntityManager

  @doc """
  Gets all entity IDs currently managed by the timeline graph.

  Delegates to `TimelineGraph.EntityManager.get_entity_ids/1`.
  """
  defdelegate get_entity_ids(timeline_graph), to: EntityManager

  @doc """
  Gets all agent IDs (entities with action capabilities).

  Delegates to `TimelineGraph.EntityManager.get_agent_ids/1`.
  """
  defdelegate get_agent_ids(timeline_graph), to: EntityManager

  # LOD Management Functions (delegated to LODManager)

  @doc """
  Gets the current LOD level for an entity's timeline.

  Delegates to `TimelineGraph.LODManager.get_lod/2`.
  """
  defdelegate get_lod(timeline_graph, entity_id), to: LODManager

  @doc """
  Processes the LOD promotion queue, upgrading timeline detail for active agents.

  Delegates to `TimelineGraph.LODManager.process_lod_promotions/1`.
  """
  defdelegate process_lod_promotions(timeline_graph), to: LODManager

  @doc """
  Sets the LOD level for a specific entity.

  Delegates to `TimelineGraph.LODManager.set_lod/3`.
  """
  defdelegate set_lod(timeline_graph, entity_id, new_lod), to: LODManager

  @doc """
  Adds an entity to the LOD promotion queue.

  Delegates to `TimelineGraph.LODManager.queue_for_promotion/2`.
  """
  defdelegate queue_for_promotion(timeline_graph, entity_id), to: LODManager

  @doc """
  Gets all entities at a specific LOD level.

  Delegates to `TimelineGraph.LODManager.get_entities_at_lod/2`.
  """
  defdelegate get_entities_at_lod(timeline_graph, target_lod), to: LODManager

  @doc """
  Gets LOD statistics for the timeline graph.

  Delegates to `TimelineGraph.LODManager.get_lod_statistics/1`.
  """
  defdelegate get_lod_statistics(timeline_graph), to: LODManager

  @doc """
  Automatically adjusts LOD levels based on entity activity and system performance.

  Delegates to `TimelineGraph.LODManager.auto_adjust_lod/2`.
  """
  defdelegate auto_adjust_lod(timeline_graph, opts \\ []), to: LODManager

  # Scheduling Functions (delegated to Scheduler)

  @doc """
  Schedules a routine activity for an agent with priority and deadline handling.

  Delegates to `TimelineGraph.Scheduler.schedule_routine/4`.
  """
  defdelegate schedule_routine(timeline_graph, entity_id, routine_type, opts), to: Scheduler

  @doc """
  Resolves schedule conflicts for an entity based on priority and deadline handling.

  Delegates to `TimelineGraph.Scheduler.resolve_schedule_conflicts/4`.
  """
  defdelegate resolve_schedule_conflicts(timeline_graph, entity_id, new_routine, conflicts),
    to: Scheduler

  @doc """
  Gets the current scheduled routines for an entity within a time window.

  Delegates to `TimelineGraph.Scheduler.get_scheduled_routines/4`.
  """
  defdelegate get_scheduled_routines(timeline_graph, entity_id, start_time, end_time),
    to: Scheduler

  @doc """
  Cancels a scheduled routine by routine type and optional time range.

  Delegates to `TimelineGraph.Scheduler.cancel_routine/4`.
  """
  defdelegate cancel_routine(timeline_graph, entity_id, routine_type, opts \\ []), to: Scheduler

  @doc """
  Gets all active routines for an entity at the current time.

  Delegates to `TimelineGraph.Scheduler.get_active_routines/2`.
  """
  defdelegate get_active_routines(timeline_graph, entity_id), to: Scheduler

  @doc """
  Checks if an entity has any schedule conflicts in a given time range.

  Delegates to `TimelineGraph.Scheduler.has_schedule_conflicts?/4`.
  """
  defdelegate has_schedule_conflicts?(timeline_graph, entity_id, start_time, end_time),
    to: Scheduler

  # Environmental Process Functions (delegated to EnvironmentalProcesses)

  @doc """
  Adds a process or event that affects multiple entities over time.

  Delegates to `TimelineGraph.EnvironmentalProcesses.add_environmental_process/3`.
  """
  defdelegate add_environmental_process(timeline_graph, process_type, opts),
    to: EnvironmentalProcesses

  @doc """
  Removes an environmental process from all affected entities.

  Delegates to `TimelineGraph.EnvironmentalProcesses.remove_environmental_process/3`.
  """
  defdelegate remove_environmental_process(timeline_graph, process_type, opts \\ []),
    to: EnvironmentalProcesses

  @doc """
  Gets all active environmental processes affecting a specific entity.

  Delegates to `TimelineGraph.EnvironmentalProcesses.get_active_processes/3`.
  """
  defdelegate get_active_processes(timeline_graph, entity_id, opts \\ []),
    to: EnvironmentalProcesses

  @doc """
  Gets the combined effects of all environmental processes affecting an entity.

  Delegates to `TimelineGraph.EnvironmentalProcesses.get_combined_effects/3`.
  """
  defdelegate get_combined_effects(timeline_graph, entity_id, opts \\ []),
    to: EnvironmentalProcesses

  @doc """
  Adds a recurring environmental process (like day/night cycles).

  Delegates to `TimelineGraph.EnvironmentalProcesses.add_recurring_process/3`.
  """
  defdelegate add_recurring_process(timeline_graph, process_type, opts),
    to: EnvironmentalProcesses
end
