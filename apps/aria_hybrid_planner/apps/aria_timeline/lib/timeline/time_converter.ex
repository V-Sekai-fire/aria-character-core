# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.TimeConverter do
  @moduledoc "Time conversion utilities for the Timeline system.\n\nHandles DateTime conversions with float precision for temporal reasoning.\nSupports both relative time (duration in seconds) and absolute time (DateTime).\n\n## Design Principles\n\n- External API accepts seconds (float/integer) or DateTime\n- Internal storage uses DateTime with microsecond precision\n- Float resolution for precise temporal calculations\n- Robust edge case handling and validation\n\n## Examples\n\n    iex> Timeline.TimeConverter.seconds_to_datetime(5.5)\n    ~U[1970-01-01 00:00:05.500000Z]\n    iex> Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:05.500000Z])\n    5.5\n    iex> Timeline.TimeConverter.add_seconds(~U[2025-01-01 10:00:00.000000Z], 1.5)\n    ~U[2025-01-01 10:00:01.500000Z]\n\n## References\n\n- ADR-006: Game Engine Real-time Execution (float precision)\n- ADR-079: Timeline Module Implementation Progress (DateTime with float)\n"
  @type seconds_input :: number()
  @type datetime_internal :: DateTime.t()
  @doc "Converts seconds to DateTime for internal storage.\n\nUses Unix epoch as the base time for relative calculations.\nSupports microsecond precision for accurate temporal reasoning.\n\n## Examples\n\n    iex> Timeline.TimeConverter.seconds_to_datetime(5.5)\n    ~U[1970-01-01 00:00:05.500000Z]\n    iex> Timeline.TimeConverter.seconds_to_datetime(0)\n    ~U[1970-01-01 00:00:00.000000Z]\n    iex> Timeline.TimeConverter.seconds_to_datetime(1.123456)\n    ~U[1970-01-01 00:00:01.123456Z]\n\n## Edge Cases\n\n    iex> Timeline.TimeConverter.seconds_to_datetime(-1.5)\n    ~U[1969-12-31 23:59:58.500000Z]\n\n"
  @spec seconds_to_datetime(seconds_input()) :: datetime_internal()
  def seconds_to_datetime(seconds) when is_number(seconds) do
    microseconds = round(seconds * 1_000_000)
    DateTime.add(~U[1970-01-01 00:00:00.000000Z], microseconds, :microsecond)
  end

  def seconds_to_datetime(input) do
    raise ArgumentError, "Expected number, got: #{inspect(input)}"
  end

  @doc "Converts DateTime to seconds for external API.\n\nReturns float seconds relative to Unix epoch.\n\n## Examples\n\n    iex> Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:05.500000Z])\n    5.5\n    iex> Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:00.000000Z])\n    0.0\n    iex> Timeline.TimeConverter.datetime_to_seconds(~U[1970-01-01 00:00:01.123456Z])\n    1.123456\n\n"
  @spec datetime_to_seconds(datetime_internal()) :: float()
  def datetime_to_seconds(%DateTime{} = dt) do
    microseconds = DateTime.diff(dt, ~U[1970-01-01 00:00:00.000000Z], :microsecond)
    microseconds / 1_000_000.0
  end

  def datetime_to_seconds(input) do
    raise ArgumentError, "Expected DateTime, got: #{inspect(input)}"
  end

  @doc "Adds seconds to a DateTime with float precision.\n\n## Examples\n\n    iex> base = ~U[2025-01-01 10:00:00.000000Z]\n    iex> Timeline.TimeConverter.add_seconds(base, 1.5)\n    ~U[2025-01-01 10:00:01.500000Z]\n    iex> Timeline.TimeConverter.add_seconds(base, -0.5)\n    ~U[2025-01-01 09:59:59.500000Z]\n\n"
  @spec add_seconds(datetime_internal(), seconds_input()) :: datetime_internal()
  def add_seconds(%DateTime{} = dt, seconds) when is_number(seconds) do
    microseconds = round(seconds * 1_000_000)
    DateTime.add(dt, microseconds, :microsecond)
  end

  def add_seconds(dt, seconds) do
    raise ArgumentError, "Expected DateTime and number, got: #{inspect(dt)}, #{inspect(seconds)}"
  end

  @doc "Validates that a time value is valid for DateTime operations.\n\n## Examples\n\n    iex> Timeline.TimeConverter.validate_time_value(5.5)\n    :ok\n    iex> Timeline.TimeConverter.validate_time_value(0.0)\n    :ok\n\n"
  @spec validate_time_value(seconds_input()) :: :ok | {:error, String.t()}
  def validate_time_value(seconds) when is_number(seconds) do
    :ok
  end

  def validate_time_value(input) do
    {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc "Validates that start time is before end time.\n\n## Examples\n\n    iex> Timeline.TimeConverter.validate_time_order(0.0, 5.0)\n    :ok\n    iex> Timeline.TimeConverter.validate_time_order(5.0, 3.0)\n    {:error, \"Start time (5.0) must be before end time (3.0)\"}\n    iex> Timeline.TimeConverter.validate_time_order(5.0, 5.0)\n    {:error, \"Start time (5.0) must be before end time (5.0)\"}\n\n"
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

  @doc "Calculates duration between two DateTimes in seconds.\n\n## Examples\n\n    iex> start_dt = ~U[2025-01-01 10:00:00.000000Z]\n    iex> end_dt = ~U[2025-01-01 10:00:02.500000Z]\n    iex> Timeline.TimeConverter.duration_seconds(start_dt, end_dt)\n    2.5\n\n"
  @spec duration_seconds(datetime_internal(), datetime_internal()) :: float()
  def duration_seconds(%DateTime{} = start_dt, %DateTime{} = end_dt) do
    microseconds = DateTime.diff(end_dt, start_dt, :microsecond)
    microseconds / 1_000_000.0
  end

  def duration_seconds(start_dt, end_dt) do
    raise ArgumentError, "Expected DateTimes, got: #{inspect(start_dt)}, #{inspect(end_dt)}"
  end

  @doc "Validates and converts time input with comprehensive error handling.\n\n## Examples\n\n    iex> Timeline.TimeConverter.safe_seconds_to_datetime(5.5)\n    {:ok, ~U[1970-01-01 00:00:05.500000Z]}\n    iex> Timeline.TimeConverter.safe_seconds_to_datetime(\"invalid\")\n    {:error, \"Expected number, got: \"invalid\"\"}\n\n"
  @spec safe_seconds_to_datetime(any()) :: {:ok, datetime_internal()} | {:error, String.t()}
  def safe_seconds_to_datetime(input) do
    with :ok <- validate_time_value(input) do
      {:ok, seconds_to_datetime(input)}
    end
  rescue
    ArgumentError -> {:error, "Expected number, got: #{inspect(input)}"}
  end

  @doc "Validates and converts interval times with comprehensive error handling.\n\n## Examples\n\n    iex> Timeline.TimeConverter.safe_interval_to_datetime(0.0, 5.0)\n    {:ok, {~U[1970-01-01 00:00:00.000000Z], ~U[1970-01-01 00:00:05.000000Z]}}\n    iex> Timeline.TimeConverter.safe_interval_to_datetime(5.0, 3.0)\n    {:error, \"Start time (5.0) must be before end time (3.0)\"}\n\n"
  @spec safe_interval_to_datetime(any(), any()) ::
          {:ok, {datetime_internal(), datetime_internal()}} | {:error, String.t()}
  def safe_interval_to_datetime(start_input, end_input) do
    with :ok <- validate_time_value(start_input),
         :ok <- validate_time_value(end_input),
         :ok <- validate_time_order(start_input, end_input) do
      start_dt = seconds_to_datetime(start_input)
      end_dt = seconds_to_datetime(end_input)
      {:ok, {start_dt, end_dt}}
    end
  rescue
    ArgumentError ->
      {:error, "Expected numbers, got: start=#{inspect(start_input)}, end=#{inspect(end_input)}"}
  end

  @doc "Converts milliseconds to seconds.\n\n## Examples\n\n    iex> Timeline.TimeConverter.ms_to_seconds(1000)\n    1.0\n    iex> Timeline.TimeConverter.ms_to_seconds(1500)\n    1.5\n\n"
  @spec ms_to_seconds(number()) :: float()
  def ms_to_seconds(milliseconds) when is_number(milliseconds) do
    milliseconds / 1000.0
  end

  @doc "Converts seconds to milliseconds.\n\n## Examples\n\n    iex> Timeline.TimeConverter.seconds_to_ms(1.0)\n    1000\n    iex> Timeline.TimeConverter.seconds_to_ms(1.5)\n    1500\n\n"
  @spec seconds_to_ms(number()) :: integer()
  def seconds_to_ms(seconds) when is_number(seconds) do
    round(seconds * 1000)
  end
end
