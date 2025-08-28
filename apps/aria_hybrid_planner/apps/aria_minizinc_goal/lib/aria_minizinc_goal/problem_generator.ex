# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincGoal.ProblemGenerator do
  @moduledoc """
  Generates MiniZinc constraint satisfaction problems from planning requests.

  This module converts planning goals and domain information into MiniZinc
  constraint problems that can be solved by the MiniZinc solver.
  """

  require Logger

  @doc """
  Generate a MiniZinc problem from planning parameters.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints

  ## Returns
  - `{:ok, problem_data}` - Successfully generated problem
  - `{:error, reason}` - Failed to generate problem
  """
  def generate_problem(domain, state, goals, options \\ %{}) do
    try do
      Logger.debug("Generating MiniZinc problem for #{length(goals)} goals")

      # Convert goals to constraint variables
      variables = extract_variables(goals, state)

      # Generate constraints from domain and goals
      constraints = generate_constraints(domain, state, goals, options)

      # Create objective function
      objective = generate_objective(goals, options)

      # Build complete MiniZinc model
      model = build_minizinc_model(variables, constraints, objective)

      problem_data = %{
        model: model,
        variables: variables,
        constraints: constraints,
        objective: objective,
        metadata: %{
          goal_count: length(goals),
          variable_count: length(variables),
          constraint_count: length(constraints),
          generation_time: System.monotonic_time(:millisecond)
        }
      }

      {:ok, problem_data}
    rescue
      error ->
        Logger.error("Failed to generate MiniZinc problem: #{inspect(error)}")
        {:error, "Problem generation failed: #{Exception.message(error)}"}
    end
  end

  # Extract decision variables from goals and state
  defp extract_variables(goals, _state) do
    # Extract entities and their possible values
    entities = goals
    |> Enum.map(fn {subject, _predicate, _value} -> subject end)
    |> Enum.uniq()

    # Create variables for each entity's possible states
    Enum.flat_map(entities, fn entity ->
      [
        %{name: "#{entity}_location", type: "var int", domain: "1..10"},
        %{name: "#{entity}_time", type: "var int", domain: "0..100"},
        %{name: "#{entity}_active", type: "var bool", domain: nil}
      ]
    end)
  end

  # Generate constraints from domain rules and goals
  defp generate_constraints(domain, state, goals, options) do
    goal_constraints = generate_goal_constraints(goals)
    domain_constraints = generate_domain_constraints(domain, state)
    temporal_constraints = generate_temporal_constraints(goals, options)

    goal_constraints ++ domain_constraints ++ temporal_constraints
  end

  # Generate constraints to satisfy goals
  defp generate_goal_constraints(goals) do
    Enum.map(goals, fn {subject, predicate, value} ->
      case predicate do
        "location" ->
          "constraint #{subject}_location = #{encode_location(value)};"
        "state" ->
          "constraint #{subject}_active = #{encode_boolean(value)};"
        _ ->
          "constraint true; % Generic goal: #{subject} #{predicate} #{value}"
      end
    end)
  end

  # Generate domain-specific constraints
  defp generate_domain_constraints(_domain, _state) do
    [
      "constraint forall(i in 1..num_entities) (entity_time[i] >= 0);",
      "constraint forall(i in 1..num_entities) (entity_location[i] >= 1);",
      "constraint forall(i in 1..num_entities) (entity_location[i] <= 10);"
    ]
  end

  # Generate temporal ordering constraints
  defp generate_temporal_constraints(_goals, options) do
    if Map.get(options, :temporal_ordering, false) do
      [
        "constraint forall(i in 1..num_entities-1) (entity_time[i] <= entity_time[i+1]);"
      ]
    else
      []
    end
  end

  # Generate optimization objective
  defp generate_objective(_goals, options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time ->
        "minimize max(entity_time);"
      :minimize_distance ->
        "minimize sum(i in 1..num_entities) (entity_location[i]);"
      :maximize_efficiency ->
        "maximize sum(i in 1..num_entities) (if entity_active[i] then 1 else 0 endif);"
      _ ->
        "satisfy;"
    end
  end

  # Build complete MiniZinc model string
  defp build_minizinc_model(variables, constraints, objective) do
    variable_declarations = Enum.map(variables, fn var ->
      if var.domain do
        "#{var.type}: #{var.domain} = #{var.name};"
      else
        "#{var.type} = #{var.name};"
      end
    end)

    """
    % Generated MiniZinc Model
    % Variables: #{length(variables)}
    % Constraints: #{length(constraints)}

    % Parameters
    int: num_entities = #{div(length(variables), 3)};

    % Decision Variables
    #{Enum.join(variable_declarations, "\n")}

    % Constraints
    #{Enum.join(constraints, "\n")}

    % Objective
    #{objective}

    % Output
    output ["Solution found\\n"];
    """
  end

  # Helper functions for encoding values
  defp encode_location(location) when is_binary(location) do
    # Simple hash-based encoding for location names
    :erlang.phash2(location, 10) + 1
  end
  defp encode_location(location) when is_integer(location), do: location

  defp encode_boolean(true), do: "true"
  defp encode_boolean(false), do: "false"
  defp encode_boolean("true"), do: "true"
  defp encode_boolean("false"), do: "false"
  defp encode_boolean(_), do: "true"
end
