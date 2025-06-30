# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Execution do
  @moduledoc """
  Plan execution functions for HybridCoordinatorV2.

  Handles IPyHOP-style simple execution and blacklist state management.
  """

  require Logger
  alias Plan.Utils

  @doc """
  Execute a plan using IPyHOP-style simple execution.

  This function integrates with the new blacklisting system following
  the IPyHOP pattern where blacklisted commands are checked during execution.
  """
  @spec execute_plan_lazy(map(), State.t(), keyword()) ::
          {:ok, State.t()} | {:error, String.t()}
  def execute_plan_lazy(solution_tree, initial_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      action_count = Utils.plan_cost(solution_tree)
      Logger.debug("IPyHOP execution: Starting execution of plan with #{action_count} actions")
    end

    try do
      domain = Keyword.get(opts, :domain)

      case domain do
        nil ->
          {:error, "Domain required for execution but not provided in options"}

        %Domain.Core{} = domain ->
          # Extract primitive actions from solution tree
          primitive_actions = Plan.SimpleExecutor.extract_primitive_actions(solution_tree)

          if verbose > 1 do
            Logger.debug("IPyHOP execution: Executing #{length(primitive_actions)} primitive actions")
          end

          # Execute using simple IPyHOP-style executor
          case Plan.SimpleExecutor.execute(domain, initial_state, primitive_actions, opts) do
            {:ok, final_state, execution_trace} ->
              if verbose > 1 do
                Logger.debug("IPyHOP execution: Execution completed successfully")
                if verbose > 2 do
                  Logger.debug("IPyHOP execution: Execution trace length: #{length(execution_trace)}")
                end
              end
              {:ok, final_state}

            {:error, reason, execution_trace} ->
              if verbose > 0 do
                Logger.warning("IPyHOP execution: Execution failed - #{reason}")
                if verbose > 2 do
                  Logger.debug("IPyHOP execution: Failure trace length: #{length(execution_trace)}")
                end
              end
              {:error, reason}
          end

        _ ->
          {:error, "Invalid domain type provided for execution"}
      end
    rescue
      e ->
        error_msg = "IPyHOP execution error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Extract or create blacklist state for execution.
  """
  @spec get_or_create_blacklist_state(map(), keyword()) :: term()
  def get_or_create_blacklist_state(plan, opts) do
    # Check if blacklist state is provided in options first
    case Keyword.get(opts, :blacklist_state) do
      nil ->
        # Try to extract from plan metadata
        case get_in(plan, [:metadata, :blacklist_state]) do
          nil ->
            # Create new blacklist state following IPyHOP pattern
            Plan.Blacklisting.new()

          existing_blacklist_state ->
            existing_blacklist_state
        end

      provided_blacklist_state ->
        provided_blacklist_state
    end
  end
end
