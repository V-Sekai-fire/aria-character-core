# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.Coordinator do
  @moduledoc """
  Simplified coordinator for hybrid planning operations.

  This module provides a clean interface for planning and execution operations,
  consolidating the functionality from the previous HybridCoordinatorV2 system
  while leveraging the existing mature planning infrastructure.

  ## Usage

      # Create coordinator
      coordinator = AriaHybridPlanner.Coordinator.new()

      # Plan and execute
      case AriaHybridPlanner.Coordinator.plan(coordinator, domain, state, todos) do
        {:ok, plan} ->
          AriaHybridPlanner.Coordinator.execute(coordinator, domain, state, plan)
        {:error, reason} ->
          Logger.error("Planning failed: \#{reason}")
      end
  """

  require Logger
  alias AriaHybridPlanner.State
  alias Plan.{Utils, ReentrantExecutor, Blacklisting}

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
        implementation: :consolidated
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
  Plan using the existing planning infrastructure.
  """
  @spec plan(t(), Domain.Core.t(), State.t(), [term()], keyword()) :: plan_result()
  def plan(coordinator, _domain, initial_state, todos, opts \\ []) do
    log_progress("planning", %{status: "started"}, opts)

    try do
      # Create initial solution tree using existing infrastructure
      solution_tree = Utils.create_initial_solution_tree(todos, initial_state)

      # For now, create a simple plan structure
      # This can be enhanced with proper HTN planning later
      enhanced_solution_tree = case todos do
        [] ->
          # No goals to achieve
          %{solution_tree | nodes: Map.put(solution_tree.nodes, solution_tree.root_id,
            %{solution_tree.nodes[solution_tree.root_id] | expanded: true})}

        _ ->
          # Create primitive action nodes for each todo
          {updated_tree, child_ids} = Enum.reduce(todos, {solution_tree, []}, fn todo, {tree, child_ids} ->
            child_id = Utils.generate_node_id()

            child_node = %{
              id: child_id,
              task: todo,
              parent_id: tree.root_id,
              children_ids: [],
              state: initial_state,
              visited: true,
              expanded: true,
              method_tried: nil,
              blacklisted_methods: [],
              is_primitive: Utils.is_primitive_task?(todo),
              is_durative: false
            }

            updated_nodes = Map.put(tree.nodes, child_id, child_node)
            updated_tree = %{tree | nodes: updated_nodes}
            {updated_tree, [child_id | child_ids]}
          end)

          # Update root node with children
          root_node = updated_tree.nodes[updated_tree.root_id]
          updated_root = %{root_node | children_ids: Enum.reverse(child_ids), expanded: true}
          %{updated_tree | nodes: Map.put(updated_tree.nodes, updated_tree.root_id, updated_root)}
      end

      plan = %{
        solution_tree: enhanced_solution_tree,
        metadata: %{
          created_at: System.system_time(:millisecond),
          coordinator_id: coordinator.metadata.created_at
        }
      }

      log_progress("planning", %{status: "completed_successfully"}, opts)
      {:ok, plan}

    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        log_error(error_msg, %{phase: "planning"}, opts)
        {:error, error_msg}
    end
  end

  @doc """
  Validate a plan using the existing validation infrastructure.
  """
  @spec validate_plan(t(), Domain.Core.t(), State.t(), map()) ::
          {:ok, State.t()} | {:error, String.t()}
  def validate_plan(_coordinator, domain, initial_state, plan) do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        Utils.validate_plan(domain, initial_state, Utils.get_primitive_actions_dfs(solution_tree))
      end
    rescue
      e -> {:error, "Plan validation error: #{Exception.message(e)}"}
    end
  end

  # ==================== EXECUTION FUNCTIONS ====================

  @doc """
  Execute a plan using the existing execution infrastructure.
  """
  @spec execute(t(), Domain.Core.t(), State.t(), map(), keyword()) :: execution_result()
  def execute(_coordinator, domain, initial_state, plan, opts \\ []) do
    log_progress("execution", %{status: "started"}, opts)

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

  # ==================== STRATEGY MANAGEMENT (SIMPLIFIED) ====================

  @doc """
  Get strategy information from the coordinator.
  """
  @spec get_strategy_info(t()) :: map()
  def get_strategy_info(coordinator) do
    %{
      implementation: :consolidated,
      uses_existing_infrastructure: [
        :plan_utils,
        :reentrant_executor,
        :aria_engine_core_plan,
        :blacklisting
      ],
      coordinator_metadata: coordinator.metadata
    }
  end

  @doc """
  Get performance metrics from the coordinator.
  """
  @spec get_performance_metrics(t()) :: map()
  def get_performance_metrics(coordinator) do
    Map.merge(coordinator.performance_data, %{
      coordinator_created_at: coordinator.metadata.created_at,
      implementation: :consolidated
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
            # Create new blacklist state
            Blacklisting.new()

          existing_blacklist_state ->
            existing_blacklist_state
        end

      provided_blacklist_state ->
        provided_blacklist_state
    end
  end

  # ==================== LOGGING FUNCTIONS ====================

  @doc """
  Log progress for different phases of planning and execution.
  """
  @spec log_progress(String.t(), map(), keyword()) :: :ok
  def log_progress(phase, progress, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 0 do
      case phase do
        "planning" ->
          message = "Planning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        "execution" ->
          message = "Execution phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)

        _ ->
          message = "#{phase}: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, Map.put(progress, :phase, phase), opts)
      end
    else
      :ok
    end
  end

  @doc """
  Log errors with context and metadata.
  """
  @spec log_error(term(), map(), keyword()) :: :ok
  def log_error(error, context, opts) do
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

  @doc """
  Generic logging function with structured metadata.
  """
  @spec log(atom(), String.t(), map(), keyword()) :: :ok
  def log(level, message, metadata, opts) do
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
        strategy_source: "AriaHybridPlanner"
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
end
