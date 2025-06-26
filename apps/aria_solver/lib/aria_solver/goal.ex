# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.Goal do
  @moduledoc """
  MiniZinc-based goal-oriented constraint solving for AriaSolver.

  This module provides goal-oriented planning constraint solving using MiniZinc
  with fail-fast behavior when MiniZinc is not available. Migrated from
  `aria_minizinc_goal` as part of ADR-193 layered architecture consolidation.

  ## MiniZinc-Only Strategy

  - **MiniZinc**: Pure MiniZinc constraint satisfaction for goal planning
  - **Fail-fast**: Clear error reporting when MiniZinc is unavailable

  ## Usage

      # Basic goal solving
      domain = %{actions: [...], predicates: [...]}
      state = %{facts: [...]}
      goals = [{"location", "robot", "location_a"}, {"location", "box", "location_b"}]
      options = %{optimization_type: :minimize_time}

      {:ok, result} = AriaSolver.Goal.solve_goals(domain, state, goals, options)
  """

  require Logger

  @type domain :: map()
  @type state :: map()
  @type goal :: {String.t(), String.t(), term()}
  @type goals :: [goal()]
  @type options :: map()
  @type solver_options :: keyword()
  @type solution :: %{
          status: atom(),
          solver: atom(),
          variables: map(),
          objective_value: number(),
          solve_time_ms: non_neg_integer()
        }
  @type error_reason :: String.t()

  @doc """
  Solve goal-oriented planning problems using MiniZinc constraint solving.

  ## Parameters
  - `domain` - Planning domain with actions and predicates
  - `state` - Current state with facts
  - `goals` - List of goals in {predicate, subject, value} format (ADR-181 compliant)
  - `options` - Planning options including optimization type
  - `solver_options` - Solver options including :timeout

  ## Options
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, solution}` - Successfully solved goals with variable assignments
  - `{:error, reason}` - Failed to solve goals

  ## Examples

      # Basic goal solving
      {:ok, result} = AriaSolver.Goal.solve_goals(domain, state, goals, options)
      result.variables  # => %{time_vars: [...], location_vars: [...], boolean_vars: [...]}
  """
  @spec solve_goals(domain(), state(), goals(), options(), solver_options()) :: {:ok, solution()} | {:error, error_reason()}
  def solve_goals(domain, state, goals, options, solver_options \\ []) do
    with :ok <- validate_inputs(domain, state, goals, options) do
      solve_with_minizinc(domain, state, goals, options, solver_options)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(domain, state, goals, options, solver_options) do
    case convert_goals_to_minizinc(domain, state, goals, options) do
      {:ok, template_vars} ->
        template_path = template_path()
        exec_options = [timeout: Keyword.get(solver_options, :timeout, 30_000)]

        case AriaSolver.Executor.exec(template_path, template_vars, exec_options) do
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
      not validate_goal_format(goals) ->
        {:error, "Goals must be in {predicate, subject, value} format (ADR-181 compliant)"}
      true ->
        :ok
    end
  end

  # Validate ADR-181 goal format: {predicate, subject, value}
  defp validate_goal_format(goals) do
    Enum.all?(goals, fn
      {predicate, subject, _value} when is_binary(predicate) and is_binary(subject) -> true
      _ -> false
    end)
  end

  # Convert goal planning problem to MiniZinc template variables
  defp convert_goals_to_minizinc(domain, state, goals, options) do
    try do
      generation_start = DateTime.utc_now() |> DateTime.to_iso8601()

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

  # Extract variables from goals and state (ADR-181 compliant format)
  defp extract_variables(goals, _state) do
    # Create variables based on goals - adapted for {predicate, subject, value} format
    time_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{_predicate, subject, _value}, index} ->
      %{name: "time_#{subject}_#{index}", domain: "0..100"}
    end)

    location_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{_predicate, subject, _value}, index} ->
      %{name: "loc_#{subject}_#{index}", domain: "1..10"}
    end)

    boolean_vars = goals
    |> Enum.with_index()
    |> Enum.map(fn {{predicate, subject, _value}, index} ->
      %{name: "achieved_#{predicate}_#{subject}_#{index}"}
    end)

    %{
      time_vars: time_vars,
      location_vars: location_vars,
      boolean_vars: boolean_vars
    }
  end

  # Generate constraints (simplified)
  defp generate_constraints(_domain, _state, goals, _options) do
    # Simple constraint: each goal must be achieved
    goals
    |> Enum.with_index()
    |> Enum.map(fn {{predicate, subject, _value}, index} ->
      "constraint achieved_#{predicate}_#{subject}_#{index} = true;"
    end)
  end

  # Generate objective function
  defp generate_objective_for_variables(_goals, variables, options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time ->
        time_var_names = Enum.map(variables.time_vars, & &1.name)
        if length(time_var_names) > 0 do
          "solve minimize max([#{Enum.join(time_var_names, ", ")}]);"
        else
          "solve minimize 0;"
        end
      :minimize_distance ->
        location_var_names = Enum.map(variables.location_vars, & &1.name)
        if length(location_var_names) > 0 do
          "solve minimize sum([#{Enum.join(location_var_names, ", ")}]);"
        else
          "solve minimize 0;"
        end
      :maximize_efficiency ->
        boolean_var_names = Enum.map(variables.boolean_vars, & &1.name)
        if length(boolean_var_names) > 0 do
          bool_conditions = Enum.map(boolean_var_names, fn name -> "if #{name} then 1 else 0 endif" end)
          "solve maximize sum([#{Enum.join(bool_conditions, ", ")}]);"
        else
          "solve maximize 0;"
        end
      _ ->
        "solve minimize 0;"
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

  # Get template path - updated for aria_solver location
  defp template_path do
    Path.join([Application.app_dir(:aria_solver), "priv", "templates", "goal_solving.mzn.eex"])
  end
end
