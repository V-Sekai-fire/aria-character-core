# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Utils do
  @moduledoc "Utility functions for AriaEngine.\n\nThis module provides common utility functions used across the AriaEngine\nsystem, including duration handling, string formatting, and data conversion.\n"

  require Timex
  alias Timex.Duration

  @doc "Normalizes a duration to ISO8601 duration string format.\n\nAccepts various duration formats:\n- Maps with time units (hours, minutes, seconds)\n- Maps with ISO8601 datetime strings (start/end)\n- Tuples like {:fixed, seconds}, {:range, min, max}, {:open_ended, map}\n- Numbers (interpreted as seconds)\n- ISO8601 duration strings\n\n## Examples\n\n    iex> AriaEngine.Utils.normalize_duration(%{hours: 1, minutes: 30})\n    \"PT1H30M\"\n    \n    iex> AriaEngine.Utils.normalize_duration(%{\"start\" => \"2025-06-20T09:00:00Z\", \"end\" => \"2025-06-20T10:00:00Z\"})\n    \"PT1H\"\n    \n    iex> AriaEngine.Utils.normalize_duration({:fixed, 3600})\n    \"PT1H\"\n"
  @spec normalize_duration(map() | tuple() | number() | String.t()) :: String.t()
  def normalize_duration(duration) when is_map(duration) do
    normalized =
      duration
      |> Enum.map(fn
        {key, value} when is_binary(key) -> {String.to_atom(key), value}
        {key, value} -> {key, value}
      end)
      |> Enum.into(%{})

    duration_struct =
      cond do
        Map.has_key?(normalized, :start) or Map.has_key?(normalized, :end) ->
          normalize_datetime_duration(normalized)

        Map.has_key?(normalized, :hours) or Map.has_key?(normalized, :minutes) or
            Map.has_key?(normalized, :seconds) ->
          %{
            hours: Map.get(normalized, :hours, 0),
            minutes: Map.get(normalized, :minutes, 0),
            seconds: Map.get(normalized, :seconds, 0)
          }

        true ->
          %{hours: 0, minutes: 0, seconds: 1}
      end

    duration_struct_to_iso8601(duration_struct)
  end

  def normalize_duration({:fixed, seconds}) when is_number(seconds) do
    seconds |> round() |> seconds_to_duration_struct() |> duration_struct_to_iso8601()
  end

  def normalize_duration({:range, min_seconds, max_seconds})
      when is_number(min_seconds) and is_number(max_seconds) do
    min_seconds |> round() |> seconds_to_duration_struct() |> duration_struct_to_iso8601()
  end

  def normalize_duration({:open_ended, duration_map}) when is_map(duration_map) do
    normalize_duration(duration_map)
  end

  def normalize_duration(seconds) when is_number(seconds) do
    seconds |> round() |> seconds_to_duration_struct() |> duration_struct_to_iso8601()
  end

  def normalize_duration(iso8601_string) when is_binary(iso8601_string) do
    case Duration.parse(iso8601_string) do
      {:ok, duration} ->
        total_seconds = Duration.to_seconds(duration) |> round()
        total_seconds |> seconds_to_duration_struct() |> duration_struct_to_iso8601()

      {:error, _} ->
        "PT1S"
    end
  end

  def normalize_duration(_) do
    "PT1S"
  end

  @spec normalize_datetime_duration(map()) :: map()
  defp normalize_datetime_duration(duration_map) do
    start_time = Map.get(duration_map, :start)
    end_time = Map.get(duration_map, :end)

    cond do
      start_time && end_time ->
        case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
          {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
            diff_seconds = DateTime.diff(end_dt, start_dt, :second)
            seconds_to_duration_struct(max(diff_seconds, 1))

          _ ->
            %{hours: 1, minutes: 0, seconds: 0}
        end

      start_time || end_time ->
        %{hours: 1, minutes: 0, seconds: 0}

      true ->
        %{hours: 0, minutes: 0, seconds: 1}
    end
  end

  @doc "Converts a duration struct to ISO8601 duration string using Timex.\n\n## Examples\n\n    iex> AriaEngine.Utils.duration_struct_to_iso8601(%{hours: 1, minutes: 30, seconds: 0})\n    \"PT1H30M\"\n    \n    iex> AriaEngine.Utils.duration_struct_to_iso8601(%{hours: 0, minutes: 5, seconds: 30})\n    \"PT5M30S\"\n"
  @spec duration_struct_to_iso8601(map()) :: String.t()
  def duration_struct_to_iso8601(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)
    time_struct = Time.new!(hours, minutes, seconds)
    Duration.from_time(time_struct) |> Duration.to_string()
  end

  @doc "Converts a duration struct to total seconds.\n\n## Examples\n\n    iex> AriaEngine.Utils.duration_struct_to_seconds(%{hours: 1, minutes: 30, seconds: 15})\n    5415\n    \n    iex> AriaEngine.Utils.duration_struct_to_seconds(%{hours: 0, minutes: 5, seconds: 0})\n    300\n"
  @spec duration_struct_to_seconds(map()) :: integer()
  def duration_struct_to_seconds(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)
    hours * 3600 + minutes * 60 + seconds
  end

  @doc "Converts a duration struct to a human-readable string.\n\n## Examples\n\n    iex> AriaEngine.Utils.duration_to_string(%{hours: 1, minutes: 30, seconds: 0})\n    \"1h 30m\"\n    \n    iex> AriaEngine.Utils.duration_to_string(%{hours: 0, minutes: 0, seconds: 45})\n    \"45s\"\n"
  @spec duration_to_string(map()) :: String.t()
  def duration_to_string(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)
    parts = []

    parts =
      if hours > 0 do
        ["#{hours}h" | parts]
      else
        parts
      end

    parts =
      if minutes > 0 do
        ["#{minutes}m" | parts]
      else
        parts
      end

    parts =
      if seconds > 0 do
        ["#{seconds}s" | parts]
      else
        parts
      end

    case parts do
      [] -> "0s"
      _ -> parts |> Enum.reverse() |> Enum.join(" ")
    end
  end

  @doc "Converts seconds to a duration struct.\n\n## Examples\n\n    iex> AriaEngine.Utils.seconds_to_duration_struct(3665)\n    %{hours: 1, minutes: 1, seconds: 5}\n    \n    iex> AriaEngine.Utils.seconds_to_duration_struct(300)\n    %{hours: 0, minutes: 5, seconds: 0}\n"
  @spec seconds_to_duration_struct(integer()) :: map()
  def seconds_to_duration_struct(total_seconds) when is_integer(total_seconds) do
    hours = div(total_seconds, 3600)
    remaining_seconds = rem(total_seconds, 3600)
    minutes = div(remaining_seconds, 60)
    seconds = rem(remaining_seconds, 60)
    %{hours: hours, minutes: minutes, seconds: seconds}
  end

  @doc "Validates that a duration map has valid values.\n\n## Examples\n\n    iex> AriaEngine.Utils.valid_duration?(%{hours: 1, minutes: 30, seconds: 0})\n    true\n    \n    iex> AriaEngine.Utils.valid_duration?(%{hours: -1, minutes: 30, seconds: 0})\n    false\n"
  @spec valid_duration?(map()) :: boolean()
  def valid_duration?(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)

    is_integer(hours) and hours >= 0 and is_integer(minutes) and minutes >= 0 and minutes < 60 and
      is_integer(seconds) and seconds >= 0 and seconds < 60
  end

  def valid_duration?(_) do
    false
  end

  @doc "Converts an ISO8601 duration string to seconds.\n\n## Examples\n\n    iex> AriaEngine.Utils.iso8601_to_seconds(\"PT1H30M\")\n    5400\n    \n    iex> AriaEngine.Utils.iso8601_to_seconds(\"PT5M30S\")\n    330\n"
  @spec iso8601_to_seconds(String.t()) :: integer()
  def iso8601_to_seconds(iso8601_string) when is_binary(iso8601_string) do
    case Duration.parse(iso8601_string) do
      {:ok, duration} -> Duration.to_seconds(duration) |> round()
      {:error, _} -> 1
    end
  end

  @doc "Converts an ISO8601 duration string to a duration struct.\n\n## Examples\n\n    iex> AriaEngine.Utils.iso8601_to_duration_struct(\"PT1H30M\")\n    %{hours: 1, minutes: 30, seconds: 0}\n    \n    iex> AriaEngine.Utils.iso8601_to_duration_struct(\"PT5M30S\")\n    %{hours: 0, minutes: 5, seconds: 30}\n"
  @spec iso8601_to_duration_struct(String.t()) :: map()
  def iso8601_to_duration_struct(iso8601_string) when is_binary(iso8601_string) do
    iso8601_string |> iso8601_to_seconds() |> seconds_to_duration_struct()
  end
end
