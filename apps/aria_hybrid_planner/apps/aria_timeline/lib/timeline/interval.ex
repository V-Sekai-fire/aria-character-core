# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Interval do
  @moduledoc "Represents a temporal interval with start and end points using DateTime with timezone information.\n\nIntervals are the fundamental building blocks of the Timeline system,\nrepresenting periods of time during which events, actions, or states occur.\n\nOnly DateTime structs with explicit timezone information are supported\nto ensure temporal consistency and proper timezone handling across the system.\nThis enforces clarity about when events occur in global context.\n\n## Timezone Enforcement\n\n- All temporal data uses DateTime.t() with timezone information\n- NaiveDateTime is not supported to prevent ambiguity\n- Integer timestamps are not supported to enforce explicit timezone handling\n- All time comparisons account for timezone differences automatically\n\n## Duration API Design\n\nThe module provides multiple ways to access interval durations:\n\n- `duration_ms/1` and `duration/1` - Default millisecond precision (integer)\n- `duration_seconds/1` - Floating-point seconds for human-readable values\n- `duration_in_unit/2` - Flexible unit conversion for any supported time unit\n- `to_stn_points/2` - STN integration with explicit unit specification\n\nMilliseconds are used as the default unit for temporal systems requiring high\nprecision and integer arithmetic, while the flexible API supports conversion\nto any time unit as needed.\n"
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
  defstruct id: nil, start_time: nil, end_time: nil, agent: nil, entity: nil, metadata: %{}

  @doc "Creates a new interval with DateTime values.\n\nBoth start_time and end_time must be DateTime structs with timezone information.\nThis ensures all temporal data has explicit timezone context.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> interval.start_time\n    ~U[2023-01-01 00:00:00Z]\n\n"
  @spec new(DateTime.t(), DateTime.t()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time) do
    validate_time_ordering!(start_time, end_time)
    %__MODULE__{id: generate_id(), start_time: start_time, end_time: end_time, metadata: %{}}
  end

  @doc "Creates a new interval with DateTime values and options.\n\nBoth start_time and end_time must be DateTime structs with timezone information.\n\n## Options\n\n- `:agent` - The agent associated with this interval\n- `:entity` - The entity associated with this interval  \n- `:metadata` - Additional metadata for the interval\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt, metadata: %{type: :action})\n    iex> interval.metadata\n    %{type: :action}\n\n"
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

  @doc "Gets the duration of the interval in milliseconds.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> Timeline.Interval.duration_ms(interval)\n    330000\n\n"
  @spec duration_ms(t()) :: integer()
  def duration_ms(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :millisecond)
  end

  @doc "Gets the duration of the interval in seconds.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> Timeline.Interval.duration_seconds(interval)\n    330.0\n\n"
  @spec duration_seconds(t()) :: float()
  def duration_seconds(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :microsecond) / 1_000_000.0
  end

  @doc "Checks if a DateTime point is contained within the interval.\n\nOnly DateTime values are supported for time points to maintain timezone consistency.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> check_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> Timeline.Interval.contains?(interval, check_time)\n    true\n\n"
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_time: start_time, end_time: end_time}, %DateTime{} = time_point) do
    DateTime.compare(start_time, time_point) in [:lt, :eq] and
      DateTime.compare(time_point, end_time) == :lt
  end

  @doc "Checks if the interval is associated with an agent.\n\n## Examples\n\n    iex> agent = %{type: :agent, id: \"agent1\", name: \"Alice\"}\n    iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt, agent: agent)\n    iex> Timeline.Interval.agent?(interval)\n    true\n\n"
  @spec agent?(t()) :: boolean()
  def agent?(%__MODULE__{agent: agent}) do
    not is_nil(agent)
  end

  @doc "Checks if the interval is associated with an entity.\n\n## Examples\n\n    iex> entity = %{type: :entity, id: \"entity1\", name: \"Conference Room\"}\n    iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt, entity: entity)\n    iex> Timeline.Interval.entity?(interval)\n    true\n\n"
  @spec entity?(t()) :: boolean()
  def entity?(%__MODULE__{entity: entity}) do
    not is_nil(entity)
  end

  @doc "Alias for duration_ms/1 for backward compatibility.\n"
  @spec duration(t()) :: integer()
  def duration(interval) do
    duration_ms(interval)
  end

  @doc "Creates a new interval from ISO 8601 datetime strings.\n\nSupports both string arguments and map-based unified constructor patterns.\n\n## Examples\n\n    iex> interval = Timeline.Interval.new_fixed_schedule(\"2025-06-22T10:00:00Z\", \"2025-06-22T11:00:00Z\")\n    iex> interval.start_time\n    ~U[2025-06-22 10:00:00Z]\n\n"
  @spec new_fixed_schedule(String.t(), String.t()) :: t()
  def new_fixed_schedule(start_iso8601, end_iso8601)
      when is_binary(start_iso8601) and is_binary(end_iso8601) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    new(start_dt, end_dt,
      metadata: %{
        fixed_schedule: true,
        iso8601_start: start_iso8601,
        iso8601_end: end_iso8601
      }
    )
  end

  def new_fixed_schedule(invalid_spec, _opts) when is_map(invalid_spec) do
    raise ArgumentError, "Invalid temporal specification: #{inspect(invalid_spec)}"
  end

  def new_fixed_schedule(%{start: start_iso8601}, opts) when is_list(opts) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: nil,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(
          %{open_ended_start: true, iso8601_start: start_iso8601},
          Keyword.get(opts, :metadata, %{})
        )
    }
  end

  def new_fixed_schedule(start_iso8601, end_iso8601, opts)
      when is_binary(start_iso8601) and is_binary(end_iso8601) and is_list(opts) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    # Merge fixed_schedule metadata with user-provided metadata
    base_metadata = %{
      fixed_schedule: true,
      iso8601_start: start_iso8601,
      iso8601_end: end_iso8601
    }

    user_metadata = Keyword.get(opts, :metadata, %{})
    merged_metadata = Map.merge(base_metadata, user_metadata)

    updated_opts = Keyword.put(opts, :metadata, merged_metadata)
    new(start_dt, end_dt, updated_opts)
  end

  def new_fixed_schedule(%{start: start_iso8601, end: end_iso8601}) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    new(start_dt, end_dt,
      metadata: %{
        fixed_schedule: true,
        iso8601_start: start_iso8601,
        iso8601_end: end_iso8601
      }
    )
  end

  def new_fixed_schedule(%{duration: duration_iso8601}) do
    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: nil,
      metadata: %{
        floating_duration: true,
        duration: duration_iso8601,
        iso8601_duration: duration_iso8601
      }
    }
  end

  def new_fixed_schedule(%{start: start_iso8601}) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: nil,
      metadata: %{open_ended_start: true, iso8601_start: start_iso8601}
    }
  end

  def new_fixed_schedule(%{end: end_iso8601}) do
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: end_dt,
      metadata: %{open_ended_end: true, iso8601_end: end_iso8601}
    }
  end

  def new_fixed_schedule(invalid_spec) when is_map(invalid_spec) do
    raise ArgumentError, "Invalid temporal specification: #{inspect(invalid_spec)}"
  end

  @doc "Creates a floating duration interval from ISO 8601 duration string.\n\n## Examples\n\n    iex> interval = Timeline.Interval.new_floating_duration(\"PT2H\")\n    iex> interval.metadata.floating_duration\n    true\n\n"
  @spec new_floating_duration(String.t()) :: t()
  def new_floating_duration(duration_iso8601) when is_binary(duration_iso8601) do
    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: nil,
      metadata: %{
        floating_duration: true,
        duration: duration_iso8601,
        iso8601_duration: duration_iso8601
      }
    }
  end

  @doc "Creates a floating duration interval with options.\n"
  @spec new_floating_duration(String.t(), keyword()) :: t()
  def new_floating_duration(duration_iso8601, opts)
      when is_binary(duration_iso8601) and is_list(opts) do
    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: nil,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(
          %{
            floating_duration: true,
            duration: duration_iso8601,
            iso8601_duration: duration_iso8601
          },
          Keyword.get(opts, :metadata, %{})
        )
    }
  end

  @doc "Creates an open-ended interval with start time only.\n\n## Examples\n\n    iex> interval = Timeline.Interval.new_open_ended_start(\"2025-06-22T10:00:00Z\")\n    iex> interval.start_time\n    ~U[2025-06-22 10:00:00Z]\n\n"
  @spec new_open_ended_start(String.t()) :: t()
  def new_open_ended_start(start_iso8601) when is_binary(start_iso8601) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: nil,
      metadata: %{open_ended_start: true, iso8601_start: start_iso8601}
    }
  end

  @doc "Creates an open-ended interval with end time only.\n\n## Examples\n\n    iex> interval = Timeline.Interval.new_open_ended_end(\"2025-06-22T17:00:00Z\")\n    iex> interval.end_time\n    ~U[2025-06-22 17:00:00Z]\n\n"
  @spec new_open_ended_end(String.t()) :: t()
  def new_open_ended_end(end_iso8601) when is_binary(end_iso8601) do
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: end_dt,
      metadata: %{open_ended_end: true, iso8601_end: end_iso8601}
    }
  end

  @doc "Gets the duration of the interval in a specific time unit.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 01:00:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> Timeline.Interval.duration_in_unit(interval, :minute)\n    60\n\n"
  @spec duration_in_unit(t(), :microsecond | :millisecond | :second | :minute | :hour | :day) ::
          integer()
  def duration_in_unit(%__MODULE__{start_time: start_time, end_time: end_time}, unit) do
    case unit do
      :microsecond -> DateTime.diff(end_time, start_time, :microsecond)
      :millisecond -> DateTime.diff(end_time, start_time, :millisecond)
      :second -> DateTime.diff(end_time, start_time, :second)
      :minute -> div(DateTime.diff(end_time, start_time, :second), 60)
      :hour -> div(DateTime.diff(end_time, start_time, :second), 3600)
      :day -> div(DateTime.diff(end_time, start_time, :second), 86400)
    end
  end

  @doc "Creates an interval from duration in a specific time unit.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.from_duration(start_dt, 30, :minute)\n    iex> Timeline.Interval.duration_in_unit(interval, :minute)\n    30\n\n"
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

  @doc "Converts the interval to STN time points with explicit unit and LOD information.\n\nThis provides metadata that STN can use for automatic rescaling.\n\n## Examples\n\n    iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:00], \"Etc/UTC\")\n    iex> interval = Timeline.Interval.new(start_dt, end_dt)\n    iex> {_start_point, _end_point, duration} = Timeline.Interval.to_stn_points(interval, :second)\n    iex> duration\n    300\n\n"
  @spec to_stn_points(t(), :microsecond | :millisecond | :second | :minute | :hour | :day) ::
          {String.t(), String.t(), integer()}
  def to_stn_points(%__MODULE__{id: id} = interval, unit) do
    start_point = "#{id}_start"
    end_point = "#{id}_end"
    duration = duration_in_unit(interval, unit)
    {start_point, end_point, duration}
  end

  @doc "Checks if two intervals overlap in time.\n\n## Examples\n\n    iex> start1 = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2023-01-01 01:00:00], \"Etc/UTC\")\n    iex> interval1 = Timeline.Interval.new(start1, end1)\n    iex> start2 = DateTime.from_naive!(~N[2023-01-01 00:30:00], \"Etc/UTC\")\n    iex> end2 = DateTime.from_naive!(~N[2023-01-01 01:30:00], \"Etc/UTC\")\n    iex> interval2 = Timeline.Interval.new(start2, end2)\n    iex> Timeline.Interval.overlaps?(interval1, interval2)\n    true\n\n"
  @spec overlaps?(t(), t()) :: boolean()
  def overlaps?(%__MODULE__{start_time: start1, end_time: end1}, %__MODULE__{
        start_time: start2,
        end_time: end2
      }) do
    DateTime.compare(start1, end2) == :lt and DateTime.compare(start2, end1) == :lt
  end

  @doc "Calculates the temporal relationship between two intervals using Allen's interval algebra.\n\nReturns one of: :before, :meets, :overlaps, :finished_by, :contains, :starts, :equals,\n:started_by, :during, :finishes, :overlapped_by, :met_by, :after\n\n## Examples\n\n    iex> start1 = DateTime.from_naive!(~N[2023-01-01 00:00:00], \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2023-01-01 01:00:00], \"Etc/UTC\")\n    iex> interval1 = Timeline.Interval.new(start1, end1)\n    iex> start2 = DateTime.from_naive!(~N[2023-01-01 01:00:00], \"Etc/UTC\")\n    iex> end2 = DateTime.from_naive!(~N[2023-01-01 02:00:00], \"Etc/UTC\")\n    iex> interval2 = Timeline.Interval.new(start2, end2)\n    iex> Timeline.Interval.allen_relation(interval1, interval2)\n    :meets\n\n"
  @spec allen_relation(t(), t()) :: atom()
  def allen_relation(%__MODULE__{start_time: s1, end_time: e1}, %__MODULE__{
        start_time: s2,
        end_time: e2
      }) do
    s1_vs_s2 = DateTime.compare(s1, s2)
    e1_vs_e2 = DateTime.compare(e1, e2)
    e1_vs_s2 = DateTime.compare(e1, s2)
    s1_vs_e2 = DateTime.compare(s1, e2)

    case check_simple_relations(e1_vs_s2, s1_vs_e2) do
      nil -> check_complex_relations(s1_vs_s2, e1_vs_e2, e1_vs_s2, s1_vs_e2)
      relation -> relation
    end
  end

  defp unit_to_microseconds(:microsecond) do
    1
  end

  defp unit_to_microseconds(:millisecond) do
    1000
  end

  defp unit_to_microseconds(:second) do
    1_000_000
  end

  defp unit_to_microseconds(:minute) do
    60_000_000
  end

  defp unit_to_microseconds(:hour) do
    3_600_000_000
  end

  defp unit_to_microseconds(:day) do
    86_400_000_000
  end

  defp validate_time_ordering!(start_time, end_time) do
    case DateTime.compare(start_time, end_time) do
      :gt -> raise ArgumentError, "start_time must be before or equal to end_time"
      _ -> :ok
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

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
