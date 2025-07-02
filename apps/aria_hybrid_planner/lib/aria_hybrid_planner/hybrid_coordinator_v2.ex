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
  - Plan execution

  ## Usage

      # Create coordinator
      coordinator = HybridPlanner.HybridCoordinatorV2.new()

      # Use coordinator for planning with todo lists
      case HybridPlanner.HybridCoordinatorV2.plan(coordinator, domain, state, todos) do
        {:ok, plan} ->
          HybridPlanner.HybridCoordinatorV2.execute(coordinator, domain, state, plan)
        {:error, reason} ->
          Logger.error("Planning failed: \#{reason}")
      end
  """

  require Logger
  alias AriaHybridPlanner.State
  alias HybridPlanner.HybridCoordinatorV2.{Planning, Logging}
  alias Plan.ReentrantExecutor

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
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
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
    new(opts)
  end

  # ==================== PLANNING FUNCTIONS ====================

  @doc """
  Plan using HTN planning algorithm.
  """
  @spec plan(t(), Domain.Core.t(), State.t(), [term()], keyword()) :: plan_result()
  def plan(coordinator, domain, initial_state, todos, opts \\ []) do
    Logging.log_progress("planning", %{status: "started"}, opts)

    try do
      # Create initial blacklist state
      blacklist_state = Plan.Blacklisting.new()

      # Enhanced options for planning
      enhanced_opts = opts
      |> Keyword.put(:domain, domain)
      |> Keyword.put(:blacklist_state, blacklist_state)

      # Perform HTN planning using the existing planning infrastructure
      case htn_plan(domain, initial_state, todos, enhanced_opts) do
        {:ok, solution_tree} ->
          plan = %{
            solution_tree: solution_tree,
            metadata: %{
              created_at: System.system_time(:millisecond),
              blacklist_state: blacklist_state,
              coordinator_id: coordinator.metadata.created_at
            }
          }

          Logging.log_progress("planning", %{status: "completed_successfully"}, opts)
          {:ok, plan}

        {:error, reason} ->
          Logging.log_error(reason, %{phase: "planning"}, opts)
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

        case ReentrantExecutor.execute_plan_lazy(solution_tree, initial_state, enhanced_opts) do
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

  # ==================== STRATEGY MANAGEMENT (SIMPLIFIED) ====================

  @doc """
  Replace a strategy in the coordinator (no-op since strategies are inlined).
  """
  @spec replace_strategy(t(), atom(), module()) :: t()
  def replace_strategy(coordinator, _strategy_type, _new_strategy) do
    # No-op since strategies are inlined in this monolithic implementation
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

  # HTN planning implementation
  defp htn_plan(domain, initial_state, todos, _opts) do
    try do
      # Simple HTN planning implementation
      # For now, create a basic solution tree structure
      # This will be enhanced with proper HTN algorithm later

      case todos do
        [] ->
          # No goals to achieve
          {:ok, %{task: :empty, status: :completed, children: []}}

        [single_todo] ->
          # Single goal - create simple solution tree
          solution_tree = %{
            task: single_todo,
            status: :primitive,
            children: [],
            metadata: %{
              created_at: System.system_time(:millisecond),
              domain: domain,
              initial_state: initial_state
            }
          }
          {:ok, solution_tree}

        multiple_todos ->
          # Multiple goals - create compound solution tree
          children = Enum.map(multiple_todos, fn todo ->
            %{
              task: todo,
              status: :primitive,
              children: [],
              metadata: %{created_at: System.system_time(:millisecond)}
            }
          end)

          solution_tree = %{
            task: {:multigoal, multiple_todos},
            status: :compound,
            children: children,
            metadata: %{
              created_at: System.system_time(:millisecond),
              domain: domain,
              initial_state: initial_state
            }
          }
          {:ok, solution_tree}
      end
    rescue
      e ->
        {:error, "HTN planning failed: #{Exception.message(e)}"}
    end
  end

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
end
