# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planning.CoreInterface do
  @moduledoc "Replan from a failure point using HybridPlanner.HybridCoordinatorV2.\n"
  alias Planning.Internal
  alias Core
  @type t :: Planning.HighLevel.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()
  @doc "Simple planning interface - finds a plan to achieve the given todos.\n"
  @spec plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [todo_item()], keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan(_domain, _state, _todos, _opts \\ []) do
    # Note: AriaEngine.PlannerAdapter.plan currently only returns {:error, String.t()}
    # This is a stub implementation - full planning requires aria_hybrid_planner integration
    # TODO: Implement actual planning logic using aria_hybrid_planner
    {:error, "Planning not yet implemented in self-contained mode"}
  end

  @doc "Advanced planning interface - returns the full solution tree.\n"
  @spec plan_with_tree(
          AriaEngine.DomainBehaviour.t(),
          AriaEngine.Core.state(),
          [todo_item()],
          keyword()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(domain, state, todos, opts \\ []) do
    try do
      # Create HybridCoordinatorV2 for HTN planning
      coordinator = HybridPlanner.HybridCoordinatorV2.new_default(opts)

      # Create initial solution tree
      solution_tree = Plan.Utils.create_initial_solution_tree(todos, state)

      # Use the actual HTN planning system
      # For now, we'll use the lazy execution as a working implementation
      # until the full HTN system is connected
      case AriaEngine.Planning.LazyExecution.plan(domain, state, todos, Map.new(opts)) do
        {:ok, lazy_plan} ->
          # Convert lazy plan to solution tree format
          actions = Map.get(lazy_plan, :actions, [])

          # Create a simple solution tree with primitive action nodes
          {updated_tree, _} = create_solution_tree_from_actions(solution_tree, actions, state)

          {:ok, updated_tree}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      error ->
        {:error, "Planning error: #{Exception.message(error)}"}
    end
  end

  @doc "Executes a plan step by step, returning the final state.\n"
  @spec execute_plan(AriaEngine.DomainBehaviour.t(), AriaEngine.Core.state(), [plan_step()]) ::
          {:ok, AriaEngine.Core.state()} | {:error, String.t()}
  def execute_plan(_domain, _initial_state, _plan) do
    # TODO: Implement actual plan execution using aria_hybrid_planner
    {:error, "Plan execution not yet implemented in self-contained mode"}
  end

  @doc "Replan from a failure point using HybridPlanner.HybridCoordinator.\n"
  @spec replan(Core.t(), String.t(), keyword()) ::
          {:ok, Core.t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ [])

  def replan(%Core{solution_tree: solution_tree} = engine, _fail_node_id, _opts)
      when not is_nil(solution_tree) do
    _domain_interface = Internal.to_planner_interface(engine)

    # Note: AriaEngine.PlannerAdapter.replan currently only returns {:error, String.t()}
    # This is a stub implementation - full replanning requires aria_hybrid_planner integration
    # TODO: Implement actual replanning logic using aria_hybrid_planner
    {:error, "Replanning not yet implemented in self-contained mode"}
  end

  def replan(%Core{solution_tree: nil}, _fail_node_id, _opts) do
    {:error, "No solution tree available for replanning"}
  end

  @doc "Validate the current plan.\n"
  @spec validate_plan(Core.t()) :: {:ok, map()} | {:error, String.t()}
  def validate_plan(%Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do
    _domain_interface = Internal.to_planner_interface(engine)
    # TODO: Implement actual plan validation using aria_hybrid_planner
    {:error, "Plan validation not yet implemented in self-contained mode"}
  end

  def validate_plan(%Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end

  # Private helper functions

  @spec create_solution_tree_from_actions(solution_tree(), list(), any()) :: {solution_tree(), any()}
  defp create_solution_tree_from_actions(solution_tree, actions, initial_state) do
    # Create primitive action nodes for each action
    {updated_nodes, final_state} = Enum.reduce(actions, {solution_tree.nodes, initial_state},
      fn action_item, {nodes_acc, state_acc} ->
        node_id = Plan.Utils.generate_node_id()

        # Normalize action format - handle different input formats
        normalized_task = case action_item do
          {action, args} when is_atom(action) and is_list(args) ->
            {action, args}
          {action, args} when is_binary(action) and is_list(args) ->
            {String.to_atom(action), args}
          {:achieve, goal} ->
            {:achieve, goal}
          other ->
            # Fallback for unknown formats
            other
        end

        # Create a primitive action node
        action_node = %{
          id: node_id,
          task: normalized_task,
          parent_id: solution_tree.root_id,
          children_ids: [],
          state: state_acc,
          visited: true,
          expanded: true,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: true,
          is_durative: false
        }

        # Add to nodes and update parent's children
        updated_nodes = Map.put(nodes_acc, node_id, action_node)

        # Update root node to include this child
        root_node = updated_nodes[solution_tree.root_id]
        updated_root = %{root_node | children_ids: root_node.children_ids ++ [node_id]}
        final_nodes = Map.put(updated_nodes, solution_tree.root_id, updated_root)

        {final_nodes, state_acc}
      end)

    updated_tree = %{solution_tree | nodes: updated_nodes}
    {updated_tree, final_state}
  end
end
