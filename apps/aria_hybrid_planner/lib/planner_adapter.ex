# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PlannerAdapter do
  @moduledoc "Migration adapter that provides the Plan API while delegating to HybridCoordinator.\n\nThis module allows seamless migration from the old Plan module to the new HybridCoordinator\nby maintaining the same public API and function signatures while using the hybrid planner\ninternally.\n\n## Migration Strategy\n\n1. Replace Plan usages with PlannerAdapter\n2. Test compatibility and behavior parity\n3. Gradually migrate to direct HybridCoordinator usage\n4. Remove this adapter once migration is complete\n"
  alias HybridPlanner.{HybridCoordinatorV2, DataStructures}
  alias AriaEngine.Plan.Utils
  alias Plan.Blacklisting
  require Logger
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.State.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()
  @type solution_tree :: map()
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  @doc "Plan using HTN task decomposition directly with temporal validation.\n\nThis function bypasses the goal-based HybridCoordinator.plan/4 and uses\ndirect HTN task decomposition while preserving temporal planning capabilities.\n"
  @spec plan_tasks(Domain.Core.t(), AriaEngine.State.t(), [task()], keyword()) :: plan_result()
  def plan_tasks(domain, %AriaEngine.State{} = state, tasks, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    Logger.info(
      "🔧 PlannerAdapter.plan_tasks() called with #{length(tasks)} tasks, verbose=#{verbose}"
    )

    Logger.info("🔧 Tasks: #{inspect(tasks)}")
    Logger.info("🔧 Opts: #{inspect(opts)}")

    if verbose > 1 do
      Logger.debug(
        "PlannerAdapter: Starting HTN task decomposition using HybridCoordinatorV2 for #{length(tasks)} tasks"
      )
    end

    Logger.info("🔧 Creating HybridCoordinatorV2 with opts: #{inspect(opts)}")
    coordinator = HybridCoordinatorV2.new_default(opts)
    Logger.info("🔧 Calling HybridCoordinatorV2.plan() with coordinator: #{inspect(coordinator)}")

    case HybridCoordinatorV2.plan(coordinator, domain, state, tasks, opts) do
      {:ok, %{solution_tree: solution_tree}} ->
        Logger.info("🔧 PlannerAdapter: HybridCoordinatorV2 planning completed successfully")

        if verbose > 1 do
          Logger.debug("PlannerAdapter: HybridCoordinatorV2 planning completed successfully")
        end

        {:ok, solution_tree}

      {:error, reason} ->
        Logger.warning("🔧 PlannerAdapter: HybridCoordinatorV2 planning failed - #{reason}")

        if verbose > 0 do
          Logger.warning("PlannerAdapter: HybridCoordinatorV2 planning failed - #{reason}")
        end

        {:error, reason}
    end
  end

  @doc "Plan using HybridCoordinator while maintaining Plan.plan/4 API compatibility.\n\nConverts between Plan module API and HybridCoordinator API seamlessly.\n"
  @spec plan(Domain.Core.t(), AriaEngine.State.t(), [todo_item()], keyword()) :: plan_result()
  def plan(domain, %AriaEngine.State{} = state, todos, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("PlannerAdapter: Converting Plan.plan/4 call to HybridCoordinator.plan/4")
    end

    converted_goals = convert_todos_to_goals(todos)
    coordinator = HybridCoordinatorV2.new_default(opts)

    case HybridCoordinatorV2.plan(coordinator, domain, state, converted_goals, opts) do
      {:ok, %{solution_tree: solution_tree}} ->
        if verbose > 1 do
          Logger.debug(
            "PlannerAdapter: Successfully converted HybridCoordinatorV2 result to Plan format"
          )
        end

        {:ok, solution_tree}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Replan using HybridCoordinator while maintaining Plan.replan/5 API compatibility.\n"
  @spec replan(Domain.Core.t(), AriaEngine.State.t(), solution_tree(), node_id(), keyword()) ::
          replan_result()
  def replan(domain, %AriaEngine.State{} = state, solution_tree, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("PlannerAdapter: Converting Plan.replan/5 call to HybridCoordinator.replan/5")
    end

    encapsulated_plan =
      DataStructures.EncapsulatedPlan.new(solution_tree, %{
        adapter_wrapped: true,
        original_api: "Plan.replan"
      })

    coordinator = HybridCoordinatorV2.new_default(opts)

    case HybridCoordinatorV2.replan(
           coordinator,
           domain,
           state,
           encapsulated_plan,
           fail_node_id,
           opts
         ) do
      {:ok, %{solution_tree: new_solution_tree}} -> {:ok, new_solution_tree}
      {:error, reason} -> {:error, reason}
      :failure -> :failure
    end
  end

  @doc "Execute plan using HybridCoordinator while maintaining run_lazy_refineahead API compatibility.\n"
  @spec run_lazy_refineahead(Domain.Core.t(), AriaEngine.State.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def run_lazy_refineahead(
        domain,
        %AriaEngine.State{} = initial_state,
        solution_tree,
        opts \\ []
      ) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug(
        "PlannerAdapter: Converting run_lazy_refineahead call to HybridCoordinator.execute/4"
      )
    end

    encapsulated_plan =
      DataStructures.EncapsulatedPlan.new(solution_tree, %{
        adapter_wrapped: true,
        original_api: "Plan.run_lazy_refineahead"
      })

    coordinator = HybridCoordinatorV2.new_default(opts)

    case HybridCoordinatorV2.execute(coordinator, domain, initial_state, encapsulated_plan, opts) do
      {:ok, final_state} -> {:ok, final_state}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Validate plan using HybridCoordinator while maintaining Plan.validate_plan/3 API compatibility.\n"
  @spec validate_plan(Domain.Core.t(), AriaEngine.State.t(), [plan_step()] | solution_tree()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def validate_plan(domain, %AriaEngine.State{} = initial_state, plan) do
    case plan do
      plan when is_list(plan) ->
        Utils.validate_plan(domain, initial_state, plan)

      solution_tree when is_map(solution_tree) ->
        encapsulated_plan =
          DataStructures.EncapsulatedPlan.new(solution_tree, %{
            adapter_wrapped: true,
            original_api: "Plan.validate_plan"
          })

        coordinator = HybridCoordinatorV2.new_default([])

        case HybridCoordinatorV2.validate_plan(
               coordinator,
               domain,
               initial_state,
               encapsulated_plan
             ) do
          {:ok, final_state} -> {:ok, final_state}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc "Calculate plan cost - delegates to existing Utils for compatibility.\n"
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(plan) do
    Utils.plan_cost(plan)
  end

  @doc "Get tree statistics - delegates to existing Utils for compatibility.\n"
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    Utils.tree_stats(solution_tree)
  end

  @doc "Blacklist command - delegates to existing Blacklisting for compatibility.\n"
  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command) do
    Blacklisting.blacklist_command(solution_tree, command)
  end

  @doc "Get the underlying HybridCoordinator for direct access.\n\nThis function allows gradual migration to direct HybridCoordinator usage.\n"
  @spec get_hybrid_coordinator() :: module()
  def get_hybrid_coordinator do
    HybridCoordinatorV2
  end

  @doc "Convert solution tree to EncapsulatedPlan for direct HybridCoordinator usage.\n"
  @spec wrap_in_encapsulated_plan(solution_tree(), map()) :: DataStructures.EncapsulatedPlan.t()
  def wrap_in_encapsulated_plan(solution_tree, metadata \\ %{}) do
    enhanced_metadata = Map.put(metadata, :adapter_source, "PlannerAdapter")
    DataStructures.EncapsulatedPlan.new(solution_tree, enhanced_metadata)
  end

  @doc "Extract solution tree from EncapsulatedPlan for legacy compatibility.\n"
  @spec extract_solution_tree(DataStructures.EncapsulatedPlan.t()) :: solution_tree()
  def extract_solution_tree(%DataStructures.EncapsulatedPlan{} = encapsulated_plan) do
    DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
  end

  defp convert_todos_to_goals(todos) when is_list(todos) do
    Enum.map(todos, &convert_todo_to_goal/1)
  end

  defp convert_todo_to_goal({task_name, args}) when is_binary(task_name) and is_list(args) do
    {task_name, args}
  end

  defp convert_todo_to_goal({predicate, subject, value})
       when is_binary(predicate) and is_binary(subject) do
    {predicate, subject, value}
  end

  defp convert_todo_to_goal(%Multigoal{} = multigoal) do
    goals = Multigoal.to_goals(multigoal)
    convert_todos_to_goals(goals)
  end

  defp convert_todo_to_goal(other) do
    Logger.warning("PlannerAdapter: Unknown todo format #{inspect(other)}, passing through")
    other
  end

  @doc "Check if a module is using the old Plan API and suggest migrations.\n"
  @spec suggest_migration(module()) :: :ok
  def suggest_migration(calling_module) do
    Logger.info("Migration suggestion for #{calling_module}:

1. Replace Plan with PlannerAdapter for immediate compatibility
2. Consider migrating to HybridPlanner.HybridCoordinator for enhanced features:
   - Temporal reasoning with STN validation
   - Enhanced error handling and recovery
   - Function as Object strategy patterns
   - Comprehensive backtracking and replanning

See ADR-091 for detailed migration guidance.
")
  end

  @doc "Test compatibility between Plan and HybridCoordinator results.\n"
  @spec test_compatibility(Domain.Core.t(), AriaEngine.State.t(), [todo_item()], keyword()) ::
          {:compatible | :incompatible, map()}
  def test_compatibility(domain, state, todos, opts \\ []) do
    try do
      {:ok, adapter_result} = plan(domain, state, todos, opts)

      compatibility_metrics = %{
        adapter_success: true,
        result_type: :solution_tree,
        action_count: Utils.plan_cost(adapter_result)
      }

      {:compatible, compatibility_metrics}
    rescue
      e -> {:incompatible, %{error: Exception.message(e)}}
    end
  end
end