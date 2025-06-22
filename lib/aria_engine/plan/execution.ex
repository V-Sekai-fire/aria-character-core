# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Execution do
  @moduledoc """
  IPyHOP-faithful lazy execution implementation.

  This module implements true lazy refinement execution where the solution tree
  is traversed and expanded just-in-time during execution, matching the original
  IPyHOP algorithm semantics.
  """

  require Logger
  alias AriaEngine.Plan.Blacklisting

  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: term(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaEngine.StateV2.t() | nil,
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

  @type plan_step :: {atom(), list()}

  @type execution_context :: %{
          current_state: AriaEngine.StateV2.t(),
          solution_tree: solution_tree(),
          execution_stack: [node_id()],
          verbose: non_neg_integer()
        }

  @default_verbose 0

  # Helper to conditionally output debug information
  defp debug_puts(message, verbose) when verbose > 1 do
    if Application.get_env(:ex_unit, :trace, false) or not test_mode?() do
      Logger.debug(message)
    end
  end
  defp debug_puts(_message, _verbose), do: :ok

  defp test_mode?() do
    Mix.env() == :test
  end

  @doc """
  Execute a solution tree using IPyHOP-faithful lazy refinement.

  This function implements true lazy execution where task nodes are expanded
  just-in-time during execution, and primitive actions are executed immediately
  when encountered. Follows the original IPyHOP algorithm semantics.
  """
  @spec run_lazy_refineahead(AriaEngine.Domain.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, %AriaEngine.StateV2{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    debug_puts("Starting IPyHOP lazy refinement execution", verbose)

    # Initialize execution context
    context = %{
      current_state: initial_state,
      solution_tree: solution_tree,
      execution_stack: [solution_tree.root_id],
      verbose: verbose
    }

    try do
      # Start lazy execution from root
      execute_lazy_step(domain, context, opts)
    rescue
      e ->
        error_msg = "Lazy refinement execution error: #{Exception.message(e)}"
        debug_puts(error_msg, verbose)
        {:error, error_msg}
    end
  end

  # Main execution loop - processes nodes from the execution stack
  @spec execute_lazy_step(AriaEngine.Domain.t(), execution_context(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_lazy_step(domain, context, opts) do
    case context.execution_stack do
      [] ->
        # Execution stack is empty - all tasks completed successfully
        debug_puts("Lazy execution completed successfully", context.verbose)
        {:ok, context.current_state}

      [current_node_id | remaining_stack] ->
        # Process the current node
        current_node = context.solution_tree.nodes[current_node_id]

        debug_puts("Processing node #{current_node_id}: #{inspect(current_node.task)}", context.verbose)

        cond do
          current_node.is_primitive ->
            # Execute primitive action
            execute_primitive_action(domain, context, current_node_id, remaining_stack, opts)

          current_node.expanded ->
            # Task node is already expanded - add children to execution stack
            add_children_to_stack(domain, context, current_node_id, remaining_stack, opts)

          true ->
            # Task node needs expansion - expand it just-in-time
            expand_task_node(domain, context, current_node_id, remaining_stack, opts)
        end
    end
  end

  # Execute a primitive action
  @spec execute_primitive_action(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_primitive_action(domain, context, node_id, remaining_stack, opts) do
    node = context.solution_tree.nodes[node_id]
    action = node.task

    debug_puts("Executing primitive action: #{inspect(action)}", context.verbose)

    # Check if action is blacklisted
    if MapSet.member?(context.solution_tree.blacklisted_commands, action) do
      debug_puts("Action #{inspect(action)} is blacklisted, treating as failure", context.verbose)
      handle_action_failure(domain, context, node_id, remaining_stack, "Action is blacklisted", opts)
    else
      # Execute the action
      case apply_action_to_state(domain, context.current_state, action, opts) do
        {:ok, new_state} ->
          # Action succeeded - continue with remaining stack
          updated_context = %{context |
            current_state: new_state,
            execution_stack: remaining_stack
          }
          execute_lazy_step(domain, updated_context, opts)

        {:error, reason} ->
          # Action failed - handle failure
          handle_action_failure(domain, context, node_id, remaining_stack, reason, opts)
      end
    end
  end

  # Add children of an expanded task node to the execution stack
  @spec add_children_to_stack(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp add_children_to_stack(domain, context, node_id, remaining_stack, opts) do
    node = context.solution_tree.nodes[node_id]

    debug_puts("Adding children of expanded node #{node_id} to stack", context.verbose)

    # Add children to front of execution stack (depth-first execution)
    new_stack = node.children_ids ++ remaining_stack

    updated_context = %{context | execution_stack: new_stack}
    execute_lazy_step(domain, updated_context, opts)
  end

  # Expand a task node just-in-time
  @spec expand_task_node(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp expand_task_node(domain, context, node_id, remaining_stack, opts) do
    node = context.solution_tree.nodes[node_id]
    {task_name, task_args} = node.task

    debug_puts("Expanding task node #{node_id}: #{task_name}(#{inspect(task_args)})", context.verbose)

    # Get available methods for this task, excluding blacklisted ones
    available_methods = get_available_methods(domain, task_name, node.blacklisted_methods)

    case available_methods do
      [] ->
        # No methods available - task expansion failed
        debug_puts("No available methods for task #{task_name}", context.verbose)
        handle_task_failure(domain, context, node_id, remaining_stack, "No available methods", opts)

      [method_name | _] ->
        # Try the first available method
        debug_puts("Trying method #{method_name} for task #{task_name}", context.verbose)
        attempt_method_expansion(domain, context, node_id, remaining_stack, method_name, opts)
    end
  end

  # Get available methods for a task, excluding blacklisted ones
  @spec get_available_methods(AriaEngine.Domain.t(), String.t(), [String.t()]) :: [String.t()]
  defp get_available_methods(domain, task_name, blacklisted_methods) do
    case AriaEngine.Domain.get_task_methods(domain, task_name) do
      [] -> []
      methods ->
        methods
        |> Enum.map(fn {method_name, _method_func} -> method_name end)
        |> Enum.reject(&(&1 in blacklisted_methods))
    end
  end

  # Attempt to expand a task using a specific method
  @spec attempt_method_expansion(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp attempt_method_expansion(domain, context, node_id, remaining_stack, method_name, opts) do
    node = context.solution_tree.nodes[node_id]
    {_task_name, task_args} = node.task

    # Get the method function
    case AriaEngine.Domain.get_method(domain, method_name) do
      nil ->
        # Method not found - blacklist it and try next
        debug_puts("Method #{method_name} not found", context.verbose)
        blacklist_method_and_retry(domain, context, node_id, remaining_stack, method_name, opts)

      method_func ->
        # Apply the method to get subtasks
        case apply_method(method_func, context.current_state, task_args, opts) do
          {:ok, subtasks} ->
            # Method succeeded - create child nodes and continue
            expand_with_subtasks(domain, context, node_id, remaining_stack, method_name, subtasks, opts)

          {:error, reason} ->
            # Method failed - blacklist it and try next
            debug_puts("Method #{method_name} failed: #{reason}", context.verbose)
            blacklist_method_and_retry(domain, context, node_id, remaining_stack, method_name, opts)
        end
    end
  end

  # Apply a method function to get subtasks
  @spec apply_method(function(), AriaEngine.StateV2.t(), list(), keyword()) ::
          {:ok, [term()]} | {:error, String.t()}
  defp apply_method(method_func, state, args, _opts) do
    try do
      case method_func.(state, args) do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        false ->
          {:error, "Method returned false"}
        {:error, reason} ->
          {:error, reason}
        other ->
          {:error, "Method returned unexpected result: #{inspect(other)}"}
      end
    rescue
      e ->
        {:error, "Method execution error: #{Exception.message(e)}"}
    end
  end

  # Expand a task node with the given subtasks
  @spec expand_with_subtasks(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], String.t(), [term()], keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp expand_with_subtasks(domain, context, node_id, remaining_stack, method_name, subtasks, opts) do
    debug_puts("Expanding node #{node_id} with #{length(subtasks)} subtasks using method #{method_name}", context.verbose)

    # Create child nodes for each subtask
    {updated_tree, child_ids} = create_child_nodes(context.solution_tree, node_id, subtasks)

    # Mark the parent node as expanded
    updated_node = %{context.solution_tree.nodes[node_id] |
      expanded: true,
      method_tried: method_name,
      children_ids: child_ids
    }

    updated_tree = %{updated_tree | nodes: Map.put(updated_tree.nodes, node_id, updated_node)}

    # Add children to execution stack
    new_stack = child_ids ++ remaining_stack

    updated_context = %{context |
      solution_tree: updated_tree,
      execution_stack: new_stack
    }

    execute_lazy_step(domain, updated_context, opts)
  end

  # Create child nodes for subtasks
  @spec create_child_nodes(solution_tree(), node_id(), [term()]) :: {solution_tree(), [node_id()]}
  defp create_child_nodes(solution_tree, parent_id, subtasks) do
    {updated_nodes, child_ids} =
      Enum.reduce(subtasks, {solution_tree.nodes, []}, fn subtask, {nodes_acc, ids_acc} ->
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
          is_primitive: is_primitive_task?(subtask)
        }

        {Map.put(nodes_acc, child_id, child_node), [child_id | ids_acc]}
      end)

    # Reverse child_ids to maintain order
    child_ids = Enum.reverse(child_ids)

    updated_tree = %{solution_tree | nodes: updated_nodes}
    {updated_tree, child_ids}
  end

  # Check if a task is primitive (action vs compound task)
  @spec is_primitive_task?(term()) :: boolean()
  defp is_primitive_task?({task_name, _args}) when is_atom(task_name), do: true
  defp is_primitive_task?({task_name, _args}) when is_binary(task_name) do
    # Heuristic: if task name starts with lowercase, it's likely primitive
    case String.first(task_name) do
      nil -> false
      first_char -> first_char == String.downcase(first_char)
    end
  end
  defp is_primitive_task?(_), do: false

  # Generate a unique node ID
  @spec generate_node_id() :: node_id()
  defp generate_node_id() do
    "node_#{:erlang.unique_integer([:positive])}"
  end

  # Blacklist a method and retry with next available method
  @spec blacklist_method_and_retry(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp blacklist_method_and_retry(domain, context, node_id, remaining_stack, failed_method, opts) do
    # Add failed method to blacklist for this node
    node = context.solution_tree.nodes[node_id]
    updated_blacklist = [failed_method | node.blacklisted_methods]
    updated_node = %{node | blacklisted_methods: updated_blacklist}

    updated_tree = %{context.solution_tree |
      nodes: Map.put(context.solution_tree.nodes, node_id, updated_node)
    }

    updated_context = %{context | solution_tree: updated_tree}

    # Try expanding again with the updated blacklist
    expand_task_node(domain, updated_context, node_id, remaining_stack, opts)
  end

  # Handle primitive action failure
  @spec handle_action_failure(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp handle_action_failure(domain, context, failed_node_id, remaining_stack, reason, opts) do
    debug_puts("Action failed: #{reason}", context.verbose)

    # Blacklist the failed action globally
    failed_action = context.solution_tree.nodes[failed_node_id].task
    updated_tree = Blacklisting.blacklist_command(context.solution_tree, failed_action)

    # Find the parent task and try alternative methods
    case find_parent_task(context.solution_tree, failed_node_id) do
      nil ->
        # No parent task - this was a root action that failed
        {:error, "Root action failed: #{reason}"}

      parent_id ->
        # Reset parent task to unexpanded state and try alternative methods
        reset_parent_and_retry(domain, context, parent_id, remaining_stack, updated_tree, opts)
    end
  end

  # Handle task expansion failure
  @spec handle_task_failure(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp handle_task_failure(domain, context, failed_node_id, remaining_stack, reason, opts) do
    debug_puts("Task expansion failed: #{reason}", context.verbose)

    # Find the parent task and try alternative methods
    case find_parent_task(context.solution_tree, failed_node_id) do
      nil ->
        # No parent task - this was a root task that failed
        {:error, "Root task failed: #{reason}"}

      parent_id ->
        # Try alternative methods for the parent task
        reset_parent_and_retry(domain, context, parent_id, remaining_stack, context.solution_tree, opts)
    end
  end

  # Find the parent task node
  @spec find_parent_task(solution_tree(), node_id()) :: node_id() | nil
  defp find_parent_task(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      node -> node.parent_id
    end
  end

  # Reset parent task to unexpanded state and retry with alternative methods
  @spec reset_parent_and_retry(AriaEngine.Domain.t(), execution_context(), node_id(), [node_id()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp reset_parent_and_retry(domain, context, parent_id, remaining_stack, updated_tree, opts) do
    # Reset parent to unexpanded state
    parent_node = updated_tree.nodes[parent_id]
    reset_parent = %{parent_node |
      expanded: false,
      children_ids: [],
      blacklisted_methods: [parent_node.method_tried | parent_node.blacklisted_methods]
    }

    # Remove child nodes from tree
    updated_nodes = remove_child_nodes(updated_tree.nodes, parent_node.children_ids)
    updated_nodes = Map.put(updated_nodes, parent_id, reset_parent)

    final_tree = %{updated_tree | nodes: updated_nodes}

    # Add parent back to execution stack to retry
    new_stack = [parent_id | remaining_stack]

    updated_context = %{context |
      solution_tree: final_tree,
      execution_stack: new_stack
    }

    execute_lazy_step(domain, updated_context, opts)
  end

  # Remove child nodes recursively
  @spec remove_child_nodes(map(), [node_id()]) :: map()
  defp remove_child_nodes(nodes, child_ids) do
    Enum.reduce(child_ids, nodes, fn child_id, acc ->
      case acc[child_id] do
        nil -> acc
        child_node ->
          # Recursively remove grandchildren
          acc_without_grandchildren = remove_child_nodes(acc, child_node.children_ids)
          # Remove this child
          Map.delete(acc_without_grandchildren, child_id)
      end
    end)
  end

  # Apply a single action to the current state
  @spec apply_action_to_state(AriaEngine.Domain.t(), AriaEngine.StateV2.t(), plan_step(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp apply_action_to_state(domain, state, {action_name, args}, opts) when is_atom(action_name) do
    verbose = Keyword.get(opts, :verbose, 0)

    case AriaEngine.Domain.has_action?(domain, action_name) do
      true ->
        # Execute primitive action
        action_func = AriaEngine.Domain.get_action(domain, action_name)

        case action_func.(state, args) do
          %AriaEngine.StateV2{} = new_state ->
            {:ok, new_state}
          false ->
            {:error, "Action #{action_name} failed with args #{inspect(args)}"}
          {:error, reason} ->
            {:error, "Action #{action_name} failed: #{reason}"}
          other ->
            {:error, "Action #{action_name} returned unexpected result: #{inspect(other)}"}
        end

      false ->
        # Check if it's a durative action
        case AriaEngine.Domain.get_durative_action(domain, action_name) do
          nil ->
            {:error, "Unknown action: #{action_name}"}
          _durative_action ->
            # For now, treat durative actions as regular actions
            debug_puts("Executing durative action #{action_name} as regular action", verbose)
            {:error, "Durative action execution not yet implemented: #{action_name}"}
        end
    end
  end

  defp apply_action_to_state(_domain, _state, action, _opts) do
    {:error, "Invalid action format: #{inspect(action)}"}
  end
end
