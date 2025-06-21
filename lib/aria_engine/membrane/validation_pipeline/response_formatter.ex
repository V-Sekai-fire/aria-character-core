defmodule AriaEngine.Membrane.ValidationPipeline.ResponseFormatter do
  @moduledoc """
  Handles formatting validation pipeline responses for MCP protocol.
  """

  require Logger

  @doc """
  Creates a comprehensive validation response in MCP format.
  """
  def create_validation_response(
        validation_result,
        hybrid_result,
        minizinc_result,
        mcp_request,
        state
      ) do
    %{
      "id" => mcp_request["id"],
      "jsonrpc" => "2.0",
      "result" => %{
        "status" => Atom.to_string(validation_result.overall_status),
        "validation_type" => "pipeline_validation",
        "reason" => validation_result.reason,
        "hybrid_solved" => validation_result.hybrid_solved,
        "minizinc_solved" => validation_result.minizinc_solved,
        "solutions_match" => validation_result.solutions_match,
        "minizinc_available" => state.minizinc_available,
        "hybrid_result" => format_solver_result(hybrid_result, "hybrid"),
        "minizinc_result" => format_solver_result(minizinc_result, "minizinc"),
        "solution_trees" => %{
          "hybrid" => create_solution_tree(hybrid_result),
          "minizinc" => create_solution_tree(minizinc_result)
        },
        "metadata" => %{
          "validation_count" => state.validation_count + 1,
          "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "pipeline" => "validation_pipeline_filter"
        }
      }
    }
  end

  @doc """
  Formats solver result for inclusion in response.
  """
  def format_solver_result(result, solver_name) do
    %{
      "solver" => solver_name,
      "status" => Atom.to_string(result.status),
      "solve_time_ms" => Map.get(result, :solve_time_ms),
      "solution" => Map.get(result, :solution),
      "error" => Map.get(result, :error),
      "reason" => Map.get(result, :reason)
    }
  end

  @doc """
  Creates a solution tree representation for visualization.
  """
  def create_solution_tree(result) do
    case result.status do
      :success ->
        solution = Map.get(result, :solution, %{})
        activities = Map.get(solution, :activities, [])

        %{
          "type" => "solution",
          "makespan" => Map.get(solution, :makespan, 0),
          "activities" => Enum.map(activities, &format_activity_node/1),
          "resource_utilization" => Map.get(solution, :resource_utilization, %{}),
          "solve_time_ms" => Map.get(result, :solve_time_ms, 0)
        }

      :error ->
        %{
          "type" => "error",
          "error" => Map.get(result, :error, "Unknown error"),
          "solve_time_ms" => Map.get(result, :solve_time_ms, 0)
        }

      :unavailable ->
        %{
          "type" => "unavailable",
          "reason" => Map.get(result, :reason, "Solver not available")
        }

      :unsupported ->
        %{
          "type" => "unsupported",
          "reason" => Map.get(result, :reason, "Problem type not supported")
        }

      _ ->
        %{
          "type" => "unknown",
          "status" => Atom.to_string(result.status)
        }
    end
  end

  # Private functions

  defp format_activity_node(activity) do
    %{
      "id" => activity.id || activity["id"],
      "start_time" => activity.start_time || activity["start_time"] || 0,
      "end_time" => activity.end_time || activity["end_time"] || 0,
      "duration" => activity.duration || activity["duration"] || 0,
      "type" => "activity"
    }
  end
end
