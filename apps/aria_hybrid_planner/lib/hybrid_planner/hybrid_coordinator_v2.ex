# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2 do
  @moduledoc "Strategy-based hybrid goal task reentrant temporal planner using dependency injection.\n\nThis version implements the Function as Object pattern with injected strategy\ndependencies as defined in ADR-091. All dependencies are provided through\nstrategy objects, enabling maximum modularity, testability, and flexibility.\n\n## Strategy Architecture\n\nThe coordinator accepts six strategy objects:\n- PlanningStrategy: HTN planning logic\n- TemporalStrategy: Temporal constraint management\n- StateStrategy: State management and action application\n- DomainStrategy: Domain queries and metadata\n- LoggingStrategy: Logging and progress tracking\n- ExecutionStrategy: Plan execution and failure recovery\n\n## Specialized Modules\n\nThis module delegates to specialized sub-modules for different aspects of functionality:\n\n- `HybridPlanner.HybridCoordinatorV2.Constructor` - Strategy injection and coordinator creation\n- `HybridPlanner.HybridCoordinatorV2.PlanningOperations` - HTN planning and temporal validation\n- `HybridPlanner.HybridCoordinatorV2.ExecutionOperations` - Plan execution\n- `HybridPlanner.HybridCoordinatorV2.ReplanningOperations` - Replanning from failure points\n- `HybridPlanner.HybridCoordinatorV2.StrategyManagement` - Strategy replacement and metrics\n\n## Usage\n\n    # Create strategies\n    strategies = %{\n      planning_strategy: HybridPlanner.Strategies.Default.HTNPlanningStrategy,\n      temporal_strategy: HybridPlanner.Strategies.Default.STNTemporalStrategy,\n      state_strategy: HybridPlanner.Strategies.Default.StateV2Strategy,\n      domain_strategy: HybridPlanner.Strategies.Default.DomainStrategy,\n      logging_strategy: HybridPlanner.Strategies.Default.LoggerStrategy,\n      execution_strategy: HybridPlanner.Strategies.Default.LazyExecutionStrategy\n    }\n    \n    # Create coordinator with injected strategies\n    coordinator = HybridPlanner.HybridCoordinatorV2.new(strategies)\n    \n    # Use coordinator for planning\n    case HybridPlanner.HybridCoordinatorV2.plan(coordinator, domain, state, goals) do\n      {:ok, plan} ->\n        HybridPlanner.HybridCoordinatorV2.execute(coordinator, domain, state, plan)\n      {:error, error_reason} ->\n        Logger.error(\"Planning failed: \#{error_reason}\")\n    end\n"
  alias HybridPlanner.HybridCoordinatorV2.Constructor
  alias HybridPlanner.HybridCoordinatorV2.PlanningOperations
  alias HybridPlanner.HybridCoordinatorV2.ExecutionOperations
  alias HybridPlanner.HybridCoordinatorV2.ReplanningOperations
  alias HybridPlanner.HybridCoordinatorV2.StrategyManagement
  alias AriaEngine.State

  defstruct [
    :planning_strategy,
    :temporal_strategy,
    :state_strategy,
    :domain_strategy,
    :logging_strategy,
    :execution_strategy,
    :metadata
  ]

  @type t :: %__MODULE__{
          planning_strategy: module(),
          temporal_strategy: module(),
          state_strategy: module(),
          domain_strategy: module(),
          logging_strategy: module(),
          execution_strategy: module(),
          metadata: map()
        }
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type execution_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, map()} | {:error, String.t()} | :failure
  @doc "Create a new hybrid coordinator with injected strategy dependencies.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.Constructor.new/2`.\n"
  defdelegate new(strategies, opts \\ []), to: Constructor

  @doc "Create a coordinator with default strategy implementations.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.Constructor.new_default/1`.\n"
  defdelegate new_default(opts \\ []), to: Constructor

  @doc "Plan goals using injected planning and temporal strategies.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.plan/5`.\n"
  defdelegate plan(coordinator, domain, state, goals, opts \\ []), to: PlanningOperations

  @doc "Validate a plan using injected planning strategy.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.validate_plan/4`.\n"
  defdelegate validate_plan(coordinator, domain, initial_state, plan), to: PlanningOperations

  @doc "Simple plan interface for backward compatibility.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.plan/2`.\n"
  defdelegate plan(coordinator, request), to: PlanningOperations

  @doc "Execute a plan using injected execution strategy.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.ExecutionOperations.execute/5`.\n"
  defdelegate execute(coordinator, domain, initial_state, plan, opts \\ []),
    to: ExecutionOperations

  @doc "Replan from a failure point using injected planning and temporal strategies.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.ReplanningOperations.replan/6`.\n"
  defdelegate replan(coordinator, domain, state, plan, fail_node_id, opts \\ []),
    to: ReplanningOperations

  @doc "Simple replan interface for backward compatibility.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.ReplanningOperations.replan/2`.\n"
  defdelegate replan(coordinator, request), to: ReplanningOperations

  @doc "Replace a strategy in the coordinator.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.replace_strategy/3`.\n"
  defdelegate replace_strategy(coordinator, strategy_type, new_strategy), to: StrategyManagement

  @doc "Get strategy information from the coordinator.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_strategy_info/1`.\n"
  defdelegate get_strategy_info(coordinator), to: StrategyManagement

  @doc "Get specific strategy information by strategy type.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_strategy_info/2`.\n"
  defdelegate get_strategy_info(coordinator, strategy_type), to: StrategyManagement

  @doc "Get performance metrics from strategies.\n\nDelegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_performance_metrics/1`.\n"
  defdelegate get_performance_metrics(coordinator), to: StrategyManagement
end