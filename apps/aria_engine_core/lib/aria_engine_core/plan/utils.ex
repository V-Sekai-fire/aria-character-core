# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Plan.Utils do
  @moduledoc "Utility functions for IPyHOP planning.\n"
  alias AriaEngineCore.State
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), State.fact_value()}
  @type todo_item :: task() | goal() | AriaEngineCore.Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: State.t() | nil,
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
  @spec create_initial_solution_tree([todo_item()], State.t()) :: solution_tree()
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

  @spec generate_node_id() :: String.t()
  def generate_node_id do
    "node_#{:erlang.unique_integer([:positive])}"
  end

  @spec solution_complete?(solution_tree()) :: boolean()
  def solution_complete?(solution_tree) do
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = id == solution_tree.root_id
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  @spec update_cached_states(solution_tree(), State.t()) :: solution_tree()
  def update_cached_states(solution_tree, new_state) do
    updated_nodes =
      Map.new(solution_tree.nodes, fn {id, node} -> {id, %{node | state: new_state}} end)

    %{solution_tree | nodes: updated_nodes}
  end

  @spec get_all_descendants(solution_tree(), node_id()) :: [node_id()]
  def get_all_descendants(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        direct_children = node.children_ids

        all_descendants =
          Enum.flat_map(direct_children, fn child_id ->
            [child_id | get_all_descendants(solution_tree, child_id)]
          end)

        all_descendants
    end
  end

  @spec get_primitive_actions_dfs(solution_tree()) :: [plan_step()]
  def get_primitive_actions_dfs(solution_tree) do
    get_actions_from_node(solution_tree, solution_tree.root_id)
  end

  @spec get_actions_from_node(solution_tree(), node_id()) :: [plan_step()]
  defp get_actions_from_node(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        if node.is_primitive and node.expanded do
          case node.task do
            {action_name, args} -> [{action_name, args}]
            _ -> []
          end
        else
          Enum.flat_map(node.children_ids, fn child_id ->
            get_actions_from_node(solution_tree, child_id)
          end)
        end
    end
  end

  @doc "Validates a plan by executing it step by step.\nFor compatibility with existing AriaEngineCore usage.\n"
  @spec validate_plan(map(), State.t(), [plan_step()] | solution_tree()) ::
          {:ok, State.t()} | {:error, String.t()}
  def validate_plan(
        domain,
        initial_state,
        %{root_id: _} = solution_tree
      ) when is_map(domain) do
    actions = get_primitive_actions_dfs(solution_tree)
    validate_plan(domain, initial_state, actions)
  end

  def validate_plan(domain, initial_state, plan) when is_map(domain) and is_list(plan) do
    Enum.reduce_while(plan, {:ok, initial_state}, fn {action_name, args}, {:ok, state} ->
      action_atom =
        if is_binary(action_name) do
          String.to_atom(action_name)
        else
          action_name
        end

      case AriaEngineCore.Domain.execute_action(domain, state, action_atom, args) do
        false -> {:halt, {:error, "Action #{action_name} failed during validation"}}
        {:ok, new_state} -> {:cont, {:ok, new_state}}
      end
    end)
  end

  @doc "Estimates the cost of a plan (simple step count for now).\nFor compatibility with existing AriaEngineCore usage.\n"
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(%{root_id: _} = solution_tree) do
    actions = get_primitive_actions_dfs(solution_tree)
    length(actions)
  end

  def plan_cost(plan) when is_list(plan) do
    length(plan)
  end

  @doc "Get statistics about the solution tree.\n"
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    nodes = Map.values(solution_tree.nodes)

    %{
      total_nodes: length(nodes),
      expanded_nodes: Enum.count(nodes, & &1.expanded),
      primitive_actions: length(get_primitive_actions_dfs(solution_tree)),
      max_depth: calculate_max_depth(solution_tree, solution_tree.root_id, 0)
    }
  end

  @spec calculate_max_depth(solution_tree(), node_id(), integer()) :: integer()
  defp calculate_max_depth(solution_tree, node_id, current_depth) do
    case solution_tree.nodes[node_id] do
      nil ->
        current_depth

      node ->
        if Enum.empty?(node.children_ids) do
          current_depth
        else
          Enum.map(node.children_ids, fn child_id ->
            calculate_max_depth(solution_tree, child_id, current_depth + 1)
          end)
          |> Enum.max()
        end
    end
  end

  @spec is_primitive_task?(todo_item()) :: boolean()
  def is_primitive_task?({name, _args}) when is_atom(name) do
    true
  end

  def is_primitive_task?({name, _args}) when is_binary(name) do
    false
  end

  def is_primitive_task?(_) do
    false
  end
end
