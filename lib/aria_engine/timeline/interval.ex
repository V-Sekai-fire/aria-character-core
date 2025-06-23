# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.Interval do
  alias AriaEngine.Timeline.AgentEntity
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

  @spec new(map() | DateTime.t(), keyword() | DateTime.t()) :: t()
  def new(temporal_spec_or_start, opts_or_end \\ [])

  def new(%DateTime{} = start_time, %DateTime{} = end_time) do
    IO.warn(
      "AriaEngine.Timeline.Interval.new/2 with DateTime structs is deprecated. Use new_fixed_schedule/2 with ISO 8601 strings instead."
    )

    validate_time_ordering!(start_time, end_time)
    %__MODULE__{id: generate_id(), start_time: start_time, end_time: end_time, metadata: %{}}
  end

  def new(temporal_spec, opts) when is_map(temporal_spec) and is_list(opts) do
    cond do
      Map.has_key?(temporal_spec, :start) and Map.has_key?(temporal_spec, :end) ->
        new_fixed_schedule(temporal_spec.start, temporal_spec.end, opts)

      Map.has_key?(temporal_spec, :duration) ->
        new_floating_duration(temporal_spec.duration, opts)

      Map.has_key?(temporal_spec, :start) ->
        new_open_ended_start(temporal_spec.start, opts)

      Map.has_key?(temporal_spec, :end) ->
        new_open_ended_end(temporal_spec.end, opts)

      true ->
        raise ArgumentError,
              "Invalid temporal specification. Must include :start, :end, :duration, or combination thereof."
    end
  end

  @spec new_fixed_schedule(map() | String.t(), String.t() | keyword(), keyword()) :: t()
  def new_fixed_schedule(start_or_map, end_or_opts \\ [], opts \\ [])

  def new_fixed_schedule(%{start: start_iso8601, end: end_iso8601}, opts, _) when is_list(opts) do
    new_fixed_schedule(start_iso8601, end_iso8601, opts)
  end

  def new_fixed_schedule(start_iso8601, end_iso8601, opts)
      when is_binary(start_iso8601) and is_binary(end_iso8601) and is_list(opts) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)
    validate_time_ordering!(start_dt, end_dt)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: end_dt,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(Keyword.get(opts, :metadata, %{}), %{
          iso8601_start: start_iso8601,
          iso8601_end: end_iso8601,
          fixed_schedule: true
        })
    }
  end

  def new_fixed_schedule(%DateTime{} = start_dt, %DateTime{} = end_dt, opts) when is_list(opts) do
    IO.warn(
      "AriaEngine.Timeline.Interval.new_fixed_schedule/3 with DateTime structs is deprecated. Use ISO 8601 strings instead."
    )

    validate_time_ordering!(start_dt, end_dt)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: end_dt,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(Keyword.get(opts, :metadata, %{}), %{
          iso8601_start: DateTime.to_iso8601(start_dt),
          iso8601_end: DateTime.to_iso8601(end_dt),
          fixed_schedule: true
        })
    }
  end

  @spec new_floating_duration(String.t(), keyword()) :: t()
  def new_floating_duration(duration_iso8601, opts \\ []) when is_binary(duration_iso8601) do
    normalized_duration = AriaEngine.Utils.normalize_duration(duration_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: nil,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(Keyword.get(opts, :metadata, %{}), %{
          iso8601_duration: normalized_duration,
          floating_duration: true
        })
    }
  end

  @spec new(DateTime.t(), DateTime.t(), keyword()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time, opts) when is_list(opts) do
    IO.warn(
      "AriaEngine.Timeline.Interval.new/3 with DateTime structs is deprecated. Use new_fixed_schedule/3 with ISO 8601 strings instead."
    )

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

  @spec new_open_ended_start(String.t(), keyword()) :: t()
  def new_open_ended_start(start_iso8601, opts \\ []) when is_binary(start_iso8601) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: start_dt,
      end_time: nil,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(Keyword.get(opts, :metadata, %{}), %{
          iso8601_start: start_iso8601,
          open_ended_start: true
        })
    }
  end

  @spec new_open_ended_end(String.t(), keyword()) :: t()
  def new_open_ended_end(end_iso8601, opts \\ []) when is_binary(end_iso8601) do
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso8601)

    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: end_dt,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata:
        Map.merge(Keyword.get(opts, :metadata, %{}), %{
          iso8601_end: end_iso8601,
          open_ended_end: true
        })
    }
  end

  @spec duration_ms(t()) :: integer()
  def duration_ms(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :millisecond)
  end

  @spec duration_seconds(t()) :: float()
  def duration_seconds(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :microsecond) / 1_000_000.0
  end

  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_time: start_time, end_time: end_time}, %DateTime{} = time_point) do
    DateTime.compare(start_time, time_point) in [:lt, :eq] and
      DateTime.compare(time_point, end_time) == :lt
  end

  @spec agent?(t()) :: boolean()
  def agent?(%__MODULE__{agent: agent}) do
    not is_nil(agent)
  end

  @spec entity?(t()) :: boolean()
  def entity?(%__MODULE__{entity: entity}) do
    not is_nil(entity)
  end

  @spec duration(t()) :: integer()
  def duration(interval) do
    duration_ms(interval)
  end

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

  @spec from_iso8601_duration(String.t()) :: t()
  def from_iso8601_duration(iso8601_string) when is_binary(iso8601_string) do
    normalized_duration = AriaEngine.Utils.normalize_duration(iso8601_string)

    %__MODULE__{
      id: generate_id(),
      start_time: nil,
      end_time: nil,
      metadata: %{iso8601_duration: normalized_duration, floating_duration: true}
    }
  end

  @spec to_stn_points(t(), :microsecond | :millisecond | :second | :minute | :hour | :day) ::
          {String.t(), String.t(), integer()}
  def to_stn_points(%__MODULE__{id: id} = interval, unit) do
    start_point = "#{id}_start"
    end_point = "#{id}_end"
    duration = duration_in_unit(interval, unit)
    {start_point, end_point, duration}
  end

  @spec overlaps?(t(), t()) :: boolean()
  def overlaps?(%__MODULE__{start_time: start1, end_time: end1}, %__MODULE__{
        start_time: start2,
        end_time: end2
      }) do
    DateTime.compare(start1, end2) == :lt and DateTime.compare(start2, end1) == :lt
  end

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
