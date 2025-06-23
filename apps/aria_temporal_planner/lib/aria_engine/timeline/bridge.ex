# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.Bridge do
  @moduledoc "Bridge structure for Timeline segmentation and decision points.\n\nBridges represent temporal markers that can be used to segment timelines\nfor analysis, execution, or decision-making. They mark specific points\nin time where important events, decisions, or state changes occur.\n\n## Bridge Types\n\n- `:decision` - Decision points requiring user or system input\n- `:condition` - Conditional branches based on state evaluation\n- `:synchronization` - Synchronization points for parallel processes\n- `:resource_check` - Resource availability validation points\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> bridge.id\n    \"decision_1\"\n\n"

  @type id :: String.t()
  @type bridge_type :: :decision | :condition | :synchronization | :resource_check
  @type t :: %__MODULE__{
          id: id(),
          position: DateTime.t(),
          type: bridge_type(),
          metadata: map()
        }

  defstruct id: nil, position: nil, type: nil, metadata: %{}

  @valid_types [:decision, :condition, :synchronization, :resource_check]

  @doc "Creates a new bridge with the specified parameters.\n\n## Parameters\n\n- `id` - Unique identifier for the bridge\n- `position` - DateTime when the bridge occurs (must have timezone) or ISO 8601 string\n- `type` - Type of bridge operation\n- `opts` - Additional options including metadata\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> bridge.id\n    \"decision_1\"\n\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", \"2025-01-01T12:00:00Z\", :decision)\n    iex> bridge.id\n    \"decision_1\"\n\n"
  @spec new(id(), DateTime.t() | String.t(), bridge_type(), keyword()) :: t()
  def new(id, position, type, opts \\ [])

  def new(id, %DateTime{} = position, type, opts) do
    validate_bridge_type!(type)
    metadata = Keyword.get(opts, :metadata, %{})
    %__MODULE__{id: id, position: position, type: type, metadata: metadata}
  end

  def new(id, position, type, opts) when is_binary(position) do
    {:ok, datetime, _} = DateTime.from_iso8601(position)
    new(id, datetime, type, opts)
  end

  @doc "Checks if a bridge type is valid.\n\n## Examples\n\n    iex> AriaEngine.Timeline.Bridge.valid_type?(:decision)\n    true\n    iex> AriaEngine.Timeline.Bridge.valid_type?(:invalid)\n    false\n\n"
  @spec valid_type?(bridge_type()) :: boolean()
  def valid_type?(type) do
    type in @valid_types
  end

  @doc "Checks if a bridge is a decision point.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> AriaEngine.Timeline.Bridge.decision?(bridge)\n    true\n\n"
  @spec decision?(t()) :: boolean()
  def decision?(%__MODULE__{type: :decision}), do: true
  def decision?(_), do: false

  @doc "Checks if a bridge is a condition point.\n"
  @spec condition?(t()) :: boolean()
  def condition?(%__MODULE__{type: :condition}), do: true
  def condition?(_), do: false

  @doc "Checks if a bridge is a synchronization point.\n"
  @spec synchronization?(t()) :: boolean()
  def synchronization?(%__MODULE__{type: :synchronization}), do: true
  def synchronization?(_), do: false

  @doc "Checks if a bridge is a resource check point.\n"
  @spec resource_check?(t()) :: boolean()
  def resource_check?(%__MODULE__{type: :resource_check}), do: true
  def resource_check?(_), do: false

  @doc "Updates the metadata of a bridge.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> updated = AriaEngine.Timeline.Bridge.update_metadata(bridge, %{priority: :high})\n    iex> updated.metadata.priority\n    :high\n\n"
  @spec update_metadata(t(), map()) :: t()
  def update_metadata(%__MODULE__{} = bridge, metadata) when is_map(metadata) do
    %{bridge | metadata: Map.merge(bridge.metadata, metadata)}
  end

  @doc "Checks if a bridge occurs before a given time.\n\n## Examples\n\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> check_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], \"Etc/UTC\")\n    iex> AriaEngine.Timeline.Bridge.before?(bridge, check_time)\n    true\n\n"
  @spec before?(t(), DateTime.t() | String.t()) :: boolean()
  def before?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :lt
  end

  @doc "Checks if a bridge occurs after a given time.\n"
  @spec after?(t(), DateTime.t() | String.t()) :: boolean()
  def after?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :gt
  end

  @doc "Checks if a bridge occurs at exactly the given time.\n"
  @spec at?(t(), DateTime.t() | String.t()) :: boolean()
  def at?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :eq
  end

  @doc "Sorts a list of bridges by their temporal position.\n\n## Examples\n\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :condition)\n    iex> [first, _second] = AriaEngine.Timeline.Bridge.sort_by_position([bridge2, bridge1])\n    iex> first.id\n    \"b1\"\n\n"
  @spec sort_by_position([t()]) :: [t()]
  def sort_by_position(bridges) when is_list(bridges) do
    Enum.sort_by(bridges, & &1.position, DateTime)
  end

  @doc "Filters bridges to those within a time range.\n\n## Examples\n\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], \"Etc/UTC\")\n    iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], \"Etc/UTC\")\n    iex> bridge1 = AriaEngine.Timeline.Bridge.new(\"b1\", pos1, :decision)\n    iex> bridge2 = AriaEngine.Timeline.Bridge.new(\"b2\", pos2, :decision)\n    iex> bridges = AriaEngine.Timeline.Bridge.in_range([bridge1, bridge2], start_time, end_time)\n    iex> length(bridges)\n    1\n\n"
  @spec in_range([t()], DateTime.t() | String.t(), DateTime.t() | String.t()) :: [t()]
  def in_range(bridges, start_time, end_time) when is_list(bridges) do
    start_dt = parse_datetime(start_time)
    end_dt = parse_datetime(end_time)

    Enum.filter(bridges, fn bridge ->
      DateTime.compare(bridge.position, start_dt) != :lt and
      DateTime.compare(bridge.position, end_dt) != :gt
    end)
  end

  defp validate_bridge_type!(type) do
    unless valid_type?(type) do
      raise ArgumentError, "Invalid bridge type: #{inspect(type)}. Valid types: #{inspect(@valid_types)}"
    end
  end

  defp parse_datetime(%DateTime{} = datetime), do: datetime
  defp parse_datetime(iso8601_string) when is_binary(iso8601_string) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
    datetime
  end
end
