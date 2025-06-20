defmodule AriaEngine.Utils do
  @moduledoc """
  Utility functions for AriaEngine, including ISO 8601 duration normalization and math.
  """

  @doc """
  Normalize a duration value (integer seconds, float seconds, or ISO 8601 string) to an ISO 8601 duration string.

  Returns ISO 8601 duration string, or raises ArgumentError if invalid.
  """
  def normalize_duration(duration) when is_integer(duration) or is_float(duration) do
    seconds_to_iso8601(duration)
  end

  def normalize_duration(duration) when is_binary(duration) do
    # Validate ISO 8601 format, but return as-is if valid
    regex = ~r/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$/
    if Regex.match?(regex, String.upcase(duration)) do
      String.upcase(duration)
    else
      raise ArgumentError, "Invalid ISO 8601 duration format: #{duration}"
    end
  end

  @doc """
  Convert ISO 8601 duration string or seconds (int/float) to float seconds.
  """
  def duration_to_seconds(duration) when is_integer(duration), do: duration * 1.0
  def duration_to_seconds(duration) when is_float(duration), do: duration
  def duration_to_seconds(duration) when is_binary(duration) do
    regex = ~r/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$/
    case Regex.run(regex, String.upcase(duration)) do
      [_, hours_str, minutes_str, seconds_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)
        seconds = parse_time_component(seconds_str)
        hours * 3600 + minutes * 60 + seconds
      [_, hours_str, minutes_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)
        hours * 3600 + minutes * 60
      [_, hours_str] ->
        hours = parse_time_component(hours_str)
        hours * 3600
      _ ->
        raise ArgumentError, "Invalid ISO 8601 duration format: #{duration}"
    end
  end

  @doc """
  Convert float seconds to ISO 8601 duration string.
  """
  def seconds_to_iso8601(seconds) when is_integer(seconds) or is_float(seconds) do
    total_seconds = trunc(seconds)
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    secs = rem(total_seconds, 60) + (if is_float(seconds), do: seconds - trunc(seconds), else: 0.0)
    "PT" <>
      (if hours > 0, do: "#{hours}H", else: "") <>
      (if minutes > 0, do: "#{minutes}M", else: "") <>
      (if secs > 0, do: "#{Float.round(secs, 3)}S", else: "")
  end

  @doc """
  Add two ISO 8601 duration strings (or seconds), return ISO 8601 string.
  """
  def add_durations(d1, d2) do
    s1 = duration_to_seconds(d1)
    s2 = duration_to_seconds(d2)
    seconds_to_iso8601(s1 + s2)
  end

  @doc """
  Subtract two ISO 8601 duration strings (or seconds), return ISO 8601 string.
  """
  def subtract_durations(d1, d2) do
    s1 = duration_to_seconds(d1)
    s2 = duration_to_seconds(d2)
    seconds_to_iso8601(max(s1 - s2, 0.0))
  end

  defp parse_time_component(nil), do: 0.0
  defp parse_time_component(""), do: 0.0
  defp parse_time_component(str) when is_binary(str) do
    case Float.parse(str) do
      {value, ""} -> value
      _ -> 0.0
    end
  end
end
