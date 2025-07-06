# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Bridge do
  @type semantic_position ::
          :starts
          | :finishes
          | :meets
          | :met_by
          | :during
          | :contains
          | :overlaps
          | :overlapped_by
          | :before
          | :after
          | :equals

  @type position :: DateTime.t() | String.t() | semantic_position()

  @type t :: %__MODULE__{
          id: String.t(),
          position: position(),
          type: :decision | :condition | :synchronization | :resource_check | :auto_generated,
          metadata: map(),
          # New fields for semantic bridges:
          semantic_relation: semantic_position() | nil,

          # Timeline ID or interval ID
          reference_target: String.t() | nil,

          # Calculated absolute position
          computed_position: DateTime.t() | nil
        }
  @type id :: String.t()

  defstruct [
    :id,
    :position,
    :type,
    :metadata,
    :semantic_relation,
    :reference_target,
    :computed_position
  ]

  @moduledoc """
  Bridge layer for temporal relations classification and STN constraint generation.

  This module serves as the critical bridge between high-level temporal specifications
  and the STN solver, implementing the temporal relations system described in ADR-152.

  ## Core Responsibilities

  - **Temporal Relation Classification**: Identifies and categorizes temporal relationships
  - **STN Constraint Generation**: Converts temporal relations to valid STN constraints
  - **Contract Violation Prevention**: Filters invalid specifications before STN processing
  - **Language-Neutral Relations**: Supports internationalization with standardized codes
  - **Bridge Management**: Creates, validates, and manages timeline bridges

  ## Temporal Relations Supported

  ### Allen's 13 Core Relations (Language-Neutral Codes)
  - Point Relations: `EQ` (=), `ADJ_F` (→), `ADJ_B` (←)
  - Containment: `WITHIN` (⊂), `CONTAINS` (⊃), `START_ALIGN` (⊢), `START_EXTEND` (⊢→), `END_ALIGN` (⊣), `END_EXTEND` (←⊣)
  - Overlap: `OVERLAP_F` (⟩⟨), `OVERLAP_B` (⟨⟩)
  - Separation: `PRECEDES` (<), `FOLLOWS` (>)

  ### Contract Violation Prevention

  The Bridge layer prevents zero-duration and other invalid specifications from reaching
  the STN solver, which expects positive duration constraints for temporal reasoning.

  ## Examples

      iex> alias Timeline.{Interval, Bridge}
      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Interval.new(start_dt, end_dt)
      iex> interval2 = Interval.new(end_dt, DateTime.add(end_dt, 3600, :second))
      iex> Bridge.classify_relation(interval1, interval2)
      :ADJ_F

  """

  alias Timeline.Interval
  alias Timeline.Internal.STN
  alias Timeline.Bridge.{Relations, Constraints, Management, Queries}

  @type relation_code :: Relations.relation_code()
  @type temporal_constraint :: Constraints.temporal_constraint()
  @type constraint_result :: Constraints.constraint_result()
  @type bridge_type ::
          :decision | :condition | :synchronization | :resource_check | :auto_generated

  # ==================== BRIDGE MANAGEMENT FUNCTIONS ====================

  @doc """
  Creates a new bridge with the specified parameters.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `position` - DateTime when the bridge occurs (must have timezone), ISO 8601 string, or semantic position
  - `type` - Type of bridge operation
  - `opts` - Additional options including metadata

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> bridge.id
      "decision_1"

      iex> bridge = Timeline.Bridge.new("decision_1", "2025-01-01T12:00:00Z", :decision)
      iex> bridge.id
      "decision_1"

      iex> bridge = Timeline.Bridge.new("semantic_1", :starts, :decision)
      iex> bridge.semantic_relation
      :starts

  """
  @spec new(id(), DateTime.t() | String.t() | semantic_position(), bridge_type(), keyword()) ::
          t()
  defdelegate new(id, position, type, opts \\ []), to: Management

  @doc """
  Creates a new semantic bridge with explicit reference target.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `semantic_relation` - Allen-style semantic position
  - `reference_target` - What the bridge is positioned relative to ("timeline" or interval ID)
  - `type` - Type of bridge operation
  - `opts` - Additional options including metadata

  ## Examples

      iex> bridge = Timeline.Bridge.new_semantic("start_check", :starts, "timeline", :decision)
      iex> bridge.semantic_relation
      :starts

      iex> bridge = Timeline.Bridge.new_semantic("task_end", :finishes, "task_interval_1", :synchronization)
      iex> bridge.reference_target
      "task_interval_1"

  """
  @spec new_semantic(id(), semantic_position(), String.t(), bridge_type(), keyword()) :: t()
  defdelegate new_semantic(id, semantic_relation, reference_target, type, opts \\ []), to: Management

  @doc """
  Checks if a bridge type is valid.

  ## Examples

      iex> Timeline.Bridge.valid_type?(:decision)
      true
      iex> Timeline.Bridge.valid_type?(:invalid)
      false

  """
  @spec valid_type?(bridge_type()) :: boolean()
  defdelegate valid_type?(type), to: Management

  @doc """
  Checks if a bridge is a decision point.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> Timeline.Bridge.decision?(bridge)
      true

  """
  @spec decision?(t()) :: boolean()
  defdelegate decision?(bridge), to: Management

  @doc """
  Checks if a bridge is a condition point.
  """
  @spec condition?(t()) :: boolean()
  defdelegate condition?(bridge), to: Management

  @doc """
  Checks if a bridge is a synchronization point.
  """
  @spec synchronization?(t()) :: boolean()
  defdelegate synchronization?(bridge), to: Management

  @doc """
  Checks if a bridge is a resource check point.
  """
  @spec resource_check?(t()) :: boolean()
  defdelegate resource_check?(bridge), to: Management

  @doc """
  Updates the metadata of a bridge.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> updated = Timeline.Bridge.update_metadata(bridge, %{priority: :high})
      iex> updated.metadata.priority
      :high

  """
  @spec update_metadata(t(), map()) :: t()
  defdelegate update_metadata(bridge, metadata), to: Management

  @doc """
  Checks if a bridge occurs before a given time.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> Timeline.Bridge.before?(bridge, check_time)
      true

  """
  @spec before?(t(), DateTime.t() | String.t()) :: boolean()
  defdelegate before?(bridge, time), to: Queries

  @doc """
  Checks if a bridge occurs after a given time.
  """
  @spec after?(t(), DateTime.t() | String.t()) :: boolean()
  defdelegate after?(bridge, time), to: Queries

  @doc """
  Checks if a bridge occurs at exactly the given time.
  """
  @spec at?(t(), DateTime.t() | String.t()) :: boolean()
  defdelegate at?(bridge, time), to: Queries

  @doc """
  Sorts a list of bridges by their temporal position.

  ## Examples

      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> [first, _second] = Timeline.Bridge.sort_by_position([bridge2, bridge1])
      iex> first.id
      "b1"

  """
  @spec sort_by_position([t()]) :: [t()]
  defdelegate sort_by_position(bridges), to: Queries

  @doc """
  Filters bridges to those within a time range.

  ## Examples

      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :decision)
      iex> bridges = Timeline.Bridge.in_range([bridge1, bridge2], start_time, end_time)
      iex> length(bridges)
      1

  """
  @spec in_range([t()], DateTime.t() | String.t(), DateTime.t() | String.t()) :: [t()]
  defdelegate in_range(bridges, start_time, end_time), to: Queries

  # ==================== TEMPORAL RELATIONS FUNCTIONS ====================

  @doc """
  Classifies the temporal relationship between two intervals using language-neutral codes.

  Returns standardized relation codes that can be internationalized while maintaining
  consistent temporal reasoning semantics.

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> interval2 = Timeline.Interval.new(start2, end2)
      iex> Timeline.Bridge.classify_relation(interval1, interval2)
      :ADJ_F

  """
  @spec classify_relation(Interval.t(), Interval.t()) :: relation_code()
  defdelegate classify_relation(interval1, interval2), to: Relations

  @doc """
  Generates STN constraints for a temporal relation between two intervals.

  This function implements the core Bridge layer functionality, converting high-level
  temporal relations into valid STN constraints while preventing contract violations.

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> interval2 = Timeline.Interval.new(start2, end2)
      iex> {:ok, constraint} = Timeline.Bridge.generate_stn_constraint(interval1, interval2, :second)
      iex> constraint
      {-1, 1}

  """
  @spec generate_stn_constraint(Interval.t(), Interval.t(), STN.time_unit()) ::
          constraint_result()
  defdelegate generate_stn_constraint(interval1, interval2, time_unit), to: Constraints

  @doc """
  Validates that an interval meets STN contract requirements.

  Prevents zero-duration and other invalid specifications from reaching the STN solver.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> Timeline.Bridge.validate_interval_for_stn(interval, :second)
      :ok

  """
  @spec validate_interval_for_stn(Interval.t(), STN.time_unit()) :: :ok | {:error, atom()}
  defdelegate validate_interval_for_stn(interval, time_unit), to: Constraints

  @doc """
  Filters a list of intervals to remove those that would cause STN contract violations.

  Returns only intervals that can be safely processed by the STN solver.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> valid_interval = Timeline.Interval.new(start_dt, end_dt)
      iex> zero_interval = Timeline.Interval.new(start_dt, start_dt)
      iex> Timeline.Bridge.filter_valid_intervals([valid_interval, zero_interval], :second)
      [valid_interval]

  """
  @spec filter_valid_intervals([Interval.t()], STN.time_unit()) :: [Interval.t()]
  defdelegate filter_valid_intervals(intervals, time_unit), to: Constraints

  @doc """
  Converts Allen relation symbols to language-neutral codes.

  Provides a mapping from traditional Allen relation names to standardized
  international codes that can be localized while maintaining semantic consistency.
  """
  @spec allen_to_language_neutral(atom()) :: relation_code()
  defdelegate allen_to_language_neutral(relation), to: Relations

  @doc """
  Gets the human-readable description for a relation code.

  Supports internationalization by providing a base description that can be
  localized while maintaining the standardized relation code.
  """
  @spec relation_description(relation_code()) :: String.t()
  defdelegate relation_description(relation_code), to: Relations

end
