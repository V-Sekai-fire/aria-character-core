# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TimelineGraph do
  @moduledoc """
  Manages timeline integration with the Entity Timeline Graph Architecture (ADR-087).
  
  This module connects the existing AriaEngine.Timeline.AgentEntity system with 
  auto-growing timelines, implementing the core concept that every entity owns
  a timeline that grows automatically based on their capabilities and interactions.
  
  ## Core Concepts
  
  - **Every Entity has a Timeline**: Created automatically when entities are instantiated
  - **Timeline Growth**: Automatic based on entity capabilities and interactions  
  - **LOD Management**: Level of Detail scaling based on relevance and proximity
  - **Bridge Management**: Inter-timeline connections for coordination
  
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

  alias AriaEngine.Timeline.AgentEntity
  alias AriaEngine.Timeline.STN
  alias AriaEngine.Timeline.Interval
  alias AriaEngine.StateV2

  @type entity_id :: String.t()
  @type timeline_id :: String.t()
  @type lod_level :: :very_low | :low | :medium | :high | :ultra_high
  @type bridge_type :: :proximity | :memory | :communication | :conversation | :causal | :coordination

  @type entity_timeline :: %{
    entity: AgentEntity.participant(),
    timeline: STN.t(),
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

  defstruct [
    entities: %{},
    state: %StateV2{},
    bridge_strength: %{},
    lod_promotion_queue: [],
    growth_triggers: %{}
  ]

  @doc """
  Creates a new TimelineGraph with empty entity and timeline registry.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      state: StateV2.new()
    }
  end

  @doc """
  Creates a new entity with automatic timeline attachment.
  
  This implements the core ADR-087 principle: every entity owns an auto-growing timeline.
  The timeline starts with basic LOD and grows based on entity capabilities and interactions.
  
  ## Examples
  
  ```elixir
  # Create passive entity (furniture)
  {:ok, timeline_graph, "chair1"} = TimelineGraph.create_entity(
    timeline_graph, 
    "chair1", 
    "Wooden Chair", 
    %{type: "furniture", material: "wood"}
  )
  
  # Create potential agent (NPC)  
  {:ok, timeline_graph, "guard"} = TimelineGraph.create_entity(
    timeline_graph,
    "guard", 
    "Tower Guard", 
    %{type: "humanoid", location: "tower"}
  )
  ```
  """
  @spec create_entity(t(), entity_id(), String.t(), map(), keyword()) :: 
    {:ok, t(), entity_id()} | {:error, term()}
  def create_entity(timeline_graph, entity_id, name, properties \\ %{}, opts \\ []) do
    # Create entity using existing AgentEntity system
    entity = AgentEntity.create_entity(entity_id, name, properties, opts)
    
    # Create timeline for this entity (STN.new/0 for basic usage)
    timeline = STN.new()
    
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
    updated_state = Enum.reduce(properties, timeline_graph.state, fn {predicate, value}, state ->
      StateV2.set_fact(state, entity_id, predicate, value)
    end)
    
    # Add entity to timeline graph
    updated_timeline_graph = %{timeline_graph |
      entities: Map.put(timeline_graph.entities, entity_id, entity_timeline),
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
  {:ok, updated_graph} = TimelineGraph.add_capabilities(
    timeline_graph, 
    "door1", 
    [:autonomous_operation, :decision_making]
  )
  
  # Entity is now an agent with enhanced timeline growth
  TimelineGraph.is_currently_agent?(updated_graph, "door1") # => true
  ```
  """
  @spec add_capabilities(t(), entity_id(), [atom()]) :: {:ok, t()} | {:error, term()}
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
        updated_timeline = grow_timeline_for_capabilities(
          entity_timeline.timeline, 
          new_capabilities,
          transition_to_agent: !was_agent && is_now_agent
        )
        
        # Determine new LOD based on agent status
        new_lod = if is_now_agent do
          promote_lod(entity_timeline.lod)
        else
          entity_timeline.lod
        end
        
        # Update entity timeline record
        updated_entity_timeline = %{entity_timeline |
          entity: updated_entity,
          timeline: updated_timeline,
          lod: new_lod,
          last_growth: DateTime.utc_now()
        }
        
        # Update timeline graph
        updated_timeline_graph = %{timeline_graph |
          entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
        }
        
        # Add to LOD promotion queue if became agent
        final_timeline_graph = if !was_agent && is_now_agent do
          %{updated_timeline_graph |
            lod_promotion_queue: [entity_id | updated_timeline_graph.lod_promotion_queue]
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
  @spec is_currently_agent?(t(), entity_id()) :: boolean()
  def is_currently_agent?(timeline_graph, entity_id) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil -> false
      entity_timeline -> AgentEntity.is_currently_agent?(entity_timeline.entity)
    end
  end

  @doc """
  Gets the current LOD level for an entity's timeline.
  """
  @spec get_lod(t(), entity_id()) :: {:ok, lod_level()} | {:error, :not_found}
  def get_lod(timeline_graph, entity_id) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil -> {:error, :not_found}
      entity_timeline -> {:ok, entity_timeline.lod}
    end
  end

  @doc """
  Gets entity properties using entity-first StateV2 API.
  """
  @spec get_entity_properties(t(), entity_id()) :: %{String.t() => any()}
  def get_entity_properties(timeline_graph, entity_id) do
    StateV2.get_properties(timeline_graph.state, entity_id)
  end

  @doc """
  Sets an entity property and triggers timeline growth if appropriate.
  """
  @spec set_entity_property(t(), entity_id(), String.t(), any()) :: {:ok, t()} | {:error, term()}
  def set_entity_property(timeline_graph, entity_id, predicate, value) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}
      
      entity_timeline ->
        # Update state using entity-first API
        updated_state = StateV2.set_fact(timeline_graph.state, entity_id, predicate, value)
        
        # Trigger timeline growth for property change
        updated_timeline = grow_timeline_for_property_change(
          entity_timeline.timeline,
          predicate,
          value
        )
        
        # Update entity timeline record
        updated_entity_timeline = %{entity_timeline |
          timeline: updated_timeline,
          last_growth: DateTime.utc_now()
        }
        
        # Update timeline graph
        updated_timeline_graph = %{timeline_graph |
          entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline),
          state: updated_state
        }
        
        {:ok, updated_timeline_graph}
    end
  end

  @doc """
  Gets all entity IDs currently managed by the timeline graph.
  """
  @spec get_entity_ids(t()) :: [entity_id()]
  def get_entity_ids(timeline_graph) do
    Map.keys(timeline_graph.entities)
  end

  @doc """
  Gets all agent IDs (entities with action capabilities).
  """
  @spec get_agent_ids(t()) :: [entity_id()]
  def get_agent_ids(timeline_graph) do
    timeline_graph.entities
    |> Enum.filter(fn {_id, entity_timeline} ->
      AgentEntity.is_currently_agent?(entity_timeline.entity)
    end)
    |> Enum.map(fn {id, _timeline} -> id end)
  end

  @doc """
  Processes the LOD promotion queue, upgrading timeline detail for active agents.
  """
  @spec process_lod_promotions(t()) :: t()
  def process_lod_promotions(timeline_graph) do
    Enum.reduce(timeline_graph.lod_promotion_queue, timeline_graph, fn entity_id, graph ->
      case Map.get(graph.entities, entity_id) do
        nil ->
          graph
        
        entity_timeline ->
          promoted_lod = promote_lod(entity_timeline.lod)
          updated_entity_timeline = %{entity_timeline | lod: promoted_lod}
          
          %{graph |
            entities: Map.put(graph.entities, entity_id, updated_entity_timeline)
          }
      end
    end)
    |> Map.put(:lod_promotion_queue, [])
  end

  @doc """
  Schedules a routine activity for an agent with priority and deadline handling.
  
  This implements Enhanced Scheduling for Phase 1 of ADR-085, enabling NPCs to 
  follow complex, time-sensitive routines like work shifts, meal times, and sleep cycles.
  
  ## Examples
  
  ```elixir
  # Schedule daily work routine
  {:ok, updated_graph} = TimelineGraph.schedule_routine(
    timeline_graph,
    "guard",
    :work_shift,
    start_time: ~U[2025-06-17 08:00:00Z],
    duration_hours: 8,
    priority: :high,
    repeat: :daily
  )
  
  # Schedule meal break with deadline
  {:ok, updated_graph} = TimelineGraph.schedule_routine(
    timeline_graph,
    "chef",
    :lunch_prep,
    start_time: ~U[2025-06-17 11:30:00Z],
    deadline: ~U[2025-06-17 12:00:00Z],
    priority: :medium
  )
  ```
  """
  @spec schedule_routine(t(), entity_id(), atom(), keyword()) :: {:ok, t()} | {:error, term()}
  def schedule_routine(timeline_graph, entity_id, routine_type, opts) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}
      
      entity_timeline ->
        start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
        duration_hours = Keyword.get(opts, :duration_hours, 1)
        priority = Keyword.get(opts, :priority, :medium)
        deadline = Keyword.get(opts, :deadline)
        repeat = Keyword.get(opts, :repeat, :none)
        
        # Calculate end time
        end_time = DateTime.add(start_time, duration_hours * 3600, :second)
        
        # Create routine interval with metadata
        routine_interval = Interval.new(
          start_time,
          end_time,
          metadata: %{
            type: :scheduled_routine,
            routine_type: routine_type,
            priority: priority,
            deadline: deadline,
            repeat: repeat,
            entity_id: entity_id
          }
        )
        
        # Add to timeline with conflict detection
        case detect_schedule_conflicts(entity_timeline.timeline, routine_interval) do
          [] ->
            # No conflicts, add routine
            updated_timeline = STN.add_interval(entity_timeline.timeline, routine_interval)
            
            updated_entity_timeline = %{entity_timeline |
              timeline: updated_timeline,
              last_growth: DateTime.utc_now()
            }
            
            updated_timeline_graph = %{timeline_graph |
              entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
            }
            
            {:ok, updated_timeline_graph}
          
          conflicts ->
            # Handle conflicts based on priority
            resolve_schedule_conflicts(timeline_graph, entity_id, routine_interval, conflicts)
        end
    end
  end

  @doc """
  Resolves schedule conflicts for an entity based on priority and deadline handling.
  
  Implements intelligent conflict resolution:
  - Higher priority activities override lower priority ones
  - Activities with deadlines get precedence over flexible ones
  - Attempts to reschedule conflicting lower-priority activities
  """
  @spec resolve_schedule_conflicts(t(), entity_id(), Interval.t(), [Interval.t()]) :: 
    {:ok, t()} | {:error, term()}
  def resolve_schedule_conflicts(timeline_graph, entity_id, new_routine, conflicts) do
    entity_timeline = Map.get(timeline_graph.entities, entity_id)
    new_priority = get_in(new_routine.metadata, [:priority])
    new_deadline = get_in(new_routine.metadata, [:deadline])
    
    # Analyze conflicts to determine resolution strategy
    {can_override, reschedulable} = Enum.split_with(conflicts, fn conflict ->
      conflict_priority = get_in(conflict.metadata, [:priority])
      conflict_deadline = get_in(conflict.metadata, [:deadline])
      
      # Override if new routine has higher priority or has deadline while conflict doesn't
      priority_higher?(new_priority, conflict_priority) or 
      (new_deadline != nil and conflict_deadline == nil)
    end)
    
    # Remove overridden activities
    updated_timeline = Enum.reduce(can_override, entity_timeline.timeline, fn conflict, timeline ->
      STN.remove_interval(timeline, conflict.id)
    end)
    
    # Add new routine
    updated_timeline = STN.add_interval(updated_timeline, new_routine)
    
    # Attempt to reschedule reschedulable activities
    final_timeline = Enum.reduce(reschedulable, updated_timeline, fn activity, timeline ->
      case find_next_available_slot(timeline, activity) do
        {:error, _} ->
          # Could not reschedule - activity is dropped
          timeline
      end
    end)
    
    updated_entity_timeline = %{entity_timeline |
      timeline: final_timeline,
      last_growth: DateTime.utc_now()
    }
    
    updated_timeline_graph = %{timeline_graph |
      entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
    }
    
    {:ok, updated_timeline_graph}
  end

  @doc """
  Gets the current scheduled routines for an entity within a time window.
  
  ## Examples
  
  ```elixir
  # Get today's schedule for a guard
  start_of_day = DateTime.beginning_of_day(DateTime.utc_now())
  end_of_day = DateTime.end_of_day(DateTime.utc_now())
  
  routines = TimelineGraph.get_scheduled_routines(
    timeline_graph, 
    "guard", 
    start_of_day,
    end_of_day
  )
  ```
  """
  @spec get_scheduled_routines(t(), entity_id(), DateTime.t(), DateTime.t()) :: 
    [Interval.t()] | {:error, term()}
  def get_scheduled_routines(timeline_graph, entity_id, _start_time, _end_time) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}
      
      _entity_timeline ->
        # Extract intervals from STN that overlap with time window
        # This would need to be implemented in the STN module
        # For now, return empty list as placeholder
        []
    end
  end

  @doc """
  Adds a process or event that affects multiple entities over time.
  
  This supports Phase 2 environmental dynamics from ADR-085, enabling
  NPCs to react to environmental changes like weather, resource depletion, etc.
  
  ## Examples
  
  ```elixir
  # Add weather event affecting outdoor NPCs
  {:ok, updated_graph} = TimelineGraph.add_environmental_process(
    timeline_graph,
    :storm_weather,
    affects: ["guard", "farmer", "merchant"],
    start_time: DateTime.utc_now(),
    duration_hours: 3,
    effects: %{visibility: :reduced, movement_speed: 0.5}
  )
  ```
  """
  @spec add_environmental_process(t(), atom(), keyword()) :: {:ok, t()} | {:error, term()}
  def add_environmental_process(timeline_graph, process_type, opts) do
    affected_entities = Keyword.get(opts, :affects, [])
    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
    duration_hours = Keyword.get(opts, :duration_hours, 1)
    effects = Keyword.get(opts, :effects, %{})
    
    end_time = DateTime.add(start_time, duration_hours * 3600, :second)
    
    # Apply process to all affected entities
    Enum.reduce_while(affected_entities, {:ok, timeline_graph}, fn entity_id, {:ok, graph} ->
      case Map.get(graph.entities, entity_id) do
        nil ->
          {:cont, {:ok, graph}}  # Skip non-existent entities
        
        entity_timeline ->
          # Create process interval
          process_interval = Interval.new(
            start_time,
            end_time,
            metadata: %{
              type: :environmental_process,
              process_type: process_type,
              effects: effects,
              affected_entity: entity_id
            }
          )
          
          # Add to entity timeline
          updated_timeline = STN.add_interval(entity_timeline.timeline, process_interval)
          
          updated_entity_timeline = %{entity_timeline |
            timeline: updated_timeline,
            last_growth: DateTime.utc_now()
          }
          
          updated_graph = %{graph |
            entities: Map.put(graph.entities, entity_id, updated_entity_timeline)
          }
          
          {:cont, {:ok, updated_graph}}
      end
    end)
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
    far_future = DateTime.add(creation_time, 365 * 24 * 3600, :second)  # 1 year from creation
    
    creation_interval = Interval.new(
      creation_time,
      far_future,
      metadata: %{type: :creation, event: "entity_created"}
    )
    
    STN.add_interval(timeline, creation_interval)
  end

  defp grow_timeline_for_capabilities(timeline, new_capabilities, opts) do
    transition_to_agent = Keyword.get(opts, :transition_to_agent, false)
    now = DateTime.utc_now()
    
    # Add interval for capability acquisition
    capability_interval = Interval.new(
      now,
      DateTime.add(now, 1, :second),  # Instantaneous event
      metadata: %{
        type: :capability_change,
        capabilities_added: new_capabilities,
        became_agent: transition_to_agent
      }
    )
    
    STN.add_interval(timeline, capability_interval)
  end

  defp grow_timeline_for_property_change(timeline, predicate, value) do
    now = DateTime.utc_now()
    
    # Add interval for property change  
    property_interval = Interval.new(
      now,
      DateTime.add(now, 1, :second),  # Instantaneous event
      metadata: %{
        type: :property_change,
        predicate: predicate,
        new_value: value
      }
    )
    
    STN.add_interval(timeline, property_interval)
  end

  defp promote_lod(current_lod) do
    case current_lod do
      :very_low -> :low
      :low -> :medium
      :medium -> :high
      :high -> :ultra_high
      :ultra_high -> :ultra_high  # Already at max
    end
  end

  # Enhanced Scheduling helper functions

  defp detect_schedule_conflicts(timeline, new_interval) do
    start_time = get_in(new_interval.metadata, [:start_time])
    end_time = get_in(new_interval.metadata, [:end_time])
    
    # Convert DateTime to STN time units if necessary
    {stn_start, stn_end} = case {start_time, end_time} do
      {%DateTime{} = start_dt, %DateTime{} = end_dt} ->
        # Convert DateTime to milliseconds since epoch, then to STN units
        start_ms = DateTime.to_unix(start_dt, :millisecond)
        end_ms = DateTime.to_unix(end_dt, :millisecond)
        {convert_to_stn_time(start_ms, timeline.time_unit),
         convert_to_stn_time(end_ms, timeline.time_unit)}
      {start_num, end_num} when is_number(start_num) and is_number(end_num) ->
        {start_num, end_num}
      _ ->
        # Fallback: use start_time and end_time from Interval if available
        if new_interval.start_time && new_interval.end_time do
          start_ms = DateTime.to_unix(new_interval.start_time, :millisecond)
          end_ms = DateTime.to_unix(new_interval.end_time, :millisecond)
          {convert_to_stn_time(start_ms, timeline.time_unit),
           convert_to_stn_time(end_ms, timeline.time_unit)}
        else
          {0, 1}  # Fallback for malformed intervals
        end
    end
    
    # Use STN Core to find conflicts
    conflicts = STN.Core.check_interval_conflicts(timeline, stn_start, stn_end)
    
    # Convert back to Interval format for compatibility
    Enum.map(conflicts, fn conflict ->
      Interval.new(
        # Convert back from STN time units to DateTime
        convert_from_stn_time(conflict.start_time, timeline.time_unit),
        convert_from_stn_time(conflict.end_time, timeline.time_unit),
        metadata: conflict.metadata
      )
    end)
  end

  defp priority_higher?(priority1, priority2) do
    priority_values = %{
      :low => 1,
      :medium => 2,
      :high => 3,
      :critical => 4
    }
    
    Map.get(priority_values, priority1, 0) > Map.get(priority_values, priority2, 0)
  end

  defp find_next_available_slot(timeline, activity) do
    # Extract duration and start time from activity
    duration = case get_in(activity.metadata, [:duration_hours]) do
      hours when is_number(hours) -> 
        # Convert hours to STN time units
        convert_duration_to_stn_time(hours * 3600 * 1000, timeline.time_unit)  # hours to milliseconds to STN units
      _ -> 
        # Default 1 hour duration
        convert_duration_to_stn_time(3600 * 1000, timeline.time_unit)
    end
    
    earliest_start = case get_in(activity.metadata, [:start_time]) do
      %DateTime{} = dt ->
        convert_to_stn_time(DateTime.to_unix(dt, :millisecond), timeline.time_unit)
      num when is_number(num) ->
        num
      _ ->
        # Default to current time in STN units
        now_ms = DateTime.to_unix(DateTime.utc_now(), :millisecond)
        convert_to_stn_time(now_ms, timeline.time_unit)
    end
    
    # Use STN Core to find next available slot
    case STN.Core.find_next_available_slot(timeline, duration, earliest_start) do
      {:ok, slot_start, slot_end} ->
        # Convert back to DateTime format
        start_dt = convert_from_stn_time(slot_start, timeline.time_unit)
        end_dt = convert_from_stn_time(slot_end, timeline.time_unit)
        
        # Return rescheduled activity
        {:ok, Interval.new(start_dt, end_dt, metadata: activity.metadata)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions for time conversion

  defp convert_to_stn_time(time_value_ms, target_unit) do
    case target_unit do
      :microsecond -> time_value_ms * 1000
      :millisecond -> time_value_ms
      :second -> div(time_value_ms, 1000)
      :minute -> div(time_value_ms, 60_000)
      :hour -> div(time_value_ms, 3_600_000)
      :day -> div(time_value_ms, 86_400_000)
      _ -> time_value_ms  # Default to milliseconds
    end
  end

  defp convert_from_stn_time(stn_time_value, source_unit) do
    # Convert STN time units back to milliseconds, then to DateTime
    ms_value = case source_unit do
      :microsecond -> div(stn_time_value, 1000)
      :millisecond -> stn_time_value
      :second -> stn_time_value * 1000
      :minute -> stn_time_value * 60_000
      :hour -> stn_time_value * 3_600_000
      :day -> stn_time_value * 86_400_000
      _ -> stn_time_value  # Default treat as milliseconds
    end
    
    DateTime.from_unix!(ms_value, :millisecond)
  end

  defp convert_duration_to_stn_time(duration_ms, target_unit) do
    convert_to_stn_time(duration_ms, target_unit)
  end
end
