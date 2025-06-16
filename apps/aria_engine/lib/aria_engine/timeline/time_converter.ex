# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.TimeConverter do
  @moduledoc """
  Time conversion utilities for the Timeline system.

  Handles DateTime conversions with float precision for temporal reasoning.
  Supports both relative time (duration in seconds) and absolute time (DateTime).

  ## Design Principles

  - External API accepts seconds (float/integer) or DateTime
  - Internal storage uses DateTime with microsecond precision
  - Float resolution for precise temporal calculations
  - Robust edge case handling and validation

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.seconds_to_datetime(5.5)
      ~U[1970-01-01 00:00:05.500000Z]
      iex> AriaEngine.Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:05.500000Z])
      5.5
      iex> AriaEngine.Timeline.TimeConverter.add_seconds(~U[2025-01-01 10:00:00.000000Z], 1.5)
      ~U[2025-01-01 10:00:01.500000Z]

  ## References

  - ADR-006: Game Engine Real-time Execution (float precision)
  - ADR-079: Timeline Module Implementation Progress (DateTime with float)
  """

  @type seconds_input :: number()
  @type datetime_internal :: DateTime.t()

  @doc """
  Converts seconds to DateTime for internal storage.

  Uses Unix epoch as the base time for relative calculations.
  Supports microsecond precision for accurate temporal reasoning.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.seconds_to_datetime(5.5)
      ~U[1970-01-01 00:00:05.500000Z]
      iex> AriaEngine.Timeline.TimeConverter.seconds_to_datetime(0)
      ~U[1970-01-01 00:00:00.000000Z]
      iex> AriaEngine.Timeline.TimeConverter.seconds_to_datetime(1.123456)
      ~U[1970-01-01 00:00:01.123456Z]

  ## Edge Cases

      iex> AriaEngine.Timeline.TimeConverter.seconds_to_datetime(-1.5)
      ~U[1969-12-31 23:59:58.500000Z]

  """
  @spec seconds_to_datetime(seconds_input()) :: datetime_internal()
  def seconds_to_datetime(seconds) when is_number(seconds) do
    # Use Unix epoch as base and add seconds with microsecond precision
    microseconds = round(seconds * 1_000_000)
    DateTime.add(~U[1970-01-01 00:00:00.000000Z], microseconds, :microsecond)
  end

  def seconds_to_datetime(input) do
    raise ArgumentError, "Expected number, got: #{inspect(input)}"
  end

  @doc """
  Converts DateTime to seconds for external API.

  Returns float seconds relative to Unix epoch.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:05.500000Z])
      5.5
      iex> AriaEngine.Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:00.000000Z])
      0.0
      iex> AriaEngine.Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:01.123456Z])
      1.123456

  """
  @spec datetime_to_seconds(datetime_internal()) :: float()
  def datetime_to_seconds(%DateTime{} = dt) do
    # Get microseconds since Unix epoch and convert to float seconds
    microseconds = DateTime.diff(dt, ~U[1970-01-01 00:00:00.000000Z], :microsecond)
    microseconds / 1_000_000.0
  end

  def datetime_to_seconds(input) do
    raise ArgumentError, "Expected DateTime, got: #{inspect(input)}"
  end

  @doc """
  Adds seconds to a DateTime with float precision.

  ## Examples

      iex> base = ~U[2025-01-01 10:00:00.000000Z]
      iex> AriaEngine.Timeline.TimeConverter.add_seconds(base, 1.5)
      ~U[2025-01-01 10:00:01.500000Z]
      iex> AriaEngine.Timeline.TimeConverter.add_seconds(base, -0.5)
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

      iex> AriaEngine.Timeline.TimeConverter.validate_time_value(5.5)
      :ok
      iex> AriaEngine.Timeline.TimeConverter.validate_time_value(0.0)
      :ok

  """
  @spec validate_time_value(seconds_input()) :: :ok | {:error, String.t()}
  def validate_time_value(seconds) when is_number(seconds), do: :ok
  def validate_time_value(input) do
    {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc """
  Validates that start time is before end time.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.validate_time_order(0.0, 5.0)
      :ok
      iex> AriaEngine.Timeline.TimeConverter.validate_time_order(5.0, 3.0)
      {:error, "Start time (5.0) must be before end time (3.0)"}
      iex> AriaEngine.Timeline.TimeConverter.validate_time_order(5.0, 5.0)
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
    {:error, "Expected numbers, got: start=#{inspect(start_seconds)}, end=#{inspect(end_seconds)}"}
  end

  @doc """
  Calculates duration between two DateTimes in seconds.

  ## Examples

      iex> start_dt = ~U[2025-01-01 10:00:00.000000Z]
      iex> end_dt = ~U[2025-01-01 10:00:02.500000Z]
      iex> AriaEngine.Timeline.TimeConverter.duration_seconds(start_dt, end_dt)
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
  Validates and converts time input with comprehensive error handling.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.safe_seconds_to_datetime(5.5)
      {:ok, ~U[1970-01-01 00:00:05.500000Z]}
      iex> AriaEngine.Timeline.TimeConverter.safe_seconds_to_datetime("invalid")
      {:error, "Expected number, got: \"invalid\""}

  """
  @spec safe_seconds_to_datetime(any()) :: {:ok, datetime_internal()} | {:error, String.t()}
  def safe_seconds_to_datetime(input) do
    with :ok <- validate_time_value(input) do
      {:ok, seconds_to_datetime(input)}
    end
  rescue
    ArgumentError -> {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc """
  Validates and converts interval times with comprehensive error handling.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.safe_interval_to_datetime(0.0, 5.0)
      {:ok, {~U[1970-01-01 00:00:00.000000Z], ~U[1970-01-01 00:00:05.000000Z]}}
      iex> AriaEngine.Timeline.TimeConverter.safe_interval_to_datetime(5.0, 3.0)
      {:error, "Start time (5.0) must be before end time (3.0)"}

  """
  @spec safe_interval_to_datetime(any(), any()) :: {:ok, {datetime_internal(), datetime_internal()}} | {:error, String.t()}
  def safe_interval_to_datetime(start_input, end_input) do
    with :ok <- validate_time_value(start_input),
         :ok <- validate_time_value(end_input),
         :ok <- validate_time_order(start_input, end_input) do
      start_dt = seconds_to_datetime(start_input)
      end_dt = seconds_to_datetime(end_input)
      {:ok, {start_dt, end_dt}}
    end
  rescue
    ArgumentError -> {:error, "Expected numbers, got: start=#{inspect(start_input)}, end=#{inspect(end_input)}"}
  end

  @doc """
  Converts milliseconds to seconds.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.ms_to_seconds(1000)
      1.0
      iex> AriaEngine.Timeline.TimeConverter.ms_to_seconds(1500)
      1.5

  """
  @spec ms_to_seconds(number()) :: float()
  def ms_to_seconds(milliseconds) when is_number(milliseconds) do
    milliseconds / 1000.0
  end

  @doc """
  Converts seconds to milliseconds.

  ## Examples

      iex> AriaEngine.Timeline.TimeConverter.seconds_to_ms(1.0)
      1000
      iex> AriaEngine.Timeline.TimeConverter.seconds_to_ms(1.5)
      1500

  """
  @spec seconds_to_ms(number()) :: integer()
  def seconds_to_ms(seconds) when is_number(seconds) do
    round(seconds * 1000)
  end
end
