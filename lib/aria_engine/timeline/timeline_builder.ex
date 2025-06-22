# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.TimelineBuilder do
  @moduledoc """
  Bridge builder pattern and fluent API for Timeline construction.

  This module provides:
  - Bridge builder pattern functions
  - Auto-insertion logic and rules
  - Fluent API for timeline construction
  - Phase management and workflow helpers

  The builder pattern allows for easy construction of complex timelines
  with automatic bridge placement and validation.
  """

  alias AriaEngine.Timeline.Bridge
  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.IntervalOperations

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: any(),
          metadata: map()
        }

  @type builder_opts :: [
          auto_bridges: boolean(),
          bridge_spacing: pos_integer(),
          phase_tracking: boolean()
        ]

  @doc """
  Creates a new timeline builder with configuration options.

  ## Options

  - `:auto_bridges` - Automatically insert bridges at regular intervals (default: false)
  - `:bridge_spacing` - Minimum time between auto-inserted bridges in seconds (default: 3600)
  - `:phase_tracking` - Track construction phases in metadata (default: true)

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new(auto_bridges: true, bridge_spacing: 1800)
      iex> Map.get(builder.metadata, :auto_bridges)
      true

  """
  @spec new(builder_opts()) :: timeline()
  def new(opts \\ []) do
    auto_bridges = Keyword.get(opts, :auto_bridges, false)
    bridge_spacing = Keyword.get(opts, :bridge_spacing, 3600)
    phase_tracking = Keyword.get(opts, :phase_tracking, true)

    metadata = %{
      auto_bridges: auto_bridges,
      bridge_spacing: bridge_spacing,
      phase_tracking: phase_tracking,
      construction_phase: :initial,
      last_bridge_time: nil
    }

    IntervalOperations.new(metadata: metadata)
  end

  @doc """
  Adds an interval to the timeline with automatic bridge insertion.

  If auto_bridges is enabled, this will automatically insert bridges
  based on the configured spacing rules.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new(auto_bridges: true, bridge_spacing: 1800)
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_time, end_time)
      iex> updated_builder = AriaEngine.Timeline.Builder.add_interval(builder, interval)
      iex> map_size(updated_builder.intervals)
      1

  """
  @spec add_interval(timeline(), Interval.t()) :: timeline()
  def add_interval(timeline, %Interval{} = interval) do
    # Add the interval using core functionality
    updated_timeline = IntervalOperations.add_interval(timeline, interval)

    # Apply auto-bridge insertion if enabled
    if timeline.metadata[:auto_bridges] do
      insert_auto_bridges(updated_timeline, interval)
    else
      updated_timeline
    end
  end

  @doc """
  Adds multiple intervals to the timeline with batch bridge insertion.

  More efficient than calling add_interval/2 multiple times when adding
  many intervals, as it can optimize bridge placement across all intervals.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> interval1 = AriaEngine.Timeline.Interval.new(start1, end1)
      iex> interval2 = AriaEngine.Timeline.Interval.new(start2, end2)
      iex> updated_builder = AriaEngine.Timeline.Builder.add_intervals(builder, [interval1, interval2])
      iex> map_size(updated_builder.intervals)
      2

  """
  @spec add_intervals(timeline(), [Interval.t()]) :: timeline()
  def add_intervals(timeline, intervals) when is_list(intervals) do
    # Add all intervals first
    updated_timeline = IntervalOperations.add_intervals(timeline, intervals)

    # Apply batch auto-bridge insertion if enabled
    if timeline.metadata[:auto_bridges] do
      insert_batch_auto_bridges(updated_timeline, intervals)
    else
      updated_timeline
    end
  end

  @doc """
  Manually adds a bridge to the timeline with validation.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> updated_builder = AriaEngine.Timeline.Builder.add_bridge(builder, bridge)
      iex> Map.has_key?(updated_builder.bridges, "decision_1")
      true

  """
  @spec add_bridge(timeline(), Bridge.t()) :: timeline()
  def add_bridge(timeline, %Bridge{} = bridge) do
    # Validate bridge placement
    case validate_bridge_for_builder(timeline, bridge) do
      :ok ->
        updated_timeline = %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
        update_last_bridge_time(updated_timeline, bridge.position)

      {:error, reason} ->
        raise ArgumentError, "Bridge validation failed: #{reason}"
    end
  end

  @doc """
  Sets the construction phase for tracking build progress.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new()
      iex> updated_builder = AriaEngine.Timeline.Builder.set_phase(builder, :intervals_complete)
      iex> Map.get(updated_builder.metadata, :construction_phase)
      :intervals_complete

  """
  @spec set_phase(timeline(), atom()) :: timeline()
  def set_phase(timeline, phase) when is_atom(phase) do
    if timeline.metadata[:phase_tracking] do
      metadata = Map.put(timeline.metadata, :construction_phase, phase)
      %{timeline | metadata: metadata}
    else
      timeline
    end
  end

  @doc """
  Finalizes the timeline construction and returns a standard Timeline.

  This removes builder-specific metadata and performs final validation.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new()
      iex> finalized = AriaEngine.Timeline.Builder.finalize(builder)
      iex> Map.has_key?(finalized.metadata, :auto_bridges)
      false

  """
  @spec finalize(timeline()) :: timeline()
  def finalize(timeline) do
    # Remove builder-specific metadata
    cleaned_metadata =
      timeline.metadata
      |> Map.drop([:auto_bridges, :bridge_spacing, :phase_tracking, :construction_phase, :last_bridge_time])

    # Set final phase if tracking is enabled
    final_metadata =
      if timeline.metadata[:phase_tracking] do
        Map.put(cleaned_metadata, :finalized_at, DateTime.utc_now())
      else
        cleaned_metadata
      end

    %{timeline | metadata: final_metadata}
  end

  @doc """
  Gets the current construction phase.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new()
      iex> AriaEngine.Timeline.Builder.get_phase(builder)
      :initial

  """
  @spec get_phase(timeline()) :: atom() | nil
  def get_phase(timeline) do
    Map.get(timeline.metadata, :construction_phase)
  end

  @doc """
  Checks if auto-bridge insertion is enabled.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new(auto_bridges: true)
      iex> AriaEngine.Timeline.Builder.auto_bridges_enabled?(builder)
      true

  """
  @spec auto_bridges_enabled?(timeline()) :: boolean()
  def auto_bridges_enabled?(timeline) do
    Map.get(timeline.metadata, :auto_bridges, false)
  end

  @doc """
  Gets the configured bridge spacing in seconds.

  ## Examples

      iex> builder = AriaEngine.Timeline.Builder.new(bridge_spacing: 1800)
      iex> AriaEngine.Timeline.Builder.get_bridge_spacing(builder)
      1800

  """
  @spec get_bridge_spacing(timeline()) :: pos_integer()
  def get_bridge_spacing(timeline) do
    Map.get(timeline.metadata, :bridge_spacing, 3600)
  end

  # Private helper functions

  defp insert_auto_bridges(timeline, %Interval{} = interval) do
    bridge_spacing = get_bridge_spacing(timeline)
    last_bridge_time = Map.get(timeline.metadata, :last_bridge_time)

    case should_insert_bridge?(interval, last_bridge_time, bridge_spacing) do
      {true, bridge_position} ->
        bridge_id = generate_auto_bridge_id(timeline)
        bridge = Bridge.new(bridge_id, bridge_position, :auto_generated)

        timeline
        |> Map.put(:bridges, Map.put(timeline.bridges, bridge_id, bridge))
        |> update_last_bridge_time(bridge_position)

      false ->
        timeline
    end
  end

  defp insert_batch_auto_bridges(timeline, intervals) when is_list(intervals) do
    bridge_spacing = get_bridge_spacing(timeline)
    last_bridge_time = Map.get(timeline.metadata, :last_bridge_time)

    # Find all positions where bridges should be inserted
    bridge_positions = calculate_batch_bridge_positions(intervals, last_bridge_time, bridge_spacing)

    # Insert all bridges
    {updated_bridges, final_bridge_time} =
      bridge_positions
      |> Enum.with_index()
      |> Enum.reduce({timeline.bridges, last_bridge_time}, fn {position, index}, {bridges_acc, _} ->
        bridge_id = "auto_bridge_#{map_size(bridges_acc) + index + 1}"
        bridge = Bridge.new(bridge_id, position, :auto_generated)
        {Map.put(bridges_acc, bridge_id, bridge), position}
      end)

    timeline
    |> Map.put(:bridges, updated_bridges)
    |> update_last_bridge_time(final_bridge_time)
  end

  defp should_insert_bridge?(%Interval{start_time: start_time}, nil, _bridge_spacing) do
    # First interval, insert bridge at start
    {true, start_time}
  end

  defp should_insert_bridge?(%Interval{start_time: start_time}, last_bridge_time, bridge_spacing) do
    time_diff = DateTime.diff(start_time, last_bridge_time, :second)

    if time_diff >= bridge_spacing do
      # Calculate optimal bridge position (middle of the gap)
      bridge_position = DateTime.add(last_bridge_time, div(time_diff, 2), :second)
      {true, bridge_position}
    else
      false
    end
  end

  defp calculate_batch_bridge_positions(intervals, last_bridge_time, bridge_spacing) do
    # Sort intervals by start time
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time, DateTime)

    # Calculate bridge positions based on spacing rules
    {positions, _} =
      sorted_intervals
      |> Enum.reduce({[], last_bridge_time}, fn interval, {positions_acc, last_time} ->
        case should_insert_bridge?(interval, last_time, bridge_spacing) do
          {true, bridge_position} ->
            {[bridge_position | positions_acc], bridge_position}

          false ->
            {positions_acc, last_time}
        end
      end)

    Enum.reverse(positions)
  end

  defp generate_auto_bridge_id(timeline) do
    existing_count =
      timeline.bridges
      |> Map.keys()
      |> Enum.count(fn id -> String.starts_with?(id, "auto_bridge_") end)

    "auto_bridge_#{existing_count + 1}"
  end

  defp update_last_bridge_time(timeline, bridge_time) when not is_nil(bridge_time) do
    metadata = Map.put(timeline.metadata, :last_bridge_time, bridge_time)
    %{timeline | metadata: metadata}
  end

  defp update_last_bridge_time(timeline, nil), do: timeline

  defp validate_bridge_for_builder(timeline, %Bridge{} = bridge) do
    # Check for duplicate bridge IDs
    if Map.has_key?(timeline.bridges, bridge.id) do
      {:error, "Bridge with ID '#{bridge.id}' already exists"}
    else
      # Additional builder-specific validations could go here
      :ok
    end
  end
end
