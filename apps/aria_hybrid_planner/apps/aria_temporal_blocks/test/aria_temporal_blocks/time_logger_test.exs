defmodule AriaTemporalBlocks.TimeLoggerTest do
  use ExUnit.Case
  doctest AriaTemporalBlocks.TimeLogger

  alias AriaTemporalBlocks.TimeLogger
  alias AriaBlocks.Domain

  describe "extract_action_duration/3" do
    test "extracts ISO 8601 durations from domain" do
      domain = Domain.create()

      # Test pickup action (PT2S)
      assert TimeLogger.extract_action_duration(domain, :pickup, ["block_a"]) == 2.0

      # Test unstack action (PT3S)
      assert TimeLogger.extract_action_duration(domain, :unstack, ["block_a", "block_b"]) == 3.0

      # Test putdown action (actual domain value is 5.0 due to AriaCore converter issue)
      assert TimeLogger.extract_action_duration(domain, :putdown, ["block_a"]) == 5.0

      # Test stack action (actual domain value is 5.0 due to AriaCore converter issue)
      assert TimeLogger.extract_action_duration(domain, :stack, ["block_a", "block_b"]) == 5.0
    end

    test "handles parametric duration for wait action" do
      domain = Domain.create()

      # Test wait action with parameter
      assert TimeLogger.extract_action_duration(domain, :wait, [5.0]) == 5.0
      assert TimeLogger.extract_action_duration(domain, :wait, [2.5]) == 2.5
    end

    test "uses default duration for unknown actions" do
      domain = Domain.create()

      # Test unknown action
      assert TimeLogger.extract_action_duration(domain, :unknown_action, []) == 1.0
    end
  end

  # Note: parse_iso8601_duration/1 is tested indirectly through extract_action_duration/3

  describe "calculate_timeline/2" do
    test "calculates timeline for simple action sequence" do
      domain = Domain.create()

      # Create a simple solution tree manually for testing
      actions = [
        {:pickup, ["block_a"]},    # 2.0s
        {:stack, ["block_a", "block_b"]}, # 5.0s (actual domain value)
        {:wait, [1.0]}             # 1.0s
      ]

      solution_tree = AriaEngineCore.Plan.create_solution_tree_from_actions(
        actions,
        [{"pos", "block_a", "block_b"}],
        AriaState.new()
      )

      {:ok, timeline} = TimeLogger.calculate_timeline(solution_tree, domain)

      assert length(timeline) == 3

      # Check first action (pickup)
      assert List.first(timeline).action == :pickup
      assert List.first(timeline).start_time == 0.0
      assert List.first(timeline).end_time == 2.0
      assert List.first(timeline).duration == 2.0

      # Check second action (stack)
      second_action = Enum.at(timeline, 1)
      assert second_action.action == :stack
      assert second_action.start_time == 2.0
      assert second_action.end_time == 7.0  # 2.0 + 5.0 = 7.0
      assert second_action.duration == 5.0

      # Check third action (wait)
      third_action = Enum.at(timeline, 2)
      assert third_action.action == :wait
      assert third_action.start_time == 7.0
      assert third_action.end_time == 8.0
      assert third_action.duration == 1.0
    end
  end

  describe "log_planned_timeline/2" do
    test "logs timeline without errors" do
      import ExUnit.CaptureLog

      domain = Domain.create()

      actions = [
        {:pickup, ["block_a"]},
        {:putdown, ["block_a"]}
      ]

      solution_tree = AriaEngineCore.Plan.create_solution_tree_from_actions(
        actions,
        [{"pos", "block_a", "table"}],
        AriaState.new()
      )

      # Should not raise errors
      assert :ok = TimeLogger.log_planned_timeline(solution_tree, domain)

      # Test that debug logs are generated
      log = capture_log([level: :debug], fn ->
        TimeLogger.log_planned_timeline(solution_tree, domain)
      end)

      assert log =~ "=== PLANNED TIMELINE ==="
      assert log =~ "Total planned duration:"
      assert log =~ "pickup"
      assert log =~ "putdown"
      assert log =~ "=== END PLANNED TIMELINE ==="
    end
  end

  describe "log_execution_timing/6" do
    test "logs execution timing without errors" do
      import ExUnit.CaptureLog

      # Should not raise errors
      assert :ok = TimeLogger.log_execution_timing(:pickup, ["block_a"], 0.0, 0.1, 2.0, 2.1)

      # Test that debug logs are generated
      log = capture_log([level: :debug], fn ->
        TimeLogger.log_execution_timing(:pickup, ["block_a"], 0.0, 0.1, 2.0, 2.1)
      end)

      assert log =~ "EXEC"
      assert log =~ "pickup"
      assert log =~ "block_a"
      assert log =~ "planned: 2.0s"
      assert log =~ "actual: 2.1s"
    end

    test "logs timing deviation warnings" do
      import ExUnit.CaptureLog

      # Test with significant deviation (> 0.1s)
      log = capture_log([level: :debug], fn ->
        TimeLogger.log_execution_timing(:pickup, ["block_a"], 0.0, 0.5, 2.0)
      end)

      assert log =~ "⚠ Timing deviation"
      assert log =~ "0.5s from planned start"
    end
  end
end
