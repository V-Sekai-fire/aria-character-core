# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Bridge.Relations do
  @moduledoc """
  Temporal relations classification and Allen relation mapping.

  Handles the classification of temporal relationships between intervals
  and conversion between Allen relation symbols and language-neutral codes.
  """

  alias Timeline.Interval

  @type relation_code ::
          :EQ
          | :ADJ_F
          | :ADJ_B
          | :WITHIN
          | :CONTAINS
          | :START_ALIGN
          | :START_EXTEND
          | :END_ALIGN
          | :END_EXTEND
          | :OVERLAP_F
          | :OVERLAP_B
          | :PRECEDES
          | :FOLLOWS

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
      iex> Timeline.Bridge.Relations.classify_relation(interval1, interval2)
      :ADJ_F

  """
  @spec classify_relation(Interval.t(), Interval.t()) :: relation_code()
  def classify_relation(%Interval{} = interval1, %Interval{} = interval2) do
    allen_relation = Interval.allen_relation(interval1, interval2)
    allen_to_language_neutral(allen_relation)
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
  # Default fallback
  def allen_to_language_neutral(_), do: :EQ

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
end
