# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.SimpleExecutor do
  @moduledoc """
  Simple IPyHOP-style executor following the MonteCarloExecutor pattern.

  This executor implements the IPyHOP execution pattern:
  - Linear execution through plan steps
  - Fail-fast on action failures
  - Return execution trace for debugging
  - No internal backtracking or replanning

  Based on IPyHOP's MonteCarloExecutor from thirdparty/IPyHOP/ipyhop/mc_executor.py
  """

  require Logger
  alias AriaEngine.State

  @type plan_step :: {atom() | String.t(), list()}
  @type execution_trace_entry :: {plan_step() | nil, State.t() | nil}
  @type execution_trace :: [execution_trace_entry()]
  @type execution_result :: {:ok, State.t(), execution_trace()} | {:error, String.t(), execution_trace()}

  @doc """
  Execute a plan using simple linear execution with fail-fast behavior.

  This follows the IPyHOP MonteCarloExecutor pattern:
  1. Start with initial state in execution trace
  2. Execute each action in sequence
  3. Check for blacklisted commands (IPyHOP pattern)
  4. If action succeeds, add result to trace and continue
  5. If action fails, add failure to trace and return immediately
  6. Return final state and complete execution trace

  ## Parameters

  - `domain`: The domain containing action definitions
  - `initial_state`: Starting state for execution
  - `plan`: List of plan steps to execute
  - `opts`: Execution options (verbose, blacklist_state, etc.)

  ## Options

  - `:verbose` - Verbosity level (0-3)
  - `:blacklist_state` - Current blacklist state for command checking

  ## Returns

  - `{:ok, final_state, execution_trace}` on successful completion
  - `{:error, reason, execution_trace}` on failure (with trace up to failure point)

  ## Examples

      iex> plan = [{:move, ["agent1", "kitchen"]}, {:cook, ["pasta"]}]
      iex> Plan.SimpleExecutor.execute(domain, state, plan)
      {:ok, final_state, [
        {nil, initial_state},
        {{:move, ["agent1", "kitchen"]}, intermediate_state},
        {{:cook, ["pasta"]}, final_state}
      ]}

      # On failure:
      {:error, "action_failed", [
        {nil, initial_state},
        {{:move, ["agent1", "kitchen"]}, intermediate_state},
        {{:cook, ["pasta"]}, nil}  # nil indicates failure
      ]}

      # With blacklisted command:
      {:error, "command_blacklisted", [
        {nil, initial_state},
        {{:move, ["agent1", "kitchen"]}, nil}  # nil indicates blacklist failure
      ]}
  """
  @spec execute(AriaEngine.Domain.Core.t(), State.t(), [plan_step()], keyword()) :: execution_result()
  def execute(domain, %State{} = initial_state, plan, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("SimpleExecutor: Starting execution of #{length(plan)} actions")
    end

    # Initialize execution trace with initial state (following IPyHOP pattern)
    initial_trace = [{nil, initial_state}]

    # Execute plan steps linearly with blacklist checking
    execute_steps(domain, initial_state, plan, initial_trace, opts)
  end

  @doc """
  Extract primitive actions from a solution tree for execution.

  This is a utility function to convert solution trees to the simple
  plan format expected by the executor.
  """
  @spec extract_primitive_actions(map()) :: [plan_step()]
  def extract_primitive_actions(solution_tree) do
    AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
  end

  # Private implementation functions

  @spec execute_steps(AriaEngine.Domain.Core.t(), State.t(), [plan_step()], execution_trace(), keyword()) :: execution_result()
  defp execute_steps(_domain, current_state, [], execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("SimpleExecutor: Execution completed successfully")
    end

    {:ok, current_state, Enum.reverse(execution_trace)}
  end

  defp execute_steps(domain, current_state, [action | remaining_actions], execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    {action_name, args} = action

    # Convert action name to atom if needed
    action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

    if verbose > 2 do
      Logger.debug("SimpleExecutor: Executing action #{action_name}(#{inspect(args)})")
    end

    # Check if command is blacklisted (IPyHOP pattern)
    case check_command_blacklist(action, opts) do
      :ok ->
        # Command not blacklisted, proceed with execution
        execute_non_blacklisted_command(domain, current_state, action, action_atom, args, remaining_actions, execution_trace, opts)

      {:blacklisted, reason} ->
        # Command is blacklisted - fail immediately (IPyHOP pattern)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Command #{action_name} is blacklisted: #{reason}")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Command blacklisted: #{action_name} - #{reason}"
        {:error, error_message, Enum.reverse(failure_trace)}
    end
  end

  # Execute a command that is not blacklisted
  defp execute_non_blacklisted_command(domain, current_state, action, action_atom, args, remaining_actions, execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    {action_name, _args} = action

    # Execute the action using domain's command execution
    case execute_action_command(domain, current_state, action_atom, args, opts) do
      {:ok, new_state} ->
        # Action succeeded - add to trace and continue
        new_trace = [{action, new_state} | execution_trace]
        execute_steps(domain, new_state, remaining_actions, new_trace, opts)

      {:error, reason} ->
        # Action failed - add failure to trace and return immediately (fail-fast)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Action #{action_name} failed: #{reason}")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Action execution failed: #{action_name} - #{reason}"
        {:error, error_message, Enum.reverse(failure_trace)}

      false ->
        # Action returned false (IPyHOP-style failure)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Action #{action_name} returned false")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Action execution failed: #{action_name} - returned false"
        {:error, error_message, Enum.reverse(failure_trace)}
    end
  end

  # Check if a command is blacklisted following IPyHOP pattern
  defp check_command_blacklist(command, opts) do
    case Keyword.get(opts, :blacklist_state) do
      nil ->
        # No blacklist state provided, allow execution
        :ok

      blacklist_state ->
        # Check if command is blacklisted
        if Plan.Blacklisting.command_blacklisted?(blacklist_state, command) do
          {:blacklisted, "command previously failed during execution"}
        else
          :ok
        end
    end
  end

  @spec execute_action_command(AriaEngine.Domain.Core.t(), State.t(), atom(), list(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_action_command(domain, state, action_atom, args, _opts) do
    # Try to execute as a command first (ADR-181 compliance)
    command_name = String.to_atom("#{action_atom}_command")

    case AriaEngine.Domain.has_action?(domain, command_name) do
      true ->
        # Execute as command (execution-time logic with failure handling)
        AriaEngine.Domain.execute_action(domain, state, command_name, args)

      false ->
        # Fall back to action execution (planning-time logic)
        case AriaEngine.Domain.execute_action(domain, state, action_atom, args) do
          {:ok, new_state} -> {:ok, new_state}
          {:error, reason} -> {:error, reason}
          false -> false
          other -> {:error, "Unexpected action result: #{inspect(other)}"}
        end
    end
  end
end
