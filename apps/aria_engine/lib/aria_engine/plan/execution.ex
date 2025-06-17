# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Execution do
  @moduledoc """
  Functions for executing the planned solution using Run-Lazy-Refineahead.
  """
  alias AriaEngine.{Domain, State}
  alias AriaEngine.Plan.{Backtracking, Utils, Blacklisting, Core} # Added Core alias

  @type node_id :: String.t()
  @type solution_node :: %{
    id: node_id(),
    task: term(), # Using term() as task type is defined in Core
    parent_id: node_id() | nil,
    children_ids: [node_id()],
    state: State.t() | nil,
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

  # @default_verbose 0 # Removed this module attribute

  @doc """
  Run-Lazy-Refineahead: Execute plan with replanning on failure.
  """
  @spec run_lazy_refineahead(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  def run_lazy_refineahead(%AriaEngine.Domain.Core{} = domain, %State{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    if verbose > 2 do
      IO.puts("Starting Run-Lazy-Refineahead execution")
    end

    # Initialize execution state
    current_state = initial_state
    current_tree = solution_tree

    # Main execution loop
    run_execution_loop(domain, current_state, current_tree, opts)
  end

  # Run execution loop for Run-Lazy-Refineahead
  @spec run_execution_loop(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  defp run_execution_loop(domain, current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    # Get primitive actions from the solution tree
    actions = Utils.get_primitive_actions_dfs(solution_tree)

    if verbose > 1 do
      IO.puts("Executing #{length(actions)} primitive actions")
    end

    # Execute actions one by one with lazy checking
    execute_actions_lazily(domain, current_state, actions, solution_tree, opts)
  end

  # Execute actions with lazy failure checking and replanning
  @spec execute_actions_lazily(AriaEngine.Domain.Core.t(), State.t(), [plan_step()], solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  defp execute_actions_lazily(_domain, state, [], _solution_tree, _opts) do
    {:ok, state}
  end

  defp execute_actions_lazily(domain, state, [action | remaining_actions], solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Get from Core

    {action_name, args} = action
    action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

    if verbose > 2 do
      IO.puts("Executing action: #{action_name}(#{inspect(args)})")
    end

    case Domain.execute_action(domain, state, action_atom, args) do
      {:ok, new_state} ->
        # Action succeeded, continue with remaining actions
        execute_actions_lazily(domain, new_state, remaining_actions, solution_tree, opts)

      false ->
        # Action failed - trigger replanning (Run-Lazy-Refineahead core feature)
        if verbose > 2 do
          IO.puts("Action failed: #{action_name}, attempting replanning...")
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
                  IO.puts("Replanning succeeded, executing #{length(new_actions)} new actions")
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
