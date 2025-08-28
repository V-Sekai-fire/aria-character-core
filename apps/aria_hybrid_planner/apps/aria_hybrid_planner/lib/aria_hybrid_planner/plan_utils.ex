# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Plan.Utils do
  @moduledoc """
  Utility functions for plan manipulation and analysis.

  This module provides essential utilities for working with solution trees,
  extracting primitive actions, validating plans, and managing plan state.
  """

  alias AriaEngineCore.Plan

  @type solution_tree :: Plan.solution_tree()
  @type solution_node :: Plan.solution_node()
  @type node_id :: Plan.node_id()
  @type plan_step :: Plan.plan_step()

  @doc """
  Create an initial solution tree from a list of todos and initial state.
  """
  @spec create_initial_solution_tree([Plan.todo_item()], AriaState.t()) :: solution_tree()
  def create_initial_solution_tree(todos, initial_state) do
    root_id = generate_node_id()

    root_node = %{
      id: root_id,
      task: {:root, todos},
      parent_id: nil,
      children_ids: [],
      state: initial_state,
      visited: false,
      expanded: false,
      method_tried: nil,
      blacklisted_methods: [],
      is_primitive: false,
      is_durative: false
    }

    %{
      root_id: root_id,
      nodes: %{root_id => root_node},
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
  end

  @doc """
  Generate a unique node ID for solution tree nodes.
  """
  @spec generate_node_id() :: node_id()
  def generate_node_id() do
    "node_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end

  @doc """
  Calculate the cost of a plan (number of primitive actions).
  """
  @spec plan_cost(solution_tree()) :: integer()
  def plan_cost(solution_tree) do
    solution_tree
    |> AriaEngineCore.Plan.get_primitive_actions_dfs()
    |> length()
  end

  @doc """
  Get statistics about a solution tree.
  """
  @spec tree_stats(solution_tree()) :: map()
  def tree_stats(solution_tree) do
    nodes = solution_tree.nodes
    primitive_count = Enum.count(nodes, fn {_id, node} -> node.is_primitive end)
    task_count = Enum.count(nodes, fn {_id, node} -> not node.is_primitive end)

    %{
      total_nodes: map_size(nodes),
      primitive_nodes: primitive_count,
      task_nodes: task_count,
      action_count: plan_cost(solution_tree),
      blacklisted_commands: MapSet.size(solution_tree.blacklisted_commands)
    }
  end

  @doc """
  Update cached states in a solution tree after state changes.
  """
  @spec update_cached_states(solution_tree(), AriaState.t()) :: solution_tree()
  def update_cached_states(solution_tree, new_state) do
    # Update the root node's state and propagate as needed
    root_node = solution_tree.nodes[solution_tree.root_id]
    updated_root = %{root_node | state: new_state}
    updated_nodes = Map.put(solution_tree.nodes, solution_tree.root_id, updated_root)

    %{solution_tree | nodes: updated_nodes}
  end

  @doc """
  Get all descendant node IDs for a given node.
  """
  @spec get_all_descendants(solution_tree(), node_id()) :: [node_id()]
  def get_all_descendants(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> []
      node ->
        direct_children = node.children_ids
        indirect_descendants = Enum.flat_map(direct_children, fn child_id ->
          get_all_descendants(solution_tree, child_id)
        end)
        direct_children ++ indirect_descendants
    end
  end

  @doc """
  Remove a node and all its descendants from a solution tree.
  """
  @spec remove_subtree(solution_tree(), node_id()) :: solution_tree()
  def remove_subtree(solution_tree, node_id) do
    descendants = get_all_descendants(solution_tree, node_id)
    nodes_to_remove = [node_id | descendants]
    updated_nodes = Map.drop(solution_tree.nodes, nodes_to_remove)

    %{solution_tree | nodes: updated_nodes}
  end

  @doc """
  Find the path from root to a specific node.
  """
  @spec get_path_to_node(solution_tree(), node_id()) :: [node_id()]
  def get_path_to_node(solution_tree, target_node_id) do
    get_path_to_node_recursive(solution_tree, solution_tree.root_id, target_node_id, [])
  end

  defp get_path_to_node_recursive(solution_tree, current_node_id, target_node_id, path) do
    new_path = [current_node_id | path]

    if current_node_id == target_node_id do
      Enum.reverse(new_path)
    else
      case solution_tree.nodes[current_node_id] do
        nil -> []
        node ->
          Enum.find_value(node.children_ids, fn child_id ->
            result = get_path_to_node_recursive(solution_tree, child_id, target_node_id, new_path)
            if Enum.empty?(result), do: nil, else: result
          end) || []
      end
    end
  end

  @doc """
  Check if a solution tree is complete (all nodes are expanded or primitive).
  """
  @spec is_complete?(solution_tree()) :: boolean()
  def is_complete?(solution_tree) do
    Enum.all?(solution_tree.nodes, fn {_id, node} ->
      node.is_primitive or node.expanded
    end)
  end

  @doc """
  Get all leaf nodes (nodes with no children) in a solution tree.
  """
  @spec get_leaf_nodes(solution_tree()) :: [node_id()]
  def get_leaf_nodes(solution_tree) do
    solution_tree.nodes
    |> Enum.filter(fn {_id, node} -> Enum.empty?(node.children_ids) end)
    |> Enum.map(fn {id, _node} -> id end)
  end

  @doc """
  Count nodes by type in a solution tree.
  """
  @spec count_nodes_by_type(solution_tree()) :: map()
  def count_nodes_by_type(solution_tree) do
    Enum.reduce(solution_tree.nodes, %{primitive: 0, task: 0, goal: 0, multigoal: 0},
      fn {_id, node}, acc ->
        case node.task do
          {_action, _args} when node.is_primitive ->
            Map.update!(acc, :primitive, &(&1 + 1))
          {_task_name, _args} ->
            Map.update!(acc, :task, &(&1 + 1))
          {_predicate, _subject, _value} ->
            Map.update!(acc, :goal, &(&1 + 1))
          %AriaEngineCore.Multigoal{} ->
            Map.update!(acc, :multigoal, &(&1 + 1))
          _ ->
            acc
        end
      end)
  end
end
