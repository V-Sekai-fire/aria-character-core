# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.StrategyRegistry do
  @moduledoc """
  Registry of planning strategy functions that can be composed at runtime.

  Pure Function as Object implementation following Martin Fowler's pattern.
  All strategies are functions that can be stored, passed around, and composed
  without requiring complex object hierarchies.

  ## Function Signatures

  All strategy functions follow consistent signatures for composability:

  - Planning strategies: `(Domain.t(), AriaEngine.StateV2.t(), [term()], keyword()) -> {:ok, term()} | {:error, String.t()}`
  - Temporal strategies: `(term(), Domain.t(), keyword()) -> {:ok, term()} | {:error, String.t()}`
  - Execution strategies: `(Domain.t(), AriaEngine.StateV2.t(), term(), keyword()) -> {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}`

  ## Usage

      strategies = StrategyRegistry.default_strategies()
      planning_fn = strategies.planning.htn
      temporal_fn = strategies.temporal.stn
      execution_fn = strategies.execution.lazy

      # Compose them in a coordinator
      coordinator = StrategyCoordinator.new(planning_fn, temporal_fn, execution_fn)
  """


  # Strategy function type definitions
  @type planning_strategy :: (Domain.Core.t(), AriaEngine.StateV2.t(), [term()], keyword() ->
                                {:ok, term()} | {:error, String.t()})
  @type temporal_strategy :: (term(), Domain.Core.t(), keyword() ->
                                {:ok, term()} | {:error, String.t()})
  @type execution_strategy :: (Domain.Core.t(), AriaEngine.StateV2.t(), term(), keyword() ->
                                 {:ok, AriaEngine.StateV2.t()} | {:error, String.t()})

  @type strategy_map :: %{
          planning: %{atom() => planning_strategy()},
          temporal: %{atom() => temporal_strategy()},
          execution: %{atom() => execution_strategy()}
        }

  @doc """
  Get the default registry of strategy functions.

  Returns a map of strategy categories, each containing named function strategies.
  """
  @spec default_strategies() :: strategy_map()
  def default_strategies() do
    %{
      planning: %{
        htn: &htn_planning_strategy/4,
      },
      temporal: %{
        stn: &stn_temporal_strategy/3,
        csp: &csp_temporal_strategy/3,
        none: &no_temporal_strategy/3
      },
      execution: %{
        lazy: &lazy_execution_strategy/4,
        streaming: &streaming_execution_strategy/4
      }
    }
  end

  @doc """
  Register a custom strategy function.
  """
  @spec register_strategy(strategy_map(), atom(), atom(), function()) :: strategy_map()
  def register_strategy(strategies, category, name, strategy_fn) do
    put_in(strategies, [category, name], strategy_fn)
  end

  @doc """
  Get a specific strategy function by category and name.
  """
  @spec get_strategy(strategy_map(), atom(), atom()) :: {:ok, function()} | {:error, String.t()}
  def get_strategy(strategies, category, name) do
    case get_in(strategies, [category, name]) do
      nil -> {:error, "Strategy #{category}.#{name} not found"}
      strategy_fn -> {:ok, strategy_fn}
    end
  end

  @doc """
  Create a function pipeline for enhanced strategy composition.
  """
  @spec create_pipeline([function()]) :: function()
  def create_pipeline(functions) when is_list(functions) do
    fn input ->
      Enum.reduce_while(functions, {:ok, input}, fn func, {:ok, acc} ->
        case func.(acc) do
          {:ok, result} -> {:cont, {:ok, result}}
          error -> {:halt, error}
        end
      end)
    end
  end

  # ==================== PLANNING STRATEGIES ====================

  @doc false
  def htn_planning_strategy(domain, state, goals, opts) do
    # Delegate to existing HTN implementation
    Plan.plan(domain, state, goals, opts)
  end

  # ==================== TEMPORAL STRATEGIES ====================

  @doc false
  def stn_temporal_strategy(plan, _domain, _opts) do
    # STN temporal validation using AriaEngine.Timeline
    # For now, just pass through - full STN validation will be implemented
    # when Timeline integration is complete
    {:ok, plan}
  end

  @doc false
  def csp_temporal_strategy(plan, _domain, _opts) do
    # Future: CSP-based temporal validation
    # For now, just pass through
    {:ok, plan}
  end

  @doc false
  def no_temporal_strategy(plan, _domain, _opts) do
    # No temporal validation - just pass through
    {:ok, plan}
  end

  # ==================== EXECUTION STRATEGIES ====================

  @doc false
  def lazy_execution_strategy(domain, state, plan, _opts) do
    # Use plan validation for execution
    Plan.validate_plan(domain, state, plan)
  end

  @doc false
  def streaming_execution_strategy(domain, state, plan, _opts) do
    # Future: Streaming execution with live updates
    # For now, delegate to plan validation
    Plan.validate_plan(domain, state, plan)
  end

end
