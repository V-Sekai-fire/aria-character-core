defmodule AriaEngine.MCPTools.Converter do
  @moduledoc """
  Provides data conversion functions for MCP tool calls,
  transforming data between different formats and structs.
  """

  require Logger

  def convert_activities(activities) when is_list(activities) do
    Enum.map(activities, fn activity ->
      %{
        id: Map.get(activity, "id"),
        duration: process_duration(Map.get(activity, "duration")),
        dependencies: Map.get(activity, "dependencies", []),
        required_capabilities: convert_capabilities(Map.get(activity, "required_capabilities", [])),
        required_resources: convert_capabilities(Map.get(activity, "required_resources", []))
      }
    end)
  end

  def convert_activities(_), do: []

  def convert_entities(entities) when is_list(entities) do
    Enum.map(entities, fn entity ->
      %AriaEngine.Scheduler.Entity{
        id: Map.get(entity, "id", "unknown"),
        type: String.to_atom(Map.get(entity, "type", "agent")),
        capabilities: convert_capabilities(Map.get(entity, "capabilities", [])),
        current_activity: Map.get(entity, "current_activity"),
        availability: convert_availability(Map.get(entity, "availability")),
        resources_held: Map.get(entity, "resources_held", []),
        metadata: Map.get(entity, "metadata", %{})
      }
    end)
  end

  def convert_entities(_), do: []

  def convert_capabilities(capabilities) when is_list(capabilities) do
    Enum.map(capabilities, fn cap ->
      if is_binary(cap), do: String.to_atom(cap), else: cap
    end)
  end

  def convert_capabilities(_), do: []

  def convert_availability(nil), do: nil
  def convert_availability(availability) when is_map(availability), do: availability
  def convert_availability(_), do: nil

  def convert_simulation_result_to_map(%AriaEngine.Scheduler.SimulationResult{} = result) do
    try do
      %{
        status: result.status,
        reason: result.reason,
        schedule: result.schedule || [],
        analysis: result.analysis || %{},
        activity_log: safe_convert_activity_log(result.activity_log || []),
        resource_utilization: result.resource_utilization || %{},
        timeline: result.timeline || [],
        simulation_metadata: result.simulation_metadata || %{}
      }
    rescue
      e ->
        Logger.error("Error converting SimulationResult to map: #{Exception.message(e)}")
        %{
          status: "error",
          reason: "Conversion error: #{Exception.message(e)}",
          schedule: [],
          analysis: %{},
          activity_log: [],
          resource_utilization: %{},
          timeline: [],
          simulation_metadata: %{}
        }
    end
  end

  def safe_convert_activity_log(activity_log) when is_list(activity_log) do
    try do
      convert_activity_log(activity_log)
    rescue
      e ->
        Logger.warning("Error converting activity log: #{Exception.message(e)}")
        []
    end
  end

  def safe_convert_activity_log(_), do: []

  def convert_activity_log(activity_log) when is_list(activity_log) do
    Enum.map(activity_log, fn entry ->
      case entry do
        %AriaEngine.Scheduler.ActivityLogEntry{} = log_entry ->
          # Handle both timestamp and mission_duration formats
          time_info = case {log_entry.timestamp, log_entry.mission_duration} do
            {%DateTime{} = timestamp, _} ->
              %{timestamp: safe_datetime_to_iso8601(timestamp)}
            {nil, mission_duration} when is_binary(mission_duration) ->
              %{mission_duration: mission_duration}
            _ ->
              %{relative_minutes: log_entry.relative_minutes}
          end

          base_entry = %{
            activity_id: log_entry.activity_id,
            entity_id: log_entry.entity_id,
            event_type: log_entry.event_type,
            resource_snapshot: log_entry.resource_snapshot || %{},
            state_changes: log_entry.state_changes || [],
            metadata: log_entry.metadata || %{}
          }

          Map.merge(base_entry, time_info)
        _ ->
          entry
      end
    end)
  end

  def convert_activity_log(_), do: []

  # Safe DateTime to ISO8601 conversion with proper Erlang syntax
  def safe_datetime_to_iso8601(timestamp) do
    case timestamp do
      %DateTime{} = dt ->
        DateTime.to_iso8601(dt)

      {{year, month, day}, {hour, minute, second}} ->
        # Erlang datetime tuple format - convert to ISO8601 using NaiveDateTime
        case NaiveDateTime.from_erl({{year, month, day}, {hour, minute, second}}) do
          {:ok, naive_dt} -> NaiveDateTime.to_iso8601(naive_dt)
          {:error, _} -> "Invalid datetime tuple"
        end

      timestamp_str when is_binary(timestamp_str) ->
        timestamp_str

      timestamp_int when is_integer(timestamp_int) ->
        # Unix timestamp - convert to DateTime first
        case DateTime.from_unix(timestamp_int) do
          {:ok, dt} -> DateTime.to_iso8601(dt)
          {:error, _} -> "Invalid timestamp"
        end

      _ ->
        "Unknown timestamp format"
    end
  rescue
    _ -> "Error formatting timestamp"
  end

  def process_duration(duration) do
    case duration do
      duration_str when is_binary(duration_str) ->
        case AriaEngine.MCPTools.Validator.parse_iso8601_duration(duration_str) do
          {:ok, parsed_duration} ->
            convert_parsed_duration_to_minutes(parsed_duration)
          {:error, _} -> nil
        end
      duration_map when is_map(duration_map) ->
        with {:ok, start_time} <- parse_duration_datetime(duration_map, "start"),
             {:ok, end_time} <- parse_duration_datetime(duration_map, "end") do
          DateTime.diff(end_time, start_time, :minute)
        else
          _ -> nil
        end
      duration_int when is_integer(duration_int) ->
        # Keep integer durations as-is (test compatibility)
        duration_int
      _ ->
        nil
    end
  end

  def parse_duration_datetime(map, key) do
    case Map.get(map, key) do
      nil -> {:error, "Missing '#{key}' in duration object"}
      datetime_str when is_binary(datetime_str) ->
        case DateTime.from_iso8601(datetime_str) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, reason} -> {:error, "Invalid '#{key}' datetime format: #{reason}"}
        end
      _ -> {:error, "Invalid '#{key}' format: must be a string"}
    end
  end

  def convert_parsed_duration_to_minutes(%{hours: hours, minutes: minutes, seconds: seconds}) do
    # Convert to fractional minutes for better precision
    hours * 60 + minutes + (seconds / 60)
  end
end
