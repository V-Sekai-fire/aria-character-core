# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincStn do
  @moduledoc """
  MiniZinc-based Simple Temporal Network (STN) solver.

  This application provides STN constraint solving using MiniZinc constraint
  solving with fail-fast behavior when MiniZinc is not available.

  ## MiniZinc-Only Strategy

  - **MiniZinc**: Pure MiniZinc constraint satisfaction solving
  - **Fail-fast**: Clear error reporting when MiniZinc is unavailable

  ## Usage

      # Basic STN solving
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {1, 5},
          {"B", "C"} => {2, 8}
        },
        consistent: nil,
        metadata: %{}
      }
      {:ok, result} = AriaMinizincStn.solve_stn(stn)
  """

  require Logger

  @type time_point :: String.t()
  @type constraint_bounds :: {number(), number()}
  @type stn_constraints :: %{optional({time_point(), time_point()}) => constraint_bounds()}
  @type stn :: %{
          time_points: MapSet.t(time_point()),
          constraints: stn_constraints(),
          consistent: boolean() | nil,
          metadata: map()
        }
  @type solver_options :: keyword()
  @type solution :: %{status: :satisfiable | :unsatisfiable, start_times: [number()]}
  @type error_reason :: String.t()

  @doc """
  Solve an STN using MiniZinc constraint solving.

  ## Parameters
  - `stn` - STN data structure with time_points, constraints, etc.
  - `options` - Solver options including :timeout

  ## Options
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, updated_stn}` - Successfully solved STN with consistency info
  - `{:error, reason}` - Failed to solve STN

  ## Examples

      # Basic STN solving
      {:ok, result} = AriaMinizincStn.solve_stn(stn)
      result.consistent  # => true/false
  """
  @spec solve_stn(stn(), solver_options()) :: {:ok, stn()} | {:error, error_reason()}
  def solve_stn(stn, options \\ []) do
    with :ok <- validate_stn(stn) do
      solve_with_minizinc(stn, options)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(stn, options) do
    case convert_stn_to_minizinc(stn) do
      {:ok, template_vars} ->
        template_path = template_path()
        exec_options = [timeout: Keyword.get(options, :timeout, 30_000)]

        case AriaMinizincExecutor.exec(template_path, template_vars, exec_options) do
          {:ok, executor_result} ->
            # Try to parse the raw output first, then fall back to parsed solution
            raw_output = Map.get(executor_result, :raw_output, "")

            case parse_minizinc_output(raw_output) do
              {:ok, %{status: :unsatisfiable}} ->
                {:error, :unsatisfiable}
              {:ok, solution} ->
                updated_stn = update_stn_with_solution(stn, solution)
                {:ok, %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}
              {:error, _reason} ->
                # Fallback: try parsing the structured solution from executor
                case Map.get(executor_result, :solution) do
                  %{start_times: start_times} when is_list(start_times) ->
                    solution = %{status: :satisfiable, start_times: start_times}
                    updated_stn = update_stn_with_solution(stn, solution)
                    {:ok, %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}
                  _ ->
                    {:error, "Failed to parse MiniZinc output from both raw and structured formats"}
                end
            end

          {:error, reason} ->
            {:error, "MiniZinc execution failed: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Validate STN structure
  defp validate_stn(stn) do
    cond do
      not is_map(stn) ->
        {:error, "STN must be a map"}
      not Map.has_key?(stn, :time_points) ->
        {:error, "STN must have :time_points field"}
      not Map.has_key?(stn, :constraints) ->
        {:error, "STN must have :constraints field"}
      not is_map(stn.constraints) ->
        {:error, "STN constraints must be a map"}
      true ->
        :ok
    end
  end

  # Convert STN data structure to MiniZinc template variables
  defp convert_stn_to_minizinc(stn) do
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

  # Parse MiniZinc output (handles both string and structured responses)
  defp parse_minizinc_output(output) when is_binary(output) do
    cond do
      String.contains?(output, "=====UNSATISFIABLE=====") ->
        {:ok, %{status: :unsatisfiable}}
      true ->
        case Jason.decode(output) do
          {:ok, %{"status" => "SATISFIABLE", "start_times" => start_times}} ->
            {:ok, %{status: :satisfiable, start_times: start_times}}
          {:ok, %{"status" => "UNSATISFIABLE"}} ->
            {:ok, %{status: :unsatisfiable}}
          {:ok, parsed} ->
            {:error, "Invalid result format: #{inspect(parsed)}"}
          {:error, reason} ->
            {:error, "JSON decode failed: #{inspect(reason)}"}
        end
    end
  end

  defp parse_minizinc_output(%{solution: %{start_times: start_times}} = output) when is_map(output) do
    {:ok, %{status: :satisfiable, start_times: start_times}}
  end

  defp parse_minizinc_output(%{solution: %{status: "UNSATISFIED"}} = _output) do
    {:ok, %{status: :unsatisfiable}}
  end

  defp parse_minizinc_output(output) when is_map(output) do
    # Handle structured response from executor
    case output do
      %{raw_output: raw_output} when is_binary(raw_output) ->
        parse_minizinc_output(raw_output)
      %{solution: solution} when is_map(solution) ->
        case Map.get(solution, :start_times) do
          start_times when is_list(start_times) ->
            {:ok, %{status: :satisfiable, start_times: start_times}}
          _ ->
            {:ok, %{status: :unsatisfiable}}
        end
      _ ->
        {:error, "Invalid structured output format: #{inspect(output)}"}
    end
  end

  defp parse_minizinc_output(output) do
    {:error, "Expected string or map output, got: #{inspect(output)}"}
  end

  defp update_stn_with_solution(stn, solution) do
    consistent = solution.status == :satisfiable
    updated_stn = %{stn | consistent: consistent}

    if consistent and solution[:start_times] do
      solved_times = extract_solved_times(stn, solution)
      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, solved_times)}
    else
      # For unsatisfiable cases, provide empty solved_times to prevent nil access
      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, %{})}
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


  # Get template path
  defp template_path do
    Path.join([Application.app_dir(:aria_minizinc_stn), "priv", "templates", "stn_temporal.mzn.eex"])
  end
end
