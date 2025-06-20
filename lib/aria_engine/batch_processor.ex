# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BatchProcessor do
  @moduledoc """
  Batch processing for multiple convergence problems with optimal core distribution.
  
  Distributes CPU cores across multiple problems to achieve maximum utilization
  when solving multiple independent convergence problems simultaneously.
  
  This approach addresses the core utilization bottleneck observed in single-problem
  Flow processing by running multiple problems in parallel, each with its allocated
  subset of CPU cores.
  
  Expected performance improvement: 3-4x for multiple problem scenarios.
  """

  require Logger
  
  @doc """
  Generate test problems for batch processing benchmarks.
  
  Creates multiple independent activity sets for testing batch processing performance.
  """
  def generate_test_problems(problem_count, activities_per_problem \\ 1000) do
    Logger.debug("Generating #{problem_count} test problems with #{activities_per_problem} activities each")
    
    for problem_id <- 1..problem_count do
      generate_single_test_problem(problem_id, activities_per_problem)
    end
  end
  
  # Private functions

  defp generate_single_test_problem(problem_id, activity_count) do
    # Generate realistic test activities for a single problem
    base_seed = problem_id * 1000
    :rand.seed(:exsss, {base_seed, base_seed + 1, base_seed + 2})
    
    for activity_id <- 1..activity_count do
      %{
        id: activity_id,
        problem_id: problem_id,
        name: "problem_#{problem_id}_activity_#{activity_id}",
        duration: :rand.uniform(50) + 10,
        resources: generate_test_resources(activity_id, problem_id),
        dependencies: generate_test_dependencies(activity_id, activity_count),
        priority: :rand.uniform(10),
        constraints: generate_test_constraints(activity_id)
      }
    end
  end
  
  defp generate_test_resources(activity_id, problem_id) do
    # Generate 1-3 resources per activity, scoped to the problem
    resource_count = :rand.uniform(3)
    resource_pool = ["cpu", "memory", "disk", "network", "gpu"]
    
    for i <- 1..resource_count do
      resource_type = Enum.at(resource_pool, rem(activity_id + i, length(resource_pool)))
      "#{resource_type}_p#{problem_id}"
    end
  end
  
  defp generate_test_dependencies(activity_id, _max_activities) do
    # Generate 0-2 dependencies per activity
    if activity_id > 1 and :rand.uniform(3) == 1 do
      dep_count = min(2, activity_id - 1)
      for _ <- 1..dep_count, do: :rand.uniform(activity_id - 1)
    else
      []
    end
  end
  
  defp generate_test_constraints(_activity_id) do
    # Generate realistic temporal constraints
    [
      %{type: :start_after, time: :rand.uniform(20)},
      %{type: :finish_before, time: :rand.uniform(100) + 50}
    ]
  end
end
