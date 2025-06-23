# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.Format.StrategyRequest do
  @moduledoc """
  Membrane format for strategy-specific planning requests.

  This format represents internal routing between different planning strategies
  within the planning bin, containing strategy-specific parameters and
  fallback configuration.

  Used for routing between HybridCoordinator, MiniZinc, and other strategies
  based on problem characteristics and strategy preferences.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W027SREQ"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  alias AriaEngine.Membrane.Format.PlanningParams

  defstruct [
    :planning_params,
    :strategy,
    :fallback_strategies,
    :execution_context,
    :strategy_config,
    :timeout_ms,
    :request_id,
    :routing_metadata
  ]

  @type strategy :: :hybrid_coordinator | :minizinc | :lazy_execution | :mock | :default

  @type execution_context :: %{
    attempt_number: pos_integer(),
    previous_failures: [String.t()],
    resource_constraints: map(),
    performance_hints: map()
  }

  @type t :: %__MODULE__{
          planning_params: PlanningParams.t(),
          strategy: strategy(),
          fallback_strategies: [strategy()],
          execution_context: execution_context(),
          strategy_config: map(),
          timeout_ms: pos_integer(),
          request_id: String.t(),
          routing_metadata: map()
        }

  @doc """
  Creates a new strategy request from planning parameters.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params,
      ...>   :hybrid_coordinator,
      ...>   [:minizinc, :mock]
      ...> )
      iex> request.strategy
      :hybrid_coordinator

  """
  @spec new(PlanningParams.t(), strategy(), [strategy()], keyword()) :: t()
  def new(planning_params, strategy, fallback_strategies, opts \\ []) do
    %__MODULE__{
      planning_params: planning_params,
      strategy: strategy,
      fallback_strategies: fallback_strategies,
      execution_context: Keyword.get(opts, :execution_context, %{
        attempt_number: 1,
        previous_failures: [],
        resource_constraints: %{},
        performance_hints: %{}
      }),
      strategy_config: Keyword.get(opts, :strategy_config, %{}),
      timeout_ms: Keyword.get(opts, :timeout_ms, 30_000),
      request_id: planning_params.request_id,
      routing_metadata: Keyword.get(opts, :routing_metadata, %{
        routed_at: DateTime.utc_now(),
        routing_reason: "strategy_preference"
      })
    }
  end

  @doc """
  Creates a fallback strategy request when primary strategy fails.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> original_request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params, :hybrid_coordinator, [:minizinc]
      ...> )
      iex> fallback_request = AriaEngine.Membrane.Planning.Format.StrategyRequest.create_fallback(
      ...>   original_request,
      ...>   "HybridCoordinator failed: timeout"
      ...> )
      iex> fallback_request.strategy
      :minizinc

  """
  @spec create_fallback(t(), String.t()) :: t() | {:error, :no_fallback_strategies}
  def create_fallback(%__MODULE__{fallback_strategies: []} = _request, _failure_reason) do
    {:error, :no_fallback_strategies}
  end

  def create_fallback(%__MODULE__{fallback_strategies: [next_strategy | remaining]} = request, failure_reason) do
    %__MODULE__{
      request
      | strategy: next_strategy,
        fallback_strategies: remaining,
        execution_context: %{
          request.execution_context
          | attempt_number: request.execution_context.attempt_number + 1,
            previous_failures: [failure_reason | request.execution_context.previous_failures]
        },
        routing_metadata: %{
          request.routing_metadata
          | routed_at: DateTime.utc_now(),
            routing_reason: "fallback_after_failure",
            previous_strategy: request.strategy,
            failure_reason: failure_reason
        }
    }
  end

  @doc """
  Validates a strategy request structure.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params, :hybrid_coordinator, [:minizinc]
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.StrategyRequest.valid?(request)
      true

  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    PlanningParams.valid?(request.planning_params) and
      valid_strategy?(request.strategy) and
      valid_strategies?(request.fallback_strategies) and
      is_map(request.execution_context) and
      is_map(request.strategy_config) and
      is_integer(request.timeout_ms) and
      request.timeout_ms > 0 and
      is_binary(request.request_id) and
      is_map(request.routing_metadata)
  end

  def valid?(_), do: false

  @doc """
  Gets the strategy configuration for the current strategy.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params,
      ...>   :hybrid_coordinator,
      ...>   [:minizinc],
      ...>   strategy_config: %{hybrid_coordinator: %{max_depth: 10}}
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.StrategyRequest.get_strategy_config(request)
      %{max_depth: 10}

  """
  @spec get_strategy_config(t()) :: map()
  def get_strategy_config(%__MODULE__{strategy: strategy, strategy_config: config}) do
    Map.get(config, strategy, %{})
  end

  @doc """
  Checks if this is a fallback attempt.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params, :hybrid_coordinator, [:minizinc]
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.StrategyRequest.fallback_attempt?(request)
      false

  """
  @spec fallback_attempt?(t()) :: boolean()
  def fallback_attempt?(%__MODULE__{execution_context: context}) do
    context.attempt_number > 1
  end

  @doc """
  Gets the number of remaining fallback strategies.

  ## Examples

      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> request = AriaEngine.Membrane.Planning.Format.StrategyRequest.new(
      ...>   params, :hybrid_coordinator, [:minizinc, :mock]
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.StrategyRequest.remaining_fallbacks(request)
      2

  """
  @spec remaining_fallbacks(t()) :: non_neg_integer()
  def remaining_fallbacks(%__MODULE__{fallback_strategies: strategies}) do
    length(strategies)
  end

  @doc """
  Converts strategy request to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    %{
      "planning_params" => PlanningParams.to_map(request.planning_params),
      "strategy" => request.strategy,
      "fallback_strategies" => request.fallback_strategies,
      "execution_context" => request.execution_context,
      "strategy_config" => request.strategy_config,
      "timeout_ms" => request.timeout_ms,
      "request_id" => request.request_id,
      "routing_metadata" => request.routing_metadata
    }
  end

  # Private functions

  defp valid_strategy?(strategy) do
    strategy in [:hybrid_coordinator, :minizinc, :lazy_execution, :mock, :default]
  end

  defp valid_strategies?(strategies) do
    Enum.all?(strategies, &valid_strategy?/1)
  end
end
