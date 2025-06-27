# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Execution do
  @moduledoc "Functions for executing the planned solution using Run-Lazy-Refineahead.\n"
  require Logger
  alias Plan.{Backtracking, Blacklisting, Core}
  alias AriaEngine.Plan.Utils
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
  @type plan_step :: {atom(), list()}
  defp debug_puts(message) do
    if Application.get_env(:ex_unit, :trace, false) or not test_mode?() do
      Logger.debug(message)
    end
  end

  defp test_mode?() do
    Mix.env() == :test
  end

  @doc "Run-Lazy-Refineahead: Execute plan with replanning on failure.\n"
  @spec run_lazy_refineahead(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def run_lazy_refineahead(
        %AriaEngine.Domain.Core{} = domain,
        %AriaEngine.State{} = initial_state,
        solution_tree,
        opts \\ []
      ) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose())

    if verbose > 2 do
      debug_puts("Starting Run-Lazy-Refineahead execution")
    end

    current_state = initial_state
    current_tree = solution_tree
    run_execution_loop(domain, current_state, current_tree, opts)
  end

  @spec run_execution_loop(AriaEngine.Domain.Core.t(), AriaEngine.State.t(), solution_tree(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  defp run_execution_loop(domain, current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose())
    actions = Utils.get_primitive_actions_dfs(solution_tree)

    if verbose > 1 do
      debug_puts("Executing #{length(actions)} primitive actions")
    end

    execute_actions_lazily(domain, current_state, actions, solution_tree, opts)
  end

  @spec execute_actions_lazily(
          AriaEngine.Domain.Core.t(),
          AriaEngine.State.t(),
          [plan_step()],
          solution_tree(),
          keyword()
        ) :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  defp execute_actions_lazily(_domain, state, [], _solution_tree, _opts) do
    {:ok, state}
  end

  defp execute_actions_lazily(domain, state, [action | remaining_actions], solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, Core.get_default_verbose())
    {action_name, args} = action

    action_atom =
      if is_binary(action_name) do
        String.to_atom(action_name)
      else
        action_name
      end

    if verbose > 2 do
      debug_puts("Executing action: #{action_name}(#{inspect(args)})")
    end

    case AriaEngine.Domain.execute_action(domain, state, action_atom, args) do
      {:ok, new_state} ->
        execute_actions_lazily(domain, new_state, remaining_actions, solution_tree, opts)

      false ->
        if verbose > 2 do
          debug_puts("Action failed: #{action_name}, attempting replanning...")
        end

        case find_action_node(solution_tree, action) do
          nil ->
            {:error, "Action execution failed: #{action_name} (node not found for replanning)"}

          fail_node_id ->
            updated_tree = Blacklisting.blacklist_command(solution_tree, {action_name, args})

            case Backtracking.replan(domain, state, updated_tree, fail_node_id, opts) do
              {:ok, new_solution_tree} ->
                new_actions = Utils.get_primitive_actions_dfs(new_solution_tree)

                if verbose > 1 do
                  debug_puts("Replanning succeeded, executing #{length(new_actions)} new actions")
                end

                execute_actions_lazily(domain, state, new_actions, new_solution_tree, opts)

              {:error, reason} ->
                {:error, "Replanning failed: #{reason}"}
            end
        end
    end
  end

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
