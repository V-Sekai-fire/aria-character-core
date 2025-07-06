# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.Units do
  @moduledoc false
  alias Timeline.Internal.STN
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000
  @doc "Changes the LOD level of an STN, rescaling all constraints appropriately.\n"
  @spec rescale_lod(STN.t(), lod_level()) :: STN.t()
  def rescale_lod(stn, new_lod_level) do
    if stn.lod_level == new_lod_level do
      stn
    else
      old_resolution = stn.lod_resolution
      new_resolution = lod_resolution_for_level(new_lod_level)
      scale_factor = old_resolution / new_resolution

      rescaled_constraints =
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * scale_factor), round(max_dist * scale_factor)}}
        end)
        |> Map.new()

      updated_stn = %{
        stn
        | lod_level: new_lod_level,
          lod_resolution: new_resolution,
          constraints: rescaled_constraints
      }

      # Only solve if there are time points to solve
      if MapSet.size(updated_stn.time_points) > 0 do
        case AriaMinizincStn.solve_stn(updated_stn) do
          {:ok, solved_stn} -> solved_stn
          {:error, _} -> updated_stn
        end
      else
        updated_stn
      end
    end
  end

  @doc "Converts STN units to a different time unit.\n"
  @spec convert_units(STN.t(), time_unit()) :: STN.t()
  def convert_units(stn, new_unit) do
    if stn.time_unit == new_unit do
      stn
    else
      conversion_factor = unit_conversion_factor(stn.time_unit, new_unit)

      converted_constraints =
        Enum.map(stn.constraints, fn {{from, to}, {min_dist, max_dist}} ->
          {{from, to}, {round(min_dist * conversion_factor), round(max_dist * conversion_factor)}}
        end)
        |> Map.new()

      updated_stn = %{stn | time_unit: new_unit, constraints: converted_constraints}

      # Only solve if there are time points to solve
      if MapSet.size(updated_stn.time_points) > 0 do
        case AriaMinizincStn.solve_stn(updated_stn) do
          {:ok, solved_stn} -> solved_stn
          {:error, _} -> updated_stn
        end
      else
        updated_stn
      end
    end
  end

  @doc "Creates an STN from DateTime intervals with automatic unit conversion.\n"
  @spec from_datetime_intervals([Timeline.Interval.t()], keyword()) :: STN.t()
  def from_datetime_intervals(intervals, opts \\ []) do
    stn = STN.new(opts)

    Enum.reduce(intervals, stn, fn interval, acc_stn ->
      STN.Core.add_interval(acc_stn, interval)
    end)
  end

  @spec lod_resolution_for_level(lod_level()) :: lod_resolution()
  def lod_resolution_for_level(:ultra_high) do
    1
  end

  def lod_resolution_for_level(:high) do
    10
  end

  def lod_resolution_for_level(:medium) do
    100
  end

  def lod_resolution_for_level(:low) do
    1000
  end

  def lod_resolution_for_level(:very_low) do
    10000
  end

  @spec unit_conversion_factor(time_unit(), time_unit()) :: float()
  def unit_conversion_factor(from_unit, to_unit) do
    from_microseconds = unit_to_microseconds(from_unit)
    to_microseconds = unit_to_microseconds(to_unit)
    from_microseconds / to_microseconds
  end

  @spec unit_to_microseconds(time_unit()) :: integer()
  def unit_to_microseconds(:microsecond) do
    1
  end

  def unit_to_microseconds(:millisecond) do
    1000
  end

  def unit_to_microseconds(:second) do
    1_000_000
  end

  def unit_to_microseconds(:minute) do
    60_000_000
  end

  def unit_to_microseconds(:hour) do
    3_600_000_000
  end

  def unit_to_microseconds(:day) do
    86_400_000_000
  end

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
    duration_microseconds = DateTime.diff(end_dt, start_dt, :microsecond)
    target_unit_microseconds = unit_to_microseconds(target_unit)
    duration_in_target_units = duration_microseconds / target_unit_microseconds
    duration_in_stn_units = duration_in_target_units * lod_resolution
    round(duration_in_stn_units)
  end
end
