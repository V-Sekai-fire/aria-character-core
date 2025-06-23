defmodule AriaEngine.Timeline.IntervalISO8601Test do
  use ExUnit.Case, async: true
  alias AriaEngine.Timeline.Interval

  describe("new_fixed_schedule/2") do
    test "creates interval from ISO 8601 datetime strings" do
      interval = Interval.new_fixed_schedule("2025-06-22T10:00:00Z", "2025-06-22T11:00:00Z")
      assert interval.start_time == ~U[2025-06-22 10:00:00Z]
      assert interval.end_time == ~U[2025-06-22 11:00:00Z]
      assert interval.metadata.iso8601_start == "2025-06-22T10:00:00Z"
      assert interval.metadata.iso8601_end == "2025-06-22T11:00:00Z"
      assert interval.metadata.fixed_schedule == true
    end

    test "creates interval with options" do
      agent = %{type: :agent, id: "agent1", name: "Alice"}
      entity = %{type: :entity, id: "room1", name: "Conference Room"}

      interval =
        Interval.new_fixed_schedule("2025-06-22T10:00:00Z", "2025-06-22T11:00:00Z",
          agent: agent,
          entity: entity,
          metadata: %{task: "meeting"}
        )

      assert interval.agent == agent
      assert interval.entity == entity
      assert interval.metadata.task == "meeting"
      assert interval.metadata.fixed_schedule == true
    end
  end

  describe("new_floating_duration/1") do
    test "creates floating duration interval from ISO 8601 duration string" do
      interval = Interval.new_floating_duration("PT2H")
      assert interval.start_time == nil
      assert interval.end_time == nil
      assert interval.metadata.iso8601_duration == "PT2H"
      assert interval.metadata.floating_duration == true
    end

    test "creates floating duration with options" do
      interval = Interval.new_floating_duration("PT30M", metadata: %{task: "cooking"})
      assert interval.metadata.task == "cooking"
      assert interval.metadata.floating_duration == true
    end
  end

  describe("new_open_ended_start/1") do
    test "creates open-ended interval with start time only" do
      interval = Interval.new_open_ended_start("2025-06-22T10:00:00Z")
      assert interval.start_time == ~U[2025-06-22 10:00:00Z]
      assert interval.end_time == nil
      assert interval.metadata.iso8601_start == "2025-06-22T10:00:00Z"
      assert interval.metadata.open_ended_start == true
    end
  end

  describe("new_open_ended_end/1") do
    test "creates open-ended interval with end time only" do
      interval = Interval.new_open_ended_end("2025-06-22T17:00:00Z")
      assert interval.start_time == nil
      assert interval.end_time == ~U[2025-06-22 17:00:00Z]
      assert interval.metadata.iso8601_end == "2025-06-22T17:00:00Z"
      assert interval.metadata.open_ended_end == true
    end
  end

  describe("unified new/2 constructor") do
    test "auto-detects fixed schedule pattern" do
      interval =
        Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"})

      assert interval.metadata.fixed_schedule == true
      assert interval.metadata.iso8601_start == "2025-06-22T10:00:00Z"
      assert interval.metadata.iso8601_end == "2025-06-22T11:00:00Z"
    end

    test "auto-detects floating duration pattern" do
      interval = Interval.new_fixed_schedule(%{duration: "PT2H"})
      assert interval.metadata.floating_duration == true
      assert interval.metadata.iso8601_duration == "PT2H"
    end

    test "auto-detects open-ended start pattern" do
      interval = Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z"})
      assert interval.metadata.open_ended_start == true
      assert interval.metadata.iso8601_start == "2025-06-22T10:00:00Z"
    end

    test "auto-detects open-ended end pattern" do
      interval = Interval.new_fixed_schedule(%{end: "2025-06-22T17:00:00Z"})
      assert interval.metadata.open_ended_end == true
      assert interval.metadata.iso8601_end == "2025-06-22T17:00:00Z"
    end

    test "raises error for invalid temporal specification" do
      assert_raise ArgumentError, ~r/Invalid temporal specification/, fn ->
        Interval.new_fixed_schedule(%{invalid: "value"})
      end
    end

    test "works with options" do
      agent = %{type: :agent, id: "agent1", name: "Alice"}
      interval = Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z"}, agent: agent)
      assert interval.agent == agent
      assert interval.metadata.open_ended_start == true
    end
  end

  describe("backward compatibility with DateTime constructors") do
    test "new/2 with DateTime structs shows deprecation warning" do
      start_dt = "2025-06-22T10:00:00Z"
      end_dt = "2025-06-22T11:00:00Z"
      import ExUnit.CaptureIO

      output =
        capture_io(:stderr, fn ->
          interval =
            Interval.new_fixed_schedule(
              DateTime.to_iso8601(start_dt),
              DateTime.to_iso8601(end_dt)
            )

          assert interval.start_time == start_dt
          assert interval.end_time == end_dt
        end)

      assert output =~ "deprecated"
      assert output =~ "new_fixed_schedule/2"
    end

    test "new/3 with DateTime structs shows deprecation warning" do
      start_dt = "2025-06-22T10:00:00Z"
      end_dt = "2025-06-22T11:00:00Z"
      import ExUnit.CaptureIO

      output =
        capture_io(:stderr, fn ->
          interval =
            Interval.new_fixed_schedule(
              DateTime.to_iso8601(start_dt),
              DateTime.to_iso8601(end_dt),
              metadata: %{type: :action}
            )

          assert interval.metadata.type == :action
        end)

      assert output =~ "deprecated"
      assert output =~ "new_fixed_schedule/3"
    end
  end

  describe("integration with unified durative action specification") do
    test "supports all temporal patterns from unified specification" do
      fixed =
        Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"})

      assert fixed.metadata.fixed_schedule == true
      floating = Interval.new_fixed_schedule(%{duration: "PT2H"})
      assert floating.metadata.floating_duration == true
      open_start = Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z"})
      assert open_start.metadata.open_ended_start == true
      open_end = Interval.new_fixed_schedule(%{end: "2025-06-22T17:00:00Z"})
      assert open_end.metadata.open_ended_end == true
    end

    test "preserves ISO 8601 strings in metadata for round-trip compatibility" do
      interval =
        Interval.new_fixed_schedule(%{start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"})

      assert interval.metadata.iso8601_start == "2025-06-22T10:00:00Z"
      assert interval.metadata.iso8601_end == "2025-06-22T11:00:00Z"
      assert interval.start_time == ~U[2025-06-22 10:00:00Z]
      assert interval.end_time == ~U[2025-06-22 11:00:00Z]
    end
  end
end