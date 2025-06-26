defmodule AriaSolver do
  @moduledoc """
  Unified solving interface maintaining ADR-181 compliance.
  
  Consolidates all constraint solving, planning, and temporal reasoning
  into a single cohesive layer while preserving the declarative planning
  paradigm established in ADR-181.
  
  ## Architecture
  
  This module serves as the unified entry point for all solving operations,
  consolidating functionality from:
  
  - `aria_minizinc_goal` → `AriaSolver.Goal`
  - `aria_minizinc_stn` → `AriaSolver.STN`
  - `aria_minizinc_executor` → `AriaSolver.Executor`
  - `aria_minizinc_multiply` → `AriaSolver.MultiObjective`
  - `aria_engine_core` → `AriaSolver.Engine`
  - `aria_hybrid_planner` → `AriaSolver.HybridPlanner`
  - `aria_temporal_planner` → `AriaSolver.TemporalPlanner`
  - `aria_timeline` → `AriaSolver.Timeline`
  
  ## ADR-181 Compliance
  
  This module maintains full compatibility with ADR-181 specifications:
  - Entity-based resource management with capabilities
  - Unified action specification with function attributes
  - Temporal patterns (9 valid combinations) with ISO 8601 durations
  - Goal format: `{predicate, subject, value}` ONLY
  - State validation via `AriaState.RelationalState.get_fact/3`
  - Planning paradigm (declarative vs imperative) distinction
  - Method decomposition for complex workflows
  """

  @type domain :: term()
  @type state :: term()
  @type goal :: {String.t(), String.t(), term()}
  @type solution :: term()
  @type solution_tree :: term()
  @type plan :: term()

  @doc """
  Unified solving interface that automatically determines the appropriate
  solver strategy based on the goals and options provided.
  
  ## Parameters
  
  - `domain`: ADR-181 compliant domain specification
  - `state`: Current state (must support `AriaState.RelationalState.get_fact/3`)
  - `goals`: List of goals in `{predicate, subject, value}` format
  - `opts`: Solver options and strategy hints
  
  ## Examples
  
      # Goal optimization
      {:ok, solution} = AriaSolver.solve(domain, state, [
        {"location", "chef_1", "kitchen"}
      ])
      
      # Multi-objective solving
      {:ok, solution} = AriaSolver.solve(domain, state, goals, strategy: :multi_objective)
      
      # Temporal constraint solving
      {:ok, solution} = AriaSolver.solve(domain, state, goals, strategy: :stn_temporal)
  """
  @spec solve(domain(), state(), [goal()], keyword()) :: 
    {:ok, solution()} | {:error, term()}
  def solve(domain, state, goals, opts \\ []) do
    case determine_solver_strategy(goals, opts) do
      :minizinc_goal -> 
        AriaSolver.Goal.solve_goals(domain, state, goals, opts)
      :stn_temporal -> 
        stn = build_stn_from_goals(goals, opts)
        AriaSolver.STN.solve_stn(stn, opts)
      :hybrid_planning -> 
        AriaSolver.HybridPlanner.plan(domain, state, goals, opts)
      :engine_planning -> 
        AriaSolver.Engine.plan(domain, state, goals)
      :multi_objective ->
        AriaSolver.MultiObjective.solve(domain, state, goals, opts)
      strategy ->
        {:error, {:unknown_strategy, strategy}}
    end
  end

  @doc """
  ADR-181 compliant solution tree interface for declarative planning.
  
  Maintains the planning paradigm distinction by providing solution trees
  that can be executed lazily with `run_lazy_refineahead/3`.
  
  ## Examples
  
      {:ok, solution_tree, plan} = AriaSolver.plan_with_tree(domain, state, [
        {:cook_meal, ["pasta"]},
        {"location", "chef_1", "kitchen"}
      ])
  """
  @spec plan_with_tree(domain(), state(), [goal()]) :: 
    {:ok, solution_tree(), plan()} | {:error, term()}
  def plan_with_tree(domain, state, goals) do
    AriaSolver.Engine.plan_with_tree(domain, state, goals)
  end

  @doc """
  ADR-181 compliant lazy execution interface.
  
  Executes a solution tree using the lazy refinement approach,
  maintaining the declarative planning paradigm.
  
  ## Examples
  
      case AriaSolver.run_lazy_refineahead(domain, state, solution_tree) do
        {:ok, final_state} -> Logger.info("Execution completed")
        {:error, reason} -> Logger.error("Execution failed: #{reason}")
      end
  """
  @spec run_lazy_refineahead(domain(), state(), solution_tree()) :: 
    {:ok, state()} | {:error, term()}
  def run_lazy_refineahead(domain, state, solution_tree) do
    AriaSolver.Engine.run_lazy_refineahead(domain, state, solution_tree)
  end

  # Private helper functions

  defp determine_solver_strategy(goals, opts) do
    cond do
      Keyword.get(opts, :strategy) -> Keyword.get(opts, :strategy)
      has_temporal_constraints?(goals) -> :stn_temporal
      has_multiple_objectives?(goals) -> :multi_objective
      has_complex_planning_requirements?(goals) -> :hybrid_planning
      true -> :minizinc_goal
    end
  end

  defp build_stn_from_goals(goals, opts) do
    # Placeholder implementation - will be implemented when STN module is migrated
    %{goals: goals, opts: opts}
  end

  defp has_temporal_constraints?(goals) do
    # Check if any goals involve temporal relationships
    Enum.any?(goals, fn
      {predicate, _subject, _value} when predicate in ["before", "after", "during", "overlaps"] -> true
      _ -> false
    end)
  end

  defp has_multiple_objectives?(goals) do
    # Check if we have multiple conflicting objectives
    length(goals) > 3
  end

  defp has_complex_planning_requirements?(goals) do
    # Check if goals require complex method decomposition
    Enum.any?(goals, fn
      {predicate, _subject, _value} when predicate in ["cook_meal", "transport", "assemble"] -> true
      _ -> false
    end)
  end
end
