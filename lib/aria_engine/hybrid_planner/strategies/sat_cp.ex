defmodule AriaEngine.HybridPlanner.Strategies.SatCp do
  @moduledoc """
  SAT-CP Mock Strategy - Extremely Simple Implementation

  This mock strategy schedules activities one after another with 1-hour gaps.
  It's designed for clarity and testing, not performance.
  """

  @behaviour AriaEngine.HybridPlanner.OptimizerStrategy

  @impl true
  def solve(activities, _constraints \\ %{}, _options \\ []) do
    scheduled = 
      activities
      |> Enum.with_index()
      |> Enum.map(fn {activity, index} ->
        start_time = index * 3600  # Each activity starts 1 hour after previous
        duration = 3600            # All activities take 1 hour
        
        %{
          id: activity["id"] || "task_#{index}",
          start_time: start_time,
          end_time: start_time + duration,
          duration: duration
        }
      end)
    
    {:ok, %{
      status: "success",
      method: "SAT-CP (Mock)",
      activities: scheduled,
      total_duration: length(activities) * 3600
    }}
  end

  @impl true
  def validate_input(activities, _constraints \\ %{}) do
    if is_list(activities) and length(activities) > 0 do
      :ok
    else
      {:error, "Need a non-empty list of activities"}
    end
  end
end
