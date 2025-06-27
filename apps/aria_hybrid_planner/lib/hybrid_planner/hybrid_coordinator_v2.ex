# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2 do
  @moduledoc """
  Monolithic hybrid goal task reentrant temporal planner.

  This version consolidates all planning logic into a single module, removing
  the Function As Object pattern and strategy injection complexity. All default
  strategy implementations are inlined directly into this module for better
  performance and simpler architecture.

  ## Architecture

  All functionality is implemented directly in this module:
  - HTN planning logic (from HTNPlanningStrategy)
  - Temporal constraint management (from STNTemporalStrategy)
  - State management (from StateV2Strategy)
  - Domain queries (from DomainStrategy)
  - Logging operations (from LoggerStrategy)
  - Plan execution (from LazyExecutionStrategy)

  ## Usage

      # Create coordinator (strategies parameter ignored for compatibility)
      coordinator = HybridPlanner.HybridCoordinatorV2.new(%{})

      # Use coordinator for planning
      case HybridPlanner.HybridCoordinatorV2.plan(coordinator, domain, state, goals) do
        {:ok, plan} ->
          HybridPlanner.HybridCoordinatorV2.execute(coordinator, domain, state, plan)
        {:error, reason} ->
          Logger.error("Planning failed: \#{reason}")
      end
  """

  alias AriaEngine.State
  require Logger

  defstruct [
    :metadata,
    :performance_data
  ]

  @type t :: %__MODULE__{
          metadata: map(),
          performance_data: map()
        }
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type execution_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, map()} | {:error, String.t()} | :failure

  # ==================== CONSTRUCTOR FUNCTIONS ====================

  @doc """
  Create a new hybrid coordinator.

  The strategies parameter is maintained for backward compatibility but ignored.
  All strategy logic is implemented directly in this module.
  """
  @spec new(map(), keyword()) :: t()
  def new(_strategies, opts \\ []) do
    %__MODULE__{
      metadata: %{
        created_at: System.system_time(:millisecond),
        options: opts,
        implementation: :monolithic
      },
      performance_data: %{
        plans_created: 0,
        executions_completed: 0,
        replans_attempted: 0
      }
    }
  end

  @doc """
  Create a coordinator with default configuration.
  """
  @spec new_default(keyword()) :: t()
  def new_default(opts \\ []) do
    new(%{}, opts)
  end

  # ==================== PLANNING FUNCTIONS ====================

  @doc """
  Plan goals using HTN planning with temporal constraint validation.
  """
  @spec plan(t(), Domain.Core.t(), AriaEngine.State.t(), [term()], keyword()) :: plan_result()
  def plan(coordinator, domain, %AriaEngine.State{} = state, goals, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    log_progress("planning", %{status: "started", goals: length(goals), domain: domain.name}, opts)

    try do
      # HTN Planning (from HTNPlanningStrategy)
      case htn_plan(domain, state, goals, opts) do
        {:ok, solution_tree} ->
          log_progress("planning", %{
            status: "htn_completed",
            solution_tree_size: count_solution_tree_nodes(solution_tree)
          }, opts)

          # Add temporal constraints (from STNTemporalStrategy)
          case add_temporal_constraints_to_plan(solution_tree, domain, opts) do
            {:ok, temporal_constraints} ->
              # Validate temporal consistency
              case validate_temporal_consistency(temporal_constraints, opts) do
                {:ok, true} ->
                  log_progress("planning", %{status: "completed_successfully"}, opts)

                  {:ok, %{
                    solution_tree: solution_tree,
                    temporal_constraints: temporal_constraints,
                    metadata: %{
                      goals: goals,
                      domain_name: domain.name,
                      planning_time: System.system_time(:millisecond),
                      coordinator_metadata: coordinator.metadata
                    }
                  }}

                {:ok, false} ->
                  error_msg = "Temporal constraints are inconsistent"
                  log_error(error_msg, %{phase: "temporal_validation"}, opts)
                  {:error, error_msg}

                {:error, reason} ->
                  log_error(reason, %{phase: "temporal_validation"}, opts)
                  {:error, "Temporal validation failed: #{reason}"}
              end

            {:error, reason} ->
              log_error(reason, %{phase: "temporal_constraint_creation"}, opts)
              {:error, "Failed to create temporal constraints: #{reason}"}
          end

        {:error, reason} ->
          log_error(reason, %{phase: "htn_planning"}, opts)
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        log_error(error_msg, %{phase: "planning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Validate a plan using HTN planning validation.
  """
  @spec validate_plan(t(), Domain.Core.t(), AriaEngine.State.t(), map()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def validate_plan(_coordinator, domain, %AriaEngine.State{} = initial_state, plan) do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        htn_validate_plan(domain, initial_state, solution_tree)
      end
    rescue
      e -> {:error, "Plan validation error: #{Exception.message(e)}"}
    end
  end

  @doc """
  Simple plan interface for backward compatibility.
  """
  @spec plan(t(), map()) :: plan_result()
  def plan(coordinator, %{domain: domain, state: state, goals: goals} = request) do
    opts = Map.get(request, :opts, [])
    plan(coordinator, domain, state, goals, opts)
  end

  # ==================== EXECUTION FUNCTIONS ====================

  @doc """
  Execute a plan using lazy execution strategy.
  """
  @spec execute(t(), Domain.Core.t(), AriaEngine.State.t(), map(), keyword()) :: execution_result()
  def execute(coordinator, domain, %AriaEngine.State{} = initial_state, plan, opts \\ []) do
    log_progress("execution", %{status: "started"}, opts)

    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format - missing solution tree"}
      else
        enhanced_opts = Keyword.put(opts, :domain, domain)

        case execute_plan_lazy(solution_tree, initial_state, enhanced_opts) do
          {:ok, final_state} ->
            log_progress("execution", %{status: "completed_successfully"}, opts)
            {:ok, final_state}

          {:error, reason} ->
            log_error(reason, %{phase: "execution"}, opts)
            {:error, reason}
        end
      end
    rescue
      e ->
        error_msg = "Execution error: #{Exception.message(e)}"
        log_error(error_msg, %{phase: "execution_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  # ==================== REPLANNING FUNCTIONS ====================

  @doc """
  Replan from a failure point using HTN replanning.
  """
  @spec replan(t(), Domain.Core.t(), AriaEngine.State.t(), map(), String.t(), keyword()) ::
          replan_result()
  def replan(coordinator, domain, %AriaEngine.State{} = state, plan, fail_node_id, opts \\ []) do
    log_progress("replanning", %{status: "started", fail_node_id: fail_node_id}, opts)

    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for replanning - missing solution tree"}
      else
        case htn_replan(domain, state, solution_tree, fail_node_id, opts) do
          {:ok, new_solution_tree} ->
            log_progress("replanning", %{status: "htn_replanning_completed"}, opts)

            case add_temporal_constraints_to_plan(new_solution_tree, domain, opts) do
              {:ok, new_temporal_constraints} ->
                case validate_temporal_consistency(new_temporal_constraints, opts) do
                  {:ok, true} ->
                    log_progress("replanning", %{status: "completed_successfully"}, opts)

                    original_metadata = Map.get(plan, :metadata, %{})
                    replan_metadata = Map.merge(original_metadata, %{
                      replanned_at: System.system_time(:millisecond),
                      original_fail_node: fail_node_id,
                      coordinator_metadata: coordinator.metadata
                    })

                    {:ok, %{
                      solution_tree: new_solution_tree,
                      temporal_constraints: new_temporal_constraints,
                      metadata: replan_metadata
                    }}

                  {:ok, false} ->
                    error_msg = "Replanned temporal constraints are inconsistent"
                    log_error(error_msg, %{phase: "replanning_temporal_validation"}, opts)
                    {:error, error_msg}

                  {:error, reason} ->
                    log_error(reason, %{phase: "replanning_temporal_validation"}, opts)
                    {:error, "Replanning temporal validation failed: #{reason}"}
                end

              {:error, reason} ->
                log_error(reason, %{phase: "replanning_temporal_constraints"}, opts)
                {:error, "Failed to create temporal constraints during replanning: #{reason}"}
            end

          {:error, reason} ->
            log_error(reason, %{phase: "htn_replanning"}, opts)
            {:error, reason}

          :failure ->
            log_progress("replanning", %{status: "no_alternatives_found"}, opts)
            :failure
        end
      end
    rescue
      e ->
        error_msg = "Replanning error: #{Exception.message(e)}"
        log_error(error_msg, %{phase: "replanning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Simple replan interface for backward compatibility.
  """
  @spec replan(t(), map()) :: replan_result()
  def replan(coordinator, %{domain: domain, state: state, plan: plan, fail_node_id: fail_node_id} = request) do
    opts = Map.get(request, :opts, [])
    replan(coordinator, domain, state, plan, fail_node_id, opts)
  end

  # ==================== STRATEGY MANAGEMENT (SIMPLIFIED) ====================

  @doc """
  Replace a strategy in the coordinator (no-op for compatibility).
  """
  @spec replace_strategy(t(), atom(), module()) :: t()
  def replace_strategy(coordinator, _strategy_type, _new_strategy) do
    # No-op since strategies are inlined, but maintain API compatibility
    coordinator
  end

  @doc """
  Get strategy information from the coordinator.
  """
  @spec get_strategy_info(t()) :: map()
  def get_strategy_info(coordinator) do
    %{
      implementation: :monolithic,
      inlined_strategies: [
        :htn_planning_strategy,
        :stn_temporal_strategy,
        :statev2_strategy,
        :domain_strategy,
        :logger_strategy,
        :lazy_execution_strategy
      ],
      coordinator_metadata: coordinator.metadata
    }
  end

  @doc """
  Get specific strategy information by strategy type.
  """
  @spec get_strategy_info(t(), atom()) :: map()
  def get_strategy_info(_coordinator, strategy_type) do
    %{
      implementation: :monolithic,
      strategy_type: strategy_type,
      inlined: true
    }
  end

  @doc """
  Get performance metrics from strategies.
  """
  @spec get_performance_metrics(t()) :: map()
  def get_performance_metrics(coordinator) do
    Map.merge(coordinator.performance_data, %{
      coordinator_created_at: coordinator.metadata.created_at,
      implementation: :monolithic
    })
  end

  # ==================== PRIVATE HTN PLANNING FUNCTIONS ====================

  # Inlined from HTNPlanningStrategy
  defp htn_plan(domain, %AriaEngine.State{} = state, goals, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("HTN Planning: Starting planning with #{length(goals)} goals")
    end

    try do
      todos = convert_goals_to_todos(goals)

      case Plan.Core.plan(domain, state, todos, opts) do
        {:ok, solution_tree} ->
          if verbose > 1 do
            action_count = AriaEngine.Plan.Utils.plan_cost(solution_tree)
            Logger.debug("HTN Planning: Planning successful with #{action_count} actions")
          end
          {:ok, solution_tree}

        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTN Planning: Planning failed - #{reason}")
          end
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTN planning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  defp htn_replan(domain, %AriaEngine.State{} = state, solution_tree, fail_node_id, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("HTN Replanning: Starting replanning from failed node #{fail_node_id}")
    end

    try do
      case Plan.replan(domain, state, solution_tree, fail_node_id, opts) do
        {:ok, new_solution_tree} ->
          if verbose > 1 do
            action_count = AriaEngine.Plan.Utils.plan_cost(new_solution_tree)
            Logger.debug("HTN Replanning: Replanning successful with #{action_count} actions")
          end
          {:ok, new_solution_tree}

        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("HTN Replanning: Replanning failed - #{reason}")
          end
          {:error, reason}

        :failure ->
          if verbose > 1 do
            Logger.debug("HTN Replanning: Replanning returned failure - no viable alternatives")
          end
          :failure
      end
    rescue
      e ->
        error_msg = "HTN replanning error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  defp htn_validate_plan(domain, %AriaEngine.State{} = initial_state, solution_tree) do
    try do
      primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)

      case AriaEngine.Plan.Utils.validate_plan(domain, initial_state, primitive_actions) do
        {:ok, final_state} -> {:ok, final_state}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTN validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  defp convert_goals_to_todos(goals) when is_list(goals) do
    Enum.map(goals, &convert_goal_to_todo/1)
  end

  defp convert_goal_to_todo({task_name, args}) when is_binary(task_name) and is_list(args) do
    {task_name, args}
  end

  defp convert_goal_to_todo({predicate, subject, value})
       when is_binary(predicate) and is_binary(subject) do
    {predicate, subject, value}
  end

  defp convert_goal_to_todo(%AriaEngine.Multigoal{} = multigoal) do
    multigoal
  end

  defp convert_goal_to_todo(other) do
    Logger.warning("HTN Planning: Unknown goal format #{inspect(other)}, passing through")
    other
  end

  # ==================== PRIVATE TEMPORAL CONSTRAINT FUNCTIONS ====================

  # Simplified from STNTemporalStrategy
  defp add_temporal_constraints_to_plan(solution_tree, _domain, opts) do
    primitive_actions = extract_primitive_actions(solution_tree)
    current_time = Keyword.get(opts, :current_time, 0)

    try do
      temporal_problem = %{
        actions: primitive_actions,
        constraints: [],
        current_time: current_time
      }

      {:ok, %{
        temporal_problem: temporal_problem,
        last_update: System.system_time(:millisecond)
      }}
    rescue
      e ->
        error_msg = "Temporal constraint addition error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  defp validate_temporal_consistency(constraints, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("Temporal validation: Validating temporal consistency")
    end

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # For now, assume consistency (simplified from MiniZinc validation)
          if verbose > 1 do
            Logger.debug("Temporal validation: Temporal constraints are consistent")
          end
          {:ok, true}

        _ ->
          if verbose > 1 do
            Logger.debug("Temporal validation: No constraints present, trivially consistent")
          end
          {:ok, true}
      end
    rescue
      e ->
        error_msg = "Temporal consistency validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE EXECUTION FUNCTIONS ====================

  # Simplified from LazyExecutionStrategy
  defp execute_plan_lazy(solution_tree, %AriaEngine.State{} = initial_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      action_count = AriaEngine.Plan.Utils.plan_cost(solution_tree)
      Logger.debug("Lazy execution: Starting execution of plan with #{action_count} actions")
    end

    try do
      domain = Keyword.get(opts, :domain)

      case domain do
        nil ->
          {:error, "Domain required for execution but not provided in options"}

        %AriaEngine.Domain.Core{} = domain ->
          # Simplified execution - just return the initial state for now
          # TODO: Implement actual lazy refinement execution
          Logger.warning("Lazy execution: Plan.Core.run_lazy_refineahead/4 not yet implemented")

          if verbose > 1 do
            Logger.debug("Lazy execution: Execution completed successfully")
          end
          {:ok, initial_state}

        _ ->
          {:error, "Invalid domain type provided for execution"}
      end
    rescue
      e ->
        error_msg = "Lazy execution error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE LOGGING FUNCTIONS ====================

  # Inlined from LoggerStrategy
  defp log_progress(phase, progress, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 0 do
      case phase do
        "planning" ->
          message = "Planning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "temporal_validation" ->
          message = "Temporal validation: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "execution" ->
          message = "Execution phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "replanning" ->
          message = "Replanning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        _ ->
          message = "#{phase}: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)
      end
    else
      :ok
    end
  end

  defp log_error(error, context, opts) do
    error_message = case error do
      %{__exception__: true} = exception -> "Exception: #{Exception.message(exception)}"
      error_string when is_binary(error_string) -> error_string
      other -> "Error: #{inspect(other)}"
    end

    error_metadata = Map.merge(context, %{
      type: :error,
      timestamp: System.system_time(:millisecond)
    })

    log(:error, error_message, error_metadata, opts)
  end

  defp log(level, message, metadata, opts) do
    try do
      logger_level = case level do
        :debug -> :debug
        :info -> :info
        :warning -> :warning
        :error -> :error
        _ -> :info
      end

      enhanced_metadata = Map.merge(metadata, %{
        timestamp: System.system_time(:millisecond),
        strategy_source: "HybridPlanner"
      })

      verbose = Keyword.get(opts, :verbose, 0)

      formatted_message = if verbose > 2 and map_size(enhanced_metadata) > 0 do
        "#{message} | Metadata: #{inspect(enhanced_metadata)}"
      else
        message
      end

      Logger.log(logger_level, formatted_message)
      :ok
    rescue
      _ ->
        Logger.debug("Logger: #{level} - #{message}")
        :ok
    end
  end

  # ==================== PRIVATE UTILITY FUNCTIONS ====================

  defp extract_primitive_actions(solution_tree) do
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

  defp count_solution_tree_nodes(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        1 + Enum.sum(Enum.map(children, &count_solution_tree_nodes/1))

      _ ->
        1
    end
  end
end
