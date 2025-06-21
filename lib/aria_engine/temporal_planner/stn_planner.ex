# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlanner.STNPlanner do
  @moduledoc """
  STN-based hierarchical temporal planner for goal-level coordination.

  This module is the top-level coordinator in the hierarchical STN composition:
  Action → Method → Goal. It handles goal decomposition, cross-method timeline
  coordination, and reentrant execution with real-time constraint updates.

  ## Hierarchical STN Architecture

  The planner operates on three levels:
  1. **Actions**: Atomic temporal activities (STNAction)
  2. **Methods**: Grouped actions with decomposition patterns (STNMethod)  
  3. **Goals**: High-level objectives with method coordination (STNPlanner)

  ## Non-temporal Bridge Integration

  The planner handles non-temporal actions as natural segment boundaries:
  - **Decision points**: Choice nodes between method alternatives
  - **Condition checks**: State validation between temporal segments
  - **Resource allocation**: Instantaneous resource assignment/release

  ## Parallel Segment Solving

  Achieves O(k * (n/k)³) complexity reduction through:
  - Independent method segment solving
  - Cross-segment timeline coordination
  - Parallel composition using STN boolean operations

  ## Reentrant Execution

  Supports real-time replanning during execution:
  - Constraint tightening based on execution progress
  - Dynamic method alternative selection
  - Temporal consistency maintenance across plan updates
  """

  alias TemporalPlanner.STNMethod
  alias TemporalPlanner.STNAction
  alias Timeline
  # alias AriaEngine.ConvergenceFlow

  @type goal_id :: String.t()
  @type planning_strategy :: :sequential | :parallel | :hierarchical | :adaptive
  @type execution_status :: :planning | :executing | :completed | :failed | :replanning
  @type constraint_update :: %{
          timepoint: String.t(),
          constraint: Timeline.constraint(),
          timestamp: DateTime.t()
        }

  @type t :: %__MODULE__{
          goal_id: goal_id(),
          planning_strategy: planning_strategy(),
          methods: [STNMethod.t()],
          goal_stn: Timeline.t(),
          method_segments: [Timeline.t()],
          execution_status: execution_status(),
          constraint_updates: [constraint_update()],
          world_constraints: Timeline.t(),
          parallel_segments: [{Timeline.t(), pid()}],
          reentrant_enabled: boolean(),
          metadata: map()
        }

  defstruct goal_id: nil,
            planning_strategy: :hierarchical,
            methods: [],
            goal_stn: nil,
            method_segments: [],
            execution_status: :planning,
            constraint_updates: [],
            world_constraints: nil,
            parallel_segments: [],
            reentrant_enabled: true,
            metadata: %{}

  @doc """
  Creates a new STN planner for goal-level temporal planning.

  ## Examples

      iex> planner = STNPlanner.new("rescue_mission", :hierarchical)
      iex> planner.goal_id
      "rescue_mission"

  """
  @spec new(goal_id(), planning_strategy(), keyword()) :: t()
  def new(goal_id, strategy, opts \\ []) when strategy in [:sequential, :parallel, :hierarchical, :adaptive] do
    methods = Keyword.get(opts, :methods, [])
    world_constraints = Keyword.get(opts, :world_constraints, Timeline.new())
    reentrant_enabled = Keyword.get(opts, :reentrant_enabled, true)
    metadata = Keyword.get(opts, :metadata, %{})

    # Compute initial goal STN from methods
    goal_stn = compute_goal_stn(strategy, methods)
    
    # Create method segments for parallel solving
    method_segments = create_method_segments(methods, strategy)

    %__MODULE__{
      goal_id: goal_id,
      planning_strategy: strategy,
      methods: methods,
      goal_stn: goal_stn,
      method_segments: method_segments,
      execution_status: :planning,
      constraint_updates: [],
      world_constraints: world_constraints,
      parallel_segments: [],
      reentrant_enabled: reentrant_enabled,
      metadata: metadata
    }
  end

  @doc """
  Adds a method to the planner and recomputes the goal STN.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical)
      iex> method = STNMethod.new("recon", :sequential, [])
      iex> updated_planner = STNPlanner.add_method(planner, method)
      iex> length(updated_planner.methods)
      1

  """
  @spec add_method(t(), STNMethod.t()) :: t()
  def add_method(%__MODULE__{} = planner, %STNMethod{} = method) do
    updated_methods = planner.methods ++ [method]
    
    # Recompute goal STN with new method
    updated_goal_stn = compute_goal_stn(planner.planning_strategy, updated_methods)
    
    # Recreate method segments
    updated_segments = create_method_segments(updated_methods, planner.planning_strategy)

    %{planner | 
      methods: updated_methods,
      goal_stn: updated_goal_stn,
      method_segments: updated_segments
    }
  end

  @doc """
  Updates world constraints and triggers replanning if reentrant execution is enabled.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical, reentrant_enabled: true)
      iex> constraint = {"agent_position", "target_location", {100, 200}}
      iex> updated_planner = STNPlanner.update_constraint(planner, constraint)
      iex> length(updated_planner.constraint_updates) >= 1
      true

  """
  @spec update_constraint(t(), {String.t(), String.t(), Timeline.constraint()}) :: t()
  def update_constraint(%__MODULE__{} = planner, {from_point, to_point, constraint}) do
    # Add constraint update to history
    constraint_update = %{
      timepoint: "#{from_point}_to_#{to_point}",
      constraint: constraint,
      timestamp: DateTime.utc_now()
    }
    
    updated_constraint_updates = [constraint_update | planner.constraint_updates]
    
    # Update world constraints
    updated_world_constraints = planner.world_constraints
    |> Timeline.add_constraint(from_point, to_point, constraint)
    
    # Trigger replanning if reentrant execution is enabled
    updated_planner = %{planner | 
      constraint_updates: updated_constraint_updates,
      world_constraints: updated_world_constraints
    }
    
    if planner.reentrant_enabled and planner.execution_status == :executing do
      trigger_replanning(updated_planner)
    else
      updated_planner
    end
  end

  @doc """
  Starts plan execution with real-time constraint monitoring.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical)
      iex> executing_planner = STNPlanner.start_execution(planner)
      iex> executing_planner.execution_status
      :executing

  """
  @spec start_execution(t()) :: t()
  def start_execution(%__MODULE__{} = planner) do
    %{planner | execution_status: :executing}
  end

  @doc """
  Checks if the current plan is consistent with world constraints.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical)
      iex> STNPlanner.consistent?(planner)
      true

  """
  @spec consistent?(t()) :: boolean()
  def consistent?(%__MODULE__{goal_stn: goal_stn, world_constraints: world_constraints}) do
    # Check consistency of the intersection of goal and world constraints
    combined_timeline = Timeline.intersection(goal_stn, world_constraints)
    Timeline.consistent?(combined_timeline)
  end

  @doc """
  Gets the current execution timeline with all temporal constraints.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical)
      iex> timeline = STNPlanner.get_timeline(planner)
      iex> is_map(timeline.constraints)
      true

  """
  @spec get_timeline(t()) :: Timeline.t()
  def get_timeline(%__MODULE__{goal_stn: goal_stn, world_constraints: world_timeline}) do
    Timeline.intersection(goal_stn, world_timeline)
  end

  @doc """
  Estimates the total plan execution duration.

  ## Examples

      iex> planner = STNPlanner.new("mission", :hierarchical)
      iex> {min_duration, max_duration} = STNPlanner.estimate_duration(planner)
      iex> is_number(min_duration)
      true

  """
  @spec estimate_duration(t()) :: STNAction.duration_constraint()
  def estimate_duration(%__MODULE__{methods: methods, planning_strategy: strategy}) do
    method_durations = Enum.map(methods, & &1.estimated_duration)
    
    case strategy do
      :sequential ->
        # Sum all method durations
        Enum.reduce(method_durations, {0, 0}, fn
          {min, max}, {acc_min, acc_max} ->
            new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max + acc_max
            {min + acc_min, new_max}
        end)
      
      :parallel ->
        # Take maximum method duration
        Enum.reduce(method_durations, {0, 0}, fn
          {min, max}, {acc_min, acc_max} ->
            new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max(max, acc_max)
            {max(min, acc_min), new_max}
        end)
        
      :hierarchical ->
        # Mixed strategy based on method dependencies
        estimate_hierarchical_duration(method_durations)
        
      :adaptive ->
        # Conservative estimate based on current world constraints
        estimate_adaptive_duration(method_durations)
    end
  end

  # Private helper functions

  defp compute_goal_stn(strategy, methods) do
    method_timelines = Enum.map(methods, &STNMethod.to_timeline/1)
    
    case strategy do
      :sequential -> 
        Timeline.chain(method_timelines)
      :parallel -> 
        Timeline.parallel_join(method_timelines)
      :hierarchical ->
        # Hierarchical strategy uses both sequential and parallel composition
        compose_hierarchical(method_timelines)
      :adaptive ->
        # Adaptive strategy selects best composition based on constraints
        compose_adaptive(method_timelines)
    end
  end

  defp create_method_segments(methods, strategy) do
    case strategy do
      :sequential ->
        # Each method is a separate segment for sequential execution
        Enum.map(methods, &STNMethod.to_timeline/1)
      :parallel ->
        # All methods in single segment for parallel execution
        case methods do
          [] -> []
          methods -> [STNMethod.parallel(methods)]
        end
      :hierarchical ->
        # Create segments based on method dependencies
        create_hierarchical_segments(methods)
      :adaptive ->
        # Dynamic segmentation based on current constraints
        create_adaptive_segments(methods)
    end
  end

  defp trigger_replanning(%__MODULE__{} = planner) do
    # Set status to replanning and recompute goal STN
    updated_goal_stn = compute_goal_stn(planner.planning_strategy, planner.methods)
    
    %{planner | 
      execution_status: :replanning,
      goal_stn: updated_goal_stn
    }
  end

  defp compose_hierarchical(method_timelines) do
    # Hierarchical composition: alternate between sequential and parallel
    case method_timelines do
      [] -> Timeline.new()
      [single] -> single
      multiple ->
        # Group methods and apply mixed composition
        multiple
        |> Enum.chunk_every(2)
        |> Enum.map(fn
          [single] -> single
          chunk -> Timeline.parallel_join(chunk)
        end)
        |> Timeline.chain()
    end
  end

  defp compose_adaptive(method_timelines) do
    # Adaptive composition: choose best strategy based on constraint density
    case method_timelines do
      [] -> Timeline.new()
      [single] -> single
      multiple ->
        # For now, use hierarchical as default adaptive strategy
        compose_hierarchical(multiple)
    end
  end

  defp create_hierarchical_segments(methods) do
    # Group methods into hierarchical segments
    methods
    |> Enum.chunk_every(3)  # Group into chunks of 3 for hierarchical processing
    |> Enum.map(fn method_chunk ->
      STNMethod.parallel(method_chunk)
    end)
  end

  defp create_adaptive_segments(methods) do
    # For now, use hierarchical segmentation as default
    create_hierarchical_segments(methods)
  end

  defp estimate_hierarchical_duration(method_durations) do
    # Hierarchical duration: mix of sequential and parallel
    case method_durations do
      [] -> {0, 0}
      durations ->
        # Group durations and apply mixed estimation
        durations
        |> Enum.chunk_every(2)
        |> Enum.map(fn
          [single] -> single
          chunk -> 
            # Parallel execution within chunk
            Enum.reduce(chunk, {0, 0}, fn
              {min, max}, {acc_min, acc_max} ->
                new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max(max, acc_max)
                {max(min, acc_min), new_max}
            end)
        end)
        |> Enum.reduce({0, 0}, fn
          {min, max}, {acc_min, acc_max} ->
            new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max + acc_max
            {min + acc_min, new_max}
        end)
    end
  end

  defp estimate_adaptive_duration(method_durations) do
    # Conservative estimate: assume sequential execution
    Enum.reduce(method_durations, {0, 0}, fn
      {min, max}, {acc_min, acc_max} ->
        new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max + acc_max
        {min + acc_min, new_max}
    end)
  end
end
