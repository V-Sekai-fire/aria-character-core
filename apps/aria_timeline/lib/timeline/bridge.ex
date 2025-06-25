# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Bridge do
  @type t :: %__MODULE__{
          id: String.t(),
          position: DateTime.t() | String.t(),
          type: :decision | :condition | :synchronization | :resource_check | :auto_generated,
          metadata: map()
        }
  @type id :: String.t()

  defstruct [:id, :position, :type, :metadata]

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

  @type relation_code ::
    :EQ | :ADJ_F | :ADJ_B | :WITHIN | :CONTAINS |
    :START_ALIGN | :START_EXTEND | :END_ALIGN | :END_EXTEND |
    :OVERLAP_F | :OVERLAP_B | :PRECEDES | :FOLLOWS

  @type temporal_constraint :: {number(), number()}
  @type constraint_result :: {:ok, temporal_constraint()} | {:error, atom()}
  @type bridge_type :: :decision | :condition | :synchronization | :resource_check | :auto_generated

  # Minimum duration threshold to prevent zero-duration contract violations
  @min_duration_threshold 1
  @valid_types [:decision, :condition, :synchronization, :resource_check, :auto_generated]

  # ==================== BRIDGE MANAGEMENT FUNCTIONS ====================

  @doc """
  Creates a new bridge with the specified parameters.

  ## Parameters

  - `id` - Unique identifier for the bridge
  - `position` - DateTime when the bridge occurs (must have timezone) or ISO 8601 string
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

  """
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

  @doc """
  Checks if a bridge type is valid.

  ## Examples

      iex> Timeline.Bridge.valid_type?(:decision)
      true
      iex> Timeline.Bridge.valid_type?(:invalid)
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
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> Timeline.Bridge.decision?(bridge)
      true

  """
  @spec decision?(t()) :: boolean()
  def decision?(%__MODULE__{type: :decision}), do: true
  def decision?(_), do: false

  @doc """
  Checks if a bridge is a condition point.
  """
  @spec condition?(t()) :: boolean()
  def condition?(%__MODULE__{type: :condition}), do: true
  def condition?(_), do: false

  @doc """
  Checks if a bridge is a synchronization point.
  """
  @spec synchronization?(t()) :: boolean()
  def synchronization?(%__MODULE__{type: :synchronization}), do: true
  def synchronization?(_), do: false

  @doc """
  Checks if a bridge is a resource check point.
  """
  @spec resource_check?(t()) :: boolean()
  def resource_check?(%__MODULE__{type: :resource_check}), do: true
  def resource_check?(_), do: false

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
  def update_metadata(%__MODULE__{} = bridge, metadata) when is_map(metadata) do
    %{bridge | metadata: Map.merge(bridge.metadata, metadata)}
  end

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
  def before?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :lt
  end

  @doc """
  Checks if a bridge occurs after a given time.
  """
  @spec after?(t(), DateTime.t() | String.t()) :: boolean()
  def after?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :gt
  end

  @doc """
  Checks if a bridge occurs at exactly the given time.
  """
  @spec at?(t(), DateTime.t() | String.t()) :: boolean()
  def at?(%__MODULE__{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :eq
  end

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
  def sort_by_position(bridges) when is_list(bridges) do
    Enum.sort_by(bridges, & &1.position, DateTime)
  end

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
  def in_range(bridges, start_time, end_time) when is_list(bridges) do
    start_dt = parse_datetime(start_time)
    end_dt = parse_datetime(end_time)

    Enum.filter(bridges, fn bridge ->
      DateTime.compare(bridge.position, start_dt) != :lt and
      DateTime.compare(bridge.position, end_dt) != :gt
    end)
  end

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
  def classify_relation(%Interval{} = interval1, %Interval{} = interval2) do
    allen_relation = Interval.allen_relation(interval1, interval2)
    allen_to_language_neutral(allen_relation)
  end

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
  @spec generate_stn_constraint(Interval.t(), Interval.t(), STN.time_unit()) :: constraint_result()
  def generate_stn_constraint(%Interval{} = interval1, %Interval{} = interval2, time_unit) do
    relation = classify_relation(interval1, interval2)

    # Validate intervals before constraint generation
    with :ok <- validate_interval_duration(interval1, time_unit),
         :ok <- validate_interval_duration(interval2, time_unit) do
      generate_constraint_for_relation(interval1, interval2, relation, time_unit)
    else
      {:error, reason} -> {:error, reason}
    end
  end

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
  def validate_interval_for_stn(%Interval{} = interval, time_unit) do
    validate_interval_duration(interval, time_unit)
  end

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
  def filter_valid_intervals(intervals, time_unit) when is_list(intervals) do
    Enum.filter(intervals, fn interval ->
      case validate_interval_for_stn(interval, time_unit) do
        :ok -> true
        {:error, _} -> false
      end
    end)
  end

  @doc """
  Converts Allen relation symbols to language-neutral codes.

  Provides a mapping from traditional Allen relation names to standardized
  international codes that can be localized while maintaining semantic consistency.
  """
  @spec allen_to_language_neutral(atom()) :: relation_code()
  def allen_to_language_neutral(:equals), do: :EQ
  def allen_to_language_neutral(:meets), do: :ADJ_F
  def allen_to_language_neutral(:met_by), do: :ADJ_B
  def allen_to_language_neutral(:during), do: :WITHIN
  def allen_to_language_neutral(:contains), do: :CONTAINS
  def allen_to_language_neutral(:starts), do: :START_ALIGN
  def allen_to_language_neutral(:started_by), do: :START_EXTEND
  def allen_to_language_neutral(:finishes), do: :END_ALIGN
  def allen_to_language_neutral(:finished_by), do: :END_EXTEND
  def allen_to_language_neutral(:overlaps), do: :OVERLAP_F
  def allen_to_language_neutral(:overlapped_by), do: :OVERLAP_B
  def allen_to_language_neutral(:before), do: :PRECEDES
  def allen_to_language_neutral(:after), do: :FOLLOWS
  def allen_to_language_neutral(_), do: :EQ  # Default fallback

  @doc """
  Gets the human-readable description for a relation code.

  Supports internationalization by providing a base description that can be
  localized while maintaining the standardized relation code.
  """
  @spec relation_description(relation_code()) :: String.t()
  def relation_description(:EQ), do: "Equal temporal positions"
  def relation_description(:ADJ_F), do: "Adjacent forward (meets)"
  def relation_description(:ADJ_B), do: "Adjacent backward (met by)"
  def relation_description(:WITHIN), do: "Contained within"
  def relation_description(:CONTAINS), do: "Contains other interval"
  def relation_description(:START_ALIGN), do: "Start times aligned"
  def relation_description(:START_EXTEND), do: "Starts and extends beyond"
  def relation_description(:END_ALIGN), do: "End times aligned"
  def relation_description(:END_EXTEND), do: "Extends and ends aligned"
  def relation_description(:OVERLAP_F), do: "Overlaps forward"
  def relation_description(:OVERLAP_B), do: "Overlaps backward"
  def relation_description(:PRECEDES), do: "Occurs before"
  def relation_description(:FOLLOWS), do: "Occurs after"

  # ==================== PRIVATE HELPER FUNCTIONS ====================

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

  defp validate_interval_duration(%Interval{start_time: start_time, end_time: end_time}, time_unit) do
    duration_in_unit = calculate_duration_in_unit(start_time, end_time, time_unit)

    cond do
      duration_in_unit < @min_duration_threshold ->
        {:error, :zero_duration_violation}
      duration_in_unit < 0 ->
        {:error, :negative_duration}
      true ->
        :ok
    end
  end

  defp calculate_duration_in_unit(start_time, end_time, time_unit) do
    case time_unit do
      :microsecond -> DateTime.diff(end_time, start_time, :microsecond)
      :millisecond -> DateTime.diff(end_time, start_time, :millisecond)
      :second -> DateTime.diff(end_time, start_time, :second)
      :minute -> div(DateTime.diff(end_time, start_time, :second), 60)
      :hour -> div(DateTime.diff(end_time, start_time, :second), 3600)
      :day -> div(DateTime.diff(end_time, start_time, :second), 86400)
    end
  end

  defp generate_constraint_for_relation(interval1, interval2, relation, time_unit) do
    case relation do
      :EQ ->
        # Equal intervals - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :ADJ_F ->
        # interval1 meets interval2 - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :ADJ_B ->
        # interval2 meets interval1 - convert fixed-point to micro-range
        {:ok, {-1, 1}}

      :PRECEDES ->
        # interval1 before interval2 - positive gap between them
        gap = calculate_gap_between_intervals(interval1, interval2, time_unit)
        # Convert fixed-point to micro-range
        {:ok, {max(gap - 1, 0), gap + 1}}

      :FOLLOWS ->
        # interval1 after interval2 - negative gap (interval2 before interval1)
        gap = calculate_gap_between_intervals(interval2, interval1, time_unit)
        # Convert fixed-point to micro-range
        {:ok, {-gap - 1, max(-gap + 1, 1)}}

      :OVERLAP_F ->
        # interval1 overlaps interval2 forward
        overlap = calculate_overlap_constraint(interval1, interval2, time_unit)
        {:ok, overlap}

      :OVERLAP_B ->
        # interval1 overlapped by interval2
        overlap = calculate_overlap_constraint(interval2, interval1, time_unit)
        {:ok, {-elem(overlap, 1), -elem(overlap, 0)}}

      :WITHIN ->
        # interval1 during interval2
        {:ok, generate_containment_constraint(interval1, interval2, time_unit)}

      :CONTAINS ->
        # interval1 contains interval2
        constraint = generate_containment_constraint(interval2, interval1, time_unit)
        {:ok, {-elem(constraint, 1), -elem(constraint, 0)}}

      :START_ALIGN ->
        # interval1 starts interval2 - same start, different end
        {:ok, {-1, 1}}

      :START_EXTEND ->
        # interval1 started by interval2 - same start, interval1 extends
        {:ok, {-1, 1}}

      :END_ALIGN ->
        # interval1 finishes interval2 - same end, different start
        {:ok, {-1, 1}}

      :END_EXTEND ->
        # interval1 finished by interval2 - same end, interval1 extends
        {:ok, {-1, 1}}

      _ ->
        # Default case - treat as equal
        {:ok, {-1, 1}}
    end
  end

  defp calculate_gap_between_intervals(interval1, interval2, time_unit) do
    gap_microseconds = DateTime.diff(interval2.start_time, interval1.end_time, :microsecond)
    convert_microseconds_to_unit(gap_microseconds, time_unit)
  end

  defp calculate_overlap_constraint(interval1, interval2, time_unit) do
    # Calculate the overlap duration and position
    overlap_start = max_datetime(interval1.start_time, interval2.start_time)
    overlap_end = min_datetime(interval1.end_time, interval2.end_time)

    if DateTime.compare(overlap_start, overlap_end) == :lt do
      overlap_duration = DateTime.diff(overlap_end, overlap_start, :microsecond)
      overlap_in_unit = convert_microseconds_to_unit(overlap_duration, time_unit)
      # Convert fixed-point to micro-range if needed
      if overlap_in_unit == 0 do
        {-1, 1}
      else
        {max(overlap_in_unit - 1, 0), overlap_in_unit + 1}
      end
    else
      # No overlap - convert fixed-point to micro-range
      {-1, 1}
    end
  end

  defp generate_containment_constraint(inner_interval, outer_interval, time_unit) do
    # Calculate the temporal distance from outer start to inner start
    start_offset = DateTime.diff(inner_interval.start_time, outer_interval.start_time, :microsecond)
    start_offset_in_unit = convert_microseconds_to_unit(start_offset, time_unit)

    # Calculate the temporal distance from inner end to outer end
    end_offset = DateTime.diff(outer_interval.end_time, inner_interval.end_time, :microsecond)
    end_offset_in_unit = convert_microseconds_to_unit(end_offset, time_unit)

    {start_offset_in_unit, start_offset_in_unit + end_offset_in_unit}
  end

  defp convert_microseconds_to_unit(microseconds, time_unit) do
    case time_unit do
      :microsecond -> microseconds
      :millisecond -> div(microseconds, 1000)
      :second -> div(microseconds, 1_000_000)
      :minute -> div(microseconds, 60_000_000)
      :hour -> div(microseconds, 3_600_000_000)
      :day -> div(microseconds, 86_400_000_000)
    end
  end

  defp max_datetime(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :gt -> dt1
      _ -> dt2
    end
  end

  defp min_datetime(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :lt -> dt1
      _ -> dt2
    end
  end
end
