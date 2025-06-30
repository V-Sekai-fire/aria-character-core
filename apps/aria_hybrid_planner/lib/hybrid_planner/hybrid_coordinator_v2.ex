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

  require Logger
  alias State
  alias Plan.Utils
  alias HybridPlanner.HybridCoordinatorV2.{Planning, Temporal, Execution, Logging}

  defstruct [
    :metadata,
    :performance_data
  ]

  @type t :: %__MODULE__{
          metadata: map(),
          performance_data: map()
        }
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type execution_result :: {:ok, State.t()} | {:error, String.t()}
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
  @spec plan(t(), Domain.Core.t(), State.t(), [term()], keyword()) :: plan_result()
  def plan(_coordinator, domain, state, goals, opts \\ []) do
    _verbose = Keyword.get(opts, :verbose, 0)

    Logging.log_progress("planning", %{status: "started", goals: length(goals), domain: domain.name}, opts)

    try do
      # HTN Planning (from HTNPlanningStrategy)
        case Planning.htn_plan(domain, state, goals, opts) do
        {:ok, solution_tree} ->
          Logging.log_progress("planning", %{
            status: "htn_completed",
            solution_tree_size: count_solution_tree_nodes(solution_tree)
          }, opts)

          # Add temporal constraints (from STNTemporalStrategy)
          case Temporal.add_temporal_constraints_to_plan(solution_tree, domain, opts) do
            {:ok, temporal_constraints} ->
              # Validate temporal consistency
              case Temporal.validate_temporal_consistency(temporal_constraints, opts) do
                {:ok, true} ->
                  Logging.log_progress("planning", %{status: "completed_successfully"}, opts)

                  {:ok, %{
                    solution_tree: solution_tree,
                    temporal_constraints: temporal_constraints,
                    metadata: %{
                      goals: goals,
                      domain_name: domain.name,
                      planning_time: System.system_time(:millisecond),
                      coordinator_metadata: %{implementation: :monolithic}
                    }
                  }}

                {:error, reason} ->
                  Logging.log_error(reason, %{phase: "temporal_validation"}, opts)
                  {:error, "Temporal validation failed: #{reason}"}
              end

            {:error, reason} ->
              Logging.log_error(reason, %{phase: "temporal_constraint_creation"}, opts)
              {:error, "Failed to create temporal constraints: #{reason}"}
          end

        {:error, reason} ->
          Logging.log_error(reason, %{phase: "htn_planning"}, opts)
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        Logging.log_error(error_msg, %{phase: "planning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Validate a plan using HTN planning validation.
  """
  @spec validate_plan(t(), Domain.Core.t(), State.t(), map()) ::
          {:ok, State.t()} | {:error, String.t()}
  def validate_plan(_coordinator, domain, initial_state, plan) do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        Planning.htn_validate_plan(domain, initial_state, solution_tree)
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
  Execute a plan using IPyHOP-style simple execution.

  This function now integrates with the new blacklisting system following
  the IPyHOP pattern where blacklisted commands are checked during execution.
  """
  @spec execute(t(), Domain.Core.t(), State.t(), map(), keyword()) :: execution_result()
  def execute(_coordinator, domain, initial_state, plan, opts \\ []) do
    Logging.log_progress("execution", %{status: "started"}, opts)

    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format - missing solution tree"}
      else
        # Extract or create blacklist state from plan metadata
        blacklist_state = get_or_create_blacklist_state(plan, opts)

        enhanced_opts = opts
        |> Keyword.put(:domain, domain)
        |> Keyword.put(:blacklist_state, blacklist_state)

        case Execution.execute_plan_lazy(solution_tree, initial_state, enhanced_opts) do
          {:ok, final_state} ->
            Logging.log_progress("execution", %{status: "completed_successfully"}, opts)
            {:ok, final_state}

          {:error, reason} ->
            Logging.log_error(reason, %{phase: "execution"}, opts)
            {:error, reason}
        end
      end
    rescue
      e ->
        error_msg = "Execution error: #{Exception.message(e)}"
        Logging.log_error(error_msg, %{phase: "execution_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  # ==================== REPLANNING FUNCTIONS ====================

  @doc """
  Replan from a failure point using HTN replanning.
  """
  @spec replan(t(), Domain.Core.t(), State.t(), map(), String.t(), keyword()) ::
          replan_result()
  def replan(coordinator, domain, state, plan, fail_node_id, opts \\ []) do
    Logging.log_progress("replanning", %{status: "started", fail_node_id: fail_node_id}, opts)

    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for replanning - missing solution tree"}
      else
        case Planning.htn_replan(domain, state, solution_tree, fail_node_id, opts) do
          {:ok, new_solution_tree} ->
            Logging.log_progress("replanning", %{status: "htn_replanning_completed"}, opts)

            case Temporal.add_temporal_constraints_to_plan(new_solution_tree, domain, opts) do
              {:ok, new_temporal_constraints} ->
                case Temporal.validate_temporal_consistency(new_temporal_constraints, opts) do
                  {:ok, true} ->
                    Logging.log_progress("replanning", %{status: "completed_successfully"}, opts)

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


                  {:error, reason} ->
                    Logging.log_error(reason, %{phase: "replanning_temporal_validation"}, opts)
                    {:error, "Replanning temporal validation failed: #{reason}"}
                end

              {:error, reason} ->
                Logging.log_error(reason, %{phase: "replanning_temporal_constraints"}, opts)
                {:error, "Failed to create temporal constraints during replanning: #{reason}"}
            end

          {:error, reason} ->
            Logging.log_error(reason, %{phase: "htn_replanning"}, opts)
            {:error, reason}

          :failure ->
            Logging.log_progress("replanning", %{status: "no_alternatives_found"}, opts)
            :failure
        end
      end
    rescue
      e ->
        error_msg = "Replanning error: #{Exception.message(e)}"
        Logging.log_error(error_msg, %{phase: "replanning_coordinator"}, opts)
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


  # ==================== PRIVATE UTILITY FUNCTIONS ====================

  # Extract or create blacklist state for execution
  defp get_or_create_blacklist_state(plan, opts) do
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
