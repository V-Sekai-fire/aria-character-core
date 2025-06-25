# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincGoal do
  @moduledoc """
  MiniZinc-based goal-oriented constraint solving with Fixpoint fallback.

  This application provides goal-oriented planning constraint solving using MiniZinc
  with automatic fallback to pure Elixir computation when MiniZinc is not available.

  ## Dual Solver Strategy

  - **MiniZinc**: Primary solver using constraint satisfaction for goal planning
  - **Fixpoint**: Fallback using iterative constraint propagation
  - **Auto**: Automatically selects the best available solver

  ## Usage

      # Basic goal solving with auto solver selection
      domain = %{actions: [...], predicates: [...]}
      state = %{facts: [...]}
      goals = [{:robot, :at, :location_a}, {:box, :at, :location_b}]
      options = %{optimization_type: :minimize_time}

      {:ok, result} = AriaMinizincGoal.solve_goals(domain, state, goals, options)

      # Force specific solver
      {:ok, result} = AriaMinizincGoal.solve_goals(domain, state, goals, options, solver: :minizinc)
      {:ok, result} = AriaMinizincGoal.solve_goals(domain, state, goals, options, solver: :fixpoint)
  """

  require Logger

  @doc """
  Solve goal-oriented planning problems using the specified solver strategy.

  ## Parameters
  - `domain` - Planning domain with actions and predicates
  - `state` - Current state with facts
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options including optimization type
  - `solver_options` - Solver options including :solver, :timeout

  ## Solver Options
  - `:solver` - `:auto` (default), `:minizinc`, or `:fixpoint`
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, solution}` - Successfully solved goals with variable assignments
  - `{:error, reason}` - Failed to solve goals

  ## Examples

      # Basic goal solving
      {:ok, result} = AriaMinizincGoal.solve_goals(domain, state, goals, options)
      result.variables  # => %{time_vars: [...], location_vars: [...], boolean_vars: [...]}

      # Force specific solver
      {:ok, result} = AriaMinizincGoal.solve_goals(domain, state, goals, options, solver: :fixpoint)
  """
  def solve_goals(domain, state, goals, options, solver_options \\ []) do
    with :ok <- validate_inputs(domain, state, goals, options) do
      solver = Keyword.get(solver_options, :solver, :auto)

      case solver do
        :minizinc -> solve_with_minizinc(domain, state, goals, options, solver_options)
        :fixpoint -> solve_with_fixpoint(domain, state, goals, options, solver_options)
        :auto -> auto_select_solver(domain, state, goals, options, solver_options)
        _ -> {:error, "Invalid solver option: #{inspect(solver)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Auto-select the best available solver
  defp auto_select_solver(domain, state, goals, options, solver_options) do
    case AriaMinizincExecutor.check_availability() do
      {:ok, _version} ->
        case solve_with_minizinc(domain, state, goals, options, solver_options) do
          {:ok, result} -> {:ok, result}
          {:error, _reason} -> solve_with_fixpoint(domain, state, goals, options, solver_options)
        end
      {:error, _reason} ->
        solve_with_fixpoint(domain, state, goals, options, solver_options)
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(domain, state, goals, options, solver_options) do
    case convert_goals_to_minizinc(domain, state, goals, options) do
      {:ok, template_vars} ->
        template_path = template_path()
        exec_options = [timeout: Keyword.get(solver_options, :timeout, 30_000)]

        case AriaMinizincExecutor.exec(template_path, template_vars, exec_options) do
          {:ok, raw_output} ->
            case parse_minizinc_output(raw_output) do
              {:ok, solution} ->
                result = %{
                  status: :success,
                  solver: :minizinc,
                  variables: solution.variables,
                  objective_value: solution.objective_value,
                  solve_time_ms: solution.solve_time_ms
                }
                {:ok, result}
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

  # Solve using Fixpoint CP solver (fallback)
  defp solve_with_fixpoint(domain, state, goals, options, solver_options) do
    case convert_goals_to_cp_model(domain, state, goals, options) do
      {:ok, model} ->
        timeout = Keyword.get(solver_options, :timeout, 30_000)

        # CPSolver.solve always returns {:ok, results}, never {:error, reason}
        {:ok, results} = CPSolver.solve(model, timeout: timeout)
        {success, solution} = extract_cp_solution(results, goals)

        if success do
          result = %{
            status: :success,
            solver: :fixpoint,
            variables: solution.variables,
            objective_value: solution.objective_value,
            solve_time_ms: 0  # CPSolver doesn't provide timing
          }
          {:ok, result}
        else
          {:error, "No solution found with Fixpoint CP solver"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Validate input parameters
  defp validate_inputs(domain, state, goals, options) do
    cond do
      not is_map(domain) ->
        {:error, "Domain must be a map"}
      not is_map(state) ->
        {:error, "State must be a map"}
      not is_list(goals) ->
        {:error, "Goals must be a list"}
      not is_map(options) ->
        {:error, "Options must be a map"}
      Enum.empty?(goals) ->
        {:error, "Goals list cannot be empty"}
      true ->
        :ok
    end
  end

  # Convert goal planning problem to MiniZinc template variables
  defp convert_goals_to_minizinc(domain, state, goals, options) do
    try do
      generation_start = Timex.now() |> Timex.format!("{ISO:Extended}")

      # Extract variables and constraints using the original logic
      variables = extract_variables(goals, state)
      constraints = generate_constraints(domain, state, goals, options)
      objective = generate_objective_for_variables(goals, variables, options)

      # Calculate counts
      variable_count = count_total_variables(variables)
      constraint_count = length(constraints)

      # Process variables with formatted domains
      processed_variables = %{
        time_vars: Enum.map(variables.time_vars, &process_variable/1),
        location_vars: Enum.map(variables.location_vars, &process_variable/1),
        boolean_vars: Enum.map(variables.boolean_vars, &process_variable/1)
      }

      # Render constraints to strings
      rendered_constraints = Enum.map(constraints, &render_constraint/1)

      template_vars = %{
        variable_count: variable_count,
        constraint_count: constraint_count,
        generation_start: generation_start,
        num_entities: div(variable_count, 3),
        variables: processed_variables,
        constraints: rendered_constraints,
        objective: objective
      }

      {:ok, template_vars}
    rescue
      error ->
        {:error, "Failed to convert goals to MiniZinc: #{Exception.message(error)}"}
    end
  end

  # Convert goal planning problem to CP solver model
  defp convert_goals_to_cp_model(domain, state, goals, options) do
    try do
      # Extract variables for CP model
      variables = extract_variables_for_cp(goals, state)
      constraints = generate_cp_constraints(domain, state, goals, options, variables)

      # Create the CP model
      model = CPSolver.Model.new(variables, constraints)
      {:ok, model}
    rescue
      error ->
        {:error, "Failed to convert goals to CP model: #{Exception.message(error)}"}
    end
  end

  # Extract variables from goals and state (simplified version)
  defp extract_variables(goals, _state) do
    # Create variables based on goals
    time_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, _predicate, _value}, index} ->
      %{name: "time_#{subject}_#{index}", domain: "0..100"}
    end)

    location_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, _predicate, _value}, index} ->
      %{name: "loc_#{subject}_#{index}", domain: "1..10"}
    end)

    boolean_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, _value}, index} ->
      %{name: "achieved_#{subject}_#{predicate}_#{index}"}
    end)

    %{
      time_vars: time_vars,
      location_vars: location_vars,
      boolean_vars: boolean_vars
    }
  end

  # Extract variables for CP solver
  defp extract_variables_for_cp(goals, _state) do
    goals
    |> Enum.with_index()
    |> Enum.flat_map(fn {{subject, predicate, _value}, index} ->
      [
        CPSolver.IntVariable.new(0..100, name: "time_#{subject}_#{index}"),
        CPSolver.IntVariable.new(1..10, name: "loc_#{subject}_#{index}"),
        CPSolver.BoolVariable.new(name: "achieved_#{subject}_#{predicate}_#{index}")
      ]
    end)
  end

  # Generate constraints (simplified)
  defp generate_constraints(_domain, _state, goals, _options) do
    # Simple constraint: each goal must be achieved
    goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, _value}, index} ->
      "constraint achieved_#{subject}_#{predicate}_#{index} = true;"
    end)
  end

  # Generate CP constraints
  defp generate_cp_constraints(_domain, _state, _goals, _options, variables) do
    # Simple constraint: boolean variables must be true
    boolean_vars = Enum.filter(variables, fn var ->
      String.contains?(var.name, "achieved_")
    end)

    Enum.map(boolean_vars, fn var ->
      CPSolver.Constraint.Equal.new(var, true)
    end)
  end

  # Generate objective function
  defp generate_objective_for_variables(_goals, variables, options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time ->
        time_var_names = Enum.map(variables.time_vars, & &1.name)
        if length(time_var_names) > 0 do
          "minimize max([#{Enum.join(time_var_names, ", ")}]);"
        else
          "minimize 0;"
        end
      :minimize_distance ->
        location_var_names = Enum.map(variables.location_vars, & &1.name)
        if length(location_var_names) > 0 do
          "minimize sum([#{Enum.join(location_var_names, ", ")}]);"
        else
          "minimize 0;"
        end
      :maximize_efficiency ->
        boolean_var_names = Enum.map(variables.boolean_vars, & &1.name)
        if length(boolean_var_names) > 0 do
          bool_conditions = Enum.map(boolean_var_names, fn name -> "if #{name} then 1 else 0 endif" end)
          "maximize sum([#{Enum.join(bool_conditions, ", ")}]);"
        else
          "maximize 0;"
        end
      _ ->
        "minimize 0;"
    end
  end

  # Helper functions
  defp count_total_variables(variables) do
    length(variables.time_vars) + length(variables.location_vars) + length(variables.boolean_vars)
  end

  defp process_variable(var) do
    Map.put_new(var, :domain, var[:domain] || "0..100")
  end

  defp render_constraint(constraint) when is_binary(constraint), do: constraint
  defp render_constraint(constraint), do: inspect(constraint)

  # Parse MiniZinc JSON output
  defp parse_minizinc_output(output) when is_binary(output) do
    case Jason.decode(output) do
      {:ok, %{"status" => "SATISFIABLE"} = result} ->
        variables = extract_variables_from_result(result)
        objective_value = Map.get(result, "objective", 0)

        {:ok, %{
          status: :satisfiable,
          variables: variables,
          objective_value: objective_value,
          solve_time_ms: 0
        }}
      {:ok, %{"status" => "UNSATISFIABLE"}} ->
        {:error, "Problem is unsatisfiable"}
      {:ok, parsed} ->
        {:error, "Invalid result format: #{inspect(parsed)}"}
      {:error, reason} ->
        {:error, "JSON decode failed: #{inspect(reason)}"}
    end
  end

  defp parse_minizinc_output(output) do
    {:error, "Expected string output, got: #{inspect(output)}"}
  end

  defp extract_variables_from_result(result) do
    # Extract variable assignments from MiniZinc result
    %{
      time_vars: Map.get(result, "time_vars", []),
      location_vars: Map.get(result, "location_vars", []),
      boolean_vars: Map.get(result, "boolean_vars", [])
    }
  end

  # Extract solution from CP solver results
  defp extract_cp_solution(results, goals) do
    case results.status do
      :all_solutions ->
        if length(results.solutions) > 0 do
          solution = List.first(results.solutions)
          variables = extract_variables_from_cp_solution(solution, goals)

          {true, %{
            variables: variables,
            objective_value: 0
          }}
        else
          {false, %{}}
        end

      _ ->
        {false, %{}}
    end
  end

  defp extract_variables_from_cp_solution(solution, goals) do
    # Map CP solution back to variable structure
    num_goals = length(goals)

    %{
      time_vars: Enum.take(solution, num_goals),
      location_vars: Enum.slice(solution, num_goals, num_goals),
      boolean_vars: Enum.slice(solution, num_goals * 2, num_goals)
    }
  end

  # Get template path
  defp template_path do
    Path.join([Application.app_dir(:aria_minizinc_goal), "priv", "templates", "goal_solving.mzn.eex"])
  end
end
