# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TimelineGraph.EntityManager do
  @moduledoc "Manages entity creation, capabilities, and basic timeline operations.\n\nThis module handles the core entity lifecycle within the TimelineGraph system,\nincluding entity creation with automatic timeline attachment, capability management,\nand entity property operations.\n"
  alias AriaTimeline.TimelineCore, as: Timeline
  alias Timeline.AgentEntity
  alias Timeline.Interval
  @type entity_id :: String.t()
  @type lod_level :: :very_low | :low | :medium | :high | :ultra_high
  @type entity_timeline :: %{
          entity: AgentEntity.participant(),
          timeline: Timeline.t(),
          lod: lod_level(),
          last_growth: DateTime.t(),
          bridges: %{entity_id() => atom()}
        }
  @doc "Creates a new entity with automatic timeline attachment.\n\nThis implements the core ADR-087 principle: every entity owns an auto-growing timeline.\nThe timeline starts with basic LOD and grows based on entity capabilities and interactions.\n\n## Examples\n\n```elixir\n# Create passive entity (furniture)\n{:ok, timeline_graph, \"chair1\"} = TimelineGraph.EntityManager.create_entity(\n  timeline_graph, \n  \"chair1\", \n  \"Wooden Chair\", \n  %{type: \"furniture\", material: \"wood\"}\n)\n\n# Create potential agent (NPC)\n{:ok, timeline_graph, \"guard\"} = TimelineGraph.EntityManager.create_entity(\n  timeline_graph,\n  \"guard\", \n  \"Tower Guard\", \n  %{type: \"humanoid\", location: \"tower\"}\n)\n```\n"
  @spec create_entity(map(), entity_id(), String.t(), map(), keyword()) ::
          {:ok, map(), entity_id()} | {:error, term()}
  def create_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []) do
    entity = AgentEntity.create_entity(entity_id, name, properties, opts)
    timeline = Timeline.new()
    initial_lod = determine_initial_lod(entity)
    now = DateTime.utc_now()
    timeline_with_creation = add_creation_interval(timeline, now)

    entity_timeline = %{
      entity: entity,
      timeline: timeline_with_creation,
      lod: initial_lod,
      last_growth: now,
      bridges: %{}
    }

    updated_state =
      Enum.reduce(properties, timeline_graph.state, fn {predicate, value}, state ->
        AriaState.set_fact(state, entity_id, predicate, value)
      end)

    updated_timeline_graph = %{
      timeline_graph
      | entities: Map.put(timeline_graph.entities, entity_id, entity_timeline),
        state: updated_state,
        growth_triggers: Map.put(timeline_graph.growth_triggers, entity_id, [:creation])
    }

    {:ok, updated_timeline_graph, entity_id}
  end

  @doc "Adds capabilities to an entity, potentially transitioning it to agent status.\n\nThis triggers timeline growth when the entity gains action capabilities,\nimplementing the ADR-087 principle that agents are entities with action capabilities.\n\n## Examples\n\n```elixir\n# Transform passive door into autonomous door\n{:ok, updated_graph} = TimelineGraph.EntityManager.add_capabilities(\n  timeline_graph, \n  \"door1\", \n  [:autonomous_operation, :decision_making]\n)\n\n# Entity is now an agent with enhanced timeline growth\nTimelineGraph.is_currently_agent?(updated_graph, \"door1\") # => true\n```\n"
  @spec add_capabilities(map(), entity_id(), [atom()]) :: {:ok, map()} | {:error, term()}
  def add_capabilities(timeline_graph, entity_id, new_capabilities) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        old_entity = entity_timeline.entity
        updated_entity = AgentEntity.add_capabilities(old_entity, new_capabilities)
        was_agent = AgentEntity.is_currently_agent?(old_entity)
        is_now_agent = AgentEntity.is_currently_agent?(updated_entity)

        updated_timeline =
          grow_timeline_for_capabilities(
            entity_timeline.timeline,
            new_capabilities,
            transition_to_agent: !was_agent && is_now_agent
          )

        new_lod =
          if is_now_agent do
            TimelineGraph.LODManager.promote_lod(entity_timeline.lod)
          else
            entity_timeline.lod
          end

        updated_entity_timeline = %{
          entity_timeline
          | entity: updated_entity,
            timeline: updated_timeline,
            lod: new_lod,
            last_growth: DateTime.utc_now()
        }

        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
        }

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

  @doc "Checks if an entity is currently acting as an agent.\n\nUses the existing AgentEntity capability-based determination.\n"
  @spec is_currently_agent?(map(), entity_id()) :: boolean()
  def is_currently_agent?(timeline_graph, entity_id) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil -> false
      entity_timeline -> AgentEntity.is_currently_agent?(entity_timeline.entity)
    end
  end

  @doc "Gets entity properties using entity-first StateV2 API.\n"
  @spec get_entity_properties(map(), entity_id()) :: %{String.t() => any()}
  def get_entity_properties(timeline_graph, entity_id) do
    AriaState.get_subject_properties(timeline_graph.state, entity_id)
  end

  @doc "Sets an entity property and triggers timeline growth if appropriate.\n"
  @spec set_entity_property(map(), entity_id(), String.t(), any()) ::
          {:ok, map()} | {:error, term()}
  def set_entity_property(timeline_graph, entity_id, predicate, value) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        updated_state = AriaState.set_fact(timeline_graph.state, entity_id, predicate, value)

        updated_timeline =
          grow_timeline_for_property_change(
            entity_timeline.timeline,
            predicate,
            value
          )

        updated_entity_timeline = %{
          entity_timeline
          | timeline: updated_timeline,
            last_growth: DateTime.utc_now()
        }

        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline),
            state: updated_state
        }

        {:ok, updated_timeline_graph}
    end
  end

  @doc "Gets all entity IDs currently managed by the timeline graph.\n"
  @spec get_entity_ids(map()) :: [entity_id()]
  def get_entity_ids(timeline_graph) do
    Map.keys(timeline_graph.entities)
  end

  @doc "Gets all agent IDs (entities with action capabilities).\n"
  @spec get_agent_ids(map()) :: [entity_id()]
  def get_agent_ids(timeline_graph) do
    timeline_graph.entities
    |> Enum.filter(fn {_id, entity_timeline} ->
      AgentEntity.is_currently_agent?(entity_timeline.entity)
    end)
    |> Enum.map(fn {id, _timeline} -> id end)
  end

  defp determine_initial_lod(entity) do
    cond do
      AgentEntity.is_currently_agent?(entity) -> :medium
      AgentEntity.entity?(entity) -> :low
      true -> :very_low
    end
  end

  defp add_creation_interval(timeline, creation_time) do
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

    capability_interval =
      Interval.new(
        now,
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

    property_interval =
      Interval.new(
        now,
        DateTime.add(now, 1, :second),
        metadata: %{type: :property_change, predicate: predicate, new_value: value}
      )

    Timeline.add_interval(timeline, property_interval)
  end
end
