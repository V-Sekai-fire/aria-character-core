# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Plan.ReentrantExecutor do
  @moduledoc """
  Reentrant executor with todo item failure recovery using IPyHOP pattern.

  This executor implements execution-time backtracking through the reentrant
  solution tree structure. When any todo item fails during execution,
  the executor uses the existing Plan.Blacklisting infrastructure to blacklist
  the failed item and re-enters execution with the modified tree.

  Key features:
  - Universal todo item execution (actions, commands, methods, etc.)
  - Todo item failure recovery through existing blacklisting infrastructure
  - Maintains IPyHOP reentrant tree structure
  - Minimal replanning - only re-extract primitives with updated blacklist
  - IPyHOP-style simple execution with blacklist state management
  """

  require Logger
  alias Plan.{Blacklisting, Utils}

  @type plan_step :: {atom() | String.t(), list()}
  @type execution_trace_entry :: {plan_step() | nil, map() | nil}
  @type execution_trace :: [execution_trace_entry()]
  @type execution_result :: {:ok, map(), execution_trace()} | {:error, String.t(), execution_trace()}
  @type solution_tree :: map()

  @doc """
  Execute a plan using IPyHOP-style simple execution.

  This function integrates with the new blacklisting system following
  the IPyHOP pattern where blacklisted commands are checked during execution.
  """
  @spec execute_plan_lazy(map(), map(), keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def execute_plan_lazy(solution_tree, initial_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      action_count = Utils.plan_cost(solution_tree)
      Logger.debug("IPyHOP execution: Starting execution of plan with #{action_count} actions")
    end

    domain = Keyword.get(opts, :domain)

    case domain do
      nil ->
        {:error, "Domain required for execution but not provided in options"}

      domain when is_map(domain) ->
        # Extract primitive actions from solution tree
        primitive_actions = AriaEngineCore.Plan.get_primitive_actions_dfs(solution_tree)

        if verbose > 1 do
          Logger.debug("IPyHOP execution: Executing #{length(primitive_actions)} primitive actions")
        end

        # Execute using reentrant IPyHOP-style executor with recovery
        case execute_with_recovery(domain, initial_state, solution_tree, opts) do
          {:ok, final_state, execution_trace} ->
            if verbose > 1 do
              Logger.debug("IPyHOP execution: Execution completed successfully")
              if verbose > 2 do
                Logger.debug("IPyHOP execution: Execution trace length: #{length(execution_trace)}")
              end
            end
            {:ok, final_state}

          {:error, reason, execution_trace} ->
            if verbose > 1 do
              Logger.debug("IPyHOP execution: Execution failed with reason: #{reason}")
              if verbose > 2 do
                Logger.debug("IPyHOP execution: Partial trace length: #{length(execution_trace)}")
              end
            end
            {:error, reason}
        end

      _ ->
        {:error, "Invalid domain type provided for execution"}
    end
  end

  @doc """
  Execute a solution tree with todo item failure recovery.

  This is the main entry point that implements the reentrant IPyHOP pattern:
  1. Extract primitive actions from solution tree
  2. Execute each todo item using universal execution
  3. If todo item fails, blacklist it using Plan.Blacklisting and retry
  4. Continue until all actions complete or unrecoverable failure

  ## Parameters

  - `domain`: The domain containing action and method definitions
  - `initial_state`: Starting state for execution
  - `solution_tree`: Solution tree with actions and blacklist
  - `opts`: Execution options (verbose, max_retries, etc.)

  ## Options

  - `:verbose` - Verbosity level (0-3)
  - `:max_retries` - Maximum retry attempts per failed todo item (default: 3)

  ## Returns

  - `{:ok, final_state, execution_trace}` on successful completion
  - `{:error, reason, execution_trace}` on failure (with trace up to failure point)
  """
  @spec execute_with_recovery(map(), map(), solution_tree(), keyword()) :: execution_result()
  def execute_with_recovery(domain, initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    max_retries = Keyword.get(opts, :max_retries, 3)

    if verbose > 1 do
      Logger.debug("ReentrantExecutor: Starting execution with recovery capability")
    end

    # Get or create blacklist state using existing infrastructure
    blacklist_state = get_or_create_blacklist_state(solution_tree, opts)

    # Extract primitive actions from solution tree
    primitive_actions = AriaEngineCore.Plan.get_primitive_actions_dfs(solution_tree)

    # Initialize execution trace with initial state
    initial_trace = [{nil, initial_state}]

    # Execute with retry capability
    execute_with_retry(domain, initial_state, primitive_actions, solution_tree, blacklist_state, initial_trace, opts, 0, max_retries)
  end

  # Private implementation functions

  @spec execute_with_retry(map(), map(), [plan_step()], solution_tree(), map(), execution_trace(), keyword(), integer(), integer()) :: execution_result()
  defp execute_with_retry(domain, current_state, actions, solution_tree, blacklist_state, execution_trace, opts, retry_count, max_retries) do
    verbose = Keyword.get(opts, :verbose, 0)

    case execute_actions_sequence(domain, current_state, actions, blacklist_state, execution_trace, opts) do
      {:ok, final_state, final_trace} ->
        if verbose > 1 do
          Logger.debug("ReentrantExecutor: Execution completed successfully")
        end
        {:ok, final_state, Enum.reverse(final_trace)}

      {:error, :todo_item_failed, failed_action, partial_state, partial_trace} when retry_count < max_retries ->
        if verbose > 1 do
          Logger.debug("ReentrantExecutor: Todo item failed, attempting HTN backtracking (retry #{retry_count + 1}/#{max_retries})")
        end

        # HTN Backtracking: Find which method generated this failed action
        case find_method_for_failed_action(solution_tree, failed_action, verbose) do
          {:ok, parent_node_id, method_name} ->
            if verbose > 1 do
              Logger.debug("ReentrantExecutor: Blacklisting method '#{method_name}' in node #{parent_node_id}")
            end

            # Blacklist the method that generated the failed action
            updated_tree = blacklist_method_in_node(solution_tree, parent_node_id, method_name)

            # Re-plan from the parent node with blacklisted method
            case replan_from_node(domain, updated_tree, parent_node_id, partial_state, opts) do
              {:ok, replanned_tree} ->
                # Extract new primitive actions from replanned tree
                updated_actions = AriaEngineCore.Plan.get_primitive_actions_dfs(replanned_tree)

                if verbose > 1 do
                  Logger.debug("ReentrantExecutor: Re-planned with #{length(updated_actions)} actions")
                end

                # Retry execution with replanned tree
                execute_with_retry(domain, partial_state, updated_actions, replanned_tree, blacklist_state, partial_trace, opts, retry_count + 1, max_retries)

              {:error, replan_reason} ->
                if verbose > 1 do
                  Logger.debug("ReentrantExecutor: Re-planning failed: #{replan_reason}")
                end
                {:error, "HTN backtracking failed: #{replan_reason}", Enum.reverse(partial_trace)}
            end

          {:error, :no_method_found} ->
            if verbose > 1 do
              Logger.debug("ReentrantExecutor: No method found for failed action, falling back to action blacklisting")
            end

            # Fallback to action-level blacklisting for primitive actions
            updated_blacklist_state = Blacklisting.blacklist_command(blacklist_state, failed_action)
            updated_tree = Map.put(solution_tree, :blacklisted_commands, updated_blacklist_state.blacklisted_commands)
            updated_actions = AriaEngineCore.Plan.get_primitive_actions_dfs(updated_tree)

            execute_with_retry(domain, partial_state, updated_actions, updated_tree, updated_blacklist_state, partial_trace, opts, retry_count + 1, max_retries)
        end

            {:error, reason, _failed_action, _partial_state, partial_trace} ->
              if verbose > 1 do
                Logger.debug("ReentrantExecutor: Execution failed with unrecoverable error: #{reason}")
              end
              # Convert atom reasons to strings for consistency
              string_reason = case reason do
                atom when is_atom(atom) -> Atom.to_string(atom)
                string when is_binary(string) -> string
                other -> inspect(other)
              end
              {:error, string_reason, Enum.reverse(partial_trace)}
    end
  end

  @spec execute_actions_sequence(map(), map(), [plan_step()], map(), execution_trace(), keyword()) ::
    {:ok, map(), execution_trace()} |
    {:error, atom(), plan_step(), map(), execution_trace()}
  defp execute_actions_sequence(domain, current_state, actions, blacklist_state, execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    Enum.reduce_while(actions, {:ok, current_state, execution_trace}, fn action, {:ok, state, trace} ->
      case execute_single_todo_item(domain, state, action, blacklist_state, opts) do
        {:ok, new_state} ->
          new_trace = [{action, new_state} | trace]
          if verbose > 2 do
            Logger.debug("ReentrantExecutor: Todo item succeeded: #{inspect(action)}")
          end
          {:cont, {:ok, new_state, new_trace}}

        {:error, reason} ->
          if verbose > 1 do
            Logger.debug("ReentrantExecutor: Todo item failed: #{inspect(action)}, reason: #{reason}")
          end
          # Return error with current state and trace for potential recovery
          {:halt, {:error, :todo_item_failed, action, state, trace}}
      end
    end)
  end

  @spec execute_single_todo_item(map(), map(), plan_step(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  defp execute_single_todo_item(domain, state, {action_name, args}, blacklist_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Check if todo item is blacklisted using existing infrastructure
    if Blacklisting.command_blacklisted?(blacklist_state, {action_name, args}) do
      if verbose > 2 do
        Logger.debug("ReentrantExecutor: Skipping blacklisted todo item: #{action_name}")
      end
      {:error, :todo_item_blacklisted}
    else
      # Execute the todo item using universal execution
      case execute_todo_item_universal(domain, state, action_name, args, opts) do
        {:ok, new_state} ->
          if verbose > 2 do
            Logger.debug("ReentrantExecutor: Todo item executed successfully: #{action_name}")
          end
          {:ok, new_state}

        {:error, reason} ->
          if verbose > 2 do
            Logger.debug("ReentrantExecutor: Todo item execution failed: #{action_name}, reason: #{reason}")
          end
          {:error, reason}
      end
    end
  end

  @spec execute_todo_item_universal(map(), map(), atom() | String.t(), list(), keyword()) :: {:ok, map()} | {:error, term()}
  defp execute_todo_item_universal(domain, state, action_name, args, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Convert to atom for function lookup
    action_atom = case action_name do
      atom when is_atom(atom) -> atom
      string when is_binary(string) -> String.to_atom(string)
    end

    # Try to execute the todo item using domain actions
    cond do
      # Check if domain is an AriaCore.Domain struct with actions
      is_map(domain) and Map.has_key?(domain, :actions) ->
        # Try both string and atom keys for action lookup
        action_def = Map.get(domain.actions, action_atom) || Map.get(domain.actions, Atom.to_string(action_atom))

        case action_def do
          nil ->
            {:error, "Todo item action not found in domain: #{action_name}"}
          action_def when is_map(action_def) ->
            if verbose > 2 do
              Logger.debug("ReentrantExecutor: Executing domain action: #{action_atom}")
            end
            # Try different action function locations in AriaCore domain structure
            action_fn = cond do
              # Check for function field (primary location)
              Map.has_key?(action_def, :function) and is_function(action_def.function, 2) ->
                action_def.function

              # Check for action_fn in metadata (secondary location)
              Map.has_key?(action_def, :metadata) and
              Map.has_key?(action_def.metadata, :action_fn) and
              is_function(action_def.metadata.action_fn, 2) ->
                action_def.metadata.action_fn

              # Check for direct action_fn field (legacy support)
              Map.has_key?(action_def, :action_fn) and is_function(action_def.action_fn, 2) ->
                action_def.action_fn

              true ->
                nil
            end

            case action_fn do
              nil ->
                {:error, "Action #{action_name} has no valid function"}
              action_fn when is_function(action_fn, 2) ->
                try do
                  case action_fn.(state, args) do
                    {:ok, new_state} -> {:ok, new_state}
                    {:error, reason} -> {:error, reason}
                    new_state -> {:ok, new_state}  # Handle direct state return
                  end
                rescue
                  e ->
                    {:error, "Action execution failed: #{Exception.message(e)}"}
                end
            end
        end

      # Domain is a module - try direct function call
      is_atom(domain) ->
        if function_exported?(domain, action_atom, 2) do
          if verbose > 2 do
            Logger.debug("ReentrantExecutor: Executing domain function: #{action_atom}")
          end
          apply(domain, action_atom, [state, args])
        else
          {:error, "Todo item function not found: #{action_name}"}
        end

      # Unknown domain type
      true ->
        {:error, "Invalid domain type for execution: #{inspect(domain)}"}
    end
  end

  @spec get_or_create_blacklist_state(solution_tree(), keyword()) :: map()
  defp get_or_create_blacklist_state(solution_tree, opts) do
    # Check if blacklist state is provided in options first
    case Keyword.get(opts, :blacklist_state) do
      nil ->
        # Create new blacklist state or extract from solution tree
        blacklist_state = Blacklisting.new()
        case Map.get(solution_tree, :blacklisted_commands) do
          %MapSet{} = commands ->
            %{blacklist_state | blacklisted_commands: commands}
          nil ->
            blacklist_state
          _other ->
            blacklist_state
        end

      provided_blacklist_state ->
        provided_blacklist_state
    end
  end

  # HTN Backtracking Helper Functions

  # Find which method generated a failed action by tracing back through the solution tree.
  #
  # This function searches the solution tree to find the parent node that contains
  # the method responsible for generating the failed primitive action.
  @spec find_method_for_failed_action(solution_tree(), plan_step(), integer()) ::
    {:ok, String.t(), String.t()} | {:error, :no_method_found}
  defp find_method_for_failed_action(solution_tree, failed_action, verbose) do
    if verbose > 2 do
      Logger.debug("HTN Backtracking: Searching for method that generated action: #{inspect(failed_action)}")
    end

    # Find the node containing this action
    case find_node_with_action(solution_tree, failed_action) do
      {:ok, action_node_id} ->
        # Trace back to find parent node with method
        case find_parent_with_method(solution_tree, action_node_id, verbose) do
          {:ok, parent_node_id, method_name} ->
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Found method '#{method_name}' in parent node #{parent_node_id}")
            end
            {:ok, parent_node_id, method_name}

          {:error, reason} ->
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Could not find parent method: #{reason}")
            end
            {:error, :no_method_found}
        end

      {:error, reason} ->
        if verbose > 2 do
          Logger.debug("HTN Backtracking: Could not find action node: #{reason}")
        end
        {:error, :no_method_found}
    end
  end

  @spec find_node_with_action(solution_tree(), plan_step()) :: {:ok, String.t()} | {:error, String.t()}
  defp find_node_with_action(solution_tree, {action_name, args}) do
    # Search through all nodes to find one with matching task
    matching_node = Enum.find(solution_tree.nodes, fn {_id, node} ->
      case node.task do
        {^action_name, ^args} -> true
        _ -> false
      end
    end)

    case matching_node do
      {node_id, _node} -> {:ok, node_id}
      nil -> {:error, "No node found with action #{inspect({action_name, args})}"}
    end
  end

  @spec find_parent_with_method(solution_tree(), String.t(), integer()) ::
    {:ok, String.t(), String.t()} | {:error, String.t()}
  defp find_parent_with_method(solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        case node.parent_id do
          nil ->
            {:error, "Reached root node without finding method"}

          parent_id ->
            case solution_tree.nodes[parent_id] do
              nil ->
                {:error, "Parent node not found: #{parent_id}"}

              parent_node ->
                case parent_node.method_tried do
                  nil ->
                    # Parent has no method, continue searching up the tree
                    if verbose > 2 do
                      Logger.debug("HTN Backtracking: Parent node #{parent_id} has no method, searching further up")
                    end
                    find_parent_with_method(solution_tree, parent_id, verbose)

                  method_name ->
                    # Found parent with method
                    {:ok, parent_id, method_name}
                end
            end
        end
    end
  end

  # Blacklist a method in a specific node by adding it to the node's blacklisted_methods list.
  @spec blacklist_method_in_node(solution_tree(), String.t(), String.t()) :: solution_tree()
  defp blacklist_method_in_node(solution_tree, node_id, method_name) do
    case solution_tree.nodes[node_id] do
      nil ->
        # Node not found, return tree unchanged
        solution_tree

      node ->
        # Add method to blacklisted_methods list if not already present
        updated_blacklisted_methods =
          if method_name in node.blacklisted_methods do
            node.blacklisted_methods
          else
            [method_name | node.blacklisted_methods]
          end

        # Update the node
        updated_node = %{node |
          blacklisted_methods: updated_blacklisted_methods,
          method_tried: nil,  # Clear current method
          expanded: false     # Mark for re-expansion
        }

        # Update the solution tree
        put_in(solution_tree.nodes[node_id], updated_node)
    end
  end

  # Re-plan from a specific node by trying alternative methods.
  #
  # This function attempts to expand the given node using methods that haven't
  # been blacklisted, effectively implementing HTN backtracking.
  @spec replan_from_node(map(), solution_tree(), String.t(), map(), keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp replan_from_node(domain, solution_tree, node_id, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found for re-planning: #{node_id}"}

      node ->
        if verbose > 2 do
          Logger.debug("HTN Backtracking: Re-planning node #{node_id} with task: #{inspect(node.task)}")
        end

        # Clear children from failed expansion
        cleared_node = %{node | children_ids: [], expanded: false}
        cleared_tree = put_in(solution_tree.nodes[node_id], cleared_node)

        # Try to expand the node with alternative methods
        case try_alternative_methods(domain, cleared_tree, node_id, state, opts) do
          {:ok, expanded_tree} ->
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Successfully re-planned node #{node_id}")
            end
            {:ok, expanded_tree}

          {:error, reason} ->
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Re-planning failed for node #{node_id}: #{reason}")
            end
            {:error, reason}
        end
    end
  end

  @spec try_alternative_methods(map(), solution_tree(), String.t(), map(), keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp try_alternative_methods(domain, solution_tree, node_id, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        case node.task do
          {action_name, _args} when is_atom(action_name) ->
            # Primitive action - mark as primitive (no methods to try)
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Marking primitive action as expanded: #{action_name}")
            end
            Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

          {task_name, args} when is_binary(task_name) ->
            # Task node - try alternative task methods
            try_task_methods(domain, solution_tree, node_id, task_name, args, state, opts)

          {predicate, subject, value} when is_binary(predicate) ->
            # Goal node - try alternative unigoal methods
            try_unigoal_methods(domain, solution_tree, node_id, predicate, subject, value, state, opts)

          _ ->
            # Unknown task type - mark as primitive
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Unknown task type, marking as primitive")
            end
            Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)
        end
    end
  end

  @spec try_task_methods(map(), solution_tree(), String.t(), String.t(), list(), map(), keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp try_task_methods(domain, solution_tree, node_id, task_name, args, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Get available methods for this task
    task_atom = String.to_atom(task_name)
    available_methods = AriaCore.get_task_methods_from_domain(domain, task_atom)

    # Filter out blacklisted methods
    usable_methods = Enum.reject(available_methods, fn method ->
      method in node.blacklisted_methods
    end)

    if verbose > 2 do
      Logger.debug("HTN Backtracking: Task #{task_name} has #{length(usable_methods)} usable methods (#{length(available_methods)} total)")
    end

    case usable_methods do
      [] ->
        # No usable methods left - mark as primitive
        if verbose > 2 do
          Logger.debug("HTN Backtracking: No usable methods for task #{task_name}, marking as primitive")
        end
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

      [method_name | _] ->
        # Try the first available method
        if verbose > 2 do
          Logger.debug("HTN Backtracking: Trying method #{method_name} for task #{task_name}")
        end

        # Execute the task method and create child nodes from result
        case execute_task_method(domain, state, task_atom, args, method_name, opts) do
          {:ok, []} ->
            # Method returned empty list - task already completed
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Task method #{method_name} returned empty list - task completed")
            end
            updated_node = %{node | method_tried: method_name, expanded: true, is_primitive: true}
            updated_tree = put_in(solution_tree.nodes[node_id], updated_node)
            {:ok, updated_tree}

          {:ok, subtasks} ->
            # Method returned subtasks - create child nodes
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Task method #{method_name} returned #{length(subtasks)} subtasks")
            end
            case create_child_nodes_from_subtasks(solution_tree, node_id, subtasks, method_name, opts) do
              {:ok, updated_tree} -> {:ok, updated_tree}
              {:error, reason} -> {:error, "Failed to create child nodes: #{reason}"}
            end

          {:error, reason} ->
            # Method execution failed - try next method or mark as primitive
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Task method #{method_name} failed: #{reason}")
            end
            # Blacklist this method and try alternatives
            blacklisted_node = %{node | blacklisted_methods: [method_name | node.blacklisted_methods]}
            blacklisted_tree = put_in(solution_tree.nodes[node_id], blacklisted_node)
            try_task_methods(domain, blacklisted_tree, node_id, task_name, args, state, opts)
        end
    end
  end

  @spec try_unigoal_methods(map(), solution_tree(), String.t(), String.t(), String.t(), any(), map(), keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp try_unigoal_methods(domain, solution_tree, node_id, predicate, subject, value, state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Get available unigoal methods for this predicate
    predicate_atom = String.to_atom(predicate)
    available_methods = AriaCore.get_unigoal_methods_from_domain(domain, predicate_atom)

    # Filter out blacklisted methods
    usable_methods = Enum.reject(available_methods, fn method ->
      method in node.blacklisted_methods
    end)

    if verbose > 2 do
      Logger.debug("HTN Backtracking: Goal #{predicate} has #{length(usable_methods)} usable methods (#{length(available_methods)} total)")
    end

    case usable_methods do
      [] ->
        # No usable methods left - mark as primitive
        if verbose > 2 do
          Logger.debug("HTN Backtracking: No usable methods for goal #{predicate}, marking as primitive")
        end
        Plan.NodeExpansion.mark_as_primitive(solution_tree, node_id)

      [method_name | _] ->
        # Try the first available method
        if verbose > 2 do
          Logger.debug("HTN Backtracking: Trying unigoal method #{method_name} for goal #{predicate}")
        end

        # Execute the unigoal method and create child nodes from result
        case execute_unigoal_method(domain, state, predicate_atom, {subject, value}, method_name, opts) do
          {:ok, []} ->
            # Method returned empty list - goal already satisfied
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Unigoal method #{method_name} returned empty list - goal satisfied")
            end
            updated_node = %{node | method_tried: method_name, expanded: true, is_primitive: true}
            updated_tree = put_in(solution_tree.nodes[node_id], updated_node)
            {:ok, updated_tree}

          {:ok, subtasks} ->
            # Method returned subtasks - create child nodes
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Unigoal method #{method_name} returned #{length(subtasks)} subtasks")
            end
            case create_child_nodes_from_subtasks(solution_tree, node_id, subtasks, method_name, opts) do
              {:ok, updated_tree} -> {:ok, updated_tree}
              {:error, reason} -> {:error, "Failed to create child nodes: #{reason}"}
            end

          {:error, reason} ->
            # Method execution failed - try next method or mark as primitive
            if verbose > 2 do
              Logger.debug("HTN Backtracking: Unigoal method #{method_name} failed: #{reason}")
            end
            # Blacklist this method and try alternatives
            blacklisted_node = %{node | blacklisted_methods: [method_name | node.blacklisted_methods]}
            blacklisted_tree = put_in(solution_tree.nodes[node_id], blacklisted_node)
            try_unigoal_methods(domain, blacklisted_tree, node_id, predicate, subject, value, state, opts)
        end
    end
  end

  # Helper functions for method execution

  # Execute a unigoal method and return the resulting subtasks.
  #
  # This function retrieves the unigoal method from the domain and executes it
  # with the provided state and goal arguments.
  @spec execute_unigoal_method(map(), map(), atom(), {String.t(), any()}, String.t(), keyword()) ::
    {:ok, list()} | {:error, String.t()}
  defp execute_unigoal_method(domain, state, predicate, {subject, value}, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Method Execution: Executing unigoal method #{method_name} for #{predicate}(#{subject}, #{value})")
    end

    try do
      # Get the method function from the domain
      case get_unigoal_method_function(domain, predicate, method_name) do
        {:ok, method_fn} ->
          # Execute the method with state and goal arguments
          case method_fn.(state, {subject, value}) do
            subtasks when is_list(subtasks) ->
              if verbose > 2 do
                Logger.debug("HTN Method Execution: Method #{method_name} returned #{length(subtasks)} subtasks")
              end
              {:ok, subtasks}

            other_result ->
              if verbose > 2 do
                Logger.debug("HTN Method Execution: Method #{method_name} returned non-list result: #{inspect(other_result)}")
              end
              {:error, "Method returned non-list result: #{inspect(other_result)}"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Method execution failed: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Method Execution: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  # Execute a task method and return the resulting subtasks.
  #
  # This function retrieves the task method from the domain and executes it
  # with the provided state and task arguments.
  @spec execute_task_method(map(), map(), atom(), list(), String.t(), keyword()) ::
    {:ok, list()} | {:error, String.t()}
  defp execute_task_method(domain, state, task_name, args, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Method Execution: Executing task method #{method_name} for #{task_name}(#{inspect(args)})")
    end

    try do
        # Get the method function from the domain
        case get_task_method_function(domain, task_name, method_name) do
        {:ok, method_fn} ->
          # Execute the method with state and task arguments
          case method_fn.(state, args) do
            subtasks when is_list(subtasks) ->
              if verbose > 2 do
                Logger.debug("HTN Method Execution: Method #{method_name} returned #{length(subtasks)} subtasks")
              end
              {:ok, subtasks}

            other_result ->
              if verbose > 2 do
                Logger.debug("HTN Method Execution: Method #{method_name} returned non-list result: #{inspect(other_result)}")
              end
              {:error, "Method returned non-list result: #{inspect(other_result)}"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Method execution failed: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Method Execution: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  # Get a task method function from the domain.
  @spec get_task_method_function(map(), atom(), String.t()) :: {:ok, function()} | {:error, String.t()}
  defp get_task_method_function(domain, task_name, method_name) do
    # Get task methods for the actual task name
    case AriaCore.get_task_methods_from_domain(domain, task_name) do
      [] ->
        {:error, "Task method #{method_name} not found in domain"}

      methods when is_list(methods) ->
        # Convert method name to atom for lookup
        method_atom = case method_name do
          atom when is_atom(atom) -> atom
          string when is_binary(string) -> String.to_atom(string)
        end

        # Find the method function in the keyword list
        case Keyword.get(methods, method_atom) do
          nil ->
            # If exact match not found, try the first available method
            case methods do
              [{_name, method_fn} | _] when is_function(method_fn, 2) ->
                {:ok, method_fn}
              _ ->
                {:error, "No valid method function found for #{method_name}"}
            end

          method_fn when is_function(method_fn, 2) ->
            {:ok, method_fn}

          _other ->
            {:error, "Invalid method function for #{method_name}"}
        end

      _other ->
        {:error, "Invalid task methods structure for #{method_name}"}
    end
  end

  # Get a unigoal method function from the domain.
  @spec get_unigoal_method_function(map(), atom(), String.t()) :: {:ok, function()} | {:error, String.t()}
  defp get_unigoal_method_function(domain, predicate, method_name) do
    # Convert predicate atom to string for AriaCore.Domain API
    predicate_string = Atom.to_string(predicate)

    # Try to get methods for the predicate using the new Domain API
    case AriaCore.get_unigoal_methods_for_predicate(domain, predicate_string) do
      methods when map_size(methods) == 0 ->
        {:error, "No unigoal methods found for predicate #{predicate}"}

      methods when is_map(methods) ->
        # Try to find the specific method by name first
        case Map.get(methods, String.to_atom(method_name)) do
          nil ->
            # If specific method not found, use the first available method
            case Enum.at(methods, 0) do
              nil ->
                {:error, "No unigoal methods available for predicate #{predicate}"}

              {_method_name, method_spec} ->
                extract_unigoal_function(method_spec, method_name)
            end

          method_spec when is_map(method_spec) ->
            extract_unigoal_function(method_spec, method_name)

          method_fn when is_function(method_fn, 2) ->
            {:ok, method_fn}

          _other ->
            {:error, "Invalid method specification for #{method_name}"}
        end

      _other ->
        {:error, "Invalid unigoal methods structure for predicate #{predicate}"}
    end
  end

  @spec extract_unigoal_function(map(), String.t()) :: {:ok, function()} | {:error, String.t()}
  defp extract_unigoal_function(method_spec, method_name) do
    cond do
      Map.has_key?(method_spec, :goal_fn) and is_function(method_spec.goal_fn, 2) ->
        {:ok, method_spec.goal_fn}

      Map.has_key?(method_spec, :function) and is_function(method_spec.function, 2) ->
        {:ok, method_spec.function}

      true ->
        {:error, "Method #{method_name} has no valid function"}
    end
  end

  # Create child nodes from a list of subtasks returned by a method.
  #
  # This function creates new nodes in the solution tree for each subtask
  #and links them as children of the parent node.
  @spec create_child_nodes_from_subtasks(solution_tree(), String.t(), list(), String.t(), keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp create_child_nodes_from_subtasks(solution_tree, parent_node_id, subtasks, method_name, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Node Creation: Creating #{length(subtasks)} child nodes for parent #{parent_node_id}")
    end

    try do
      # Generate unique IDs for child nodes
      {child_nodes, child_ids} = Enum.with_index(subtasks)
      |> Enum.map(fn {subtask, index} ->
        child_id = "#{parent_node_id}_#{method_name}_#{index}"
        child_node = create_child_node(subtask, parent_node_id, child_id)
        {child_node, child_id}
      end)
      |> Enum.unzip()

      # Update parent node with method and children
      parent_node = solution_tree.nodes[parent_node_id]
      updated_parent = %{parent_node |
        method_tried: method_name,
        expanded: true,
        is_primitive: false,
        children_ids: child_ids
      }

      # Add all child nodes to the solution tree
      updated_nodes = child_nodes
      |> Enum.zip(child_ids)
      |> Enum.reduce(solution_tree.nodes, fn {{child_node, child_id}, _}, acc_nodes ->
        Map.put(acc_nodes, child_id, child_node)
      end)
      |> Map.put(parent_node_id, updated_parent)

      updated_tree = %{solution_tree | nodes: updated_nodes}

      if verbose > 2 do
        Logger.debug("HTN Node Creation: Successfully created #{length(child_ids)} child nodes")
      end

      {:ok, updated_tree}
    rescue
      e ->
        error_msg = "Failed to create child nodes: #{Exception.message(e)}"
        if verbose > 1 do
          Logger.debug("HTN Node Creation: #{error_msg}")
        end
        {:error, error_msg}
    end
  end

  # Create a single child node from a subtask.
  @spec create_child_node(any(), String.t(), String.t()) :: map()
  defp create_child_node(subtask, parent_id, node_id) do
    %{
      id: node_id,
      task: subtask,
      parent_id: parent_id,
      children_ids: [],
      expanded: false,
      is_primitive: false,
      method_tried: nil,
      blacklisted_methods: []
    }
  end
end
