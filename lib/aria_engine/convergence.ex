# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Convergence do
  @moduledoc """
  Unified convergence solving API with Flow-based parallel processing.
  
  This module provides a clean interface for solving convergence problems
  using Flow-based parallel processing with automatic batch optimization
  for multiple problems via the new BatchProcessor.
  """

  # alias AriaEngine.ConvergenceFlow
  alias AriaEngine.BatchProcessor

  require Logger

  @doc """
  Solve STN constraints using Flow-based parallel processing.
  
  ## Options
  
  - `:max_iterations` - Maximum iterations for convergence (default: 100)
  - `:stages` - Number of Flow stages for parallel processing (default: System.schedulers_online())
  
  ## Examples
  
      # Single problem
      Convergence.solve_stn(constraints)
      
      # With custom options
      Convergence.solve_stn(constraints, max_iterations: 200, stages: 8)
  """
  def solve_stn(_constraints, _opts \\ []) do
    raise "ConvergenceFlow.solve_stn_with_convergence/2 is not implemented"
  end

  @doc """
  Solve activity scheduling using Flow-based parallel processing.
  
  ## Options
  
  - `:max_iterations` - Maximum iterations for convergence (default: 50)
  - `:stages` - Number of Flow stages for parallel processing (default: System.schedulers_online())
  
  ## Examples
  
      # Single problem
      Convergence.solve_activities(activities)
      
      # With custom options
      Convergence.solve_activities(activities, max_iterations: 100, stages: 4)
  """
  def solve_activities(_activities, _opts \\ []) do
    raise "ConvergenceFlow.solve_activities_with_convergence/2 is not implemented"
  end

  @doc """
  Solve multiple STN constraint sets in batch using the new BatchProcessor.
  
  This function automatically uses the optimized BatchProcessor for improved
  performance when processing multiple problems simultaneously.
  
  ## Options
  
  - `:max_concurrency` - Maximum number of problems to process simultaneously (default: number of problems)
  - `:timeout` - Timeout per problem in milliseconds (default: 60_000)
  - `:ordered` - Whether to preserve problem order in results (default: false)
  - `:cores_per_problem` - Explicit core allocation per problem (overrides automatic calculation)
  - `:max_iterations` - Maximum iterations for convergence (default: 100)
  
  ## Examples
  
      # Batch solve multiple timelines (uses all cores distributed)
      timelines = [
        %{id: "npc1", constraints: constraints1},
        %{id: "npc2", constraints: constraints2},
        %{id: "npc3", constraints: constraints3}
      ]
      
      Convergence.solve_stn_batch(timelines)
      
      # Force single core per problem for maximum cross-problem parallelism
      Convergence.solve_stn_batch(timelines, cores_per_problem: 1)
      
      # With custom options
      Convergence.solve_stn_batch(timelines, max_concurrency: 4, timeout: 30_000)
  """
  def solve_stn_batch(timelines, opts \\ []) do
    if length(timelines) == 0 do
      %{
        batch_solved: true,
        timelines: [],
        total_count: 0,
        successful_count: 0
      }
    else
      # Convert timelines to problems format for BatchProcessor
      problems = Enum.map(timelines, fn timeline ->
        Map.get(timeline, :constraints, %{})
      end)
      
      # Use the new BatchProcessor for optimal performance
      results = BatchProcessor.solve_multiple_stn_problems(problems, opts)
      
      # Convert results back to timeline format
      timeline_results = Enum.zip(timelines, results)
      |> Enum.map(fn {timeline, result} ->
        Map.put(timeline, :result, result)
      end)
      
      %{
        batch_solved: true,
        timelines: timeline_results,
        total_count: length(timelines),
        successful_count: Enum.count(timeline_results, fn t -> 
          get_in(t, [:result, :converged]) || get_in(t, [:result, :solved])
        end)
      }
    end
  end

  @doc """
  Solve multiple activity scheduling problems in batch using the new BatchProcessor.
  
  This function automatically uses the optimized BatchProcessor for improved
  performance when processing multiple activity sets simultaneously.
  
  ## Options
  
  - `:max_concurrency` - Maximum number of activity sets to process simultaneously (default: number of sets)
  - `:timeout` - Timeout per activity set in milliseconds (default: 60_000)
  - `:ordered` - Whether to preserve activity set order in results (default: false)
  - `:cores_per_problem` - Explicit core allocation per problem (overrides automatic calculation)
  - `:max_iterations` - Maximum iterations for convergence (default: 50)
  
  ## Examples
  
      # Batch solve multiple activity sets (uses all cores distributed)
      activity_sets = [
        %{id: "project1", activities: activities1},
        %{id: "project2", activities: activities2}
      ]
      
      Convergence.solve_activities_batch(activity_sets)
      
      # Force single core per problem for maximum cross-problem parallelism
      Convergence.solve_activities_batch(activity_sets, cores_per_problem: 1)
  """
  def solve_activities_batch(activity_sets, opts \\ []) do
    if length(activity_sets) == 0 do
      %{
        batch_solved: true,
        activity_sets: [],
        total_count: 0,
        successful_count: 0
      }
    else
      # Convert activity sets to problems format for BatchProcessor
      problems = Enum.map(activity_sets, fn activity_set ->
        Map.get(activity_set, :activities, [])
      end)
      
      # Use the new BatchProcessor for optimal performance
      results = BatchProcessor.solve_multiple_activities_batches(problems, opts)
      
      # Convert results back to activity set format
      activity_set_results = Enum.zip(activity_sets, results)
      |> Enum.map(fn {activity_set, result} ->
        Map.put(activity_set, :result, result)
      end)
      
      %{
        batch_solved: true,
        activity_sets: activity_set_results,
        total_count: length(activity_sets),
        successful_count: Enum.count(activity_set_results, fn s -> 
          get_in(s, [:result, :converged]) || get_in(s, [:result, :solved])
        end)
      }
    end
  end

  @doc """
  Solve multiple problems using all available cores (distributed approach).
  
  Convenience function that uses the BatchProcessor's all-cores strategy.
  Best for complex problems that benefit from internal parallelization.
  """
  def solve_batch_all_cores(problems, opts \\ []) do
    BatchProcessor.solve_multiple_problems_all_cores(problems, opts)
  end

  @doc """
  Solve multiple problems using single core per problem (wide parallelism).
  
  Convenience function that uses the BatchProcessor's single-core strategy.
  Best for many simple problems or when testing cross-problem parallelism.
  """
  def solve_batch_single_core(problems, opts \\ []) do
    BatchProcessor.solve_multiple_problems_single_core(problems, opts)
  end

  @doc """
  Get information about available convergence approaches and their capabilities.
  """
  def info do
    %{
      approaches: %{
        flow: %{
          description: "Pure Elixir parallel processing with Flow library",
          strengths: ["Activity scheduling", "STN constraints", "Consistent performance", "Large datasets"],
          backend: "CPU (Elixir processes)"
        },
        batch_processor: %{
          description: "Optimized batch processing for multiple problems with core distribution",
          strengths: ["Multiple problems", "Core utilization", "Parallel scaling", "Performance optimization"],
          backend: "CPU (Task.async_stream + Flow)"
        }
      },
      system: %{
        total_cores: System.schedulers_online(),
        architecture: get_system_architecture(),
        recommended_approach: :batch_processor_for_multiple_problems
      },
      core_strategies: %{
        all_cores: "Distribute all cores across problems (default)",
        single_core: "Use 1 core per problem, maximize cross-problem parallelism"
      }
    }
  end

  # Private helper functions

  defp get_system_architecture do
    case :erlang.system_info(:system_architecture) do
      arch when is_list(arch) -> List.to_string(arch)
      _ -> "unknown"
    end
  end
end
