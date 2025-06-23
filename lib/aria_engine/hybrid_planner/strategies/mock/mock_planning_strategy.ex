defmodule HybridPlanner.Strategies.Mock.MockPlanningStrategy do
  @moduledoc "Mock planning strategy for testing purposes.\n\nThis strategy provides predictable, configurable behavior for testing\nthe hybrid planner without dependencies on actual planning algorithms.\nUses static configuration via application environment for simplicity.\n\n## Configuration\n\nConfigure mock behavior via application environment:\n\n```elixir\n# Set custom results for testing\nApplication.put_env(:aria_engine, :mock_plan_result, {:ok, [%{action: :test_action, args: [\"result\"]}]})\nApplication.put_env(:aria_engine, :mock_replan_result, {:error, \"replan failed\"})\nApplication.put_env(:aria_engine, :mock_validate_result, {:ok, %AriaEngine.StateV2{}})\n```\n\n## Usage\n\n```elixir\n# Use in tests with default successful behavior\nfactory = StrategyFactory.new(%{planning_strategy: MockPlanningStrategy})\n\n# Configure specific results for test scenarios\nApplication.put_env(:aria_engine, :mock_plan_result, {:error, \"planning failed\"})\nresult = MockPlanningStrategy.plan(domain, state, goals, [])\n# => {:error, \"planning failed\"}\n```\n"
  @behaviour HybridPlanner.Strategies.PlanningStrategy
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
  @default_validate_result {:ok, %AriaEngine.State{}}
  @impl HybridPlanner.Strategies.PlanningStrategy
  def plan(_domain, _state, _goals, opts \\ []) do
    apply_delay(opts)
    Application.get_env(:aria_engine, :mock_plan_result, @default_plan_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def replan(_domain, _state, _solution_tree, _fail_node_id, opts \\ []) do
    apply_delay(opts)
    Application.get_env(:aria_engine, :mock_replan_result, @default_replan_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def validate_plan(_domain, _state, _solution_tree) do
    Application.get_env(:aria_engine, :mock_validate_result, @default_validate_result)
  end

  @impl HybridPlanner.Strategies.PlanningStrategy
  def strategy_info do
    %{
      name: "Mock Planning Strategy",
      version: "1.0.0",
      type: :mock,
      description: "Configurable mock strategy for testing",
      capabilities: [:plan, :replan, :validate_plan, :configurable_results],
      limitations: [:no_actual_planning, :static_configuration_only],
      configuration: %{
        plan_result: Application.get_env(:aria_engine, :mock_plan_result, @default_plan_result),
        replan_result:
          Application.get_env(:aria_engine, :mock_replan_result, @default_replan_result),
        validate_result:
          Application.get_env(:aria_engine, :mock_validate_result, @default_validate_result)
      }
    }
  end

  @doc "Backward compatibility constructor - converts old instance pattern to static config.\n\nThis function provides compatibility with existing tests that use the old API.\nInstead of returning a struct, it configures the static mock behavior.\n\n## Parameters\n- `opts`: Configuration options (same as old API)\n\n## Returns\n- Module name for use with strategy factory\n"
  @spec new(keyword()) :: module()
  def new(opts \\ []) do
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

    configure(config)
    __MODULE__
  end

  @doc "Configure mock planning result.\n\n## Parameters\n- `result`: Result to return from plan/4 calls\n\n## Examples\n\n    MockPlanningStrategy.set_plan_result({:ok, [action1, action2]})\n    MockPlanningStrategy.set_plan_result({:error, \"planning failed\"})\n"
  @spec set_plan_result(term()) :: :ok
  def set_plan_result(result) do
    Application.put_env(:aria_engine, :mock_plan_result, result)
  end

  @doc "Configure mock replanning result.\n\n## Parameters\n- `result`: Result to return from replan/5 calls\n"
  @spec set_replan_result(term()) :: :ok
  def set_replan_result(result) do
    Application.put_env(:aria_engine, :mock_replan_result, result)
  end

  @doc "Configure mock validation result.\n\n## Parameters\n- `result`: Result to return from validate_plan/3 calls\n"
  @spec set_validate_result(term()) :: :ok
  def set_validate_result(result) do
    Application.put_env(:aria_engine, :mock_validate_result, result)
  end

  @doc "Reset all mock configuration to defaults.\n"
  @spec reset_config() :: :ok
  def reset_config do
    Application.delete_env(:aria_engine, :mock_plan_result)
    Application.delete_env(:aria_engine, :mock_replan_result)
    Application.delete_env(:aria_engine, :mock_validate_result)
    Application.delete_env(:aria_engine, :mock_delay_ms)
    :ok
  end

  @doc "Configure artificial delay for all mock operations.\n\n## Parameters\n- `delay_ms`: Delay in milliseconds (0 to disable)\n"
  @spec set_delay(non_neg_integer()) :: :ok
  def set_delay(delay_ms) when is_integer(delay_ms) and delay_ms >= 0 do
    Application.put_env(:aria_engine, :mock_delay_ms, delay_ms)
  end

  @doc "Configure multiple mock results at once.\n\n## Parameters\n- `config`: Map with `:plan_result`, `:replan_result`, `:validate_result` keys\n\n## Example\n\n    MockPlanningStrategy.configure(%{\n      plan_result: {:ok, [action1]},\n      replan_result: {:error, \"replan failed\"},\n      validate_result: {:ok, final_state}\n    })\n"
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

  @doc "Create a simple successful solution tree for testing.\n\n## Parameters\n- `actions`: List of action names to include (default: [:mock_action])\n\n## Returns\n- Solution tree structure suitable for testing\n"
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

  @doc "Create a mock state with basic test data.\n\n## Returns\n- StateV2 instance suitable for testing\n"
  @spec create_mock_state() :: AriaEngine.State.t()
  def create_mock_state do
    state = %AriaEngine.State{}

    case function_exported?(AriaEngine.State, :add_fact, 4) do
      true ->
        state
        |> AriaEngine.State.add_fact("mock_predicate", "mock_subject", "mock_value")
        |> AriaEngine.State.add_fact("test_ready", "system", true)

      false ->
        state
    end
  end

  defp apply_delay(opts) do
    delay_ms =
      Keyword.get(opts, :mock_delay_ms) || Application.get_env(:aria_engine, :mock_delay_ms, 0)

    if delay_ms > 0 do
      Process.sleep(delay_ms)
    end
  end
end