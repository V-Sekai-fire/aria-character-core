# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN do
  @moduledoc false
  alias Timeline.Internal.STN.Core
  alias AriaMinizincStn
  alias Timeline.Internal.STN.Units
  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000
  @type t :: %__MODULE__{
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          consistent: boolean(),
          segments: [segment()],
          metadata: map(),
          time_unit: time_unit(),
          lod_level: lod_level(),
          lod_resolution: lod_resolution(),
          auto_rescale: boolean(),
          datetime_conversion_unit: time_unit(),
          max_timepoints: pos_integer(),
          constant_work_enabled: boolean(),
          dummy_constraints: constraint_matrix()
        }
  @type segment :: %{
          id: String.t(),
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          boundary_points: [time_point()],
          consistent: boolean()
        }
  defstruct time_points: MapSet.new(),
            constraints: %{},
            consistent: true,
            segments: [],
            metadata: %{},
            time_unit: :second,
            lod_level: :medium,
            lod_resolution: 100,
            auto_rescale: true,
            datetime_conversion_unit: :second,
            max_timepoints: 64,
            constant_work_enabled: false,
            dummy_constraints: %{}

  @doc "Creates a new empty Simple Temporal Network.\n\nUses seconds as the default time unit for human-readable temporal constraints.\n"
  @spec new() :: t()
  def new do
    %__MODULE__{time_points: MapSet.new(), constraints: %{}, consistent: true, time_unit: :second}
  end

  @doc "Creates a new Simple Temporal Network with specified units and LOD level.\n"
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    time_unit = Keyword.get(opts, :time_unit, :second)
    lod_level = Keyword.get(opts, :lod_level, :medium)
    max_timepoints = Keyword.get(opts, :max_timepoints, 64)
    constant_work_enabled = Keyword.get(opts, :constant_work_enabled, false)

    stn = %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      time_unit: time_unit,
      lod_level: lod_level,
      lod_resolution: Units.lod_resolution_for_level(lod_level),
      auto_rescale: Keyword.get(opts, :auto_rescale, true),
      datetime_conversion_unit: Keyword.get(opts, :datetime_conversion_unit, :second),
      max_timepoints: max_timepoints,
      constant_work_enabled: constant_work_enabled,
      dummy_constraints: %{}
    }

    if constant_work_enabled do
      initialize_constant_work_structure(stn)
    else
      stn
    end
  end

  @doc "Creates a new Simple Temporal Network with constant work pattern enabled by default.\n"
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    opts_with_constant_work = Keyword.put(opts, :constant_work_enabled, true)
    new(opts_with_constant_work)
  end

  defdelegate add_interval(stn, interval), to: Core
  defdelegate update_interval(stn, interval), to: Core
  defdelegate remove_interval(stn, interval_id), to: Core
  defdelegate add_constraint(stn, from_point, to_point, constraint), to: Core
  defdelegate consistent?(stn), to: Core
  defdelegate time_points(stn), to: Core
  defdelegate get_constraint(stn, from_point, to_point), to: Core
  defdelegate add_time_point(stn, time_point), to: Core
  defdelegate get_intervals(stn), to: Core
  defdelegate get_overlapping_intervals(stn, query_start, query_end), to: Core
  defdelegate find_free_slots(stn, duration, window_start, window_end), to: Core
  defdelegate check_interval_conflicts(stn, new_start, new_end), to: Core
  defdelegate find_next_available_slot(stn, duration, earliest_start), to: Core
  defdelegate solve_stn(stn), to: AriaMinizincStn
  defdelegate rescale_lod(stn, new_lod_level), to: Units
  defdelegate convert_units(stn, new_unit), to: Units
  defdelegate from_datetime_intervals(intervals, opts), to: Units

  defp initialize_constant_work_structure(stn) do
    dummy_points =
      for i <- 1..stn.max_timepoints do
        "dummy_#{i}"
      end
      |> MapSet.new()

    dummy_constraints =
      Enum.reduce(dummy_points, %{}, fn point, acc -> Map.put(acc, {point, point}, {-1, 1}) end)

    %{
      stn
      | time_points: MapSet.union(stn.time_points, dummy_points),
        dummy_constraints: dummy_constraints,
        constraints: Map.merge(stn.constraints, dummy_constraints)
    }
  end
end
