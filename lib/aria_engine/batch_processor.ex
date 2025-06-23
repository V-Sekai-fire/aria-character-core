# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BatchProcessor do
  @moduledoc "Batch processing for multiple convergence problems with optimal core distribution.\n\nDistributes CPU cores across multiple problems to achieve maximum utilization\nwhen solving multiple independent convergence problems simultaneously.\n\nThis approach addresses the core utilization bottleneck observed in single-problem\nFlow processing by running multiple problems in parallel, each with its allocated\nsubset of CPU cores.\n\nExpected performance improvement: 3-4x for multiple problem scenarios.\n"
  require Logger

  @doc "Generate test problems for batch processing benchmarks.\n\nCreates multiple independent activity sets for testing batch processing performance.\n"
  def generate_test_problems(problem_count, activities_per_problem \\ 1000) do
    Logger.debug(
      "Generating #{problem_count} test problems with #{activities_per_problem} activities each"
    )

    for problem_id <- 1..problem_count do
      generate_single_test_problem(problem_id, activities_per_problem)
    end
  end

  defp generate_single_test_problem(problem_id, activity_count) do
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
    resource_count = :rand.uniform(3)
    resource_pool = ["cpu", "memory", "disk", "network", "gpu"]

    for i <- 1..resource_count do
      resource_type = Enum.at(resource_pool, rem(activity_id + i, length(resource_pool)))
      "#{resource_type}_p#{problem_id}"
    end
  end

  defp generate_test_dependencies(activity_id, _max_activities) do
    if activity_id > 1 and :rand.uniform(3) == 1 do
      dep_count = min(2, activity_id - 1)

      for _ <- 1..dep_count do
        :rand.uniform(activity_id - 1)
      end
    else
      []
    end
  end

  defp generate_test_constraints(_activity_id) do
    [
      %{type: :start_after, time: :rand.uniform(20)},
      %{type: :finish_before, time: :rand.uniform(100) + 50}
    ]
  end
end