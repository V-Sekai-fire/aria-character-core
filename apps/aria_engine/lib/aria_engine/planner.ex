# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planner do
  @moduledoc """
  DEPRECATED: Use AriaEngine.HybridPlanner.HybridCoordinator instead.
  
  This module provides backward compatibility for existing code but delegates
  to the new encapsulated hybrid planner implementation with better separation
  of concerns and private engines.
  
  ## Migration Guide
  
  Old code:
  ```elixir
  case AriaEngine.Planner.plan(domain_interface, state, goals, opts, current_time) do
    {:ok, solution_tree} ->
      AriaEngine.Planner.execute(domain_interface, state, solution_tree, opts)
    {:error, reason} -> {:error, reason}
  end
  ```
  
  New code:
  ```elixir
  case AriaEngine.HybridPlanner.HybridCoordinator.plan(domain, state, goals, opts) do
    {:ok, encapsulated_plan} ->
      AriaEngine.HybridPlanner.HybridCoordinator.execute(domain, state, encapsulated_plan, opts)
    {:error, reason} -> {:error, reason}
  end
  ```
  
  ## Benefits of Migration
  
  - Better encapsulation with private engines
  - Cleaner separation between HTN planning and STN temporal validation
  - Opaque data structures that hide internal complexity
  - More maintainable and testable code structure
  """

  alias AriaEngine.{Domain, StateV2, Multigoal}
  alias AriaEngine.HybridPlanner.{HybridCoordinator, DataStructures}
  alias AriaEngine.Plan # For compatibility
  require Logger

  # Core planner types (maintained for compatibility)
  @type planner_opts :: keyword()
  @type planner_result :: {:ok, Plan.solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, StateV2.t()} | {:error, String.t()}
  @type replan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()} | :failure

  # Domain interface types (maintained for compatibility)
  @type domain_interface :: %{
    actions: %{atom() => function()},
    task_methods: %{String.t() => [{String.t(), function()}]},
    unigoal_methods: %{String.t() => [{String.t(), function()}]},
    multigoal_methods: [{String.t(), function()}]
  }

  # Solution tree types (maintained for compatibility)
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), StateV2.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}

  @type node_id :: String.t()
  @type solution_node :: Plan.solution_node()
  @type solution_tree :: Plan.solution_tree()

  @doc """
  Plan goals using hybrid HTN planning with STN temporal validation.
  
  DEPRECATED: Use AriaEngine.HybridPlanner.HybridCoordinator.plan/4 instead.
  """
  @spec plan(domain_interface(), StateV2.t(), [Plan.todo_item()], planner_opts(), integer() | nil) :: planner_result()
  def plan(domain_interface, %StateV2{} = initial_state, goals, opts \\ [], current_time \\ nil) when is_list(goals) do
    Logger.warning("AriaEngine.Planner.plan/5 is deprecated. Use AriaEngine.HybridPlanner.HybridCoordinator.plan/4 instead.")
    
    # Convert domain interface to Domain struct for compatibility
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to planning options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Delegate to new hybrid coordinator
    case HybridCoordinator.plan(domain, initial_state, goals, temporal_opts) do
      {:ok, encapsulated_plan} ->
        # Extract internal plan for backward compatibility
        internal_plan = DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
        {:ok, internal_plan}
      {:error, reason} -> 
        {:error, reason}
    end
  end

  @doc """
  Execute a solution tree with coordinated execution and replanning.
  
  DEPRECATED: Use AriaEngine.HybridPlanner.HybridCoordinator.execute/4 instead.
  """
  @spec execute(domain_interface(), StateV2.t(), Plan.solution_tree(), planner_opts(), integer() | nil) :: execution_result()
  def execute(domain_interface, %StateV2{} = initial_state, solution_tree, opts \\ [], current_time \\ nil) do
    Logger.warning("AriaEngine.Planner.execute/5 is deprecated. Use AriaEngine.HybridPlanner.HybridCoordinator.execute/4 instead.")
    
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to execution options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Create encapsulated plan for new API
    encapsulated_plan = DataStructures.EncapsulatedPlan.new(solution_tree, %{
      legacy_execution: true,
      original_domain_interface: domain_interface
    })

    # Delegate to new hybrid coordinator
    HybridCoordinator.execute(domain, initial_state, encapsulated_plan, temporal_opts)
  end

  @doc """
  Replan from a failure point using coordinated HTN replanning with temporal validation.
  
  DEPRECATED: Use AriaEngine.HybridPlanner.HybridCoordinator.replan/5 instead.
  """
  @spec replan(domain_interface(), StateV2.t(), Plan.solution_tree(), String.t(), planner_opts(), integer() | nil) :: replan_result()
  def replan(domain_interface, %StateV2{} = current_state, solution_tree, fail_node_id, opts \\ [], current_time \\ nil) do
    Logger.warning("AriaEngine.Planner.replan/6 is deprecated. Use AriaEngine.HybridPlanner.HybridCoordinator.replan/5 instead.")
    
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)
    
    # Add temporal information to replanning options if provided
    temporal_opts = if current_time do
      Keyword.put(opts, :current_time, current_time)
    else
      opts
    end

    # Create encapsulated plan for new API
    encapsulated_plan = DataStructures.EncapsulatedPlan.new(solution_tree, %{
      legacy_replanning: true,
      original_domain_interface: domain_interface
    })

    # Delegate to new hybrid coordinator
    case HybridCoordinator.replan(domain, current_state, encapsulated_plan, fail_node_id, temporal_opts) do
      {:ok, new_encapsulated_plan} ->
        # Extract internal plan for backward compatibility
        new_internal_plan = DataStructures.EncapsulatedPlan.get_internal_plan(new_encapsulated_plan)
        {:ok, new_internal_plan}
      {:error, reason} -> {:error, reason}
      :failure -> :failure
    end
  end

  @doc """
  Validate a plan against the domain and initial state using coordinated validation.
  
  DEPRECATED: Use AriaEngine.HybridPlanner.HybridCoordinator.validate_plan/3 instead.
  """
  @spec validate_plan(domain_interface(), StateV2.t(), Plan.solution_tree()) ::
    {:ok, StateV2.t()} | {:error, String.t()}
  def validate_plan(domain_interface, initial_state, solution_tree) do
    Logger.warning("AriaEngine.Planner.validate_plan/3 is deprecated. Use AriaEngine.HybridPlanner.HybridCoordinator.validate_plan/3 instead.")
    
    domain = interface_to_domain(domain_interface)
    
    # Create encapsulated plan for new API
    encapsulated_plan = DataStructures.EncapsulatedPlan.new(solution_tree, %{
      legacy_validation: true,
      original_domain_interface: domain_interface
    })

    # Delegate to new hybrid coordinator
    HybridCoordinator.validate_plan(domain, initial_state, encapsulated_plan)
  end

  @doc """
  Extract primitive actions from a solution tree (maintained for compatibility).
  """
  @spec extract_actions(Plan.solution_tree()) :: [Plan.plan_step()]
  def extract_actions(solution_tree) do
    Plan.Utils.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Get statistics about a solution tree (maintained for compatibility).
  """
  @spec tree_stats(Plan.solution_tree()) :: map()
  def tree_stats(solution_tree) do
    Plan.Utils.tree_stats(solution_tree)
  end

  @doc """
  Calculate the cost (number of primitive actions) of a solution tree.
  """
  @spec plan_cost(Plan.solution_tree()) :: non_neg_integer()
  def plan_cost(solution_tree) do
    Plan.Utils.plan_cost(solution_tree)
  end

  @doc """
  Create a domain interface from an AriaEngine.Domain struct (maintained for compatibility).
  """
  @spec domain_to_interface(AriaEngine.Domain.Core.t()) :: domain_interface()
  def domain_to_interface(%AriaEngine.Domain.Core{} = domain) do
    %{
      actions: domain.actions,
      task_methods: domain.task_methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: domain.multigoal_methods
    }
  end

  ## Private Helper Functions

  # Convert domain interface to Domain struct (maintained for compatibility)
  @spec interface_to_domain(domain_interface()) :: AriaEngine.Domain.Core.t()
  defp interface_to_domain(interface) do
    %AriaEngine.Domain.Core{
      name: "legacy_domain_interface",
      actions: Map.get(interface, :actions, %{}),
      task_methods: Map.get(interface, :task_methods, %{}),
      unigoal_methods: Map.get(interface, :unigoal_methods, %{}),
      multigoal_methods: Map.get(interface, :multigoal_methods, [])
    }
  end
end
