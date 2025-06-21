defmodule AriaEngine.Membrane.ValidationPipeline.HybridSolver do
  @moduledoc """
  Handles solving scheduling problems using the AriaEngine Hybrid solver.
  """

  require Logger

  @doc """
  Solves a scheduling problem using the AriaEngine Hybrid solver.
  """
  def solve(params, state) do
    Logger.info("🔧 Calling Hybrid solver")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Call the real AriaEngine scheduler
      case AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
             params["schedule_name"] || "validation_test",
             params["activities"] || [],
             params["entities"] || [],
             params["resources"] || %{},
             params["constraints"] || %{},
             # simulation_mode
             true,
             # activity_log
             true,
             # verbose
             1
           ) do
        {:ok, result} ->
          end_time = System.monotonic_time(:millisecond)
          solve_time = end_time - start_time

          Logger.info("✅ Hybrid solver completed in #{solve_time}ms")

          %{
            status: :success,
            solution: extract_solution(result),
            solve_time_ms: solve_time,
            raw_result: result
          }

        {:error, reason} ->
          end_time = System.monotonic_time(:millisecond)
          solve_time = end_time - start_time

          Logger.error("❌ Hybrid solver failed: #{reason}")

          %{
            status: :error,
            error: reason,
            solve_time_ms: solve_time
          }
      end
    rescue
      error ->
        Logger.error("❌ Hybrid solver exception: #{inspect(error)}")

        %{
          status: :error,
          error: "Hybrid solver exception: #{Exception.message(error)}"
        }
    end
  end

  @doc """
  Extracts solution data from AriaEngine scheduler result.
  """
  def extract_solution(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{schedule: schedule} ->
        %{
          activities: extract_activities_from_schedule(schedule),
          makespan: calculate_makespan(schedule),
          resource_utilization: extract_resource_utilization(result)
        }

      %{schedule: schedule} ->
        %{
          activities: extract_activities_from_schedule(schedule),
          makespan: calculate_makespan(schedule),
          resource_utilization: %{}
        }

      _ ->
        %{
          activities: [],
          makespan: 0,
          resource_utilization: %{}
        }
    end
  end

  # Private functions

  defp extract_activities_from_schedule(schedule) when is_list(schedule) do
    Enum.map(schedule, fn activity ->
      %{
        id: activity["id"] || activity[:id],
        start_time: parse_time_value(activity["start_time"] || activity[:start_time]),
        end_time: parse_time_value(activity["end_time"] || activity[:end_time]),
        duration: parse_time_value(activity["duration"] || activity[:duration])
      }
    end)
  end

  defp extract_activities_from_schedule(_), do: []

  defp parse_time_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, _} -> int_val
      :error -> 0
    end
  end

  defp parse_time_value(value) when is_integer(value), do: value
  defp parse_time_value(_), do: 0

  defp calculate_makespan(schedule) when is_list(schedule) do
    schedule
    |> Enum.map(fn activity ->
      parse_time_value(activity["end_time"] || activity[:end_time])
    end)
    |> Enum.max(fn -> 0 end)
  end

  defp calculate_makespan(_), do: 0

  defp extract_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end
end
