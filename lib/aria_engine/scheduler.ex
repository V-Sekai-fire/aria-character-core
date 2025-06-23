defmodule AriaEngine.Scheduler do
  @moduledoc "Advanced scheduler with entity/resource/capability management and simulation.\n\nProvides comprehensive scheduling capabilities including:\n- Entity and resource modeling with capabilities\n- run_lazy simulation for predictive scheduling\n- Resource conflict detection and resolution\n- Critical path analysis with resource constraints\n\n## Features\n\n- Entity management with capabilities and availability\n- Resource modeling with capacity and constraints\n- Simulation modes for schedule validation\n- Timeline optimization\n\n## Usage\n\n    # Define entities with capabilities\n    entities = [\n      %AriaEngine.Scheduler.Entity{\n        id: \"developer_1\",\n        type: :agent,\n        capabilities: [:coding, :testing],\n        availability: %Timeline.Interval{start: 0, end: 480}\n      }\n    ]\n    \n    # Define resources with capacity\n    resources = [\n      %AriaEngine.Scheduler.Resource{\n        id: \"dev_server\",\n        type: :computational,\n        capacity: 4,\n        current_usage: 0\n      }\n    ]\n    \n    # Schedule activities with resource requirements\n    activities = [\n      %{\n        id: \"implement_feature\",\n        duration: 120,\n        dependencies: [],\n        required_capabilities: [:coding],\n        required_resources: [\"dev_server\"]\n      }\n    ]\n    \n    {:ok, result} = AriaEngine.Scheduler.schedule_activities(\n      \"Feature Development\",\n      activities,\n      entities: entities,\n      resources: resources,\n      simulation_mode: true\n    )\n"
  require Logger

  @type activity :: %{
          id: String.t(),
          duration: non_neg_integer(),
          dependencies: [String.t()],
          required_capabilities: [atom()],
          required_resources: [String.t()]
        }
  @type state :: AriaEngine.State.t()
  @type entity_list :: [Entity.t()]
  @type resource_list :: [Resource.t()]
  @type activity_list :: [activity()]
  @type schedule_options :: keyword()
  @type schedule_result :: {:ok, SimulationResult.t()} | {:error, String.t()}
  defmodule Entity do
    @moduledoc "Represents an entity (agent, NPC, object) with capabilities and availability.\n"
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
    @moduledoc "Represents a resource with capacity and constraints.\n"
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
    @moduledoc "Represents a logged activity event.\n\nSupports both absolute timestamps (when mission start time is known)\nand duration-based formatting (when only relative timing is available).\n"
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
    @moduledoc "Results from a scheduling simulation.\n"
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

  @doc "Schedule activities with advanced entity/resource management and simulation.\n\n## Parameters\n\n- `schedule_name` - Name for this scheduling request\n- `activities` - List of activities to schedule (can be empty)\n- `opts` - Required and optional parameters:\n  - `:base_datetime` - Base datetime for scheduling (REQUIRED)\n  - `:entities` - List of Entity structs with capabilities\n  - `:resources` - List of Resource structs with capacity\n  - `:constraints` - Scheduling constraints and limits\n  - `:simulation_mode` - Run in simulation mode (default: false)\n  - `:verbose` - Logging verbosity level (0-3, default: 0)\n\n## Returns\n\n- `{:ok, SimulationResult.t()}` - Successful scheduling with results\n- `{:error, reason}` - Scheduling failed with error details\n"
  @spec schedule_activities(String.t(), list(), keyword()) ::
          {:ok, SimulationResult.t()} | {:error, String.t()}
  def schedule_activities(schedule_name, activities, opts \\ []) do
    case Keyword.get(opts, :base_datetime) do
      nil ->
        {:error, "base_datetime is required but not provided"}

      %DateTime{} = base_datetime ->
        entities = Keyword.get(opts, :entities, [])
        raw_resources = Keyword.get(opts, :resources, [])
        constraints = Keyword.get(opts, :constraints, %{})
        simulation_mode = Keyword.get(opts, :simulation_mode, false)
        verbose = Keyword.get(opts, :verbose, 0)
        log_activities = Keyword.get(opts, :log_activities, true)

        schedule_activities_with_base_datetime(
          schedule_name,
          activities,
          base_datetime,
          entities,
          raw_resources,
          constraints,
          simulation_mode,
          verbose,
          log_activities
        )

      _ ->
        {:error, "base_datetime must be a DateTime struct"}
    end
  end

  defp schedule_activities_with_base_datetime(
         schedule_name,
         activities,
         base_datetime,
         entities,
         raw_resources,
         constraints,
         simulation_mode,
         verbose,
         log_activities
       ) do
    resources = convert_resources_to_structs(raw_resources)

    if verbose > 0 do
      Logger.info(
        "AriaEngine.Scheduler: Starting #{if simulation_mode do
          "simulation"
        else
          "scheduling"
        end} for '#{schedule_name}'"
      )

      Logger.info(
        "AriaEngine.Scheduler: #{length(activities)} activities, #{length(entities)} entities, #{length(resources)} resources"
      )
    end

    try do
      activity_log =
        if log_activities do
          []
        else
          nil
        end

      AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
        schedule_name,
        activities,
        entities,
        resources,
        constraints,
        simulation_mode,
        activity_log,
        verbose,
        base_datetime
      )
    rescue
      e ->
        error_msg = "Scheduler error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc "Run a simulation to predict scheduling outcomes without execution.\n\nThis is a convenience function that sets simulation_mode to true.\n"
  @spec simulate_schedule(String.t(), list(), keyword()) ::
          {:ok, SimulationResult.t()} | {:error, String.t()}
  def simulate_schedule(schedule_name, activities, opts \\ []) do
    opts = Keyword.put(opts, :simulation_mode, true)
    schedule_activities(schedule_name, activities, opts)
  end

  @doc "Analyze resource utilization is no longer supported (analytics removed).\n"
  @spec analyze_resource_utilization([map()], [Resource.t()]) :: no_return()
  def analyze_resource_utilization(_schedule, _resources) do
    raise "Resource utilization analytics have been removed from AriaEngine."
  end

  @doc false
  defp convert_resources_to_structs(resources) when is_list(resources) do
    resources
  end

  defp convert_resources_to_structs(resources) when is_map(resources) do
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

  defp convert_resources_to_structs(_) do
    []
  end
end