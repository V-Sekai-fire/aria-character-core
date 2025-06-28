# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.NodeExpansion do
  @moduledoc "Functions for expanding different types of nodes in the solution tree.\n"
  require Logger
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
  @spec expand_root_node(solution_tree(), node_id(), [todo_item()], State.t()) ::
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
          is_primitive: Plan.Utils.is_primitive_task?(todo),
          is_durative: false
        }

        new_tree = put_in(tree.nodes[child_id], child_node)
        {new_tree, [child_id | ids]}
      end)

    child_ids = Enum.reverse(child_ids)
    updated_root = %{solution_tree.nodes[root_id] | children_ids: child_ids, expanded: true}
    final_tree = put_in(new_tree.nodes[root_id], updated_root)
    {:ok, final_tree}
  end

  @spec expand_task_node(
          Domain.Core.t(),
          State.t(),
          solution_tree(),
          node_id(),
          String.t(),
          list(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  def expand_task_node(domain, _state, solution_tree, node_id, task_name, args, verbose) do
    node = solution_tree.nodes[node_id]
    methods = Domain.Core.get_task_methods(domain, task_name)

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
      [{method_name, method_fn} | _] = available_methods
      method_id = method_name

      case method_fn.(node.state, args) do
        false ->
          if verbose > 2 do
            Logger.debug("Method failed preconditions for task: #{task_name}")
            Logger.debug("expand_task_node - method_id: #{inspect(method_id)}")
          end

          updated_node = %{node | expanded: false, method_tried: method_id}
          updated_solution_tree = put_in(solution_tree.nodes[node_id], updated_node)
          {:failure, updated_solution_tree}

        subtasks when is_list(subtasks) ->
          if verbose > 2 do
            Logger.debug("Method succeeded, created #{length(subtasks)} subtasks")
          end

          {new_tree, child_ids, _final_state} =
            Enum.reduce(subtasks, {solution_tree, [], node.state}, fn subtask, acc ->
              create_task_child_node(domain, node_id, subtask, acc, verbose)
            end)

          child_ids = Enum.reverse(child_ids)

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

  @spec expand_goal_node(
          Domain.Core.t(),
          State.t(),
          solution_tree(),
          node_id(),
          String.t(),
          String.t(),
          State.fact_value(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
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

    case State.get_fact(node.state, subject, predicate) do
      ^fact_value ->
        mark_goal_satisfied(solution_tree, node_id)

      _ ->
        try_goal_methods(
          domain,
          state,
          solution_tree,
          node_id,
          predicate,
          subject,
          fact_value,
          verbose
        )
    end
  end

  @spec expand_multigoal_node(
          Domain.Core.t(),
          State.t(),
          solution_tree(),
          node_id(),
          Multigoal.t(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  def expand_multigoal_node(_domain, _state, solution_tree, node_id, multigoal, verbose) do
    node = solution_tree.nodes[node_id]

    if Multigoal.satisfied?(multigoal, node.state) do
      updated_node = %{node | expanded: true, is_primitive: true}
      final_tree = put_in(solution_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    else
      unsatisfied = Multigoal.unsatisfied_goals(multigoal, node.state)

      if verbose > 2 do
        Logger.debug("Multigoal has #{length(unsatisfied)} unsatisfied goals")
      end

      {new_tree, child_ids} =
        Enum.reduce(unsatisfied, {solution_tree, []}, fn goal, {tree, ids} ->
          child_id = Plan.Utils.generate_node_id()
          is_primitive = Plan.Utils.is_primitive_task?(goal)

          child_node = %{
            id: child_id,
            task: goal,
            parent_id: node_id,
            children_ids: [],
            state: node.state,
            visited: false,
            expanded: is_primitive,
            method_tried: nil,
            blacklisted_methods: [],
            is_primitive: is_primitive,
            is_durative: false
          }

          new_tree = put_in(tree.nodes[child_id], child_node)
          {new_tree, [child_id | ids]}
        end)

      child_ids = Enum.reverse(child_ids)
      updated_node = %{node | children_ids: child_ids, expanded: true}
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

  defp mark_goal_satisfied(solution_tree, node_id) do
    node = solution_tree.nodes[node_id]
    updated_node = %{node | expanded: true, is_primitive: true}
    final_tree = put_in(solution_tree.nodes[node_id], updated_node)
    {:ok, final_tree}
  end

  defp try_goal_methods(
         domain,
         _state,
         solution_tree,
         node_id,
         predicate,
         subject,
         fact_value,
         verbose
       ) do
    node = solution_tree.nodes[node_id]
    methods = Domain.Core.get_unigoal_methods(domain, predicate)

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
      [{method_name, method_fn} | _] = available_methods
      method_id = method_name

      case method_fn.(node.state, [subject, fact_value]) do
        false ->
          handle_goal_method_failure(solution_tree, node_id, method_id, predicate, verbose)

        subtasks when is_list(subtasks) ->
          handle_goal_method_success(domain, solution_tree, node_id, method_id, subtasks, verbose)

        {:multigoal, goals} ->
          handle_multigoal_result(domain, solution_tree, node_id, goals, verbose)

        _ ->
          {:error, "Invalid goal method result for: #{predicate}"}
      end
    end
  end

  defp handle_goal_method_failure(solution_tree, node_id, method_id, predicate, verbose) do
    if verbose > 2 do
      Logger.debug("Method failed preconditions for goal: #{predicate}")
    end

    node = solution_tree.nodes[node_id]
    updated_node = %{node | expanded: false, method_tried: method_id}
    updated_solution_tree = put_in(solution_tree.nodes[node_id], updated_node)
    {:failure, updated_solution_tree}
  end

  defp handle_goal_method_success(domain, solution_tree, node_id, method_id, subtasks, verbose) do
    if verbose > 2 do
      Logger.debug("Goal method succeeded, created #{length(subtasks)} subtasks")
    end

    node = solution_tree.nodes[node_id]

    {new_tree, child_ids, _final_state, any_action_failed} =
      Enum.reduce(subtasks, {solution_tree, [], node.state, false}, fn subtask, acc ->
        create_goal_child_node(domain, node_id, subtask, acc, verbose)
      end)

    child_ids = Enum.reverse(child_ids)
    updated_node = %{node | children_ids: child_ids, expanded: true, method_tried: method_id}
    final_tree = put_in(new_tree.nodes[node_id], updated_node)

    if any_action_failed do
      {:failure, final_tree}
    else
      {:ok, final_tree}
    end
  end

  defp handle_multigoal_result(domain, solution_tree, node_id, goals, verbose) do
    if verbose > 2 do
      Logger.debug("Goal method returned multigoal with #{length(goals)} goals")
    end

    multigoal_struct = Multigoal.new(goals)
    expand_multigoal_node(domain, nil, solution_tree, node_id, multigoal_struct, verbose)
  end

  defp create_task_child_node(domain, parent_id, subtask, {tree, ids, current_state}, verbose) do
    child_id = Plan.Utils.generate_node_id()
    is_primitive = Plan.Utils.is_primitive_task?(subtask)

    child_state =
      if is_primitive do
        execute_primitive_action(domain, subtask, current_state, verbose)
      else
        current_state
      end

    new_tree =
      put_in(tree.nodes[child_id], %{
        id: child_id,
        task: subtask,
        parent_id: parent_id,
        children_ids: [],
        state: child_state,
        visited: false,
        expanded: is_primitive,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: is_primitive,
        is_durative: false
      })

    {new_tree, [child_id | ids], child_state}
  end

  defp create_goal_child_node(
         domain,
         parent_id,
         subtask,
         {tree, ids, current_state, failed_so_far},
         verbose
       ) do
    child_id = Plan.Utils.generate_node_id()
    is_primitive = Plan.Utils.is_primitive_task?(subtask)

    is_durative =
      if is_primitive do
        {action_name, _args} = subtask

        action_atom =
          if is_binary(action_name) do
            String.to_atom(action_name)
          else
            action_name
          end

        Domain.Core.get_durative_action(domain, action_atom) != nil
      else
        false
      end

    {child_state, action_succeeded} =
      if is_primitive do
        execute_primitive_action_with_result(domain, subtask, current_state, verbose)
      else
        {current_state, true}
      end

    child_node = %{
      id: child_id,
      task: subtask,
      parent_id: parent_id,
      children_ids: [],
      state: child_state,
      visited: false,
      expanded: is_primitive and action_succeeded,
      method_tried: nil,
      blacklisted_methods: [],
      is_primitive: is_primitive,
      is_durative: is_durative
    }

    new_tree = put_in(tree.nodes[child_id], child_node)

    {new_tree, [child_id | ids], child_state,
     failed_so_far or (is_primitive and not action_succeeded)}
  end

  defp execute_primitive_action(domain, {action_name, args}, current_state, verbose) do
    action_atom =
      if is_binary(action_name) do
        String.to_atom(action_name)
      else
        action_name
      end

    case Domain.Core.execute_action(domain, current_state, action_atom, args) do
      {:ok, new_state} ->
        if verbose > 2 do
          Logger.debug("Executed primitive action #{action_name}(#{inspect(args)}) successfully")
        end

        new_state

      false ->
        if verbose > 2 do
          Logger.debug("Primitive action #{action_name}(#{inspect(args)}) failed")
        end

        current_state
    end
  end

  defp execute_primitive_action_with_result(domain, {action_name, args}, current_state, verbose) do
    action_atom =
      if is_binary(action_name) do
        String.to_atom(action_name)
      else
        action_name
      end

    case Domain.Core.execute_action(domain, current_state, action_atom, args) do
      {:ok, new_state} ->
        if verbose > 2 do
          Logger.debug("Executed primitive action #{action_name}(#{inspect(args)}) successfully")
        end

        {new_state, true}

      false ->
        if verbose > 2 do
          Logger.debug("Primitive action #{action_name}(#{inspect(args)}) failed")
        end

        {current_state, false}
    end
  end
end
