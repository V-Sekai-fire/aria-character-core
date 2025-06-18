# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.Strategies.Mock.MockPlanningStrategy do
  @moduledoc """
  Mock planning strategy for testing purposes.
  
  This strategy provides predictable, configurable behavior for testing
  the hybrid planner without dependencies on actual planning algorithms.
  
  ## Configuration Options
  
  - `:plan_result` - What the `plan/2` function should return
  - `:replan_result` - What the `replan/2` function should return  
  - `:validate_result` - What the `validate_plan/2` function should return
  - `:call_delay` - Artificial delay in milliseconds to simulate processing time
  - `:call_count_limit` - Maximum number of calls before returning errors
  - `:should_fail_on` - List of function names that should fail (:plan, :replan, :validate_plan)
  
  ## Usage
  
      # Create mock with successful planning
      mock = MockPlanningStrategy.new(plan_result: {:ok, ["action1", "action2"]})
      
      # Create mock that fails after 3 calls
      mock = MockPlanningStrategy.new(call_count_limit: 3)
      
      # Create mock with artificial delay
      mock = MockPlanningStrategy.new(call_delay: 100)
  """

  @behaviour AriaEngine.HybridPlanner.Strategies.PlanningStrategy

  defstruct [
    :config,
    :call_counts,
    :call_history,
    :metadata
  ]

  @type config :: %{
    plan_result: term(),
    replan_result: term(),
    validate_result: term(),
    call_delay: non_neg_integer(),
    call_count_limit: non_neg_integer() | nil,
    should_fail_on: [atom()],
    track_calls: boolean()
  }

  @type t :: %__MODULE__{
    config: config(),
    call_counts: %{atom() => non_neg_integer()},
    call_history: [map()],
    metadata: map()
  }

  # ==================== CONSTRUCTOR ====================

  @doc """
  Create a new mock planning strategy with the given configuration.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    config = %{
      plan_result: {:ok, []},
      replan_result: {:ok, []},
      validate_result: :ok,
      call_delay: 0,
      call_count_limit: nil,
      should_fail_on: [],
      track_calls: true
    }
    |> Map.merge(Enum.into(opts, %{}))

    %__MODULE__{
      config: config,
      call_counts: %{plan: 0, replan: 0, validate_plan: 0},
      call_history: [],
      metadata: %{
        created_at: System.system_time(:millisecond),
        strategy_type: :mock_planning,
        version: "1.0.0"
      }
    }
  end

  # ==================== STRATEGY BEHAVIOR IMPLEMENTATION ====================

  @impl AriaEngine.HybridPlanner.Strategies.PlanningStrategy
  def plan(%__MODULE__{} = strategy, planning_request) do
    strategy = record_call(strategy, :plan, %{request: planning_request})
    
    with :ok <- check_call_limit(strategy, :plan),
         :ok <- check_should_fail(strategy, :plan),
         :ok <- apply_delay(strategy) do
      strategy.config.plan_result
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl AriaEngine.HybridPlanner.Strategies.PlanningStrategy
  def replan(%__MODULE__{} = strategy, replan_request) do
    strategy = record_call(strategy, :replan, %{request: replan_request})
    
    with :ok <- check_call_limit(strategy, :replan),
         :ok <- check_should_fail(strategy, :replan),
         :ok <- apply_delay(strategy) do
      strategy.config.replan_result
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl AriaEngine.HybridPlanner.Strategies.PlanningStrategy
  def validate_plan(%__MODULE__{} = strategy, validation_request) do
    strategy = record_call(strategy, :validate_plan, %{request: validation_request})
    
    with :ok <- check_call_limit(strategy, :validate_plan),
         :ok <- check_should_fail(strategy, :validate_plan),
         :ok <- apply_delay(strategy) do
      strategy.config.validate_result
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl AriaEngine.HybridPlanner.Strategies.PlanningStrategy
  def strategy_info(%__MODULE__{} = strategy) do
    %{
      name: :mock_planning_strategy,
      type: :planning,
      capabilities: [:plan, :replan, :validate_plan, :configurable_behavior],
      configuration: strategy.config,
      call_counts: strategy.call_counts,
      call_history_length: length(strategy.call_history),
      metadata: strategy.metadata
    }
  end

  # ==================== MOCK-SPECIFIC METHODS ====================

  @doc """
  Get the call history for this mock strategy.
  """
  @spec get_call_history(t()) :: [map()]
  def get_call_history(%__MODULE__{} = strategy) do
    strategy.call_history
  end

  @doc """
  Get the call count for a specific function.
  """
  @spec get_call_count(t(), atom()) :: non_neg_integer()
  def get_call_count(%__MODULE__{} = strategy, function_name) do
    Map.get(strategy.call_counts, function_name, 0)
  end

  @doc """
  Reset the call counts and history.
  """
  @spec reset_calls(t()) :: t()
  def reset_calls(%__MODULE__{} = strategy) do
    %{strategy | 
      call_counts: %{plan: 0, replan: 0, validate_plan: 0},
      call_history: []
    }
  end

  @doc """
  Update the configuration of the mock strategy.
  """
  @spec update_config(t(), map()) :: t()
  def update_config(%__MODULE__{} = strategy, config_updates) do
    updated_config = Map.merge(strategy.config, config_updates)
    %{strategy | config: updated_config}
  end

  @doc """
  Set the result that plan/2 should return.
  """
  @spec set_plan_result(t(), term()) :: t()
  def set_plan_result(%__MODULE__{} = strategy, result) do
    update_config(strategy, %{plan_result: result})
  end

  @doc """
  Set the result that replan/2 should return.
  """
  @spec set_replan_result(t(), term()) :: t()
  def set_replan_result(%__MODULE__{} = strategy, result) do
    update_config(strategy, %{replan_result: result})
  end

  @doc """
  Set the result that validate_plan/2 should return.
  """
  @spec set_validate_result(t(), term()) :: t()
  def set_validate_result(%__MODULE__{} = strategy, result) do
    update_config(strategy, %{validate_result: result})
  end

  @doc """
  Configure which functions should fail.
  """
  @spec set_should_fail_on(t(), [atom()]) :: t()
  def set_should_fail_on(%__MODULE__{} = strategy, function_names) do
    update_config(strategy, %{should_fail_on: function_names})
  end

  @doc """
  Set a call count limit after which functions will fail.
  """
  @spec set_call_limit(t(), non_neg_integer() | nil) :: t()
  def set_call_limit(%__MODULE__{} = strategy, limit) do
    update_config(strategy, %{call_count_limit: limit})
  end

  @doc """
  Check if the mock has been called.
  """
  @spec was_called?(t()) :: boolean()
  def was_called?(%__MODULE__{} = strategy) do
    strategy.call_counts
    |> Map.values()
    |> Enum.sum() > 0
  end

  @doc """
  Check if a specific function was called.
  """
  @spec was_called?(t(), atom()) :: boolean()
  def was_called?(%__MODULE__{} = strategy, function_name) do
    get_call_count(strategy, function_name) > 0
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Record a function call for tracking
  defp record_call(strategy, function_name, call_data) do
    if strategy.config.track_calls do
      updated_counts = Map.update!(strategy.call_counts, function_name, &(&1 + 1))
      
      call_record = %{
        function: function_name,
        timestamp: System.system_time(:millisecond),
        data: call_data
      }
      
      updated_history = [call_record | strategy.call_history]
      
      %{strategy | call_counts: updated_counts, call_history: updated_history}
    else
      strategy
    end
  end

  # Check if the call count limit has been reached
  defp check_call_limit(strategy, function_name) do
    case strategy.config.call_count_limit do
      nil -> :ok
      limit ->
        current_count = get_call_count(strategy, function_name)
        if current_count >= limit do
          {:error, "Call limit reached for #{function_name} (#{limit})"}
        else
          :ok
        end
    end
  end

  # Check if this function should fail based on configuration
  defp check_should_fail(strategy, function_name) do
    if function_name in strategy.config.should_fail_on do
      {:error, "Configured to fail on #{function_name}"}
    else
      :ok
    end
  end

  # Apply artificial delay if configured
  defp apply_delay(strategy) do
    case strategy.config.call_delay do
      0 -> :ok
      delay when delay > 0 ->
        Process.sleep(delay)
        :ok
    end
  end
end
