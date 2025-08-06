# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Plan.NodeExpansion do
  @moduledoc "Functions for expanding different types of nodes in the solution tree.\n"
  require Logger
  @type task :: {atom(), list()}
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
          Multigoal.t()
        ) :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  def expand_multigoal_node(domain, state, solution_tree, node_id, multigoal) do
    node = solution_tree.nodes[node_id]
    # Use the node's current state instead of the global state
    current_state = node.state || state

    if AriaEngineCore.Multigoal.satisfied?(multigoal, current_state) do
      updated_node = %{node | expanded: true, is_primitive: true}
      final_tree = put_in(solution_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    else
      # Try to use domain's multigoal methods first
      multigoal_methods = AriaCore.get_multigoal_methods_from_domain(domain)

      case try_multigoal_methods(multigoal_methods, current_state, multigoal) do
        {:ok, []} ->
          # Method returned empty list - multigoal already completed
          Logger.debug("Multigoal method returned empty list, marking as completed")
          mark_as_completed(solution_tree, node_id)

        {:ok, todo_list} ->
          # Create child nodes for the todo list returned by the multigoal method
          {new_tree, child_ids} =
            Enum.reduce(todo_list, {solution_tree, []}, fn todo_item, {tree, ids} ->
              child_id = Plan.Utils.generate_node_id()

              child_node = %{
                id: child_id,
                task: todo_item,
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
              {new_tree, ids ++ [child_id]}  # Append to maintain order
            end)

          # Multigoal methods return goals in correct dependency order
          updated_node = %{node | children_ids: child_ids, expanded: true, method_tried: :multigoal_method}
          final_tree = put_in(new_tree.nodes[node_id], updated_node)
          {:ok, final_tree}

        :no_methods ->
          # Fallback to simple unsatisfied goal expansion
          unsatisfied = AriaEngineCore.Multigoal.unsatisfied_goals(multigoal, node.state)

          Logger.debug("Multigoal has #{length(unsatisfied)} unsatisfied goals (no domain methods)")

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

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Helper function to try multigoal methods
  defp try_multigoal_methods([], _state, _multigoal), do: :no_methods
  defp try_multigoal_methods([{_method_name, method_fn} | rest], state, multigoal) do
    try do
      case method_fn.(state, multigoal) do
        {:ok, []} ->
          # Method returned empty list - multigoal already satisfied
          Logger.debug("Multigoal method succeeded, returned empty list - multigoal completed")
          {:ok, []}
        {:ok, todo_list} when is_list(todo_list) ->
          Logger.debug("Multigoal method succeeded, returned #{length(todo_list)} todo items")
          {:ok, todo_list}
        {:error, reason} ->
          Logger.debug("Multigoal method failed: #{inspect(reason)}")
          try_multigoal_methods(rest, state, multigoal)
        _other ->
          Logger.debug("Multigoal method returned unexpected result")
          try_multigoal_methods(rest, state, multigoal)
      end
    rescue
      error ->
        Logger.debug("Multigoal method raised error: #{inspect(error)}")
        try_multigoal_methods(rest, state, multigoal)
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

  @spec mark_as_completed(solution_tree(), node_id(), keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  def mark_as_completed(solution_tree, node_id, opts \\ []) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        is_durative = Keyword.get(opts, :is_durative, false)
        updated_node = %{node | is_primitive: false, expanded: true, is_durative: is_durative}
        final_tree = put_in(solution_tree.nodes[node_id], updated_node)
        {:ok, final_tree}
    end
  end
end
