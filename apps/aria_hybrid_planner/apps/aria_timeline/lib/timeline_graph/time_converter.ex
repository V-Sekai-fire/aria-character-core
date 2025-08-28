# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule TimelineGraph.TimeConverter do
  @moduledoc "Utility functions for converting between different time formats and units.\n\nThis module handles conversions between DateTime, STN time units, and various\ntime representations used throughout the timeline graph system.\n"
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @doc "Converts a time value in milliseconds to STN time units.\n\n## Examples\n\n```elixir\n# Convert current time to STN seconds\nnow_ms = DateTime.to_unix(DateTime.utc_now(), :millisecond)\nstn_seconds = TimeConverter.convert_to_stn_time(now_ms, :second)\n\n# Convert to STN hours\nstn_hours = TimeConverter.convert_to_stn_time(now_ms, :hour)\n```\n"
  @spec convert_to_stn_time(integer(), time_unit()) :: integer()
  def convert_to_stn_time(time_value_ms, target_unit) do
    case target_unit do
      :microsecond -> time_value_ms * 1000
      :millisecond -> time_value_ms
      :second -> div(time_value_ms, 1000)
      :minute -> div(time_value_ms, 60000)
      :hour -> div(time_value_ms, 3_600_000)
      :day -> div(time_value_ms, 86_400_000)
      _ -> time_value_ms
    end
  end

  @doc "Converts STN time units back to milliseconds, then to DateTime.\n\n## Examples\n\n```elixir\n# Convert STN seconds back to DateTime\ndatetime = TimeConverter.convert_from_stn_time(1640995200, :second)\n\n# Convert STN hours back to DateTime\ndatetime = TimeConverter.convert_from_stn_time(456387, :hour)\n```\n"
  @spec convert_from_stn_time(integer(), time_unit()) :: DateTime.t()
  def convert_from_stn_time(stn_time_value, source_unit) do
    ms_value =
      case source_unit do
        :microsecond -> div(stn_time_value, 1000)
        :millisecond -> stn_time_value
        :second -> stn_time_value * 1000
        :minute -> stn_time_value * 60000
        :hour -> stn_time_value * 3_600_000
        :day -> stn_time_value * 86_400_000
        _ -> stn_time_value
      end

    DateTime.from_unix!(ms_value, :millisecond)
  end

  @doc "Converts a duration in milliseconds to STN time units.\n\nThis is useful for converting time durations (like activity lengths)\nrather than absolute time points.\n\n## Examples\n\n```elixir\n# Convert 2 hours to STN minutes\ntwo_hours_ms = 2 * 60 * 60 * 1000\nduration_minutes = TimeConverter.convert_duration_to_stn_time(two_hours_ms, :minute)\n# => 120\n\n# Convert 30 minutes to STN seconds\nthirty_minutes_ms = 30 * 60 * 1000\nduration_seconds = TimeConverter.convert_duration_to_stn_time(thirty_minutes_ms, :second)\n# => 1800\n```\n"
  @spec convert_duration_to_stn_time(integer(), time_unit()) :: integer()
  def convert_duration_to_stn_time(duration_ms, target_unit) do
    convert_to_stn_time(duration_ms, target_unit)
  end

  @doc "Converts a DateTime to STN time units.\n\n## Examples\n\n```elixir\nnow = DateTime.utc_now()\nstn_seconds = TimeConverter.datetime_to_stn_time(now, :second)\nstn_hours = TimeConverter.datetime_to_stn_time(now, :hour)\n```\n"
  @spec datetime_to_stn_time(DateTime.t(), time_unit()) :: integer()
  def datetime_to_stn_time(datetime, target_unit) do
    ms_value = DateTime.to_unix(datetime, :millisecond)
    convert_to_stn_time(ms_value, target_unit)
  end

  @doc "Converts hours to STN time units.\n\nConvenience function for common duration conversions.\n\n## Examples\n\n```elixir\n# Convert 8 hours to STN seconds\nwork_shift_seconds = TimeConverter.hours_to_stn_time(8, :second)\n# => 28800\n\n# Convert 0.5 hours to STN minutes\nhalf_hour_minutes = TimeConverter.hours_to_stn_time(0.5, :minute)\n# => 30\n```\n"
  @spec hours_to_stn_time(number(), time_unit()) :: integer()
  def hours_to_stn_time(hours, target_unit) do
    duration_ms = round(hours * 3600 * 1000)
    convert_duration_to_stn_time(duration_ms, target_unit)
  end

  @doc "Converts minutes to STN time units.\n\nConvenience function for common duration conversions.\n\n## Examples\n\n```elixir\n# Convert 15 minutes to STN seconds\nbreak_seconds = TimeConverter.minutes_to_stn_time(15, :second)\n# => 900\n\n# Convert 90 minutes to STN hours\nmovie_hours = TimeConverter.minutes_to_stn_time(90, :hour)\n# => 1 (rounded down)\n```\n"
  @spec minutes_to_stn_time(number(), time_unit()) :: integer()
  def minutes_to_stn_time(minutes, target_unit) do
    duration_ms = round(minutes * 60 * 1000)
    convert_duration_to_stn_time(duration_ms, target_unit)
  end

  @doc "Gets the current time in STN units.\n\n## Examples\n\n```elixir\ncurrent_stn_seconds = TimeConverter.now_stn_time(:second)\ncurrent_stn_hours = TimeConverter.now_stn_time(:hour)\n```\n"
  @spec now_stn_time(time_unit()) :: integer()
  def now_stn_time(target_unit) do
    datetime_to_stn_time(DateTime.utc_now(), target_unit)
  end

  @doc "Calculates the difference between two DateTime values in STN time units.\n\n## Examples\n\n```elixir\nstart_time = ~U[2025-06-17 08:00:00Z]\nend_time = ~U[2025-06-17 16:00:00Z]\n\n# Get difference in STN hours\nwork_hours = TimeConverter.datetime_diff_stn(end_time, start_time, :hour)\n# => 8\n\n# Get difference in STN minutes\nwork_minutes = TimeConverter.datetime_diff_stn(end_time, start_time, :minute)\n# => 480\n```\n"
  @spec datetime_diff_stn(DateTime.t(), DateTime.t(), time_unit()) :: integer()
  def datetime_diff_stn(datetime1, datetime2, target_unit) do
    diff_ms = DateTime.diff(datetime1, datetime2, :millisecond)
    convert_duration_to_stn_time(abs(diff_ms), target_unit)
  end

  @doc "Adds a duration in STN time units to a DateTime.\n\n## Examples\n\n```elixir\nstart_time = ~U[2025-06-17 08:00:00Z]\n\n# Add 8 STN hours\nend_time = TimeConverter.add_stn_duration(start_time, 8, :hour)\n\n# Add 30 STN minutes\nbreak_end = TimeConverter.add_stn_duration(start_time, 30, :minute)\n```\n"
  @spec add_stn_duration(DateTime.t(), integer(), time_unit()) :: DateTime.t()
  def add_stn_duration(datetime, duration, source_unit) do
    duration_ms =
      case source_unit do
        :microsecond -> div(duration, 1000)
        :millisecond -> duration
        :second -> duration * 1000
        :minute -> duration * 60000
        :hour -> duration * 3_600_000
        :day -> duration * 86_400_000
        _ -> duration
      end

    DateTime.add(datetime, duration_ms, :millisecond)
  end

  @doc "Subtracts a duration in STN time units from a DateTime.\n\n## Examples\n\n```elixir\nend_time = ~U[2025-06-17 16:00:00Z]\n\n# Subtract 8 STN hours to get start time\nstart_time = TimeConverter.subtract_stn_duration(end_time, 8, :hour)\n\n# Subtract 15 STN minutes\nearlier_time = TimeConverter.subtract_stn_duration(end_time, 15, :minute)\n```\n"
  @spec subtract_stn_duration(DateTime.t(), integer(), time_unit()) :: DateTime.t()
  def subtract_stn_duration(datetime, duration, source_unit) do
    duration_ms =
      case source_unit do
        :microsecond -> div(duration, 1000)
        :millisecond -> duration
        :second -> duration * 1000
        :minute -> duration * 60000
        :hour -> duration * 3_600_000
        :day -> duration * 86_400_000
        _ -> duration
      end

    DateTime.add(datetime, -duration_ms, :millisecond)
  end
end
