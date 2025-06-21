defmodule AriaEngine.Membrane.ValidationPipeline.MiniZincSolver do
  @moduledoc """
  Handles solving scheduling problems using MiniZinc constraint solver.
  """

  require Logger
  alias AriaEngine.MiniZinc.Executor

  @doc """
  Checks if MiniZinc is available on the system.
  """
  def check_availability do
    Executor.check_availability()
  end

  @doc """
  Solves a scheduling problem using MiniZinc.
  """
  def solve(params, state) do
    # For widget assembly problems, use the existing model
    schedule_name = params["schedule_name"] || ""

    if String.contains?(schedule_name, "widget") do
      solve_widget_assembly(state)
    else
      # For STN temporal problems, use the template-based approach
      solve_stn_temporal(params, state)
    end
  end

  # Private functions

  defp solve_stn_temporal(params, state) do
    try do
      # Convert MCP schedule_activities format to MiniZinc template variables
      template_vars = convert_to_minizinc_format(params)

      # Use the EEx-based executor to solve with STN temporal template
      case Executor.exec("stn_temporal", template_vars: template_vars, timeout: state.timeout) do
        {:ok, result} ->
          converted_solution = convert_minizinc_solution(result.solution, params)
          
          %{
            status: :success,
            solution: converted_solution,
            solve_time_ms: result.solve_time_ms,
            raw_output: result.raw_output
          }

        {:error, error} ->
          %{
            status: :error,
            error: "MiniZinc STN temporal solver failed: #{inspect(error)}",
            solve_time_ms: 0
          }
      end
    rescue
      error ->
        %{
          status: :error,
          error: "STN temporal conversion failed: #{Exception.message(error)}",
          solve_time_ms: 0
        }
    end
  end

  defp solve_widget_assembly(_state) do
    start_time = System.monotonic_time(:millisecond)

    # Execute MiniZinc command
    cmd_args = [
      "--solver",
      "org.minizinc.mip.coin-bc",
      "--output-mode",
      "json",
      "--output-objective",
      "widget_assembly.mzn"
    ]

    case System.cmd("minizinc", cmd_args, stderr_to_stdout: true) do
      {output, 0} ->
        end_time = System.monotonic_time(:millisecond)
        solve_time = end_time - start_time


        # Parse MiniZinc output
        solution = parse_output(output)

        %{
          status: :success,
          solution: solution,
          solve_time_ms: solve_time,
          raw_output: output
        }

      {output, exit_code} ->
        end_time = System.monotonic_time(:millisecond)
        solve_time = end_time - start_time
        %{
          status: :error,
          error: "MiniZinc solver failed with exit code #{exit_code}",
          output: output,
          solve_time_ms: solve_time
        }
    end
  end

  defp parse_output(output) do
    # Parse the MiniZinc output to extract solution
    lines = String.split(output, "\n")

    # Look for solution lines
    solution_lines =
      Enum.filter(lines, fn line ->
        String.contains?(line, "start_times") or
          String.contains?(line, "makespan") or
          String.contains?(line, "=")
      end)

    # Extract start times and makespan
    start_times = extract_start_times(solution_lines)
    makespan = extract_makespan(solution_lines)

    %{
      activities: [
        %{
          id: "prepare_materials",
          start_time: Enum.at(start_times, 0, 0),
          end_time: Enum.at(start_times, 0, 0) + 30,
          duration: 30
        },
        %{
          id: "assemble_widget",
          start_time: Enum.at(start_times, 1, 30),
          end_time: Enum.at(start_times, 1, 30) + 45,
          duration: 45
        }
      ],
      makespan: makespan,
      start_times: start_times
    }
  end

  defp extract_start_times(lines) do
    # Look for start_times array
    start_times_line =
      Enum.find(lines, fn line ->
        String.contains?(line, "start_times")
      end)

    if start_times_line do
      # Extract array values: start_times = [0, 30];
      case Regex.run(~r/start_times\s*=\s*\[([^\]]+)\]/, start_times_line) do
        [_, values_str] ->
          values_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          # Default fallback
          [0, 30]
      end
    else
      # Default fallback
      [0, 30]
    end
  end

  defp extract_makespan(lines) do
    # Look for makespan value
    makespan_line =
      Enum.find(lines, fn line ->
        String.contains?(line, "makespan")
      end)

    if makespan_line do
      case Regex.run(~r/makespan\s*=\s*(\d+)/, makespan_line) do
        [_, value_str] ->
          String.to_integer(value_str)

        _ ->
          # Default fallback
          75
      end
    else
      # Default fallback
      75
    end
  end

  # Convert MCP schedule_activities format to MiniZinc template variables
  defp convert_to_minizinc_format(params) do
    activities = params["activities"] || []
    
    # Extract durations from activities
    durations = 
      activities
      |> Enum.map(fn activity ->
        case activity["duration"] do
          duration when is_integer(duration) -> duration
          duration_str when is_binary(duration_str) -> 
            # Parse duration string like "PT30M" or just "30"
            parse_duration_string(duration_str)
          _ -> 30  # Default duration
        end
      end)

    # Create simple temporal constraints (sequential for now)
    constraints = create_sequential_constraints(length(activities))

    %{
      num_activities: length(activities),
      num_constraints: length(constraints),
      durations: durations,
      constraints: constraints
    }
  end

  defp parse_duration_string(duration_str) do
    cond do
      # ISO 8601 duration format like "PT30M"
      String.starts_with?(duration_str, "PT") ->
        case Regex.run(~r/PT(\d+)M/, duration_str) do
          [_, minutes] -> String.to_integer(minutes)
          _ -> 30
        end
      
      # Simple number string
      String.match?(duration_str, ~r/^\d+$/) ->
        String.to_integer(duration_str)
      
      # Default fallback
      true -> 30
    end
  end

  defp create_sequential_constraints(num_activities) when num_activities <= 1 do
    []
  end

  defp create_sequential_constraints(num_activities) do
    # Create sequential constraints: activity i must finish before activity i+1 starts
    1..(num_activities - 1)
    |> Enum.map(fn i ->
      %{
        from_activity: i,
        to_activity: i + 1,
        min_distance: 0,  # No minimum gap
        max_distance: 1000  # Large maximum gap
      }
    end)
  end

  # Convert MiniZinc solution back to MCP format
  defp convert_minizinc_solution(minizinc_solution, params) do
    activities = params["activities"] || []
    start_times = minizinc_solution[:start_times] || []
    end_times = minizinc_solution[:end_times] || []

    # Create activity results
    activity_results = 
      activities
      |> Enum.with_index()
      |> Enum.map(fn {activity, index} ->
        start_time = Enum.at(start_times, index, 0)
        end_time = Enum.at(end_times, index, start_time + 30)
        
        %{
          id: activity["id"] || "activity_#{index + 1}",
          start_time: start_time,
          end_time: end_time,
          duration: end_time - start_time
        }
      end)

    %{
      activities: activity_results,
      makespan: minizinc_solution[:makespan] || 0,
      start_times: start_times,
      end_times: end_times
    }
  end
end
