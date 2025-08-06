# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Bridge.Management do
  @moduledoc """
  Bridge management functions for creating, validating, and updating timeline bridges.

  This module handles the core lifecycle operations for timeline bridges including
  creation with various position types, validation, and metadata management.
  """

  alias Timeline.Bridge

  @type semantic_position :: Bridge.semantic_position()
  @type bridge_type :: Bridge.bridge_type()
  @type id :: Bridge.id()

  @valid_types [:decision, :condition, :synchronization, :resource_check, :auto_generated]

  @doc """
  Creates a new bridge with the specified parameters.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `position` - DateTime when the bridge occurs (must have timezone), ISO 8601 string, or semantic position
  - `type` - Type of bridge operation
  - `opts` - Additional options including metadata

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.Management.new("decision_1", position, :decision)
      iex> bridge.id
      "decision_1"

      iex> bridge = Timeline.Bridge.Management.new("decision_1", "2025-01-01T12:00:00Z", :decision)
      iex> bridge.id
      "decision_1"

      iex> bridge = Timeline.Bridge.Management.new("semantic_1", :starts, :decision)
      iex> bridge.semantic_relation
      :starts

  """
  @spec new(id(), DateTime.t() | String.t() | semantic_position(), bridge_type(), keyword()) ::
          Bridge.t()
  def new(id, position, type, opts \\ [])

  def new(id, %DateTime{} = position, type, opts) do
    validate_bridge_type!(type)
    metadata = Keyword.get(opts, :metadata, %{})
    %Bridge{id: id, position: position, type: type, metadata: metadata}
  end

  def new(id, position, type, opts) when is_binary(position) do
    {:ok, datetime, _} = DateTime.from_iso8601(position)
    new(id, datetime, type, opts)
  end

  def new(id, position, type, opts) when is_atom(position) do
    validate_bridge_type!(type)
    validate_semantic_position!(position)
    metadata = Keyword.get(opts, :metadata, %{})
    reference_target = Keyword.get(opts, :reference_target, "timeline")

    %Bridge{
      id: id,
      position: position,
      type: type,
      metadata: metadata,
      semantic_relation: position,
      reference_target: reference_target
    }
  end

  @doc """
  Creates a new semantic bridge with explicit reference target.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `semantic_relation` - Allen-style semantic position
  - `reference_target` - What the bridge is positioned relative to ("timeline" or interval ID)
  - `type` - Type of bridge operation
  - `opts` - Additional options including metadata

  ## Examples

      iex> bridge = Timeline.Bridge.Management.new_semantic("start_check", :starts, "timeline", :decision)
      iex> bridge.semantic_relation
      :starts

      iex> bridge = Timeline.Bridge.Management.new_semantic("task_end", :finishes, "task_interval_1", :synchronization)
      iex> bridge.reference_target
      "task_interval_1"

  """
  @spec new_semantic(id(), semantic_position(), String.t(), bridge_type(), keyword()) :: Bridge.t()
  def new_semantic(id, semantic_relation, reference_target, type, opts \\ []) do
    validate_bridge_type!(type)
    validate_semantic_position!(semantic_relation)
    metadata = Keyword.get(opts, :metadata, %{})

    %Bridge{
      id: id,
      position: semantic_relation,
      type: type,
      metadata: metadata,
      semantic_relation: semantic_relation,
      reference_target: reference_target
    }
  end

  @doc """
  Checks if a bridge type is valid.

  ## Examples

      iex> Timeline.Bridge.Management.valid_type?(:decision)
      true
      iex> Timeline.Bridge.Management.valid_type?(:invalid)
      false

  """
  @spec valid_type?(bridge_type()) :: boolean()
  def valid_type?(type) do
    type in @valid_types
  end

  @doc """
  Checks if a bridge is a decision point.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.Management.new("decision_1", position, :decision)
      iex> Timeline.Bridge.Management.decision?(bridge)
      true

  """
  @spec decision?(Bridge.t()) :: boolean()
  def decision?(%Bridge{type: :decision}), do: true
  def decision?(_), do: false

  @doc """
  Checks if a bridge is a condition point.
  """
  @spec condition?(Bridge.t()) :: boolean()
  def condition?(%Bridge{type: :condition}), do: true
  def condition?(_), do: false

  @doc """
  Checks if a bridge is a synchronization point.
  """
  @spec synchronization?(Bridge.t()) :: boolean()
  def synchronization?(%Bridge{type: :synchronization}), do: true
  def synchronization?(_), do: false

  @doc """
  Checks if a bridge is a resource check point.
  """
  @spec resource_check?(Bridge.t()) :: boolean()
  def resource_check?(%Bridge{type: :resource_check}), do: true
  def resource_check?(_), do: false

  @doc """
  Updates the metadata of a bridge.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.Management.new("decision_1", position, :decision)
      iex> updated = Timeline.Bridge.Management.update_metadata(bridge, %{priority: :high})
      iex> updated.metadata.priority
      :high

  """
  @spec update_metadata(Bridge.t(), map()) :: Bridge.t()
  def update_metadata(%Bridge{} = bridge, metadata) when is_map(metadata) do
    %{bridge | metadata: Map.merge(bridge.metadata, metadata)}
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  defp validate_bridge_type!(type) do
    unless valid_type?(type) do
      raise ArgumentError,
            "Invalid bridge type: #{inspect(type)}. Valid types: #{inspect(@valid_types)}"
    end
  end

  defp validate_semantic_position!(position) do
    valid_positions = [
      :starts,
      :finishes,
      :meets,
      :met_by,
      :during,
      :contains,
      :overlaps,
      :overlapped_by,
      :before,
      :after,
      :equals
    ]

    unless position in valid_positions do
      raise ArgumentError,
            "Invalid semantic position: #{inspect(position)}. Valid positions: #{inspect(valid_positions)}"
    end
  end
end
