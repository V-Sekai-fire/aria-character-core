# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.BridgeOperations do
  @moduledoc "Bridge management functionality for Timeline segmentation and decision points.\n\nThis module handles:\n- Bridge CRUD operations\n- Bridge validation and placement\n- Bridge querying and filtering\n- Bridge positioning and sorting\n\nBridges represent decision points, synchronization points, or other temporal\nmarkers that can be used to segment timelines for analysis or execution.\n"
  alias Timeline.Bridge
  alias Timeline.Interval

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: any(),
          metadata: map()
        }
  @doc "Adds a bridge to the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> updated_timeline = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)\n    iex> Map.has_key?(updated_timeline.bridges, \"decision_1\")\n    true\n\n"
  @spec add_bridge(timeline(), Bridge.t()) :: timeline()
  def add_bridge(timeline, %Bridge{} = bridge) do
    validate_bridge_placement!(timeline, bridge)
    %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
  end

  @doc "Removes a bridge from the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)\n    iex> updated_timeline = AriaEngine.Timeline.Bridges.remove_bridge(timeline_with_bridge, \"decision_1\")\n    iex> Map.has_key?(updated_timeline.bridges, \"decision_1\")\n    false\n\n"
  @spec remove_bridge(timeline(), Bridge.id()) :: timeline()
  def remove_bridge(timeline, bridge_id) do
    %{timeline | bridges: Map.delete(timeline.bridges, bridge_id)}
  end

  @doc "Gets a bridge by ID.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)\n    iex> retrieved_bridge = AriaEngine.Timeline.Bridges.get_bridge(timeline_with_bridge, \"decision_1\")\n    iex> retrieved_bridge.id\n    \"decision_1\"\n\n"
  @spec get_bridge(timeline(), Bridge.id()) :: Bridge.t() | nil
  def get_bridge(timeline, bridge_id) do
    timeline.bridges[bridge_id]
  end

  @doc "Gets all bridges in the timeline, sorted by position.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :condition)\n    iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge2) |> AriaEngine.Timeline.Bridges.add_bridge(bridge1)\n    iex> [first, _second] = AriaEngine.Timeline.Bridges.get_bridges(timeline)\n    iex> first.id\n    \"b1\"\n\n"
  @spec get_bridges(timeline()) :: [Bridge.t()]
  def get_bridges(timeline) do
    timeline.bridges |> Map.values() |> Bridge.sort_by_position()
  end

  @doc "Updates a bridge in the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> timeline_with_bridge = AriaEngine.Timeline.Bridges.add_bridge(timeline, bridge)\n    iex> updated_bridge = AriaEngine.Timeline.Bridge.update_metadata(bridge, %{priority: :high})\n    iex> updated_timeline = AriaEngine.Timeline.Bridges.update_bridge(timeline_with_bridge, updated_bridge)\n    iex> retrieved_bridge = AriaEngine.Timeline.Bridges.get_bridge(updated_timeline, \"decision_1\")\n    iex> retrieved_bridge.metadata.priority\n    :high\n\n"
  @spec update_bridge(timeline(), Bridge.t()) :: timeline()
  def update_bridge(timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge, true) do
      :ok -> %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc "Gets the temporal positions of all bridges in the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :condition)\n    iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge1) |> AriaEngine.Timeline.Bridges.add_bridge(bridge2)\n    iex> positions = AriaEngine.Timeline.Bridges.bridge_positions(timeline)\n    iex> length(positions)\n    2\n\n"
  @spec bridge_positions(timeline()) :: [DateTime.t()]
  def bridge_positions(timeline) do
    timeline |> get_bridges() |> Enum.map(& &1.position)
  end

  @doc "Validates that a bridge can be placed at the specified position.\n\nChecks that the bridge position doesn't conflict with existing intervals\nor create temporal inconsistencies.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> AriaEngine.Timeline.Bridges.validate_bridge_placement(timeline, bridge)\n    :ok\n\n"
  @spec validate_bridge_placement(timeline(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(timeline, %Bridge{} = bridge) do
    validate_bridge_placement(timeline, bridge, false)
  end

  @doc "Validates that a bridge can be placed at the specified position.\n\nThe `allow_existing` parameter controls whether to allow updating an existing bridge ID.\n"
  @spec validate_bridge_placement(timeline(), Bridge.t(), boolean()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(timeline, %Bridge{} = bridge, allow_existing) do
    case {Map.has_key?(timeline.bridges, bridge.id), allow_existing} do
      {true, false} -> {:error, "Bridge with ID '#{bridge.id}' already exists"}
      _ -> validate_bridge_temporal_placement(timeline, bridge)
    end
  end

  @doc "Finds bridges within a specific time range.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], \"Etc/UTC\")\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :decision)\n    iex> timeline = timeline |> AriaEngine.Timeline.Bridges.add_bridge(bridge1) |> AriaEngine.Timeline.Bridges.add_bridge(bridge2)\n    iex> bridges = AriaEngine.Timeline.Bridges.bridges_in_range(timeline, start_time, end_time)\n    iex> length(bridges)\n    1\n\n"
  @spec bridges_in_range(timeline(), DateTime.t(), DateTime.t()) :: [Bridge.t()]
  def bridges_in_range(timeline, start_time, end_time) do
    timeline |> get_bridges() |> Bridge.in_range(start_time, end_time)
  end

  @doc "Validate all bridge placements in the timeline.\n\nReturns :ok if all bridges are valid, or {:error, reason} if any are invalid.\n"
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

  defp validate_bridge_placement!(timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp validate_bridge_temporal_placement(timeline, %Bridge{} = bridge) do
    conflicts =
      timeline.intervals
      |> Map.values()
      |> Enum.filter(fn interval ->
        DateTime.compare(bridge.position, interval.start_time) == :eq or
          DateTime.compare(bridge.position, interval.end_time) == :eq
      end)

    case conflicts do
      [] ->
        :ok

      [conflict | _] ->
        {:error, "Bridge position conflicts with interval '#{conflict.id}' boundary"}
    end
  end
end
