# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.ResponseFilter do
  @moduledoc """
  Production Membrane Filter element that converts PlanningResult to MCPResponse.

  This element transforms planning results into the standardized MCPResponse
  format required for MCP tool consumption. It handles result formatting,
  error handling, and response status codes.

  Consolidates functionality from both ResponseFilter and PlannerMCPFilter
  to provide comprehensive PlanningResult → MCPResponse transformation.
  """
  use Membrane.Filter
  require Logger
  alias Membrane.Format.{PlanningResult, MCPResponse}
  alias Membrane.Buffer

  def_input_pad(:input, accepted_format: PlanningResult, flow_control: :manual, demand_unit: :buffers)
  def_output_pad(:output, accepted_format: MCPResponse, flow_control: :manual, demand_unit: :buffers)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :response_filter],
      description: "Telemetry event prefix for monitoring"
    ],
    response_format: [
      spec: :json | :structured | :mcp_compatible,
      default: :json,
      description: "Format for response content (:json, :structured, or :mcp_compatible)"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      response_format: opts.response_format,
      converted_count: 0,
      success_count: 0,
      error_count: 0
    }

    Logger.info("ResponseFilter initialized with format: #{opts.response_format}")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: planning_result}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    Logger.debug("ResponseFilter converting PlanningResult: #{planning_result.request_id}")

    case convert_planning_result_to_mcp_response(planning_result, state) do
      {:ok, mcp_response} ->
        conversion_time_us = System.monotonic_time(:microsecond) - start_time

        emit_telemetry(state.telemetry_prefix, :conversion_success, %{
          request_id: planning_result.request_id,
          status: planning_result.status,
          conversion_time_us: conversion_time_us
        })

        output_buffer = %Buffer{payload: mcp_response}

        new_state = %{
          state
          | converted_count: state.converted_count + 1,
            success_count: if(planning_result.status == :success, do: state.success_count + 1, else: state.success_count)
        }

        Logger.debug("ResponseFilter conversion successful in #{div(conversion_time_us, 1000)}ms")
        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        conversion_time_us = System.monotonic_time(:microsecond) - start_time

        emit_telemetry(state.telemetry_prefix, :conversion_error, %{
          request_id: planning_result.request_id,
          error_reason: reason,
          conversion_time_us: conversion_time_us
        })

        # Create error response
        error_response = MCPResponse.error(reason, planning_result.request_id)
        output_buffer = %Buffer{payload: error_response}

        new_state = %{
          state
          | converted_count: state.converted_count + 1,
            error_count: state.error_count + 1
        }

        Logger.warning("ResponseFilter conversion failed: #{reason}")
        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  defp convert_planning_result_to_mcp_response(%PlanningResult{} = planning_result, state) do
    try do
      case planning_result.status do
        :success ->
          convert_success_result(planning_result, state)

        :error ->
          convert_error_result(planning_result, state)

        _ ->
          {:error, "Unknown planning result status: #{planning_result.status}"}
      end
    rescue
      error ->
        Logger.error("Response conversion exception: #{inspect(error)}")
        {:error, "Response conversion exception: #{Exception.message(error)}"}
    end
  end

  defp convert_success_result(%PlanningResult{} = planning_result, state) do
    # Extract the first result from the results list
    result_data = case planning_result.results do
      [first_result | _] -> first_result
      [] -> %{}
      single_result when is_map(single_result) -> single_result
      _ -> %{raw_results: planning_result.results}
    end

    # Format response content based on configuration
    content = case state.response_format do
      :json ->
        format_json_response(result_data, planning_result)

      :structured ->
        format_structured_response(result_data, planning_result)

      :mcp_compatible ->
        format_mcp_compatible_response(result_data, planning_result)
    end

    mcp_response = MCPResponse.success(
      content,
      planning_result.execution_metadata,
      planning_result.request_id
    )

    {:ok, mcp_response}
  end

  defp convert_error_result(%PlanningResult{} = planning_result, _state) do
    error_message = case planning_result.results do
      [error_msg] when is_binary(error_msg) -> error_msg
      error_msg when is_binary(error_msg) -> error_msg
      _ -> "Planning execution failed"
    end

    mcp_response = MCPResponse.error(error_message, planning_result.request_id)
    {:ok, mcp_response}
  end

  defp format_json_response(result_data, planning_result) do
    response_map = %{
      status: "success",
      result: result_data,
      metadata: planning_result.execution_metadata,
      request_id: planning_result.request_id,
      timestamp: DateTime.utc_now()
    }

    case Jason.encode(response_map) do
      {:ok, json_string} -> json_string
      {:error, _} -> inspect(response_map)
    end
  end

  defp format_structured_response(result_data, planning_result) do
    %{
      status: "success",
      result: result_data,
      metadata: planning_result.execution_metadata,
      request_id: planning_result.request_id,
      timestamp: DateTime.utc_now()
    }
  end

  defp format_mcp_compatible_response(result_data, planning_result) do
    %{
      "status" => "success",
      "schedule" => format_schedule_from_planning_result(result_data),
      "error_details" => nil,
      "request_id" => planning_result.request_id,
      "response_metadata" => %{
        "formatted_at" => DateTime.utc_now(),
        "execution_time_ms" => get_in(planning_result, [:performance_metrics, :execution_time_ms]) || 0,
        "planning_metadata" => planning_result.metadata,
        "transformation_source" => "response_filter"
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
    %{
      "activities" => [],
      "timeline" => %{},
      "resources" => %{},
      "metadata" => %{"error" => "Unable to format plan result"}
    }
  end

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

      _ ->
        []
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

      _ ->
        %{}
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
        Enum.reduce(metadata, %{}, fn {key, value}, acc ->
          string_key =
            if is_atom(key) do
              Atom.to_string(key)
            else
              key
            end

          Map.put(acc, string_key, value)
        end)

      _ ->
        %{}
    end
  end

  defp get_action_field(action, keys) when is_map(action) do
    Enum.find_value(keys, fn key -> Map.get(action, key) end)
  end

  defp get_action_field(_action, _keys) do
    nil
  end

  defp get_field(map, keys) when is_map(map) do
    Enum.find_value(keys, fn key -> Map.get(map, key) end)
  end

  defp get_field(_map, _keys) do
    nil
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current conversion statistics of the ResponseFilter element."
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
      converted_count: state.converted_count,
      success_count: state.success_count,
      error_count: state.error_count,
      success_rate:
        if state.converted_count > 0 do
          state.success_count / state.converted_count
        else
          0.0
        end,
      response_format: state.response_format
    }

    send(from, {:response_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("ResponseFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
