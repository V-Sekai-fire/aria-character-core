# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Mock.MockPlanningStrategy do
  @moduledoc """
  Mock planning strategy for testing purposes.

  This strategy provides predictable, configurable behavior for testing
  the hybrid planner without dependencies on actual planning algorithms.
  Uses static configuration via application environment for simplicity.

  ## Configuration

  Configure mock behavior via application environment:

  ```elixir
  # Set custom results for testing
  Application.put_env(:aria_engine, :mock_plan_result, {:ok, [%{action: :test_action, args: ["result"]}]})
  Application.put_env(:aria_engine, :mock_replan_result, {:error, "replan failed"})
  Application.put_env(:aria_engine, :mock_validate_result, {:ok, %State{}})
  ```

  ## Usage

  ```elixir
  # Use in tests with default successful behavior
  factory = StrategyFactory.new(%{planning_strategy: MockPlanningStrategy})

  # Configure specific results for test scenarios
  Application.put_env(:aria_engine, :mock_plan_result, {:error, "planning failed"})
  result = MockPlanningStrategy.plan(domain, state, goals, [])
  # => {:error, "planning failed"}
  ```
  """

  @behaviour HybridPlanner.Strategies.PlanningStrategy

  # Default static configuration
  @default_plan_result {:ok,
                        [%{action: :mock_action, args: ["mock_result"], node_id: "mock_node_1"}]}
  @default_replan_result {:ok,
                          [
                            %{
                              action: :mock_replan_action,
                              args: ["mock_replan_result"],
                              node_id: "mock_node_2"
                            }
                          ]}
  @default_validate_result {:ok, %State{}}

  # ==================== BEHAVIOR IMPLEMENTATION ====================

  @impl HybridPlanner.Strategies.PlanningStrategy
  def plan(_domain, _state, _goals, opts \\ []) do
    # Check for artificial delay configuration
    apply_delay(opts)

    # Return configured result or default
    Application.get_env(:aria_engine, :mock_plan_result, @default_plan_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def replan(_domain, _state, _solution_tree, _fail_node_id, opts \\ []) do
    # Check for artificial delay configuration
    apply_delay(opts)

    # Return configured result or default
    Application.get_env(:aria_engine, :mock_replan_result, @default_replan_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def validate_plan(_domain, _state, _solution_tree) do
    # Return configured result or default
    Application.get_env(:aria_engine, :mock_validate_result, @default_validate_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def strategy_info do
    %{
      name: "Mock Planning Strategy",
      version: "1.0.0",
      type: :mock,
      description: "Configurable mock strategy for testing",
      capabilities: [
        :plan,
        :replan,
        :validate_plan,
        :configurable_results
      ],
      limitations: [
        :no_actual_planning,
        :static_configuration_only
      ],
      configuration: %{
        plan_result: Application.get_env(:aria_engine, :mock_plan_result, @default_plan_result),
        replan_result:
          Application.get_env(:aria_engine, :mock_replan_result, @default_replan_result),
        validate_result:
          Application.get_env(:aria_engine, :mock_validate_result, @default_validate_result)
      }
    }
  end

  # ==================== BACKWARD COMPATIBILITY ====================

  @doc """
  Backward compatibility constructor - converts old instance pattern to static config.

  This function provides compatibility with existing tests that use the old API.
  Instead of returning a struct, it configures the static mock behavior.

  ## Parameters
  - `opts`: Configuration options (same as old API)

  ## Returns
  - Module name for use with strategy factory
  """
  @spec new(keyword()) :: module()
  def new(opts \\ []) do
    # Convert old options to new static configuration
    initial_config = %{}

    config =
      if Keyword.has_key?(opts, :plan_result) do
        Map.put(initial_config, :plan_result, Keyword.get(opts, :plan_result))
      else
        initial_config
      end

    config =
      if Keyword.has_key?(opts, :replan_result) do
        Map.put(config, :replan_result, Keyword.get(opts, :replan_result))
      else
        config
      end

    config =
      if Keyword.has_key?(opts, :validate_result) do
        Map.put(config, :validate_result, Keyword.get(opts, :validate_result))
      else
        config
      end

    config =
      if Keyword.has_key?(opts, :call_delay) do
        Map.put(config, :delay_ms, Keyword.get(opts, :call_delay))
      else
        config
      end

    # Apply the configuration
    configure(config)

    # Return the module name for use with strategy factory
    __MODULE__
  end

  # ==================== CONFIGURATION HELPERS ====================

  @doc """
  Configure mock planning result.

  ## Parameters
  - `result`: Result to return from plan/4 calls

  ## Examples

      MockPlanningStrategy.set_plan_result({:ok, [action1, action2]})
      MockPlanningStrategy.set_plan_result({:error, "planning failed"})
  """
  @spec set_plan_result(term()) :: :ok
  def set_plan_result(result) do
    Application.put_env(:aria_engine, :mock_plan_result, result)
  end

  @doc """
  Configure mock replanning result.

  ## Parameters
  - `result`: Result to return from replan/5 calls
  """
  @spec set_replan_result(term()) :: :ok
  def set_replan_result(result) do
    Application.put_env(:aria_engine, :mock_replan_result, result)
  end

  @doc """
  Configure mock validation result.

  ## Parameters
  - `result`: Result to return from validate_plan/3 calls
  """
  @spec set_validate_result(term()) :: :ok
  def set_validate_result(result) do
    Application.put_env(:aria_engine, :mock_validate_result, result)
  end

  @doc """
  Reset all mock configuration to defaults.
  """
  @spec reset_config() :: :ok
  def reset_config do
    Application.delete_env(:aria_engine, :mock_plan_result)
    Application.delete_env(:aria_engine, :mock_replan_result)
    Application.delete_env(:aria_engine, :mock_validate_result)
    Application.delete_env(:aria_engine, :mock_delay_ms)
    :ok
  end

  @doc """
  Configure artificial delay for all mock operations.

  ## Parameters
  - `delay_ms`: Delay in milliseconds (0 to disable)
  """
  @spec set_delay(non_neg_integer()) :: :ok
  def set_delay(delay_ms) when is_integer(delay_ms) and delay_ms >= 0 do
    Application.put_env(:aria_engine, :mock_delay_ms, delay_ms)
  end

  @doc """
  Configure multiple mock results at once.

  ## Parameters
  - `config`: Map with `:plan_result`, `:replan_result`, `:validate_result` keys

  ## Example

      MockPlanningStrategy.configure(%{
        plan_result: {:ok, [action1]},
        replan_result: {:error, "replan failed"},
        validate_result: {:ok, final_state}
      })
  """
  @spec configure(map()) :: :ok
  def configure(config) when is_map(config) do
    if Map.has_key?(config, :plan_result) do
      set_plan_result(config.plan_result)
    end

    if Map.has_key?(config, :replan_result) do
      set_replan_result(config.replan_result)
    end

    if Map.has_key?(config, :validate_result) do
      set_validate_result(config.validate_result)
    end

    if Map.has_key?(config, :delay_ms) do
      set_delay(config.delay_ms)
    end

    :ok
  end

  # ==================== TESTING HELPERS ====================

  @doc """
  Create a simple successful solution tree for testing.

  ## Parameters
  - `actions`: List of action names to include (default: [:mock_action])

  ## Returns
  - Solution tree structure suitable for testing
  """
  @spec create_mock_solution_tree([atom()]) :: Plan.solution_tree()
  def create_mock_solution_tree(actions \\ [:mock_action]) do
    actions
    |> Enum.with_index(1)
    |> Enum.map(fn {action, index} ->
      %{
        action: action,
        args: ["mock_result_#{index}"],
        node_id: "mock_node_#{index}",
        status: :completed
      }
    end)
  end

  @doc """
  Create a mock state with basic test data.

  ## Returns
  - State instance suitable for testing
  """
  @spec create_mock_state() :: State.t()
  def create_mock_state do
    # Create a basic State with some test facts
    %State{}
    |> State.set_fact("mock_subject", "mock_predicate", "mock_value")
    |> State.set_fact("test_ready", "system", true)
  end

  # ==================== PRIVATE HELPERS ====================

  # Apply artificial delay if configured
  defp apply_delay(opts) do
    # Check for delay in opts first, then application config
    delay_ms =
      Keyword.get(opts, :mock_delay_ms) ||
        Application.get_env(:aria_engine, :mock_delay_ms, 0)

    if delay_ms > 0 do
      Process.sleep(delay_ms)
    end
  end
end
