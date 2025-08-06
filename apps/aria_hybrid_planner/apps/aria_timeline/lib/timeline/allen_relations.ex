# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.IntervalRelations do
  @moduledoc "Implementation of Allen's Interval Algebra for temporal reasoning.\n\nThis module provides all 13 Allen interval relations for comparing temporal intervals.\nAllen's Interval Algebra is a calculus for temporal reasoning that enables qualitative\nreasoning about time intervals and their relationships.\n\n## Allen's 13 Interval Relations\n\nUsing symbolic notation that's language-agnostic:\n\n1. **before** (X < Y): X ends before Y starts\n2. **after** (X > Y): X starts after Y ends\n3. **meets** (X m Y): X ends exactly when Y starts\n4. **met_by** (X mi Y): X starts exactly when Y ends\n5. **overlaps** (X o Y): X starts before Y, ends during Y\n6. **overlapped_by** (X oi Y): X starts during Y, ends after Y\n7. **starts** (X s Y): X and Y start together, X ends before Y\n8. **started_by** (X si Y): X and Y start together, X ends after Y\n9. **during** (X d Y): X starts after Y starts, X ends before Y ends\n10. **contains** (X di Y): X starts before Y starts, X ends after Y ends\n11. **finishes** (X f Y): X starts after Y, X and Y end together\n12. **finished_by** (X fi Y): X starts before Y, X and Y end together\n13. **equals** (X = Y): X and Y have the same start and end times\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 13:00:00], ~N[2025-01-01 15:00:00])\n    iex> IntervalRelations.before?(i1, i2)\n    true\n    iex> IntervalRelations.describe_relation(i1, i2, :en)\n    \"before\"\n\nUsing the pipe operator for functional composition:\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 11:00:00], ~N[2025-01-01 13:00:00])\n    iex> IntervalRelations.relation(i1, i2) |> IntervalRelations.valid_relation?()\n    true\n\n## References\n\n- Allen, J.F. (1983). \"Maintaining knowledge about temporal intervals\"\n- ADR-045: Allen's Interval Algebra Temporal Relationships\n- ADR-046: Interval Notation Usability\n"
  alias Timeline.Interval
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
  @doc "Checks if interval1 occurs before interval2.\n\nAllen's 'before' relation: X < Y\nX ends before Y starts.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 13:00:00], ~N[2025-01-01 15:00:00])\n    iex> IntervalRelations.before?(i1, i2)\n    true\n\n"
  @spec before?(Interval.t(), Interval.t()) :: boolean()
  def before?(%Interval{end_time: end1}, %Interval{start_time: start2}) do
    compare_times(end1, start2) < 0
  end

  @doc "Checks if interval1 occurs after interval2.\n\nAllen's 'after' relation: X > Y\nX starts after Y ends.\n"
  @spec after?(Interval.t(), Interval.t()) :: boolean()
  def after?(interval1, interval2) do
    before?(interval2, interval1)
  end

  @doc "Checks if interval1 meets interval2.\n\nAllen's 'meets' relation: X m Y\nX ends exactly when Y starts.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 12:00:00], ~N[2025-01-01 14:00:00])\n    iex> IntervalRelations.meets?(i1, i2)\n    true\n\n"
  @spec meets?(Interval.t(), Interval.t()) :: boolean()
  def meets?(%Interval{end_time: end1}, %Interval{start_time: start2}) do
    compare_times(end1, start2) == 0
  end

  @doc "Checks if interval1 is met by interval2.\n\nAllen's 'met-by' relation: X mi Y\nX starts exactly when Y ends.\n"
  @spec met_by?(Interval.t(), Interval.t()) :: boolean()
  def met_by?(interval1, interval2) do
    meets?(interval2, interval1)
  end

  @doc "Checks if interval1 overlaps interval2.\n\nAllen's 'overlaps' relation: X o Y\nX starts before Y, ends during Y.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 13:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 12:00:00], ~N[2025-01-01 15:00:00])\n    iex> IntervalRelations.overlaps?(i1, i2)\n    true\n\n"
  @spec overlaps?(Interval.t(), Interval.t()) :: boolean()
  def overlaps?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    compare_times(start1, start2) < 0 and compare_times(start2, end1) < 0 and
      compare_times(end1, end2) < 0
  end

  @doc "Checks if interval1 is overlapped by interval2.\n\nAllen's 'overlapped-by' relation: X oi Y\nX starts during Y, ends after Y.\n"
  @spec overlapped_by?(Interval.t(), Interval.t()) :: boolean()
  def overlapped_by?(interval1, interval2) do
    overlaps?(interval2, interval1)
  end

  @doc "Checks if interval1 starts interval2.\n\nAllen's 'starts' relation: X s Y\nX and Y start together, X ends before Y.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 14:00:00])\n    iex> IntervalRelations.starts?(i1, i2)\n    true\n\n"
  @spec starts?(Interval.t(), Interval.t()) :: boolean()
  def starts?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    compare_times(start1, start2) == 0 and compare_times(end1, end2) < 0
  end

  @doc "Checks if interval1 is started by interval2.\n\nAllen's 'started-by' relation: X si Y\nX and Y start together, X ends after Y.\n"
  @spec started_by?(Interval.t(), Interval.t()) :: boolean()
  def started_by?(interval1, interval2) do
    starts?(interval2, interval1)
  end

  @doc "Checks if interval1 is during interval2.\n\nAllen's 'during' relation: X d Y\nX starts after Y starts, X ends before Y ends.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 11:00:00], ~N[2025-01-01 13:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 14:00:00])\n    iex> IntervalRelations.during?(i1, i2)\n    true\n\n"
  @spec during?(Interval.t(), Interval.t()) :: boolean()
  def during?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    compare_times(start2, start1) < 0 and compare_times(end1, end2) < 0
  end

  @doc "Checks if interval1 contains interval2.\n\nAllen's 'contains' relation: X di Y\nX starts before Y starts, X ends after Y ends.\n"
  @spec contains?(Interval.t(), Interval.t()) :: boolean()
  def contains?(interval1, interval2) do
    during?(interval2, interval1)
  end

  @doc "Checks if interval1 finishes interval2.\n\nAllen's 'finishes' relation: X f Y\nX starts after Y, X and Y end together.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 12:00:00], ~N[2025-01-01 14:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 14:00:00])\n    iex> IntervalRelations.finishes?(i1, i2)\n    true\n\n"
  @spec finishes?(Interval.t(), Interval.t()) :: boolean()
  def finishes?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    compare_times(start2, start1) < 0 and compare_times(end1, end2) == 0
  end

  @doc "Checks if interval1 is finished by interval2.\n\nAllen's 'finished-by' relation: X fi Y\nX starts before Y, X and Y end together.\n"
  @spec finished_by?(Interval.t(), Interval.t()) :: boolean()
  def finished_by?(interval1, interval2) do
    finishes?(interval2, interval1)
  end

  @doc "Checks if interval1 equals interval2.\n\nAllen's 'equals' relation: X = Y\nX and Y have the same start and end times.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> IntervalRelations.equals?(i1, i2)\n    true\n\n"
  @spec equals?(Interval.t(), Interval.t()) :: boolean()
  def equals?(
        %Interval{start_time: start1, end_time: end1},
        %Interval{start_time: start2, end_time: end2}
      ) do
    compare_times(start1, start2) == 0 and compare_times(end1, end2) == 0
  end

  @doc "Determines the Allen relation between two intervals.\n\nReturns the specific Allen relation that holds between the intervals.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 13:00:00], ~N[2025-01-01 15:00:00])\n    iex> IntervalRelations.relation(i1, i2)\n    :before\n\n"
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

  @doc "Describes the Allen relation between two intervals in a human-readable format.\n\nSupports internationalization with different locales.\n\n## Examples\n\n    iex> alias Timeline.{Interval, IntervalRelations}\n    iex> i1 = Interval.new(~N[2025-01-01 10:00:00], ~N[2025-01-01 12:00:00])\n    iex> i2 = Interval.new(~N[2025-01-01 13:00:00], ~N[2025-01-01 15:00:00])\n    iex> IntervalRelations.describe_relation(i1, i2, :en)\n    \"before\"\n    iex> IntervalRelations.describe_relation(i1, i2, :es)\n    \"antes de\"\n\n"
  @spec describe_relation(Interval.t(), Interval.t(), locale()) :: String.t()
  def describe_relation(interval1, interval2, locale \\ :en) do
    relation = relation(interval1, interval2)
    localize_relation(relation, locale)
  end

  @doc "Validates that a relation atom is a valid Allen relation.\n\n## Examples\n\n    iex> Timeline.IntervalRelations.valid_relation?(:before)\n    true\n    iex> Timeline.IntervalRelations.valid_relation?(:invalid)\n    false\n\n"
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

  defp compare_times(time1, time2) do
    case {time1, time2} do
      {%DateTime{} = dt1, %DateTime{} = dt2} ->
        case DateTime.compare(dt1, dt2) do
          :lt -> -1
          :eq -> 0
          :gt -> 1
        end

      {%NaiveDateTime{} = ndt1, %NaiveDateTime{} = ndt2} ->
        case NaiveDateTime.compare(ndt1, ndt2) do
          :lt -> -1
          :eq -> 0
          :gt -> 1
        end

      {int1, int2} when is_integer(int1) and is_integer(int2) ->
        cond do
          int1 < int2 -> -1
          int1 > int2 -> 1
          true -> 0
        end

      _ ->
        raise ArgumentError, "Incompatible time types for comparison"
    end
  end

  defp localize_relation(relation, locale) do
    translations = %{
      en: %{
        before: "before",
        after: "after",
        meets: "meets",
        met_by: "met by",
        overlaps: "overlaps",
        overlapped_by: "overlapped by",
        starts: "starts",
        started_by: "started by",
        during: "during",
        contains: "contains",
        finishes: "finishes",
        finished_by: "finished by",
        equals: "equals",
        unknown: "unknown"
      },
      es: %{
        before: "antes de",
        after: "después de",
        meets: "se encuentra con",
        met_by: "es encontrado por",
        overlaps: "se superpone con",
        overlapped_by: "es superpuesto por",
        starts: "comienza",
        started_by: "es comenzado por",
        during: "durante",
        contains: "contiene",
        finishes: "termina",
        finished_by: "es terminado por",
        equals: "es igual a",
        unknown: "desconocido"
      },
      fr: %{
        before: "avant",
        after: "après",
        meets: "rencontre",
        met_by: "rencontré par",
        overlaps: "chevauche",
        overlapped_by: "chevauché par",
        starts: "commence",
        started_by: "commencé par",
        during: "pendant",
        contains: "contient",
        finishes: "finit",
        finished_by: "fini par",
        equals: "égal à",
        unknown: "inconnu"
      }
    }

    locale_translations = Map.get(translations, locale, translations.en)
    Map.get(locale_translations, relation, "unknown")
  end
end
