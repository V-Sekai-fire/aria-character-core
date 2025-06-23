# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Default.StateV2Strategy do
  @moduledoc """
  Default State strategy implementation wrapping existing state management logic.

  This strategy encapsulates State operations while providing the clean
  strategy interface defined in ADR-091.
  """

  @behaviour HybridPlanner.Strategies.StateStrategy

  alias State
  require Logger

  @impl true
  def apply_action(%State{} = state, {action_name, args}, domain, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("StateV2Strategy: Applying action #{action_name} with args #{inspect(args)}")
    end

    try do
      # Get action function from domain
      case Map.get(domain.actions, action_name) do
        action_fn when is_function(action_fn) ->
          case apply(action_fn, [state | args]) do
            %State{} = new_state ->
              if verbose > 1 do
                Logger.debug("StateV2Strategy: Action applied successfully")
              end

              {:ok, new_state}

            other ->
              error_msg = "Action #{action_name} returned invalid state: #{inspect(other)}"
              Logger.error(error_msg)
              {:error, error_msg}
          end

        nil ->
          error_msg = "Action #{action_name} not found in domain"
          {:error, error_msg}
      end
    rescue
      e ->
        error_msg = "StateV2Strategy action application error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def query_state(%State{} = state, query, _opts \\ []) do
    try do
      case query do
        {:fact, subject, predicate} ->
          result = State.get_fact(state, subject, predicate)
          {:ok, result}

        {:facts, predicate} ->
          result = State.get_subjects_with_predicate(state, predicate)
          {:ok, result}

        {:all_facts} ->
          {:ok, state.data}

        _ ->
          {:error, "Unknown query type: #{inspect(query)}"}
      end
    rescue
      e ->
        {:error, "StateV2Strategy query error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def create_checkpoint(%State{} = state, checkpoint_id, _opts \\ []) do
    try do
      # Simple checkpoint by storing state data with special checkpoint key
      checkpoint_key = {"__checkpoint__", checkpoint_id}

      checkpointed_state = %State{
        data: Map.put(state.data, checkpoint_key, state.data)
      }

      {:ok, checkpointed_state}
    rescue
      e ->
        {:error, "StateV2Strategy checkpoint error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def rollback_to_checkpoint(%State{} = state, checkpoint_id, _opts \\ []) do
    try do
      checkpoint_key = {"__checkpoint__", checkpoint_id}

      case Map.get(state.data, checkpoint_key) do
        nil ->
          {:error, "Checkpoint #{checkpoint_id} not found"}

        saved_data ->
          restored_state = %State{data: saved_data}
          {:ok, restored_state}
      end
    rescue
      e ->
        {:error, "StateV2Strategy rollback error: #{Exception.message(e)}"}
    end
  end

  def strategy_info do
    %{
      name: "State Strategy",
      version: "1.0.0",
      description: "Default State state management strategy",
      capabilities: [:fact_storage, :action_application, :state_querying, :checkpointing],
      underlying_implementation: "State"
    }
  end
end
