# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TimelineGraph do
  @moduledoc "Manages timeline integration with the Entity Timeline Graph Architecture (ADR-087).\n\nThis module connects the existing Timeline.AgentEntity system with \nauto-growing timelines, implementing the core concept that every entity owns\na timeline that grows automatically based on their capabilities and interactions.\n\n## Core Concepts\n\n- **Every Entity has a Timeline**: Created automatically when entities are instantiated\n- **Timeline Growth**: Automatic based on entity capabilities and interactions\n- **LOD Management**: Level of Detail scaling based on relevance and proximity\n- **Bridge Management**: Inter-timeline connections for coordination\n\n## Specialized Modules\n\nThis module delegates to specialized sub-modules for different aspects of functionality:\n\n- `TimelineGraph.EntityManager` - Entity creation, capabilities, and basic timeline operations\n- `TimelineGraph.LODManager` - Level of Detail management and promotion\n- `TimelineGraph.EnvironmentalProcesses` - Multi-entity environmental effects\n- `TimelineGraph.TimeConverter` - Time format conversion utilities\n\n## Usage\n\n```elixir\n# Create entity with automatic timeline attachment\n{:ok, entity_id} = TimelineGraph.create_entity(\"chair1\", \"Wooden Chair\", %{type: \"furniture\"})\n\n# Promote to agent with timeline growth triggers\n{:ok, updated_entity} = TimelineGraph.add_capabilities(entity_id, [:autonomous_operation])\n\n# Timeline automatically grows when entity becomes agent\nTimelineGraph.is_agent_timeline?(entity_id) # => true\n```\n"
  alias Timeline.AgentEntity
  alias Timeline
  alias Timeline.State
  alias TimelineGraph.EntityManager
  alias TimelineGraph.LODManager
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
          state: AriaAriaState.t(),
          bridge_strength: %{{entity_id(), entity_id()} => float()},
          lod_promotion_queue: [entity_id()],
          growth_triggers: %{entity_id() => [atom()]}
        }
  defstruct entities: %{},
            state: %State{},
            bridge_strength: %{},
            lod_promotion_queue: [],
            growth_triggers: %{}

  @doc "Creates a new TimelineGraph with empty entity and timeline registry.\n"
  @spec new() :: t()
  def new do
    %__MODULE__{state: AriaState.new()}
  end

  @doc "Creates a new entity with automatic timeline attachment.\n\nDelegates to `TimelineGraph.EntityManager.create_entity/5`.\n"
  defdelegate create_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []),
    to: EntityManager

  @doc "Adds capabilities to an entity, potentially transitioning it to agent status.\n\nDelegates to `TimelineGraph.EntityManager.add_capabilities/3`.\n"
  defdelegate add_capabilities(timeline_graph, entity_id, new_capabilities), to: EntityManager

  @doc "Checks if an entity is currently acting as an agent.\n\nDelegates to `TimelineGraph.EntityManager.is_currently_agent?/2`.\n"
  defdelegate is_currently_agent?(timeline_graph, entity_id), to: EntityManager

  @doc "Gets entity properties using entity-first StateV2 API.\n\nDelegates to `TimelineGraph.EntityManager.get_entity_properties/2`.\n"
  defdelegate get_entity_properties(timeline_graph, entity_id), to: EntityManager

  @doc "Sets an entity property and triggers timeline growth if appropriate.\n\nDelegates to `TimelineGraph.EntityManager.set_entity_property/4`.\n"
  defdelegate set_entity_property(timeline_graph, entity_id, predicate, value), to: EntityManager

  @doc "Gets all entity IDs currently managed by the timeline graph.\n\nDelegates to `TimelineGraph.EntityManager.get_entity_ids/1`.\n"
  defdelegate get_entity_ids(timeline_graph), to: EntityManager

  @doc "Gets all agent IDs (entities with action capabilities).\n\nDelegates to `TimelineGraph.EntityManager.get_agent_ids/1`.\n"
  defdelegate get_agent_ids(timeline_graph), to: EntityManager

  @doc "Gets the current LOD level for an entity's timeline.\n\nDelegates to `TimelineGraph.LODManager.get_lod/2`.\n"
  defdelegate get_lod(timeline_graph, entity_id), to: LODManager

  @doc "Processes the LOD promotion queue, upgrading timeline detail for active agents.\n\nDelegates to `TimelineGraph.LODManager.process_lod_promotions/1`.\n"
  defdelegate process_lod_promotions(timeline_graph), to: LODManager

  @doc "Sets the LOD level for a specific entity.\n\nDelegates to `TimelineGraph.LODManager.set_lod/3`.\n"
  defdelegate set_lod(timeline_graph, entity_id, new_lod), to: LODManager

  @doc "Adds an entity to the LOD promotion queue.\n\nDelegates to `TimelineGraph.LODManager.queue_for_promotion/2`.\n"
  defdelegate queue_for_promotion(timeline_graph, entity_id), to: LODManager

  @doc "Gets all entities at a specific LOD level.\n\nDelegates to `TimelineGraph.LODManager.get_entities_at_lod/2`.\n"
  defdelegate get_entities_at_lod(timeline_graph, target_lod), to: LODManager

  @doc "Gets LOD statistics for the timeline graph.\n\nDelegates to `TimelineGraph.LODManager.get_lod_statistics/1`.\n"
  defdelegate get_lod_statistics(timeline_graph), to: LODManager

  @doc "Automatically adjusts LOD levels based on entity activity and system performance.\n\nDelegates to `TimelineGraph.LODManager.auto_adjust_lod/2`.\n"
  defdelegate auto_adjust_lod(timeline_graph, opts \\ []), to: LODManager

  @doc "Adds a process or event that affects multiple entities over time.\n\nDelegates to `TimelineGraph.EnvironmentalProcesses.add_environmental_process/3`.\n"
  defdelegate add_environmental_process(timeline_graph, process_type, opts),
    to: EnvironmentalProcesses

  @doc "Removes an environmental process from all affected entities.\n\nDelegates to `TimelineGraph.EnvironmentalProcesses.remove_environmental_process/3`.\n"
  defdelegate remove_environmental_process(timeline_graph, process_type, opts \\ []),
    to: EnvironmentalProcesses

  @doc "Gets all active environmental processes affecting a specific entity.\n\nDelegates to `TimelineGraph.EnvironmentalProcesses.get_active_processes/3`.\n"
  defdelegate get_active_processes(timeline_graph, entity_id, opts \\ []),
    to: EnvironmentalProcesses

  @doc "Gets the combined effects of all environmental processes affecting an entity.\n\nDelegates to `TimelineGraph.EnvironmentalProcesses.get_combined_effects/3`.\n"
  defdelegate get_combined_effects(timeline_graph, entity_id, opts \\ []),
    to: EnvironmentalProcesses

  @doc "Adds a recurring environmental process (like day/night cycles).\n\nDelegates to `TimelineGraph.EnvironmentalProcesses.add_recurring_process/3`.\n"
  defdelegate add_recurring_process(timeline_graph, process_type, opts),
    to: EnvironmentalProcesses
end
