# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Constructor do
  @moduledoc """
  Constructor and validation logic for HybridCoordinatorV2.

  Handles strategy dependency injection, validation, and coordinator creation
  following the Function as Object pattern.
  """

  alias HybridPlanner.Strategies

  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @type strategies_map :: %{
          planning_strategy: module(),
          temporal_strategy: module(),
          state_strategy: module(),
          domain_strategy: module(),
          logging_strategy: module(),
          execution_strategy: module()
        }

  @doc """
  Create a new hybrid coordinator with injected strategy dependencies.

  This implements the Function as Object pattern - the coordinator becomes
  a composable object containing strategy functions as data.
  """
  @spec new(strategies_map(), keyword()) :: coordinator()
  def new(strategies, opts \\ []) do
    # Validate that all required strategies are provided
    required_strategies = [
      :planning_strategy,
      :temporal_strategy,
      :state_strategy,
      :domain_strategy,
      :logging_strategy,
      :execution_strategy
    ]

    missing_strategies =
      required_strategies
      |> Enum.filter(fn strategy -> not Map.has_key?(strategies, strategy) end)

    if length(missing_strategies) > 0 do
      raise ArgumentError, "Missing required strategies: #{inspect(missing_strategies)}"
    end

    # Validate strategy implementations
    case validate_strategy_compatibility(strategies) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, "Strategy validation failed: #{reason}"
    end

    %HybridPlanner.HybridCoordinatorV2{
      planning_strategy: Map.get(strategies, :planning_strategy),
      temporal_strategy: Map.get(strategies, :temporal_strategy),
      state_strategy: Map.get(strategies, :state_strategy),
      domain_strategy: Map.get(strategies, :domain_strategy),
      logging_strategy: Map.get(strategies, :logging_strategy),
      execution_strategy: Map.get(strategies, :execution_strategy),
      metadata: %{
        created_at: System.system_time(:millisecond),
        strategy_composition: get_strategy_composition_info(strategies),
        options: opts
      }
    }
  end

  @doc """
  Create a coordinator with default strategy implementations.
  """
  @spec new_default(keyword()) :: coordinator()
  def new_default(opts \\ []) do
    default_strategies = %{
      planning_strategy: Strategies.Default.HTNPlanningStrategy,
      temporal_strategy: Strategies.Default.STNTemporalStrategy,
      state_strategy: Strategies.Default.StateStrategy,
      domain_strategy: Strategies.Default.DomainStrategy,
      logging_strategy: Strategies.Default.LoggerStrategy,
      execution_strategy: Strategies.Default.LazyExecutionStrategy
    }

    new(default_strategies, opts)
  end

  @doc """
  Validate strategy compatibility.
  """
  @spec validate_strategy_compatibility(strategies_map()) :: :ok | {:error, String.t()}
  def validate_strategy_compatibility(strategies) when is_map(strategies) do
    Strategies.validate_strategy_compatibility(strategies)
  end

  @doc """
  Get composition information for metadata.
  """
  @spec get_strategy_composition_info(strategies_map()) :: map()
  def get_strategy_composition_info(strategies) do
    strategies
    |> Enum.map(fn {strategy_type, strategy_module} ->
      strategy_info =
        if function_exported?(strategy_module, :strategy_info, 0) do
          try do
            strategy_module.strategy_info()
          rescue
            _ -> %{module: strategy_module, info_available: false}
          end
        else
          %{module: strategy_module, info_available: false}
        end

      {strategy_type,
       %{
         module: strategy_module,
         info: strategy_info
       }}
    end)
    |> Enum.into(%{})
  end
end
