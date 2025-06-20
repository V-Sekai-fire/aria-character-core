# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.EchoFilter do
  @moduledoc """
  Generic Membrane Filter element that echoes input formats to corresponding output formats.
  
  This element provides mock functionality for testing pipeline flows without
  actual processing. It automatically detects input format and transforms to
  the appropriate output format:
  
  - MCPRequest → MCPResponse (direct MCP testing)
  - PlanningParams → PlanningResult (PlannerSink mock)
  
  ## Pipeline Configurations
  
  **Direct MCP Testing:**
  ```
  MCPSource → EchoFilter → MCPSink
  ```
  
  **Full Pipeline Testing:**
  ```
  MCPSource → PlanFilter → EchoFilter → MCPSink
  ```
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{MCPRequest, MCPResponse, PlanningParams, PlanningResult}
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: [MCPRequest, PlanningParams],
    flow_control: :auto

  def_output_pad :output,
    accepted_format: [MCPResponse, PlanningResult],
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
              telemetry_prefix: [
                spec: [atom()],
                default: [:aria_engine, :membrane, :echo_filter],
                description: "Telemetry event prefix for monitoring"
              ]

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      mock_scenario: opts.mock_scenario,
      processing_delay_ms: opts.processing_delay_ms,
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
    
    response = create_mock_mcp_response(request, state.mock_scenario)
    
    emit_telemetry(state.telemetry_prefix, :mcp_transform, %{
      request_id: request.request_id,
      scenario: state.mock_scenario,
      processing_time: System.monotonic_time(:microsecond) - start_time
    })
    
    output_buffer = %Buffer{payload: response}
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
            original_activities: length(request.activities),
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
      "schedule_name" => request.schedule_name,
      "activities" => Enum.map(request.activities, fn activity ->
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
      "resources" => request.resources,
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

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # Public API for testing and configuration

  @doc """
  Gets the current processing statistics of the EchoFilter element.
  """
  @spec get_stats(pid()) :: map()
  def get_stats(filter_pid) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:echo_filter_stats, stats} -> stats
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
    
    send(from, {:echo_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    require Logger
    Logger.debug("EchoFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
