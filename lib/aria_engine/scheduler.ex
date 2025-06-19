# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler do
  @moduledoc """
  Advanced scheduler with entity/resource/capability management and simulation.
  
  Provides comprehensive scheduling capabilities including:
  - Entity and resource modeling with capabilities
  - Activity logging and execution tracking
  - run_lazy simulation for predictive scheduling
  - Resource conflict detection and resolution
  - Critical path analysis with resource constraints
  
  ## Features
  
  - Entity management with capabilities and availability
  - Resource modeling with capacity and constraints
  - Comprehensive activity logging
  - Simulation modes for schedule validation
  - Resource utilization analytics
  - Timeline optimization
  
  ## Usage
  
      # Define entities with capabilities
      entities = [
        %AriaEngine.Scheduler.Entity{
          id: "developer_1",
          type: :agent,
          capabilities: [:coding, :testing],
          availability: %Timeline.Interval{start: 0, end: 480}
        }
      ]
      
      # Define resources with capacity
      resources = [
        %AriaEngine.Scheduler.Resource{
          id: "dev_server",
          type: :computational,
          capacity: 4,
          current_usage: 0
        }
      ]
      
      # Schedule activities with resource requirements
      activities = [
        %{
          id: "implement_feature",
          duration: 120,
          dependencies: [],
          required_capabilities: [:coding],
          required_resources: ["dev_server"]
        }
      ]
      
      {:ok, result} = AriaEngine.Scheduler.schedule_activities(
        "Feature Development",
        activities,
        entities: entities,
        resources: resources,
        simulation_mode: true
      )
  """
  
  require Logger
  
  # Type definitions for the scheduler system
  @type activity :: %{
    id: String.t(),
    duration: non_neg_integer(),
    dependencies: [String.t()],
    required_capabilities: [atom()],
    required_resources: [String.t()]
  }
  
  @type state :: AriaEngine.StateV2.t()
  @type entity_list :: [Entity.t()]
  @type resource_list :: [Resource.t()]
  @type activity_list :: [activity()]
  @type schedule_options :: keyword()
  @type schedule_result :: {:ok, SimulationResult.t()} | {:error, String.t()}
  
  # Data structures for enhanced scheduling
  defmodule Entity do
    @moduledoc """
    Represents an entity (agent, NPC, object) with capabilities and availability.
    """
    
    @derive Jason.Encoder
    defstruct [
      :id,
      :type,
      :capabilities,
      :current_activity,
      :availability,
      :resources_held,
      :metadata
    ]
    
    @type t :: %__MODULE__{
      id: String.t(),
      type: :agent | :npc | :object | :resource,
      capabilities: [atom()],
      current_activity: String.t() | nil,
      availability: Timeline.Interval.t() | nil,
      resources_held: [String.t()],
      metadata: map()
    }
  end
  
  defmodule Resource do
    @moduledoc """
    Represents a resource with capacity and constraints.
    """
    
    @derive Jason.Encoder
    defstruct [
      :id,
      :type,
      :capacity,
      :current_usage,
      :constraints,
      :availability_schedule,
      :metadata
    ]
    
    @type t :: %__MODULE__{
      id: String.t(),
      type: :computational | :physical | :human | :virtual,
      capacity: non_neg_integer(),
      current_usage: non_neg_integer(),
      constraints: map(),
      availability_schedule: [Timeline.Interval.t()],
      metadata: map()
    }
  end
  
  defmodule ActivityLogEntry do
    @moduledoc """
    Represents a logged activity event.
    
    Supports both absolute timestamps (when mission start time is known)
    and duration-based formatting (when only relative timing is available).
    """
    
    @derive Jason.Encoder
    defstruct [
      :timestamp,
      :mission_duration,
      :relative_minutes,
      :activity_id,
      :entity_id,
      :event_type,
      :resource_snapshot,
      :state_changes,
      :metadata
    ]
    
    @type t :: %__MODULE__{
      timestamp: DateTime.t() | nil,
      mission_duration: String.t() | nil,
      relative_minutes: non_neg_integer() | nil,
      activity_id: String.t(),
      entity_id: String.t() | nil,
      event_type: :started | :completed | :failed | :paused | :resumed,
      resource_snapshot: map(),
      state_changes: [map()],
      metadata: map()
    }
  end
  
  defmodule SimulationResult do
    @moduledoc """
    Results from a scheduling simulation.
    """
    
    @derive Jason.Encoder
    defstruct [
      :status,
      :reason,
      :schedule,
      :analysis,
      :activity_log,
      :resource_utilization,
      :timeline,
      :simulation_metadata
    ]
    
    @type t :: %__MODULE__{
      status: String.t(),
      reason: String.t(),
      schedule: [map()],
      analysis: map(),
      activity_log: [ActivityLogEntry.t()],
      resource_utilization: map(),
      timeline: [map()],
      simulation_metadata: map()
    }
  end
  
  @doc """
  Schedule activities with advanced entity/resource management and simulation.
  
  ## Parameters
  
  - `schedule_name` - Name for this scheduling request
  - `activities` - List of activities to schedule (can be empty)
  - `opts` - Optional parameters:
    - `:entities` - List of Entity structs with capabilities
    - `:resources` - List of Resource structs with capacity
    - `:constraints` - Scheduling constraints and limits
    - `:simulation_mode` - Run in simulation mode (default: false)
    - `:verbose` - Logging verbosity level (0-3, default: 0)
    - `:log_activities` - Enable activity logging (default: true)
  
  ## Returns
  
  - `{:ok, SimulationResult.t()}` - Successful scheduling with comprehensive results
  - `{:error, reason}` - Scheduling failed with error details
  """
  @spec schedule_activities(String.t(), list(), keyword()) :: 
    {:ok, SimulationResult.t()} | {:error, String.t()}
  def schedule_activities(schedule_name, activities, opts \\ []) do
    entities = Keyword.get(opts, :entities, [])
    raw_resources = Keyword.get(opts, :resources, [])
    constraints = Keyword.get(opts, :constraints, %{})
    simulation_mode = Keyword.get(opts, :simulation_mode, false)
    verbose = Keyword.get(opts, :verbose, 0)
    log_activities = Keyword.get(opts, :log_activities, true)
    
    # Convert resources from map format to struct format if needed
    resources = convert_resources_to_structs(raw_resources)
    
    if verbose > 0 do
      Logger.info("AriaEngine.Scheduler: Starting #{if simulation_mode, do: "simulation", else: "scheduling"} for '#{schedule_name}'")
      Logger.info("AriaEngine.Scheduler: #{length(activities)} activities, #{length(entities)} entities, #{length(resources)} resources")
    end
    
    try do
      # Initialize activity log
      activity_log = if log_activities, do: [], else: nil
      
      # Delegate to core implementation
      AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
        schedule_name, 
        activities, 
        entities, 
        resources, 
        constraints, 
        simulation_mode,
        activity_log,
        verbose
      )
    rescue
      e ->
        error_msg = "Scheduler error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end
  
  @doc """
  Run a simulation to predict scheduling outcomes without execution.
  
  This is a convenience function that sets simulation_mode to true.
  """
  @spec simulate_schedule(String.t(), list(), keyword()) :: 
    {:ok, SimulationResult.t()} | {:error, String.t()}
  def simulate_schedule(schedule_name, activities, opts \\ []) do
    opts = Keyword.put(opts, :simulation_mode, true)
    schedule_activities(schedule_name, activities, opts)
  end
  
  @doc """
  Analyze resource utilization for a given schedule.
  
  Provides detailed metrics including:
  - Resource usage patterns
  - Efficiency scores
  - Bottleneck identification
  - Optimization recommendations
  """
  @spec analyze_resource_utilization([map()], [Resource.t()]) :: map()
  def analyze_resource_utilization(schedule, resources) do
    AriaEngine.Scheduler.Core.calculate_resource_utilization(schedule, resources)
  end
  
  # Private helper functions
  
  @doc false
  defp convert_resources_to_structs(resources) when is_list(resources) do
    # Already a list, assume it's in the correct format
    resources
  end
  
  defp convert_resources_to_structs(resources) when is_map(resources) do
    # Convert map format to list of Resource structs
    Enum.map(resources, fn {resource_id, resource_config} ->
      %Resource{
        id: to_string(resource_id),
        type: Map.get(resource_config, :type, :computational),
        capacity: Map.get(resource_config, :capacity, 1),
        current_usage: Map.get(resource_config, :current_usage, 0),
        constraints: Map.get(resource_config, :constraints, %{}),
        availability_schedule: Map.get(resource_config, :availability_schedule, []),
        metadata: Map.get(resource_config, :metadata, %{})
      }
    end)
  end
  
  defp convert_resources_to_structs(_), do: []
end
