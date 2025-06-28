# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.Core do
  @moduledoc """
  Unified API for the Aria Hybrid Planner.

  This module provides the single, authoritative interface for all hybrid planning
  functionality, consolidating the previously fragmented APIs into a coherent,
  easy-to-use interface.

  ## Features

  - **HTN Planning**: Hierarchical Task Network planning with method decomposition
  - **Temporal Constraints**: Integration with temporal constraint solving
  - **IPyHOP Execution**: Simple, fail-fast execution following IPyHOP patterns
  - **Replanning**: Intelligent replanning from failure points
  - **Blacklisting**: Method and command blacklisting for failure recovery

  ## Basic Usage

      # Create a coordinator
      coordinator = AriaHybridPlanner.Core.new_coordinator()

      # Plan goals
      case AriaHybridPlanner.Core.plan(coordinator, domain, state, goals) do
        {:ok, plan} ->
          # Execute the plan
          case AriaHybridPlanner.Core.execute(coordinator, domain, state, plan) do
            {:ok, final_state} ->
              IO.puts("Planning and execution successful!")
            {:error, exec_reason} ->
              IO.puts("Execution failed: \#{exec_reason}")
          end
        {:error, plan_reason} ->
          IO.puts("Planning failed: \#{plan_reason}")
      end

  ## Advanced Usage

      # Plan with options
      opts = [verbose: 2, timeout: 30_000]
      {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, domain, state, goals, opts)

      # Validate a plan before execution
      case AriaHybridPlanner.Core.validate_plan(coordinator, domain, state, plan) do
        {:ok, _final_state} ->
          # Plan is valid, proceed with execution
          AriaHybridPlanner.Core.execute(coordinator, domain, state, plan)
        {:error, validation_reason} ->
          IO.puts("Plan validation failed: \#{validation_reason}")
      end

      # Handle execution failures with replanning
      case AriaHybridPlanner.Core.execute(coordinator, domain, state, plan) do
        {:ok, final_state} ->
          final_state
        {:error, exec_reason} ->
          # Attempt replanning from failure point
          case AriaHybridPlanner.Core.replan(coordinator, domain, state, plan, "failed_node_id") do
            {:ok, new_plan} ->
              AriaHybridPlanner.Core.execute(coordinator, domain, state, new_plan)
            {:error, replan_reason} ->
              {:error, "Both execution and replanning failed: \#{exec_reason}, \#{replan_reason}"}
          end
      end

  ## Types

  All types are properly specified for Dialyzer compatibility and clear documentation.
  """

  # Import types from existing modules for compatibility
  alias HybridPlanner.HybridCoordinatorV2
  alias AriaEngine.Domain.Core, as: Domain
  alias AriaEngine.State

  @type coordinator :: HybridCoordinatorV2.t()
  @type domain :: Domain.t()
  @type state :: State.t()
  @type goals :: [term()]
  @type plan :: map()
  @type plan_result :: {:ok, plan()} | {:error, String.t()}
  @type execution_result :: {:ok, state()} | {:error, String.t()}
  @type validation_result :: {:ok, state()} | {:error, String.t()}
  @type replan_result :: {:ok, plan()} | {:error, String.t()} | :failure

  # ==================== COORDINATOR MANAGEMENT ====================

  @doc """
  Create a new hybrid planning coordinator with default configuration.

  The coordinator manages planning strategies, execution patterns, and maintains
  state for replanning operations.

  ## Options

  - `:verbose` - Verbosity level (0-3, default: 0)
  - `:timeout` - Planning timeout in milliseconds (default: 30_000)
  - `:max_depth` - Maximum planning depth (default: 100)

  ## Examples

      coordinator = AriaHybridPlanner.Core.new_coordinator()

      coordinator = AriaHybridPlanner.Core.new_coordinator(verbose: 2, timeout: 60_000)
  """
  @spec new_coordinator(keyword()) :: coordinator()
  def new_coordinator(opts \\ []) do
    HybridCoordinatorV2.new_default(opts)
  end

  @doc """
  Create a coordinator with custom strategy configuration.

  For advanced users who need to customize the planning strategies.
  Note: In the current monolithic implementation, strategies are inlined,
  but this function maintains API compatibility.

  ## Examples

      strategies = %{htn_strategy: CustomHTNStrategy}
      coordinator = AriaHybridPlanner.Core.new_coordinator_with_strategies(strategies)
  """
  @spec new_coordinator_with_strategies(map(), keyword()) :: coordinator()
  def new_coordinator_with_strategies(strategies, opts \\ []) do
    HybridCoordinatorV2.new(strategies, opts)
  end

  # ==================== PLANNING FUNCTIONS ====================

  @doc """
  Plan to achieve the given goals using HTN planning with temporal constraints.

  This is the main planning function that combines HTN planning with temporal
  constraint validation to produce executable plans.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain with actions and methods
  - `state` - The current world state
  - `goals` - List of goals to achieve
  - `opts` - Planning options (optional)

  ## Options

  - `:verbose` - Verbosity level (0-3, default: 0)
  - `:timeout` - Planning timeout in milliseconds
  - `:current_time` - Current time for temporal planning
  - `:max_depth` - Maximum planning depth

  ## Returns

  - `{:ok, plan}` - Planning successful, returns executable plan
  - `{:error, reason}` - Planning failed with error message

  ## Examples

      case AriaHybridPlanner.Core.plan(coordinator, domain, state, goals) do
        {:ok, plan} ->
          IO.puts("Planning successful!")
        {:error, plan_reason} ->
          IO.puts("Planning failed: \#{plan_reason}")
      end

      # With options
      opts = [verbose: 2, timeout: 60_000, current_time: 1000]
      {:ok, plan} = AriaHybridPlanner.Core.plan(coordinator, domain, state, goals, opts)
  """
  @spec plan(coordinator(), domain(), state(), goals(), keyword()) :: plan_result()
  def plan(coordinator, domain, state, goals, opts \\ []) do
    HybridCoordinatorV2.plan(coordinator, domain, state, goals, opts)
  end

  @doc """
  Validate a plan without executing it.

  This function checks if a plan is valid by simulating its execution
  and verifying that all actions can be applied successfully.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain
  - `state` - The initial state for validation
  - `plan` - The plan to validate

  ## Returns

  - `{:ok, final_state}` - Plan is valid, returns predicted final state
  - `{:error, reason}` - Plan validation failed

  ## Examples

      case AriaHybridPlanner.Core.validate_plan(coordinator, domain, state, plan) do
        {:ok, final_state} ->
          IO.puts("Plan is valid, final state: \#{inspect(final_state)}")
        {:error, validation_reason} ->
          IO.puts("Plan validation failed: \#{validation_reason}")
      end
  """
  @spec validate_plan(coordinator(), domain(), state(), plan()) :: validation_result()
  def validate_plan(coordinator, domain, state, plan) do
    HybridCoordinatorV2.validate_plan(coordinator, domain, state, plan)
  end

  # ==================== EXECUTION FUNCTIONS ====================

  @doc """
  Execute a plan using IPyHOP-style simple execution.

  This function executes a plan step-by-step, following the IPyHOP pattern
  of fail-fast execution with detailed execution traces for debugging.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain
  - `state` - The initial state for execution
  - `plan` - The plan to execute
  - `opts` - Execution options (optional)

  ## Options

  - `:verbose` - Verbosity level (0-3, default: 0)
  - `:blacklist_state` - Existing blacklist state for command filtering

  ## Returns

  - `{:ok, final_state}` - Execution successful, returns final state
  - `{:error, reason}` - Execution failed with error message

  ## Examples

      case AriaHybridPlanner.Core.execute(coordinator, domain, state, plan) do
        {:ok, final_state} ->
          IO.puts("Execution successful!")
        {:error, exec_reason} ->
          IO.puts("Execution failed: \#{exec_reason}")
      end

      # With options
      opts = [verbose: 2, blacklist_state: existing_blacklist]
      {:ok, final_state} = AriaHybridPlanner.Core.execute(coordinator, domain, state, plan, opts)
  """
  @spec execute(coordinator(), domain(), state(), plan(), keyword()) :: execution_result()
  def execute(coordinator, domain, state, plan, opts \\ []) do
    HybridCoordinatorV2.execute(coordinator, domain, state, plan, opts)
  end

  # ==================== REPLANNING FUNCTIONS ====================

  @doc """
  Replan from a failure point using HTN replanning with blacklisting.

  When execution fails, this function attempts to find an alternative plan
  by replanning from the failure point while blacklisting the failed approach.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain
  - `state` - The current state at failure point
  - `plan` - The original plan that failed
  - `fail_node_id` - Identifier of the failed node for replanning
  - `opts` - Replanning options (optional)

  ## Options

  - `:verbose` - Verbosity level (0-3, default: 0)
  - `:max_replan_attempts` - Maximum replanning attempts

  ## Returns

  - `{:ok, new_plan}` - Replanning successful, returns new plan
  - `{:error, reason}` - Replanning failed with error message
  - `:failure` - No alternative plans available

  ## Examples

      case AriaHybridPlanner.Core.replan(coordinator, domain, state, plan, "failed_action_123") do
        {:ok, new_plan} ->
          IO.puts("Replanning successful!")
        {:error, replan_reason} ->
          IO.puts("Replanning failed: \#{replan_reason}")
        :failure ->
          IO.puts("No alternative plans available")
      end
  """
  @spec replan(coordinator(), domain(), state(), plan(), String.t(), keyword()) :: replan_result()
  def replan(coordinator, domain, state, plan, fail_node_id, opts \\ []) do
    HybridCoordinatorV2.replan(coordinator, domain, state, plan, fail_node_id, opts)
  end

  # ==================== UTILITY FUNCTIONS ====================

  @doc """
  Get information about the coordinator's current configuration.

  Returns details about the strategies, performance metrics, and configuration
  of the planning coordinator.

  ## Examples

      info = AriaHybridPlanner.Core.get_coordinator_info(coordinator)
      IO.inspect(info)
  """
  @spec get_coordinator_info(coordinator()) :: map()
  def get_coordinator_info(coordinator) do
    HybridCoordinatorV2.get_strategy_info(coordinator)
  end

  @doc """
  Get performance metrics from the coordinator.

  Returns performance data including planning times, execution counts,
  and other operational metrics.

  ## Examples

      metrics = AriaHybridPlanner.Core.get_performance_metrics(coordinator)
      IO.puts("Plans created: \#{metrics.plans_created}")
  """
  @spec get_performance_metrics(coordinator()) :: map()
  def get_performance_metrics(coordinator) do
    HybridCoordinatorV2.get_performance_metrics(coordinator)
  end

  @doc """
  Get the version of the AriaHybridPlanner application.

  ## Examples

      version = AriaHybridPlanner.Core.version()
      IO.puts("Hybrid Planner version: \#{version}")
  """
  @spec version() :: String.t()
  def version do
    AriaHybridPlanner.version()
  end

  # ==================== CONVENIENCE FUNCTIONS ====================

  @doc """
  Plan and execute goals in a single operation.

  This convenience function combines planning and execution into a single
  call, handling the common case where you want to plan and immediately
  execute the resulting plan.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain
  - `state` - The initial state
  - `goals` - List of goals to achieve
  - `opts` - Combined planning and execution options

  ## Returns

  - `{:ok, final_state}` - Planning and execution successful
  - `{:error, reason}` - Either planning or execution failed

  ## Examples

      case AriaHybridPlanner.Core.plan_and_execute(coordinator, domain, state, goals) do
        {:ok, final_state} ->
          IO.puts("Success! Final state: \#{inspect(final_state)}")
        {:error, reason} ->
          IO.puts("Failed: \#{reason}")
      end
  """
  @spec plan_and_execute(coordinator(), domain(), state(), goals(), keyword()) :: execution_result()
  def plan_and_execute(coordinator, domain, state, goals, opts \\ []) do
    case plan(coordinator, domain, state, goals, opts) do
      {:ok, plan} ->
        execute(coordinator, domain, state, plan, opts)
      {:error, reason} ->
        {:error, "Planning failed: #{reason}"}
    end
  end

  @doc """
  Plan, execute, and handle failures with automatic replanning.

  This high-level function provides automatic failure recovery by attempting
  replanning when execution fails.

  ## Parameters

  - `coordinator` - The planning coordinator
  - `domain` - The planning domain
  - `state` - The initial state
  - `goals` - List of goals to achieve
  - `opts` - Combined options for all operations

  ## Options

  - `:max_replan_attempts` - Maximum replanning attempts (default: 3)
  - All planning and execution options

  ## Returns

  - `{:ok, final_state}` - Success (possibly after replanning)
  - `{:error, reason}` - All attempts failed

  ## Examples

      case AriaHybridPlanner.Core.plan_execute_with_recovery(coordinator, domain, state, goals) do
        {:ok, final_state} ->
          IO.puts("Success (possibly after replanning)!")
        {:error, reason} ->
          IO.puts("All attempts failed: \#{reason}")
      end
  """
  @spec plan_execute_with_recovery(coordinator(), domain(), state(), goals(), keyword()) :: execution_result()
  def plan_execute_with_recovery(coordinator, domain, state, goals, opts \\ []) do
    _max_attempts = Keyword.get(opts, :max_replan_attempts, 3)

    case plan_and_execute(coordinator, domain, state, goals, opts) do
      {:ok, final_state} ->
        {:ok, final_state}
      {:error, reason} ->
        # TODO: Implement automatic replanning with failure recovery
        # This would require extracting failure information and attempting replanning
        {:error, "Execution failed and automatic recovery not yet implemented: #{reason}"}
    end
  end
end
