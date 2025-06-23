defmodule Timeline.Internal.STN.Core do
  @moduledoc false
  alias Timeline.Interval
  alias Timeline.Internal.STN
  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @doc "Adds an interval to the STN with automatic unit conversion and LOD rescaling.\n\nThis creates two time points (start and end) and adds the necessary\ntemporal constraints. Then applies MiniZinc solver to maintain consistency.\n\nThe interval's DateTime values are automatically converted to the STN's\ndeclared time units and rescaled according to the LOD level.\n"
  @spec add_interval(STN.t(), Interval.t()) :: STN.t()
  def add_interval(stn, interval) do
    start_point = "#{interval.id}_start"
    end_point = "#{interval.id}_end"

    duration =
      STN.Units.convert_datetime_duration_to_stn_units(
        interval.start_time,
        interval.end_time,
        stn.time_unit,
        stn.lod_level,
        stn.lod_resolution
      )

    duration_constraint = {duration, duration}

    stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    |> add_constraint(start_point, end_point, duration_constraint)
  end

  @doc "Updates an interval in the STN by removing the old one and adding the new one.\n"
  @spec update_interval(STN.t(), Interval.t()) :: STN.t()
  def update_interval(stn, interval) do
    stn |> remove_interval(interval.id) |> add_interval(interval)
  end

  @doc "Removes an interval from the STN.\n"
  @spec remove_interval(STN.t(), String.t()) :: STN.t()
  def remove_interval(stn, interval_id) do
    start_point = "#{interval_id}_start"
    end_point = "#{interval_id}_end"

    updated_constraints =
      stn.constraints
      |> Enum.reject(fn {{from, to}, _} ->
        from == start_point or to == start_point or from == end_point or to == end_point
      end)
      |> Map.new()

    updated_time_points =
      stn.time_points |> MapSet.delete(start_point) |> MapSet.delete(end_point)

    %{stn | time_points: updated_time_points, constraints: updated_constraints}
  end

  @doc "Adds a temporal constraint between two time points.\n\nThe constraint represents the allowable distance between the time points\nas {min_distance, max_distance}. Supports :infinity for unbounded constraints.\n"
  @spec add_constraint(STN.t(), time_point(), time_point(), constraint()) :: STN.t()
  def add_constraint(stn, from_point, to_point, {min_dist, max_dist} = constraint)
      when (is_number(min_dist) or min_dist == :neg_infinity) and
             (is_number(max_dist) or max_dist == :infinity) do
    unless valid_constraint_bounds?(min_dist, max_dist) do
      raise ArgumentError, "Invalid constraint bounds: #{inspect(constraint)}"
    end

    stn = stn |> add_time_point(from_point) |> add_time_point(to_point)
    current_constraints = stn.constraints
    is_consistent = stn.consistent

    {updated_constraints_1, consistent_1} =
      update_single_constraint(current_constraints, {from_point, to_point}, constraint)

    reverse_constraint = {negate_constraint_value(max_dist), negate_constraint_value(min_dist)}

    {updated_constraints_2, consistent_2} =
      update_single_constraint(updated_constraints_1, {to_point, from_point}, reverse_constraint)

    final_consistent = is_consistent and consistent_1 and consistent_2
    updated_stn = %{stn | constraints: updated_constraints_2, consistent: final_consistent}
    updated_stn
  end

  @doc "Checks if the STN is temporally consistent.\n"
  @spec consistent?(STN.t()) :: boolean()
  def consistent?(stn) do
    stn.consistent
  end

  @doc "Gets all time points in the STN.\n"
  @spec time_points(STN.t()) :: [time_point()]
  def time_points(stn) do
    MapSet.to_list(stn.time_points)
  end

  @doc "Gets a constraint between two time points.\n"
  @spec get_constraint(STN.t(), time_point(), time_point()) :: constraint() | nil
  def get_constraint(stn, from_point, to_point) do
    Map.get(stn.constraints, {from_point, to_point})
  end

  @doc "Adds a time point to the STN.\n"
  @spec add_time_point(STN.t(), time_point()) :: STN.t()
  def add_time_point(stn, time_point) do
    updated_time_points = MapSet.put(stn.time_points, time_point)
    updated_constraints = Map.put(stn.constraints, {time_point, time_point}, {0, 0})
    %{stn | time_points: updated_time_points, constraints: updated_constraints}
  end

  @doc "Gets all intervals currently stored in the STN.\n\nReturns a list of interval representations with their time bounds.\nEach interval is returned as %{id: interval_id, start_time: number, end_time: number, metadata: map}\nwhere times are in the STN's time units.\n"
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

  @doc "Finds intervals that overlap with the given time range.\n\nReturns intervals that have any overlap with [query_start, query_end].\nTimes should be in the same units as the STN.\n"
  @spec get_overlapping_intervals(STN.t(), number(), number()) :: [
          %{id: String.t(), start_time: number(), end_time: number(), metadata: map()}
        ]
  def get_overlapping_intervals(stn, query_start, query_end) when query_start <= query_end do
    get_intervals(stn)
    |> Enum.filter(fn interval ->
      interval.start_time <= query_end and query_start <= interval.end_time
    end)
  end

  @doc "Finds free time slots of the specified duration within the given time window.\n\nReturns a list of available slots as %{start_time: number, end_time: number}.\nEach slot has exactly the requested duration and fits within [window_start, window_end].\n"
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

  @doc "Checks if a new interval conflicts with existing intervals in the STN.\n\nReturns a list of conflicting intervals, or empty list if no conflicts.\n"
  @spec check_interval_conflicts(STN.t(), number(), number()) :: [
          %{id: String.t(), start_time: number(), end_time: number(), metadata: map()}
        ]
  def check_interval_conflicts(stn, new_start, new_end) when new_start <= new_end do
    get_overlapping_intervals(stn, new_start, new_end)
  end

  @doc "Finds the next available time slot for the given duration after the specified start time.\n\nReturns {:ok, start_time, end_time} for the first available slot,\nor {:error, reason} if no slot is available within a reasonable search window.\n"
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

  defp valid_constraint_bounds?(min_dist, max_dist) do
    case {min_dist, max_dist} do
      {:neg_infinity, :infinity} ->
        true

      {:neg_infinity, max_dist} when is_number(max_dist) ->
        true

      {min_dist, :infinity} when is_number(min_dist) ->
        true

      {min_dist, max_dist} when is_number(min_dist) and is_number(max_dist) ->
        min_dist <= max_dist

      _ ->
        false
    end
  end

  defp intersect_constraints({min1, max1}, {min2, max2}) do
    new_min = constraint_max(min1, min2)
    new_max = constraint_min(max1, max2)

    if constraint_greater_than?(new_min, new_max) do
      :inconsistent
    else
      {new_min, new_max}
    end
  end

  defp constraint_max(:neg_infinity, other) do
    other
  end

  defp constraint_max(other, :neg_infinity) do
    other
  end

  defp constraint_max(:infinity, _) do
    :infinity
  end

  defp constraint_max(_, :infinity) do
    :infinity
  end

  defp constraint_max(a, b) when is_number(a) and is_number(b) do
    max(a, b)
  end

  defp constraint_min(:infinity, other) do
    other
  end

  defp constraint_min(other, :infinity) do
    other
  end

  defp constraint_min(:neg_infinity, _) do
    :neg_infinity
  end

  defp constraint_min(_, :neg_infinity) do
    :neg_infinity
  end

  defp constraint_min(a, b) when is_number(a) and is_number(b) do
    min(a, b)
  end

  defp constraint_greater_than?(:infinity, _) do
    false
  end

  defp constraint_greater_than?(_, :neg_infinity) do
    false
  end

  defp constraint_greater_than?(:neg_infinity, _) do
    true
  end

  defp constraint_greater_than?(_, :infinity) do
    true
  end

  defp constraint_greater_than?(a, b) when is_number(a) and is_number(b) do
    a > b
  end

  defp negate_constraint_value(:infinity) do
    :neg_infinity
  end

  defp negate_constraint_value(:neg_infinity) do
    :infinity
  end

  defp negate_constraint_value(value) when is_number(value) do
    -value
  end

  defp update_single_constraint(constraints, key, new_constraint) do
    case Map.get(constraints, key) do
      nil ->
        {Map.put(constraints, key, new_constraint), true}

      existing_constraint ->
        case intersect_constraints(existing_constraint, new_constraint) do
          :inconsistent -> {Map.put(constraints, key, new_constraint), false}
          intersected_constraint -> {Map.put(constraints, key, intersected_constraint), true}
        end
    end
  end

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