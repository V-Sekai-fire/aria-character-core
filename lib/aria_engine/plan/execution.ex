# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Execution do
  @moduledoc """
  Plan execution utilities with lazy refinement and blacklisting support.

  This module provides utilities for plan execution, including the core
  `run_lazy_refineahead` function that implements IPyHOP-style lazy refinement
  with proper backtracking and blacklisting functionality.
  """

  require Logger

  @type execution_result :: {:ok, State.t()} | {:error, String.t()}

  @doc """
  Execute a solution tree using lazy refinement with backtracking.

  This function implements the core IPyHOP algorithm adapted for Elixir,
  providing incremental refinement of the solution tree with proper
  state management and backtracking when actions or methods fail.

  ## Parameters

  - `domain`: The planning domain containing methods and actions
  - `initial_state`: The initial state to start execution from
  - `solution_tree`: The solution tree to execute
  - `opts`: Options including `:verbose` level

  ## Returns

  - `{:ok, final_state}` if execution succeeds
  - `{:error, reason}` if execution fails completely

  ## Algorithm

  Based on IPyHOP's `_planning` method, this function:

  1. Iteratively processes nodes in the solution tree
  2. Saves and restores state at each node for backtracking
  3. Tries alternative methods when nodes fail
  4. Uses blacklisting to prevent repeated failed actions
  5. Backtracks when no alternatives are available

  ## Examples

      iex> AriaEngine.Plan.Execution.run_lazy_refineahead(domain, state, tree)
      {:ok, final_state}

      iex> AriaEngine.Plan.Execution.run_lazy_refineahead(domain, state, tree, verbose: 3)
      {:ok, final_state}
  """
  @spec run_lazy_refineahead(
          AriaEngine.Domain.Core.t(),
          State.t(),
          AriaEngine.Plan.Core.solution_tree(),
          keyword()
        ) :: execution_result()
  def run_lazy_refineahead(
        %AriaEngine.Domain.Core{} = domain,
        %State{} = initial_state,
        solution_tree,
        opts \\ []
      ) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 0 do
      Logger.info("Starting run_lazy_refineahead execution")
    end

    # Initialize execution state
    execution_state = %{
      current_state: initial_state,
      domain: domain,
      solution_tree: solution_tree,
      blacklisted_commands: MapSet.new(),
      node_states: %{},
      verbose: verbose
    }

    # Start execution from root node
    case execute_from_node(execution_state, solution_tree.root_id) do
      {:ok, final_execution_state} ->
        if verbose > 0 do
          Logger.info("run_lazy_refineahead execution completed successfully")
        end

        {:ok, final_execution_state.current_state}

      {:error, reason} ->
        if verbose > 0 do
          Logger.warning("run_lazy_refineahead execution failed: #{reason}")
        end

        {:error, reason}
    end
  end

  # Execute starting from a specific node in the solution tree
  @spec execute_from_node(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp execute_from_node(execution_state, node_id) do
    case get_node(execution_state.solution_tree, node_id) do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        if execution_state.verbose > 2 do
          Logger.debug("Processing node #{node_id}: #{inspect(node.task)}")
        end

        # Save current state for potential backtracking
        execution_state = save_node_state(execution_state, node_id)

        # Process the node based on its type
        process_node(execution_state, node_id, node)
    end
  end

  # Process a node based on its task type
  @spec process_node(map(), String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  defp process_node(execution_state, node_id, node) do
    case node.task do
      {:root, _todos} ->
        # Root node - process all children (the todos have been expanded into children)
        process_children_sequentially(execution_state, node.children_ids)

      {task_name, args} when is_binary(task_name) ->
        # Task node - check if it's primitive or needs decomposition
        if node.is_primitive do
          # Convert to atom and execute as action
          action_name = String.to_atom(task_name)
          process_action_node(execution_state, node_id, node, action_name, args)
        else
          # Task node - try to decompose using methods
          process_task_node(execution_state, node_id, node, task_name, args)
        end

      {predicate, subject, fact_value} ->
        # Goal node - try to achieve the goal
        process_goal_node(execution_state, node_id, node, predicate, subject, fact_value)

      {action_name, args} when is_atom(action_name) ->
        # Action node - execute the primitive action
        process_action_node(execution_state, node_id, node, action_name, args)

      %AriaEngine.Multigoal{} = multigoal ->
        # Multigoal node - try to achieve multiple goals
        process_multigoal_node(execution_state, node_id, node, multigoal)

      _ ->
        {:error, "Unknown node type: #{inspect(node.task)}"}
    end
  end

  # Process children nodes sequentially
  @spec process_children_sequentially(map(), list()) :: {:ok, map()} | {:error, String.t()}
  defp process_children_sequentially(execution_state, []), do: {:ok, execution_state}

  defp process_children_sequentially(execution_state, [child_id | remaining_children]) do
    case execute_from_node(execution_state, child_id) do
      {:ok, updated_execution_state} ->
        process_children_sequentially(updated_execution_state, remaining_children)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Process a task node by trying available methods
  @spec process_task_node(map(), String.t(), map(), String.t(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp process_task_node(execution_state, node_id, node, task_name, args) do
    if node.expanded do
      # Node already expanded - process children
      process_children_sequentially(execution_state, node.children_ids)
    else
      # Try to expand the node using available methods
      try_task_methods(execution_state, node_id, node, task_name, args)
    end
  end

  # Try available methods for a task
  @spec try_task_methods(map(), String.t(), map(), String.t(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_task_methods(execution_state, node_id, node, task_name, args) do
    methods = AriaEngine.Domain.get_task_methods(execution_state.domain, task_name)
    available_methods = filter_blacklisted_methods(methods, node.blacklisted_methods)

    case available_methods do
      [] ->
        if execution_state.verbose > 2 do
          Logger.debug("No available methods for task #{task_name}")
        end

        {:error, "No methods available for task: #{task_name}"}

      [method | remaining_methods] ->
        try_method(execution_state, node_id, node, method, task_name, args, remaining_methods)
    end
  end

  # Try a specific method for a task
  @spec try_method(map(), String.t(), map(), tuple(), String.t(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_method(execution_state, node_id, node, {method_name, method_fn}, task_name, args, remaining_methods) do
    if execution_state.verbose > 2 do
      Logger.debug("Trying method #{method_name} for task #{task_name}")
    end

    # Apply the method to get subtasks
    case apply_method(method_fn, execution_state.current_state, args) do
      {:ok, subtasks} ->
        # Method succeeded - expand the node
        expand_node_with_subtasks(execution_state, node_id, node, subtasks, method_name)

      {:error, _reason} ->
        # Method failed - try next method or backtrack
        handle_method_failure(execution_state, node_id, node, method_name, task_name, args, remaining_methods)
    end
  end

  # Apply a method function safely
  @spec apply_method(function(), State.t(), list()) ::
          {:ok, list()} | {:error, String.t()}
  defp apply_method(method_fn, state, args) do
    try do
      case apply(method_fn, [state | args]) do
        false ->
          {:error, "Method returned false"}

        nil ->
          {:error, "Method returned nil"}

        subtasks when is_list(subtasks) ->
          {:ok, subtasks}

        other ->
          {:error, "Method returned invalid result: #{inspect(other)}"}
      end
    rescue
      e ->
        {:error, "Method execution failed: #{Exception.message(e)}"}
    end
  end

  # Expand a node with the subtasks returned by a method
  @spec expand_node_with_subtasks(map(), String.t(), map(), list(), String.t()) ::
          {:ok, map()} | {:error, String.t()}
  defp expand_node_with_subtasks(execution_state, node_id, node, subtasks, method_name) do
    if execution_state.verbose > 2 do
      Logger.debug("Method #{method_name} succeeded, expanding with #{length(subtasks)} subtasks")
    end

    # Create child nodes for subtasks
    {updated_tree, child_ids} = create_child_nodes(execution_state.solution_tree, node_id, subtasks)

    # Update the node as expanded
    updated_node = %{
      node
      | expanded: true,
        children_ids: child_ids,
        method_tried: method_name
    }

    updated_tree = put_node(updated_tree, node_id, updated_node)

    updated_execution_state = %{
      execution_state
      | solution_tree: updated_tree
    }

    # Process the child nodes
    process_children_sequentially(updated_execution_state, child_ids)
  end

  # Handle method failure by trying alternatives or backtracking
  @spec handle_method_failure(map(), String.t(), map(), String.t(), String.t(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp handle_method_failure(execution_state, node_id, node, failed_method, task_name, args, remaining_methods) do
    if execution_state.verbose > 2 do
      Logger.debug("Method #{failed_method} failed for task #{task_name}")
    end

    # Blacklist the failed method
    updated_node = %{
      node
      | blacklisted_methods: [failed_method | node.blacklisted_methods]
    }

    updated_tree = put_node(execution_state.solution_tree, node_id, updated_node)
    updated_execution_state = %{execution_state | solution_tree: updated_tree}

    case remaining_methods do
      [] ->
        # No more methods to try
        {:error, "All methods failed for task: #{task_name}"}

      [next_method | rest] ->
        # Try the next method
        try_method(updated_execution_state, node_id, updated_node, next_method, task_name, args, rest)
    end
  end

  # Process a goal node
  @spec process_goal_node(map(), String.t(), map(), String.t(), String.t(), term()) ::
          {:ok, map()} | {:error, String.t()}
  defp process_goal_node(execution_state, node_id, node, predicate, subject, fact_value) do
    # Check if goal is already achieved
    current_value = State.get_fact(execution_state.current_state, predicate, subject)

    if current_value == fact_value do
      if execution_state.verbose > 2 do
        Logger.debug("Goal already achieved: #{subject}.#{predicate} = #{inspect(fact_value)}")
      end

      {:ok, execution_state}
    else
      # Goal not achieved - try to achieve it using methods
      if node.expanded do
        process_children_sequentially(execution_state, node.children_ids)
      else
        try_goal_methods(execution_state, node_id, node, predicate, subject, fact_value)
      end
    end
  end

  # Try available methods for a goal
  @spec try_goal_methods(map(), String.t(), map(), String.t(), String.t(), term()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_goal_methods(execution_state, node_id, node, predicate, subject, fact_value) do
    methods = AriaEngine.Domain.get_unigoal_methods(execution_state.domain, predicate)
    available_methods = filter_blacklisted_methods(methods, node.blacklisted_methods)

    case available_methods do
      [] ->
        {:error, "No methods available for goal: #{subject}.#{predicate} = #{inspect(fact_value)}"}

      [method | remaining_methods] ->
        try_goal_method(execution_state, node_id, node, method, predicate, subject, fact_value, remaining_methods)
    end
  end

  # Try a specific method for a goal
  @spec try_goal_method(map(), String.t(), map(), tuple(), String.t(), String.t(), term(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_goal_method(execution_state, node_id, node, {method_name, method_fn}, predicate, subject, fact_value, remaining_methods) do
    if execution_state.verbose > 2 do
      Logger.debug("Trying goal method #{method_name} for #{subject}.#{predicate}")
    end

    case apply_method(method_fn, execution_state.current_state, [subject, fact_value]) do
      {:ok, subtasks} ->
        expand_node_with_subtasks(execution_state, node_id, node, subtasks, method_name)

      {:error, _reason} ->
        handle_goal_method_failure(execution_state, node_id, node, method_name, predicate, subject, fact_value, remaining_methods)
    end
  end

  # Handle goal method failure
  @spec handle_goal_method_failure(map(), String.t(), map(), String.t(), String.t(), String.t(), term(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp handle_goal_method_failure(execution_state, node_id, node, failed_method, predicate, subject, fact_value, remaining_methods) do
    updated_node = %{
      node
      | blacklisted_methods: [failed_method | node.blacklisted_methods]
    }

    updated_tree = put_node(execution_state.solution_tree, node_id, updated_node)
    updated_execution_state = %{execution_state | solution_tree: updated_tree}

    case remaining_methods do
      [] ->
        {:error, "All methods failed for goal: #{subject}.#{predicate} = #{inspect(fact_value)}"}

      [next_method | rest] ->
        try_goal_method(updated_execution_state, node_id, updated_node, next_method, predicate, subject, fact_value, rest)
    end
  end

  # Process a multigoal node
  @spec process_multigoal_node(map(), String.t(), map(), AriaEngine.Multigoal.t()) ::
          {:ok, map()} | {:error, String.t()}
  defp process_multigoal_node(execution_state, node_id, node, multigoal) do
    # Check if multigoal is already satisfied
    if AriaEngine.Multigoal.satisfied?(multigoal, execution_state.current_state) do
      if execution_state.verbose > 2 do
        Logger.debug("Multigoal already satisfied")
      end

      {:ok, execution_state}
    else
      # Multigoal not satisfied - try to achieve it using methods
      if node.expanded do
        process_children_sequentially(execution_state, node.children_ids)
      else
        try_multigoal_methods(execution_state, node_id, node, multigoal)
      end
    end
  end

  # Try available methods for a multigoal
  @spec try_multigoal_methods(map(), String.t(), map(), AriaEngine.Multigoal.t()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_multigoal_methods(execution_state, node_id, node, multigoal) do
    methods = AriaEngine.Domain.get_multigoal_methods(execution_state.domain)
    available_methods = filter_blacklisted_methods(methods, node.blacklisted_methods)

    case available_methods do
      [] ->
        # No multigoal methods available - fall back to splitting into individual goals
        if execution_state.verbose > 2 do
          Logger.debug("No multigoal methods available, splitting into individual goals")
        end

        split_multigoal_into_goals(execution_state, node_id, node, multigoal)

      [method | remaining_methods] ->
        try_multigoal_method(execution_state, node_id, node, method, multigoal, remaining_methods)
    end
  end

  # Try a specific method for a multigoal
  @spec try_multigoal_method(map(), String.t(), map(), tuple(), AriaEngine.Multigoal.t(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp try_multigoal_method(execution_state, node_id, node, {method_name, method_fn}, multigoal, remaining_methods) do
    if execution_state.verbose > 2 do
      Logger.debug("Trying multigoal method #{method_name}")
    end

    # Convert multigoal to goals list for method call
    goals = AriaEngine.Multigoal.to_goals(multigoal)

    case apply_method(method_fn, execution_state.current_state, [goals]) do
      {:ok, subtasks} ->
        expand_node_with_subtasks(execution_state, node_id, node, subtasks, method_name)

      {:error, _reason} ->
        handle_multigoal_method_failure(execution_state, node_id, node, method_name, multigoal, remaining_methods)
    end
  end

  # Handle multigoal method failure
  @spec handle_multigoal_method_failure(map(), String.t(), map(), String.t(), AriaEngine.Multigoal.t(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp handle_multigoal_method_failure(execution_state, node_id, node, failed_method, multigoal, remaining_methods) do
    updated_node = %{
      node
      | blacklisted_methods: [failed_method | node.blacklisted_methods]
    }

    updated_tree = put_node(execution_state.solution_tree, node_id, updated_node)
    updated_execution_state = %{execution_state | solution_tree: updated_tree}

    case remaining_methods do
      [] ->
        # No more multigoal methods - fall back to splitting
        if execution_state.verbose > 2 do
          Logger.debug("All multigoal methods failed, splitting into individual goals")
        end

        split_multigoal_into_goals(updated_execution_state, node_id, updated_node, multigoal)

      [next_method | rest] ->
        try_multigoal_method(updated_execution_state, node_id, updated_node, next_method, multigoal, rest)
    end
  end

  # Split a multigoal into individual goal nodes
  @spec split_multigoal_into_goals(map(), String.t(), map(), AriaEngine.Multigoal.t()) ::
          {:ok, map()} | {:error, String.t()}
  defp split_multigoal_into_goals(execution_state, node_id, node, multigoal) do
    # Get unsatisfied goals
    unsatisfied_goals = AriaEngine.Multigoal.unsatisfied_goals(multigoal, execution_state.current_state)

    if Enum.empty?(unsatisfied_goals) do
      # All goals already satisfied
      {:ok, execution_state}
    else
      # Convert goals to individual goal tasks
      goal_tasks = Enum.map(unsatisfied_goals, fn {subject, predicate, fact_value} ->
        {predicate, subject, fact_value}
      end)

      if execution_state.verbose > 2 do
        Logger.debug("Splitting multigoal into #{length(goal_tasks)} individual goals")
      end

      # Expand node with individual goal tasks
      expand_node_with_subtasks(execution_state, node_id, node, goal_tasks, "split_multigoal")
    end
  end

  # Process an action node
  @spec process_action_node(map(), String.t(), map(), atom(), list()) ::
          {:ok, map()} | {:error, String.t()}
  defp process_action_node(execution_state, node_id, _node, action_name, args) do
    action_tuple = {action_name, args}

    # Check if action is blacklisted
    if MapSet.member?(execution_state.blacklisted_commands, action_tuple) do
      if execution_state.verbose > 2 do
        Logger.debug("Action #{action_name} is blacklisted")
      end

      {:error, "Action is blacklisted: #{inspect(action_tuple)}"}
    else
      # Try to execute the action
      execute_action(execution_state, node_id, action_name, args)
    end
  end

  # Execute a primitive action
  @spec execute_action(map(), String.t(), atom(), list()) :: {:ok, map()} | {:error, String.t()}
  defp execute_action(execution_state, node_id, action_name, args) do
    if execution_state.verbose > 2 do
      Logger.debug("Executing action #{action_name} with args #{inspect(args)}")
    end

    case AriaEngine.Domain.get_action(execution_state.domain, action_name) do
      nil ->
        {:error, "Action not found: #{action_name}"}

      action_fn ->
        case apply_action(action_fn, execution_state.current_state, args) do
          {:ok, new_state} ->
            if execution_state.verbose > 2 do
              Logger.debug("Action #{action_name} succeeded")
            end

            updated_execution_state = %{
              execution_state
              | current_state: new_state
            }

            {:ok, updated_execution_state}

          {:error, reason} ->
            if execution_state.verbose > 2 do
              Logger.debug("Action #{action_name} failed: #{reason}")
            end

            # Blacklist the failed action
            action_tuple = {action_name, args}
            updated_execution_state = %{
              execution_state
              | blacklisted_commands: MapSet.put(execution_state.blacklisted_commands, action_tuple)
            }

            # Use backtracking to find alternative
            case AriaEngine.Plan.Backtracking.replan(
                   execution_state.domain,
                   execution_state.current_state,
                   execution_state.solution_tree,
                   node_id,
                   verbose: execution_state.verbose
                 ) do
              {:ok, new_tree} ->
                updated_execution_state = %{
                  updated_execution_state
                  | solution_tree: new_tree
                }

                execute_from_node(updated_execution_state, new_tree.root_id)

              {:error, replan_reason} ->
                {:error, "Action failed and replanning failed: #{reason} -> #{replan_reason}"}

              :no_alternatives ->
                {:error, "Action failed and no alternatives available: #{reason}"}
            end
        end
    end
  end

  # Apply an action function safely
  @spec apply_action(function(), State.t(), list()) ::
          {:ok, State.t()} | {:error, String.t()}
  defp apply_action(action_fn, state, args) do
    try do
      case apply(action_fn, [state, args]) do
        false ->
          {:error, "Action returned false"}

        nil ->
          {:error, "Action returned nil"}

        %State{} = new_state ->
          {:ok, new_state}

        other ->
          {:error, "Action returned invalid result: #{inspect(other)}"}
      end
    rescue
      e ->
        {:error, "Action execution failed: #{Exception.message(e)}"}
    end
  end

  # Helper functions for solution tree manipulation

  @spec get_node(AriaEngine.Plan.Core.solution_tree(), String.t()) :: map() | nil
  defp get_node(solution_tree, node_id) do
    Map.get(solution_tree.nodes, node_id)
  end

  @spec put_node(AriaEngine.Plan.Core.solution_tree(), String.t(), map()) ::
          AriaEngine.Plan.Core.solution_tree()
  defp put_node(solution_tree, node_id, node) do
    %{solution_tree | nodes: Map.put(solution_tree.nodes, node_id, node)}
  end

  @spec create_child_nodes(AriaEngine.Plan.Core.solution_tree(), String.t(), list()) ::
          {AriaEngine.Plan.Core.solution_tree(), list()}
  defp create_child_nodes(solution_tree, parent_id, subtasks) do
    {updated_tree, child_ids} =
      Enum.reduce(subtasks, {solution_tree, []}, fn subtask, {tree, ids} ->
        child_id = generate_node_id()

        child_node = %{
          id: child_id,
          task: subtask,
          parent_id: parent_id,
          children_ids: [],
          state: nil,
          visited: false,
          expanded: false,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: is_primitive_task(subtask)
        }

        updated_tree = %{tree | nodes: Map.put(tree.nodes, child_id, child_node)}
        {updated_tree, [child_id | ids]}
      end)

    {updated_tree, Enum.reverse(child_ids)}
  end

  @spec generate_node_id() :: String.t()
  defp generate_node_id do
    "node_#{System.unique_integer([:positive])}"
  end

  @spec is_primitive_task(term()) :: boolean()
  defp is_primitive_task({name, _args}) when is_atom(name), do: true
  defp is_primitive_task(_), do: false

  @spec filter_blacklisted_methods(list(), list()) :: list()
  defp filter_blacklisted_methods(methods, blacklisted_methods) do
    Enum.reject(methods, fn {method_name, _method_fn} ->
      method_name in blacklisted_methods
    end)
  end

  @spec save_node_state(map(), String.t()) :: map()
  defp save_node_state(execution_state, node_id) do
    %{
      execution_state
      | node_states: Map.put(execution_state.node_states, node_id, execution_state.current_state)
    }
  end
end
