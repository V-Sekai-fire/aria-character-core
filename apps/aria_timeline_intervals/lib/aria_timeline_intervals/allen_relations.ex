# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervals.AllenRelations do
  @moduledoc """
  Implementation of Allen's Interval Algebra for temporal reasoning.

  This module provides all 13 Allen interval relations for comparing temporal intervals.
  Allen's Interval Algebra is a calculus for temporal reasoning that enables qualitative
  reasoning about time intervals and their relationships.

  ## Allen's 13 Interval Relations

  Using symbolic notation that's language-agnostic:

  1. **before** (X < Y): X ends before Y starts
  2. **after** (X > Y): X starts after Y ends
  3. **meets** (X m Y): X ends exactly when Y starts
  4. **met_by** (X mi Y): X starts exactly when Y ends
  5. **overlaps** (X o Y): X starts before Y, ends during Y
  6. **overlapped_by** (X oi Y): X starts during Y, ends after Y
  7. **starts** (X s Y): X and Y start together, X ends before Y
  8. **started_by** (X si Y): X and Y start together, X ends after Y
  9. **during** (X d Y): X starts after Y starts, X ends before Y ends
  10. **contains** (X di Y): X starts before Y starts, X ends after Y ends
  11. **finishes** (X f Y): X starts after Y, X and Y end together
  12. **finished_by** (X fi Y): X starts before Y, X and Y end together
  13. **equals** (X = Y): X and Y have the same start and end times

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.before?(i1, i2)
      true

  ## References

  - Allen, J.F. (1983). "Maintaining knowledge about temporal intervals"
  - ADR-045: Allen's Interval Algebra Temporal Relationships
  - ADR-046: Interval Notation Usability
  """

  alias AriaTimelineIntervals.Interval

  @type locale :: atom()
  @type relation ::
          :before
          | :after
          | :meets
          | :met_by
          | :overlaps
          | :overlapped_by
          | :starts
          | :started_by
          | :during
          | :contains
          | :finishes
          | :finished_by
          | :equals

  @doc """
  Checks if interval1 occurs before interval2.

  Allen's 'before' relation: X < Y
  X ends before Y starts.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.before?(i1, i2)
      true

  """
  @spec before?(Interval.t(), Interval.t()) :: boolean()
  def before?(%Interval{end_time: end1}, %Interval{start_time: start2}) do
    DateTime.compare(end1, start2) == :lt
  end

  @doc """
  Checks if interval1 occurs after interval2.

  Allen's 'after' relation: X > Y
  X starts after Y ends.
  """
  @spec after?(Interval.t(), Interval.t()) :: boolean()
  def after?(interval1, interval2) do
    before?(interval2, interval1)
  end

  @doc """
  Checks if interval1 meets interval2.

  Allen's 'meets' relation: X m Y
  X ends exactly when Y starts.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.meets?(i1, i2)
      true

  """
  @spec meets?(Interval.t(), Interval.t()) :: boolean()
  def meets?(%Interval{end_time: end1}, %Interval{start_time: start2}) do
    DateTime.compare(end1, start2) == :eq
  end

  @doc """
  Checks if interval1 is met by interval2.

  Allen's 'met-by' relation: X mi Y
  X starts exactly when Y ends.
  """
  @spec met_by?(Interval.t(), Interval.t()) :: boolean()
  def met_by?(interval1, interval2) do
    meets?(interval2, interval1)
  end

  @doc """
  Checks if interval1 overlaps interval2.

  Allen's 'overlaps' relation: X o Y
  X starts before Y, ends during Y.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.overlaps?(i1, i2)
      true

  """
  @spec overlaps?(Interval.t(), Interval.t()) :: boolean()
  def overlaps?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    DateTime.compare(start1, start2) == :lt and
    DateTime.compare(start2, end1) == :lt and
    DateTime.compare(end1, end2) == :lt
  end

  @doc """
  Checks if interval1 is overlapped by interval2.

  Allen's 'overlapped-by' relation: X oi Y
  X starts during Y, ends after Y.
  """
  @spec overlapped_by?(Interval.t(), Interval.t()) :: boolean()
  def overlapped_by?(interval1, interval2) do
    overlaps?(interval2, interval1)
  end

  @doc """
  Checks if interval1 starts interval2.

  Allen's 'starts' relation: X s Y
  X and Y start together, X ends before Y.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start_time, end1)
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start_time, end2)
      iex> AllenRelations.starts?(i1, i2)
      true

  """
  @spec starts?(Interval.t(), Interval.t()) :: boolean()
  def starts?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    DateTime.compare(start1, start2) == :eq and DateTime.compare(end1, end2) == :lt
  end

  @doc """
  Checks if interval1 is started by interval2.

  Allen's 'started-by' relation: X si Y
  X and Y start together, X ends after Y.
  """
  @spec started_by?(Interval.t(), Interval.t()) :: boolean()
  def started_by?(interval1, interval2) do
    starts?(interval2, interval1)
  end

  @doc """
  Checks if interval1 is during interval2.

  Allen's 'during' relation: X d Y
  X starts after Y starts, X ends before Y ends.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.during?(i1, i2)
      true

  """
  @spec during?(Interval.t(), Interval.t()) :: boolean()
  def during?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    DateTime.compare(start2, start1) == :lt and DateTime.compare(end1, end2) == :lt
  end

  @doc """
  Checks if interval1 contains interval2.

  Allen's 'contains' relation: X di Y
  X starts before Y starts, X ends after Y ends.
  """
  @spec contains?(Interval.t(), Interval.t()) :: boolean()
  def contains?(interval1, interval2) do
    during?(interval2, interval1)
  end

  @doc """
  Checks if interval1 finishes interval2.

  Allen's 'finishes' relation: X f Y
  X starts after Y, X and Y end together.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end_time)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end_time)
      iex> AllenRelations.finishes?(i1, i2)
      true

  """
  @spec finishes?(Interval.t(), Interval.t()) :: boolean()
  def finishes?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    DateTime.compare(start2, start1) == :lt and DateTime.compare(end1, end2) == :eq
  end

  @doc """
  Checks if interval1 is finished by interval2.

  Allen's 'finished-by' relation: X fi Y
  X starts before Y, X and Y end together.
  """
  @spec finished_by?(Interval.t(), Interval.t()) :: boolean()
  def finished_by?(interval1, interval2) do
    finishes?(interval2, interval1)
  end

  @doc """
  Checks if interval1 equals interval2.

  Allen's 'equals' relation: X = Y
  X and Y have the same start and end times.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start_time, end_time)
      iex> i2 = Interval.new(start_time, end_time)
      iex> AllenRelations.equals?(i1, i2)
      true

  """
  @spec equals?(Interval.t(), Interval.t()) :: boolean()
  def equals?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    DateTime.compare(start1, start2) == :eq and DateTime.compare(end1, end2) == :eq
  end

  @doc """
  Determines the Allen relation between two intervals.

  Returns the specific Allen relation that holds between the intervals.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.relation(i1, i2)
      :before

  """
  @spec relation(Interval.t(), Interval.t()) :: relation()
  def relation(interval1, interval2) do
    cond do
      before?(interval1, interval2) -> :before
      after?(interval1, interval2) -> :after
      meets?(interval1, interval2) -> :meets
      met_by?(interval1, interval2) -> :met_by
      overlaps?(interval1, interval2) -> :overlaps
      overlapped_by?(interval1, interval2) -> :overlapped_by
      starts?(interval1, interval2) -> :starts
      started_by?(interval1, interval2) -> :started_by
      during?(interval1, interval2) -> :during
      contains?(interval1, interval2) -> :contains
      finishes?(interval1, interval2) -> :finishes
      finished_by?(interval1, interval2) -> :finished_by
      equals?(interval1, interval2) -> :equals
      true -> :unknown
    end
  end

  @doc """
  Checks if two intervals satisfy a specific Allen relation.

  ## Examples

      iex> alias AriaTimelineIntervals.{Interval, AllenRelations}
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> i1 = Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> i2 = Interval.new(start2, end2)
      iex> AllenRelations.satisfies_relation?(i1, i2, :before)
      true

  """
  @spec satisfies_relation?(Interval.t(), Interval.t(), relation()) :: boolean()
  def satisfies_relation?(interval1, interval2, expected_relation) do
    relation(interval1, interval2) == expected_relation
  end

  @doc """
  Validates that a relation atom is a valid Allen relation.

  ## Examples

      iex> AriaTimelineIntervals.AllenRelations.valid_relation?(:before)
      true
      iex> AriaTimelineIntervals.AllenRelations.valid_relation?(:invalid)
      false

  """
  @spec valid_relation?(atom()) :: boolean()
  def valid_relation?(relation) do
    relation in [
      :before,
      :after,
      :meets,
      :met_by,
      :overlaps,
      :overlapped_by,
      :starts,
      :started_by,
      :during,
      :contains,
      :finishes,
      :finished_by,
      :equals
    ]
  end
end
