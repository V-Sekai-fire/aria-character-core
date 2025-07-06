# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.PlanFilter do
  @moduledoc """
  Production Membrane Filter element that converts MCPRequest to PlanningParams.

  This element transforms incoming MCP requests into the standardized PlanningParams
  format required by the planning pipeline. It handles tool-specific parameter
  extraction and validation.
  """
  use Membrane.Filter
  require Logger
  alias Membrane.Format.{MCPRequest, PlanningParams}
  alias Membrane.Buffer

  def_input_pad(:input, accepted_format: MCPRequest, flow_control: :manual, demand_unit: :buffers)
  def_output_pad(:output, accepted_format: PlanningParams, flow_control: :manual, demand_unit: :buffers)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :plan_filter],
      description: "Telemetry event prefix for monitoring"
    ],
    default_context: [
      spec: map(),
      default: %{},
      description: "Default context to include in planning parameters"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      default_context: opts.default_context,
      converted_count: 0,
      error_count: 0
    }

    Logger.info("PlanFilter initialized")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: mcp_request}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)
    Logger.debug("PlanFilter converting MCPRequest: #{mcp_request.request_id}")

    case convert_mcp_to_planning_params(mcp_request, state) do
      {:ok, planning_params} ->
        conversion_time_us = System.monotonic_time(:microsecond) - start_time

        emit_telemetry(state.telemetry_prefix, :conversion_success, %{
          request_id: mcp_request.request_id,
          tool_name: mcp_request.tool_name,
          conversion_time_us: conversion_time_us
        })

        output_buffer = %Buffer{payload: planning_params}

        new_state = %{state | converted_count: state.converted_count + 1}
        Logger.debug("PlanFilter conversion successful in #{div(conversion_time_us, 1000)}ms")

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        conversion_time_us = System.monotonic_time(:microsecond) - start_time

        emit_telemetry(state.telemetry_prefix, :conversion_error, %{
          request_id: mcp_request.request_id,
          tool_name: mcp_request.tool_name,
          error_reason: reason,
          conversion_time_us: conversion_time_us
        })

        # Create error planning params to pass through the pipeline
        error_planning_params = PlanningParams.error(reason, mcp_request.request_id)
        output_buffer = %Buffer{payload: error_planning_params}

        new_state = %{state | error_count: state.error_count + 1}
        Logger.warning("PlanFilter conversion failed: #{reason}")

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  defp convert_mcp_to_planning_params(%MCPRequest{} = mcp_request, state) do
    try do
      case mcp_request.tool_name do
        "schedule_activities" ->
          convert_schedule_activities(mcp_request, state)

        tool_name when is_binary(tool_name) ->
          convert_generic_tool(mcp_request, state)

        _ ->
          {:error, "Invalid tool name: #{inspect(mcp_request.tool_name)}"}
      end
    rescue
      error ->
        Logger.error("Conversion exception: #{inspect(error)}")
        {:error, "Conversion exception: #{Exception.message(error)}"}
    end
  end

  defp convert_schedule_activities(%MCPRequest{} = mcp_request, state) do
    arguments = mcp_request.arguments

    # Extract schedule-specific parameters
    schedule_name = Map.get(arguments, "schedule_name", "default_schedule")
    activities = Map.get(arguments, "activities", [])
    constraints = Map.get(arguments, "constraints", [])

    # Build goal from schedule parameters
    goal = %{
      type: "schedule_activities",
      schedule_name: schedule_name,
      activities: activities,
      target_completion: Map.get(arguments, "target_completion")
    }

    # Build context with schedule data
    context = Map.merge(state.default_context, %{
      "tool_name" => "schedule_activities",
      "schedule_data" => %{
        "name" => schedule_name,
        "activities" => activities
      },
      "original_arguments" => arguments
    })

    planning_params = PlanningParams.new(
      goal,
      context,
      constraints,
      mcp_request.request_id
    )

    {:ok, planning_params}
  end

  defp convert_generic_tool(%MCPRequest{} = mcp_request, state) do
    # Generic conversion for any MCP tool
    goal = %{
      type: "generic_tool_execution",
      tool_name: mcp_request.tool_name,
      parameters: mcp_request.arguments
    }

    context = Map.merge(state.default_context, %{
      "tool_name" => mcp_request.tool_name,
      "original_arguments" => mcp_request.arguments
    })

    # Extract constraints if present
    constraints = Map.get(mcp_request.arguments, "constraints", [])

    planning_params = PlanningParams.new(
      goal,
      context,
      constraints,
      mcp_request.request_id
    )

    {:ok, planning_params}
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current conversion statistics of the PlanFilter element."
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
    total_requests = state.converted_count + state.error_count

    stats = %{
      converted_count: state.converted_count,
      error_count: state.error_count,
      total_requests: total_requests,
      success_rate:
        if total_requests > 0 do
          state.converted_count / total_requests
        else
          0.0
        end
    }

    send(from, {:plan_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("PlanFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
