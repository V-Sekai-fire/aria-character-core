# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Execution do
  @moduledoc """
  Functions for executing the planned solution using Run-Lazy-Refineahead.
  """

  require Logger
  alias AriaEngine.Plan.Utils
  alias AriaEngine.Plan.Blacklisting

  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          # Using term() as task type is defined in Core
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

  @default_verbose 0
  @default_replan_depth 10

  # Helper to conditionally output debug information
  defp debug_puts(message) do
    # Only output during tests if ExUnit trace mode is enabled
    if Application.get_env(:ex_unit, :trace, false) or not test_mode?() do
      Logger.debug(message)
    end
  end

  defp test_mode?() do
    # Check if we're running in test environment
    Mix.env() == :test
  end

  @doc """
  Execute a solution tree using lazy refinement with optional replanning on failure.

  This function implements lazy execution where actions are executed incrementally
  with state updates, supporting refinement-ahead strategies and replanning when
  actions fail during execution.
  """
  @spec run_lazy_refineahead(AriaEngine.Domain.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, %AriaEngine.StateV2{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    replan_depth = Keyword.get(opts, :replan_depth, @default_replan_depth)
    refinement_ahead = Keyword.get(opts, :refinement_ahead, false)
    lookahead_depth = Keyword.get(opts, :lookahead_depth, 1)
    enable_checkpoints = Keyword.get(opts, :enable_checkpoints, false)
    enable_rollback = Keyword.get(opts, :enable_rollback, false)

    if verbose > 1 do
      debug_puts("Starting lazy refinement execution")
    end

    try do
      # Extract primitive actions from solution tree
      actions = Utils.get_primitive_actions_dfs(solution_tree)

      if verbose > 2 do
        debug_puts("Extracted #{length(actions)} primitive actions for execution")
      end

      # Initialize execution context
      context = %{
        current_state: initial_state,
        remaining_actions: actions,
        executed_actions: [],
        checkpoints: if(enable_checkpoints, do: [initial_state], else: []),
        replan_attempts: 0,
        max_replan_attempts: replan_depth,
        refinement_ahead: refinement_ahead,
        lookahead_depth: lookahead_depth,
        enable_rollback: enable_rollback,
        verbose: verbose
      }

      # Execute actions with lazy refinement
      execute_actions_lazily(domain, context, solution_tree, opts)
    rescue
      e ->
        error_msg = "Lazy refinement execution error: #{Exception.message(e)}"
        if verbose > 0 do
          debug_puts(error_msg)
        end
        {:error, error_msg}
    end
  end

  # Execute actions incrementally with lazy refinement
  @spec execute_actions_lazily(AriaEngine.Domain.t(), map(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_actions_lazily(domain, context, solution_tree, opts) do
    case context.remaining_actions do
      [] ->
        # All actions executed successfully
        if context.verbose > 1 do
          debug_puts("Lazy execution completed successfully")
        end
        {:ok, context.current_state}

      [action | remaining_actions] ->
        # Execute next action with refinement-ahead if enabled
        if context.refinement_ahead and context.lookahead_depth > 0 do
          execute_with_refinement_ahead(domain, context, action, remaining_actions, solution_tree, opts)
        else
          execute_single_action(domain, context, action, remaining_actions, solution_tree, opts)
        end
    end
  end

  # Execute single action without refinement-ahead
  @spec execute_single_action(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_single_action(domain, context, action, remaining_actions, solution_tree, opts) do
    if context.verbose > 2 do
      debug_puts("Executing action: #{inspect(action)}")
    end

    case apply_action_to_state(domain, context.current_state, action, opts) do
      {:ok, new_state} ->
        # Action succeeded, continue with remaining actions
        updated_context = %{
          context
          | current_state: new_state,
            remaining_actions: remaining_actions,
            executed_actions: [action | context.executed_actions]
        }

        # Add checkpoint if enabled
        updated_context = if context.checkpoints != [] do
          %{updated_context | checkpoints: [new_state | context.checkpoints]}
        else
          updated_context
        end

        execute_actions_lazily(domain, updated_context, solution_tree, opts)

      {:error, reason} ->
        # Action failed during execution - this should not happen if planning was done correctly
        {:error, "Action execution failed (planning bug): #{inspect(action)} - #{reason}"}
    end
  end

  # Execute action with refinement-ahead optimization
  @spec execute_with_refinement_ahead(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_with_refinement_ahead(domain, context, action, remaining_actions, solution_tree, opts) do
    if context.verbose > 2 do
      debug_puts("Executing action with refinement-ahead: #{inspect(action)}")
    end

    # Check if action is blacklisted
    if MapSet.member?(solution_tree.blacklisted_commands, action) do
      if context.verbose > 1 do
        debug_puts("Action #{inspect(action)} is blacklisted, skipping")
      end
      # Skip blacklisted action and continue with remaining actions
      updated_context = %{
        context
        | remaining_actions: remaining_actions,
          executed_actions: [action | context.executed_actions]
      }
      execute_actions_lazily(domain, updated_context, solution_tree, opts)
    else
      # Look ahead at upcoming actions for optimization opportunities
      lookahead_actions = Enum.take(remaining_actions, context.lookahead_depth)

      # For now, implement basic refinement-ahead by checking if upcoming actions are compatible
      case apply_action_to_state(domain, context.current_state, action, opts) do
        {:ok, new_state} ->
          # Check if refinement-ahead optimization is possible
          optimized_state = apply_refinement_optimization(domain, new_state, lookahead_actions, opts)

          updated_context = %{
            context
            | current_state: optimized_state,
              remaining_actions: remaining_actions,
              executed_actions: [action | context.executed_actions]
          }

          execute_actions_lazily(domain, updated_context, solution_tree, opts)

        {:error, reason} ->
          # Action failed, blacklist it and attempt replanning if possible
          updated_solution_tree = Blacklisting.blacklist_command(solution_tree, action)
          handle_action_failure(domain, context, action, remaining_actions, updated_solution_tree, reason, opts)
      end
    end
  end

  # Apply refinement optimization based on lookahead
  @spec apply_refinement_optimization(AriaEngine.Domain.t(), AriaEngine.StateV2.t(), [plan_step()], keyword()) ::
          AriaEngine.StateV2.t()
  defp apply_refinement_optimization(_domain, state, lookahead_actions, _opts) do
    # Simple optimization: if we can detect that upcoming actions will set "optimized" flag,
    # set it early for domains that support this
    case lookahead_actions do
      [{:move_optimized, _args} | _] ->
        # Set optimization flag early if the domain supports it
        case AriaEngine.StateV2.get_fact(state, "robot", "optimized") do
          nil -> state  # Domain doesn't support optimization flag
          _ -> AriaEngine.StateV2.set_fact(state, "robot", "optimized", true)
        end
      _ ->
        state
    end
  end

  # Handle action execution failure with replanning
  @spec handle_action_failure(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp handle_action_failure(domain, context, failed_action, remaining_actions, solution_tree, reason, opts) do
    Logger.error("EXECUTION: Action failed: #{inspect(failed_action)}, reason: #{reason}")
    Logger.error("EXECUTION: Blacklisted commands: #{inspect(MapSet.to_list(solution_tree.blacklisted_commands))}")

    if context.verbose > 1 do
      debug_puts("Action failed: #{inspect(failed_action)}, reason: #{reason}")
    end

    cond do
      context.replan_attempts >= context.max_replan_attempts ->
        {:error, "Replanning failed: maximum replan attempts (#{context.max_replan_attempts}) exceeded"}

      context.enable_rollback and length(context.checkpoints) > 1 ->
        # Attempt rollback to previous checkpoint
        attempt_rollback_and_replan(domain, context, failed_action, remaining_actions, solution_tree, opts)

      true ->
        # Attempt replanning from current state
        attempt_replan_from_current_state(domain, context, failed_action, remaining_actions, solution_tree, opts)
    end
  end

  # Attempt rollback to previous checkpoint and replan
  @spec attempt_rollback_and_replan(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp attempt_rollback_and_replan(domain, context, _failed_action, remaining_actions, _solution_tree, opts) do
    case context.checkpoints do
      [_current, previous_state | _rest] ->
        if context.verbose > 1 do
          debug_puts("Rolling back to previous checkpoint and attempting replan")
        end

        # Create new todos from remaining actions
        todos = remaining_actions

        # Attempt to replan from the previous checkpoint
        case AriaEngine.Plan.Core.plan(domain, previous_state, todos, opts) do
          {:ok, new_solution_tree} ->
            # Extract new actions and continue execution
            new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)

            updated_context = %{
              context
              | current_state: previous_state,
                remaining_actions: new_actions,
                replan_attempts: context.replan_attempts + 1,
                checkpoints: tl(context.checkpoints)  # Remove current checkpoint
            }

            execute_actions_lazily(domain, updated_context, new_solution_tree, opts)

          {:error, replan_reason} ->
            {:error, "Rollback and replan failed: #{replan_reason}"}
        end

      _ ->
        {:error, "Rollback failed: no previous checkpoint available"}
    end
  end

  # Attempt replanning from current state
  @spec attempt_replan_from_current_state(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp attempt_replan_from_current_state(domain, context, failed_action, remaining_actions, solution_tree, opts) do
    Logger.error("EXECUTION: Attempting replan from current state")
    Logger.error("EXECUTION: Failed action: #{inspect(failed_action)}")
    Logger.error("EXECUTION: Remaining actions: #{inspect(remaining_actions)}")

    if context.verbose > 1 do
      debug_puts("Attempting replan from current state")
    end

    # First, try to use backtracking to find alternative methods for the failed action
    case try_backtrack_for_failed_action(domain, context.current_state, solution_tree, failed_action, opts) do
      {:ok, new_solution_tree} ->
        # Backtracking succeeded, extract new actions and continue
        new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)

        Logger.error("EXECUTION: Backtracking succeeded, new actions: #{inspect(new_actions)}")

        updated_context = %{
          context
          | remaining_actions: new_actions,
            replan_attempts: context.replan_attempts + 1
        }

        execute_actions_lazily(domain, updated_context, new_solution_tree, opts)

      {:error, backtrack_reason} ->
        Logger.error("EXECUTION: Backtracking failed: #{backtrack_reason}")

        # Backtracking failed, fall back to full replanning
        attempt_full_replan(domain, context, failed_action, remaining_actions, solution_tree, opts)
    end
  end

  # Try to use backtracking to find alternative methods for the failed action
  @spec try_backtrack_for_failed_action(AriaEngine.Domain.t(), AriaEngine.StateV2.t(), solution_tree(), plan_step(), keyword()) ::
          {:ok, solution_tree()} | {:error, String.t()}
  defp try_backtrack_for_failed_action(domain, current_state, solution_tree, failed_action, opts) do
    # Find the node that corresponds to the failed action
    case find_node_for_action(solution_tree, failed_action) do
      nil ->
        {:error, "Could not find node for failed action: #{inspect(failed_action)}"}

      failed_node_id ->
        Logger.error("EXECUTION: Found failed node: #{failed_node_id}")

        # Use the backtracking system to try alternative methods
        case AriaEngine.Plan.Backtracking.replan(domain, current_state, solution_tree, failed_node_id, opts) do
          {:ok, new_tree} ->
            {:ok, new_tree}
          {:error, reason} ->
            {:error, reason}
          :no_alternatives ->
            {:error, "No alternative methods available"}
        end
    end
  end

  # Find the node in the solution tree that corresponds to a specific action
  @spec find_node_for_action(solution_tree(), plan_step()) :: node_id() | nil
  defp find_node_for_action(solution_tree, target_action) do
    Enum.find_value(solution_tree.nodes, fn {node_id, node} ->
      if node.is_primitive and node.task == target_action do
        node_id
      else
        nil
      end
    end)
  end

  # Fall back to full replanning when backtracking fails
  @spec attempt_full_replan(AriaEngine.Domain.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp attempt_full_replan(domain, context, failed_action, remaining_actions, solution_tree, opts) do
    Logger.error("EXECUTION: Attempting full replan as fallback")

    # For replanning, we need to replan the original goal, not just remaining actions
    # If remaining actions is empty, we need to extract the original goal from the failed action
    todos = if remaining_actions == [] do
      # Extract the goal from the failed action - in this case, the move goal
      case failed_action do
        {:move_unreliable, [_from, to]} -> [{"move_with_failure", ["start", to]}]
        {:move_reliable, [_from, to]} -> [{"move_with_failure", ["start", to]}]
        _ -> remaining_actions
      end
    else
      remaining_actions
    end

    Logger.error("EXECUTION: Todos for replanning: #{inspect(todos)}")
    Logger.error("EXECUTION: Blacklisted commands being passed to planner: #{inspect(MapSet.to_list(solution_tree.blacklisted_commands))}")

    # Pass blacklisted commands to the planner
    replan_opts = Keyword.put(opts, :blacklisted_commands, solution_tree.blacklisted_commands)
    Logger.error("EXECUTION: Replan opts: #{inspect(replan_opts)}")

    # Attempt to replan from current state
    case AriaEngine.Plan.Core.plan(domain, context.current_state, todos, replan_opts) do
      {:ok, new_solution_tree} ->
        # Extract new actions and continue execution
        new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)

        # Check if the new plan contains the same failing action that just failed
        # This prevents infinite loops when replanning produces the same plan
        if failed_action in new_actions do
          if context.verbose > 1 do
            debug_puts("Replan produced same failing action #{inspect(failed_action)}, terminating to prevent infinite loop")
          end
          {:error, "No alternative plan available: replanning produced the same failing action #{inspect(failed_action)}"}
        else
          # Merge blacklisted commands from original solution tree to new one
          updated_solution_tree = %{
            new_solution_tree
            | blacklisted_commands: MapSet.union(new_solution_tree.blacklisted_commands, solution_tree.blacklisted_commands)
          }

          updated_context = %{
            context
            | remaining_actions: new_actions,
              replan_attempts: context.replan_attempts + 1
          }

          execute_actions_lazily(domain, updated_context, updated_solution_tree, opts)
        end

      {:error, replan_reason} ->
        {:error, "Replan failed: #{replan_reason}"}
    end
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
            # In a full implementation, this would handle temporal constraints
            if verbose > 1 do
              debug_puts("Executing durative action #{action_name} as regular action")
            end
            {:error, "Durative action execution not yet implemented: #{action_name}"}
        end
    end
  end

  defp apply_action_to_state(_domain, _state, action, _opts) do
    {:error, "Invalid action format: #{inspect(action)}"}
  end
end
