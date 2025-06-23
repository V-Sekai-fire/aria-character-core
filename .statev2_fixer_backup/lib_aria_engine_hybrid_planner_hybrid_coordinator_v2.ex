# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2 do
  @moduledoc """
  Strategy-based hybrid goal task reentrant temporal planner using dependency injection.

  This version implements the Function as Object pattern with injected strategy
  dependencies as defined in ADR-091. All dependencies are provided through
  strategy objects, enabling maximum modularity, testability, and flexibility.

  ## Strategy Architecture

  The coordinator accepts six strategy objects:
  - PlanningStrategy: HTN planning logic
  - TemporalStrategy: Temporal constraint management
  - StateStrategy: State management and action application
  - DomainStrategy: Domain queries and metadata
  - LoggingStrategy: Logging and progress tracking
  - ExecutionStrategy: Plan execution and failure recovery

  ## Specialized Modules

  This module delegates to specialized sub-modules for different aspects of functionality:

  - `HybridPlanner.HybridCoordinatorV2.Constructor` - Strategy injection and coordinator creation
  - `HybridPlanner.HybridCoordinatorV2.PlanningOperations` - HTN planning and temporal validation
  - `HybridPlanner.HybridCoordinatorV2.ExecutionOperations` - Plan execution
  - `HybridPlanner.HybridCoordinatorV2.ReplanningOperations` - Replanning from failure points
  - `HybridPlanner.HybridCoordinatorV2.StrategyManagement` - Strategy replacement and metrics

  ## Usage

      # Create strategies
      strategies = %{
        planning_strategy: HybridPlanner.Strategies.Default.HTNPlanningStrategy,
        temporal_strategy: HybridPlanner.Strategies.Default.STNTemporalStrategy,
        state_strategy: HybridPlanner.Strategies.Default.StateV2Strategy,
        domain_strategy: HybridPlanner.Strategies.Default.DomainStrategy,
        logging_strategy: HybridPlanner.Strategies.Default.LoggerStrategy,
        execution_strategy: HybridPlanner.Strategies.Default.LazyExecutionStrategy
      }
      
      # Create coordinator with injected strategies
      coordinator = HybridPlanner.HybridCoordinatorV2.new(strategies)
      
      # Use coordinator for planning
      case HybridPlanner.HybridCoordinatorV2.plan(coordinator, domain, state, goals) do
        {:ok, plan} ->
          HybridPlanner.HybridCoordinatorV2.execute(coordinator, domain, state, plan)
        {:error, error_reason} ->
          Logger.error("Planning failed: \#{error_reason}")
      end
  """

  alias HybridPlanner.HybridCoordinatorV2.Constructor
  alias HybridPlanner.HybridCoordinatorV2.PlanningOperations
  alias HybridPlanner.HybridCoordinatorV2.ExecutionOperations
  alias HybridPlanner.HybridCoordinatorV2.ReplanningOperations
  alias HybridPlanner.HybridCoordinatorV2.StrategyManagement

  # Strategy-based coordinator structure
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
  @type execution_result :: {:ok, State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, map()} | {:error, String.t()} | :failure

  # ==================== CONSTRUCTOR FUNCTIONS ====================

  @doc """
  Create a new hybrid coordinator with injected strategy dependencies.

  Delegates to `HybridPlanner.HybridCoordinatorV2.Constructor.new/2`.
  """
  defdelegate new(strategies, opts \\ []), to: Constructor

  @doc """
  Create a coordinator with default strategy implementations.

  Delegates to `HybridPlanner.HybridCoordinatorV2.Constructor.new_default/1`.
  """
  defdelegate new_default(opts \\ []), to: Constructor

  # ==================== PLANNING OPERATIONS ====================

  @doc """
  Plan goals using injected planning and temporal strategies.

  Delegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.plan/5`.
  """
  defdelegate plan(coordinator, domain, state, goals, opts \\ []), to: PlanningOperations

  @doc """
  Validate a plan using injected planning strategy.

  Delegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.validate_plan/4`.
  """
  defdelegate validate_plan(coordinator, domain, initial_state, plan), to: PlanningOperations

  @doc """
  Simple plan interface for backward compatibility.

  Delegates to `HybridPlanner.HybridCoordinatorV2.PlanningOperations.plan/2`.
  """
  defdelegate plan(coordinator, request), to: PlanningOperations

  # ==================== EXECUTION OPERATIONS ====================

  @doc """
  Execute a plan using injected execution strategy.

  Delegates to `HybridPlanner.HybridCoordinatorV2.ExecutionOperations.execute/5`.
  """
  defdelegate execute(coordinator, domain, initial_state, plan, opts \\ []),
    to: ExecutionOperations

  # ==================== REPLANNING OPERATIONS ====================

  @doc """
  Replan from a failure point using injected planning and temporal strategies.

  Delegates to `HybridPlanner.HybridCoordinatorV2.ReplanningOperations.replan/6`.
  """
  defdelegate replan(coordinator, domain, state, plan, fail_node_id, opts \\ []),
    to: ReplanningOperations

  @doc """
  Simple replan interface for backward compatibility.

  Delegates to `HybridPlanner.HybridCoordinatorV2.ReplanningOperations.replan/2`.
  """
  defdelegate replan(coordinator, request), to: ReplanningOperations

  # ==================== STRATEGY MANAGEMENT ====================

  @doc """
  Replace a strategy in the coordinator.

  Delegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.replace_strategy/3`.
  """
  defdelegate replace_strategy(coordinator, strategy_type, new_strategy), to: StrategyManagement

  @doc """
  Get strategy information from the coordinator.

  Delegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_strategy_info/1`.
  """
  defdelegate get_strategy_info(coordinator), to: StrategyManagement

  @doc """
  Get specific strategy information by strategy type.

  Delegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_strategy_info/2`.
  """
  defdelegate get_strategy_info(coordinator, strategy_type), to: StrategyManagement

  @doc """
  Get performance metrics from strategies.

  Delegates to `HybridPlanner.HybridCoordinatorV2.StrategyManagement.get_performance_metrics/1`.
  """
  defdelegate get_performance_metrics(coordinator), to: StrategyManagement
end
