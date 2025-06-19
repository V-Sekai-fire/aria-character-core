# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Execution do
  @moduledoc """
  Functions for executing the planned solution using Run-Lazy-Refineahead.
  """
  
  require Logger
  alias Plan.{Backtracking, Blacklisting, Core} # Added Core alias
  alias AriaEngine.Plan.Utils

  @type node_id :: String.t()
  @type solution_node :: %{
    id: node_id(),
    task: term(), # Using term() as task type is defined in Core
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
  Run-Lazy-Refineahead: Execute plan with replanning on failure.
  """
  @spec run_lazy_refineahead(Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
    {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def run_lazy_refineahead(%Domain.Core{} = domain, %AriaEngine.StateV2{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    if verbose > 2 do
      debug_puts("Starting Run-Lazy-Refineahead execution")
    end

    # Initialize execution state
    current_state = initial_state
    current_tree = solution_tree

    # Main execution loop
    run_execution_loop(domain, current_state, current_tree, opts)
  end

  # Run execution loop for Run-Lazy-Refineahead
  @spec run_execution_loop(Domain.Core.t(), AriaEngine.StateV2.t(), solution_tree(), keyword()) ::
    {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp run_execution_loop(domain, current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    # Get primitive actions from the solution tree
    actions = Utils.get_primitive_actions_dfs(solution_tree)

    if verbose > 1 do
      debug_puts("Executing #{length(actions)} primitive actions")
    end

    # Execute actions one by one with lazy checking
    execute_actions_lazily(domain, current_state, actions, solution_tree, opts)
  end

  # Execute actions with lazy failure checking and replanning
  @spec execute_actions_lazily(Domain.Core.t(), AriaEngine.StateV2.t(), [plan_step()], solution_tree(), keyword()) ::
    {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  defp execute_actions_lazily(_domain, state, [], _solution_tree, _opts) do
    {:ok, state}
  end

  defp execute_actions_lazily(domain, state, [action | remaining_actions], solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    {action_name, args} = action
    action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

    if verbose > 2 do
      debug_puts("Executing action: #{action_name}(#{inspect(args)})")
    end

    case Domain.execute_action(domain, state, action_atom, args) do
      {:ok, new_state} ->
        # Action succeeded, continue with remaining actions
        execute_actions_lazily(domain, new_state, remaining_actions, solution_tree, opts)

      false ->
        # Action failed - trigger replanning (Run-Lazy-Refineahead core feature)
        if verbose > 2 do
          debug_puts("Action failed: #{action_name}, attempting replanning...")
        end

        # Find the failing node in the solution tree
        case find_action_node(solution_tree, action) do
          nil ->
            {:error, "Action execution failed: #{action_name} (node not found for replanning)"}

          fail_node_id ->
            # Blacklist the failed command to prevent trying it again
            updated_tree = Blacklisting.blacklist_command(solution_tree, {action_name, args})

            # Attempt replanning from the failure point
            case Backtracking.replan(domain, state, updated_tree, fail_node_id, opts) do
              {:ok, new_solution_tree} ->
                # Get new action sequence from replanned tree
                new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)

                if verbose > 1 do
                  debug_puts("Replanning succeeded, executing #{length(new_actions)} new actions")
                end

                # Execute the new plan
                execute_actions_lazily(domain, state, new_actions, new_solution_tree, opts)

              {:error, reason} ->
                {:error, "Replanning failed: #{reason}"}
            end
        end
    end
  end

  # Find the node ID corresponding to a specific action in the solution tree
  @spec find_action_node(solution_tree(), plan_step()) :: node_id() | nil
  defp find_action_node(solution_tree, target_action) do
    Enum.find_value(solution_tree.nodes, fn {node_id, node} ->
      if node.is_primitive and node.expanded and node.task == target_action do
        node_id
      else
        nil
      end
    end)
  end
end
