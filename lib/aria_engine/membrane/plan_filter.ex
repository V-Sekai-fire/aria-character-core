# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.PlanFilter do
  @moduledoc """
  Membrane Filter element that converts MCP requests to planning parameters.
  
  This element validates MCP input and transforms it into the format expected
  by the HybridCoordinator planning system using the existing PlanTransformer.
  """

  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias AriaEngine.HybridPlanner.PlanTransformer
  alias Membrane.Buffer

  def_input_pad :input,
    accepted_format: MCPRequest,
    flow_control: :auto

  def_output_pad :output,
    accepted_format: PlanningParams,
    flow_control: :auto

  def_options telemetry_prefix: [
    spec: [atom()],
    default: [:aria_engine, :membrane, :plan_filter],
    description: "Telemetry event prefix for monitoring"
  ]

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      processed_count: 0,
      success_count: 0,
      error_count: 0
    }
    
    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    %Buffer{payload: mcp_request} = buffer
    start_time = System.monotonic_time(:microsecond)

    case transform_mcp_request(mcp_request) do
      {:ok, planning_params} ->
        # Extract activities count for telemetry
        activities_count = length(mcp_request.parameters["activities"] || [])

        emit_telemetry(state.telemetry_prefix, :transformation_success, %{
          request_id: mcp_request.request_id,
          processing_time: System.monotonic_time(:microsecond) - start_time,
          activities_count: activities_count
        })

        output_buffer = %Buffer{payload: planning_params}
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          success_count: state.success_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        emit_telemetry(state.telemetry_prefix, :transformation_error, %{
          request_id: mcp_request.request_id,
          error_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        error_params = create_error_planning_params(mcp_request, reason)
        output_buffer = %Buffer{payload: error_params}
        new_state = %{state | 
          processed_count: state.processed_count + 1,
          error_count: state.error_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  defp transform_mcp_request(%MCPRequest{} = request) do
    # Extract parameters directly from the MCP request
    mcp_params = request.parameters
    
    case PlanTransformer.convert_to_planning_params(mcp_params) do
      {:ok, transformer_result} ->
        planning_params = %PlanningParams{
          domain: transformer_result.domain,
          state: transformer_result.initial_state,
          goals: transformer_result.goals,
          options: [],
          request_id: request.request_id,
          conversion_metadata: %{
            original_activities: length(mcp_params["activities"] || []),
            converted_at: DateTime.utc_now(),
            schedule_name: mcp_params["schedule_name"],
            transformer_metadata: transformer_result.metadata
          }
        }
        {:ok, planning_params}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_error_planning_params(%MCPRequest{} = request, reason) do
    # Try to extract activities count for error metadata, handle malformed data
    activities_count = case request.parameters["activities"] do
      activities when is_list(activities) -> length(activities)
      _ -> 0
    end

    %PlanningParams{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true],
      request_id: request.request_id,
      conversion_metadata: %{
        error: true,
        error_reason: reason,
        converted_at: DateTime.utc_now(),
        original_activities: activities_count
      }
    }
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  # Public API for testing and monitoring

  @doc """
  Gets the current processing statistics of the PlanFilter element.
  """
  @spec get_stats(pid()) :: map()
  def get_stats(filter_pid) do
    send(filter_pid, {:get_stats, self()})
    
    receive do
      {:plan_filter_stats, stats} -> stats
    after
      5000 -> %{error: "Timeout waiting for stats"}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      success_count: state.success_count,
      error_count: state.error_count,
      success_rate: calculate_success_rate(state.success_count, state.processed_count)
    }
    
    send(from, {:plan_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    require Logger
    Logger.debug("PlanFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  def calculate_success_rate(0, 0), do: 0.0
  def calculate_success_rate(success_count, total_count) do
    Float.round(success_count / total_count * 100, 2)
  end
end
