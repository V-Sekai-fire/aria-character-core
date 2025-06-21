# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Interval do
  @moduledoc """
  Represents a temporal interval with start and end points using DateTime with timezone information.

  Intervals are the fundamental building blocks of the Timeline system,
  representing periods of time during which events, actions, or states occur.

  Only DateTime structs with explicit timezone information are supported
  to ensure temporal consistency and proper timezone handling across the system.
  This enforces clarity about when events occur in global context.

  ## Timezone Enforcement

  - All temporal data uses DateTime.t() with timezone information
  - NaiveDateTime is not supported to prevent ambiguity
  - Integer timestamps are not supported to enforce explicit timezone handling
  - All time comparisons account for timezone differences automatically

  ## Duration API Design

  The module provides multiple ways to access interval durations:

  - `duration_ms/1` and `duration/1` - Default millisecond precision (integer)
  - `duration_seconds/1` - Floating-point seconds for human-readable values
  - `duration_in_unit/2` - Flexible unit conversion for any supported time unit
  - `to_stn_points/2` - STN integration with explicit unit specification

  Milliseconds are used as the default unit for temporal systems requiring high
  precision and integer arithmetic, while the flexible API supports conversion
  to any time unit as needed.
  """

  alias Timeline.AgentEntity

  @type id :: String.t()
  @type t :: %__MODULE__{
          id: id(),
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          agent: AgentEntity.agent() | nil,
          entity: AgentEntity.entity() | nil,
          metadata: map()
        }

  defstruct id: nil,
            start_time: nil,
            end_time: nil,
            agent: nil,
            entity: nil,
            metadata: %{}

  @doc """
  Creates a new interval with DateTime values.

  Both start_time and end_time must be DateTime structs with timezone information.
  This ensures all temporal data has explicit timezone context.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> interval.start_time
      ~U[2023-01-01 00:00:00Z]

  """
  @spec new(DateTime.t(), DateTime.t()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time) do
    validate_time_ordering!(start_time, end_time)

    %__MODULE__{
      id: generate_id(),
      start_time: start_time,
      end_time: end_time,
      metadata: %{}
    }
  end

  @doc """
  Creates a new interval with DateTime values and options.

  Both start_time and end_time must be DateTime structs with timezone information.

  ## Options

  - `:agent` - The agent associated with this interval
  - `:entity` - The entity associated with this interval  
  - `:metadata` - Additional metadata for the interval

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt, metadata: %{type: :action})
      iex> interval.metadata
      %{type: :action}

  """
  @spec new(DateTime.t(), DateTime.t(), keyword()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time, opts) when is_list(opts) do
    validate_time_ordering!(start_time, end_time)

    %__MODULE__{
      id: generate_id(),
      start_time: start_time,
      end_time: end_time,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Gets the duration of the interval in milliseconds.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> Timeline.Interval.duration_ms(interval)
      330000

  """
  @spec duration_ms(t()) :: integer()
  def duration_ms(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :millisecond)
  end

  @doc """
  Gets the duration of the interval in seconds.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> Timeline.Interval.duration_seconds(interval)
      330.0

  """
  @spec duration_seconds(t()) :: float()
  def duration_seconds(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :microsecond) / 1_000_000.0
  end

  @doc """
  Checks if a DateTime point is contained within the interval.

  Only DateTime values are supported for time points to maintain timezone consistency.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> Timeline.Interval.contains?(interval, check_time)
      true

  """
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_time: start_time, end_time: end_time}, %DateTime{} = time_point) do
    DateTime.compare(start_time, time_point) in [:lt, :eq] and
      DateTime.compare(time_point, end_time) == :lt
  end

  @doc """
  Checks if the interval is associated with an agent.

  ## Examples

      iex> agent = %{type: :agent, id: "agent1", name: "Alice"}
      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt, agent: agent)
      iex> Timeline.Interval.agent?(interval)
      true

  """
  @spec agent?(t()) :: boolean()
  def agent?(%__MODULE__{agent: agent}), do: not is_nil(agent)

  @doc """
  Checks if the interval is associated with an entity.

  ## Examples

      iex> entity = %{type: :entity, id: "entity1", name: "Conference Room"}
      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt, entity: entity)
      iex> Timeline.Interval.entity?(interval)
      true

  """
  @spec entity?(t()) :: boolean()
  def entity?(%__MODULE__{entity: entity}), do: not is_nil(entity)

  @doc """
  Alias for duration_ms/1 for backward compatibility.
  """
  @spec duration(t()) :: integer()
  def duration(interval), do: duration_ms(interval)

  @doc """
  Gets the duration of the interval in a specific time unit.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> Timeline.Interval.duration_in_unit(interval, :minute)
      60

  """
  @spec duration_in_unit(t(), :microsecond | :millisecond | :second | :minute | :hour | :day) ::
          integer()
  def duration_in_unit(%__MODULE__{start_time: start_time, end_time: end_time}, unit) do
    case unit do
      :microsecond -> DateTime.diff(end_time, start_time, :microsecond)
      :millisecond -> DateTime.diff(end_time, start_time, :millisecond)
      :second -> DateTime.diff(end_time, start_time, :second)
      :minute -> div(DateTime.diff(end_time, start_time, :second), 60)
      :hour -> div(DateTime.diff(end_time, start_time, :second), 3600)
      :day -> div(DateTime.diff(end_time, start_time, :second), 86_400)
    end
  end

  @doc """
  Creates an interval from duration in a specific time unit.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> interval = Timeline.Interval.from_duration(start_dt, 30, :minute)
      iex> Timeline.Interval.duration_in_unit(interval, :minute)
      30

  """
  @spec from_duration(
          DateTime.t(),
          integer(),
          :microsecond | :millisecond | :second | :minute | :hour | :day
        ) :: t()
  def from_duration(%DateTime{} = start_time, duration, unit) do
    microseconds = duration * unit_to_microseconds(unit)
    end_time = DateTime.add(start_time, microseconds, :microsecond)
    new(start_time, end_time)
  end

  @doc """
  Converts the interval to STN time points with explicit unit and LOD information.

  This provides metadata that STN can use for automatic rescaling.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:00], "Etc/UTC")
      iex> interval = Timeline.Interval.new(start_dt, end_dt)
      iex> {_start_point, _end_point, duration} = Timeline.Interval.to_stn_points(interval, :second)
      iex> duration
      300

  """
  @spec to_stn_points(t(), :microsecond | :millisecond | :second | :minute | :hour | :day) ::
          {String.t(), String.t(), integer()}
  def to_stn_points(%__MODULE__{id: id} = interval, unit) do
    start_point = "#{id}_start"
    end_point = "#{id}_end"
    duration = duration_in_unit(interval, unit)
    {start_point, end_point, duration}
  end

  @doc """
  Checks if two intervals overlap in time.

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2023-01-01 00:30:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2023-01-01 01:30:00], "Etc/UTC")
      iex> interval2 = Timeline.Interval.new(start2, end2)
      iex> Timeline.Interval.overlaps?(interval1, interval2)
      true

  """
  @spec overlaps?(t(), t()) :: boolean()
  def overlaps?(%__MODULE__{start_time: start1, end_time: end1}, %__MODULE__{
        start_time: start2,
        end_time: end2
      }) do
    DateTime.compare(start1, end2) == :lt and DateTime.compare(start2, end1) == :lt
  end

  @doc """
  Calculates the temporal relationship between two intervals using Allen's interval algebra.

  Returns one of: :before, :meets, :overlaps, :finished_by, :contains, :starts, :equals,
  :started_by, :during, :finishes, :overlapped_by, :met_by, :after

  ## Examples

      iex> start1 = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> start2 = DateTime.from_naive!(~N[2023-01-01 01:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2023-01-01 02:00:00], "Etc/UTC")
      iex> interval2 = Timeline.Interval.new(start2, end2)
      iex> Timeline.Interval.allen_relation(interval1, interval2)
      :meets

  """
  @spec allen_relation(t(), t()) :: atom()
  def allen_relation(%__MODULE__{start_time: s1, end_time: e1}, %__MODULE__{
        start_time: s2,
        end_time: e2
      }) do
    # Pre-compute all comparisons to avoid redundant calculations
    s1_vs_s2 = DateTime.compare(s1, s2)
    e1_vs_e2 = DateTime.compare(e1, e2)
    e1_vs_s2 = DateTime.compare(e1, s2)
    s1_vs_e2 = DateTime.compare(s1, e2)

    # Check for simple temporal ordering first
    case check_simple_relations(e1_vs_s2, s1_vs_e2) do
      nil -> check_complex_relations(s1_vs_s2, e1_vs_e2, e1_vs_s2, s1_vs_e2)
      relation -> relation
    end
  end

  # Private helper functions

  defp unit_to_microseconds(:microsecond), do: 1
  defp unit_to_microseconds(:millisecond), do: 1_000
  defp unit_to_microseconds(:second), do: 1_000_000
  defp unit_to_microseconds(:minute), do: 60_000_000
  defp unit_to_microseconds(:hour), do: 3_600_000_000
  defp unit_to_microseconds(:day), do: 86_400_000_000

  # Private helper functions

  defp validate_time_ordering!(start_time, end_time) do
    case DateTime.compare(start_time, end_time) do
      :gt -> raise ArgumentError, "start_time must be before or equal to end_time"
      # Allow :eq and :lt
      _ -> :ok
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  # Helper functions for allen_relation to reduce complexity

  defp check_simple_relations(e1_vs_s2, s1_vs_e2) do
    cond do
      e1_vs_s2 == :lt -> :before
      e1_vs_s2 == :eq -> :meets
      s1_vs_e2 == :eq -> :met_by
      s1_vs_e2 == :gt -> :after
      true -> nil
    end
  end

  defp check_complex_relations(s1_vs_s2, e1_vs_e2, e1_vs_s2, s1_vs_e2) do
    cond do
      s1_vs_s2 == :eq and e1_vs_e2 == :eq -> :equals
      s1_vs_s2 == :eq -> check_start_relations(e1_vs_e2)
      e1_vs_e2 == :eq -> check_end_relations(s1_vs_s2)
      true -> check_overlap_relations(s1_vs_s2, e1_vs_e2, e1_vs_s2, s1_vs_e2)
    end
  end

  defp check_start_relations(e1_vs_e2) do
    case e1_vs_e2 do
      :lt -> :starts
      :gt -> :started_by
      _ -> :unknown
    end
  end

  defp check_end_relations(s1_vs_s2) do
    case s1_vs_s2 do
      :gt -> :finishes
      :lt -> :finished_by
      _ -> :unknown
    end
  end

  defp check_overlap_relations(s1_vs_s2, e1_vs_e2, e1_vs_s2, s1_vs_e2) do
    cond do
      s1_vs_s2 == :gt and e1_vs_e2 == :lt -> :during
      s1_vs_s2 == :lt and e1_vs_e2 == :gt -> :contains
      s1_vs_s2 == :lt and e1_vs_e2 == :lt and e1_vs_s2 == :gt -> :overlaps
      s1_vs_s2 == :gt and e1_vs_e2 == :gt and s1_vs_e2 == :lt -> :overlapped_by
      true -> :unknown
    end
  end
end
