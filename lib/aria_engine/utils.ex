# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Utils do
  @moduledoc """
  Utility functions for AriaEngine.

  This module provides common utility functions used across the AriaEngine
  system, including duration handling, string formatting, and data conversion.
  """

  @doc """
  Normalizes a duration map to a standard format.

  ## Examples

      iex> AriaEngine.Utils.normalize_duration(%{hours: 1, minutes: 30})
      %{hours: 1, minutes: 30, seconds: 0}
      
      iex> AriaEngine.Utils.normalize_duration(%{"hours" => 2})
      %{hours: 2, minutes: 0, seconds: 0}
  """
  @spec normalize_duration(map()) :: map()
  def normalize_duration(duration) when is_map(duration) do
    # Convert string keys to atoms if needed
    normalized =
      duration
      |> Enum.map(fn
        {key, value} when is_binary(key) -> {String.to_atom(key), value}
        {key, value} -> {key, value}
      end)
      |> Enum.into(%{})

    # Ensure all required fields are present
    %{
      hours: Map.get(normalized, :hours, 0),
      minutes: Map.get(normalized, :minutes, 0),
      seconds: Map.get(normalized, :seconds, 0)
    }
  end

  @doc """
  Converts a duration struct to total seconds.

  ## Examples

      iex> AriaEngine.Utils.duration_struct_to_seconds(%{hours: 1, minutes: 30, seconds: 15})
      5415
      
      iex> AriaEngine.Utils.duration_struct_to_seconds(%{hours: 0, minutes: 5, seconds: 0})
      300
  """
  @spec duration_struct_to_seconds(map()) :: integer()
  def duration_struct_to_seconds(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)

    hours * 3600 + minutes * 60 + seconds
  end

  @doc """
  Converts a duration struct to a human-readable string.

  ## Examples

      iex> AriaEngine.Utils.duration_to_string(%{hours: 1, minutes: 30, seconds: 0})
      "1h 30m"
      
      iex> AriaEngine.Utils.duration_to_string(%{hours: 0, minutes: 0, seconds: 45})
      "45s"
  """
  @spec duration_to_string(map()) :: String.t()
  def duration_to_string(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)

    parts = []

    parts = if hours > 0, do: ["#{hours}h" | parts], else: parts
    parts = if minutes > 0, do: ["#{minutes}m" | parts], else: parts
    parts = if seconds > 0, do: ["#{seconds}s" | parts], else: parts

    case parts do
      [] -> "0s"
      _ -> parts |> Enum.reverse() |> Enum.join(" ")
    end
  end

  @doc """
  Converts seconds to a duration struct.

  ## Examples

      iex> AriaEngine.Utils.seconds_to_duration_struct(3665)
      %{hours: 1, minutes: 1, seconds: 5}
      
      iex> AriaEngine.Utils.seconds_to_duration_struct(300)
      %{hours: 0, minutes: 5, seconds: 0}
  """
  @spec seconds_to_duration_struct(integer()) :: map()
  def seconds_to_duration_struct(total_seconds) when is_integer(total_seconds) do
    hours = div(total_seconds, 3600)
    remaining_seconds = rem(total_seconds, 3600)
    minutes = div(remaining_seconds, 60)
    seconds = rem(remaining_seconds, 60)

    %{
      hours: hours,
      minutes: minutes,
      seconds: seconds
    }
  end

  @doc """
  Validates that a duration map has valid values.

  ## Examples

      iex> AriaEngine.Utils.valid_duration?(%{hours: 1, minutes: 30, seconds: 0})
      true
      
      iex> AriaEngine.Utils.valid_duration?(%{hours: -1, minutes: 30, seconds: 0})
      false
  """
  @spec valid_duration?(map()) :: boolean()
  def valid_duration?(duration) when is_map(duration) do
    hours = Map.get(duration, :hours, 0)
    minutes = Map.get(duration, :minutes, 0)
    seconds = Map.get(duration, :seconds, 0)

    is_integer(hours) and hours >= 0 and
      is_integer(minutes) and minutes >= 0 and minutes < 60 and
      is_integer(seconds) and seconds >= 0 and seconds < 60
  end

  def valid_duration?(_), do: false
end
