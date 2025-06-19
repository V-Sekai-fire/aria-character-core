# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2 do
  @moduledoc """
  require Logger
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

  alias HybridPlanner.Strategies

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
  @type execution_result :: {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  @type replan_result :: {:ok, map()} | {:error, String.t()} | :failure

  # ==================== CONSTRUCTOR ====================

  @doc """
  Create a new hybrid coordinator with injected strategy dependencies.
  
  This implements the Function as Object pattern - the coordinator becomes
  a composable object containing strategy functions as data.
  """
  @spec new(map(), keyword()) :: t()
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

    missing_strategies = required_strategies
    |> Enum.filter(fn strategy -> not Map.has_key?(strategies, strategy) end)

    if length(missing_strategies) > 0 do
      raise ArgumentError, "Missing required strategies: #{inspect(missing_strategies)}"
    end

    # Validate strategy implementations
    case validate_strategy_compatibility(strategies) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, "Strategy validation failed: #{reason}"
    end

    %__MODULE__{
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
  @spec new_default(keyword()) :: t()
  def new_default(opts \\ []) do
    default_strategies = %{
      planning_strategy: Strategies.Default.HTNPlanningStrategy,
      temporal_strategy: Strategies.Default.STNTemporalStrategy,
      state_strategy: Strategies.Default.StateV2Strategy,
      domain_strategy: Strategies.Default.DomainStrategy,
      logging_strategy: Strategies.Default.LoggerStrategy,
      execution_strategy: Strategies.Default.LazyExecutionStrategy
    }

    new(default_strategies, opts)
  end

  # ==================== PUBLIC API ====================

  @doc """
  Plan goals using injected planning and temporal strategies.
  
  Pure Function as Object implementation - all dependencies are injected strategies.
  """
  @spec plan(t(), Domain.Core.t(), AriaEngine.StateV2.t(), [term()], keyword()) :: plan_result()
  def plan(%__MODULE__{} = coordinator, domain, %AriaEngine.StateV2{} = state, goals, opts \\ []) do
    _verbose = Keyword.get(opts, :verbose, 0)
    
    # Log start using injected logging strategy
    coordinator.logging_strategy.log_progress("planning", %{
      status: "started",
      goals: length(goals),
      domain: domain.name
    }, opts)

    try do
      # Phase 1: HTN Planning using injected planning strategy
      case coordinator.planning_strategy.plan(domain, state, goals, opts) do
        {:ok, solution_tree} ->
          coordinator.logging_strategy.log_progress("planning", %{
            status: "htn_completed",
            solution_tree_size: count_solution_tree_nodes(solution_tree)
          }, opts)

          # Phase 2: Temporal Validation using injected temporal strategy
          case add_temporal_constraints_to_plan(coordinator, solution_tree, domain, opts) do
            {:ok, temporal_constraints} ->
              # Phase 3: Validate temporal consistency
              case coordinator.temporal_strategy.validate_temporal_consistency(temporal_constraints, opts) do
                {:ok, true} ->
                  coordinator.logging_strategy.log_progress("planning", %{
                    status: "completed_successfully"
                  }, opts)

                  # Return composite plan with both HTN and temporal information
                  {:ok, %{
                    solution_tree: solution_tree,
                    temporal_constraints: temporal_constraints,
                    metadata: %{
                      goals: goals,
                      domain_name: domain.name,
                      planning_time: System.system_time(:millisecond),
                      strategy_coordinator: coordinator.metadata
                    }
                  }}

                {:ok, false} ->
                  error_msg = "Temporal constraints are inconsistent"
                  coordinator.logging_strategy.log_error(error_msg, %{phase: "temporal_validation"}, opts)
                  {:error, error_msg}

                {:error, reason} ->
                  coordinator.logging_strategy.log_error(reason, %{phase: "temporal_validation"}, opts)
                  {:error, "Temporal validation failed: #{reason}"}
              end

            {:error, reason} ->
              coordinator.logging_strategy.log_error(reason, %{phase: "temporal_constraint_creation"}, opts)
              {:error, "Failed to create temporal constraints: #{reason}"}
          end

        {:error, reason} ->
          coordinator.logging_strategy.log_error(reason, %{phase: "htn_planning"}, opts)
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        coordinator.logging_strategy.log_error(error_msg, %{phase: "planning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Execute a plan using injected execution strategy.
  """
  @spec execute(t(), Domain.Core.t(), AriaEngine.StateV2.t(), map(), keyword()) :: execution_result()
  def execute(%__MODULE__{} = coordinator, domain, %AriaEngine.StateV2{} = initial_state, plan, opts \\ []) do
    coordinator.logging_strategy.log_progress("execution", %{
      status: "started"
    }, opts)

    try do
      # Extract solution tree from composite plan
      solution_tree = Map.get(plan, :solution_tree)
      _temporal_constraints = Map.get(plan, :temporal_constraints)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format - missing solution tree"}
      else
        # Use injected execution strategy with all strategies available
        strategies = extract_strategies_map(coordinator)
        enhanced_opts = Keyword.put(opts, :domain, domain)

        case coordinator.execution_strategy.execute_plan(solution_tree, initial_state, strategies, enhanced_opts) do
          {:ok, final_state} ->
            coordinator.logging_strategy.log_progress("execution", %{
              status: "completed_successfully"
            }, opts)
            {:ok, final_state}

          {:error, reason} ->
            coordinator.logging_strategy.log_error(reason, %{phase: "execution"}, opts)
            {:error, reason}
        end
      end
    rescue
      e ->
        error_msg = "Execution error: #{Exception.message(e)}"
        coordinator.logging_strategy.log_error(error_msg, %{phase: "execution_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Replan from a failure point using injected planning and temporal strategies.
  """
  @spec replan(t(), Domain.Core.t(), AriaEngine.StateV2.t(), map(), String.t(), keyword()) :: replan_result()
  def replan(%__MODULE__{} = coordinator, domain, %AriaEngine.StateV2{} = state, plan, fail_node_id, opts \\ []) do
    coordinator.logging_strategy.log_progress("replanning", %{
      status: "started",
      fail_node_id: fail_node_id
    }, opts)

    try do
      # Extract solution tree from composite plan
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for replanning - missing solution tree"}
      else
        # Use injected planning strategy for replanning
        case coordinator.planning_strategy.replan(domain, state, solution_tree, fail_node_id, opts) do
          {:ok, new_solution_tree} ->
            coordinator.logging_strategy.log_progress("replanning", %{
              status: "htn_replanning_completed"
            }, opts)

            # Re-validate temporal constraints for new plan
            case add_temporal_constraints_to_plan(coordinator, new_solution_tree, domain, opts) do
              {:ok, new_temporal_constraints} ->
                case coordinator.temporal_strategy.validate_temporal_consistency(new_temporal_constraints, opts) do
                  {:ok, true} ->
                    coordinator.logging_strategy.log_progress("replanning", %{
                      status: "completed_successfully"
                    }, opts)

                    # Return new composite plan
                    original_metadata = Map.get(plan, :metadata, %{})
                    replan_metadata = Map.merge(original_metadata, %{
                      replanned_at: System.system_time(:millisecond),
                      original_fail_node: fail_node_id,
                      strategy_coordinator: coordinator.metadata
                    })

                    {:ok, %{
                      solution_tree: new_solution_tree,
                      temporal_constraints: new_temporal_constraints,
                      metadata: replan_metadata
                    }}

                  {:ok, false} ->
                    error_msg = "Replanned temporal constraints are inconsistent"
                    coordinator.logging_strategy.log_error(error_msg, %{phase: "replanning_temporal_validation"}, opts)
                    {:error, error_msg}

                  {:error, reason} ->
                    coordinator.logging_strategy.log_error(reason, %{phase: "replanning_temporal_validation"}, opts)
                    {:error, "Replanning temporal validation failed: #{reason}"}
                end

              {:error, reason} ->
                coordinator.logging_strategy.log_error(reason, %{phase: "replanning_temporal_constraints"}, opts)
                {:error, "Failed to create temporal constraints during replanning: #{reason}"}
            end

          {:error, reason} ->
            coordinator.logging_strategy.log_error(reason, %{phase: "htn_replanning"}, opts)
            {:error, reason}

          :failure ->
            coordinator.logging_strategy.log_progress("replanning", %{
              status: "no_alternatives_found"
            }, opts)
            :failure
        end
      end
    rescue
      e ->
        error_msg = "Replanning error: #{Exception.message(e)}"
        coordinator.logging_strategy.log_error(error_msg, %{phase: "replanning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Validate a plan using injected planning strategy.
  """
  @spec validate_plan(t(), Domain.Core.t(), AriaEngine.StateV2.t(), map()) :: {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def validate_plan(%__MODULE__{} = coordinator, domain, %AriaEngine.StateV2{} = initial_state, plan) do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        # Use injected planning strategy for validation
        coordinator.planning_strategy.validate_plan(domain, initial_state, solution_tree)
      end
    rescue
      e ->
        {:error, "Plan validation error: #{Exception.message(e)}"}
    end
  end

  # ==================== STRATEGY MANAGEMENT ====================

  @doc """
  Replace a strategy in the coordinator.
  
  This enables runtime strategy swapping for adaptive planning.
  """
  @spec replace_strategy(t(), atom(), module()) :: t()
  def replace_strategy(%__MODULE__{} = coordinator, strategy_type, new_strategy) do
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

  @doc """
  Get strategy information from the coordinator.
  """
  @spec get_strategy_info(t()) :: map()
  def get_strategy_info(%__MODULE__{} = coordinator) do
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

  @doc """
  Get specific strategy information by strategy type.
  """
  @spec get_strategy_info(t(), atom()) :: map()
  def get_strategy_info(%__MODULE__{} = coordinator, strategy_type) do
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

  @doc """
  Simple plan interface for backward compatibility.
  """
  @spec plan(t(), map()) :: plan_result()
  def plan(%__MODULE__{} = coordinator, %{domain: domain, state: state, goals: goals} = request) do
    opts = Map.get(request, :opts, [])
    plan(coordinator, domain, state, goals, opts)
  end

  @doc """
  Simple replan interface for backward compatibility.
  """
  @spec replan(t(), map()) :: replan_result()
  def replan(%__MODULE__{} = coordinator, %{domain: domain, state: state, plan: plan, fail_node_id: fail_node_id} = request) do
    opts = Map.get(request, :opts, [])
    replan(coordinator, domain, state, plan, fail_node_id, opts)
  end

  @doc """
  Get performance metrics from strategies.
  """
  @spec get_performance_metrics(t()) :: map()
  def get_performance_metrics(%__MODULE__{} = coordinator) do
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

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Validate strategy compatibility
  defp validate_strategy_compatibility(strategies) when is_map(strategies) do
    Strategies.validate_strategy_compatibility(strategies)
  end

  # Add temporal constraints to a plan using the temporal strategy
  defp add_temporal_constraints_to_plan(coordinator, solution_tree, _domain, opts) do
    # Extract primitive actions from solution tree
    primitive_actions = extract_primitive_actions(solution_tree)
    current_time = Keyword.get(opts, :current_time, 0)

    # Use temporal strategy to add constraints
    coordinator.temporal_strategy.add_temporal_constraints(%{}, primitive_actions, 
      Keyword.merge(opts, [current_time: current_time]))
  end

  # Extract primitive actions from solution tree
  defp extract_primitive_actions(solution_tree) do
    # This is a simplified extraction - in reality this would traverse the tree
    # For now, assume the solution tree has a predictable structure
    case solution_tree do
      %{children: children} when is_list(children) ->
        Enum.flat_map(children, &extract_primitive_actions/1)
      
      %{task: {action_name, args}, status: :primitive} ->
        [{action_name, args}]
      
      %{task: task} when is_tuple(task) ->
        [task]
      
      _ ->
        []
    end
  end

  # Count nodes in solution tree for metrics
  defp count_solution_tree_nodes(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        1 + Enum.sum(Enum.map(children, &count_solution_tree_nodes/1))
      
      _ ->
        1
    end
  end

  # Extract strategies as a map for passing to execution strategy
  defp extract_strategies_map(coordinator) do
    %{
      planning_strategy: coordinator.planning_strategy,
      temporal_strategy: coordinator.temporal_strategy,
      state_strategy: coordinator.state_strategy,
      domain_strategy: coordinator.domain_strategy,
      logging_strategy: coordinator.logging_strategy,
      execution_strategy: coordinator.execution_strategy
    }
  end

  # Get composition information for metadata
  defp get_strategy_composition_info(strategies) do
    strategies
    |> Enum.map(fn {strategy_type, strategy_module} ->
      strategy_info = if function_exported?(strategy_module, :strategy_info, 0) do
        try do
          strategy_module.strategy_info()
        rescue
          _ -> %{module: strategy_module, info_available: false}
        end
      else
        %{module: strategy_module, info_available: false}
      end

      {strategy_type, %{
        module: strategy_module,
        info: strategy_info
      }}
    end)
    |> Enum.into(%{})
  end

  # Safely get strategy info, handling missing functions gracefully
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

  # Get performance metrics from a strategy if available
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
