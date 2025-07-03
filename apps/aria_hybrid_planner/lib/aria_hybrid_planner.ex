# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  AriaHybridPlanner provides core temporal planning and execution capabilities.

  ## Usage

      # Plan and execute in one step (recommended)
      {:ok, {final_state, solution_tree}} = AriaHybridPlanner.run_lazy(domain, state, todos)

      # Plan first, then execute separately
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, opts)
      {:ok, {final_state, updated_tree}} = AriaHybridPlanner.run_lazy_tree(domain, state, plan.solution_tree)

      # Advanced planning with options
      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos, verbose: 2, max_depth: 15)

  ## Key Features

  - HTN (Hierarchical Task Network) planning
  - Temporal constraint handling
  - Solution tree generation and execution
  - Automatic failure recovery
  - Entity-based resource management

  ## API Functions

  ### Primary API
  - `plan/4` - Planning with options, returns detailed plan structure
  - `run_lazy/3` - Plan and execute in one step
  - `run_lazy_tree/3` - Execute with existing solution tree
  """

  # Type definitions
  @type domain :: term()
  @type state :: term()
  @type todo_item :: term()
  @type solution_tree :: map()

  # Core planning and execution functions (direct implementation)
  require Logger

  @doc """
  Plan using breadth-first HTN decomposition with node-by-node expansion.
  """
  @spec plan(term(), term(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(domain, initial_state, todos, opts \\ []) do
    try do
      verbose = Keyword.get(opts, :verbose, 0)
      max_depth = Keyword.get(opts, :max_depth, 100)

      if verbose > 1 do
        Logger.debug("HTN Planning: Starting with #{length(todos)} todos, max_depth: #{max_depth}")
      end

      # Create initial solution tree using existing infrastructure
      solution_tree = Plan.Utils.create_initial_solution_tree(todos, initial_state)

      # Expand the root node with todos
      {:ok, expanded_tree} = Plan.NodeExpansion.expand_root_node(solution_tree, solution_tree.root_id, todos, initial_state)

      # Perform HTN planning by expanding nodes one at a time (breadth-first)
      if verbose > 1 do
        Logger.debug("HTN Planning: Starting BFS planning with expanded tree")
        Logger.debug("HTN Planning: Initial tree has #{map_size(expanded_tree.nodes)} nodes")
      end

      case plan_recursive_bfs(domain, expanded_tree, initial_state, opts, 0, max_depth) do
        {:ok, final_tree} ->
          if verbose > 1 do
            Logger.debug("HTN Planning: BFS planning completed successfully")
          end
          plan = %{
            solution_tree: final_tree,
            metadata: %{
              created_at: System.system_time(:millisecond),
              domain: domain,
              planning_depth: max_depth
            }
          }

          if verbose > 0 do
            stats = Plan.Utils.tree_stats(final_tree)
            Logger.debug("HTN Planning: Completed with #{stats.total_nodes} nodes, #{stats.action_count} actions")

            # Debug: Show tree structure
            Logger.debug("HTN Planning: Tree structure:")
            Enum.each(final_tree.nodes, fn {id, node} ->
              Logger.debug("  Node #{id}: task=#{inspect(node.task)}, primitive=#{node.is_primitive}, expanded=#{node.expanded}")
            end)

            # Debug: Try to extract actions
            actions = AriaEngineCore.Plan.get_primitive_actions_dfs(final_tree)
            Logger.debug("HTN Planning: Extracted #{length(actions)} actions: #{inspect(actions)}")
          end

          {:ok, plan}

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Plan and execute in one step using lazy execution.
  """
  @spec run_lazy(term(), term(), [term()], keyword()) :: {:ok, {term(), solution_tree()}} | {:error, String.t()}
  def run_lazy(domain, initial_state, todos, opts \\ []) do
    case plan(domain, initial_state, todos, opts) do
      {:ok, plan} ->
        case run_lazy_tree(domain, initial_state, plan.solution_tree, opts) do
          {:ok, final_state} ->
            {:ok, {final_state, plan.solution_tree}}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Execute a solution tree using lazy execution.
  """
  @spec run_lazy_tree(term(), term(), solution_tree(), keyword()) :: {:ok, term()} | {:error, String.t()}
  def run_lazy_tree(domain, initial_state, solution_tree, opts \\ []) do
    # Add domain to options for executor
    execution_opts = Keyword.put(opts, :domain, domain)
    Plan.ReentrantExecutor.execute_plan_lazy(solution_tree, initial_state, execution_opts)
  end

  # Breadth-first HTN planning implementation (natural order, no sorting)
  defp plan_recursive_bfs(domain, solution_tree, state, opts, depth, max_depth) do
    verbose = Keyword.get(opts, :verbose, 0)

    if depth >= max_depth do
      if verbose > 1 do
        Logger.debug("HTN Planning: Reached maximum depth #{max_depth}")
      end
      {:ok, solution_tree}
    else
      case find_next_unexpanded_node(solution_tree) do
        nil ->
          # All nodes are expanded or primitive
          if verbose > 1 do
            Logger.debug("HTN Planning: No more unexpanded nodes, planning complete")
          end
          {:ok, solution_tree}

        node_id ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Expanding node #{node_id} (iteration depth #{depth})")
          end

          case expand_single_node(domain, solution_tree, node_id, state, opts) do
            {:ok, updated_tree} ->
              plan_recursive_bfs(domain, updated_tree, state, opts, depth + 1, max_depth)
            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  # Find the next unexpanded node (natural order from map iteration)
  defp find_next_unexpanded_node(solution_tree) do
    Enum.find_value(solution_tree.nodes, fn {id, node} ->
      if not node.expanded and not node.is_primitive do
        id
      else
        nil
      end
    end)
  end

  # Expand a single node based on its type
  defp expand_single_node(domain, solution_tree, node_id, state, opts) do
    node = solution_tree.nodes[node_id]
    expand_node_by_type(domain, solution_tree, node_id, node, state, opts)
  end

  # Expand a node based on its task type
  defp expand_node_by_type(domain, solution_tree, node_id, node, state, opts) do
    case node.task do
      # Multigoal expansion
      %AriaEngineCore.Multigoal{} = multigoal ->
        Plan.NodeExpansion.expand_multigoal_node(domain, state, solution_tree, node_id, multigoal)

      # Goal expansion (predicate, subject, value)
      {predicate, subject, value} when is_binary(predicate) ->
        expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, state, opts)

      # Task expansion (task_name, args) - handle both atoms and strings
      {task_name, args} when is_binary(task_name) or is_atom(task_name) ->
        expand_task_node(domain, solution_tree, node_id, to_string(task_name), args, state, opts)

      # Unknown task type - mark as primitive
      _ ->
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
    end
  end

  # Expand a goal node using unigoal methods
  defp expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Check if goal is already satisfied
    if goal_satisfied?(state, predicate, subject, value) do
      if verbose > 2 do
        Logger.debug("HTN Planning: Goal #{predicate}(#{subject}, #{value}) already satisfied")
      end
      Plan.NodeExpansion.mark_as_completed(solution_tree, node_id)
    else
      # Try to expand using unigoal methods
      case try_unigoal_methods(domain, state, predicate, subject, value, node.blacklisted_methods, opts) do
        {:ok, []} ->
          # Method returned empty list - goal completed
          Plan.NodeExpansion.mark_as_completed(solution_tree, node_id)

        {:ok, subtasks} ->
          # Create child nodes for subtasks
          create_child_nodes(solution_tree, node_id, subtasks, "unigoal_method")

        {:error, _reason} ->
          # No methods available - mark as primitive
          Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
      end
    end
  end

  # Expand a task node using task methods
  defp expand_task_node(domain, solution_tree, node_id, task_name, args, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Try to expand using task methods
    case try_task_methods(domain, state, task_name, args, node.blacklisted_methods, opts) do
      {:ok, []} ->
        # Method returned empty list - task completed
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} completed (empty method result)")
        end
        Plan.NodeExpansion.mark_as_completed(solution_tree, node_id)

      {:ok, subtasks} ->
        # Create child nodes for subtasks
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} expanded to #{length(subtasks)} subtasks")
        end
        create_child_nodes(solution_tree, node_id, subtasks, "task_method")

      {:error, _reason} ->
        # No methods available - validate as primitive action
        if verbose > 2 do
          Logger.debug("HTN Planning: No methods for task #{task_name}, validating as primitive action")
        end
        validate_primitive_action(domain, solution_tree, node_id, task_name, args, state, opts)
    end
  end

  # Try unigoal methods for a goal
  defp try_unigoal_methods(domain, state, predicate, subject, value, blacklisted_methods, opts) do
    case AriaCore.get_unigoal_methods_for_predicate(domain, predicate) do
      methods when map_size(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} -> Atom.to_string(method_name) in blacklisted_methods end)

        try_methods_sequentially(available_methods, state, {subject, value}, opts)

      _ ->
        {:error, "No unigoal methods found for predicate #{predicate}"}
    end
  end

  # Try task methods for a task
  defp try_task_methods(domain, state, task_name, args, blacklisted_methods, opts) do
    task_atom = String.to_atom(task_name)

    case AriaCore.get_task_methods_from_domain(domain, task_atom) do
      methods when is_list(methods) and length(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} -> Atom.to_string(method_name) in blacklisted_methods end)

        try_methods_sequentially(available_methods, state, args, opts)

      _ ->
        {:error, "No task methods found for task #{task_name}"}
    end
  end

  # Try methods sequentially until one succeeds
  defp try_methods_sequentially([], _state, _args, _opts) do
    {:error, "No available methods"}
  end

  defp try_methods_sequentially([{_method_name, method_fn} | rest], state, args, opts) do
    try do
      case method_fn.(state, args) do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        {:ok, subtasks} when is_list(subtasks) ->
          {:ok, subtasks}
        {:error, _reason} ->
          try_methods_sequentially(rest, state, args, opts)
        _other ->
          try_methods_sequentially(rest, state, args, opts)
      end
    rescue
      _e ->
        try_methods_sequentially(rest, state, args, opts)
    end
  end

  # Create child nodes from subtasks
  defp create_child_nodes(solution_tree, parent_node_id, subtasks, method_name) do
    parent_node = solution_tree.nodes[parent_node_id]

    # Generate child nodes
    {child_nodes, child_ids} = subtasks
    |> Enum.with_index()
    |> Enum.map(fn {subtask, index} ->
      child_id = "#{parent_node_id}_#{method_name}_#{index}"
      child_node = %{
        id: child_id,
        task: subtask,
        parent_id: parent_node_id,
        children_ids: [],
        state: parent_node.state,
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }
      {{child_id, child_node}, child_id}
    end)
    |> Enum.unzip()

    # Update parent node
    updated_parent = %{parent_node |
      method_tried: method_name,
      expanded: true,
      children_ids: child_ids
    }

    # Update solution tree
    updated_nodes = child_nodes
    |> Enum.into(solution_tree.nodes)
    |> Map.put(parent_node_id, updated_parent)

    updated_tree = %{solution_tree | nodes: updated_nodes}
    {:ok, updated_tree}
  end

  # Validate a primitive action by attempting to execute it
  defp validate_primitive_action(domain, solution_tree, node_id, task_name, args, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    task_atom = String.to_atom(task_name)

    # Try to execute the primitive action to validate preconditions
    case AriaCore.execute_action(domain, state, task_atom, args) do
      {:ok, _new_state} ->
        # Action is valid - mark as primitive
        if verbose > 2 do
          Logger.debug("HTN Planning: Primitive action #{task_name} validated successfully")
        end
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

      {:error, reason} ->
        # Action fails preconditions - planning should fail
        if verbose > 1 do
          Logger.debug("HTN Planning: Primitive action #{task_name} failed: #{inspect(reason)}")
        end
        {:error, "Primitive action #{task_name} failed: #{reason}"}
    end
  end

  # Check if a goal is satisfied in the current state
  defp goal_satisfied?(state, _predicate, subject, value) do
    case Map.get(state, subject) do
      ^value -> true
      _ -> false
    end
  end

  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    case Application.spec(:aria_hybrid_planner, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "unknown"
    end
  end
end
