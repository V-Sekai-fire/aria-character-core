# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline.TimelineCore do
  @moduledoc """
  Core timeline functionality with STN integration.

  This module provides the core timeline functionality that was previously
  mocked. It now properly delegates to the real timeline implementations
  including STN operations, interval management, and temporal reasoning.

  This is the proper implementation that replaces the previous mock.
  """

  alias Timeline.Internal.STN
  alias Timeline.Interval
  alias Timeline

  @type t :: Timeline.t()

  @doc """
  Create a new timeline.
  """
  @spec new() :: t()
  def new do
    Timeline.new()
  end

  @doc """
  Create a new timeline with options.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    Timeline.new(opts)
  end

  @doc """
  Add an event to the timeline.

  Events are converted to intervals for STN processing.
  """
  @spec add_event(t(), map()) :: t()
  def add_event(timeline, event) do
    # Convert event to interval if it has temporal information
    case extract_temporal_info(event) do
      {:ok, interval} ->
        Timeline.add_interval(timeline, interval)

      {:error, _} ->
        # Add as metadata if no temporal information
        metadata = Map.get(timeline, :metadata, %{})
        events = Map.get(metadata, :events, [])
        updated_metadata = Map.put(metadata, :events, [event | events])
        %{timeline | metadata: updated_metadata}
    end
  end

  @doc """
  Add an interval to the timeline.
  """
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(timeline, interval) do
    Timeline.add_interval(timeline, interval)
  end

  @doc """
  Add a constraint to the timeline.
  """
  @spec add_constraint(t(), any(), any(), any()) :: t()
  def add_constraint(timeline, from_point, to_point, constraint) do
    Timeline.add_constraint(timeline, from_point, to_point, constraint)
  end

  @doc """
  Add a time point to the timeline.
  """
  @spec add_time_point(t(), any()) :: t()
  def add_time_point(timeline, time_point) do
    Timeline.add_time_point(timeline, time_point)
  end

  @doc """
  Get time points from the timeline.
  """
  @spec time_points(t()) :: [String.t()]
  def time_points(timeline) do
    Timeline.time_points(timeline)
  end

  @doc """
  Get STN from the timeline.
  """
  @spec get_stn(t()) :: STN.t()
  def get_stn(timeline) do
    Timeline.get_stn(timeline)
  end

  @doc """
  Check if timeline is consistent.
  """
  @spec consistent?(t()) :: boolean()
  def consistent?(timeline) do
    Timeline.consistent?(timeline)
  end

  @doc """
  Get all intervals from the timeline.
  """
  @spec get_intervals(t()) :: [Interval.t()]
  def get_intervals(timeline) do
    Timeline.get_intervals(timeline)
  end

  @doc """
  Find intervals that overlap with the given time range.
  """
  @spec get_overlapping_intervals(t(), number(), number()) :: [map()]
  def get_overlapping_intervals(timeline, query_start, query_end) do
    Timeline.get_overlapping_intervals(timeline, query_start, query_end)
  end

  @doc """
  Find free time slots of the specified duration within the given time window.
  """
  @spec find_free_slots(t(), number(), number(), number()) :: [map()]
  def find_free_slots(timeline, duration, window_start, window_end) do
    Timeline.find_free_slots(timeline, duration, window_start, window_end)
  end

  @doc """
  Check if a new interval conflicts with existing intervals.
  """
  @spec check_interval_conflicts(t(), number(), number()) :: [map()]
  def check_interval_conflicts(timeline, new_start, new_end) do
    Timeline.check_interval_conflicts(timeline, new_start, new_end)
  end

  @doc """
  Find the next available time slot for the given duration.
  """
  @spec find_next_available_slot(t(), number(), number()) :: {:ok, number(), number()} | {:error, atom()}
  def find_next_available_slot(timeline, duration, earliest_start) do
    Timeline.find_next_available_slot(timeline, duration, earliest_start)
  end

  @doc """
  Solve the timeline's temporal constraints.
  """
  @spec solve(t()) :: t()
  def solve(timeline) do
    Timeline.solve(timeline)
  end

  @doc """
  Rescale the timeline to a different LOD level.
  """
  @spec rescale_lod(t(), STN.lod_level()) :: t()
  def rescale_lod(timeline, new_lod_level) do
    Timeline.rescale_lod(timeline, new_lod_level)
  end

  @doc """
  Convert the timeline to use different time units.
  """
  @spec convert_units(t(), STN.time_unit()) :: t()
  def convert_units(timeline, new_unit) do
    Timeline.convert_units(timeline, new_unit)
  end

  # Private helper functions

  defp extract_temporal_info(event) do
    cond do
      # Event has start and end times
      Map.has_key?(event, :start_time) and Map.has_key?(event, :end_time) ->
        case {event.start_time, event.end_time} do
          {%DateTime{} = start_dt, %DateTime{} = end_dt} ->
            interval = Interval.new(start_dt, end_dt, metadata: Map.drop(event, [:start_time, :end_time]))
            {:ok, interval}

          _ ->
            {:error, :invalid_datetime}
        end

      # Event has ISO 8601 temporal specification
      Map.has_key?(event, :start) and Map.has_key?(event, :end) ->
        try do
          interval = Interval.new_fixed_schedule(event.start, event.end,
            metadata: Map.drop(event, [:start, :end]))
          {:ok, interval}
        rescue
          _ -> {:error, :invalid_iso8601}
        end

      # Event has duration only
      Map.has_key?(event, :duration) ->
        try do
          interval = Interval.new_floating_duration(event.duration,
            metadata: Map.drop(event, [:duration]))
          {:ok, interval}
        rescue
          _ -> {:error, :invalid_duration}
        end

      # No temporal information
      true ->
        {:error, :no_temporal_info}
    end
  end
end
