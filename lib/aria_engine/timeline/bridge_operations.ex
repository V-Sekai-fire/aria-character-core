# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.BridgeOperations do
  @moduledoc """
  Bridge management functionality for Timeline segmentation and decision points.

  This module handles:
  - Bridge CRUD operations
  - Bridge validation and placement
  - Bridge querying and filtering
  - Bridge positioning and sorting

  Bridges represent decision points, synchronization points, or other temporal
  markers that can be used to segment timelines for analysis or execution.
  """

  alias AriaEngine.Timeline.Bridge
  alias AriaEngine.Timeline.Interval

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: any(),
          metadata: map()
        }

  @doc """
  Adds a bridge to the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> updated_timeline = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)
      iex> Map.has_key?(updated_timeline.bridges, "decision_1")
      true

  """
  @spec add_bridge(timeline(), Bridge.t()) :: timeline()
  def add_bridge(timeline, %Bridge{} = bridge) do
    validate_bridge_placement!(timeline, bridge)

    %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
  end

  @doc """
  Removes a bridge from the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)
      iex> updated_timeline = AriaEngine.Timeline.Bridges.remove_bridge(timeline_with_bridge, "decision_1")
      iex> Map.has_key?(updated_timeline.bridges, "decision_1")
      false

  """
  @spec remove_bridge(timeline(), Bridge.id()) :: timeline()
  def remove_bridge(timeline, bridge_id) do
    %{timeline | bridges: Map.delete(timeline.bridges, bridge_id)}
  end

  @doc """
  Gets a bridge by ID.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)
      iex> retrieved_bridge = AriaEngine.Timeline.Bridges.get_bridge(timeline_with_bridge, "decision_1")
      iex> retrieved_bridge.id
      "decision_1"

  """
  @spec get_bridge(timeline(), Bridge.id()) :: Bridge.t() | nil
  def get_bridge(timeline, bridge_id) do
    timeline.bridges[bridge_id]
  end

  @doc """
  Gets all bridges in the timeline, sorted by position.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = AriaEngine.Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = AriaEngine.Timeline.Bridge.new("b2", pos2, :condition)
      iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge2) |> AriaEngine.Timeline.Bridges.add_bridge(bridge1)
      iex> [first, _second] = AriaEngine.Timeline.Bridges.get_bridges(timeline)
      iex> first.id
      "b1"

  """
  @spec get_bridges(timeline()) :: [Bridge.t()]
  def get_bridges(timeline) do
    timeline.bridges
    |> Map.values()
    |> Bridge.sort_by_position()
  end

  @doc """
  Updates a bridge in the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)
      iex> updated_bridge = AriaEngine.Timeline.Bridge.update_metadata(bridge, %{priority: :high})
      iex> updated_timeline = AriaEngine.Timeline.Bridges.update_bridge(timeline_with_bridge, updated_bridge)
      iex> retrieved_bridge = AriaEngine.Timeline.Bridges.get_bridge(updated_timeline, "decision_1")
      iex> retrieved_bridge.metadata.priority
      :high

  """
  @spec update_bridge(timeline(), Bridge.t()) :: timeline()
  def update_bridge(timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge, true) do
      :ok -> %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Gets the temporal positions of all bridges in the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = AriaEngine.Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = AriaEngine.Timeline.Bridge.new("b2", pos2, :condition)
      iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge1) |> AriaEngine.Timeline.Bridges.add_bridge(bridge2)
      iex> positions = AriaEngine.Timeline.Bridges.bridge_positions(timeline)
      iex> length(positions)
      2

  """
  @spec bridge_positions(timeline()) :: [DateTime.t()]
  def bridge_positions(timeline) do
    timeline
    |> get_bridges()
    |> Enum.map(& &1.position)
  end

  @doc """
  Validates that a bridge can be placed at the specified position.

  Checks that the bridge position doesn't conflict with existing intervals
  or create temporal inconsistencies.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> AriaEngine.Timeline.Bridges.validate_bridge_placement(timeline, bridge)
      :ok

  """
  @spec validate_bridge_placement(timeline(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(timeline, %Bridge{} = bridge) do
    validate_bridge_placement(timeline, bridge, false)
  end

  @doc """
  Validates that a bridge can be placed at the specified position.

  The `allow_existing` parameter controls whether to allow updating an existing bridge ID.
  """
  @spec validate_bridge_placement(timeline(), Bridge.t(), boolean()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(timeline, %Bridge{} = bridge, allow_existing) do
    # Check for duplicate bridge IDs only if not allowing existing
    case {Map.has_key?(timeline.bridges, bridge.id), allow_existing} do
      {true, false} ->
        {:error, "Bridge with ID '#{bridge.id}' already exists"}

      _ ->
        # Check for temporal conflicts with intervals
        validate_bridge_temporal_placement(timeline, bridge)
    end
  end

  @doc """
  Finds bridges within a specific time range.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> bridge1 = AriaEngine.Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = AriaEngine.Timeline.Bridge.new("b2", pos2, :decision)
      iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge1) |> AriaEngine.Timeline.Bridges.add_bridge(bridge2)
      iex> bridges = AriaEngine.Timeline.Bridges.bridges_in_range(timeline, start_time, end_time)
      iex> length(bridges)
      1

  """
  @spec bridges_in_range(timeline(), DateTime.t(), DateTime.t()) :: [Bridge.t()]
  def bridges_in_range(timeline, start_time, end_time) do
    timeline
    |> get_bridges()
    |> Bridge.in_range(start_time, end_time)
  end

  @doc """
  Validate all bridge placements in the timeline.

  Returns :ok if all bridges are valid, or {:error, reason} if any are invalid.
  """
  @spec validate_all_bridge_placements(timeline()) :: :ok | {:error, String.t()}
  def validate_all_bridge_placements(timeline) do
    timeline.bridges
    |> Map.values()
    |> Enum.reduce_while(:ok, fn bridge, _acc ->
      case validate_bridge_placement(timeline, bridge, true) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Private helper functions

  defp validate_bridge_placement!(timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp validate_bridge_temporal_placement(timeline, %Bridge{} = bridge) do
    # Check if bridge position conflicts with any intervals
    conflicts =
      timeline.intervals
      |> Map.values()
      |> Enum.filter(fn interval ->
        # Bridge should not be placed exactly at interval start or end times
        # to avoid ambiguity in segmentation
        DateTime.compare(bridge.position, interval.start_time) == :eq or
        DateTime.compare(bridge.position, interval.end_time) == :eq
      end)

    case conflicts do
      [] -> :ok
      [conflict | _] ->
        {:error, "Bridge position conflicts with interval '#{conflict.id}' boundary"}
    end
  end
end
