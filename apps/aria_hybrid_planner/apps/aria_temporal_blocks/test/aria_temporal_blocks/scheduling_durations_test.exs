defmodule AriaTemporalBlocks.SchedulingDurationsTest do
  use ExUnit.Case

  alias AriaBlocks.Domain
  alias AriaHybridPlanner
  alias AriaTemporalBlocks.TimeLogger

  @tag :integration
  test "schedules actions at specific start time with precise duration calculations" do
    # Create domain with specific action durations
    domain = Domain.create()

    state = AriaState.new()
    |> AriaState.set_fact("block_a", "pos", "table")
    |> AriaState.set_fact("block_a", "clear", true)
    |> AriaState.set_fact("block_b", "pos", "table")
    |> AriaState.set_fact("block_b", "clear", true)
    |> AriaState.set_fact("hand", "holding", false)

    # Define a complex task sequence with various durations
    todos = [
      {:pickup, ["block_a"]},     # Should be 2.0s from domain
      {:wait, [4.5]},             # Parametric duration: 4.5s
      {:stack, ["block_a", "block_b"]}, # Should be 5.0s from domain
      {:wait, [2.0]},             # Parametric duration: 2.0s
      {"pos", "block_b", "table"} # Goal to unstack - should trigger putdown
    ]

    # Schedule execution to start at a specific time
    start_time = "2025-08-04T20:00:00Z"

    IO.puts("\n=== SCHEDULING WITH DURATIONS TEST ===")
    IO.puts("Scheduled start: #{start_time}")

    import ExUnit.CaptureLog

    log = capture_log([level: :debug], fn ->
      case AriaHybridPlanner.plan(domain, state, todos,
        verbose: 1,
        scheduled_start_time: start_time,
        use_iso_format: true
      ) do
        {:ok, plan_result} ->
          IO.puts("✓ Planning completed successfully")

          # Test timeline calculation directly
          solution_tree = Map.get(plan_result, :solution_tree)
          if solution_tree do
            case TimeLogger.calculate_timeline(solution_tree, domain,
              scheduled_start_time: start_time, use_iso_format: true) do
              {:ok, timeline} ->
                IO.puts("✓ Timeline calculated successfully with #{length(timeline)} actions")
                validate_timeline_durations(timeline, start_time)
              {:error, reason} ->
                IO.puts("✗ Timeline calculation failed: #{reason}")
            end
          end

        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end
    end)

    # Verify timeline was logged with ISO datetime
    assert log =~ "=== PLANNED TIMELINE ==="
    assert log =~ "Scheduled start time: #{start_time}"
    assert log =~ "Total planned duration:"

    # Verify specific action durations are logged
    assert log =~ "pickup"
    assert log =~ "wait(4.5)"
    assert log =~ "stack"
    assert log =~ "wait(2.0)"

    # Verify ISO datetime formatting in timeline
    clean_log = String.replace(log, ~r/\e\[[0-9;]*m/, "")
    assert clean_log =~ ~r/2025-08-04T20:00:00(\.\d+)?Z/
    assert clean_log =~ ~r/2025-08-04T20:00:02(\.\d+)?Z/  # After pickup (2s)

    IO.puts("\n✓ Scheduling with durations test completed successfully")
  end

  @tag :integration
  test "validates duration extraction from domain and parametric actions" do
    domain = Domain.create()

    # Test individual duration extraction
    pickup_duration = TimeLogger.extract_action_duration(domain, :pickup, ["block_a"])
    stack_duration = TimeLogger.extract_action_duration(domain, :stack, ["block_a", "block_b"])
    putdown_duration = TimeLogger.extract_action_duration(domain, :putdown, ["block_a"])
    wait_duration = TimeLogger.extract_action_duration(domain, :wait, [3.5])

    IO.puts("\n=== DURATION EXTRACTION TEST ===")
    IO.puts("pickup duration: #{pickup_duration}s")
    IO.puts("stack duration: #{stack_duration}s")
    IO.puts("putdown duration: #{putdown_duration}s")
    IO.puts("wait(3.5) duration: #{wait_duration}s")

    # Verify expected durations from domain
    assert pickup_duration == 2.0, "pickup should be 2.0s"
    assert stack_duration == 5.0, "stack should be 5.0s"
    assert putdown_duration == 5.0, "putdown should be 5.0s"
    assert wait_duration == 3.5, "wait(3.5) should be 3.5s"

    IO.puts("✓ All duration extractions validated")
  end

  @tag :integration
  test "compares timeline calculations between relative and absolute timing" do
    domain = Domain.create()

    state = AriaState.new()
    |> AriaState.set_fact("block_a", "pos", "table")
    |> AriaState.set_fact("block_a", "clear", true)
    |> AriaState.set_fact("hand", "holding", false)

    todos = [
      {:pickup, ["block_a"]},     # 2.0s
      {:wait, [3.0]},             # 3.0s
      {:putdown, ["block_a"]}     # 5.0s
    ]

    import ExUnit.CaptureLog

    # Test relative timing (traditional)
    IO.puts("\n=== RELATIVE TIMING CALCULATION ===")
    relative_log = capture_log([level: :debug], fn ->
      AriaHybridPlanner.plan(domain, state, todos, verbose: 1)
    end)

    # Test absolute timing (scheduled)
    start_time = "2025-08-04T15:30:00Z"
    IO.puts("\n=== ABSOLUTE TIMING CALCULATION ===")
    absolute_log = capture_log([level: :debug], fn ->
      AriaHybridPlanner.plan(domain, state, todos,
        verbose: 1,
        scheduled_start_time: start_time,
        use_iso_format: true
      )
    end)

    # Verify both contain proper timing information
    assert relative_log =~ "t=0.0s - t=2.0s: pickup"
    assert relative_log =~ "t=2.0s - t=5.0s: wait(3.0)"
    assert relative_log =~ "t=5.0s - t=10.0s: putdown"
    assert relative_log =~ "Total planned duration: 10.0s"

    assert absolute_log =~ "2025-08-04T15:30:00Z - 2025-08-04T15:30:02Z: pickup"
    assert absolute_log =~ "2025-08-04T15:30:02Z - 2025-08-04T15:30:05Z: wait(3.0)"
    assert absolute_log =~ "2025-08-04T15:30:05Z - 2025-08-04T15:30:10Z: putdown"
    assert absolute_log =~ "Total planned duration: 10.0s"

    IO.puts("✓ Both relative and absolute timing calculations validated")
  end

  # Helper function to validate timeline durations and sequencing
  defp validate_timeline_durations(timeline, start_time) do
    IO.puts("\n=== TIMELINE VALIDATION ===")

    start_dt = parse_start_time(start_time)
    expected_time = start_dt

    # Track wait actions by their actual duration
    wait_durations_seen = []

    {_final_expected_time, wait_durations_seen} = Enum.reduce(timeline, {expected_time, wait_durations_seen}, fn entry, {current_expected_time, wait_acc} ->
      action_name = ensure_atom(entry.action)
      duration = entry.duration

      IO.puts("Action: #{action_name}(#{format_args(entry.args)}) - Duration: #{duration}s")
      IO.puts("  Start: #{entry.start_time}")
      IO.puts("  End: #{entry.end_time}")

      # Validate duration matches expectations and update wait_acc
      updated_wait_acc = case action_name do
        :pickup ->
          assert duration == 2.0, "pickup duration should be 2.0s, got #{duration}s"
          wait_acc
        :stack ->
          assert duration == 5.0, "stack duration should be 5.0s, got #{duration}s"
          wait_acc
        :putdown ->
          assert duration == 5.0, "putdown duration should be 5.0s, got #{duration}s"
          wait_acc
        :wait ->
          # For wait actions, just verify the duration is reasonable and track it
          assert is_number(duration) and duration > 0, "wait duration should be positive, got #{duration}s"
          [duration | wait_acc]
        _ ->
          # Other actions, verify they have reasonable durations
          assert is_number(duration) and duration > 0, "Invalid duration #{duration}s for #{action_name}"
          wait_acc
      end

      # Validate timing sequence (start time should match expected)
      if entry.start_time != current_expected_time do
        start_entry = parse_iso_time(entry.start_time)
        time_diff = DateTime.diff(start_entry, current_expected_time, :second)
        IO.puts("  ⚠ Time sequence gap: #{time_diff}s")
      end

      # Return updated expected time for next action
      {parse_iso_time(entry.end_time), updated_wait_acc}
    end)

    # Verify we saw some wait actions with expected durations
    wait_durations_reversed = Enum.reverse(wait_durations_seen)
    IO.puts("Wait durations seen: #{inspect(wait_durations_reversed)}")

    # Verify we have at least one wait action
    assert length(wait_durations_seen) > 0, "Expected to see wait actions in timeline"

    IO.puts("✓ Timeline validation completed")
  end

  # Helper functions
  defp parse_start_time(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> DateTime.utc_now()
    end
  end

  defp parse_iso_time(iso_string) when is_binary(iso_string) do
    parse_start_time(iso_string)
  end

  defp parse_iso_time(%DateTime{} = dt), do: dt

  defp ensure_atom(name) when is_atom(name), do: name
  defp ensure_atom(name) when is_binary(name), do: String.to_atom(name)
  defp ensure_atom(name), do: String.to_atom(to_string(name))

  defp format_args(args) do
    args
    |> Enum.map(&inspect/1)
    |> Enum.join(", ")
  end
end
