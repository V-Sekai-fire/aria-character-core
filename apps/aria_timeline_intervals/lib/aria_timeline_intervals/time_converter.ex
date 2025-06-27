# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimelineIntervals.TimeConverter do
  @moduledoc """
  Time conversion utilities for the AriaTimelineIntervals system.

  Handles time conversions between different units and formats with precision
  for temporal reasoning. Supports both relative time (duration in seconds) 
  and absolute time (DateTime).

  ## Design Principles

  - External API accepts seconds (float/integer) or DateTime
  - Internal storage uses DateTime with microsecond precision
  - Float resolution for precise temporal calculations
  - Robust edge case handling and validation

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.seconds_to_milliseconds(5.5)
      5500
      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_seconds(5500)
      5.5
      iex> AriaTimelineIntervals.TimeConverter.datetime_to_milliseconds(~U[1970-01-01 00:00:05.500000Z])
      5500

  ## References

  - ADR-006: Game Engine Real-time Execution (float precision)
  - ADR-079: Timeline Module Implementation Progress (DateTime with float)
  """

  @type seconds_input :: number()
  @type milliseconds_output :: integer()
  @type datetime_internal :: DateTime.t()

  @doc """
  Converts seconds to milliseconds.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.seconds_to_milliseconds(1.0)
      1000
      iex> AriaTimelineIntervals.TimeConverter.seconds_to_milliseconds(1.5)
      1500
      iex> AriaTimelineIntervals.TimeConverter.seconds_to_milliseconds(0.001)
      1

  """
  @spec seconds_to_milliseconds(seconds_input()) :: milliseconds_output()
  def seconds_to_milliseconds(seconds) when is_number(seconds) do
    round(seconds * 1000)
  end

  def seconds_to_milliseconds(input) do
    raise ArgumentError, "Expected number, got: #{inspect(input)}"
  end

  @doc """
  Converts milliseconds to seconds.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_seconds(1000)
      1.0
      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_seconds(1500)
      1.5
      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_seconds(1)
      0.001

  """
  @spec milliseconds_to_seconds(milliseconds_output()) :: float()
  def milliseconds_to_seconds(milliseconds) when is_number(milliseconds) do
    milliseconds / 1000.0
  end

  def milliseconds_to_seconds(input) do
    raise ArgumentError, "Expected number, got: #{inspect(input)}"
  end

  @doc """
  Converts DateTime to milliseconds since Unix epoch.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.datetime_to_milliseconds(~U[1970-01-01 00:00:05.500000Z])
      5500
      iex> AriaTimelineIntervals.TimeConverter.datetime_to_milliseconds(~U[1970-01-01 00:00:00.000000Z])
      0
      iex> AriaTimelineIntervals.TimeConverter.datetime_to_milliseconds(~U[1970-01-01 00:00:01.123000Z])
      1123

  """
  @spec datetime_to_milliseconds(datetime_internal()) :: milliseconds_output()
  def datetime_to_milliseconds(%DateTime{} = dt) do
    DateTime.diff(dt, ~U[1970-01-01 00:00:00.000000Z], :millisecond)
  end

  def datetime_to_milliseconds(input) do
    raise ArgumentError, "Expected DateTime, got: #{inspect(input)}"
  end

  @doc """
  Converts milliseconds since Unix epoch to DateTime.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_datetime(5500)
      ~U[1970-01-01 00:00:05.500000Z]
      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_datetime(0)
      ~U[1970-01-01 00:00:00.000000Z]
      iex> AriaTimelineIntervals.TimeConverter.milliseconds_to_datetime(1123)
      ~U[1970-01-01 00:00:01.123000Z]

  """
  @spec milliseconds_to_datetime(milliseconds_output()) :: datetime_internal()
  def milliseconds_to_datetime(milliseconds) when is_number(milliseconds) do
    DateTime.add(~U[1970-01-01 00:00:00.000000Z], round(milliseconds), :millisecond)
  end

  def milliseconds_to_datetime(input) do
    raise ArgumentError, "Expected number, got: #{inspect(input)}"
  end

  @doc """
  Adds seconds to a DateTime with float precision.

  ## Examples

      iex> base = ~U[2025-01-01 10:00:00.000000Z]
      iex> AriaTimelineIntervals.TimeConverter.add_seconds(base, 1.5)
      ~U[2025-01-01 10:00:01.500000Z]
      iex> AriaTimelineIntervals.TimeConverter.add_seconds(base, -0.5)
      ~U[2025-01-01 09:59:59.500000Z]

  """
  @spec add_seconds(datetime_internal(), seconds_input()) :: datetime_internal()
  def add_seconds(%DateTime{} = dt, seconds) when is_number(seconds) do
    microseconds = round(seconds * 1_000_000)
    DateTime.add(dt, microseconds, :microsecond)
  end

  def add_seconds(dt, seconds) do
    raise ArgumentError, "Expected DateTime and number, got: #{inspect(dt)}, #{inspect(seconds)}"
  end

  @doc """
  Validates that a time value is valid for DateTime operations.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.validate_time_value(5.5)
      :ok
      iex> AriaTimelineIntervals.TimeConverter.validate_time_value(0.0)
      :ok

  """
  @spec validate_time_value(seconds_input()) :: :ok | {:error, String.t()}
  def validate_time_value(seconds) when is_number(seconds) do
    :ok
  end

  def validate_time_value(input) do
    {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc """
  Validates that start time is before end time.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.validate_time_order(0.0, 5.0)
      :ok
      iex> AriaTimelineIntervals.TimeConverter.validate_time_order(5.0, 3.0)
      {:error, "Start time (5.0) must be before end time (3.0)"}
      iex> AriaTimelineIntervals.TimeConverter.validate_time_order(5.0, 5.0)
      {:error, "Start time (5.0) must be before end time (5.0)"}

  """
  @spec validate_time_order(seconds_input(), seconds_input()) :: :ok | {:error, String.t()}
  def validate_time_order(start_seconds, end_seconds)
      when is_number(start_seconds) and is_number(end_seconds) do
    if start_seconds < end_seconds do
      :ok
    else
      {:error, "Start time (#{start_seconds}) must be before end time (#{end_seconds})"}
    end
  end

  def validate_time_order(start_seconds, end_seconds) do
    {:error,
     "Expected numbers, got: start=#{inspect(start_seconds)}, end=#{inspect(end_seconds)}"}
  end

  @doc """
  Calculates duration between two DateTimes in seconds.

  ## Examples

      iex> start_dt = ~U[2025-01-01 10:00:00.000000Z]
      iex> end_dt = ~U[2025-01-01 10:00:02.500000Z]
      iex> AriaTimelineIntervals.TimeConverter.duration_seconds(start_dt, end_dt)
      2.5

  """
  @spec duration_seconds(datetime_internal(), datetime_internal()) :: float()
  def duration_seconds(%DateTime{} = start_dt, %DateTime{} = end_dt) do
    microseconds = DateTime.diff(end_dt, start_dt, :microsecond)
    microseconds / 1_000_000.0
  end

  def duration_seconds(start_dt, end_dt) do
    raise ArgumentError, "Expected DateTimes, got: #{inspect(start_dt)}, #{inspect(end_dt)}"
  end

  @doc """
  Calculates duration between two DateTimes in milliseconds.

  ## Examples

      iex> start_dt = ~U[2025-01-01 10:00:00.000000Z]
      iex> end_dt = ~U[2025-01-01 10:00:02.500000Z]
      iex> AriaTimelineIntervals.TimeConverter.duration_milliseconds(start_dt, end_dt)
      2500

  """
  @spec duration_milliseconds(datetime_internal(), datetime_internal()) :: milliseconds_output()
  def duration_milliseconds(%DateTime{} = start_dt, %DateTime{} = end_dt) do
    DateTime.diff(end_dt, start_dt, :millisecond)
  end

  def duration_milliseconds(start_dt, end_dt) do
    raise ArgumentError, "Expected DateTimes, got: #{inspect(start_dt)}, #{inspect(end_dt)}"
  end

  @doc """
  Validates and converts time input with comprehensive error handling.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.safe_seconds_to_milliseconds(5.5)
      {:ok, 5500}
      iex> AriaTimelineIntervals.TimeConverter.safe_seconds_to_milliseconds("invalid")
      {:error, "Expected number, got: \\\"invalid\\\""}

  """
  @spec safe_seconds_to_milliseconds(any()) :: {:ok, milliseconds_output()} | {:error, String.t()}
  def safe_seconds_to_milliseconds(input) do
    with :ok <- validate_time_value(input) do
      {:ok, seconds_to_milliseconds(input)}
    end
  rescue
    ArgumentError -> {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc """
  Validates and converts interval times with comprehensive error handling.

  ## Examples

      iex> AriaTimelineIntervals.TimeConverter.safe_interval_to_milliseconds(0.0, 5.0)
      {:ok, {0, 5000}}
      iex> AriaTimelineIntervals.TimeConverter.safe_interval_to_milliseconds(5.0, 3.0)
      {:error, "Start time (5.0) must be before end time (3.0)"}

  """
  @spec safe_interval_to_milliseconds(any(), any()) ::
          {:ok, {milliseconds_output(), milliseconds_output()}} | {:error, String.t()}
  def safe_interval_to_milliseconds(start_input, end_input) do
    with :ok <- validate_time_value(start_input),
         :ok <- validate_time_value(end_input),
         :ok <- validate_time_order(start_input, end_input) do
      start_ms = seconds_to_milliseconds(start_input)
      end_ms = seconds_to_milliseconds(end_input)
      {:ok, {start_ms, end_ms}}
    end
  rescue
    ArgumentError ->
      {:error, "Expected numbers, got: start=#{inspect(start_input)}, end=#{inspect(end_input)}"}
  end
end
