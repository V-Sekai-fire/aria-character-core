# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.ScheduleFilter do
  @moduledoc """
  Membrane Filter element that processes schedule_activities MCP requests.
  
  This filter specifically handles schedule_activities tool calls by:
  1. Validating that the request is for schedule_activities
  2. Extracting and validating schedule parameters
  3. Converting to PlanningParams format for the planning pipeline
  
  ## Pipeline Position
  
  ```
  MCPSource → ScheduleFilter → PlannerSink → MCPSink
  ```
  
  The ScheduleFilter sits between the generic MCPSource and the planning
  execution, providing schedule-specific validation and transformation.
  
  ## Features
  
  - Validates schedule_activities requests
  - Rejects non-schedule requests with clear error messages
  - Converts schedule parameters to planning format
  - Provides detailed telemetry for schedule processing
  - Handles legacy format compatibility
  
  ## Usage
  
      # In a pipeline spec
      children = [
        child(:mcp_source, MCPSource)
        |> child(:schedule_filter, ScheduleFilter)
        |> child(:planner_sink, PlannerSink)
        |> child(:mcp_sink, MCPSink)
      ]
  """

  use Membrane.Filter

  require Logger

  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias AriaEngine.HybridPlanner.PlanTransformer, as: CoreTransformer
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: MCPRequest,
    flow_control: :auto

  def_output_pad :output,
    accepted_format: PlanningParams,
    flow_control: :auto

  def_options telemetry_prefix: [
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

  # ==================== Membrane Callbacks ====================

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
        new_state = %{state | 
          processed_count: state.processed_count + 1,
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

        # Create error planning params to pass the error downstream
        error_params = create_error_planning_params(mcp_request, reason, error_type)
        output_buffer = %Buffer{payload: error_params}
        
        new_state = case error_type do
          :rejected ->
            %{state | 
              processed_count: state.processed_count + 1,
              rejected_count: state.rejected_count + 1
            }
          _ ->
            %{state | 
              processed_count: state.processed_count + 1,
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

  # ==================== PRIVATE FUNCTIONS ====================

  defp process_mcp_request(%MCPRequest{} = request, state) do
    cond do
      MCPRequest.is_tool?(request, "schedule_activities") ->
        process_schedule_request(request, state)
        
      state.allow_non_schedule_requests ->
        {:error, "Non-schedule request: #{request.tool_name}", :rejected}
        
      true ->
        {:error, "Only schedule_activities requests are supported", :rejected}
    end
  end

  defp process_schedule_request(%MCPRequest{} = request, state) do
    case MCPRequest.get_tool_params(request, "schedule_activities") do
      {:ok, schedule_params} ->
        convert_schedule_to_planning_params(request, schedule_params, state)
        
      {:error, reason} ->
        {:error, "Failed to extract schedule parameters: #{reason}", :validation_error}
    end
  end

  defp convert_schedule_to_planning_params(%MCPRequest{} = request, schedule_params, state) do
    # Validate schedule parameters if strict validation is enabled
    if state.strict_validation do
      case validate_schedule_params(schedule_params) do
        :ok -> 
          perform_conversion(request, schedule_params)
        {:error, reason} -> 
          {:error, "Schedule validation failed: #{reason}", :validation_error}
      end
    else
      perform_conversion(request, schedule_params)
    end
  end

  defp perform_conversion(%MCPRequest{} = request, schedule_params) do
    case CoreTransformer.convert_to_planning_params(schedule_params) do
      {:ok, {domain, state, goals}} ->
        planning_params = %PlanningParams{
          domain: domain,
          state: state,
          goals: goals,
          options: [],
          request_id: request.request_id,
          conversion_metadata: %{
            original_tool: request.tool_name,
            converted_at: DateTime.utc_now(),
            activities_count: length(schedule_params["activities"] || []),
            entities_count: length(schedule_params["entities"] || []),
            legacy_format: Map.get(request.metadata, :legacy_format, false)
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
        validate_activities(params["activities"])
    end
  end

  defp validate_schedule_params(_), do: {:error, "parameters must be a map"}

  defp validate_activities(activities) when is_list(activities) do
    case Enum.find(activities, &(not valid_activity?(&1))) do
      nil -> :ok
      invalid_activity -> {:error, "Invalid activity: #{inspect(invalid_activity)}"}
    end
  end

  defp valid_activity?(activity) when is_map(activity) do
    Map.has_key?(activity, "id") and
    Map.has_key?(activity, "name") and
    is_binary(activity["id"]) and
    is_binary(activity["name"])
  end

  defp valid_activity?(_), do: false

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
        converted_at: DateTime.utc_now()
      }
    }
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # ==================== PUBLIC API FOR TESTING AND MONITORING ====================

  @doc """
  Gets the current processing statistics of the ScheduleFilter element.
  
  ## Parameters
  
  - `filter_pid` - PID of the ScheduleFilter element
  - `timeout` - Timeout in milliseconds (default: 5000)
  
  ## Returns
  
  Map containing current statistics or error.
  """
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:schedule_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc """
  Validates schedule parameters without processing them.
  
  This is useful for testing parameter validation logic independently.
  """
  @spec validate_params(map()) :: :ok | {:error, String.t()}
  def validate_params(params) when is_map(params) do
    validate_schedule_params(params)
  end

  def validate_params(_), do: {:error, "Parameters must be a map"}
end
