defmodule Timeline.Internal.STN.MiniZincSolver do
  @moduledoc "MiniZinc-based STN solver that replaces the PC-2 algorithm.\n\nConverts STN constraints to MiniZinc format and uses the constraint solver\nto determine consistency and find solutions.\n"
  alias Timeline.Internal.STN
  alias AriaEngine.MiniZinc.Executor
  require Logger

  @doc "Solves an STN using MiniZinc constraint solver.\n\nReturns an updated STN with consistency information and potentially\ntightened constraints based on the MiniZinc solution.\n"
  @spec solve_stn(STN.t()) :: STN.t()
  def solve_stn(stn) do
    case convert_stn_to_minizinc(stn) do
      {:ok, template_vars} ->
        case Executor.exec("stn_temporal", template_vars: template_vars) do
          {:ok, %{status: :success, solution: solution, raw_output: _raw_output}} ->
            update_stn_with_solution(stn, solution)

          {:ok, %{status: :error}} ->
            %{stn | consistent: false}

          {:error, _reason} ->
            %{stn | consistent: false}
        end

      {:error, _reason} ->
        %{stn | consistent: false}
    end
  end

  @doc "Converts STN data structure to MiniZinc template variables.\n"
  @spec convert_stn_to_minizinc(STN.t()) :: {:ok, map()} | {:error, String.t()}
  def convert_stn_to_minizinc(stn) do
    time_points = MapSet.to_list(stn.time_points)

    if Enum.empty?(time_points) do
      {:error, "Empty STN - no time points to solve"}
    else
      time_point_map =
        time_points |> Enum.with_index(1) |> Map.new(fn {point, index} -> {point, index} end)

      constraints = convert_constraints(stn.constraints, time_point_map)
      durations = extract_durations(stn.constraints, time_point_map)

      template_vars = %{
        num_activities: length(time_points),
        num_constraints: length(constraints),
        durations: durations,
        constraints: constraints,
        time_point_map: time_point_map
      }

      {:ok, template_vars}
    end
  end

  defp convert_constraints(constraint_map, time_point_map) do
    constraint_map
    |> Enum.filter(fn {{from, to}, {min, max}} ->
      from != to and is_finite_constraint({min, max})
    end)
    |> Enum.map(fn {{from, to}, {min, max}} ->
      from_idx = Map.get(time_point_map, from)
      to_idx = Map.get(time_point_map, to)

      %{
        from_activity: from_idx,
        to_activity: to_idx,
        min_distance: round(min),
        max_distance: round(max)
      }
    end)
    |> Enum.filter(fn constraint ->
      constraint.from_activity != nil and constraint.to_activity != nil
    end)
  end

  defp is_finite_constraint({min, max}) do
    is_finite_number(min) and is_finite_number(max) and min <= max
  end

  defp is_finite_number(n) when is_number(n) do
    abs(n) < 1_000_000_000_000_000.0
  end

  defp is_finite_number(_) do
    false
  end

  defp extract_durations(constraint_map, time_point_map) do
    time_points = Map.keys(time_point_map)
    num_points = length(time_points)
    durations = List.duplicate(0, num_points)

    time_points
    |> Enum.reduce(durations, fn point, acc_durations ->
      case extract_duration_for_point(point, constraint_map, time_point_map) do
        nil ->
          acc_durations

        duration ->
          point_index = Map.get(time_point_map, point) - 1
          List.replace_at(acc_durations, point_index, duration)
      end
    end)
  end

  defp extract_duration_for_point(point, constraint_map, _time_point_map) do
    if String.ends_with?(point, "_start") do
      base_name = String.replace_suffix(point, "_start", "")
      end_point = base_name <> "_end"

      case Map.get(constraint_map, {point, end_point}) do
        {min_duration, max_duration} when min_duration == max_duration -> round(min_duration)
        _ -> nil
      end
    else
      nil
    end
  end

  defp update_stn_with_solution(stn, solution) do
    consistent = solution[:status] != "UNSATISFIABLE"
    updated_stn = %{stn | consistent: consistent}

    if consistent and solution[:start_times] do
      solved_times = extract_solved_times(stn, solution)
      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, solved_times)}
    else
      updated_stn
    end
  end

  defp extract_solved_times(stn, solution) do
    time_points = MapSet.to_list(stn.time_points)
    start_times = solution[:start_times] || []

    time_point_map =
      time_points |> Enum.with_index(1) |> Map.new(fn {point, index} -> {point, index} end)

    index_to_point_map =
      time_point_map |> Enum.map(fn {point, index} -> {index, point} end) |> Map.new()

    start_times
    |> Enum.with_index(1)
    |> Enum.map(fn {start_time, index} ->
      case Map.get(index_to_point_map, index) do
        nil -> nil
        time_point -> {time_point, start_time}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end
end