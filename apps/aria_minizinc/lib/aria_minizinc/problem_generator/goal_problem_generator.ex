# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator.GoalProblemGenerator do
  @moduledoc """
  Generates MiniZinc goal-solving problems from planning requests.

  This module handles the generation of constraint satisfaction problems
  for goal-oriented planning scenarios.
  """

  require Logger
  alias AriaMiniZinc.ProblemGenerator.Common

  @goal_solving_template "goal_solving.mzn.eex"

  @doc """
  Generate a goal-solving MiniZinc problem.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints
  - `generation_start` - ISO8601 timestamp when generation started

  ## Returns
  - `{:ok, problem_data}` - Successfully generated problem
  - `{:error, reason}` - Failed to generate problem
  """
  @spec generate(Common.domain(), Common.state(), [Common.goal()], Common.options(), Common.iso8601_datetime()) ::
          {:ok, map()} | {:error, String.t()}
  def generate(domain, state, goals, options, generation_start) do
    try do
      Logger.debug("Generating goal-solving MiniZinc problem for #{length(goals)} goals")

      # Extract variables and constraints
      variables = Common.extract_variables(goals, state)
      constraints = Common.generate_constraints(domain, state, goals, options)
      objective = generate_objective_for_variables(goals, variables, options)

      # Calculate counts
      variable_count = Common.count_total_variables(variables)
      constraint_count = length(constraints)

      # Process variables with formatted domains
      processed_variables = %{
        time_vars: Enum.map(variables.time_vars, &Common.process_variable/1),
        location_vars: Enum.map(variables.location_vars, &Common.process_variable/1),
        boolean_vars: Enum.map(variables.boolean_vars, &Common.process_variable/1)
      }

      # Render constraints to strings
      rendered_constraints = Enum.map(constraints, &Common.render_constraint/1)

      # Prepare template variables
      template_vars = %{
        variable_count: variable_count,
        constraint_count: constraint_count,
        generation_start: generation_start,
        num_entities: div(variable_count, 3),
        variables: processed_variables,
        constraints: rendered_constraints,
        objective: objective
      }

      # Render the MiniZinc model using template
      model = Common.render_template(@goal_solving_template, template_vars)

      # Calculate generation end time and duration
      generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
      generation_duration = Common.calculate_duration(generation_start, generation_end)

      # Create metadata
      metadata = %{
        goal_count: length(goals),
        variable_count: variable_count,
        constraint_count: constraint_count,
        optimization: Common.determine_optimization_type(options),
        generation_start: generation_start,
        generation_end: generation_end,
        generation_duration: generation_duration,
        domain: "goal_solving"
      }

      # Return data structure with both :model and :type for compatibility
      {:ok, %{
        model: model,
        type: :goal_solving,
        variable_count: variable_count,
        constraint_count: constraint_count,
        generation_start: generation_start,
        num_entities: div(variable_count, 3),
        variables: processed_variables,
        constraints: constraints,  # Keep raw constraints for test compatibility
        rendered_constraints: rendered_constraints,  # Add rendered version
        objective: objective,
        metadata: metadata
      }}
    rescue
      error ->
        Logger.error("Failed to generate goal-solving MiniZinc problem: #{inspect(error)}")
        {:error, "Goal-solving problem generation failed: #{Exception.message(error)}"}
    end
  end

  # Generate objective function that references actual declared variables
  defp generate_objective_for_variables(_goals, variables, options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time ->
        # Create objective that references actual time variables
        time_var_names = Enum.map(variables.time_vars, & &1.name)
        if length(time_var_names) > 0 do
          "minimize max([#{Enum.join(time_var_names, ", ")}]);"
        else
          "minimize 0;"
        end
      :minimize_distance ->
        # Create objective that references actual location variables
        location_var_names = Enum.map(variables.location_vars, & &1.name)
        if length(location_var_names) > 0 do
          "minimize sum([#{Enum.join(location_var_names, ", ")}]);"
        else
          "minimize 0;"
        end
      :maximize_efficiency ->
        # Create objective that references actual boolean variables
        boolean_var_names = Enum.map(variables.boolean_vars, & &1.name)
        if length(boolean_var_names) > 0 do
          bool_conditions = Enum.map(boolean_var_names, fn name -> "if #{name} then 1 else 0 endif" end)
          "maximize sum([#{Enum.join(bool_conditions, ", ")}]);"
        else
          "maximize 0;"
        end
      _ ->
        # Default to minimize time
        time_var_names = Enum.map(variables.time_vars, & &1.name)
        if length(time_var_names) > 0 do
          "minimize max([#{Enum.join(time_var_names, ", ")}]);"
        else
          "minimize 0;"
        end
    end
  end
end
