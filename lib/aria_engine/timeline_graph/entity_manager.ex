# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph.EntityManager do
  @moduledoc """
  Manages entity creation, capabilities, and basic timeline operations.

  This module handles the core entity lifecycle within the TimelineGraph system,
  including entity creation with automatic timeline attachment, capability management,
  and entity property operations.
  """

  alias Timeline.AgentEntity
  alias Timeline
  alias Timeline.Interval
  alias AriaEngine.StateV2

  @type entity_id :: String.t()
  @type lod_level :: :very_low | :low | :medium | :high | :ultra_high
  @type entity_timeline :: %{
          entity: AgentEntity.participant(),
          timeline: Timeline.t(),
          lod: lod_level(),
          last_growth: DateTime.t(),
          bridges: %{entity_id() => atom()}
        }

  @doc """
  Creates a new entity with automatic timeline attachment.

  This implements the core ADR-087 principle: every entity owns an auto-growing timeline.
  The timeline starts with basic LOD and grows based on entity capabilities and interactions.

  ## Examples

  ```elixir
  # Create passive entity (furniture)
  {:ok, timeline_graph, "chair1"} = TimelineGraph.EntityManager.create_entity(
    timeline_graph, 
    "chair1", 
    "Wooden Chair", 
    %{type: "furniture", material: "wood"}
  )

  # Create potential agent (NPC)
  {:ok, timeline_graph, "guard"} = TimelineGraph.EntityManager.create_entity(
    timeline_graph,
    "guard", 
    "Tower Guard", 
    %{type: "humanoid", location: "tower"}
  )
  ```
  """
  @spec create_entity(map(), entity_id(), String.t(), map(), keyword()) ::
          {:ok, map(), entity_id()} | {:error, term()}
  def create_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []) do
    # Create entity using existing AgentEntity system
    entity = AgentEntity.create_entity(entity_id, name, properties, opts)

    # Create timeline for this entity (Timeline.new/0 for basic usage)
    timeline = Timeline.new()

    # Determine initial LOD based on entity type
    initial_lod = determine_initial_lod(entity)

    # Add timeline growth trigger for current time (entity creation event)
    now = DateTime.utc_now()
    timeline_with_creation = add_creation_interval(timeline, now)

    # Create entity timeline record
    entity_timeline = %{
      entity: entity,
      timeline: timeline_with_creation,
      lod: initial_lod,
      last_growth: now,
      bridges: %{}
    }

    # Update state with entity properties (using entity-first StateV2)
    updated_state =
      Enum.reduce(properties, timeline_graph.state, fn {predicate, value}, state ->
        StateV2.set_fact(state, entity_id, predicate, value)
      end)

    # Add entity to timeline graph
    updated_timeline_graph = %{
      timeline_graph
      | entities: Map.put(timeline_graph.entities, entity_id, entity_timeline),
        state: updated_state,
        growth_triggers: Map.put(timeline_graph.growth_triggers, entity_id, [:creation])
    }

    {:ok, updated_timeline_graph, entity_id}
  end

  @doc """
  Adds capabilities to an entity, potentially transitioning it to agent status.

  This triggers timeline growth when the entity gains action capabilities,
  implementing the ADR-087 principle that agents are entities with action capabilities.

  ## Examples

  ```elixir
  # Transform passive door into autonomous door
  {:ok, updated_graph} = TimelineGraph.EntityManager.add_capabilities(
    timeline_graph, 
    "door1", 
    [:autonomous_operation, :decision_making]
  )

  # Entity is now an agent with enhanced timeline growth
  TimelineGraph.is_currently_agent?(updated_graph, "door1") # => true
  ```
  """
  @spec add_capabilities(map(), entity_id(), [atom()]) :: {:ok, map()} | {:error, term()}
  def add_capabilities(timeline_graph, entity_id, new_capabilities) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        # Update entity with new capabilities
        old_entity = entity_timeline.entity
        updated_entity = AgentEntity.add_capabilities(old_entity, new_capabilities)

        # Check if this transitions entity to agent status
        was_agent = AgentEntity.is_currently_agent?(old_entity)
        is_now_agent = AgentEntity.is_currently_agent?(updated_entity)

        # Grow timeline if transitioning to agent or gaining significant capabilities
        updated_timeline =
          grow_timeline_for_capabilities(
            entity_timeline.timeline,
            new_capabilities,
            transition_to_agent: !was_agent && is_now_agent
          )

        # Determine new LOD based on agent status
        new_lod =
          if is_now_agent do
            TimelineGraph.LODManager.promote_lod(entity_timeline.lod)
          else
            entity_timeline.lod
          end

        # Update entity timeline record
        updated_entity_timeline = %{
          entity_timeline
          | entity: updated_entity,
            timeline: updated_timeline,
            lod: new_lod,
            last_growth: DateTime.utc_now()
        }

        # Update timeline graph
        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
        }

        # Add to LOD promotion queue if became agent
        final_timeline_graph =
          if !was_agent && is_now_agent do
            %{
              updated_timeline_graph
              | lod_promotion_queue: [entity_id | updated_timeline_graph.lod_promotion_queue]
            }
          else
            updated_timeline_graph
          end

        {:ok, final_timeline_graph}
    end
  end

  @doc """
  Checks if an entity is currently acting as an agent.

  Uses the existing AgentEntity capability-based determination.
  """
  @spec is_currently_agent?(map(), entity_id()) :: boolean()
  def is_currently_agent?(timeline_graph, entity_id) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil -> false
      entity_timeline -> AgentEntity.is_currently_agent?(entity_timeline.entity)
    end
  end

  @doc """
  Gets entity properties using entity-first StateV2 API.
  """
  @spec get_entity_properties(map(), entity_id()) :: %{String.t() => any()}
  def get_entity_properties(timeline_graph, entity_id) do
    StateV2.get_properties(timeline_graph.state, entity_id)
  end

  @doc """
  Sets an entity property and triggers timeline growth if appropriate.
  """
  @spec set_entity_property(map(), entity_id(), String.t(), any()) :: {:ok, map()} | {:error, term()}
  def set_entity_property(timeline_graph, entity_id, predicate, value) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        # Update state using entity-first API
        updated_state = StateV2.set_fact(timeline_graph.state, entity_id, predicate, value)

        # Trigger timeline growth for property change
        updated_timeline =
          grow_timeline_for_property_change(
            entity_timeline.timeline,
            predicate,
            value
          )

        # Update entity timeline record
        updated_entity_timeline = %{
          entity_timeline
          | timeline: updated_timeline,
            last_growth: DateTime.utc_now()
        }

        # Update timeline graph
        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline),
            state: updated_state
        }

        {:ok, updated_timeline_graph}
    end
  end

  @doc """
  Gets all entity IDs currently managed by the timeline graph.
  """
  @spec get_entity_ids(map()) :: [entity_id()]
  def get_entity_ids(timeline_graph) do
    Map.keys(timeline_graph.entities)
  end

  @doc """
  Gets all agent IDs (entities with action capabilities).
  """
  @spec get_agent_ids(map()) :: [entity_id()]
  def get_agent_ids(timeline_graph) do
    timeline_graph.entities
    |> Enum.filter(fn {_id, entity_timeline} ->
      AgentEntity.is_currently_agent?(entity_timeline.entity)
    end)
    |> Enum.map(fn {id, _timeline} -> id end)
  end

  # Private helper functions

  defp determine_initial_lod(entity) do
    cond do
      AgentEntity.is_currently_agent?(entity) -> :medium
      AgentEntity.entity?(entity) -> :low
      true -> :very_low
    end
  end

  defp add_creation_interval(timeline, creation_time) do
    # Add interval representing entity creation/existence
    # Use a far future time for "indefinite" existence
    # 1 year from creation
    far_future = DateTime.add(creation_time, 365 * 24 * 3600, :second)

    creation_interval =
      Interval.new(
        creation_time,
        far_future,
        metadata: %{type: :creation, event: "entity_created"}
      )

    Timeline.add_interval(timeline, creation_interval)
  end

  defp grow_timeline_for_capabilities(timeline, new_capabilities, opts) do
    transition_to_agent = Keyword.get(opts, :transition_to_agent, false)
    now = DateTime.utc_now()

    # Add interval for capability acquisition
    capability_interval =
      Interval.new(
        now,
        # Instantaneous event
        DateTime.add(now, 1, :second),
        metadata: %{
          type: :capability_change,
          capabilities_added: new_capabilities,
          became_agent: transition_to_agent
        }
      )

    Timeline.add_interval(timeline, capability_interval)
  end

  defp grow_timeline_for_property_change(timeline, predicate, value) do
    now = DateTime.utc_now()

    # Add interval for property change
    property_interval =
      Interval.new(
        now,
        # Instantaneous event
        DateTime.add(now, 1, :second),
        metadata: %{
          type: :property_change,
          predicate: predicate,
          new_value: value
        }
      )

    Timeline.add_interval(timeline, property_interval)
  end
end
