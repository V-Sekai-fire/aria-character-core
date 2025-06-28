# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Core do
  @moduledoc "Core IPyHOP planning algorithm and decomposition loop.\n"
  require Logger
  alias Plan.{NodeExpansion, Backtracking}
  alias AriaEngine.Plan.Utils
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), State.fact_value()}
  @type todo_item :: task() | goal() | AriaEngine.Multigoal.t()
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
  defp debug_puts(message, verbose_level \\ 0) do
    if Application.get_env(:ex_unit, :trace, false) or not test_mode?() do
      if verbose_level <= get_verbose_level() do
        Logger.debug(message)
      end
    end
  end

  defp test_mode?() do
    Mix.env() == :test
  end

  defp get_verbose_level() do
    Process.get(:verbose_level, 0)
  end

  @doc "Main IPyHOP planning function that creates a solution tree to achieve the given todos.\n"
  @spec plan(AriaEngine.Domain.Core.t(), State.t(), [todo_item()], keyword()) ::
          plan_result()
  def plan(domain, state, todos, opts \\ []) do
    opts = Keyword.put_new(opts, :replan_depth, @default_replan_depth)
    solution_tree = Utils.create_initial_solution_tree(todos, state)
    ipyhop(domain, state, solution_tree, opts)
  end

  @spec ipyhop(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), keyword()) ::
          plan_result()
  def ipyhop(domain, current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)
    plan_decomposition_loop(domain, current_state, solution_tree, 0, max_depth, verbose)
  end

  @spec plan_decomposition_loop(
          AriaEngine.Domain.Core.t(),
          State.t(),
          solution_tree(),
          integer(),
          integer(),
          integer()
        ) :: plan_result()
  defp plan_decomposition_loop(domain, current_state, solution_tree, depth, max_depth, verbose) do
    Process.put(:verbose_level, verbose)
    log_planning_progress(depth, solution_tree, verbose)

    cond do
      depth >= max_depth ->
        handle_max_depth_exceeded(depth, verbose)

      true ->
        case find_next_node(solution_tree) do
          nil ->
            handle_no_more_nodes(solution_tree, verbose)

          node_id ->
            expand_node_and_continue(
              domain,
              current_state,
              solution_tree,
              node_id,
              depth,
              max_depth,
              verbose
            )
        end
    end
  end

  defp log_planning_progress(depth, solution_tree, verbose) do
    if verbose > 3 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Depth #{depth}, Nodes: #{Kernel.map_size(solution_tree.nodes)}"
      )
    end
  end

  defp handle_max_depth_exceeded(depth, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Maximum planning depth exceeded at depth #{depth}")
    end

    {:error, "Maximum planning depth exceeded"}
  end

  defp handle_no_more_nodes(solution_tree, verbose) do
    if solution_complete?(solution_tree) do
      if verbose > 0 do
        debug_puts("PLAN_DECOMPOSITION_LOOP: Solution complete.")
      end

      {:ok, solution_tree}
    else
      if verbose > 0 do
        debug_puts(
          "PLAN_DECOMPOSITION_LOOP: No complete solution found after all nodes expanded."
        )
      end

      {:error, "No complete solution found"}
    end
  end

  defp expand_node_and_continue(
         domain,
         current_state,
         solution_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 3 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Expanding node #{node_id} (Task: #{inspect(solution_tree.nodes[node_id].task)})"
      )
    end

    case try_expand_node(domain, current_state, solution_tree, node_id, verbose) do
      {:ok, new_tree} ->
        handle_successful_expansion(
          domain,
          current_state,
          new_tree,
          node_id,
          depth,
          max_depth,
          verbose
        )

      {:error, reason} ->
        handle_expansion_error(reason, node_id, verbose)

      {:failure, failed_tree} ->
        handle_expansion_failure(
          domain,
          current_state,
          failed_tree,
          node_id,
          depth,
          max_depth,
          verbose
        )
    end
  end

  defp handle_successful_expansion(
         domain,
         current_state,
         new_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 3 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expanded successfully.")
    end

    plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)
  end

  defp handle_expansion_error(reason, node_id, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion failed: #{reason}")
    end

    {:error, reason}
  end

  defp handle_expansion_failure(
         domain,
         current_state,
         failed_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 0 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion returned :failure, attempting simplified backtrack."
      )
    end

    # Simplified IPyHOP-style backtracking: try alternative methods for the failed node
    case Backtracking.try_alternative_method_for_task(domain, failed_tree, node_id, verbose) do
      {:ok, new_tree} ->
        handle_successful_backtrack(domain, current_state, new_tree, depth, max_depth, verbose)

      :no_alternatives ->
        # No more alternatives for this node - find parent and try alternatives there
        case find_parent_for_backtrack(failed_tree, node_id) do
          nil ->
            handle_backtrack_error("No complete solution found - all alternatives exhausted", verbose)

          parent_id ->
            handle_expansion_failure(domain, current_state, failed_tree, parent_id, depth, max_depth, verbose)
        end

      {:error, reason} ->
        handle_backtrack_error(reason, verbose)
    end
  end

  # Find parent node for backtracking up the tree
  defp find_parent_for_backtrack(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      node -> node.parent_id
    end
  end

  defp handle_successful_backtrack(domain, current_state, new_tree, depth, max_depth, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Backtrack succeeded, continuing planning.")
    end

    plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)
  end

  defp handle_backtrack_error(reason, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Backtrack failed: #{reason}")
    end

    {:error, reason}
  end

  @spec find_next_node(solution_tree()) :: node_id() | nil
  defp find_next_node(solution_tree) do
    find_next_node_dfs(solution_tree, solution_tree.root_id)
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

  @spec try_expand_node(
          AriaEngine.Domain.Core.t(),
          State.t(),
          solution_tree(),
          node_id(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  defp try_expand_node(domain, state, solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        log_node_expansion(node_id, node.task, verbose)
        expand_task_by_type(domain, state, solution_tree, node_id, node.task, verbose)
    end
  end

  defp log_node_expansion(node_id, task, verbose) do
    if verbose > 2 do
      debug_puts("Expanding node #{node_id}: #{inspect(task)}")
    end
  end

  defp expand_task_by_type(domain, state, solution_tree, node_id, task, verbose) do
    case task do
      {:root, todos} ->
        NodeExpansion.expand_root_node(solution_tree, node_id, todos, state)

      {task_name, args} when is_binary(task_name) ->
        expand_string_task(domain, state, solution_tree, node_id, task_name, args, verbose)

      {action_name, _args} when is_atom(action_name) ->
        expand_atom_task(domain, solution_tree, node_id, action_name)

      {predicate, subject, fact_value} ->
        NodeExpansion.expand_goal_node(
          domain,
          state,
          solution_tree,
          node_id,
          predicate,
          subject,
          fact_value,
          verbose
        )

      %AriaEngine.Multigoal{} = multigoal ->
        NodeExpansion.expand_multigoal_node(
          domain,
          state,
          solution_tree,
          node_id,
          multigoal,
          verbose
        )

      _ ->
        {:error, "Unknown task type: #{inspect(task)}"}
    end
  end

  defp expand_string_task(domain, state, solution_tree, node_id, task_name, args, verbose) do
    action_atom = String.to_atom(task_name)

    cond do
      AriaEngine.Domain.has_action?(domain, action_atom) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)

      AriaEngine.Domain.Core.get_durative_action(domain, action_atom) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)

      true ->
        NodeExpansion.expand_task_node(
          domain,
          state,
          solution_tree,
          node_id,
          task_name,
          args,
          verbose
        )
    end
  end

  defp expand_atom_task(domain, solution_tree, node_id, action_name) do
    cond do
      AriaEngine.Domain.has_action?(domain, action_name) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)

      AriaEngine.Domain.Core.get_durative_action(domain, action_name) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)

      true ->
        {:error, "Unknown action: #{action_name}"}
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
