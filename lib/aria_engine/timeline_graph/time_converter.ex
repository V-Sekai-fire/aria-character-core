# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph.TimeConverter do
  @moduledoc """
  Utility functions for converting between different time formats and units.

  This module handles conversions between DateTime, STN time units, and various
  time representations used throughout the timeline graph system.
  """

  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day

  @doc """
  Converts a time value in milliseconds to STN time units.

  ## Examples

  ```elixir
  # Convert current time to STN seconds
  now_ms = DateTime.to_unix(DateTime.utc_now(), :millisecond)
  stn_seconds = TimeConverter.convert_to_stn_time(now_ms, :second)

  # Convert to STN hours
  stn_hours = TimeConverter.convert_to_stn_time(now_ms, :hour)
  ```
  """
  @spec convert_to_stn_time(integer(), time_unit()) :: integer()
  def convert_to_stn_time(time_value_ms, target_unit) do
    case target_unit do
      :microsecond -> time_value_ms * 1000
      :millisecond -> time_value_ms
      :second -> div(time_value_ms, 1000)
      :minute -> div(time_value_ms, 60_000)
      :hour -> div(time_value_ms, 3_600_000)
      :day -> div(time_value_ms, 86_400_000)
      # Default to milliseconds
      _ -> time_value_ms
    end
  end

  @doc """
  Converts STN time units back to milliseconds, then to DateTime.

  ## Examples

  ```elixir
  # Convert STN seconds back to DateTime
  datetime = TimeConverter.convert_from_stn_time(1640995200, :second)

  # Convert STN hours back to DateTime
  datetime = TimeConverter.convert_from_stn_time(456387, :hour)
  ```
  """
  @spec convert_from_stn_time(integer(), time_unit()) :: DateTime.t()
  def convert_from_stn_time(stn_time_value, source_unit) do
    # Convert STN time units back to milliseconds, then to DateTime
    ms_value =
      case source_unit do
        :microsecond -> div(stn_time_value, 1000)
        :millisecond -> stn_time_value
        :second -> stn_time_value * 1000
        :minute -> stn_time_value * 60_000
        :hour -> stn_time_value * 3_600_000
        :day -> stn_time_value * 86_400_000
        # Default treat as milliseconds
        _ -> stn_time_value
      end

    DateTime.from_unix!(ms_value, :millisecond)
  end

  @doc """
  Converts a duration in milliseconds to STN time units.

  This is useful for converting time durations (like activity lengths)
  rather than absolute time points.

  ## Examples

  ```elixir
  # Convert 2 hours to STN minutes
  two_hours_ms = 2 * 60 * 60 * 1000
  duration_minutes = TimeConverter.convert_duration_to_stn_time(two_hours_ms, :minute)
  # => 120

  # Convert 30 minutes to STN seconds
  thirty_minutes_ms = 30 * 60 * 1000
  duration_seconds = TimeConverter.convert_duration_to_stn_time(thirty_minutes_ms, :second)
  # => 1800
  ```
  """
  @spec convert_duration_to_stn_time(integer(), time_unit()) :: integer()
  def convert_duration_to_stn_time(duration_ms, target_unit) do
    convert_to_stn_time(duration_ms, target_unit)
  end

  @doc """
  Converts a DateTime to STN time units.

  ## Examples

  ```elixir
  now = DateTime.utc_now()
  stn_seconds = TimeConverter.datetime_to_stn_time(now, :second)
  stn_hours = TimeConverter.datetime_to_stn_time(now, :hour)
  ```
  """
  @spec datetime_to_stn_time(DateTime.t(), time_unit()) :: integer()
  def datetime_to_stn_time(datetime, target_unit) do
    ms_value = DateTime.to_unix(datetime, :millisecond)
    convert_to_stn_time(ms_value, target_unit)
  end

  @doc """
  Converts hours to STN time units.

  Convenience function for common duration conversions.

  ## Examples

  ```elixir
  # Convert 8 hours to STN seconds
  work_shift_seconds = TimeConverter.hours_to_stn_time(8, :second)
  # => 28800

  # Convert 0.5 hours to STN minutes
  half_hour_minutes = TimeConverter.hours_to_stn_time(0.5, :minute)
  # => 30
  ```
  """
  @spec hours_to_stn_time(number(), time_unit()) :: integer()
  def hours_to_stn_time(hours, target_unit) do
    duration_ms = round(hours * 3600 * 1000)
    convert_duration_to_stn_time(duration_ms, target_unit)
  end

  @doc """
  Converts minutes to STN time units.

  Convenience function for common duration conversions.

  ## Examples

  ```elixir
  # Convert 15 minutes to STN seconds
  break_seconds = TimeConverter.minutes_to_stn_time(15, :second)
  # => 900

  # Convert 90 minutes to STN hours
  movie_hours = TimeConverter.minutes_to_stn_time(90, :hour)
  # => 1 (rounded down)
  ```
  """
  @spec minutes_to_stn_time(number(), time_unit()) :: integer()
  def minutes_to_stn_time(minutes, target_unit) do
    duration_ms = round(minutes * 60 * 1000)
    convert_duration_to_stn_time(duration_ms, target_unit)
  end

  @doc """
  Gets the current time in STN units.

  ## Examples

  ```elixir
  current_stn_seconds = TimeConverter.now_stn_time(:second)
  current_stn_hours = TimeConverter.now_stn_time(:hour)
  ```
  """
  @spec now_stn_time(time_unit()) :: integer()
  def now_stn_time(target_unit) do
    datetime_to_stn_time(DateTime.utc_now(), target_unit)
  end

  @doc """
  Calculates the difference between two DateTime values in STN time units.

  ## Examples

  ```elixir
  start_time = ~U[2025-06-17 08:00:00Z]
  end_time = ~U[2025-06-17 16:00:00Z]

  # Get difference in STN hours
  work_hours = TimeConverter.datetime_diff_stn(end_time, start_time, :hour)
  # => 8

  # Get difference in STN minutes
  work_minutes = TimeConverter.datetime_diff_stn(end_time, start_time, :minute)
  # => 480
  ```
  """
  @spec datetime_diff_stn(DateTime.t(), DateTime.t(), time_unit()) :: integer()
  def datetime_diff_stn(datetime1, datetime2, target_unit) do
    diff_ms = DateTime.diff(datetime1, datetime2, :millisecond)
    convert_duration_to_stn_time(abs(diff_ms), target_unit)
  end

  @doc """
  Adds a duration in STN time units to a DateTime.

  ## Examples

  ```elixir
  start_time = ~U[2025-06-17 08:00:00Z]

  # Add 8 STN hours
  end_time = TimeConverter.add_stn_duration(start_time, 8, :hour)

  # Add 30 STN minutes
  break_end = TimeConverter.add_stn_duration(start_time, 30, :minute)
  ```
  """
  @spec add_stn_duration(DateTime.t(), integer(), time_unit()) :: DateTime.t()
  def add_stn_duration(datetime, duration, source_unit) do
    # Convert STN duration to milliseconds
    duration_ms =
      case source_unit do
        :microsecond -> div(duration, 1000)
        :millisecond -> duration
        :second -> duration * 1000
        :minute -> duration * 60_000
        :hour -> duration * 3_600_000
        :day -> duration * 86_400_000
        _ -> duration
      end

    DateTime.add(datetime, duration_ms, :millisecond)
  end

  @doc """
  Subtracts a duration in STN time units from a DateTime.

  ## Examples

  ```elixir
  end_time = ~U[2025-06-17 16:00:00Z]

  # Subtract 8 STN hours to get start time
  start_time = TimeConverter.subtract_stn_duration(end_time, 8, :hour)

  # Subtract 15 STN minutes
  earlier_time = TimeConverter.subtract_stn_duration(end_time, 15, :minute)
  ```
  """
  @spec subtract_stn_duration(DateTime.t(), integer(), time_unit()) :: DateTime.t()
  def subtract_stn_duration(datetime, duration, source_unit) do
    # Convert STN duration to milliseconds and subtract
    duration_ms =
      case source_unit do
        :microsecond -> div(duration, 1000)
        :millisecond -> duration
        :second -> duration * 1000
        :minute -> duration * 60_000
        :hour -> duration * 3_600_000
        :day -> duration * 86_400_000
        _ -> duration
      end

    DateTime.add(datetime, -duration_ms, :millisecond)
  end
end
