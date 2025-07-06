# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Bridge.Queries do
  @moduledoc """
  Query operations for timeline bridges including filtering, sorting, and time-based queries.

  This module provides functions for querying and filtering collections of bridges
  based on temporal positions, types, and other criteria.
  """

  alias Timeline.Bridge

  @doc """
  Checks if a bridge occurs before a given time.

  ## Examples

      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> Timeline.Bridge.Queries.before?(bridge, check_time)
      true

  """
  @spec before?(Bridge.t(), DateTime.t() | String.t()) :: boolean()
  def before?(%Bridge{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :lt
  end

  @doc """
  Checks if a bridge occurs after a given time.
  """
  @spec after?(Bridge.t(), DateTime.t() | String.t()) :: boolean()
  def after?(%Bridge{position: position}, time) do
    time_dt = parse_datetime(time)
    DateTime.compare(position, time_dt) == :gt
  end

  @doc """
  Checks if a bridge occurs at exactly the given time.
  """
  @spec at?(Bridge.t(), DateTime.t() | String.t()) :: boolean()
  def at?(%Bridge{position: position}, time) do
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
      iex> [first, _second] = Timeline.Bridge.Queries.sort_by_position([bridge2, bridge1])
      iex> first.id
      "b1"

  """
  @spec sort_by_position([Bridge.t()]) :: [Bridge.t()]
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
      iex> bridges = Timeline.Bridge.Queries.in_range([bridge1, bridge2], start_time, end_time)
      iex> length(bridges)
      1

  """
  @spec in_range([Bridge.t()], DateTime.t() | String.t(), DateTime.t() | String.t()) :: [Bridge.t()]
  def in_range(bridges, start_time, end_time) when is_list(bridges) do
    start_dt = parse_datetime(start_time)
    end_dt = parse_datetime(end_time)

    Enum.filter(bridges, fn bridge ->
      DateTime.compare(bridge.position, start_dt) != :lt and
        DateTime.compare(bridge.position, end_dt) != :gt
    end)
  end

  @doc """
  Filters bridges by type.

  ## Examples

      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> decisions = Timeline.Bridge.Queries.by_type([bridge1, bridge2], :decision)
      iex> length(decisions)
      1

  """
  @spec by_type([Bridge.t()], Bridge.bridge_type()) :: [Bridge.t()]
  def by_type(bridges, type) when is_list(bridges) do
    Enum.filter(bridges, fn bridge -> bridge.type == type end)
  end

  @doc """
  Filters bridges by multiple types.

  ## Examples

      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> pos3 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> bridge3 = Timeline.Bridge.new("b3", pos3, :synchronization)
      iex> filtered = Timeline.Bridge.Queries.by_types([bridge1, bridge2, bridge3], [:decision, :condition])
      iex> length(filtered)
      2

  """
  @spec by_types([Bridge.t()], [Bridge.bridge_type()]) :: [Bridge.t()]
  def by_types(bridges, types) when is_list(bridges) and is_list(types) do
    Enum.filter(bridges, fn bridge -> bridge.type in types end)
  end

  @doc """
  Finds bridges with semantic relations.

  ## Examples

      iex> bridge1 = Timeline.Bridge.new("b1", :starts, :decision)
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> semantic = Timeline.Bridge.Queries.semantic_bridges([bridge1, bridge2])
      iex> length(semantic)
      1

  """
  @spec semantic_bridges([Bridge.t()]) :: [Bridge.t()]
  def semantic_bridges(bridges) when is_list(bridges) do
    Enum.filter(bridges, fn bridge -> bridge.semantic_relation != nil end)
  end

  @doc """
  Finds bridges with absolute positions (DateTime).

  ## Examples

      iex> bridge1 = Timeline.Bridge.new("b1", :starts, :decision)
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> absolute = Timeline.Bridge.Queries.absolute_bridges([bridge1, bridge2])
      iex> length(absolute)
      1

  """
  @spec absolute_bridges([Bridge.t()]) :: [Bridge.t()]
  def absolute_bridges(bridges) when is_list(bridges) do
    Enum.filter(bridges, fn bridge -> match?(%DateTime{}, bridge.position) end)
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  defp parse_datetime(%DateTime{} = datetime), do: datetime

  defp parse_datetime(iso8601_string) when is_binary(iso8601_string) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
    datetime
  end
end
