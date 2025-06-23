defmodule AriaEngine.Membrane.ValidationPipeline.HybridSolver do
  @moduledoc "Handles solving scheduling problems using the AriaEngine Hybrid solver.\n"
  require Logger
  @doc "Solves a scheduling problem using the AriaEngine Hybrid solver.\n"
  def solve(params, _state) do
    Logger.info("🔧 Calling Hybrid solver")
    start_time = System.monotonic_time(:millisecond)

    try do
      activities = ensure_list(params["activities"])
      entities = ensure_list(params["entities"])
      resources = ensure_list(params["resources"])
      constraints = params["constraints"] || %{}
      base_datetime = ~U[2025-01-01 00:00:00Z]

      case AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
             params["schedule_name"] || "validation_test",
             activities,
             entities,
             resources,
             constraints,
             true,
             true,
             1,
             base_datetime
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
          %{status: :error, error: reason, solve_time_ms: solve_time}
      end
    rescue
      error ->
        Logger.error("❌ Hybrid solver exception: #{inspect(error)}")
        %{status: :error, error: "Hybrid solver exception: #{Exception.message(error)}"}
    end
  end

  @doc "Extracts solution data from AriaEngine scheduler result.\n"
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
        %{activities: [], makespan: 0, resource_utilization: %{}}
    end
  end

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

  defp extract_activities_from_schedule(_) do
    []
  end

  defp parse_time_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, _} -> int_val
      :error -> 0
    end
  end

  defp parse_time_value(value) when is_integer(value) do
    value
  end

  defp parse_time_value(_) do
    0
  end

  defp calculate_makespan(schedule) when is_list(schedule) do
    schedule
    |> Enum.map(fn activity -> parse_time_value(activity["end_time"] || activity[:end_time]) end)
    |> Enum.max(fn -> 0 end)
  end

  defp calculate_makespan(_) do
    0
  end

  defp extract_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end

  defp ensure_list(nil) do
    []
  end

  defp ensure_list(data) when is_list(data) do
    data
  end

  defp ensure_list(data) when is_map(data) do
    Map.values(data)
  end

  defp ensure_list(_) do
    []
  end
end