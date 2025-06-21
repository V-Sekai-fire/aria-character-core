# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN.Units do
  # This module is part of the internal STN implementation
  @moduledoc false

  alias Timeline.Internal.STN

  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  # time units per tick
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10_000

  @doc """
  Changes the LOD level of an STN, rescaling all constraints appropriately.
  """
  @spec rescale_lod(STN.t(), lod_level()) :: STN.t()
  def rescale_lod(stn, new_lod_level) do
    if stn.lod_level == new_lod_level do
      stn
    else
      old_resolution = stn.lod_resolution
      new_resolution = lod_resolution_for_level(new_lod_level)
      scale_factor = old_resolution / new_resolution

      # Rescale all constraints
      rescaled_constraints =
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * scale_factor), round(max_dist * scale_factor)}}
        end)
        |> Map.new()

      %{
        stn
        | lod_level: new_lod_level,
          lod_resolution: new_resolution,
          constraints: rescaled_constraints
      }
      |> STN.PC2.apply_pc2()
    end
  end

  @doc """
  Converts STN units to a different time unit.
  """
  @spec convert_units(STN.t(), time_unit()) :: STN.t()
  def convert_units(stn, new_unit) do
    if stn.time_unit == new_unit do
      stn
    else
      conversion_factor = unit_conversion_factor(stn.time_unit, new_unit)

      # Convert all constraints
      converted_constraints =
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * conversion_factor), round(max_dist * conversion_factor)}}
        end)
        |> Map.new()

      %{stn | time_unit: new_unit, constraints: converted_constraints}
      |> STN.PC2.apply_pc2()
    end
  end

  @doc """
  Creates an STN from DateTime intervals with automatic unit conversion.
  """
  @spec from_datetime_intervals([Timeline.Interval.t()], keyword()) :: STN.t()
  def from_datetime_intervals(intervals, opts \\ []) do
    stn = STN.new(opts)

    Enum.reduce(intervals, stn, fn interval, acc_stn ->
      STN.Core.add_interval(acc_stn, interval)
    end)
  end

  # Unit Conversion and LOD Helper Functions

  @spec lod_resolution_for_level(lod_level()) :: lod_resolution()
  def lod_resolution_for_level(:ultra_high), do: 1
  def lod_resolution_for_level(:high), do: 10
  def lod_resolution_for_level(:medium), do: 100
  def lod_resolution_for_level(:low), do: 1000
  def lod_resolution_for_level(:very_low), do: 10_000

  @spec unit_conversion_factor(time_unit(), time_unit()) :: float()
  def unit_conversion_factor(from_unit, to_unit) do
    from_microseconds = unit_to_microseconds(from_unit)
    to_microseconds = unit_to_microseconds(to_unit)
    from_microseconds / to_microseconds
  end

  @spec unit_to_microseconds(time_unit()) :: integer()
  def unit_to_microseconds(:microsecond), do: 1
  def unit_to_microseconds(:millisecond), do: 1_000
  def unit_to_microseconds(:second), do: 1_000_000
  def unit_to_microseconds(:minute), do: 60_000_000
  def unit_to_microseconds(:hour), do: 3_600_000_000
  def unit_to_microseconds(:day), do: 86_400_000_000

  @spec convert_datetime_duration_to_stn_units(
          DateTime.t(),
          DateTime.t(),
          time_unit(),
          lod_level(),
          lod_resolution()
        ) :: number()
  def convert_datetime_duration_to_stn_units(
        start_dt,
        end_dt,
        target_unit,
        _lod_level,
        lod_resolution
      ) do
    # Calculate duration in microseconds
    duration_microseconds = DateTime.diff(end_dt, start_dt, :microsecond)

    # Convert to target unit
    target_unit_microseconds = unit_to_microseconds(target_unit)
    duration_in_target_units = duration_microseconds / target_unit_microseconds

    # Apply LOD rescaling
    rescaled_duration = duration_in_target_units / lod_resolution

    # Round to ensure integer constraints
    round(rescaled_duration)
  end
end
