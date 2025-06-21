defmodule AriaEngine.Membrane.ValidationPipeline.SolutionComparator do
  @moduledoc """
  Handles comparing solutions from different solvers and determining validation status.
  """

  require Logger

  @doc """
  Validates and compares results from Hybrid and MiniZinc solvers.
  Returns validation status: success, inconsistent, infeasible, or unknown.
  """
  def validate_and_compare(hybrid_result, minizinc_result, params, state) do
    cond do
      # MiniZinc not available
      minizinc_result.status == :unavailable ->
        %{
          overall_status: :unknown,
          reason: "MiniZinc not available",
          hybrid_solved: hybrid_result.status == :success,
          minizinc_solved: false,
          solutions_match: false
        }
      
      # MiniZinc unsupported for this problem type
      minizinc_result.status == :unsupported ->
        %{
          overall_status: :unknown,
          reason: "MiniZinc model not available for this problem type",
          hybrid_solved: hybrid_result.status == :success,
          minizinc_solved: false,
          solutions_match: false
        }
      
      # Both solvers failed
      hybrid_result.status != :success and minizinc_result.status != :success ->
        %{
          overall_status: :infeasible,
          reason: "Both solvers failed to find solution",
          hybrid_solved: false,
          minizinc_solved: false,
          solutions_match: false
        }
      
      # Only one solver succeeded
      hybrid_result.status == :success and minizinc_result.status != :success ->
        %{
          overall_status: :inconsistent,
          reason: "Only Hybrid solver found solution",
          hybrid_solved: true,
          minizinc_solved: false,
          solutions_match: false
        }
      
      # Only MiniZinc succeeded
      hybrid_result.status != :success and minizinc_result.status == :success ->
        %{
          overall_status: :inconsistent,
          reason: "Only MiniZinc solver found solution",
          hybrid_solved: false,
          minizinc_solved: true,
          solutions_match: false
        }
      
      # Both succeeded - compare solutions
      hybrid_result.status == :success and minizinc_result.status == :success ->
        solutions_match = compare_solutions(hybrid_result.solution, minizinc_result.solution)
        
        if solutions_match do
          %{
            overall_status: :success,
            reason: "Both solvers found matching solutions",
            hybrid_solved: true,
            minizinc_solved: true,
            solutions_match: true
          }
        else
          %{
            overall_status: :inconsistent,
            reason: "Both solvers found solutions but they don't match",
            hybrid_solved: true,
            minizinc_solved: true,
            solutions_match: false
          }
        end
      
      # Default case
      true ->
        %{
          overall_status: :unknown,
          reason: "Unexpected solver states",
          hybrid_solved: hybrid_result.status == :success,
          minizinc_solved: minizinc_result.status == :success,
          solutions_match: false
        }
    end
  end

  @doc """
  Compares two solutions to determine if they match within acceptable tolerances.
  """
  def compare_solutions(hybrid_solution, minizinc_solution) do
    # Compare makespans (allowing small tolerance)
    hybrid_makespan = hybrid_solution.makespan || 0
    minizinc_makespan = minizinc_solution.makespan || 0
    
    makespan_tolerance = 5  # Allow 5 minute tolerance
    makespans_match = abs(hybrid_makespan - minizinc_makespan) <= makespan_tolerance
    
    # Compare activity count
    hybrid_activities = length(hybrid_solution.activities || [])
    minizinc_activities = length(minizinc_solution.activities || [])
    
    activities_count_match = hybrid_activities == minizinc_activities
    
    # For now, consider solutions matching if makespans are close and activity counts match
    makespans_match and activities_count_match
  end
end
