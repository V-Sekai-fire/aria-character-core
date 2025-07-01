# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Core do
  @moduledoc "Core IPyHOP planning algorithm and decomposition loop.\n"
  require Logger
  alias Plan.{Backtracking}
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), State.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
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
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @default_max_depth 100
  @default_replan_depth 10
  @default_verbose 0

  defp test_mode?() do
    Mix.env() == :test
  end

  defp get_verbose_level() do
    Process.get(:verbose_level, 0)
  end

  defp log_planning_progress(depth, solution_tree, verbose) do
    if verbose > 3 do
      Logger.debug(
        "PLAN_DECOMPOSITION_LOOP: Depth #{depth}, Nodes: #{Kernel.map_size(solution_tree.nodes)}"
      )
    end
  end

  defp handle_max_depth_exceeded(depth, verbose) do
    if verbose > 0 do
      Logger.debug("PLAN_DECOMPOSITION_LOOP: Maximum planning depth exceeded at depth #{depth}")
    end

    {:error, "Maximum planning depth exceeded"}
  end

  defp handle_no_more_nodes(solution_tree, verbose) do
    if solution_complete?(solution_tree) do
      if verbose > 0 do
        Logger.debug("PLAN_DECOMPOSITION_LOOP: Solution complete.")
      end

      {:ok, solution_tree}
    else
      if verbose > 0 do
        Logger.debug(
          "PLAN_DECOMPOSITION_LOOP: No complete solution found after all nodes expanded."
        )
      end

      {:error, "No complete solution found"}
    end
  end

  defp handle_expansion_error(reason, node_id, verbose) do
    if verbose > 0 do
      Logger.debug("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion failed: #{reason}")
    end

    {:error, reason}
  end

  # Find parent node for backtracking up the tree
  defp find_parent_for_backtrack(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      node -> node.parent_id
    end
  end

  defp handle_backtrack_error(reason, verbose) do
    if verbose > 0 do
      Logger.debug("PLAN_DECOMPOSITION_LOOP: Backtrack failed: #{reason}")
    end

    {:error, reason}
  end

  @spec find_next_node_dfs(solution_tree(), node_id()) :: node_id() | nil
  defp find_next_node_dfs(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        nil

      node ->
        cond do
          not node.expanded and not node.is_primitive ->
            node_id

          Enum.empty?(node.children_ids) ->
            if node.is_primitive or node.expanded do
              nil
            else
              node_id
            end

          true ->
            Enum.find_value(node.children_ids, fn child_id ->
              find_next_node_dfs(solution_tree, child_id)
            end)
        end
    end
  end

  defp log_node_expansion(node_id, task, verbose) do
    if verbose > 2 do
      Logger.debug("Expanding node #{node_id}: #{inspect(task)}")
    end
  end

  @spec solution_complete?(solution_tree()) :: boolean()
  defp solution_complete?(solution_tree) do
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = id == solution_tree.root_id
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  @spec get_default_verbose() :: integer()
  def get_default_verbose() do
    @default_verbose
  end

  @spec get_default_replan_depth() :: integer()
  def get_default_replan_depth() do
    @default_replan_depth
  end
end
