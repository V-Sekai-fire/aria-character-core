# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator do
  @moduledoc """
  Generates MiniZinc constraint satisfaction problems from planning requests.

  This module converts planning goals and domain information into MiniZinc
  constraint problems that can be solved by the MiniZinc solver.
  """

  require Logger
  alias AriaEngine.State
  import Timex

  # Type definitions
  @type goal :: {subject :: String.t(), predicate :: String.t(), object :: term()}
  @type state :: AriaEngine.State.t()
  @type iso8601_datetime :: String.t()  # "2025-06-23T23:16:07.123456-07:00"
  @type iso8601_duration :: String.t()  # "PT1.234S"

  @type variable :: %{
    name: String.t(),
    type: String.t(),
    domain: Range.t() | nil | String.t()
  }

  @type structured_variables :: %{
    time_vars: [variable()],
    location_vars: [variable()],
    boolean_vars: [variable()]
  }

  @type constraint :: %{
    type: :equality | :domain | :temporal_ordering | :generic,
    variable: String.t(),
    value: term(),
    description: String.t(),
    constraint: String.t(),
    min: integer(),
    max: integer()
  }

  @type problem_metadata :: %{
    goal_count: non_neg_integer(),
    variable_count: non_neg_integer(),
    constraint_count: non_neg_integer(),
    optimization: atom(),
    generation_start: iso8601_datetime(),
    generation_end: iso8601_datetime(),
    generation_duration: iso8601_duration()
  }

  @type problem_data :: %{
    model: String.t(),
    variables: structured_variables(),
    constraints: [constraint()],
    objective: String.t(),
    metadata: problem_metadata()
  }

  @type domain :: map()
  @type options :: map()

  @template_dir "priv/templates/minizinc"
  @goal_solving_template "goal_solving.mzn.eex"
  @simple_temporal_network_template "simple_temporal_network.mzn.eex"

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
  @spec generate_problem(domain(), state(), [goal()], options()) ::
          {:ok, problem_data()} | {:error, String.t()}
  def generate_problem(domain, state, goals, options \\ %{}) do
    # Capture generation start time in local timezone ISO 8601 format
    generation_start = Timex.now() |> Timex.format!("{ISO:Extended}")

    try do
      Logger.debug("Generating MiniZinc problem for #{length(goals)} goals")

      # Convert goals to constraint variables
      variables = extract_variables(goals, state)

      # Generate constraints from domain and goals
      constraints = generate_constraints(domain, state, goals, options)

      # Create objective function
      objective = generate_objective(goals, options)

      # Build complete MiniZinc model
      model = build_minizinc_model(variables, constraints, objective, generation_start)

      # Calculate total variable count from structured variables
      variable_count = count_total_variables(variables)

      # Capture generation end time and calculate duration
      generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
      generation_duration = calculate_duration(generation_start, generation_end)

      problem_data = %{
        model: model,
        variables: variables,
        constraints: constraints,
        objective: objective,
        metadata: %{
          goal_count: length(goals),
          variable_count: variable_count,
          constraint_count: length(constraints),
          optimization: determine_optimization_type(options),
          domain: domain,
          generation_start: generation_start,
          generation_end: generation_end,
          generation_duration: generation_duration
        }
      }

      {:ok, problem_data}
    rescue
      error ->
        Logger.error("Failed to generate MiniZinc problem: #{inspect(error)}")
        {:error, "Problem generation failed: #{Exception.message(error)}"}
    end
  end

  # Calculate duration between two ISO 8601 timestamps
  @spec calculate_duration(iso8601_datetime(), iso8601_datetime()) :: iso8601_duration()
  defp calculate_duration(start_iso, end_iso) do
    start_dt = Timex.parse!(start_iso, "{ISO:Extended}")
    end_dt = Timex.parse!(end_iso, "{ISO:Extended}")

    # Use microseconds as Timex's most precise integer duration element
    duration_microseconds = Timex.diff(end_dt, start_dt, :microseconds)
    duration_seconds = duration_microseconds / 1_000_000
    "PT#{duration_seconds}S"
  end

  # Extract decision variables from goals and state - returns structured format
  @spec extract_variables([goal()], state()) :: structured_variables()
  defp extract_variables(goals, _state) do
    # Handle malformed goals gracefully
    valid_goals = Enum.filter(goals, fn
      {subject, _predicate, _value} when is_binary(subject) -> true
      _ -> false
    end)

    # Extract entities and their possible values
    entities = valid_goals
    |> Enum.map(fn {subject, _predicate, _value} -> subject end)
    |> Enum.uniq()

    # Create categorized variables for each entity
    time_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_time", type: "var int", domain: 0..100}
    end)

    location_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_location", type: "var int", domain: 1..10}
    end)

    boolean_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_active", type: "var bool", domain: nil}
    end)

    %{
      time_vars: time_vars,
      location_vars: location_vars,
      boolean_vars: boolean_vars
    }
  end

  # Count total variables from structured format
  defp count_total_variables(variables) do
    length(variables.time_vars) + length(variables.location_vars) + length(variables.boolean_vars)
  end

  # Determine optimization type from options
  defp determine_optimization_type(options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time -> :minimize_steps
      :minimize_distance -> :minimize_distance
      :maximize_efficiency -> :maximize_efficiency
      _ -> :minimize_steps
    end
  end

  # Generate constraints from domain rules and goals - returns structured format
  defp generate_constraints(domain, state, goals, options) do
    goal_constraints = generate_goal_constraints(goals)
    domain_constraints = generate_domain_constraints(domain, state)
    temporal_constraints = generate_temporal_constraints(goals, options)

    goal_constraints ++ domain_constraints ++ temporal_constraints
  end

  # Generate constraints to satisfy goals - returns structured constraint maps
  defp generate_goal_constraints(goals) do
    # Filter out malformed goals
    valid_goals = Enum.filter(goals, fn
      {subject, predicate, _value} when is_binary(subject) and is_binary(predicate) -> true
      _ -> false
    end)

    Enum.map(valid_goals, fn {subject, predicate, value} ->
      case predicate do
        "location" ->
          %{
            type: :equality,
            variable: "#{subject}_location",
            value: encode_location(value),
            description: "Goal: #{subject} at #{value}"
          }
        "state" ->
          %{
            type: :equality,
            variable: "#{subject}_active",
            value: encode_boolean(value),
            description: "Goal: #{subject} state #{value}"
          }
        _ ->
          %{
            type: :generic,
            description: "Generic goal: #{subject} #{predicate} #{value}",
            constraint: "true"
          }
      end
    end)
  end

  # Generate domain-specific constraints - returns structured constraint maps
  defp generate_domain_constraints(_domain, _state) do
    [
      %{
        type: :domain,
        variable: "entity_time",
        constraint: "forall",
        min: 0,
        description: "Time variables must be non-negative"
      },
      %{
        type: :domain,
        variable: "entity_location",
        constraint: "forall",
        min: 1,
        max: 10,
        description: "Location variables must be in valid range"
      }
    ]
  end

  # Generate temporal ordering constraints - returns structured constraint maps
  defp generate_temporal_constraints(goals, options) do
    if (Map.get(options, :temporal_ordering, false) or Map.get(options, :temporal_constraints, false)) and length(goals) > 1 do
      [
        %{
          type: :temporal_ordering,
          constraint: "forall",
          description: "Sequential temporal ordering"
        }
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
        "minimize max(entity_time);"
    end
  end

  # Build complete MiniZinc model using template
  defp build_minizinc_model(variables, constraints, objective, generation_start) do
    # Convert structured data to template format
    variable_count = count_total_variables(variables)

    # Pre-process variables with formatted domains
    processed_variables = %{
      time_vars: Enum.map(variables.time_vars, &process_variable/1),
      location_vars: Enum.map(variables.location_vars, &process_variable/1),
      boolean_vars: Enum.map(variables.boolean_vars, &process_variable/1)
    }

    # Pre-process constraints with rendered strings
    processed_constraints = Enum.map(constraints, &render_constraint/1)

    template_vars = %{
      variables: processed_variables,
      constraints: processed_constraints,
      objective: objective,
      num_entities: div(variable_count, 3),
      variable_count: variable_count,
      constraint_count: length(constraints),
      generation_start: generation_start
    }

    render_template(@goal_solving_template, template_vars)
  end

  # Process variable with formatted domain
  defp process_variable(var) do
    %{var | domain: format_domain(var.domain)}
  end

  # Load and render a MiniZinc template
  defp render_template(template_name, vars) do
    template_path = Path.join([@template_dir, template_name])

    case File.read(template_path) do
      {:ok, template_content} ->
        EEx.eval_string(template_content, assigns: vars)
      {:error, reason} ->
        Logger.error("Failed to load template #{template_name}: #{inspect(reason)}")
        raise "Template loading failed: #{template_name}"
    end
  end

  # Format domain for MiniZinc syntax
  defp format_domain(min..max//1), do: "#{min}..#{max}"
  defp format_domain(nil), do: ""
  defp format_domain(domain) when is_integer(domain), do: "#{domain}"
  defp format_domain(domain), do: "#{inspect(domain)}"

  # Render structured constraint to MiniZinc string
  defp render_constraint(%{type: :equality, variable: var, value: val, description: desc}) do
    "constraint #{var} = #{val}; % #{desc}"
  end

  defp render_constraint(%{type: :domain, variable: var, min: min, max: max, description: desc}) do
    "constraint forall(i in 1..num_entities) (#{var}[i] >= #{min} /\\ #{var}[i] <= #{max}); % #{desc}"
  end

  defp render_constraint(%{type: :domain, variable: var, min: min, description: desc}) do
    "constraint forall(i in 1..num_entities) (#{var}[i] >= #{min}); % #{desc}"
  end

  defp render_constraint(%{type: :temporal_ordering, description: desc}) do
    "constraint forall(i in 1..num_entities-1) (entity_time[i] <= entity_time[i+1]); % #{desc}"
  end

  defp render_constraint(%{type: :generic, constraint: constraint, description: desc}) do
    "constraint #{constraint}; % #{desc}"
  end

  defp render_constraint(%{type: :generic, description: desc}) do
    "constraint true; % #{desc}"
  end

  defp render_constraint(constraint) do
    "constraint true; % Unknown constraint: #{inspect(constraint)}"
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
