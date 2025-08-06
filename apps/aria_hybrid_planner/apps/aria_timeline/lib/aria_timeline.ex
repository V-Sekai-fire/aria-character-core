# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline do
  @moduledoc """
  External API for AriaTimeline - Timeline management and temporal processing.

  This module provides the public interface for AriaTimeline functionality, including:
  - Timeline creation and management
  - Interval operations and Allen's interval algebra
  - Agent and entity management
  - Timeline graph operations with LOD management
  - Environmental processes and bridge management
  - STN integration and time conversion utilities

  All cross-app communication should use this external API rather than importing
  internal AriaTimeline modules directly.

  ## Timeline Management

      # Create a new timeline
      timeline = AriaTimeline.new_timeline()

      # Add intervals to timeline
      interval = AriaTimeline.create_interval(start_time, end_time)
      timeline = AriaTimeline.add_interval(timeline, interval)

  ## Interval Operations

      # Create intervals with DateTime
      start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      end_dt = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      interval = AriaTimeline.create_interval(start_dt, end_dt)

      # Create intervals from ISO 8601 strings
      interval = AriaTimeline.create_fixed_schedule("2025-06-22T10:00:00Z", "2025-06-22T11:00:00Z")

      # Check interval relationships
      overlaps = AriaTimeline.intervals_overlap?(interval1, interval2)
      relation = AriaTimeline.allen_relation(interval1, interval2)

  ## Agent and Entity Management

      # Create agents and entities
      agent = AriaTimeline.create_agent("aria", "Aria VTuber", %{personality: "helpful"})
      entity = AriaTimeline.create_entity("room1", "Conference Room", %{capacity: 10})

      # Manage capabilities
      agent = AriaTimeline.add_capability(agent, :autonomous_operation)
      can_act = AriaTimeline.can_perform_action?(agent, :some_action)

  ## Timeline Graph Operations

      # Create timeline graph with entity management
      graph = AriaTimeline.new_timeline_graph()
      {:ok, entity_id} = AriaTimeline.create_graph_entity(graph, "chair1", "Wooden Chair", %{type: "furniture"})

      # LOD management
      graph = AriaTimeline.set_lod(graph, entity_id, :high)
      graph = AriaTimeline.process_lod_promotions(graph)

  ## State Management

      # Create and manage timeline state
      state = AriaTimeline.new_state()
      state = AriaTimeline.set_fact(state, "status", "agent1", "active")
      {:ok, status} = AriaTimeline.get_fact(state, "status", "agent1")
  """

  # Timeline Management API
  defdelegate new_timeline(), to: Timeline, as: :new
  defdelegate add_interval(timeline, interval), to: Timeline
  defdelegate add_intervals(timeline, intervals), to: Timeline
  defdelegate remove_interval(timeline, interval_id), to: Timeline

  # Timeline Core STN Operations API
  defdelegate new(), to: Timeline, as: :new
  defdelegate new(opts), to: Timeline, as: :new
  defdelegate add_constraint(timeline, from_point, to_point, constraint), to: Timeline
  defdelegate add_time_point(timeline, time_point), to: Timeline
  defdelegate time_points(timeline), to: Timeline
  defdelegate get_stn(timeline), to: Timeline
  defdelegate consistent?(timeline), to: Timeline

  # Interval Creation and Management API
  defdelegate create_interval(start_time, end_time), to: Timeline.Interval, as: :new
  defdelegate create_interval(start_time, end_time, opts), to: Timeline.Interval, as: :new
  defdelegate create_fixed_schedule(start_iso8601, end_iso8601), to: Timeline.Interval, as: :new_fixed_schedule
  defdelegate create_fixed_schedule(start_iso8601, end_iso8601, opts), to: Timeline.Interval, as: :new_fixed_schedule
  defdelegate create_fixed_schedule(temporal_spec), to: Timeline.Interval, as: :new_fixed_schedule
  defdelegate create_floating_duration(duration_iso8601), to: Timeline.Interval, as: :new_floating_duration
  defdelegate create_floating_duration(duration_iso8601, opts), to: Timeline.Interval, as: :new_floating_duration
  defdelegate create_open_ended_start(start_iso8601), to: Timeline.Interval, as: :new_open_ended_start
  defdelegate create_open_ended_end(end_iso8601), to: Timeline.Interval, as: :new_open_ended_end
  defdelegate create_interval_from_duration(start_time, duration, unit), to: Timeline.Interval, as: :from_duration

  # Interval Operations API
  defdelegate interval_duration_ms(interval), to: Timeline.Interval, as: :duration_ms
  defdelegate interval_duration_seconds(interval), to: Timeline.Interval, as: :duration_seconds
  defdelegate interval_duration(interval), to: Timeline.Interval, as: :duration
  defdelegate interval_duration_in_unit(interval, unit), to: Timeline.Interval, as: :duration_in_unit
  defdelegate interval_contains?(interval, time_point), to: Timeline.Interval, as: :contains?
  defdelegate intervals_overlap?(interval1, interval2), to: Timeline.Interval, as: :overlaps?
  defdelegate allen_relation(interval1, interval2), to: Timeline.Interval
  defdelegate interval_to_stn_points(interval, unit), to: Timeline.Interval, as: :to_stn_points
  defdelegate interval_agent?(interval), to: Timeline.Interval, as: :agent?
  defdelegate interval_entity?(interval), to: Timeline.Interval, as: :entity?

  # Agent Management API
  defdelegate create_agent(id, name, properties \\ %{}, opts \\ []), to: Timeline.AgentEntity
  defdelegate agent?(participant), to: Timeline.AgentEntity
  defdelegate has_capability?(participant, capability), to: Timeline.AgentEntity
  defdelegate add_capability(agent, capability), to: Timeline.AgentEntity
  defdelegate add_capabilities(participant, new_capabilities), to: Timeline.AgentEntity
  defdelegate remove_capabilities(participant, capabilities_to_remove), to: Timeline.AgentEntity
  defdelegate can_perform_action?(participant, action), to: Timeline.AgentEntity
  defdelegate is_currently_agent?(participant), to: Timeline.AgentEntity
  defdelegate transition_to_agent(participant, action_capabilities), to: Timeline.AgentEntity
  defdelegate transition_to_entity(participant), to: Timeline.AgentEntity

  # Entity Management API
  defdelegate create_entity(id, name, properties \\ %{}, opts \\ []), to: Timeline.AgentEntity
  defdelegate entity?(participant), to: Timeline.AgentEntity
  defdelegate owned_by?(entity, agent_id), to: Timeline.AgentEntity
  defdelegate has_owner?(entity), to: Timeline.AgentEntity
  defdelegate transfer_ownership(entity, new_owner_id), to: Timeline.AgentEntity
  defdelegate remove_ownership(entity), to: Timeline.AgentEntity

  # Property Management API
  defdelegate update_properties(participant, new_properties), to: Timeline.AgentEntity
  defdelegate get_property(participant, property_key), to: Timeline.AgentEntity
  defdelegate set_property(participant, property_key, value), to: Timeline.AgentEntity
  defdelegate validate_participant(participant), to: Timeline.AgentEntity, as: :valid?

  # Timeline Graph API
  defdelegate new_timeline_graph(), to: TimelineGraph, as: :new
  defdelegate create_graph_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []), to: TimelineGraph, as: :create_entity
  defdelegate add_graph_capabilities(timeline_graph, entity_id, new_capabilities), to: TimelineGraph, as: :add_capabilities
  defdelegate is_graph_agent?(timeline_graph, entity_id), to: TimelineGraph, as: :is_currently_agent?
  defdelegate get_entity_properties(timeline_graph, entity_id), to: TimelineGraph
  defdelegate set_entity_property(timeline_graph, entity_id, predicate, value), to: TimelineGraph
  defdelegate get_entity_ids(timeline_graph), to: TimelineGraph
  defdelegate get_agent_ids(timeline_graph), to: TimelineGraph

  # LOD Management API
  defdelegate get_lod(timeline_graph, entity_id), to: TimelineGraph
  defdelegate set_lod(timeline_graph, entity_id, new_lod), to: TimelineGraph
  defdelegate queue_for_promotion(timeline_graph, entity_id), to: TimelineGraph
  defdelegate process_lod_promotions(timeline_graph), to: TimelineGraph
  defdelegate get_entities_at_lod(timeline_graph, target_lod), to: TimelineGraph
  defdelegate get_lod_statistics(timeline_graph), to: TimelineGraph
  defdelegate auto_adjust_lod(timeline_graph, opts \\ []), to: TimelineGraph

  # Environmental Processes API
  defdelegate add_environmental_process(timeline_graph, process_type, opts), to: TimelineGraph
  defdelegate remove_environmental_process(timeline_graph, process_type, opts \\ []), to: TimelineGraph
  defdelegate get_active_processes(timeline_graph, entity_id, opts \\ []), to: TimelineGraph
  defdelegate get_combined_effects(timeline_graph, entity_id, opts \\ []), to: TimelineGraph
  defdelegate add_recurring_process(timeline_graph, process_type, opts), to: TimelineGraph

  # State Management API
  defdelegate new_state(), to: Timeline.State, as: :new
  defdelegate new_state(data), to: Timeline.State, as: :new
  defdelegate get_fact(state, predicate, subject), to: Timeline.State
  defdelegate set_fact(state, predicate, subject, value), to: Timeline.State
  defdelegate has_subject?(state, predicate, subject), to: Timeline.State
  defdelegate get_properties(state, subject), to: Timeline.State

  @doc """
  Creates a complete timeline setup with agents, entities, and intervals.

  This is a convenience function that combines timeline creation with participant
  and interval setup in one call.

  ## Parameters

  - `options`: Configuration options
    - `:agents`: List of agent specifications to create
    - `:entities`: List of entity specifications to create
    - `:intervals`: List of interval specifications to add

  ## Examples

      iex> agents = [%{id: "aria", name: "Aria VTuber", properties: %{personality: "helpful"}}]
      iex> entities = [%{id: "room1", name: "Conference Room", properties: %{capacity: 10}}]
      iex> timeline = AriaTimeline.setup_timeline(agents: agents, entities: entities)
      iex> timeline.intervals
      []
  """
  def setup_timeline(options \\ []) do
    timeline = new_timeline()

    # Create agents if provided
    agents = Keyword.get(options, :agents, [])
    _created_agents = Enum.map(agents, fn agent_spec ->
      create_agent(
        agent_spec[:id] || agent_spec["id"],
        agent_spec[:name] || agent_spec["name"],
        agent_spec[:properties] || agent_spec["properties"] || %{},
        agent_spec[:opts] || agent_spec["opts"] || []
      )
    end)

    # Create entities if provided
    entities = Keyword.get(options, :entities, [])
    _created_entities = Enum.map(entities, fn entity_spec ->
      create_entity(
        entity_spec[:id] || entity_spec["id"],
        entity_spec[:name] || entity_spec["name"],
        entity_spec[:properties] || entity_spec["properties"] || %{},
        entity_spec[:opts] || entity_spec["opts"] || []
      )
    end)

    # Add intervals if provided
    intervals = Keyword.get(options, :intervals, [])
    Enum.reduce(intervals, timeline, fn interval_spec, acc ->
      interval = case interval_spec do
        %{start_time: start_time, end_time: end_time} when is_struct(start_time, DateTime) and is_struct(end_time, DateTime) ->
          create_interval(start_time, end_time, interval_spec[:opts] || [])

        %{start_iso8601: start_iso, end_iso8601: end_iso} ->
          create_fixed_schedule(start_iso, end_iso, interval_spec[:opts] || [])

        %{duration_iso8601: duration} ->
          create_floating_duration(duration, interval_spec[:opts] || [])

        _ ->
          raise ArgumentError, "Invalid interval specification: #{inspect(interval_spec)}"
      end

      add_interval(acc, interval)
    end)
  end

  @doc """
  Creates a timeline graph with comprehensive entity and LOD management.

  This is a convenience function that sets up a complete timeline graph with
  entities, agents, and LOD configuration.

  ## Parameters

  - `options`: Configuration options
    - `:entities`: List of entity specifications to create
    - `:default_lod`: Default LOD level for new entities
    - `:environmental_processes`: List of environmental processes to add

  ## Examples

      iex> entities = [%{id: "chair1", name: "Wooden Chair", properties: %{type: "furniture"}}]
      iex> graph = AriaTimeline.setup_timeline_graph(entities: entities, default_lod: :medium)
      iex> AriaTimeline.get_entity_ids(graph)
      ["chair1"]
  """
  def setup_timeline_graph(options \\ []) do
    graph = new_timeline_graph()
    default_lod = Keyword.get(options, :default_lod, :low)

    # Create entities if provided
    entities = Keyword.get(options, :entities, [])
    graph_with_entities = Enum.reduce(entities, graph, fn entity_spec, acc ->
      entity_id = entity_spec[:id] || entity_spec["id"]
      name = entity_spec[:name] || entity_spec["name"]
      properties = entity_spec[:properties] || entity_spec["properties"] || %{}
      opts = entity_spec[:opts] || entity_spec["opts"] || []

      {:ok, updated_graph} = create_graph_entity(acc, entity_id, name, properties, opts)
      set_lod(updated_graph, entity_id, default_lod)
    end)

    # Add environmental processes if provided
    processes = Keyword.get(options, :environmental_processes, [])
    Enum.reduce(processes, graph_with_entities, fn process_spec, acc ->
      process_type = process_spec[:type] || process_spec["type"]
      opts = process_spec[:opts] || process_spec["opts"] || []
      add_environmental_process(acc, process_type, opts)
    end)
  end

  @doc """
  Processes temporal specifications and creates appropriate intervals.

  This function handles various temporal specification formats and creates
  the corresponding interval objects.

  ## Parameters

  - `temporal_specs`: List of temporal specifications in various formats

  ## Examples

      iex> specs = [
      ...>   %{start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"},
      ...>   %{duration: "PT2H"}
      ...> ]
      iex> intervals = AriaTimeline.process_temporal_specifications(specs)
      iex> length(intervals)
      2
  """
  def process_temporal_specifications(temporal_specs) when is_list(temporal_specs) do
    Enum.map(temporal_specs, fn spec ->
      case spec do
        %{start: start_iso, end: end_iso} ->
          create_fixed_schedule(start_iso, end_iso)

        %{start: start_iso} ->
          create_open_ended_start(start_iso)

        %{end: end_iso} ->
          create_open_ended_end(end_iso)

        %{duration: duration_iso} ->
          create_floating_duration(duration_iso)

        %{start_time: start_dt, end_time: end_dt} when is_struct(start_dt, DateTime) and is_struct(end_dt, DateTime) ->
          create_interval(start_dt, end_dt)

        _ ->
          raise ArgumentError, "Invalid temporal specification: #{inspect(spec)}"
      end
    end)
  end

  @doc """
  Analyzes timeline relationships and returns Allen's interval algebra relations.

  This function takes a list of intervals and returns all pairwise relationships
  using Allen's interval algebra.

  ## Parameters

  - `intervals`: List of intervals to analyze

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> interval1 = AriaTimeline.create_interval(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2023-01-01 02:00:00], "Etc/UTC")
      iex> interval2 = AriaTimeline.create_interval(start2, end2)
      iex> relations = AriaTimeline.analyze_timeline_relationships([interval1, interval2])
      iex> relations[{interval1.id, interval2.id}]
      :meets
  """
  def analyze_timeline_relationships(intervals) when is_list(intervals) do
    for i1 <- intervals, i2 <- intervals, i1.id != i2.id, into: %{} do
      {{i1.id, i2.id}, allen_relation(i1, i2)}
    end
  end

  @doc """
  Converts timeline data to STN (Simple Temporal Network) format.

  This function extracts temporal constraints from intervals and converts them
  to STN format for temporal reasoning.

  ## Parameters

  - `intervals`: List of intervals to convert
  - `unit`: Time unit for STN representation

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> interval = AriaTimeline.create_interval(start_dt, end_dt)
      iex> stn_data = AriaTimeline.convert_to_stn([interval], :second)
      iex> Map.has_key?(stn_data, :constraints)
      true
  """
  def convert_to_stn(intervals, unit \\ :second) when is_list(intervals) do
    constraints = Enum.map(intervals, fn interval ->
      {start_point, end_point, duration} = interval_to_stn_points(interval, unit)
      %{
        start_point: start_point,
        end_point: end_point,
        duration: duration,
        interval_id: interval.id
      }
    end)

    %{
      constraints: constraints,
      unit: unit,
      interval_count: length(intervals)
    }
  end
end
