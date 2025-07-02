# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

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
  """

  require Logger
  alias Plan.{Blacklisting, Utils}

  @type plan_step :: {atom() | String.t(), list()}
  @type execution_trace_entry :: {plan_step() | nil, map() | nil}
  @type execution_trace :: [execution_trace_entry()]
  @type execution_result :: {:ok, map(), execution_trace()} | {:error, String.t(), execution_trace()}
  @type solution_tree :: map()

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
    primitive_actions = extract_primitive_actions(solution_tree)

    # Initialize execution trace with initial state
    initial_trace = [{nil, initial_state}]

    # Execute with retry capability
    execute_with_retry(domain, initial_state, primitive_actions, solution_tree, blacklist_state, initial_trace, opts, 0, max_retries)
  end

  @doc """
  Extract primitive actions from a solution tree for execution.

  Uses existing utility function to maintain compatibility.
  """
  @spec extract_primitive_actions(solution_tree()) :: [plan_step()]
  def extract_primitive_actions(solution_tree) do
    Utils.get_primitive_actions_dfs(solution_tree)
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
          Logger.debug("ReentrantExecutor: Todo item failed, attempting recovery (retry #{retry_count + 1}/#{max_retries})")
        end

        # Blacklist the failed todo item using existing infrastructure
        updated_blacklist_state = Blacklisting.blacklist_command(blacklist_state, failed_action)

        # Update solution tree with new blacklist state
        updated_tree = Blacklisting.to_solution_tree(solution_tree, updated_blacklist_state)

        # Re-extract actions with updated blacklist (may choose different methods)
        updated_actions = extract_primitive_actions(updated_tree)

        # Retry execution with updated blacklist
        execute_with_retry(domain, partial_state, updated_actions, updated_tree, updated_blacklist_state, partial_trace, opts, retry_count + 1, max_retries)

      {:error, reason, _failed_action, _partial_state, partial_trace} ->
        if verbose > 1 do
          Logger.debug("ReentrantExecutor: Execution failed with unrecoverable error: #{reason}")
        end
        {:error, reason, Enum.reverse(partial_trace)}
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

    # Try to execute the todo item - any function that takes (state, args) and returns {:ok, state} | {:error, reason}
    cond do
      # Check if function exists in domain
      function_exported?(domain, action_atom, 2) ->
        if verbose > 2 do
          Logger.debug("ReentrantExecutor: Executing domain function: #{action_atom}")
        end
        apply(domain, action_atom, [state, args])

      # Function not found
      true ->
        {:error, "Todo item function not found: #{action_name}"}
    end
  end

  @spec get_or_create_blacklist_state(solution_tree(), keyword()) :: map()
  defp get_or_create_blacklist_state(solution_tree, opts) do
    # Check if blacklist state is provided in options first
    case Keyword.get(opts, :blacklist_state) do
      nil ->
        # Try to extract from solution tree using existing infrastructure
        Blacklisting.from_solution_tree(solution_tree)

      provided_blacklist_state ->
        provided_blacklist_state
    end
  end
end
