# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.PlannerMCPFilter do
  @moduledoc """
  Membrane Filter element that converts PlanningResult to MCPResponse format.
  
  This element bridges the gap between the planning execution (PlannerSink) 
  and MCP response delivery (MCPSink) by transforming planning results into
  the MCP-compatible response format.
  
  ## Pipeline Position
  
  ```
  MCPSource → PlanFilter → PlannerSink → ResponseFilter → MCPSink
  ```
  
  This filter enables the MCPSink to remain generic while providing the
  necessary format transformation for the complete pipeline.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{PlanningResult, MCPResponse}
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: PlanningResult,
    flow_control: :auto

  def_output_pad :output,
    accepted_format: MCPResponse,
    flow_control: :auto

  def_options telemetry_prefix: [
                spec: [atom()],
                default: [:aria_engine, :membrane, :response_filter],
                description: "Telemetry event prefix for monitoring"
              ]

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      processed_count: 0,
      success_transforms: 0,
      error_transforms: 0
    }
    
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: %PlanningResult{} = planning_result}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    
    mcp_response = transform_planning_result_to_mcp_response(planning_result)
    
    # Emit telemetry based on result status
    telemetry_event = case planning_result.status do
      :success -> :success_transform
      _ -> :error_transform
    end
    
    emit_telemetry(state.telemetry_prefix, telemetry_event, %{
      request_id: planning_result.request_id,
      original_status: planning_result.status,
      processing_time: System.monotonic_time(:microsecond) - start_time
    })
    
    output_buffer = %Buffer{payload: mcp_response}
    
    # Update state counters
    new_state = case planning_result.status do
      :success ->
        %{state | 
          processed_count: state.processed_count + 1,
          success_transforms: state.success_transforms + 1
        }
      _ ->
        %{state | 
          processed_count: state.processed_count + 1,
          error_transforms: state.error_transforms + 1
        }
    end
    
    {[buffer: {:output, output_buffer}], new_state}
  end

  # Catch-all clause for unsupported payload types
  @impl true
  def handle_buffer(:input, %Buffer{payload: _payload} = buffer, _ctx, state) do
    # Pass through unsupported payloads unchanged (shouldn't happen in normal pipeline)
    new_state = %{state | processed_count: state.processed_count + 1}
    {[buffer: {:output, buffer}], new_state}
  end

  # Private transformation functions

  defp transform_planning_result_to_mcp_response(%PlanningResult{status: :success} = result) do
    %MCPResponse{
      status: "success",
      schedule: format_schedule_from_planning_result(result.result),
      error_details: nil,
      request_id: result.request_id,
      response_metadata: %{
        formatted_at: DateTime.utc_now(),
        execution_time_ms: result.performance_metrics[:execution_time_ms] || 0,
        planning_metadata: result.execution_metadata,
        transformation_source: "response_filter"
      }
    }
  end

  defp transform_planning_result_to_mcp_response(%PlanningResult{status: :error} = result) do
    error_reason = get_in(result.execution_metadata, [:error_reason]) || "Unknown planning error"
    
    %MCPResponse{
      status: "error",
      schedule: nil,
      error_details: error_reason,
      request_id: result.request_id,
      response_metadata: %{
        formatted_at: DateTime.utc_now(),
        execution_time_ms: result.performance_metrics[:execution_time_ms] || 0,
        planning_metadata: result.execution_metadata,
        transformation_source: "response_filter"
      }
    }
  end

  defp transform_planning_result_to_mcp_response(%PlanningResult{} = result) do
    # Handle any other status (fallback to error)
    %MCPResponse{
      status: "error",
      schedule: nil,
      error_details: "Unexpected planning result status: #{result.status}",
      request_id: result.request_id,
      response_metadata: %{
        formatted_at: DateTime.utc_now(),
        execution_time_ms: result.performance_metrics[:execution_time_ms] || 0,
        planning_metadata: result.execution_metadata,
        transformation_source: "response_filter"
      }
    }
  end

  defp format_schedule_from_planning_result(plan_result) when is_map(plan_result) do
    %{
      "activities" => extract_activities_from_plan(plan_result),
      "timeline" => extract_timeline_from_plan(plan_result),
      "resources" => extract_resource_usage_from_plan(plan_result),
      "metadata" => extract_plan_metadata(plan_result)
    }
  end

  defp format_schedule_from_planning_result(_plan_result) do
    # Fallback for unexpected plan result format
    %{
      "activities" => [],
      "timeline" => %{},
      "resources" => %{},
      "metadata" => %{"error" => "Unable to format plan result"}
    }
  end

  # Plan extraction functions (these would integrate with existing MCPTools logic)
  
  defp extract_activities_from_plan(plan) do
    case plan do
      %{actions: actions} when is_list(actions) ->
        Enum.map(actions, fn action ->
          %{
            "id" => get_action_field(action, [:id, "id"]) || "unknown",
            "type" => get_action_field(action, [:type, "type"]) || "action",
            "timestamp" => get_action_field(action, [:timestamp, "timestamp"]) || 0,
            "status" => "scheduled"
          }
        end)
      
      _ -> []
    end
  end

  defp extract_timeline_from_plan(plan) do
    case plan do
      %{timeline: timeline} when is_map(timeline) ->
        %{
          "start" => get_field(timeline, [:start, "start"]) || 0,
          "end" => get_field(timeline, [:end, "end"]) || 0,
          "duration" => get_field(timeline, [:duration, "duration"]) || 0
        }
      
      _ -> %{}
    end
  end

  defp extract_resource_usage_from_plan(plan) do
    case plan do
      %{resources: resources} when is_map(resources) -> resources
      _ -> %{}
    end
  end

  defp extract_plan_metadata(plan) do
    case plan do
      %{metadata: metadata} when is_map(metadata) -> 
        # Convert atom keys to string keys for JSON compatibility
        Enum.reduce(metadata, %{}, fn {key, value}, acc ->
          string_key = if is_atom(key), do: Atom.to_string(key), else: key
          Map.put(acc, string_key, value)
        end)
      _ -> %{}
    end
  end

  # Helper functions to handle both atom and string keys
  defp get_action_field(action, keys) when is_map(action) do
    Enum.find_value(keys, fn key -> Map.get(action, key) end)
  end
  defp get_action_field(_action, _keys), do: nil

  defp get_field(map, keys) when is_map(map) do
    Enum.find_value(keys, fn key -> Map.get(map, key) end)
  end
  defp get_field(_map, _keys), do: nil

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # Public API for testing and monitoring

  @doc """
  Gets the current processing statistics of the ResponseFilter element.
  """
  @spec get_stats(pid()) :: map()
  def get_stats(filter_pid) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:response_filter_stats, stats} -> stats
    after
      5000 -> %{error: "Timeout waiting for stats"}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      success_transforms: state.success_transforms,
      error_transforms: state.error_transforms,
      success_rate: calculate_success_rate(state.success_transforms, state.processed_count)
    }
    
    send(from, {:response_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    require Logger
    Logger.debug("ResponseFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp calculate_success_rate(_success, 0), do: 0.0
  defp calculate_success_rate(success, total), do: success / total * 100.0
end
