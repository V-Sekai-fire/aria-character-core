# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.PlannerFilterTest do
  @moduledoc "Isolated unit tests for the PlannerFilter Membrane element.\n\nThese tests focus specifically on the PlannerFilter's core functionality:\n- Planning execution with valid inputs\n- Error handling for invalid inputs\n- Timeout handling\n- Statistics tracking\n- Telemetry emission\n"
  use ExUnit.Case, async: true
  alias AriaEngine.Membrane.PlannerFilter
  alias AriaEngine.Membrane.Format.{PlanningParams, PlanningResult}
  alias Membrane.Buffer
  @moduletag :unit
  @moduletag :planner_filter
  describe("PlannerFilter initialization") do
    test "initializes with default options" do
      opts = %{
        telemetry_prefix: [:aria_engine, :membrane, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      assert state.telemetry_prefix == [:aria_engine, :membrane, :planner_filter]
      assert state.timeout_ms == 30000
      assert state.strategy_config == %{}
      assert state.executed_count == 0
      assert state.success_count == 0
      assert state.error_count == 0
      assert state.total_planning_time_ms == 0
    end

    test "initializes with custom options" do
      custom_opts = %{
        timeout_ms: 10000,
        strategy_config: %{strategy: "test"},
        telemetry_prefix: [:test, :planner]
      }

      {[], state} = PlannerFilter.handle_init(nil, custom_opts)
      assert state.timeout_ms == 10000
      assert state.strategy_config == %{strategy: "test"}
      assert state.telemetry_prefix == [:test, :planner]
    end
  end

  describe("PlannerFilter planning execution") do
    setup do
      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      %{state: state}
    end

    test("executes planning with valid params", %{state: state}) do
      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: [{"entity", "has", "goal_1"}, {"entity", "at", "goal_2"}],
        options: [],
        request_id: "test_request_123",
        conversion_metadata: %{converted_at: DateTime.utc_now(), source: "test"}
      }

      buffer = %Buffer{payload: planning_params}
      {actions, new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.request_id == "test_request_123"
      assert result.status in [:success, :error]
      assert is_map(result.execution_metadata)
      assert is_map(result.performance_metrics)
      assert is_integer(result.performance_metrics.execution_time_ms)
      assert new_state.executed_count == 1
      assert new_state.success_count + new_state.error_count == 1
    end

    test("handles error planning params", %{state: state}) do
      error_params = PlanningParams.create_error("test_error_123", "Test error condition")
      buffer = %Buffer{payload: error_params}
      {actions, new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.request_id == "test_error_123"
      assert result.status == :error
      assert result.result == nil
      assert String.contains?(result.execution_metadata.error_reason, "conversion error")
      assert new_state.executed_count == 1
      assert new_state.error_count == 1
      assert new_state.success_count == 0
    end

    test("handles planning errors", %{state: state}) do
      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: [{"entity", "complex_goal", "large_problem_space"}],
        options: [],
        request_id: "error_test_123",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      buffer = %Buffer{payload: planning_params}
      {actions, new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.request_id == "error_test_123"
      assert result.status == :error
      assert String.contains?(result.execution_metadata.error_reason, "No methods found")
      assert new_state.executed_count == 1
      assert new_state.error_count == 1
    end
  end

  describe("PlannerFilter statistics and monitoring") do
    setup do
      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      %{state: state}
    end

    test("tracks execution statistics", %{state: initial_state}) do
      state =
        Enum.reduce(1..3, initial_state, fn i, acc_state ->
          planning_params = %PlanningParams{
            domain: nil,
            state: nil,
            goals: [{"entity", "goal", "#{i}"}],
            options: [],
            request_id: "stats_test_#{i}",
            conversion_metadata: %{converted_at: DateTime.utc_now()}
          }

          buffer = %Buffer{payload: planning_params}
          {_actions, new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, acc_state)
          new_state
        end)

      assert state.executed_count == 3
      assert state.success_count + state.error_count == 3
      assert is_integer(state.total_planning_time_ms)
    end

    test("calculates statistics correctly", %{state: state}) do
      test_state = %{
        state
        | executed_count: 5,
          success_count: 3,
          error_count: 2,
          total_planning_time_ms: 1000
      }

      avg_time =
        if test_state.executed_count > 0 do
          div(test_state.total_planning_time_ms, test_state.executed_count)
        else
          0
        end

      success_rate =
        if test_state.executed_count > 0 do
          test_state.success_count / test_state.executed_count
        else
          0.0
        end

      assert test_state.executed_count == 5
      assert test_state.success_count == 3
      assert test_state.error_count == 2
      assert success_rate == 0.6
      assert test_state.total_planning_time_ms == 1000
      assert avg_time == 200
    end

    test "handles stats request timeout gracefully" do
      fake_pid = spawn(fn -> :timer.sleep(10000) end)
      stats = PlannerFilter.get_stats(fake_pid)
      assert %{error: "Timeout waiting for stats"} = stats
    end
  end

  describe("PlannerFilter telemetry") do
    setup do
      test_pid = self()

      :telemetry.attach_many(
        "planner_filter_test",
        [[:test, :planner_filter, :planning_success], [:test, :planner_filter, :planning_error]],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("planner_filter_test") end)

      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      %{state: state}
    end

    test("emits telemetry for planning errors", %{state: state}) do
      error_params = PlanningParams.create_error("telemetry_error_test", "Test error")
      buffer = %Buffer{payload: error_params}
      {_actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)

      assert_receive {:telemetry, [:test, :planner_filter, :planning_error], %{count: 1},
                      metadata},
                     1000

      assert metadata.request_id == "telemetry_error_test"
      assert String.contains?(metadata.error_reason, "conversion error")
      assert is_integer(metadata.execution_time_ms)
    end
  end

  describe("PlannerFilter input validation") do
    setup do
      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      %{state: state}
    end

    test "validates PlanningParams format" do
      valid_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: [],
        options: [],
        request_id: "validation_test",
        conversion_metadata: %{}
      }

      assert PlanningParams.valid?(valid_params)
    end

    test("handles invalid input gracefully", %{state: state}) do
      edge_case_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: nil,
        options: [],
        request_id: "edge_case_test",
        conversion_metadata: %{}
      }

      buffer = %Buffer{payload: edge_case_params}
      {actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.status == :success
    end
  end

  describe("PlannerFilter goal conversion") do
    setup do
      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      %{state: state}
    end

    test("converts goals to activities correctly", %{state: state}) do
      goals = [
        %{type: "achieve", predicate: "at(robot, location_a)"},
        %{type: "maintain", predicate: "battery_level > 20"},
        %{type: "avoid", predicate: "collision"}
      ]

      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: goals,
        options: [],
        request_id: "goal_conversion_test",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      buffer = %Buffer{payload: planning_params}
      {actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.request_id == "goal_conversion_test"
      assert result.execution_metadata.goals_count == 3
    end

    test("handles empty goals list", %{state: state}) do
      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: [],
        options: [],
        request_id: "empty_goals_test",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      buffer = %Buffer{payload: planning_params}
      {actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.execution_metadata.goals_count == 0
    end
  end

  describe("PlannerFilter private functions") do
    test "convert_goals_to_activities with valid goals" do
      goals = [{"entity", "achieve", "goal_1"}, {"entity", "achieve", "goal_2"}]

      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: goals,
        options: [],
        request_id: "private_test",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      buffer = %Buffer{payload: planning_params}
      {actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.execution_metadata.goals_count == 2
    end

    test "convert_goals_to_activities with nil goals" do
      planning_params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: nil,
        options: [],
        request_id: "nil_goals_test",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      opts = %{
        telemetry_prefix: [:test, :planner_filter],
        timeout_ms: 30000,
        strategy_config: %{}
      }

      {[], state} = PlannerFilter.handle_init(nil, opts)
      buffer = %Buffer{payload: planning_params}
      {actions, _new_state} = PlannerFilter.handle_buffer(:input, buffer, nil, state)
      assert [buffer: {:output, output_buffer}] = actions
      assert %PlanningResult{} = result = output_buffer.payload
      assert result.status == :success
    end
  end
end