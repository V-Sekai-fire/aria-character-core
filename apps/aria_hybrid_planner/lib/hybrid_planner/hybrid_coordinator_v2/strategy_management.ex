# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.StrategyManagement do
  @moduledoc "Strategy management operations for HybridCoordinatorV2.\n\nHandles strategy replacement, information retrieval, and performance metrics\nfor the injected strategy dependencies.\n"
  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @doc "Replace a strategy in the coordinator.\n\nThis enables runtime strategy swapping for adaptive planning.\n"
  @spec replace_strategy(coordinator(), atom(), module()) :: coordinator()
  def replace_strategy(%coordinator_module{} = coordinator, strategy_type, new_strategy)
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    case strategy_type do
      :planning_strategy -> %{coordinator | planning_strategy: new_strategy}
      :temporal_strategy -> %{coordinator | temporal_strategy: new_strategy}
      :state_strategy -> %{coordinator | state_strategy: new_strategy}
      :domain_strategy -> %{coordinator | domain_strategy: new_strategy}
      :logging_strategy -> %{coordinator | logging_strategy: new_strategy}
      :execution_strategy -> %{coordinator | execution_strategy: new_strategy}
      _ -> raise ArgumentError, "Unknown strategy type: #{strategy_type}"
    end
  end

  @doc "Get strategy information from the coordinator.\n"
  @spec get_strategy_info(coordinator()) :: map()
  def get_strategy_info(%coordinator_module{} = coordinator)
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    %{
      planning_strategy: safe_strategy_info(coordinator.planning_strategy),
      temporal_strategy: safe_strategy_info(coordinator.temporal_strategy),
      state_strategy: safe_strategy_info(coordinator.state_strategy),
      domain_strategy: safe_strategy_info(coordinator.domain_strategy),
      logging_strategy: safe_strategy_info(coordinator.logging_strategy),
      execution_strategy: safe_strategy_info(coordinator.execution_strategy),
      coordinator_metadata: coordinator.metadata
    }
  end

  @doc "Get specific strategy information by strategy type.\n"
  @spec get_strategy_info(coordinator(), atom()) :: map()
  def get_strategy_info(%coordinator_module{} = coordinator, strategy_type)
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    case strategy_type do
      :planning_strategy -> safe_strategy_info(coordinator.planning_strategy)
      :temporal_strategy -> safe_strategy_info(coordinator.temporal_strategy)
      :state_strategy -> safe_strategy_info(coordinator.state_strategy)
      :domain_strategy -> safe_strategy_info(coordinator.domain_strategy)
      :logging_strategy -> safe_strategy_info(coordinator.logging_strategy)
      :execution_strategy -> safe_strategy_info(coordinator.execution_strategy)
      _ -> %{error: "Unknown strategy type: #{strategy_type}"}
    end
  end

  @doc "Get performance metrics from strategies.\n"
  @spec get_performance_metrics(coordinator()) :: map()
  def get_performance_metrics(%coordinator_module{} = coordinator)
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    %{
      planning_strategy: get_strategy_metrics(coordinator.planning_strategy),
      temporal_strategy: get_strategy_metrics(coordinator.temporal_strategy),
      state_strategy: get_strategy_metrics(coordinator.state_strategy),
      domain_strategy: get_strategy_metrics(coordinator.domain_strategy),
      logging_strategy: get_strategy_metrics(coordinator.logging_strategy),
      execution_strategy: get_strategy_metrics(coordinator.execution_strategy),
      coordinator_created_at: coordinator.metadata.created_at
    }
  end

  defp safe_strategy_info(strategy_module) do
    if function_exported?(strategy_module, :strategy_info, 0) do
      try do
        strategy_module.strategy_info()
      rescue
        _ -> %{module: strategy_module, info_available: false}
      end
    else
      %{module: strategy_module, info_available: false}
    end
  end

  defp get_strategy_metrics(strategy_module) do
    if function_exported?(strategy_module, :get_performance_metrics, 0) do
      strategy_module.get_performance_metrics()
    else
      %{
        module: strategy_module,
        metrics_available: false,
        info: safe_strategy_info(strategy_module)
      }
    end
  end
end