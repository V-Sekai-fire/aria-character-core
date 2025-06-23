# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DurationParser do
  @moduledoc """
  Centralized duration parsing utilities using Timex.

  Provides consistent duration parsing across the scheduler system,
  using Timex's native Duration format for better precision and
  microsecond support.
  """

  @doc """
  Parse an ISO8601 duration string using Timex.

  Returns a Timex.Duration struct with native microsecond precision.

  ## Examples

      iex> AriaEngine.Scheduler.DurationParser.parse_duration("PT1H30M")
      {:ok, %Timex.Duration{megaseconds: 0, seconds: 5400, microseconds: 0}}

      iex> AriaEngine.Scheduler.DurationParser.parse_duration("invalid")
      {:error, "Invalid duration format"}
  """
  @spec parse_duration(binary()) :: {:ok, Timex.Duration.t()} | {:error, binary()}
  def parse_duration(duration_str) when is_binary(duration_str) do
    case Timex.Duration.parse(duration_str) do
      {:ok, duration} ->
        {:ok, duration}

      {:error, reason} ->
        {:error, "Invalid duration format: #{inspect(reason)}"}
    end
  end

  def parse_duration(_), do: {:error, "Duration must be a string"}

  @doc """
  Parse duration and return as a list of tuples (for backward compatibility).

  This converts a Timex.Duration to a list format for legacy code compatibility.
  """
  @spec parse_duration_as_list(binary()) :: list() | :error
  def parse_duration_as_list(duration_str) when is_binary(duration_str) do
    case parse_duration(duration_str) do
      {:ok, duration} ->
        # Convert Timex.Duration to list of tuples using Timex's conversion functions
        # Only include non-zero components
        components = [
          {:years, extract_years(duration)},
          {:months, extract_months(duration)},
          {:days, Timex.Duration.to_days(duration, truncate: true)},
          {:hours, extract_hours_remainder(duration)},
          {:minutes, extract_minutes_remainder(duration)},
          {:seconds, extract_seconds_remainder(duration)}
        ]

        Enum.filter(components, fn {_key, value} -> value > 0 end)

      {:error, _reason} ->
        :error
    end
  end

  def parse_duration_as_list(_), do: :error

  # Private helper functions to extract duration components using Timex functions
  # These provide integer values with proper rounding

  defp extract_years(duration) do
    # Approximate years calculation (365.25 days per year)
    total_days = Timex.Duration.to_days(duration)
    round(total_days / 365.25)
  end

  defp extract_months(duration) do
    # Approximate months calculation after removing years
    total_days = Timex.Duration.to_days(duration)
    years = round(total_days / 365.25)
    remaining_days = total_days - (years * 365.25)
    round(remaining_days / 30.44)
  end

  defp extract_hours_remainder(duration) do
    # Hours within the current day (0-23)
    total_hours = Timex.Duration.to_hours(duration)
    days = Timex.Duration.to_days(duration, truncate: true)
    round(total_hours - (days * 24))
  end

  defp extract_minutes_remainder(duration) do
    # Minutes within the current hour (0-59)
    total_minutes = Timex.Duration.to_minutes(duration)
    hours = Timex.Duration.to_hours(duration, truncate: true)
    round(total_minutes - (hours * 60))
  end

  defp extract_seconds_remainder(duration) do
    # Seconds within the current minute (0-59)
    total_seconds = Timex.Duration.to_seconds(duration)
    minutes = Timex.Duration.to_minutes(duration, truncate: true)
    round(total_seconds - (minutes * 60))
  end
end
