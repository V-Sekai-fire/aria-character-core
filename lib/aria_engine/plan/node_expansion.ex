# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.NodeExpansion do
  @moduledoc """
  Functions for expanding different types of nodes in the solution tree.
  """

  require Logger

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.StateV2.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}

  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaEngine.StateV2.t() | nil,
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

  # Expand root node with initial todos
  @spec expand_root_node(solution_tree(), node_id(), [todo_item()], AriaEngine.StateV2.t()) ::
          {:ok, solution_tree()}
  def expand_root_node(solution_tree, root_id, todos, state) do
    # Create child nodes for each todo
    # Removed current_state from accumulator
    {new_tree, child_ids} =
      Enum.reduce(todos, {solution_tree, []}, fn todo, {tree, ids} ->
        child_id = AriaEngine.Plan.Utils.generate_node_id()

        child_node = %{
          id: child_id,
          task: todo,
          parent_id: root_id,
          children_ids: [],
          # Use initial state
          state: state,
          visited: false,
          expanded: false,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: AriaEngine.Plan.Utils.is_primitive_task?(todo),
          # Will be set appropriately when marked as primitive
          is_durative: false
        }

        new_tree = put_in(tree.nodes[child_id], child_node)
        # Removed current_state from return
        {new_tree, [child_id | ids]}
      end)

    # Reverse child_ids to maintain original order
    child_ids = Enum.reverse(child_ids)

    # Update root node
    updated_root = %{solution_tree.nodes[root_id] | children_ids: child_ids, expanded: true}

    final_tree = put_in(new_tree.nodes[root_id], updated_root)
    {:ok, final_tree}
  end

  # Expand task node using methods
  @spec expand_task_node(
          Domain.Core.t(),
          AriaEngine.StateV2.t(),
          solution_tree(),
          node_id(),
          String.t(),
          list(),
          integer()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  def expand_task_node(domain, _state, solution_tree, node_id, task_name, args, verbose) do
    node = solution_tree.nodes[node_id]
    methods = Domain.get_task_methods(domain, task_name)

    # Filter out blacklisted methods
    available_methods =
      Enum.reject(methods, fn {method_name, _method_fn} ->
        method_name in node.blacklisted_methods
      end)

    if Enum.empty?(available_methods) do
      if verbose > 2 do
        Logger.debug("No methods available for task: #{task_name}")
      end

      {:error, "No methods found for task: #{task_name}"}
    else
      # Try the first available method
      [{method_name, method_fn} | _] = available_methods
      method_id = method_name

      case method_fn.(node.state, args) do
        false ->
          if verbose > 2 do
            Logger.debug("Method failed preconditions for task: #{task_name}")
            Logger.debug("expand_task_node - method_id: #{inspect(method_id)}")
          end

          # Update the node with the method_tried and mark as not expanded (failed)
          updated_node = %{
            node
            | # It failed, so it's not expanded
              expanded: false,
              method_tried: method_id
          }

          updated_solution_tree = put_in(solution_tree.nodes[node_id], updated_node)
          # Return :failure with the updated tree
          {:failure, updated_solution_tree}

        subtasks when is_list(subtasks) ->
          if verbose > 2 do
            Logger.debug("Method succeeded, created #{length(subtasks)} subtasks")
          end

          # Create child nodes for subtasks and execute primitive actions immediately
          {new_tree, child_ids, _final_state} =
            Enum.reduce(subtasks, {solution_tree, [], node.state}, fn subtask,
                                                                      {tree, ids, current_state} ->
              child_id = AriaEngine.Plan.Utils.generate_node_id()
              is_primitive = AriaEngine.Plan.Utils.is_primitive_task?(subtask)

              # If this is a primitive action, execute it immediately to get the new state
              child_state =
                if is_primitive do
                  {action_name, args} = subtask

                  action_atom =
                    if is_binary(action_name), do: String.to_atom(action_name), else: action_name

                  case Domain.execute_action(domain, current_state, action_atom, args) do
                    {:ok, new_state} ->
                      if verbose > 2 do
                        Logger.debug(
                          "Executed primitive action #{action_name}(#{inspect(args)}) successfully"
                        )
                      end

                      new_state

                    false ->
                      if verbose > 2 do
                        Logger.debug("Primitive action #{action_name}(#{inspect(args)}) failed")
                      end

                      # Keep current state if action failed
                      current_state
                  end
                else
                  # Non-primitive tasks inherit current state
                  current_state
                end

              new_tree =
                put_in(tree.nodes[child_id], %{
                  id: child_id,
                  task: subtask,
                  parent_id: node_id,
                  children_ids: [],
                  state: child_state,
                  visited: false,
                  # Primitive actions are considered expanded
                  expanded: is_primitive,
                  method_tried: nil,
                  blacklisted_methods: [],
                  is_primitive: is_primitive,
                  # Will be set appropriately when marked as primitive
                  is_durative: false
                })

              {new_tree, [child_id | ids], child_state}
            end)

          # Reverse child_ids to maintain original order
          child_ids = Enum.reverse(child_ids)

          # Update parent node
          updated_node = %{
            node
            | children_ids: child_ids,
              expanded: true,
              method_tried: method_id
          }

          final_tree = put_in(new_tree.nodes[node_id], updated_node)
          {:ok, final_tree}

        _ ->
          {:error, "Invalid method result for task: #{task_name}"}
      end
    end
  end

  # Expand goal node
  @spec expand_goal_node(
          Domain.Core.t(),
          AriaEngine.StateV2.t(),
          solution_tree(),
          node_id(),
          String.t(),
          String.t(),
          AriaEngine.StateV2.fact_value(),
          integer()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  def expand_goal_node(
        domain,
        state,
        solution_tree,
        node_id,
        predicate,
        subject,
        fact_value,
        verbose
      ) do
    node = solution_tree.nodes[node_id]

    # Check if goal is already satisfied  
    case AriaEngine.StateV2.get_fact(node.state, subject, predicate) do
      ^fact_value ->
        # Goal already satisfied - mark as expanded with no children
        updated_node = %{node | expanded: true, is_primitive: true}
        final_tree = put_in(solution_tree.nodes[node_id], updated_node)
        {:ok, final_tree}

      _ ->
        # Try goal methods
        methods = Domain.get_unigoal_methods(domain, predicate)

        # Filter out blacklisted methods
        available_methods =
          Enum.reject(methods, fn {method_name, _method_fn} ->
            method_name in node.blacklisted_methods
          end)

        if Enum.empty?(available_methods) do
          if verbose > 2 do
            Logger.debug("No methods available for goal: #{predicate}")
          end

          {:error, "No methods found for goal: #{predicate}"}
        else
          # Try the first method
          [{method_name, method_fn} | _] = available_methods
          method_id = method_name

          case method_fn.(node.state, [subject, fact_value]) do
            false ->
              if verbose > 2 do
                Logger.debug("Method failed preconditions for goal: #{predicate}")
              end

              # Update the node with the method_tried and mark as not expanded (failed)
              updated_node = %{
                node
                | # It failed, so it's not expanded
                  expanded: false,
                  method_tried: method_id
              }

              updated_solution_tree = put_in(solution_tree.nodes[node_id], updated_node)
              # Return :failure with the updated tree
              {:failure, updated_solution_tree}

            subtasks when is_list(subtasks) ->
              if verbose > 2 do
                Logger.debug("Goal method succeeded, created #{length(subtasks)} subtasks")
              end

              # Create child nodes for subtasks and execute primitive actions immediately
              {new_tree, child_ids, _final_state, any_action_failed} =
                Enum.reduce(subtasks, {solution_tree, [], node.state, false}, fn subtask,
                                                                                 {tree, ids,
                                                                                  current_state,
                                                                                  failed_so_far} ->
                  child_id = AriaEngine.Plan.Utils.generate_node_id()
                  is_primitive = AriaEngine.Plan.Utils.is_primitive_task?(subtask)

                  # Check if this is a durative action
                  is_durative =
                    if is_primitive do
                      {action_name, _args} = subtask

                      action_atom =
                        if is_binary(action_name),
                          do: String.to_atom(action_name),
                          else: action_name

                      Domain.Core.get_durative_action(domain, action_atom) != nil
                    else
                      false
                    end

                  # If this is a primitive action, execute it immediately to check preconditions
                  {child_state, action_succeeded} =
                    if is_primitive do
                      {action_name, args} = subtask

                      action_atom =
                        if is_binary(action_name),
                          do: String.to_atom(action_name),
                          else: action_name

                      case Domain.execute_action(domain, current_state, action_atom, args) do
                        {:ok, new_state} ->
                          if verbose > 2 do
                            Logger.debug(
                              "Executed primitive action #{action_name}(#{inspect(args)}) successfully"
                            )
                          end

                          {new_state, true}

                        false ->
                          if verbose > 2 do
                            Logger.debug(
                              "Primitive action #{action_name}(#{inspect(args)}) failed"
                            )
                          end

                          # Keep current state if action failed
                          {current_state, false}
                      end
                    else
                      # Non-primitive tasks inherit current state
                      {current_state, true}
                    end

                  child_node = %{
                    id: child_id,
                    task: subtask,
                    parent_id: node_id,
                    children_ids: [],
                    state: child_state,
                    visited: false,
                    # Only expanded if action succeeded
                    expanded: is_primitive and action_succeeded,
                    method_tried: nil,
                    blacklisted_methods: [],
                    is_primitive: is_primitive,
                    is_durative: is_durative
                  }

                  new_tree = put_in(tree.nodes[child_id], child_node)

                  {new_tree, [child_id | ids], child_state,
                   failed_so_far or (is_primitive and not action_succeeded)}
                end)

              # Reverse child_ids to maintain original order
              child_ids = Enum.reverse(child_ids)

              # Update parent node
              updated_node = %{
                node
                | children_ids: child_ids,
                  expanded: true,
                  method_tried: method_id
              }

              final_tree = put_in(new_tree.nodes[node_id], updated_node)

              # If any primitive action failed, return failure to trigger backtracking
              if any_action_failed do
                {:failure, final_tree}
              else
                {:ok, final_tree}
              end

            {:multigoal, goals} ->
              if verbose > 2 do
                Logger.debug("Goal method returned multigoal with #{length(goals)} goals")
              end

              # Create a multigoal struct and use multigoal expansion
              # Corrected variable name
              multigoal_struct = Multigoal.new(goals)
              # Use corrected variable name
              expand_multigoal_node(
                domain,
                state,
                solution_tree,
                node_id,
                multigoal_struct,
                verbose
              )

            _ ->
              {:error, "Invalid goal method result for: #{predicate}"}
          end
        end
    end
  end

  # Expand multigoal node
  @spec expand_multigoal_node(
          Domain.Core.t(),
          AriaEngine.StateV2.t(),
          solution_tree(),
          node_id(),
          Multigoal.t(),
          integer()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()} | :failure
  def expand_multigoal_node(_domain, _state, solution_tree, node_id, multigoal, verbose) do
    node = solution_tree.nodes[node_id]

    # Check if multigoal is already satisfied
    if Multigoal.satisfied?(multigoal, node.state) do
      # Already satisfied - mark as expanded with no children
      updated_node = %{node | expanded: true, is_primitive: true}
      final_tree = put_in(solution_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    else
      # Get unsatisfied goals and create subtasks
      unsatisfied = Multigoal.unsatisfied_goals(multigoal, node.state)

      if verbose > 2 do
        Logger.debug("Multigoal has #{length(unsatisfied)} unsatisfied goals")
      end

      # Create child nodes for unsatisfied goals
      {new_tree, child_ids} =
        Enum.reduce(unsatisfied, {solution_tree, []}, fn goal, {tree, ids} ->
          child_id = AriaEngine.Plan.Utils.generate_node_id()
          is_primitive = AriaEngine.Plan.Utils.is_primitive_task?(goal)

          child_node = %{
            id: child_id,
            task: goal,
            parent_id: node_id,
            children_ids: [],
            state: node.state,
            visited: false,
            # Primitive actions are considered expanded
            expanded: is_primitive,
            method_tried: nil,
            blacklisted_methods: [],
            is_primitive: is_primitive,
            # Will be set appropriately when marked as primitive
            is_durative: false
          }

          new_tree = put_in(tree.nodes[child_id], child_node)
          {new_tree, [child_id | ids]}
        end)

      # Reverse child_ids to maintain original order
      child_ids = Enum.reverse(child_ids)

      # Update parent node
      updated_node = %{node | children_ids: child_ids, expanded: true}

      final_tree = put_in(new_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    end
  end

  # Mark a node as primitive (action)
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
