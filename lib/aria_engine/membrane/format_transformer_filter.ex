# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.FormatTransformerFilter do
  @moduledoc """
  Migration tool with serial number: R25W021FMTR

  Decode: mix migrate.decode_serial R25W021FMTR
  """

  @serial_number "R25W021FMTR"

  @moduledoc """
  Generic format transformer filter for Membrane pipelines.

  This filter can transform between different formats and provides
  mock scenarios for testing purposes.
  """

  use Membrane.Filter

  require Logger

  def_input_pad(:input,
    accepted_format: _any,
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: _any,
    flow_control: :auto
  )

  def_options(
    mock_scenario: [
      spec: atom(),
      default: :passthrough,
      description: "Mock scenario for testing"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      mock_scenario: opts.mock_scenario
    }

    Logger.info("FormatTransformerFilter initialized with scenario: #{opts.mock_scenario}")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    case state.mock_scenario do
      :passthrough ->
        {[buffer: {:output, buffer}], state}

      :success ->
        mock_response = create_mock_success_response(buffer.payload)
        new_buffer = %{buffer | payload: mock_response}
        {[buffer: {:output, new_buffer}], state}

      :mcp_request_to_response ->
        mock_response = create_mock_mcp_response(buffer.payload)
        new_buffer = %{buffer | payload: mock_response}
        {[buffer: {:output, new_buffer}], state}

      :planning_params_to_response ->
        mock_response = create_mock_planning_response(buffer.payload)
        new_buffer = %{buffer | payload: mock_response}
        {[buffer: {:output, new_buffer}], state}

      :planning_success ->
        mock_response = create_mock_planning_success(buffer.payload)
        new_buffer = %{buffer | payload: mock_response}
        {[buffer: {:output, new_buffer}], state}

      _ ->
        Logger.warning("Unknown mock scenario: #{state.mock_scenario}")
        {[buffer: {:output, buffer}], state}
    end
  end

  defp create_mock_success_response(payload) do
    %{
      "status" => "success",
      "message" => "Mock transformation completed",
      "original_payload" => payload,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp create_mock_mcp_response(payload) do
    %{
      "jsonrpc" => "2.0",
      "id" => "mock_response_#{System.unique_integer()}",
      "result" => %{
        "status" => "success",
        "message" => "Mock response",
        "data" => payload
      }
    }
  end

  defp create_mock_planning_response(payload) do
    %{
      "status" => "success",
      "schedule" => create_mock_schedule(payload),
      "analysis" => %{
        "total_activities" => count_activities(payload),
        "makespan" => 240,
        "resource_utilization" => %{}
      },
      "timeline" => [],
      "simulation_metadata" => %{
        "mock_response" => true,
        "scenario" => "planning_params_to_response"
      }
    }
  end

  defp create_mock_planning_success(payload) do
    %{
      "status" => "success",
      "schedule" => create_mock_schedule(payload),
      "analysis" => %{
        "total_activities" => count_activities(payload),
        "makespan" => 240,
        "resource_utilization" => %{},
        "constraints_satisfied" => true
      },
      "timeline" => create_mock_timeline(payload),
      "simulation_metadata" => %{
        "mock_response" => true,
        "scenario" => "planning_success",
        "solver" => "mock_solver"
      }
    }
  end

  defp create_mock_schedule(payload) do
    activities = extract_activities(payload)

    Enum.map(activities, fn activity ->
      %{
        "id" => activity["id"],
        "name" => activity["name"] || activity["id"],
        "duration" => activity["duration"],
        "participants" => activity["participants"] || [],
        "resources" => activity["resources"] || [],
        "location" => activity["location"],
        "status" => "scheduled",
        "start_time" => get_activity_start_time(activity),
        "end_time" => get_activity_end_time(activity)
      }
    end)
  end

  defp create_mock_timeline(payload) do
    activities = extract_activities(payload)

    Enum.map(activities, fn activity ->
      %{
        "time" => get_activity_start_time(activity),
        "event" => "activity_start",
        "activity_id" => activity["id"],
        "description" => "#{activity["name"] || activity["id"]} started"
      }
    end)
  end

  defp extract_activities(payload) do
    cond do
      is_map(payload) and Map.has_key?(payload, "activities") ->
        payload["activities"]

      is_map(payload) and Map.has_key?(payload, :parameters) and
        is_map(payload.parameters) and Map.has_key?(payload.parameters, "activities") ->
        payload.parameters["activities"]

      true ->
        []
    end
  end

  defp count_activities(payload) do
    extract_activities(payload) |> length()
  end

  defp get_activity_start_time(activity) do
    case activity["duration"] do
      %{"start" => start_time} -> start_time
      _ -> DateTime.utc_now() |> DateTime.to_iso8601()
    end
  end

  defp get_activity_end_time(activity) do
    case activity["duration"] do
      %{"end" => end_time} ->
        end_time

      %{"start" => start_time} ->
        # Add 1 hour as default duration
        {:ok, start_dt, _} = DateTime.from_iso8601(start_time)
        DateTime.add(start_dt, 3600, :second) |> DateTime.to_iso8601()

      _ ->
        DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_iso8601()
    end
  end
end
