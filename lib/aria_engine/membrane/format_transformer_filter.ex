# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.FormatTransformerFilter do
  @moduledoc """
  Generic Membrane Filter element that transforms between defined format types.
  
  This element implements explicit transformation tuples for format conversion in
  Membrane pipelines. Each input/output format pair requires explicit implementation
  for proper pipeline connections to work.
  
  ## Implemented Transformation Pairs
  
  - MCPRequest → MCPResponse (direct MCP testing)
  - MCPRequest → PlanningParams (bypass PlanFilter)
  - PlanningParams → PlanningResult (PlannerSink mock)
  - PlanningResult → MCPResponse (bypass ResponseFilter)
  
  ## "Let It Fail" Strategy
  
  We implement the most common transformation pairs explicitly. For unsupported
  format combinations, the element will fail fast with clear error messages,
  following Erlang's "let it fail" philosophy. This approach:
  
  - Keeps implementation focused on actual use cases
  - Provides clear feedback when unsupported combinations are attempted
  - Allows the market (actual usage) to decide which transformations are needed
  - Avoids over-engineering for theoretical scenarios
  
  New transformation pairs can be added when real use cases emerge, rather than
  implementing every possible combination upfront.
  
  ## Pipeline Configurations
  
  **Direct MCP Testing:**
  ```
  MCPSource → FormatTransformerFilter → MCPSink
  ```
  Uses: MCPRequest → MCPResponse
  
  **Bypass PlanFilter:**
  ```
  MCPSource → FormatTransformerFilter → PlannerSink
  ```
  Uses: MCPRequest → PlanningParams
  
  **Mock Planning:**
  ```
  MCPSource → PlanFilter → FormatTransformerFilter → MCPSink
  ```
  Uses: PlanningParams → PlanningResult
  
  **Bypass ResponseFilter:**
  ```
  PlannerSink → FormatTransformerFilter → MCPSink
  ```
  Uses: PlanningResult → MCPResponse
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{MCPRequest, MCPResponse, PlanningParams, PlanningResult}
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: [MCPRequest, PlanningParams, PlanningResult],
    flow_control: :auto

  def_output_pad :output,
    accepted_format: [MCPResponse, PlanningResult, PlanningParams],
    flow_control: :auto

  def_options mock_scenario: [
                spec: :success | :error | :timeout,
                default: :success,
                description: "Mock response scenario for testing"
              ],
              processing_delay_ms: [
                spec: non_neg_integer(),
                default: 0,
                description: "Simulated processing delay in milliseconds"
              ],
              output_format: [
                spec: :auto | :mcp_response | :planning_params | :planning_result,
                default: :auto,
                description: "Force specific output format (auto detects based on pipeline needs)"
              ],
              telemetry_prefix: [
                spec: [atom()],
                default: [:aria_engine, :membrane, :format_transformer_filter],
                description: "Telemetry event prefix for monitoring"
              ]

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      mock_scenario: opts.mock_scenario,
      processing_delay_ms: opts.processing_delay_ms,
      output_format: opts.output_format,
      telemetry_prefix: opts.telemetry_prefix,
      processed_count: 0,
      mcp_transforms: 0,
      planning_transforms: 0
    }
    
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: %MCPRequest{} = request}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Simulate processing delay if configured
    if state.processing_delay_ms > 0 do
      Process.sleep(state.processing_delay_ms)
    end
    
    # Determine output format based on configuration
    output_payload = case state.output_format do
      :planning_params ->
        create_planning_params_from_mcp_request(request, state.mock_scenario)
      
      :mcp_response ->
        create_mock_mcp_response(request, state.mock_scenario)
      
      :auto ->
        # Default to MCPResponse for auto mode
        create_mock_mcp_response(request, state.mock_scenario)
    end
    
    emit_telemetry(state.telemetry_prefix, :mcp_transform, %{
      request_id: request.request_id,
      scenario: state.mock_scenario,
      output_format: state.output_format,
      processing_time: System.monotonic_time(:microsecond) - start_time
    })
    
    output_buffer = %Buffer{payload: output_payload}
    new_state = %{state | 
      processed_count: state.processed_count + 1,
      mcp_transforms: state.mcp_transforms + 1
    }
    
    {[buffer: {:output, output_buffer}], new_state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: %PlanningParams{} = params}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Simulate processing delay if configured
    if state.processing_delay_ms > 0 do
      Process.sleep(state.processing_delay_ms)
    end
    
    result = create_mock_planning_result(params, state.mock_scenario)
    
    emit_telemetry(state.telemetry_prefix, :planning_transform, %{
      request_id: params.request_id,
      scenario: state.mock_scenario,
      processing_time: System.monotonic_time(:microsecond) - start_time
    })
    
    output_buffer = %Buffer{payload: result}
    new_state = %{state | 
      processed_count: state.processed_count + 1,
      planning_transforms: state.planning_transforms + 1
    }
    
    {[buffer: {:output, output_buffer}], new_state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: %PlanningResult{} = result}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Simulate processing delay if configured
    if state.processing_delay_ms > 0 do
      Process.sleep(state.processing_delay_ms)
    end
    
    response = create_mcp_response_from_planning_result(result, state.mock_scenario)
    
    emit_telemetry(state.telemetry_prefix, :result_to_mcp_transform, %{
      request_id: result.request_id,
      scenario: state.mock_scenario,
      processing_time: System.monotonic_time(:microsecond) - start_time
    })
    
    output_buffer = %Buffer{payload: response}
    new_state = %{state | 
      processed_count: state.processed_count + 1,
      planning_transforms: state.planning_transforms + 1
    }
    
    {[buffer: {:output, output_buffer}], new_state}
  end

  # Catch-all clause for unsupported payload types
  @impl true
  def handle_buffer(:input, %Buffer{payload: _payload} = buffer, _ctx, state) do
    # Pass through unsupported payloads unchanged
    new_state = %{state | processed_count: state.processed_count + 1}
    {[buffer: {:output, buffer}], new_state}
  end

  # Private functions for mock response creation

  defp create_mock_mcp_response(%MCPRequest{} = request, scenario) do
    case scenario do
      :success ->
        %MCPResponse{
          status: "success",
          schedule: create_mock_schedule(request),
          error_details: nil,
          request_id: request.request_id,
          response_metadata: %{
            mock: true,
            echoed_at: DateTime.utc_now(),
            original_activities: length(request.parameters["activities"] || []),
            scenario: :success
          }
        }
        
      :error ->
        %MCPResponse{
          status: "error",
          schedule: nil,
          error_details: "Mock error scenario for testing",
          request_id: request.request_id,
          response_metadata: %{
            mock: true,
            echoed_at: DateTime.utc_now(),
            scenario: :error
          }
        }
        
      :timeout ->
        %MCPResponse{
          status: "timeout",
          schedule: nil,
          error_details: "Mock timeout scenario for testing",
          request_id: request.request_id,
          response_metadata: %{
            mock: true,
            echoed_at: DateTime.utc_now(),
            scenario: :timeout
          }
        }
    end
  end

  defp create_mock_planning_result(%PlanningParams{} = params, scenario) do
    case scenario do
      :success ->
        %PlanningResult{
          status: :success,
          result: create_mock_plan(params),
          execution_metadata: %{
            mock: true,
            echoed_at: DateTime.utc_now(),
            scenario: :success
          },
          request_id: params.request_id,
          performance_metrics: %{
            execution_time_ms: 50,  # Mock execution time
            mock: true
          }
        }
        
      :error ->
        %PlanningResult{
          status: :error,
          result: nil,
          execution_metadata: %{
            mock: true,
            error_reason: "Mock planning error for testing",
            echoed_at: DateTime.utc_now(),
            scenario: :error
          },
          request_id: params.request_id,
          performance_metrics: %{
            execution_time_ms: 10,
            mock: true
          }
        }
        
      :timeout ->
        %PlanningResult{
          status: :error,
          result: nil,
          execution_metadata: %{
            mock: true,
            error_reason: "Mock planning timeout for testing",
            echoed_at: DateTime.utc_now(),
            scenario: :timeout
          },
          request_id: params.request_id,
          performance_metrics: %{
            execution_time_ms: 5000,  # Mock timeout duration
            mock: true
          }
        }
    end
  end

  defp create_mock_schedule(%MCPRequest{} = request) do
    %{
      "schedule_name" => request.parameters["schedule_name"],
      "activities" => Enum.map(request.parameters["activities"] || [], fn activity ->
        Map.merge(activity, %{
          "status" => "scheduled",
          "start_time" => "2025-06-20T16:00:00Z",
          "end_time" => "2025-06-20T17:00:00Z",
          "mock" => true
        })
      end),
      "timeline" => %{
        "start" => "2025-06-20T16:00:00Z",
        "end" => "2025-06-20T18:00:00Z",
        "mock" => true
      },
      "resources" => request.parameters["resources"] || %{},
      "constraints_satisfied" => true,
      "mock" => true
    }
  end

  defp create_mock_plan(%PlanningParams{} = params) do
    %{
      actions: [
        %{id: "mock_action_1", type: "start", timestamp: 0},
        %{id: "mock_action_2", type: "process", timestamp: 100},
        %{id: "mock_action_3", type: "complete", timestamp: 200}
      ],
      timeline: %{
        start: 0,
        end: 200,
        duration: 200
      },
      metadata: %{
        mock: true,
        original_goals: length(params.goals || []),
        planning_method: "echo_filter_mock"
      }
    }
  end

  defp create_mcp_response_from_planning_result(%PlanningResult{} = result, _scenario) do
    case result.status do
      :success ->
        %MCPResponse{
          status: "success",
          schedule: format_planning_result_to_schedule(result.result),
          error_details: nil,
          request_id: result.request_id,
          response_metadata: %{
            transformed_from: "planning_result",
            execution_time_ms: result.performance_metrics.execution_time_ms,
            transformed_at: DateTime.utc_now()
          }
        }
        
      :error ->
        %MCPResponse{
          status: "error",
          schedule: nil,
          error_details: get_in(result.execution_metadata, [:error_reason]) || "Planning execution failed",
          request_id: result.request_id,
          response_metadata: %{
            transformed_from: "planning_result",
            execution_time_ms: result.performance_metrics.execution_time_ms,
            transformed_at: DateTime.utc_now()
          }
        }
    end
  end

  defp create_planning_params_from_mcp_request(%MCPRequest{} = request, _scenario) do
    # Convert MCP request to planning parameters
    # This is a mock implementation - real implementation would use PlanTransformer
    %PlanningParams{
      domain: create_mock_domain(request),
      state: create_mock_state(request),
      goals: create_mock_goals(request),
      options: [],
      request_id: request.request_id,
      conversion_metadata: %{
        converted_from: "mcp_request",
        tool_name: request.tool_name,
        converted_at: DateTime.utc_now(),
        mock: true
      }
    }
  end

  defp format_planning_result_to_schedule(plan_result) when is_map(plan_result) do
    %{
      "activities" => extract_activities_from_plan(plan_result),
      "timeline" => extract_timeline_from_plan(plan_result),
      "resources" => extract_resources_from_plan(plan_result),
      "status" => "completed"
    }
  end

  defp format_planning_result_to_schedule(_), do: %{}

  defp extract_activities_from_plan(%{actions: actions}) when is_list(actions) do
    Enum.map(actions, fn action ->
      %{
        "id" => action[:id] || action["id"],
        "type" => action[:type] || action["type"],
        "start_time" => format_timestamp(action[:timestamp] || action["timestamp"]),
        "status" => "scheduled"
      }
    end)
  end

  defp extract_activities_from_plan(_), do: []

  defp extract_timeline_from_plan(%{timeline: timeline}) when is_map(timeline) do
    %{
      "start" => format_timestamp(timeline[:start] || timeline["start"]),
      "end" => format_timestamp(timeline[:end] || timeline["end"]),
      "duration" => timeline[:duration] || timeline["duration"]
    }
  end

  defp extract_timeline_from_plan(_), do: %{}

  defp extract_resources_from_plan(_), do: %{}

  defp format_timestamp(timestamp) when is_integer(timestamp) do
    # Convert relative timestamp to ISO8601
    base_time = DateTime.utc_now()
    DateTime.add(base_time, timestamp, :second) |> DateTime.to_iso8601()
  end

  defp format_timestamp(_), do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp create_mock_domain(%MCPRequest{}), do: nil  # Mock domain
  defp create_mock_state(%MCPRequest{}), do: nil   # Mock state
  defp create_mock_goals(%MCPRequest{}), do: []    # Mock goals

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # Public API for testing and configuration

  @doc """
  Gets the current processing statistics of the FormatTransformerFilter element.
  """
  @spec get_stats(pid()) :: map()
  def get_stats(filter_pid) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:format_transformer_filter_stats, stats} -> stats
    after
      5000 -> %{error: "Timeout waiting for stats"}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      mcp_transforms: state.mcp_transforms,
      planning_transforms: state.planning_transforms,
      mock_scenario: state.mock_scenario,
      processing_delay_ms: state.processing_delay_ms
    }
    
    send(from, {:format_transformer_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    require Logger
    Logger.debug("FormatTransformerFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
