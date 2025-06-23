defmodule AriaEngine.Membrane.SchedulePlannerFilter do
  @moduledoc "Membrane Filter element that processes schedule_activities MCP requests.\n\nThis filter specifically handles schedule_activities tool calls by:\n1. Validating that the request is for schedule_activities\n2. Extracting and validating schedule parameters\n3. Converting to PlanningParams format for the planning pipeline\n\n## Pipeline Position\n\n```\nMCPSource → ScheduleFilter → PlannerSink → MCPSink\n```\n\nThe ScheduleFilter sits between the generic MCPSource and the planning\nexecution, providing schedule-specific validation and transformation.\n\n## Features\n\n- Validates schedule_activities requests\n- Rejects non-schedule requests with clear error messages\n- Converts schedule parameters to planning format\n- Provides detailed telemetry for schedule processing\n- Handles legacy format compatibility\n\n## Usage\n\n    # In a pipeline spec\n    children = [\n      child(:mcp_source, MCPSource)\n      |> child(:schedule_filter, ScheduleFilter)\n      |> child(:planner_sink, PlannerSink)\n      |> child(:mcp_sink, MCPSink)\n    ]\n"
  use Membrane.Filter
  require Logger
  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias AriaEngine.HybridPlanner.PlanTransformer, as: CoreTransformer
  alias Membrane.Buffer
  def_input_pad(:input, accepted_format: MCPRequest, flow_control: :auto)
  def_output_pad(:output, accepted_format: PlanningParams, flow_control: :auto)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :schedule_filter],
      description: "Telemetry event prefix for monitoring"
    ],
    strict_validation: [
      spec: boolean(),
      default: true,
      description: "Whether to strictly validate schedule parameters"
    ],
    allow_non_schedule_requests: [
      spec: boolean(),
      default: false,
      description: "Whether to pass through non-schedule requests as errors"
    ]
  )

  @typedoc "Internal state of the ScheduleFilter element"
  @type state :: %{
          telemetry_prefix: [atom()],
          strict_validation: boolean(),
          allow_non_schedule_requests: boolean(),
          processed_count: non_neg_integer(),
          schedule_count: non_neg_integer(),
          error_count: non_neg_integer(),
          rejected_count: non_neg_integer()
        }
  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      strict_validation: opts.strict_validation,
      allow_non_schedule_requests: opts.allow_non_schedule_requests,
      processed_count: 0,
      schedule_count: 0,
      error_count: 0,
      rejected_count: 0
    }

    Logger.info("ScheduleFilter initialized with strict_validation: #{opts.strict_validation}")

    emit_telemetry(state.telemetry_prefix, :initialized, %{
      strict_validation: opts.strict_validation,
      allow_non_schedule_requests: opts.allow_non_schedule_requests
    })

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: mcp_request}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    case process_mcp_request(mcp_request, state) do
      {:ok, planning_params, processing_info} ->
        emit_telemetry(state.telemetry_prefix, :schedule_processed, %{
          request_id: mcp_request.request_id,
          processing_time: System.monotonic_time(:microsecond) - start_time,
          activities_count: processing_info.activities_count,
          entities_count: processing_info.entities_count
        })

        output_buffer = %Buffer{payload: planning_params}

        new_state = %{
          state
          | processed_count: state.processed_count + 1,
            schedule_count: state.schedule_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason, error_type} ->
        Logger.warning("ScheduleFilter processing failed: #{reason}")

        emit_telemetry(state.telemetry_prefix, :processing_error, %{
          request_id: mcp_request.request_id,
          error_reason: reason,
          error_type: error_type,
          tool_name: mcp_request.tool_name,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        error_params = create_error_planning_params(mcp_request, reason, error_type)
        output_buffer = %Buffer{payload: error_params}

        new_state =
          case error_type do
            :rejected ->
              %{
                state
                | processed_count: state.processed_count + 1,
                  rejected_count: state.rejected_count + 1
              }

            _ ->
              %{
                state
                | processed_count: state.processed_count + 1,
                  error_count: state.error_count + 1
              }
          end

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      schedule_count: state.schedule_count,
      error_count: state.error_count,
      rejected_count: state.rejected_count,
      strict_validation: state.strict_validation,
      allow_non_schedule_requests: state.allow_non_schedule_requests
    }

    send(from, {:schedule_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("ScheduleFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp process_mcp_request(%MCPRequest{} = request, state) do
    cond do
      request.tool_name == "schedule_activities" ->
        process_schedule_request(request, state)

      state.allow_non_schedule_requests ->
        {:error, "Non-schedule request: #{request.tool_name}", :rejected}

      true ->
        {:error, "Only schedule_activities requests are supported", :rejected}
    end
  end

  defp process_schedule_request(%MCPRequest{} = request, state) do
    schedule_params = request.parameters
    convert_schedule_to_planning_params(request, schedule_params, state)
  end

  defp convert_schedule_to_planning_params(%MCPRequest{} = request, schedule_params, state) do
    if state.strict_validation do
      case validate_schedule_params(schedule_params) do
        :ok -> perform_conversion(request, schedule_params)
        {:error, reason} -> {:error, "Schedule validation failed: #{reason}", :validation_error}
      end
    else
      perform_conversion(request, schedule_params)
    end
  end

  defp perform_conversion(%MCPRequest{} = request, schedule_params) do
    case CoreTransformer.convert_to_planning_params(schedule_params) do
      {:ok, transformer_result} ->
        planning_params = %PlanningParams{
          domain: transformer_result.domain,
          state: transformer_result.initial_state,
          goals: transformer_result.goals,
          options: [],
          request_id: request.request_id,
          conversion_metadata: %{
            original_tool: request.tool_name,
            converted_at: DateTime.utc_now(),
            activities_count: length(schedule_params["activities"] || []),
            entities_count: length(schedule_params["entities"] || []),
            legacy_format: Map.get(request.metadata, :legacy_format, false),
            transformer_metadata: transformer_result.metadata
          }
        }

        processing_info = %{
          activities_count: length(schedule_params["activities"] || []),
          entities_count: length(schedule_params["entities"] || [])
        }

        {:ok, planning_params, processing_info}

      {:error, reason} ->
        {:error, "Planning conversion failed: #{reason}", :conversion_error}
    end
  end

  defp validate_schedule_params(params) when is_map(params) do
    cond do
      not is_binary(params["schedule_name"]) ->
        {:error, "schedule_name must be a string"}

      not is_list(params["activities"]) ->
        {:error, "activities must be a list"}

      not is_list(params["entities"]) ->
        {:error, "entities must be a list"}

      not is_map(params["resources"]) ->
        {:error, "resources must be a map"}

      not is_map(params["constraints"]) ->
        {:error, "constraints must be a map"}

      Enum.empty?(params["activities"]) ->
        {:error, "activities list cannot be empty"}

      true ->
        with :ok <- validate_activities(params["activities"]),
             :ok <- validate_entities(params["entities"]),
             :ok <- validate_resources(params["resources"]),
             :ok <- validate_optional_fields(params) do
          :ok
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp validate_schedule_params(_) do
    {:error, "parameters must be a map"}
  end

  defp validate_activities(activities) when is_list(activities) do
    case Enum.find(activities, &(not valid_activity?(&1))) do
      nil -> :ok
      invalid_activity -> {:error, "Invalid activity: #{inspect(invalid_activity)}"}
    end
  end

  defp create_error_planning_params(%MCPRequest{} = request, reason, error_type) do
    %PlanningParams{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true, error_type: error_type],
      request_id: request.request_id,
      conversion_metadata: %{
        error: true,
        error_reason: reason,
        error_type: error_type,
        original_tool: request.tool_name,
        converted_at: DateTime.utc_now(),
        legacy_format: Map.get(request.metadata, :legacy_format, false)
      }
    }
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current processing statistics of the ScheduleFilter element.\n\n## Parameters\n\n- `filter_pid` - PID of the ScheduleFilter element\n- `timeout` - Timeout in milliseconds (default: 5000)\n\n## Returns\n\nMap containing current statistics or error.\n"
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})

    receive do
      {:schedule_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc "Validates schedule parameters without processing them.\n\nThis is useful for testing parameter validation logic independently.\n"
  @spec validate_params(map()) :: :ok | {:error, String.t()}
  def validate_params(params) when is_map(params) do
    validate_schedule_params(params)
  end

  def validate_params(_) do
    {:error, "Parameters must be a map"}
  end

  defp validate_entities(entities) when is_list(entities) do
    case Enum.find(entities, &(not valid_entity?(&1))) do
      nil -> :ok
      invalid_entity -> {:error, "Invalid entity: #{inspect(invalid_entity)}"}
    end
  end

  defp valid_entity?(entity) when is_map(entity) do
    has_required_fields =
      Map.has_key?(entity, "id") and Map.has_key?(entity, "type") and is_binary(entity["id"]) and
        is_binary(entity["type"])

    has_valid_optional_fields =
      valid_entity_capabilities?(entity["capabilities"]) and
        valid_entity_availability?(entity["availability"]) and
        valid_entity_resources?(entity["resources_held"]) and
        valid_entity_metadata?(entity["metadata"])

    has_required_fields and has_valid_optional_fields
  end

  defp valid_entity?(_) do
    false
  end

  defp valid_entity_capabilities?(nil) do
    true
  end

  defp valid_entity_capabilities?(capabilities) when is_list(capabilities) do
    Enum.all?(capabilities, &is_binary/1)
  end

  defp valid_entity_capabilities?(_) do
    false
  end

  defp valid_entity_availability?(nil) do
    true
  end

  defp valid_entity_availability?(availability) when is_binary(availability) do
    true
  end

  defp valid_entity_availability?(availability) when is_map(availability) do
    (is_binary(availability["start"]) or is_nil(availability["start"])) and
      (is_binary(availability["end"]) or is_nil(availability["end"]))
  end

  defp valid_entity_availability?(_) do
    false
  end

  defp valid_entity_resources?(nil) do
    true
  end

  defp valid_entity_resources?(resources) when is_list(resources) do
    Enum.all?(resources, &is_binary/1)
  end

  defp valid_entity_resources?(_) do
    false
  end

  defp valid_entity_metadata?(nil) do
    true
  end

  defp valid_entity_metadata?(metadata) when is_map(metadata) do
    true
  end

  defp valid_entity_metadata?(_) do
    false
  end

  defp validate_resources(resources) when is_map(resources) do
    case Enum.find(resources, fn {_key, resource} -> not valid_resource?(resource) end) do
      nil ->
        :ok

      {key, invalid_resource} ->
        {:error, "Invalid resource '#{key}': #{inspect(invalid_resource)}"}
    end
  end

  defp valid_resource?(resource) when is_map(resource) do
    has_valid_type = is_binary(resource["type"]) or is_nil(resource["type"])
    has_valid_capacity = is_integer(resource["capacity"]) or is_nil(resource["capacity"])
    has_valid_usage = is_integer(resource["current_usage"]) or is_nil(resource["current_usage"])
    has_valid_constraints = is_map(resource["constraints"]) or is_nil(resource["constraints"])
    has_valid_schedule = valid_resource_schedule?(resource["availability_schedule"])
    has_valid_metadata = is_map(resource["metadata"]) or is_nil(resource["metadata"])

    has_valid_type and has_valid_capacity and has_valid_usage and has_valid_constraints and
      has_valid_schedule and has_valid_metadata
  end

  defp valid_resource?(_) do
    false
  end

  defp valid_resource_schedule?(nil) do
    true
  end

  defp valid_resource_schedule?(schedule) when is_list(schedule) do
    Enum.all?(schedule, fn slot ->
      is_map(slot) and (is_binary(slot["start"]) or is_nil(slot["start"])) and
        (is_binary(slot["end"]) or is_nil(slot["end"]))
    end)
  end

  defp valid_resource_schedule?(_) do
    false
  end

  defp validate_optional_fields(params) do
    with :ok <- validate_simulation_options(params["simulation_options"]),
         :ok <- validate_resource_management(params["resource_management"]),
         :ok <- validate_pipeline_topology(params["pipeline_topology"]) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_simulation_options(nil) do
    :ok
  end

  defp validate_simulation_options(options) when is_map(options) do
    valid_simulation_mode =
      is_boolean(options["simulation_mode"]) or is_nil(options["simulation_mode"])

    valid_verbose = is_integer(options["verbose"]) or is_nil(options["verbose"])

    valid_log_activities =
      is_boolean(options["log_activities"]) or is_nil(options["log_activities"])

    if valid_simulation_mode and valid_verbose and valid_log_activities do
      :ok
    else
      {:error, "Invalid simulation_options format"}
    end
  end

  defp validate_simulation_options(_) do
    {:error, "simulation_options must be a map"}
  end

  defp validate_resource_management(nil) do
    :ok
  end

  defp validate_resource_management(management) when is_map(management) do
    valid_check_capacity =
      is_boolean(management["check_capacity"]) or is_nil(management["check_capacity"])

    valid_auto_allocate =
      is_boolean(management["auto_allocate"]) or is_nil(management["auto_allocate"])

    valid_conflict_detection =
      is_boolean(management["conflict_detection"]) or is_nil(management["conflict_detection"])

    if valid_check_capacity and valid_auto_allocate and valid_conflict_detection do
      :ok
    else
      {:error, "Invalid resource_management format"}
    end
  end

  defp validate_resource_management(_) do
    {:error, "resource_management must be a map"}
  end

  defp validate_pipeline_topology(nil) do
    :ok
  end

  defp validate_pipeline_topology(topology) when is_binary(topology) do
    :ok
  end

  defp validate_pipeline_topology(_) do
    {:error, "pipeline_topology must be a string"}
  end

  defp valid_activity?(activity) when is_map(activity) do
    has_required_fields = Map.has_key?(activity, "id") and is_binary(activity["id"])
    has_valid_duration = valid_activity_duration?(activity["duration"])
    has_valid_dependencies = valid_activity_dependencies?(activity["dependencies"])
    has_valid_capabilities = valid_activity_capabilities?(activity["required_capabilities"])
    has_valid_resources = valid_activity_resources?(activity["required_resources"])
    has_valid_participants = valid_activity_participants?(activity["participants"])
    has_valid_type = is_binary(activity["type"]) or is_nil(activity["type"])

    has_required_fields and has_valid_duration and has_valid_dependencies and
      has_valid_capabilities and has_valid_resources and has_valid_participants and has_valid_type
  end

  defp valid_activity_duration?(nil) do
    false
  end

  defp valid_activity_duration?(duration) when is_binary(duration) do
    String.starts_with?(duration, "PT") or String.starts_with?(duration, "P")
  end

  defp valid_activity_duration?(duration) when is_map(duration) do
    (is_binary(duration["start"]) or is_nil(duration["start"])) and
      (is_binary(duration["end"]) or is_nil(duration["end"])) and
      (not is_nil(duration["start"]) or not is_nil(duration["end"]))
  end

  defp valid_activity_duration?(_) do
    false
  end

  defp valid_activity_dependencies?(nil) do
    true
  end

  defp valid_activity_dependencies?(deps) when is_list(deps) do
    Enum.all?(deps, &is_binary/1)
  end

  defp valid_activity_dependencies?(_) do
    false
  end

  defp valid_activity_capabilities?(nil) do
    true
  end

  defp valid_activity_capabilities?(caps) when is_list(caps) do
    Enum.all?(caps, &is_binary/1)
  end

  defp valid_activity_capabilities?(_) do
    false
  end

  defp valid_activity_resources?(nil) do
    true
  end

  defp valid_activity_resources?(resources) when is_list(resources) do
    Enum.all?(resources, &is_binary/1)
  end

  defp valid_activity_resources?(_) do
    false
  end

  defp valid_activity_participants?(nil) do
    true
  end

  defp valid_activity_participants?(participants) when is_list(participants) do
    Enum.all?(participants, &is_binary/1)
  end

  defp valid_activity_participants?(_) do
    false
  end
end