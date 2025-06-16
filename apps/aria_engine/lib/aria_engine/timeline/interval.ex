# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.Interval do
  @moduledoc """
  Represents a temporal interval with start and end points using DateTime with float precision.

  Intervals are the fundamental building blocks of the Timeline system,
  representing periods of time during which events, actions, or states occur.
  
  Time is stored as DateTime structures with float precision for subsecond accuracy.
  """

  alias AriaEngine.Timeline.{AgentEntity, TimeConverter}

  @type t :: %__MODULE__{
          name: atom(),
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          label: String.t() | nil,
          agent: AgentEntity.agent() | nil,
          entity: AgentEntity.entity() | nil,
          metadata: map()
        }

  defstruct [:name, :start_time, :end_time, :label, :agent, :entity, metadata: %{}]

  @doc """
  Creates a new interval with millisecond precision.

  ## Parameters

  - `name`: Unique atom identifier for the interval
  - `start_ms`: Start time in milliseconds (integer)
  - `end_ms`: End time in milliseconds (integer)
  - `opts`: Optional parameters including:
    - `:label` - Human-readable label for the interval
    - `:agent` - Associated agent (if any)
    - `:entity` - Associated entity (if any)
    - `:metadata` - Additional metadata

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   :action1,
      ...>   0,
      ...>   5500,
      ...>   label: "Morning Meeting"
      ...> )
      iex> interval.name
      :action1
      iex> interval.start_ms
      0
      iex> interval.end_ms
      5500

  """
  @spec new(atom(), integer(), integer(), keyword()) :: t()
  def new(name, start_ms, end_ms, opts \\ []) when is_atom(name) and is_integer(start_ms) and is_integer(end_ms) do
    # Validate that start_ms is before end_ms
    if start_ms >= end_ms do
      raise ArgumentError, "start_ms (#{start_ms}) must be before end_ms (#{end_ms})"
    end

    %__MODULE__{
      name: name,
      start_ms: start_ms,
      end_ms: end_ms,
      label: Keyword.get(opts, :label),
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Gets the duration of the interval in milliseconds.

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(:action1, 1000, 6500)
      iex> AriaEngine.Timeline.Interval.duration_ms(interval)
      5500

  """
  @spec duration_ms(t()) :: integer()
  def duration_ms(%__MODULE__{start_ms: start_ms, end_ms: end_ms}) do
    end_ms - start_ms
  end

  @doc """
  Gets the duration of the interval in seconds.

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(:action1, 1000, 6500)
      iex> AriaEngine.Timeline.Interval.duration_seconds(interval)
      5.5

  """
  @spec duration_seconds(t()) :: float()
  def duration_seconds(interval) do
    TimeConverter.ms_to_seconds(duration_ms(interval))
  end

  @doc """
  Gets the start time in seconds.

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(:action1, 1500, 6500)
      iex> AriaEngine.Timeline.Interval.start_seconds(interval)
      1.5

  """
  @spec start_seconds(t()) :: float()
  def start_seconds(%__MODULE__{start_ms: start_ms}) do
    TimeConverter.ms_to_seconds(start_ms)
  end

  @doc """
  Gets the end time in seconds.

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(:action1, 1500, 6500)
      iex> AriaEngine.Timeline.Interval.end_seconds(interval)
      6.5

  """
  @spec end_seconds(t()) :: float()
  def end_seconds(%__MODULE__{end_ms: end_ms}) do
    TimeConverter.ms_to_seconds(end_ms)
  end

  @doc """
  Checks if a time point is contained within the interval.

  ## Examples

      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   ~N[2025-01-01 10:00:00],
      ...>   ~N[2025-01-01 12:00:00]
      ...> )
      iex> AriaEngine.Timeline.Interval.contains?(interval, ~N[2025-01-01 11:00:00])
      true

  """
  @spec contains?(t(), DateTime.t() | NaiveDateTime.t() | integer()) :: boolean()
  def contains?(%__MODULE__{start_time: start_time, end_time: end_time}, time_point) do
    compare_time(start_time, time_point) <= 0 and compare_time(time_point, end_time) < 0
  end

  @doc """
  Checks if the interval is associated with an agent.

  ## Examples

      iex> agent = %{type: :agent, id: "agent1", name: "Alice"}
      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   ~N[2025-01-01 10:00:00],
      ...>   ~N[2025-01-01 12:00:00],
      ...>   agent: agent
      ...> )
      iex> AriaEngine.Timeline.Interval.agent?(interval)
      true

  """
  @spec agent?(t()) :: boolean()
  def agent?(%__MODULE__{agent: agent}), do: not is_nil(agent)

  @doc """
  Checks if the interval is associated with an entity.

  ## Examples

      iex> entity = %{type: :entity, id: "entity1", name: "Conference Room"}
      iex> interval = AriaEngine.Timeline.Interval.new(
      ...>   ~N[2025-01-01 10:00:00],
      ...>   ~N[2025-01-01 12:00:00],
      ...>   entity: entity
      ...> )
      iex> AriaEngine.Timeline.Interval.entity?(interval)
      true

  """
  @spec entity?(t()) :: boolean()
  def entity?(%__MODULE__{entity: entity}), do: not is_nil(entity)

  # Private helper functions

  defp generate_id do
    # Generate a unique identifier for the interval
    :crypto.strong_rand_bytes(16) |> Base.encode64(padding: false)
  end

  defp valid_time_order?(start_time, end_time) do
    compare_time(start_time, end_time) < 0
  end

  defp calculate_duration(start_time, end_time) do
    case {start_time, end_time} do
      {%DateTime{} = start_dt, %DateTime{} = end_dt} ->
        DateTime.diff(end_dt, start_dt, :second)

      {%NaiveDateTime{} = start_ndt, %NaiveDateTime{} = end_ndt} ->
        NaiveDateTime.diff(end_ndt, start_ndt, :second)

      {start_int, end_int} when is_integer(start_int) and is_integer(end_int) ->
        end_int - start_int

      _ ->
        raise ArgumentError, "Incompatible time types for duration calculation"
    end
  end

  defp compare_time(time1, time2) do
    case {time1, time2} do
      {%DateTime{} = dt1, %DateTime{} = dt2} ->
        DateTime.compare(dt1, dt2) |> comparison_to_integer()

      {%NaiveDateTime{} = ndt1, %NaiveDateTime{} = ndt2} ->
        NaiveDateTime.compare(ndt1, ndt2) |> comparison_to_integer()

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

  defp comparison_to_integer(:lt), do: -1
  defp comparison_to_integer(:eq), do: 0
  defp comparison_to_integer(:gt), do: 1
end
