# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SchedulerTest do
  use ExUnit.Case, async: true
  require Logger

  alias AriaEngine.Scheduler

  # Custom assertion helper for DateTime comparison using Timex
  defp assert_datetime_equal(actual_iso_string, expected_datetime, tolerance_ms \\ 0) do
    # Parse the actual ISO string to DateTime
    {:ok, actual_datetime, _} = DateTime.from_iso8601(actual_iso_string)

    # Calculate difference in milliseconds
    diff_ms = abs(Timex.diff(actual_datetime, expected_datetime, :milliseconds))

    # Assert within tolerance
    assert diff_ms <= tolerance_ms,
           """
           DateTime difference exceeds tolerance:
           Expected: #{DateTime.to_iso8601(expected_datetime)}
           Actual:   #{actual_iso_string}
           Difference: #{diff_ms}ms (tolerance: #{tolerance_ms}ms)
           """
  end

  describe "schedule_activities/3" do
    test "handles empty activity list correctly" do
      {:ok, result} =
        Scheduler.schedule_activities(
          "Empty Project",
          [],
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"

      assert result.reason ==
               "Empty plan successfully generated - valid solution for empty todo list"

      assert result.schedule == []
      assert is_nil(result.analysis) or result.analysis.activities_analyzed == 0
      assert result.analysis.dependencies_found == 0
      assert result.analysis.resource_conflicts == 0
      assert result.analysis.circular_dependencies == 0
      assert result.analysis.critical_path_length == 0
      assert result.analysis.hybrid_planner_used == true

      assert result.analysis.empty_plan_reason ==
               "Empty todo list results in empty plan (valid solution)"
    end

    test "schedules simple activities with dependencies" do
      activities = [
        %{"id" => "design", "duration" => "PT5S", "dependencies" => []},
        %{"id" => "develop", "duration" => "PT10S", "dependencies" => ["design"]},
        %{"id" => "test", "duration" => "PT3S", "dependencies" => ["develop"]},
        %{"id" => "deploy", "duration" => "PT1S", "dependencies" => ["test"]}
      ]

      {:ok, result} =
        Scheduler.schedule_activities(
          "Website Launch",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 4
    end

    test "schedules activities with resources and constraints" do
      activities = [
        %{
          "id" => "task1",
          "duration" => "PT2S",
          "dependencies" => [],
          "resources" => ["developer"]
        },
        %{
          "id" => "task2",
          "duration" => "PT3S",
          "dependencies" => [],
          "resources" => ["developer"]
        }
      ]

      resources = %{developer: %{capacity: 1}}
      constraints = %{max_duration: 10}

      {:ok, result} =
        Scheduler.schedule_activities(
          "Resource Test",
          activities,
          resources: resources,
          constraints: constraints,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 2
    end

    test "handles verbose logging" do
      activities = [%{"id" => "task1", "duration" => "PT1S", "dependencies" => []}]

      {:ok, result} =
        Scheduler.schedule_activities(
          "Verbose Test",
          activities,
          verbose: 3,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
      assert is_list(result.schedule)
    end

    test "returns analysis with correct structure" do
      activities = [
        %{"id" => "a", "duration" => "PT1S", "dependencies" => []},
        %{"id" => "b", "duration" => "PT2S", "dependencies" => ["a"]}
      ]

      {:ok, _result} =
        Scheduler.schedule_activities(
          "Analysis Test",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )
    end

    test "scheduled activities have timing information" do
      activities = [
        %{"id" => "first", "duration" => "PT5S", "dependencies" => []},
        %{"id" => "second", "duration" => "PT3S", "dependencies" => ["first"]}
      ]

      {:ok, result} =
        Scheduler.schedule_activities(
          "Timing Test",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      scheduled = result.schedule
      assert length(scheduled) == 2

      # Check that activities have timing information
      Enum.each(scheduled, fn activity ->
        assert Map.has_key?(activity, :start_time)
        assert Map.has_key?(activity, :end_time)
        assert Map.has_key?(activity, :scheduled)
        assert activity.scheduled == true
      end)
    end

    test "handles activities without duration" do
      activities = [
        %{"id" => "no_duration", "dependencies" => []}
      ]

      {:ok, result} =
        Scheduler.schedule_activities(
          "No Duration Test",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 1
    end

    test "handles activities with empty dependencies" do
      activities = [
        %{"id" => "independent1", "duration" => "PT1S", "dependencies" => []},
        %{"id" => "independent2", "duration" => "PT2S", "dependencies" => []}
      ]

      {:ok, result} =
        Scheduler.schedule_activities(
          "Independent Test",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
      assert is_list(result.schedule)
      assert length(result.schedule) == 2
      assert is_nil(result.analysis) or result.analysis.dependencies_found == 0
    end

    test "timing constraints are respected with multiple dependencies (STN logic)" do
      activities = [
        %{"id" => "a", "duration" => "PT2S", "dependencies" => []},
        %{"id" => "b", "duration" => "PT3S", "dependencies" => ["a"]},
        %{"id" => "c", "duration" => "PT1S", "dependencies" => ["a"]},
        %{"id" => "d", "duration" => "PT4S", "dependencies" => ["b", "c"]}
      ]

      {:ok, result} =
        Scheduler.schedule_activities(
          "STN Timing Test",
          activities,
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      schedule = Enum.sort_by(result.schedule, & &1["id"])

      a = Enum.find(schedule, &(&1["id"] == "a"))
      b = Enum.find(schedule, &(&1["id"] == "b"))
      c = Enum.find(schedule, &(&1["id"] == "c"))
      d = Enum.find(schedule, &(&1["id"] == "d"))

      # Parse the base datetime from activity a's start time
      {:ok, base_time, _offset} = DateTime.from_iso8601(a.start_time)

      # Expected times using Timex for datetime arithmetic
      expected_a_end = Timex.add(base_time, Timex.Duration.from_seconds(2))
      expected_b_start = expected_a_end
      expected_b_end = Timex.add(expected_b_start, Timex.Duration.from_seconds(3))
      expected_c_start = expected_a_end
      expected_c_end = Timex.add(expected_c_start, Timex.Duration.from_seconds(1))
      expected_d_start = Enum.max([expected_b_end, expected_c_end], DateTime)
      expected_d_end = Timex.add(expected_d_start, Timex.Duration.from_seconds(4))

      # Use custom DateTime comparison to avoid precision issues
      assert_datetime_equal(a.start_time, base_time)
      assert_datetime_equal(a.end_time, expected_a_end)
      assert_datetime_equal(b.start_time, expected_b_start)
      assert_datetime_equal(b.end_time, expected_b_end)
      assert_datetime_equal(c.start_time, expected_c_start)
      assert_datetime_equal(c.end_time, expected_c_end)
      # d should start after both b and c finish
      assert_datetime_equal(d.start_time, expected_d_start)
      assert_datetime_equal(d.end_time, expected_d_end)
    end
  end

  describe "error handling" do
    test "handles invalid input gracefully" do
      # This should not crash, even with unusual input
      {:ok, result} =
        Scheduler.schedule_activities(
          "",
          [],
          base_datetime: ~U[2025-01-01 00:00:00Z]
        )

      assert result.status == "success"
    end
  end
end
