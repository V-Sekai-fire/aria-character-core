# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline do
  @moduledoc """
  Timeline management with STN (Simple Temporal Network) integration.

  This module provides timeline management functionality with sophisticated
  temporal reasoning capabilities including:
  - STN-based temporal constraint management
  - Interval operations with Allen's interval algebra
  - Agent and entity management
  - LOD (Level of Detail) management
  - Complex temporal reasoning and constraint solving

  This is the proper implementation that delegates to the real timeline
  modules, replacing the previous mock implementation.
  """

  alias Timeline.Internal.STN
  alias Timeline.Interval

  @type t :: %__MODULE__{
    stn: STN.t(),
    intervals: [Interval.t()],
    metadata: map()
  }

  defstruct stn: nil, intervals: [], metadata: %{}

  @doc """
  Create a new timeline with STN backend.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      stn: STN.new(),
      intervals: [],
      metadata: %{}
    }
  end

  @doc """
  Create a new timeline with options.

  ## Options

  - `:time_unit` - Time unit for STN (:second, :minute, :hour, etc.)
  - `:lod_level` - Level of detail (:ultra_high, :high, :medium, :low, :very_low)
  - `:max_timepoints` - Maximum number of time points
  - `:constant_work_enabled` - Enable constant work pattern
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    %__MODULE__{
      stn: STN.new(opts),
      intervals: [],
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Add an interval to the timeline.
  """
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, %Interval{} = interval) do
    updated_stn = STN.add_interval(timeline.stn, interval)
    updated_intervals = [interval | timeline.intervals]

    %{timeline |
      stn: updated_stn,
      intervals: updated_intervals
    }
  end

  @doc """
  Add multiple intervals to the timeline.
  """
  @spec add_intervals(t(), [Interval.t()]) :: t()
  def add_intervals(%__MODULE__{} = timeline, intervals) when is_list(intervals) do
    Enum.reduce(intervals, timeline, &add_interval(&2, &1))
  end

  @doc """
  Remove an interval from the timeline by ID.
  """
  @spec remove_interval(t(), String.t()) :: t()
  def remove_interval(%__MODULE__{} = timeline, interval_id) do
    updated_stn = STN.remove_interval(timeline.stn, interval_id)
    updated_intervals = Enum.reject(timeline.intervals, fn interval ->
      interval.id == interval_id
    end)

    %{timeline |
      stn: updated_stn,
      intervals: updated_intervals
    }
  end

  @doc """
  Add a temporal constraint between two time points.
  """
  @spec add_constraint(t(), String.t(), String.t(), STN.constraint()) :: t()
  def add_constraint(%__MODULE__{} = timeline, from_point, to_point, constraint) do
    updated_stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: updated_stn}
  end

  @doc """
  Add a time point to the timeline.
  """
  @spec add_time_point(t(), String.t()) :: t()
  def add_time_point(%__MODULE__{} = timeline, time_point) do
    updated_stn = STN.add_time_point(timeline.stn, time_point)
    %{timeline | stn: updated_stn}
  end

  @doc """
  Get all time points in the timeline.
  """
  @spec time_points(t()) :: [String.t()]
  def time_points(%__MODULE__{} = timeline) do
    STN.time_points(timeline.stn)
  end

  @doc """
  Get the STN from the timeline.
  """
  @spec get_stn(t()) :: STN.t()
  def get_stn(%__MODULE__{} = timeline) do
    timeline.stn
  end

  @doc """
  Check if the timeline is temporally consistent.
  """
  @spec consistent?(t()) :: boolean()
  def consistent?(%__MODULE__{} = timeline) do
    STN.consistent?(timeline.stn)
  end

@doc """
  Get all intervals from the timeline.
  """
  @spec get_intervals(t()) :: [Interval.t()]
  def get_intervals(%__MODULE__{} = timeline) do
    timeline.intervals
  end

  @doc """
  Find intervals that overlap with the given time range.
  """
  @spec get_overlapping_intervals(t(), number(), number()) :: [map()]
  def get_overlapping_intervals(%__MODULE__{} = timeline, query_start, query_end) do
    STN.get_overlapping_intervals(timeline.stn, query_start, query_end)
  end

  @doc """
  Find free time slots of the specified duration within the given time window.
  """
  @spec find_free_slots(t(), number(), number(), number()) :: [map()]
  def find_free_slots(%__MODULE__{} = timeline, duration, window_start, window_end) do
    STN.find_free_slots(timeline.stn, duration, window_start, window_end)
  end

  @doc """
  Check if a new interval conflicts with existing intervals.
  """
  @spec check_interval_conflicts(t(), number(), number()) :: [map()]
  def check_interval_conflicts(%__MODULE__{} = timeline, new_start, new_end) do
    STN.check_interval_conflicts(timeline.stn, new_start, new_end)
  end

  @doc """
  Find the next available time slot for the given duration.
  """
  @spec find_next_available_slot(t(), number(), number()) :: {:ok, number(), number()} | {:error, atom()}
  def find_next_available_slot(%__MODULE__{} = timeline, duration, earliest_start) do
    STN.find_next_available_slot(timeline.stn, duration, earliest_start)
  end

  @doc """
  Solve the timeline's temporal constraints using MiniZinc.
  """
  @spec solve(t()) :: t()
  def solve(%__MODULE__{} = timeline) do
    solved_stn = STN.solve_stn(timeline.stn)
    %{timeline | stn: solved_stn}
  end

  @doc """
  Rescale the timeline to a different LOD level.
  """
  @spec rescale_lod(t(), STN.lod_level()) :: t()
  def rescale_lod(%__MODULE__{} = timeline, new_lod_level) do
    rescaled_stn = STN.rescale_lod(timeline.stn, new_lod_level)
    %{timeline | stn: rescaled_stn}
  end

  @doc """
  Convert the timeline to use different time units.
  """
  @spec convert_units(t(), STN.time_unit()) :: t()
  def convert_units(%__MODULE__{} = timeline, new_unit) do
    converted_stn = STN.convert_units(timeline.stn, new_unit)
    %{timeline | stn: converted_stn}
  end
end
