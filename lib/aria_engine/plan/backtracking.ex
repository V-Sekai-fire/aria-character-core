defmodule Plan.Backtracking do
  @moduledoc "Functions for handling backtracking and replanning in the solution tree.\n"
  require Logger
  alias Plan.Core
  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: term(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaEngine.State.t() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean()
        }
  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure
  @doc "Replan from a specific failure node in the solution tree.\n"
  @spec replan(Domain.Core.t(), AriaEngine.State.t(), solution_tree(), node_id(), keyword()) ::
          replan_result()
  def replan(
        %Domain.Core{} = domain,
        %AriaEngine.State{} = state,
        solution_tree,
        fail_node_id,
        opts \\ []
      ) do
    replan_depth = Keyword.get(opts, :replan_depth, Core.get_default_replan_depth())

    if replan_depth <= 0 do
      Logger.debug("REPLAN: Maximum replanning depth exceeded.")
      {:error, "Maximum replanning depth exceeded"}
    else
      opts = Keyword.put(opts, :replan_depth, replan_depth - 1)
      verbose = Keyword.get(opts, :verbose, Core.get_default_verbose())

      if verbose > 2 do
        Logger.debug("Replanning from failure node: #{fail_node_id}")
      end

      case find_responsible_task_node(solution_tree, fail_node_id, verbose) do
        nil ->
          {:error, "Could not find responsible task node for failed action"}

        task_node_id ->
          if verbose > 2 do
            Logger.debug("Found responsible task node: #{task_node_id}")
          end

          updated_tree = AriaEngine.Plan.Utils.update_cached_states(solution_tree, state)

          case try_alternative_method_for_task(domain, updated_tree, task_node_id, verbose) do
            {:ok, new_tree} -> Core.ipyhop(domain, state, new_tree, opts)
            {:error, reason} -> {:error, reason}
            :no_alternatives -> :no_alternatives
          end
      end
    end
  end

  @spec find_responsible_task_node(solution_tree(), node_id(), integer()) :: node_id() | nil
  def find_responsible_task_node(solution_tree, fail_node_id, verbose) do
    case solution_tree.nodes[fail_node_id] do
      nil -> nil
      node -> find_parent_task_node(solution_tree, node.parent_id, verbose)
    end
  end

  @spec find_parent_task_node(solution_tree(), node_id() | nil, integer()) :: node_id() | nil
  def find_parent_task_node(_solution_tree, nil, _verbose) do
    nil
  end

  def find_parent_task_node(solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        nil

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            if verbose > 2 do
              Logger.debug("Found task node: #{node_id} with task: #{task_name}")
            end

            node_id

          {:root, _} ->
            find_parent_task_node(solution_tree, node.parent_id, verbose)

          _ ->
            find_parent_task_node(solution_tree, node.parent_id, verbose)
        end
    end
  end

  @spec try_alternative_method_for_task(Domain.Core.t(), solution_tree(), node_id(), integer()) ::
          {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  def try_alternative_method_for_task(domain, solution_tree, task_node_id, verbose) do
    case solution_tree.nodes[task_node_id] do
      nil ->
        {:error, "Task node not found: #{task_node_id}"}

      node ->
        log_method_attempt(node, verbose)
        handle_alternative_method(domain, solution_tree, task_node_id, node, verbose)
    end
  end

  defp log_method_attempt(_node, verbose) do
    if verbose > 2 do
      Logger.debug("Attempting alternative method for task")
    end
  end

  defp handle_alternative_method(domain, solution_tree, task_node_id, node, verbose) do
    case node.task do
      {task_name, _args} when is_binary(task_name) ->
        try_alternative_for_task(domain, solution_tree, task_node_id, node, task_name, verbose)

      {predicate, _subject, _fact_value} ->
        try_alternative_for_goal(domain, solution_tree, task_node_id, node, predicate, verbose)

      _ ->
        {:error, "Node is not a task or goal node: #{inspect(node.task)}"}
    end
  end

  defp try_alternative_for_task(domain, solution_tree, task_node_id, node, task_name, verbose) do
    blacklisted_methods = update_blacklisted_methods(node)
    all_methods = Domain.get_task_methods(domain, task_name)

    case check_remaining_methods(all_methods, blacklisted_methods, task_name, verbose) do
      :no_alternatives ->
        :no_alternatives

      :has_alternatives ->
        reset_node_for_retry(
          solution_tree,
          task_node_id,
          node,
          blacklisted_methods,
          task_name,
          verbose
        )
    end
  end

  defp try_alternative_for_goal(domain, solution_tree, task_node_id, node, predicate, verbose) do
    blacklisted_methods = update_blacklisted_methods(node)
    all_methods = Domain.get_unigoal_methods(domain, predicate)

    case check_remaining_methods(all_methods, blacklisted_methods, predicate, verbose) do
      :no_alternatives ->
        :no_alternatives

      :has_alternatives ->
        reset_node_for_retry(
          solution_tree,
          task_node_id,
          node,
          blacklisted_methods,
          predicate,
          verbose
        )
    end
  end

  defp update_blacklisted_methods(node) do
    if node.method_tried do
      [node.method_tried | node.blacklisted_methods]
    else
      node.blacklisted_methods
    end
  end

  defp check_remaining_methods(all_methods, blacklisted_methods, identifier, verbose) do
    remaining_methods =
      Enum.reject(all_methods, fn {method_name, _method_fn} ->
        method_name in blacklisted_methods
      end)

    if Enum.empty?(remaining_methods) do
      if verbose > 2 do
        Logger.debug("No alternative methods left for #{identifier}")
      end

      :no_alternatives
    else
      :has_alternatives
    end
  end

  defp reset_node_for_retry(
         solution_tree,
         task_node_id,
         node,
         blacklisted_methods,
         identifier,
         verbose
       ) do
    if verbose > 2 do
      Logger.debug("Blacklisting method for #{identifier}: #{inspect(node.method_tried)}")
      Logger.debug("Total blacklisted methods: #{inspect(blacklisted_methods)}")
    end

    reset_node = %{
      node
      | children_ids: [],
        expanded: false,
        method_tried: nil,
        blacklisted_methods: blacklisted_methods
    }

    descendant_ids = AriaEngine.Plan.Utils.get_all_descendants(solution_tree, task_node_id)
    remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)
    updated_tree = %{solution_tree | nodes: Map.put(remaining_nodes, task_node_id, reset_node)}
    {:ok, updated_tree}
  end

  @spec backtrack_and_retry(
          Domain.Core.t(),
          AriaEngine.State.t(),
          solution_tree(),
          node_id(),
          integer(),
          integer(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()}
  def backtrack_and_retry(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose) do
    if verbose > 2 do
      Logger.debug("Backtracking from failed node: #{failed_node_id}")
    end

    case solution_tree.nodes[failed_node_id] do
      nil ->
        {:error, "Failed node not found: #{failed_node_id}"}

      failed_node ->
        handle_failed_node(
          domain,
          state,
          solution_tree,
          failed_node_id,
          failed_node,
          depth,
          max_depth,
          verbose
        )
    end
  end

  defp handle_failed_node(
         domain,
         state,
         solution_tree,
         failed_node_id,
         failed_node,
         depth,
         max_depth,
         verbose
       ) do
    case failed_node.parent_id do
      nil ->
        {:error, "Root node failed - no complete solution found"}

      _parent_id ->
        try_alternatives_or_backtrack(
          domain,
          state,
          solution_tree,
          failed_node_id,
          depth,
          max_depth,
          verbose
        )
    end
  end

  defp try_alternatives_or_backtrack(
         domain,
         state,
         solution_tree,
         failed_node_id,
         depth,
         max_depth,
         verbose
       ) do
    task = solution_tree.nodes[failed_node_id].task

    case task do
      {task_name, _args} when is_binary(task_name) ->
        handle_task_node_backtrack(
          domain,
          state,
          solution_tree,
          failed_node_id,
          depth,
          max_depth,
          verbose
        )

      {_predicate, _subject, _fact_value} ->
        handle_goal_node_backtrack(
          domain,
          state,
          solution_tree,
          failed_node_id,
          depth,
          max_depth,
          verbose
        )

      _ ->
        backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)
    end
  end

  defp handle_task_node_backtrack(
         domain,
         state,
         solution_tree,
         failed_node_id,
         depth,
         max_depth,
         verbose
       ) do
    case try_alternative_method_for_task(domain, solution_tree, failed_node_id, verbose) do
      {:ok, new_tree} ->
        {:ok, new_tree}

      :no_alternatives ->
        backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_goal_node_backtrack(
         domain,
         state,
         solution_tree,
         failed_node_id,
         depth,
         max_depth,
         verbose
       ) do
    case try_alternative_method_for_task(domain, solution_tree, failed_node_id, verbose) do
      {:ok, new_tree} ->
        {:ok, new_tree}

      :no_alternatives ->
        backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec backtrack_up_tree(
          Domain.Core.t(),
          AriaEngine.State.t(),
          solution_tree(),
          node_id(),
          integer(),
          integer(),
          integer()
        ) :: {:ok, solution_tree()} | {:error, String.t()}
  def backtrack_up_tree(domain, state, solution_tree, current_node_id, depth, max_depth, verbose) do
    case solution_tree.nodes[current_node_id].parent_id do
      nil ->
        {:error, "No alternative methods available - no complete solution found"}

      parent_id ->
        backtrack_and_retry(domain, state, solution_tree, parent_id, depth, max_depth, verbose)
    end
  end
end