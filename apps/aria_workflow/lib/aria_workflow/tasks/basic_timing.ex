# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.Tasks.BasicTiming do
  @moduledoc """
  Basic timing tasks for SOP execution.

  Provides simple timing operations without external service dependencies.
  Focuses on UTC/local time capture and basic command execution timing.
  """

  require Logger

  @doc """
  Gets current time in both UTC and local timezone.
  """
  def get_current_time(state, args \\ %{}) do
    utc_now = DateTime.utc_now()

    # Get local timezone info directly
    {:ok, state_with_tz} = get_timezone_info(state, args)
    timezone_info = state_with_tz.timezone_info

    time_info = %{
      utc: utc_now,
      local: format_local_time(utc_now, timezone_info),
      timezone: timezone_info.name,
      offset_seconds: timezone_info.offset_seconds,
      timestamp_ms: System.os_time(:millisecond)
    }

    Logger.info("Current time captured: UTC=#{DateTime.to_iso8601(utc_now)}, Local=#{time_info.local}")

    # Update state with timing info
    new_state = Map.put(state_with_tz, :current_time_info, time_info)
    {:ok, new_state}
  end

  @doc """
  Gets timezone information for the current system.
  """
  def get_timezone_info(state \\ %{}, _args \\ %{}) do
    timezone_info = %{
      name: get_system_timezone(),
      offset_seconds: get_timezone_offset(),
      abbreviation: get_timezone_abbreviation()
    }

    Logger.debug("Timezone info: #{inspect(timezone_info)}")

    case state do
      %{} = state_map ->
        new_state = Map.put(state_map, :timezone_info, timezone_info)
        {:ok, new_state}
      _ ->
        timezone_info
    end
  end

  @doc """
  Starts a timer for command execution tracking.
  """
  def start_timer(state, args \\ %{}) do
    timer_id = Map.get(args, :timer_id, "default")
    start_time = System.os_time(:millisecond)

    timer_info = %{
      timer_id: timer_id,
      id: timer_id,
      start_time: start_time,
      start_datetime: DateTime.utc_now(),
      command: Map.get(args, :command, "unknown")
    }

    Logger.info("Timer started: #{timer_id} at #{DateTime.to_iso8601(timer_info.start_datetime)}")

    # Store timer in state
    active_timers = Map.get(state, :active_timers, %{})
    new_active_timers = Map.put(active_timers, timer_id, timer_info)
    new_state = Map.put(state, :active_timers, new_active_timers)

    {:ok, new_state}
  end

  @doc """
  Stops a timer and calculates duration.
  """
  def stop_timer(state, args \\ %{}) do
    timer_id = Map.get(args, :timer_id, "default")
    end_time = System.os_time(:millisecond)
    end_datetime = DateTime.utc_now()

    active_timers = Map.get(state, :active_timers, %{})

    case Map.get(active_timers, timer_id) do
      nil ->
        Logger.warning("Timer not found: #{timer_id}")
        {:error, :timer_not_found}

      timer_info ->
        duration_ms = end_time - timer_info.start_time
        duration_seconds = duration_ms / 1000.0

        completed_timer = Map.merge(timer_info, %{
          end_time: end_time,
          end_datetime: end_datetime,
          duration_ms: duration_ms,
          duration_seconds: duration_seconds,
          status: Map.get(args, :status, :completed)
        })

        Logger.info("Timer stopped: #{timer_id}, duration: #{duration_seconds}s")

        # Move timer to completed timers
        completed_timers = Map.get(state, :completed_timers, %{})
        new_completed = Map.put(completed_timers, timer_id, completed_timer)
        new_active_timers = Map.delete(active_timers, timer_id)

        new_state = state
        |> Map.put(:active_timers, new_active_timers)
        |> Map.put(:completed_timers, new_completed)

        {:ok, new_state, completed_timer}
    end
  end

  @doc """
  Logs execution information.
  """
  def log_execution(state, args \\ %{}) do
    log_entry = %{
      timestamp: DateTime.utc_now(),
      operation: Map.get(args, :operation, "unknown"),
      status: Map.get(args, :status, :info),
      duration_seconds: Map.get(args, :duration_seconds),
      details: Map.get(args, :details, %{})
    }

    # Format log message
    status_str = String.upcase(to_string(log_entry.status))
    duration_str = case log_entry.duration_seconds do
      nil -> ""
      dur when is_number(dur) -> " (#{dur}s)"
      _ -> ""
    end

    message = "[#{DateTime.to_iso8601(log_entry.timestamp)}] #{status_str}: #{log_entry.operation}#{duration_str}"

    # Log based on status
    case log_entry.status do
      :error -> Logger.error(message)
      :warning -> Logger.warning(message)
      :info -> Logger.info(message)
      _ -> Logger.debug(message)
    end

    # Store in execution log
    execution_log = Map.get(state, :execution_log, [])
    new_log = [log_entry | execution_log]
    new_state = Map.put(state, :execution_log, new_log)

    {:ok, new_state}
  end

  # Private helper functions

  defp get_system_timezone do
    case System.cmd("date", ["+%Z"], stderr_to_stdout: true) do
      {timezone, 0} -> String.trim(timezone)
      _ -> "UTC"
    end
  rescue
    _ -> "UTC"
  end

  defp get_timezone_offset do
    case System.cmd("date", ["+%z"], stderr_to_stdout: true) do
      {offset_str, 0} ->
        offset_str = String.trim(offset_str)
        case Regex.run(~r/([+-])(\d{2})(\d{2})/, offset_str) do
          [_, sign, hours, minutes] ->
            hours_int = String.to_integer(hours)
            minutes_int = String.to_integer(minutes)
            offset = hours_int * 3600 + minutes_int * 60
            if sign == "-", do: -offset, else: offset
          _ -> 0
        end
      _ -> 0
    end
  rescue
    _ -> 0
  end

  defp get_timezone_abbreviation do
    case System.cmd("date", ["+%Z"], stderr_to_stdout: true) do
      {abbr, 0} -> String.trim(abbr)
      _ -> "UTC"
    end
  rescue
    _ -> "UTC"
  end

  defp format_local_time(utc_datetime, timezone_info) do
    # Simple offset calculation
    offset_seconds = timezone_info.offset_seconds
    local_datetime = DateTime.add(utc_datetime, offset_seconds, :second)

    # Format as "YYYY-MM-DD HH:MM:SS TZ"
    "#{DateTime.to_iso8601(local_datetime, :basic)} #{timezone_info.abbreviation}"
  end
end
