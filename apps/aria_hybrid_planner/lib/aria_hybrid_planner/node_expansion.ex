# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.NodeExpansion do
  @moduledoc "Functions for expanding different types of nodes in the solution tree.\n"
  require Logger
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), any()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: map() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean(),
          is_durative: boolean()
        }
  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }
  @spec expand_root_node(solution_tree(), node_id(), [todo_item()], map()) ::
          {:ok, solution_tree()}
  def expand_root_node(solution_tree, root_id, todos, state) do
    {new_tree, child_ids} =
      Enum.reduce(todos, {solution_tree, []}, fn todo, {tree, ids} ->
        child_id = Plan.Utils.generate_node_id()

        child_node = %{
          id: child_id,
          task: todo,
          parent_id: root_id,
          children_ids: [],
          state: state,
          visited: false,
          expanded: false,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: false,
          is_durative: false
        }

        new_tree = put_in(tree.nodes[child_id], child_node)
        {new_tree, [child_id | ids]}
      end)

    child_ids = Enum.reverse(child_ids)
    updated_root = %{solution_tree.nodes[root_id] | children_ids: child_ids, expanded: true, method_tried: :root_expansion}
    final_tree = put_in(new_tree.nodes[root_id], updated_root)
    {:ok, final_tree}
  end

  @spec expand_multigoal_node(
          map(),
          map(),
          solution_tree(),
          node_id(),
          Multigoal.t(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  def expand_multigoal_node(_domain, _state, solution_tree, node_id, multigoal, verbose) do
    node = solution_tree.nodes[node_id]

    if AriaEngineCore.Multigoal.satisfied?(multigoal, node.state) do
      updated_node = %{node | expanded: true, is_primitive: true}
      final_tree = put_in(solution_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    else
      unsatisfied = AriaEngineCore.Multigoal.unsatisfied_goals(multigoal, node.state)

      if verbose > 2 do
        Logger.debug("Multigoal has #{length(unsatisfied)} unsatisfied goals")
      end

      {new_tree, child_ids} =
        Enum.reduce(unsatisfied, {solution_tree, []}, fn goal, {tree, ids} ->
          child_id = Plan.Utils.generate_node_id()

          child_node = %{
            id: child_id,
            task: goal,
            parent_id: node_id,
            children_ids: [],
            state: node.state,
            visited: false,
            expanded: false,
            method_tried: nil,
            blacklisted_methods: [],
            is_primitive: false,
            is_durative: false
          }

          new_tree = put_in(tree.nodes[child_id], child_node)
          {new_tree, [child_id | ids]}
        end)

      child_ids = Enum.reverse(child_ids)
      updated_node = %{node | children_ids: child_ids, expanded: true, method_tried: :multigoal_expansion}
      final_tree = put_in(new_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    end
  end

  @spec mark_as_primitive(solution_tree(), node_id(), keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def mark_as_primitive(solution_tree, node_id, opts \\ []) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        is_durative = Keyword.get(opts, :is_durative, false)
        updated_node = %{node | is_primitive: true, expanded: true, is_durative: is_durative}
        final_tree = put_in(solution_tree.nodes[node_id], updated_node)
        {:ok, final_tree}
    end
  end
end
