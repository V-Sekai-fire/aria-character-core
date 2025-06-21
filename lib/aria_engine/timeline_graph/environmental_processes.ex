# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph.EnvironmentalProcesses do
  @moduledoc """
  Manages environmental processes that affect multiple entities over time.

  This module supports Phase 2 environmental dynamics from ADR-085, enabling
  NPCs to react to environmental changes like weather, resource depletion,
  day/night cycles, and other world-state changes.
  """

  alias Timeline
  alias Timeline.Interval

  @type entity_id :: String.t()
  @type process_type :: atom()
  @type effects :: %{atom() => any()}

  @doc """
  Adds a process or event that affects multiple entities over time.

  This supports Phase 2 environmental dynamics from ADR-085, enabling
  NPCs to react to environmental changes like weather, resource depletion, etc.

  ## Examples

  ```elixir
  # Add weather event affecting outdoor NPCs
  {:ok, updated_graph} = TimelineGraph.EnvironmentalProcesses.add_environmental_process(
    timeline_graph,
    :storm_weather,
    affects: ["guard", "farmer", "merchant"],
    start_time: DateTime.utc_now(),
    duration_hours: 3,
    effects: %{visibility: :reduced, movement_speed: 0.5}
  )

  # Add day/night cycle affecting all entities
  {:ok, updated_graph} = TimelineGraph.EnvironmentalProcesses.add_environmental_process(
    timeline_graph,
    :night_cycle,
    affects: :all,
    start_time: ~U[2025-06-17 20:00:00Z],
    duration_hours: 10,
    effects: %{lighting: :dark, npc_activity: :reduced}
  )
  ```
  """
  @spec add_environmental_process(map(), process_type(), keyword()) :: {:ok, map()} | {:error, term()}
  def add_environmental_process(timeline_graph, process_type, opts) do
    affected_entities = resolve_affected_entities(timeline_graph, Keyword.get(opts, :affects, []))
    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
    duration_hours = Keyword.get(opts, :duration_hours, 1)
    effects = Keyword.get(opts, :effects, %{})
    intensity = Keyword.get(opts, :intensity, :medium)
    priority = Keyword.get(opts, :priority, :low)

    end_time = DateTime.add(start_time, duration_hours * 3600, :second)

    # Apply process to all affected entities
    Enum.reduce_while(affected_entities, {:ok, timeline_graph}, fn entity_id, {:ok, graph} ->
      case Map.get(graph.entities, entity_id) do
        nil ->
          # Skip non-existent entities
          {:cont, {:ok, graph}}

        entity_timeline ->
          # Create process interval
          process_interval =
            Interval.new(
              start_time,
              end_time,
              metadata: %{
                type: :environmental_process,
                process_type: process_type,
                effects: effects,
                intensity: intensity,
                priority: priority,
                affected_entity: entity_id,
                global_process: true
              }
            )

          # Add to entity timeline
          updated_timeline = Timeline.add_interval(entity_timeline.timeline, process_interval)

          updated_entity_timeline = %{
            entity_timeline
            | timeline: updated_timeline,
              last_growth: DateTime.utc_now()
          }

          updated_graph = %{
            graph
            | entities: Map.put(graph.entities, entity_id, updated_entity_timeline)
          }

          {:cont, {:ok, updated_graph}}
      end
    end)
  end

  @doc """
  Removes an environmental process from all affected entities.

  ## Examples

  ```elixir
  # Remove storm weather from all entities
  {:ok, updated_graph} = TimelineGraph.EnvironmentalProcesses.remove_environmental_process(
    timeline_graph,
    :storm_weather
  )

  # Remove process from specific entities only
  {:ok, updated_graph} = TimelineGraph.EnvironmentalProcesses.remove_environmental_process(
    timeline_graph,
    :night_cycle,
    affects: ["indoor_npc1", "indoor_npc2"]
  )
  ```
  """
  @spec remove_environmental_process(map(), process_type(), keyword()) :: {:ok, map()} | {:error, term()}
  def remove_environmental_process(timeline_graph, process_type, opts \\ []) do
    affected_entities = 
      case Keyword.get(opts, :affects) do
        nil -> Map.keys(timeline_graph.entities)  # Remove from all entities
        entities -> resolve_affected_entities(timeline_graph, entities)
      end

    # Remove process from all affected entities
    Enum.reduce(affected_entities, {:ok, timeline_graph}, fn entity_id, {:ok, graph} ->
      case Map.get(graph.entities, entity_id) do
        nil ->
          {:ok, graph}

        entity_timeline ->
          # Find and remove matching environmental process intervals
          intervals_to_remove = find_environmental_process_intervals(entity_timeline.timeline, process_type)

          updated_timeline =
            Enum.reduce(intervals_to_remove, entity_timeline.timeline, fn interval, timeline ->
              Timeline.remove_interval(timeline, interval.id)
            end)

          updated_entity_timeline = %{
            entity_timeline
            | timeline: updated_timeline,
              last_growth: DateTime.utc_now()
          }

          updated_graph = %{
            graph
            | entities: Map.put(graph.entities, entity_id, updated_entity_timeline)
          }

          {:ok, updated_graph}
      end
    end)
  end

  @doc """
  Gets all active environmental processes affecting a specific entity.

  ## Examples

  ```elixir
  # Get all environmental processes affecting a guard
  processes = TimelineGraph.EnvironmentalProcesses.get_active_processes(
    timeline_graph,
    "guard"
  )

  # Get processes active at a specific time
  processes = TimelineGraph.EnvironmentalProcesses.get_active_processes(
    timeline_graph,
    "guard",
    at_time: ~U[2025-06-17 14:30:00Z]
  )
  ```
  """
  @spec get_active_processes(map(), entity_id(), keyword()) :: [Interval.t()] | {:error, term()}
  def get_active_processes(timeline_graph, entity_id, opts \\ []) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        check_time = Keyword.get(opts, :at_time, DateTime.utc_now())
        
        # Find all environmental process intervals active at the specified time
        find_active_environmental_processes(entity_timeline.timeline, check_time)
    end
  end

  @doc """
  Gets the combined effects of all environmental processes affecting an entity.

  This function merges the effects from all active environmental processes,
  with higher intensity processes taking precedence for conflicting effects.

  ## Examples

  ```elixir
  # Get combined environmental effects for an entity
  effects = TimelineGraph.EnvironmentalProcesses.get_combined_effects(
    timeline_graph,
    "farmer"
  )
  # => %{visibility: :reduced, movement_speed: 0.7, lighting: :dim}
  ```
  """
  @spec get_combined_effects(map(), entity_id(), keyword()) :: effects() | {:error, term()}
  def get_combined_effects(timeline_graph, entity_id, opts \\ []) do
    case get_active_processes(timeline_graph, entity_id, opts) do
      {:error, reason} ->
        {:error, reason}

      active_processes ->
        # Sort by intensity and priority, then merge effects
        active_processes
        |> Enum.sort_by(fn interval ->
          intensity = get_in(interval.metadata, [:intensity]) || :medium
          priority = get_in(interval.metadata, [:priority]) || :low
          {intensity_value(intensity), priority_value(priority)}
        end, :desc)
        |> Enum.reduce(%{}, fn interval, acc_effects ->
          process_effects = get_in(interval.metadata, [:effects]) || %{}
          Map.merge(acc_effects, process_effects)
        end)
    end
  end

  @doc """
  Adds a recurring environmental process (like day/night cycles).

  ## Examples

  ```elixir
  # Add daily day/night cycle
  {:ok, updated_graph} = TimelineGraph.EnvironmentalProcesses.add_recurring_process(
    timeline_graph,
    :day_cycle,
    affects: :all,
    start_time: ~U[2025-06-17 06:00:00Z],
    duration_hours: 12,
    repeat_every_hours: 24,
    effects: %{lighting: :bright, npc_activity: :normal}
  )
  ```
  """
  @spec add_recurring_process(map(), process_type(), keyword()) :: {:ok, map()} | {:error, term()}
  def add_recurring_process(timeline_graph, process_type, opts) do
    repeat_every_hours = Keyword.get(opts, :repeat_every_hours, 24)
    repeat_count = Keyword.get(opts, :repeat_count, 365)  # Default to 1 year
    
    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
    
    # Create multiple instances of the process
    Enum.reduce_while(0..(repeat_count - 1), {:ok, timeline_graph}, fn iteration, {:ok, graph} ->
      # Calculate start time for this iteration
      iteration_start = DateTime.add(start_time, iteration * repeat_every_hours * 3600, :second)
      
      # Create process options for this iteration
      iteration_opts = 
        opts
        |> Keyword.put(:start_time, iteration_start)
        |> Keyword.delete(:repeat_every_hours)
        |> Keyword.delete(:repeat_count)
      
      case add_environmental_process(graph, process_type, iteration_opts) do
        {:ok, updated_graph} ->
          {:cont, {:ok, updated_graph}}
        
        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  # Private helper functions

  defp resolve_affected_entities(timeline_graph, :all) do
    Map.keys(timeline_graph.entities)
  end

  defp resolve_affected_entities(_timeline_graph, entity_list) when is_list(entity_list) do
    entity_list
  end

  defp resolve_affected_entities(timeline_graph, entity_id) when is_binary(entity_id) do
    if Map.has_key?(timeline_graph.entities, entity_id) do
      [entity_id]
    else
      []
    end
  end

  defp find_environmental_process_intervals(timeline, process_type) do
    # This is a placeholder implementation
    # In a real implementation, this would query the STN for intervals
    # that match the environmental process type
    _ = {timeline, process_type}
    []
  end

  defp find_active_environmental_processes(timeline, check_time) do
    # This is a placeholder implementation
    # In a real implementation, this would query the STN for environmental
    # process intervals that are active at the specified time
    _ = {timeline, check_time}
    []
  end

  defp intensity_value(intensity) do
    case intensity do
      :low -> 1
      :medium -> 2
      :high -> 3
      :extreme -> 4
      _ -> 2
    end
  end

  defp priority_value(priority) do
    case priority do
      :low -> 1
      :medium -> 2
      :high -> 3
      :critical -> 4
      _ -> 1
    end
  end
end
