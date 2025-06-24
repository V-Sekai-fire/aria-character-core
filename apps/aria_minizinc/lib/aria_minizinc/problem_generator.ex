# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator do
  @moduledoc """
  Generates MiniZinc constraint satisfaction problems from planning requests.

  This module converts planning goals and domain information into MiniZinc
  constraint problems that can be solved by the MiniZinc solver.
  """

  require Logger

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

  # True STN type definitions (mathematically sound)
  @type stn_time_point :: non_neg_integer()  # Time point index

  @type stn_distance_constraint :: %{
    from_point: non_neg_integer(),
    to_point: non_neg_integer(),
    distance: integer()  # Maximum distance: to_point - from_point ≤ distance
  }

  @type stn_problem_data :: %{
    num_time_points: non_neg_integer(),
    time_point_names: [String.t()],  # Human-readable names for time points
    distance_matrix: [[integer()]],  # Full distance constraint matrix
    horizon: non_neg_integer()       # Maximum time value
  }

  # Legacy STN types (for backward compatibility during transition)
  @type legacy_stn_activity :: %{
    id: non_neg_integer(),
    name: String.t(),
    duration: non_neg_integer()
  }

  @type legacy_stn_constraint :: %{
    from_activity: non_neg_integer(),
    to_activity: non_neg_integer(),
    min_distance: integer(),
    max_distance: integer()
  }

  @template_dir "priv/templates/minizinc"
  @goal_solving_template "goal_solving.mzn.eex"
  @simple_temporal_network_template "stn_temporal.mzn.eex"

  @doc """
  Generate and solve a MiniZinc problem from planning parameters.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints

  ## Returns
  - `{:ok, result}` - Successfully solved problem with solution
  - `{:error, reason}` - Failed to generate or solve problem
  """
  @spec solve_problem(domain(), state(), [goal()], options()) ::
          {:ok, map()} | {:error, String.t()}
  def solve_problem(domain, state, goals, options \\ %{}) do
    with {:ok, problem_data} <- generate_problem(domain, state, goals, options),
         {:ok, result} <- AriaMiniZinc.Solver.solve(problem_data, prepare_solver_options(options, problem_data)) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

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
      model = build_minizinc_model(variables, constraints, objective, generation_start, options)

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

  # Build complete MiniZinc model using template selection
  defp build_minizinc_model(variables, constraints, objective, generation_start, options) do
    # Select appropriate template based on problem characteristics
    selected_template = select_template(variables, constraints, options)

    Logger.debug("Selected template: #{selected_template}")

    case selected_template do
      @simple_temporal_network_template ->
        build_stn_model(variables, constraints, objective, generation_start, options)
      @goal_solving_template ->
        build_goal_solving_model(variables, constraints, objective, generation_start)
    end
  end

  # Build goal-solving model (existing logic)
  defp build_goal_solving_model(variables, constraints, objective, generation_start) do
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

  # Build STN model with True STN time point data transformation
  defp build_stn_model(variables, constraints, objective, generation_start, options) do
    stn_data = transform_to_stn_format(variables, constraints, objective, options)

    template_vars = %{
      num_time_points: stn_data.num_time_points,
      time_point_names: stn_data.time_point_names,
      distance_matrix: stn_data.distance_matrix,
      horizon: stn_data.horizon,
      generation_start: generation_start
    }

    render_template(@simple_temporal_network_template, template_vars)
  end

  # Template selection logic
  defp select_template(_variables, _constraints, options) do
    if is_stn_problem?(options) do
      @simple_temporal_network_template
    else
      @goal_solving_template
    end
  end

  # STN problem detection logic
  defp is_stn_problem?(options) do
    Map.get(options, :problem_type) == :stn
  end

  # Transform goal-solving data to True STN format
  @spec transform_to_stn_format(structured_variables(), [constraint()], String.t(), options()) :: stn_problem_data()
  defp transform_to_stn_format(variables, constraints, _objective, options) do
    # Extract time points from variables (activities become time point pairs)
    time_points = extract_stn_time_points(variables, options)

    # Generate distance matrix for all time point relationships
    distance_matrix = generate_stn_distance_matrix(time_points, constraints, options)

    # Calculate horizon (maximum time value)
    horizon = Map.get(options, :horizon, 1000)

    # Handle empty STN cases properly without dummy points
    %{
      num_time_points: length(time_points),
      time_point_names: time_points,
      distance_matrix: distance_matrix,
      horizon: horizon
    }
  end

  # Extract STN time points from structured variables
  @spec extract_stn_time_points(structured_variables(), options()) :: [String.t()]
  defp extract_stn_time_points(variables, _options) do
    # Convert each entity to time point pairs (start_point, end_point)
    variables.time_vars
    |> Enum.flat_map(fn var ->
      # Extract entity name from variable name (remove "_time" suffix)
      entity_name = String.replace(var.name, "_time", "")

      # Create start and end time points for each entity/activity
      ["#{entity_name}_start", "#{entity_name}_end"]
    end)
  end

  # Generate STN distance constraint matrix
  @spec generate_stn_distance_matrix([String.t()], [constraint()], options()) :: [[integer()]]
  defp generate_stn_distance_matrix(time_points, constraints, options) do
    num_points = length(time_points)
    default_duration = Map.get(options, :default_duration, 30)

    # Handle empty case - return empty matrix
    if num_points == 0 do
      []
    else
      # Initialize distance matrix with infinity (represented as large number)
      infinity = 999999
      base_matrix = for _i <- 1..num_points, do: (for _j <- 1..num_points, do: infinity)

      # Set diagonal to 0 (distance from point to itself)
      diagonal_matrix = base_matrix
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {val, j} ->
          if i == j, do: 0, else: val
        end)
      end)

      # Add duration constraints (end_point - start_point ≤ duration)
      duration_matrix = add_duration_constraints(diagonal_matrix, time_points, default_duration)

      # Add precedence constraints from temporal ordering
      precedence_matrix = add_precedence_constraints(duration_matrix, time_points, constraints)

      precedence_matrix
    end
  end

  # Add duration constraints to distance matrix
  defp add_duration_constraints(matrix, time_points, default_duration) do
    # Find start/end point pairs and add duration constraints
    time_points
    |> Enum.with_index()
    |> Enum.reduce(matrix, fn {point_name, point_index}, acc_matrix ->
      if String.ends_with?(point_name, "_start") do
        # Find corresponding end point
        entity_name = String.replace(point_name, "_start", "")
        end_point_name = "#{entity_name}_end"

        case Enum.find_index(time_points, &(&1 == end_point_name)) do
          nil -> acc_matrix  # No corresponding end point found
          end_index ->
            # Add constraint: end_point - start_point ≤ duration
            # Also add: start_point - end_point ≤ -duration (for consistency)
            acc_matrix
            |> update_matrix_cell(point_index, end_index, default_duration)
            |> update_matrix_cell(end_index, point_index, -default_duration)
        end
      else
        acc_matrix
      end
    end)
  end

  # Add precedence constraints to distance matrix
  defp add_precedence_constraints(matrix, time_points, constraints) do
    # Check for temporal ordering constraints
    temporal_constraints = Enum.filter(constraints, fn constraint ->
      Map.get(constraint, :type) == :temporal_ordering
    end)

    if length(temporal_constraints) > 0 do
      # Add sequential precedence constraints between activities
      add_sequential_precedence(matrix, time_points)
    else
      matrix
    end
  end

  # Add sequential precedence constraints (activity A must finish before activity B starts)
  defp add_sequential_precedence(matrix, time_points) do
    # Group time points by entity
    entities = time_points
    |> Enum.map(fn point ->
      cond do
        String.ends_with?(point, "_start") -> String.replace(point, "_start", "")
        String.ends_with?(point, "_end") -> String.replace(point, "_end", "")
        true -> point
      end
    end)
    |> Enum.uniq()

    # Add precedence constraints between consecutive entities
    entities
    |> Enum.with_index()
    |> Enum.reduce(matrix, fn {_entity, entity_index}, acc_matrix ->
      if entity_index < length(entities) - 1 do
        # Current entity end point
        current_entity = Enum.at(entities, entity_index)
        next_entity = Enum.at(entities, entity_index + 1)

        current_end_name = "#{current_entity}_end"
        next_start_name = "#{next_entity}_start"

        current_end_index = Enum.find_index(time_points, &(&1 == current_end_name))
        next_start_index = Enum.find_index(time_points, &(&1 == next_start_name))

        if current_end_index && next_start_index do
          # Add constraint: next_start - current_end ≤ 0 (next can start immediately after current ends)
          update_matrix_cell(acc_matrix, current_end_index, next_start_index, 0)
        else
          acc_matrix
        end
      else
        acc_matrix
      end
    end)
  end

  # Helper function to update a cell in the distance matrix
  defp update_matrix_cell(matrix, from_index, to_index, distance) do
    matrix
    |> Enum.with_index()
    |> Enum.map(fn {row, row_index} ->
      if row_index == from_index do
        row
        |> Enum.with_index()
        |> Enum.map(fn {cell, col_index} ->
          if col_index == to_index do
            min(cell, distance)  # Take minimum of existing and new constraint
          else
            cell
          end
        end)
      else
        row
      end
    end)
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

  # Prepare solver options from planning options and problem data
  defp prepare_solver_options(options, problem_data) do
    %{
      solver_type: Map.get(options, :solver_type, :production),
      timeout: Map.get(options, :timeout, 30_000),
      solver: Map.get(options, :solver, "org.minizinc.mip.coin-bc"),
      variable_count: problem_data.metadata.variable_count,
      horizon: Map.get(options, :horizon, 1000)
    }
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
