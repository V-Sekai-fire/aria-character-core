# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.Bridge do
  @moduledoc """
  Represents a bridge point in a Timeline where execution can pause, make decisions, or branch.

  Bridges are temporal points that create segmentation boundaries in timelines,
  allowing for decision points, conditional execution, resource synchronization,
  and other control flow operations within temporal planning.

  All bridge positions use DateTime with timezone information to maintain
  consistency with the Timeline system's temporal model.

  ## Bridge Types

  - `:decision` - Decision points where execution can branch based on conditions
  - `:condition` - Conditional checks that may block or redirect execution
  - `:synchronization` - Points where multiple timelines must synchronize
  - `:resource_check` - Resource availability validation points

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("route_decision",
      ...>   DateTime.utc_now(),
      ...>   :decision,
      ...>   metadata: %{options: ["north", "south"]}
      ...> )
      iex> bridge.type
      :decision

  """

  @type id :: String.t()
  @type bridge_type :: :decision | :condition | :synchronization | :resource_check
  @type t :: %__MODULE__{
          id: id(),
          position: DateTime.t(),
          type: bridge_type(),
          metadata: map()
        }

  defstruct id: nil,
            position: nil,
            type: :decision,
            metadata: %{}

  @doc """
  Creates a new bridge with the specified parameters.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `position` - DateTime when the bridge occurs (must have timezone)
  - `type` - Type of bridge operation
  - `opts` - Additional options including metadata

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> bridge.id
      "decision_1"

  """
  @spec new(id(), DateTime.t(), bridge_type(), keyword()) :: t()
  def new(id, %DateTime{} = position, type, opts \\ []) do
    validate_bridge_type!(type)
    metadata = Keyword.get(opts, :metadata, %{})

    %__MODULE__{
      id: id,
      position: position,
      type: type,
      metadata: metadata
    }
  end

  @doc """
  Validates that a bridge type is supported.

  ## Examples

      iex> AriaEngine.Timeline.Bridge.valid_type?(:decision)
      true

      iex> AriaEngine.Timeline.Bridge.valid_type?(:invalid)
      false

  """
  @spec valid_type?(atom()) :: boolean()
  def valid_type?(type) do
    type in [:decision, :condition, :synchronization, :resource_check]
  end

  @doc """
  Checks if a bridge is a decision point.

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("test", DateTime.utc_now(), :decision)
      iex> AriaEngine.Timeline.Bridge.decision?(bridge)
      true

  """
  @spec decision?(t()) :: boolean()
  def decision?(%__MODULE__{type: :decision}), do: true
  def decision?(%__MODULE__{}), do: false

  @doc """
  Checks if a bridge is a condition check.

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("test", DateTime.utc_now(), :condition)
      iex> AriaEngine.Timeline.Bridge.condition?(bridge)
      true

  """
  @spec condition?(t()) :: boolean()
  def condition?(%__MODULE__{type: :condition}), do: true
  def condition?(%__MODULE__{}), do: false

  @doc """
  Checks if a bridge is a synchronization point.

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("test", DateTime.utc_now(), :synchronization)
      iex> AriaEngine.Timeline.Bridge.synchronization?(bridge)
      true

  """
  @spec synchronization?(t()) :: boolean()
  def synchronization?(%__MODULE__{type: :synchronization}), do: true
  def synchronization?(%__MODULE__{}), do: false

  @doc """
  Checks if a bridge is a resource check point.

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("test", DateTime.utc_now(), :resource_check)
      iex> AriaEngine.Timeline.Bridge.resource_check?(bridge)
      true

  """
  @spec resource_check?(t()) :: boolean()
  def resource_check?(%__MODULE__{type: :resource_check}), do: true
  def resource_check?(%__MODULE__{}), do: false

  @doc """
  Updates bridge metadata.

  ## Examples

      iex> bridge = AriaEngine.Timeline.Bridge.new("test", DateTime.utc_now(), :decision)
      iex> updated = AriaEngine.Timeline.Bridge.update_metadata(bridge, %{priority: :high})
      iex> updated.metadata.priority
      :high

  """
  @spec update_metadata(t(), map()) :: t()
  def update_metadata(%__MODULE__{} = bridge, new_metadata) do
    %{bridge | metadata: Map.merge(bridge.metadata, new_metadata)}
  end

  @doc """
  Checks if a bridge occurs before a given DateTime.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("test", position, :decision)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> AriaEngine.Timeline.Bridge.before?(bridge, check_time)
      true

  """
  @spec before?(t(), DateTime.t()) :: boolean()
  def before?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :lt
  end

  @doc """
  Checks if a bridge occurs after a given DateTime.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("test", position, :decision)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> AriaEngine.Timeline.Bridge.after?(bridge, check_time)
      true

  """
  @spec after?(t(), DateTime.t()) :: boolean()
  def after?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :gt
  end

  @doc """
  Checks if a bridge occurs at exactly the given DateTime.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("test", position, :decision)
      iex> AriaEngine.Timeline.Bridge.at?(bridge, position)
      true

  """
  @spec at?(t(), DateTime.t()) :: boolean()
  def at?(%__MODULE__{position: position}, %DateTime{} = check_time) do
    DateTime.compare(position, check_time) == :eq
  end

  @doc """
  Sorts bridges by their temporal position.

  ## Examples

      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = AriaEngine.Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = AriaEngine.Timeline.Bridge.new("b2", pos2, :decision)
      iex> [sorted1, _sorted2] = AriaEngine.Timeline.Bridge.sort_by_position([bridge2, bridge1])
      iex> sorted1.id
      "b1"

  """
  @spec sort_by_position([t()]) :: [t()]
  def sort_by_position(bridges) when is_list(bridges) do
    Enum.sort(bridges, fn bridge1, bridge2 ->
      DateTime.compare(bridge1.position, bridge2.position) != :gt
    end)
  end

  @doc """
  Finds bridges within a time range.

  ## Examples

      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> bridge1 = AriaEngine.Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = AriaEngine.Timeline.Bridge.new("b2", pos2, :decision)
      iex> bridges = AriaEngine.Timeline.Bridge.in_range([bridge1, bridge2], start_time, end_time)
      iex> length(bridges)
      1

  """
  @spec in_range([t()], DateTime.t(), DateTime.t()) :: [t()]
  def in_range(bridges, %DateTime{} = start_time, %DateTime{} = end_time) when is_list(bridges) do
    Enum.filter(bridges, fn bridge ->
      DateTime.compare(bridge.position, start_time) != :lt and
        DateTime.compare(bridge.position, end_time) != :gt
    end)
  end

  # Private helper functions

  defp validate_bridge_type!(type) do
    unless valid_type?(type) do
      raise ArgumentError,
            "Invalid bridge type: #{inspect(type)}. Must be one of: :decision, :condition, :synchronization, :resource_check"
    end
  end
end
