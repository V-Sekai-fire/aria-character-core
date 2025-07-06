# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.Scheduling do
  @moduledoc """
  STN scheduling operations and interval queries.

  This module handles:
  - Interval retrieval and queries
  - Scheduling operations (finding free slots)
  - Conflict detection
  - Timeline gap analysis and interval merging
  """

  alias Timeline.Internal.STN

  @type constraint :: {number(), number()}
  @type time_point :: String.t()

  @doc """
  Gets all intervals currently stored in the STN.

  Returns a list of interval representations with their time bounds.
  Each interval is returned as %{id: interval_id, start_time: number, end_time: number, metadata: map}
  where times are in the STN's time units.
  """
  @spec get_intervals(STN.t()) :: [
          %{id: String.t(), start_time: number(), end_time: number(), metadata: map()}
        ]
  def get_intervals(stn) do
    stn.time_points
    |> MapSet.to_list()
    |> Enum.filter(&String.ends_with?(&1, "_start"))
    |> Enum.map(fn start_point ->
      interval_id = String.replace_suffix(start_point, "_start", "")
      end_point = "#{interval_id}_end"

      if MapSet.member?(stn.time_points, end_point) do
        case get_interval_bounds(stn, start_point, end_point) do
          {:ok, start_time, end_time} ->
            %{
              id: interval_id,
              start_time: start_time,
              end_time: end_time,
              metadata: Map.get(stn.metadata, interval_id, %{})
            }

          {:error, _} ->
            nil
        end
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Finds intervals that overlap with the given time range.

  Returns intervals that have any overlap with [query_start, query_end].
  Times should be in the same units as the STN.
  """
  @spec get_overlapping_intervals(STN.t(), number(), number()) :: [
          %{id: String.t(), start_time: number(), end_time: number(), metadata: map()}
        ]
  def get_overlapping_intervals(stn, query_start, query_end) when query_start <= query_end do
    get_intervals(stn)
    |> Enum.filter(fn interval ->
      interval.start_time <= query_end and query_start <= interval.end_time
    end)
  end

  @doc """
  Finds free time slots of the specified duration within the given time window.

  Returns a list of available slots as %{start_time: number, end_time: number}.
  Each slot has exactly the requested duration and fits within [window_start, window_end].
  """
  @spec find_free_slots(STN.t(), number(), number(), number()) :: [
          %{start_time: number(), end_time: number()}
        ]
  def find_free_slots(stn, duration, window_start, window_end)
      when duration > 0 and window_start <= window_end and window_end - window_start >= duration do
    occupied_intervals =
      get_intervals(stn)
      |> Enum.filter(fn interval ->
        interval.start_time <= window_end and window_start <= interval.end_time
      end)
      |> Enum.sort_by(& &1.start_time)

    find_gaps_in_timeline(occupied_intervals, window_start, window_end, duration)
  end

  @doc """
  Checks if a new interval conflicts with existing intervals in the STN.

  Returns a list of conflicting intervals, or empty list if no conflicts.
  """
  @spec check_interval_conflicts(STN.t(), number(), number()) :: [
          %{id: String.t(), start_time: number(), end_time: number(), metadata: map()}
        ]
  def check_interval_conflicts(stn, new_start, new_end) when new_start <= new_end do
    get_overlapping_intervals(stn, new_start, new_end)
  end

  @doc """
  Finds the next available time slot for the given duration after the specified start time.

  Returns {:ok, start_time, end_time} for the first available slot,
  or {:error, reason} if no slot is available within a reasonable search window.
  """
  @spec find_next_available_slot(STN.t(), number(), number()) ::
          {:ok, number(), number()} | {:error, atom()}
  def find_next_available_slot(stn, duration, earliest_start) when duration > 0 do
    search_window = convert_to_stn_time_units(30 * 24 * 3600 * 1000, stn.time_unit)
    window_end = earliest_start + search_window

    case find_free_slots(stn, duration, earliest_start, window_end) do
      [] -> {:error, :no_available_slot}
      [first_slot | _] -> {:ok, first_slot.start_time, first_slot.end_time}
    end
  end

  # Private helper functions

  defp get_interval_bounds(stn, start_point, end_point) do
    case get_constraint(stn, start_point, end_point) do
      {duration, duration} when is_number(duration) ->
        {:ok, 0, duration}

      {min_duration, max_duration} when is_number(min_duration) and is_number(max_duration) ->
        avg_duration = (min_duration + max_duration) / 2
        {:ok, 0, avg_duration}

      nil ->
        {:error, :no_constraint}

      _ ->
        {:error, :invalid_constraint}
    end
  end

  defp get_constraint(stn, from_point, to_point) do
    Map.get(stn.constraints, {from_point, to_point})
  end

  defp find_gaps_in_timeline(occupied_intervals, window_start, window_end, required_duration) do
    merged_intervals = merge_overlapping_intervals(occupied_intervals)
    gaps = []

    gaps =
      case merged_intervals do
        [] ->
          if window_end - window_start >= required_duration do
            [%{start_time: window_start, end_time: window_start + required_duration}]
          else
            []
          end

        [first | _] ->
          if first.start_time > window_start and
               first.start_time - window_start >= required_duration do
            [%{start_time: window_start, end_time: window_start + required_duration} | gaps]
          else
            gaps
          end
      end

    gaps =
      Enum.reduce(Enum.zip(merged_intervals, Enum.drop(merged_intervals, 1)), gaps, fn {current,
                                                                                        next},
                                                                                       acc ->
        gap_start = current.end_time
        gap_end = next.start_time
        gap_size = gap_end - gap_start

        if gap_size >= required_duration do
          slot = %{start_time: gap_start, end_time: gap_start + required_duration}
          [slot | acc]
        else
          acc
        end
      end)

    gaps =
      case List.last(merged_intervals) do
        nil ->
          gaps

        last_interval ->
          if last_interval.end_time < window_end and
               window_end - last_interval.end_time >= required_duration do
            slot = %{
              start_time: last_interval.end_time,
              end_time: last_interval.end_time + required_duration
            }

            [slot | gaps]
          else
            gaps
          end
      end

    Enum.sort_by(gaps, & &1.start_time)
  end

  defp merge_overlapping_intervals([]) do
    []
  end

  defp merge_overlapping_intervals(intervals) do
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time)

    Enum.reduce(sorted_intervals, [], fn current, acc ->
      case acc do
        [] ->
          [current]

        [last | rest] ->
          if current.start_time <= last.end_time do
            merged = %{last | end_time: max(last.end_time, current.end_time)}
            [merged | rest]
          else
            [current | acc]
          end
      end
    end)
    |> Enum.reverse()
  end

  defp convert_to_stn_time_units(time_value_ms, target_unit) do
    case target_unit do
      :microsecond -> time_value_ms * 1000
      :millisecond -> time_value_ms
      :second -> div(time_value_ms, 1000)
      :minute -> div(time_value_ms, 60000)
      :hour -> div(time_value_ms, 3_600_000)
      :day -> div(time_value_ms, 86_400_000)
      _ -> time_value_ms
    end
  end
end
