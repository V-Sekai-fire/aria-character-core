# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.Solver do
  @moduledoc """
  Reverse routing solver implementation following ADR-176 pattern.

  Routes solver requests to appropriate implementation based on solver_type:
  - :production -> Real MiniZinc solver via Executor
  - :test -> Mock solver for testing
  """

  @behaviour AriaMiniZinc.SolverBehaviour

  alias AriaMiniZinc.{Executor, SolverBehaviour}

  @impl SolverBehaviour
  def solve(problem_data, options \\ %{}) do
    # Use test mode by default in test environment
    default_solver_type =
      case Mix.env() do
        :test -> Application.get_env(:aria_minizinc, :default_solver_type, :test)
        _ -> :production
      end

    case Map.get(options, :solver_type, default_solver_type) do
      :test ->
        solve_with_mock(problem_data, options)

      :production ->
        executor = Map.get(options, :executor, Executor)
        solve_with_real_solver(problem_data, options, executor)
    end
  end

  @doc """
  Check if MiniZinc is available on the system.
  Routes to Executor for actual availability check.
  """
  def check_availability do
    Executor.check_availability()
  end

  @doc """
  Get list of available solvers.
  Returns mock data for now.
  """
  def available_solvers do
    ["org.minizinc.mip.coin-bc", "org.chuffed.chuffed", "org.gecode.gecode", :fixpoint]
  end

  @doc """
  Validate a MiniZinc model syntax.
  Basic validation for now.
  """
  def validate_model(model) when is_binary(model) do
    cond do
      String.trim(model) == "" ->
        {:error, "Empty model"}

      String.contains?(model, "constraint") and String.contains?(model, "solve") ->
        :ok

      true ->
        {:error, "Invalid MiniZinc syntax"}
    end
  end

  # Route to mock solver for tests
  defp solve_with_mock(problem_data, options) do
    # Determine and validate problem type
    problem_type = determine_problem_type(problem_data, options)

    case problem_type do
      nil ->
        {:error, "Problem type cannot be nil"}

      "" ->
        {:error, "Problem type cannot be empty"}

      type when is_atom(type) ->
        # Generate predictable mock response based on problem data
        variable_count = Map.get(options, :variable_count, 0)

        mock_solution = %{
          start_times: generate_mock_start_times(variable_count),
          end_times: generate_mock_end_times(variable_count),
          makespan: variable_count * 30,
          objective: variable_count * 30,
          status: "SATISFIED"
        }

        # Generate assignments map for compatibility with tests
        assignments = generate_mock_assignments(variable_count)

        # Generate timing metadata with dynamic local timezone
        local_timezone = get_local_timezone()
        {:ok, solving_start} = DateTime.now(local_timezone)
        solving_end = DateTime.add(solving_start, 10_000, :microsecond)  # Mock 10ms duration

        solving_start_iso = DateTime.to_iso8601(solving_start)
        solving_end_iso = DateTime.to_iso8601(solving_end)

        duration_microseconds = DateTime.diff(solving_end, solving_start, :microsecond)
        iso8601_duration = "PT#{duration_microseconds / 1_000_000}S"

        {:ok, %{
          type: type,
          status: :success,
          solution: mock_solution,
          assignments: assignments,
          solving_start: solving_start_iso,
          solving_end: solving_end_iso,
          duration: iso8601_duration,
          raw_output: generate_mock_output(mock_solution)
        }}

      _ ->
        {:error, "Invalid problem type: #{inspect(problem_type)}"}
    end
  end

  # Route to real MiniZinc solver
  defp solve_with_real_solver(problem_data, options, executor) do
    # Extract template name from model content or use default
    template_name = determine_template_name(problem_data)

    # Convert problem data to template variables
    template_vars = convert_to_template_vars(problem_data, options)

    # Execute via injected executor
    case executor.exec(template_name, template_vars: template_vars) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, "Solver execution failed: #{inspect(reason)}"}
    end
  end

  # Generate mock start times for testing
  defp generate_mock_start_times(variable_count) when variable_count <= 0, do: []
  defp generate_mock_start_times(variable_count) do
    0..(variable_count - 1)
    |> Enum.map(fn i -> i * 30 end)
  end

  # Generate mock end times for testing
  defp generate_mock_end_times(variable_count) when variable_count <= 0, do: []
  defp generate_mock_end_times(variable_count) do
    0..(variable_count - 1)
    |> Enum.map(fn i -> (i * 30) + 25 end)
  end

  # Generate mock assignments for testing
  defp generate_mock_assignments(variable_count) when variable_count <= 0, do: %{}
  defp generate_mock_assignments(variable_count) do
    0..(variable_count - 1)
    |> Enum.reduce(%{}, fn i, acc ->
      Map.put(acc, "var_#{i}", i * 10)
    end)
  end

  # Generate mock MiniZinc output format
  defp generate_mock_output(solution) do
    """
    {
      "start_times": #{Jason.encode!(solution.start_times)},
      "end_times": #{Jason.encode!(solution.end_times)},
      "makespan": #{solution.makespan},
      "_objective": #{solution.objective},
      "status": "#{solution.status}"
    }
    ----------
    ==========
    """
  end

  # Determine template name from problem data
  defp determine_template_name(problem_data) do
    cond do
      String.contains?(problem_data.model, "Simple Temporal Network") -> "stn_temporal"
      String.contains?(problem_data.model, "Goal Solving") -> "goal_solving"
      true -> "goal_solving"  # Default fallback
    end
  end

  # Convert problem data to template variables format
  defp convert_to_template_vars(problem_data, options) do
    # Check if this is an STN problem
    if String.contains?(problem_data.model, "Simple Temporal Network") do
      # STN template variables
      %{
        num_time_points: Map.get(options, :variable_count, 3),
        time_point_names: extract_time_point_names(problem_data),
        distance_matrix: extract_distance_matrix(problem_data),
        horizon: Map.get(options, :horizon, 1000),
        generation_start: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    else
      # Goal solving template variables
      %{
        variable_count: Map.get(options, :variable_count, 0),
        constraint_count: length(problem_data.constraints),
        generation_start: DateTime.utc_now() |> DateTime.to_iso8601(),
        num_entities: div(Map.get(options, :variable_count, 0), 3),
        variables: generate_template_variables(problem_data, options),
        constraints: extract_constraints_strings(problem_data),
        objective: extract_objective(problem_data)
      }
    end
  end

  # Generate default durations for template
  defp generate_default_durations(options) do
    variable_count = Map.get(options, :variable_count, 0)
    num_activities = div(variable_count, 3)

    if num_activities > 0 do
      1..num_activities |> Enum.map(fn _ -> 25 end)
    else
      []
    end
  end

  # Extract constraints as array format
  defp extract_constraints_array(problem_data) do
    problem_data.constraints
    |> Enum.map(fn constraint ->
      case constraint do
        %{type: :temporal_ordering} -> [1, 2, 0, 100]  # [from, to, min, max]
        _ -> [0, 1, 0, 50]  # Default constraint
      end
    end)
  end

  # Extract time point names from model
  defp extract_time_point_names(problem_data) do
    # Parse from model content or generate defaults
    case Regex.run(~r/time_point_names = \[(.*?)\]/, problem_data.model) do
      [_, names_str] ->
        names_str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.trim(&1, "\""))
      _ ->
        []
    end
  end

  # Extract distance matrix from model
  defp extract_distance_matrix(problem_data) do
    # Parse from model content or generate default
    case Regex.run(~r/distance_matrix = \[\|(.*?)\|\]/, problem_data.model, [:dotall]) do
      [_, matrix_str] ->
        matrix_str
        |> String.split("|")
        |> Enum.map(fn row ->
          row
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.filter(&(&1 != ""))
          |> Enum.map(&String.to_integer/1)
        end)
        |> Enum.filter(&(length(&1) > 0))
      _ ->
        [[0]]  # Default single-point matrix
    end
  end

  # Generate template variables for goal solving template
  defp generate_template_variables(problem_data, options) do
    variable_count = Map.get(options, :variable_count, 0)

    %{
      time_vars: generate_time_variables(variable_count),
      location_vars: generate_location_variables(variable_count),
      boolean_vars: generate_boolean_variables(variable_count)
    }
  end

  # Generate time variables for template
  defp generate_time_variables(variable_count) do
    num_time_vars = div(variable_count, 3)

    if num_time_vars > 0 do
      1..num_time_vars
      |> Enum.map(fn i ->
        %{
          name: "time_#{i}",
          type: "var int",
          domain: "0..1000"
        }
      end)
    else
      []
    end
  end

  # Generate location variables for template
  defp generate_location_variables(variable_count) do
    num_location_vars = div(variable_count, 3)

    if num_location_vars > 0 do
      1..num_location_vars
      |> Enum.map(fn i ->
        %{
          name: "location_#{i}",
          type: "var int",
          domain: "1..10"
        }
      end)
    else
      []
    end
  end

  # Generate boolean variables for template
  defp generate_boolean_variables(variable_count) do
    num_bool_vars = div(variable_count, 3)

    if num_bool_vars > 0 do
      1..num_bool_vars
      |> Enum.map(fn i ->
        %{
          name: "bool_#{i}",
          type: "var bool"
        }
      end)
    else
      []
    end
  end

  # Extract constraints as strings for template
  defp extract_constraints_strings(problem_data) do
    problem_data.constraints
    |> Enum.map(fn constraint ->
      case constraint do
        %{type: :temporal_ordering} -> "constraint time_1 <= time_2;"
        %{type: :location_constraint} -> "constraint location_1 != location_2;"
        _ -> "constraint true;"  # Default constraint
      end
    end)
  end

  # Extract objective for template
  defp extract_objective(problem_data) do
    # Parse from model content or use default
    if String.contains?(problem_data.model, "minimize") do
      "solve minimize sum(time_1, time_2);"
    else
      "solve satisfy;"
    end
  end

  # Determine problem type from options or problem data
  defp determine_problem_type(problem_data, options) do
    cond do
      # Explicit type in options takes precedence
      Map.has_key?(options, :problem_type) ->
        Map.get(options, :problem_type)

      # Detect from model content
      String.contains?(problem_data.model, "Simple Temporal Network") ->
        :stn_temporal

      String.contains?(problem_data.model, "Goal Solving") ->
        :goal_solving

      # Default fallback
      true ->
        :goal_solving
    end
  end

  # Get the local timezone dynamically
  defp get_local_timezone do
    case System.get_env("TZ") do
      nil -> "Etc/UTC"  # Default to UTC if no timezone set
      tz -> tz
    end
  end
end
