# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincStn do
  @moduledoc """
  MiniZinc-based Simple Temporal Network (STN) solver with Fixpoint fallback.

  This application provides STN constraint solving using MiniZinc constraint
  solving with automatic fallback to pure Elixir computation when MiniZinc
  is not available or fails.

  ## Dual Solver Strategy

  - **MiniZinc**: Primary solver using constraint satisfaction
  - **Fixpoint**: Fallback using iterative constraint propagation
  - **Auto**: Automatically selects the best available solver

  ## Usage

      # Basic STN solving with auto solver selection
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

      # Force specific solver
      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :minizinc)
      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)
  """

  require Logger

  @doc """
  Solve an STN using the specified solver strategy.

  ## Parameters
  - `stn` - STN data structure with time_points, constraints, etc.
  - `options` - Solver options including :solver, :timeout

  ## Solver Options
  - `:solver` - `:auto` (default), `:minizinc`, or `:fixpoint`
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, updated_stn}` - Successfully solved STN with consistency info
  - `{:error, reason}` - Failed to solve STN

  ## Examples

      # Basic STN solving
      {:ok, result} = AriaMinizincStn.solve_stn(stn)
      result.consistent  # => true/false

      # Force specific solver
      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)
  """
  def solve_stn(stn, options \\ []) do
    with :ok <- validate_stn(stn) do
      solver = Keyword.get(options, :solver, :auto)

      case solver do
        :minizinc -> solve_with_minizinc(stn, options)
        :fixpoint -> solve_with_fixpoint(stn, options)
        :auto -> auto_select_solver(stn, options)
        _ -> {:error, "Invalid solver option: #{inspect(solver)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Auto-select the best available solver
  defp auto_select_solver(stn, options) do
    case AriaMinizincExecutor.check_availability() do
      {:ok, _version} ->
        case solve_with_minizinc(stn, options) do
          {:ok, result} -> {:ok, result}
          {:error, _reason} -> solve_with_fixpoint(stn, options)
        end
      {:error, _reason} ->
        solve_with_fixpoint(stn, options)
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(stn, options) do
    case convert_stn_to_minizinc(stn) do
      {:ok, template_vars} ->
        template_path = template_path()
        exec_options = [timeout: Keyword.get(options, :timeout, 30_000)]

        case AriaMinizincExecutor.exec(template_path, template_vars, exec_options) do
          {:ok, raw_output} ->
            case parse_minizinc_output(raw_output) do
              {:ok, solution} ->
                updated_stn = update_stn_with_solution(stn, solution)
                {:ok, %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}
              {:error, reason} ->
                {:error, "Failed to parse MiniZinc output: #{reason}"}
            end

          {:error, reason} ->
            {:error, "MiniZinc execution failed: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Solve using Fixpoint CP solver (Fixpoint fallback)
  defp solve_with_fixpoint(stn, options) do
    case convert_stn_to_cp_model(stn) do
      {:ok, model} ->
        timeout = Keyword.get(options, :timeout, 30_000)

        # CPSolver.solve always returns {:ok, results}, never {:error, reason}
        {:ok, results} = CPSolver.solve(model, timeout: timeout)
        {consistent, solved_times} = extract_cp_solution(results, stn)
        updated_stn = %{stn | consistent: consistent}
        metadata = Map.merge(updated_stn.metadata, %{solver: :fixpoint, solved_times: solved_times})
        {:ok, %{updated_stn | metadata: metadata}}

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

  # Parse MiniZinc JSON output
  defp parse_minizinc_output(output) when is_binary(output) do
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

  defp parse_minizinc_output(output) do
    {:error, "Expected string output, got: #{inspect(output)}"}
  end

  defp update_stn_with_solution(stn, solution) do
    consistent = solution.status == :satisfiable
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

  # Convert STN to CP solver model
  defp convert_stn_to_cp_model(stn) do
    time_points = MapSet.to_list(stn.time_points)

    if Enum.empty?(time_points) do
      # Handle empty STN case - create a trivial model
      dummy_var = CPSolver.IntVariable.new(0..1, name: "dummy")
      model = CPSolver.Model.new([dummy_var], [])
      {:ok, model}
    else
      # Create variables for each time point with reasonable domains
      variables = Enum.map(time_points, fn point ->
        CPSolver.IntVariable.new(0..1000, name: point)
      end)

      # Create constraints from STN constraints
      constraints = create_cp_constraints(stn.constraints, variables, time_points)

      # Create the model
      model = CPSolver.Model.new(variables, constraints)
      {:ok, model}
    end
  end

  # Create CP constraints from STN constraints
  defp create_cp_constraints(stn_constraints, variables, time_points) do
    # Create a map from point names to variables
    var_map = Enum.zip(time_points, variables) |> Map.new()

    stn_constraints
    |> Enum.filter(fn {{from, to}, {min, max}} ->
      from != to and is_finite_constraint({min, max})
    end)
    |> Enum.flat_map(fn {{from, to}, {min, max}} ->
      from_var = Map.get(var_map, from)
      to_var = Map.get(var_map, to)

      if from_var && to_var do
        # For STN constraint: from + min <= to <= from + max
        # We need to create: to >= from + min AND to <= from + max
        # Using sum constraints: from + min <= to and to <= from + max
        min_val = round(min)
        max_val = round(max)

        [
          # to >= from + min  =>  from + min <= to
          CPSolver.Constraint.Sum.new([from_var, min_val], :less_or_equal, to_var),
          # to <= from + max  =>  to <= from + max
          CPSolver.Constraint.Sum.new([to_var], :less_or_equal, [from_var, max_val])
        ]
      else
        []
      end
    end)
  end

  # Extract solution from CP solver results
  defp extract_cp_solution(results, stn) do
    time_points = MapSet.to_list(stn.time_points)

    # Handle empty STN case
    if Enum.empty?(time_points) do
      {true, %{}}
    else
      case results.status do
        :all_solutions ->
          if length(results.solutions) > 0 do
            # Take the first solution
            solution = List.first(results.solutions)

            solved_times =
              time_points
              |> Enum.with_index()
              |> Enum.map(fn {point, index} ->
                time_value = Enum.at(solution, index, 0)
                {point, time_value}
              end)
              |> Map.new()

            {true, solved_times}
          else
            {false, %{}}
          end

        _ ->
          {false, %{}}
      end
    end
  end

  # Get template path
  defp template_path do
    Path.join([Application.app_dir(:aria_minizinc_stn), "priv", "templates", "stn_temporal.mzn.eex"])
  end
end
