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
  alias Timex

  @type plan_step :: {atom() | String.t(), list()}
  @type execution_trace_entry :: {plan_step() | nil, map() | nil}
  @type execution_trace :: [execution_trace_entry()]
  @type execution_result :: {:ok, map(), execution_trace()} | {:error, String.t(), execution_trace()}

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

  """
  @spec execute(map(), map(), [plan_step()], keyword()) :: execution_result()
  def execute(domain, initial_state, plan, opts \\ []) do
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
    Plan.Utils.get_primitive_actions_dfs(solution_tree)
  end

  # Private implementation functions

  @spec execute_steps(map(), map(), [plan_step()], execution_trace(), keyword()) :: execution_result()
  defp execute_steps(_domain, current_state, [], execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("SimpleExecutor: Execution completed successfully")
    end

    {:ok, current_state, Enum.reverse(execution_trace)}
  end

  # Validate that required entities are available and have necessary capabilities
  @spec validate_required_entities(map(), map(), list(), keyword()) :: :ok | {:error, String.t()}
  defp validate_required_entities(_state, _entity_registry, [], _opts) do
    # No entity requirements, validation passes
    :ok
  end

  # Check if an entity is available (not busy)
  @spec entity_available?(map(), String.t()) :: boolean()
  def entity_available?(state, entity_id) do
    AriaEngineCore.has_subject?(state, "status", entity_id) and AriaEngineCore.get_fact(state, "status", entity_id) == "available"
  end
end
