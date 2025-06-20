defmodule AriaEngine.HybridPlanner.Strategies.SatCp do
  @moduledoc """
  SAT-CP (Satisfiability and Constraint Programming) Mock Strategy

  This is a simple mock implementation that provides the OptimizerStrategy interface
  for testing and development purposes. It performs basic sequential scheduling
  without complex constraint solving.

  This strategy was renamed from "exhort" but maintains the same interface.
  """

  @behaviour AriaEngine.HybridPlanner.OptimizerStrategy

  @impl true
  def solve(activities, constraints \\ %{}, options \\ []) do
    try do
      # Simple mock implementation - schedule activities sequentially
      scheduled_activities = schedule_sequentially(activities)
      
      {:ok, %{
        status: "success",
        method: "SAT-CP (Mock)",
        activities: scheduled_activities,
        total_duration: calculate_total_duration(scheduled_activities),
        constraints_applied: map_size(constraints),
        options_used: length(options)
      }}
    rescue
      error ->
        {:error, "SAT-CP scheduling failed: #{inspect(error)}"}
    end
  end

  @impl true
  def validate_input(activities, constraints \\ %{}) do
    cond do
      not is_list(activities) ->
        {:error, "Activities must be a list"}
      
      Enum.empty?(activities) ->
        {:error, "Activities list cannot be empty"}
      
      not is_map(constraints) ->
        {:error, "Constraints must be a map"}
      
      not valid_activities?(activities) ->
        {:error, "Invalid activity format"}
      
      true ->
        :ok
    end
  end

  # Private functions

  defp schedule_sequentially(activities) do
    activities
    |> Enum.with_index()
    |> Enum.map(fn {activity, index} ->
      start_time = calculate_start_time(activity, index)
      duration = parse_duration(activity)
      end_time = start_time + duration
      
      %{
        id: get_activity_id(activity),
        name: get_activity_name(activity),
        start_time: start_time,
        end_time: end_time,
        duration: duration,
        dependencies: get_dependencies(activity)
      }
    end)
  end

  defp calculate_start_time(activity, index) do
    # Simple sequential scheduling - each activity starts 1 hour after the previous
    base_start = index * 3600  # 1 hour apart in seconds
    
    # Add some variation based on activity properties
    variation = case get_activity_priority(activity) do
      "high" -> 0      # High priority starts immediately
      "medium" -> 1800 # Medium priority has 30 min delay
      "low" -> 3600    # Low priority has 1 hour delay
      _ -> 0
    end
    
    base_start + variation
  end

  defp parse_duration(activity) do
    duration_str = get_activity_duration(activity)
    
    case duration_str do
      "PT" <> duration_part ->
        parse_iso8601_duration(duration_part)
      
      duration when is_integer(duration) ->
        duration
      
      duration when is_binary(duration) ->
        case Integer.parse(duration) do
          {seconds, ""} -> seconds
          _ -> 3600  # Default to 1 hour
        end
      
      _ ->
        3600  # Default to 1 hour
    end
  end

  defp parse_iso8601_duration(duration_str) do
    cond do
      String.ends_with?(duration_str, "H") ->
        duration_str
        |> String.trim_trailing("H")
        |> String.to_integer()
        |> Kernel.*(3600)
      
      String.ends_with?(duration_str, "M") ->
        duration_str
        |> String.trim_trailing("M")
        |> String.to_integer()
        |> Kernel.*(60)
      
      String.ends_with?(duration_str, "S") ->
        duration_str
        |> String.trim_trailing("S")
        |> String.to_integer()
      
      true ->
        3600  # Default to 1 hour
    end
  end

  defp calculate_total_duration(activities) do
    case activities do
      [] -> 0
      _ -> 
        max_end = activities |> Enum.map(& &1.end_time) |> Enum.max()
        min_start = activities |> Enum.map(& &1.start_time) |> Enum.min()
        max_end - min_start
    end
  end

  defp valid_activities?(activities) do
    Enum.all?(activities, fn activity ->
      is_map(activity) and has_required_fields?(activity)
    end)
  end

  defp has_required_fields?(activity) do
    # Check for either string keys or atom keys
    has_id = Map.has_key?(activity, "id") or Map.has_key?(activity, :id)
    has_duration = Map.has_key?(activity, "duration") or Map.has_key?(activity, :duration)
    
    has_id and has_duration
  end

  # Activity field accessors (handle both string and atom keys)

  defp get_activity_id(activity) do
    activity["id"] || activity[:id] || "unknown_#{:rand.uniform(1000)}"
  end

  defp get_activity_name(activity) do
    activity["name"] || activity[:name] || get_activity_id(activity)
  end

  defp get_activity_duration(activity) do
    activity["duration"] || activity[:duration] || "PT1H"
  end

  defp get_dependencies(activity) do
    activity["dependencies"] || activity[:dependencies] || 
    activity["predecessors"] || activity[:predecessors] || []
  end

  defp get_activity_priority(activity) do
    activity["priority"] || activity[:priority] || "medium"
  end
end
