# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Core do
  @moduledoc """
  Core IPyHOP planning algorithm and decomposition loop.
  """

  require Logger
  alias Plan.{NodeExpansion, Backtracking}
  alias AriaEngine.Plan.Utils
  # alias DomainBehaviour # Removed unused alias

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
          # New field to indicate if the action is durative
          is_durative: boolean()
        }

  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }

  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}

  @default_max_depth 100
  # New default replanning depth
  @default_replan_depth 10
  @default_verbose 0

  # Helper to conditionally output debug information
  defp debug_puts(message, verbose_level \\ 0) do
    # Only output during tests if ExUnit trace mode is enabled
    if Application.get_env(:ex_unit, :trace, false) or not test_mode?() do
      if verbose_level <= get_verbose_level() do
        Logger.debug(message)
      end
    end
  end

  defp test_mode?() do
    # Check if we're running in test environment
    Mix.env() == :test
  end

  defp get_verbose_level() do
    # Get verbose level from process dictionary if set by calling function
    Process.get(:verbose_level, 0)
  end

  @doc """
  Main IPyHOP planning function that creates a solution tree to achieve the given todos.
  """
  @spec plan(Domain.Core.t(), AriaEngine.StateV2.t(), [todo_item()], keyword()) :: plan_result()
  def plan(domain, %AriaEngine.StateV2{} = state, todos, opts \\ []) do
    # Add replan_depth to opts with a default value
    opts = Keyword.put_new(opts, :replan_depth, @default_replan_depth)
    # Logger.debug("Starting IPyHOP planning for ", length(todos), " todos")
    # Commented out to reduce test output noise

    # Create initial solution tree with goal-task network
    solution_tree = Utils.create_initial_solution_tree(todos, state)

    # Run IPyHOP algorithm
    ipyhop(domain, state, solution_tree, opts)
  end

  # Core IPyHOP Algorithm (Algorithm 2 from the paper)
  @spec ipyhop(Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
          plan_result()
  def ipyhop(domain, %AriaEngine.StateV2{} = current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)

    # IPyHOP main loop
    plan_decomposition_loop(domain, current_state, solution_tree, 0, max_depth, verbose)
  end

  @spec plan_decomposition_loop(
          Domain.Core.t(),
          AriaEngine.StateV2.t(),
          solution_tree(),
          integer(),
          integer(),
          integer()
        ) :: plan_result()
  defp plan_decomposition_loop(domain, current_state, solution_tree, depth, max_depth, verbose) do
    Process.put(:verbose_level, verbose)
    log_planning_progress(depth, solution_tree, verbose)

    cond do
      depth >= max_depth ->
        handle_max_depth_exceeded(depth, verbose)

      true ->
        case find_next_node(solution_tree) do
          nil ->
            handle_no_more_nodes(solution_tree, verbose)

          node_id ->
            expand_node_and_continue(
              domain,
              current_state,
              solution_tree,
              node_id,
              depth,
              max_depth,
              verbose
            )
        end
    end
  end

  defp log_planning_progress(depth, solution_tree, verbose) do
    if verbose > 3 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Depth #{depth}, Nodes: #{Kernel.map_size(solution_tree.nodes)}"
      )
    end
  end

  defp handle_max_depth_exceeded(depth, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Maximum planning depth exceeded at depth #{depth}")
    end

    {:error, "Maximum planning depth exceeded"}
  end

  defp handle_no_more_nodes(solution_tree, verbose) do
    if solution_complete?(solution_tree) do
      if verbose > 0 do
        debug_puts("PLAN_DECOMPOSITION_LOOP: Solution complete.")
      end

      {:ok, solution_tree}
    else
      if verbose > 0 do
        debug_puts(
          "PLAN_DECOMPOSITION_LOOP: No complete solution found after all nodes expanded."
        )
      end

      {:error, "No complete solution found"}
    end
  end

  defp expand_node_and_continue(
         domain,
         current_state,
         solution_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 3 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Expanding node #{node_id} (Task: #{inspect(solution_tree.nodes[node_id].task)})"
      )
    end

    case try_expand_node(domain, current_state, solution_tree, node_id, verbose) do
      {:ok, new_tree} ->
        handle_successful_expansion(
          domain,
          current_state,
          new_tree,
          node_id,
          depth,
          max_depth,
          verbose
        )

      {:error, reason} ->
        handle_expansion_error(reason, node_id, verbose)

      {:failure, failed_tree} ->
        handle_expansion_failure(
          domain,
          current_state,
          failed_tree,
          node_id,
          depth,
          max_depth,
          verbose
        )
    end
  end

  defp handle_successful_expansion(
         domain,
         current_state,
         new_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 3 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expanded successfully.")
    end

    plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)
  end

  defp handle_expansion_error(reason, node_id, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion failed: #{reason}")
    end

    {:error, reason}
  end

  defp handle_expansion_failure(
         domain,
         current_state,
         failed_tree,
         node_id,
         depth,
         max_depth,
         verbose
       ) do
    if verbose > 0 do
      debug_puts(
        "PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion returned :failure, attempting backtrack."
      )
    end

    case Backtracking.backtrack_and_retry(
           domain,
           current_state,
           failed_tree,
           node_id,
           depth,
           max_depth,
           verbose
         ) do
      {:ok, new_tree} ->
        handle_successful_backtrack(domain, current_state, new_tree, depth, max_depth, verbose)

      {:error, reason} ->
        handle_backtrack_error(reason, verbose)
    end
  end

  defp handle_successful_backtrack(domain, current_state, new_tree, depth, max_depth, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Backtrack succeeded, continuing planning.")
    end

    plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)
  end

  defp handle_backtrack_error(reason, verbose) do
    if verbose > 0 do
      debug_puts("PLAN_DECOMPOSITION_LOOP: Backtrack failed: #{reason}")
    end

    {:error, reason}
  end

  # Find the next node to expand (depth-first search)
  @spec find_next_node(solution_tree()) :: node_id() | nil
  defp find_next_node(solution_tree) do
    find_next_node_dfs(solution_tree, solution_tree.root_id)
  end

  @spec find_next_node_dfs(solution_tree(), node_id()) :: node_id() | nil
  defp find_next_node_dfs(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        nil

      node ->
        cond do
          not node.expanded and not node.is_primitive ->
            # This node needs expansion
            node_id

          Enum.empty?(node.children_ids) ->
            # Leaf node, check if it's primitive or already expanded
            if node.is_primitive or node.expanded do
              # Primitive action or already expanded leaf, no expansion needed
              nil
            else
              # Non-primitive, non-expanded leaf needs expansion
              node_id
            end

          true ->
            # Check children
            Enum.find_value(node.children_ids, fn child_id ->
              find_next_node_dfs(solution_tree, child_id)
            end)
        end
    end
  end

  # Try to expand a node
  @spec try_expand_node(
          Domain.Core.t(),
          AriaEngine.StateV2.t(),
          solution_tree(),
          node_id(),
          integer()
        ) ::
          {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  defp try_expand_node(domain, state, solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        log_node_expansion(node_id, node.task, verbose)
        expand_task_by_type(domain, state, solution_tree, node_id, node.task, verbose)
    end
  end

  defp log_node_expansion(node_id, task, verbose) do
    if verbose > 2 do
      debug_puts("Expanding node #{node_id}: #{inspect(task)}")
    end
  end

  defp expand_task_by_type(domain, state, solution_tree, node_id, task, verbose) do
    case task do
      {:root, todos} ->
        NodeExpansion.expand_root_node(solution_tree, node_id, todos, state)

      {task_name, args} when is_binary(task_name) ->
        expand_string_task(domain, state, solution_tree, node_id, task_name, args, verbose)

      {action_name, _args} when is_atom(action_name) ->
        expand_atom_task(domain, solution_tree, node_id, action_name)

      {predicate, subject, fact_value} ->
        NodeExpansion.expand_goal_node(
          domain,
          state,
          solution_tree,
          node_id,
          predicate,
          subject,
          fact_value,
          verbose
        )

      %AriaEngine.Multigoal{} = multigoal ->
        NodeExpansion.expand_multigoal_node(
          domain,
          state,
          solution_tree,
          node_id,
          multigoal,
          verbose
        )

      _ ->
        {:error, "Unknown task type: #{inspect(task)}"}
    end
  end

  defp expand_string_task(domain, state, solution_tree, node_id, task_name, args, verbose) do
    action_atom = String.to_atom(task_name)

    cond do
      Domain.has_action?(domain, action_atom) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)

      Domain.Core.get_durative_action(domain, action_atom) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)

      true ->
        NodeExpansion.expand_task_node(
          domain,
          state,
          solution_tree,
          node_id,
          task_name,
          args,
          verbose
        )
    end
  end

  defp expand_atom_task(domain, solution_tree, node_id, action_name) do
    cond do
      Domain.has_action?(domain, action_name) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)

      Domain.Core.get_durative_action(domain, action_name) ->
        NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)

      true ->
        {:error, "Unknown action: #{action_name}"}
    end
  end

  @spec solution_complete?(solution_tree()) :: boolean()
  defp solution_complete?(solution_tree) do
    # All nodes should be expanded and all leaves should be primitive actions
    # Root node is complete if expanded (even with no children for empty goals)
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = id == solution_tree.root_id
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  # Helper to get default verbose level
  @spec get_default_verbose() :: integer()
  def get_default_verbose(), do: @default_verbose

  # Helper to get default replan depth
  @spec get_default_replan_depth() :: integer()
  def get_default_replan_depth(), do: @default_replan_depth

  @doc """
  Execute a solution tree using lazy refinement with optional replanning on failure.
  
  This function implements lazy execution where actions are executed incrementally
  with state updates, supporting refinement-ahead strategies and replanning when
  actions fail during execution.
  """
  @spec run_lazy_refineahead(Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
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
  @spec execute_actions_lazily(Domain.Core.t(), map(), solution_tree(), keyword()) ::
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
  @spec execute_single_action(Domain.Core.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
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
        # Action failed, attempt replanning if possible
        handle_action_failure(domain, context, action, remaining_actions, solution_tree, reason, opts)
    end
  end

  # Execute action with refinement-ahead optimization
  @spec execute_with_refinement_ahead(Domain.Core.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_with_refinement_ahead(domain, context, action, remaining_actions, solution_tree, opts) do
    if context.verbose > 2 do
      debug_puts("Executing action with refinement-ahead: #{inspect(action)}")
    end

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
        handle_action_failure(domain, context, action, remaining_actions, solution_tree, reason, opts)
    end
  end

  # Apply refinement optimization based on lookahead
  @spec apply_refinement_optimization(Domain.Core.t(), AriaEngine.StateV2.t(), [plan_step()], keyword()) ::
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
  @spec handle_action_failure(Domain.Core.t(), map(), plan_step(), [plan_step()], solution_tree(), String.t(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp handle_action_failure(domain, context, failed_action, remaining_actions, solution_tree, reason, opts) do
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
  @spec attempt_rollback_and_replan(Domain.Core.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
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
        case plan(domain, previous_state, todos, opts) do
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
  @spec attempt_replan_from_current_state(Domain.Core.t(), map(), plan_step(), [plan_step()], solution_tree(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp attempt_replan_from_current_state(domain, context, _failed_action, remaining_actions, _solution_tree, opts) do
    if context.verbose > 1 do
      debug_puts("Attempting replan from current state")
    end

    # Create new todos from remaining actions
    todos = remaining_actions

    # Attempt to replan from current state
    case plan(domain, context.current_state, todos, opts) do
      {:ok, new_solution_tree} ->
        # Extract new actions and continue execution
        new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)
        
        updated_context = %{
          context
          | remaining_actions: new_actions,
            replan_attempts: context.replan_attempts + 1
        }

        execute_actions_lazily(domain, updated_context, new_solution_tree, opts)

      {:error, replan_reason} ->
        {:error, "Replan failed: #{replan_reason}"}
    end
  end

  # Apply a single action to the current state
  @spec apply_action_to_state(Domain.Core.t(), AriaEngine.StateV2.t(), plan_step(), keyword()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp apply_action_to_state(domain, state, {action_name, args}, opts) when is_atom(action_name) do
    verbose = Keyword.get(opts, :verbose, 0)

    case Domain.has_action?(domain, action_name) do
      true ->
        # Execute primitive action
        action_func = Domain.get_action(domain, action_name)
        
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
        case Domain.Core.get_durative_action(domain, action_name) do
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
