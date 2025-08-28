# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTemporalBlocks.IsoDatetimeSampleTest do
  use ExUnit.Case

  alias AriaBlocks.Domain
  alias AriaHybridPlanner

  @tag :integration
  test "demonstrates ISO datetime scheduling with absolute start time" do
    # Create domain and initial state
    domain = Domain.create()

    state = AriaState.new()
    |> AriaState.set_fact("block_a", "pos", "table")
    |> AriaState.set_fact("block_a", "clear", true)
    |> AriaState.set_fact("block_b", "pos", "table")
    |> AriaState.set_fact("block_b", "clear", true)
    |> AriaState.set_fact("hand", "holding", false)

    # Define planning goals - simple stacking task
    todos = [
      {"pos", "block_a", "block_b"},  # Put block_a on block_b
      {:wait, [3.0]}                  # Wait for 3 seconds
    ]

    # Create a scheduled start time 1 hour in the future
    future_time = DateTime.utc_now()
    |> DateTime.add(3600, :second)  # Add 1 hour
    |> DateTime.to_iso8601()

    IO.puts("\n=== ISO DATETIME SCHEDULING SAMPLE ===")
    IO.puts("Current time: #{DateTime.to_iso8601(DateTime.utc_now())}")
    IO.puts("Scheduled execution start: #{future_time}")

    # Enable debug logging and plan with ISO datetime scheduling
    import ExUnit.CaptureLog

    log = capture_log([level: :debug], fn ->
      case AriaHybridPlanner.plan(domain, state, todos,
        verbose: 1,
        scheduled_start_time: future_time,
        use_iso_format: true
      ) do
        {:ok, _plan_result} ->
          IO.puts("✓ Planning completed successfully with ISO datetime scheduling")
        {:error, reason} ->
          IO.puts("✗ Planning failed: #{reason}")
      end
    end)

    IO.puts("\n=== PLANNED TIMELINE OUTPUT ===")
    # Extract just the timeline portion of the log
    timeline_lines = log
    |> String.split("\n")
    |> Enum.filter(fn line ->
      String.contains?(line, "PLANNED TIMELINE") or
      String.contains?(line, "Scheduled start time:") or
      String.contains?(line, "Total planned duration:") or
      String.contains?(line, "Actions sequence:") or
      String.contains?(line, "2025-") or  # ISO datetime lines
      String.contains?(line, "pickup") or
      String.contains?(line, "stack") or
      String.contains?(line, "wait")
    end)

    Enum.each(timeline_lines, &IO.puts/1)

    # Verify that the log contains ISO datetime formatting
    assert log =~ "=== PLANNED TIMELINE ==="
    assert log =~ "Scheduled start time: #{future_time}"
    assert log =~ "Total planned duration:"
    assert log =~ "Actions sequence:"

    # Should contain ISO datetime stamps (YYYY-MM-DDTHH:MM:SS.SSSSSSZ format)
    # Strip ANSI color codes before checking
    clean_log = String.replace(log, ~r/\e\[[0-9;]*m/, "")
    assert clean_log =~ ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z/

    # Should show the scheduled actions with absolute timestamps
    assert log =~ "pickup"
    assert log =~ "stack"
    assert log =~ "wait(3.0)"

    IO.puts("\n✓ Sample completed successfully")
    IO.puts("✓ Verified ISO datetime formatting in timeline")
    IO.puts("✓ Verified scheduled start time integration")
  end

  @tag :integration
  test "compares relative vs absolute time formatting" do
    domain = Domain.create()

    state = AriaState.new()
    |> AriaState.set_fact("block_a", "pos", "table")
    |> AriaState.set_fact("block_a", "clear", true)
    |> AriaState.set_fact("hand", "holding", false)

    todos = [
      {:pickup, ["block_a"]},
      {:wait, [5.0]},
      {:putdown, ["block_a"]}
    ]

    import ExUnit.CaptureLog

    IO.puts("\n=== RELATIVE TIME FORMATTING ===")
    relative_log = capture_log([level: :debug], fn ->
      AriaHybridPlanner.plan(domain, state, todos, verbose: 1)
    end)

    # Extract and display relative timeline
    relative_lines = relative_log
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, ["t=", "Actions sequence:", "Total planned"]))

    Enum.each(relative_lines, &IO.puts/1)

    IO.puts("\n=== ABSOLUTE ISO TIME FORMATTING ===")
    start_time = "2025-08-04T18:30:00Z"

    absolute_log = capture_log([level: :debug], fn ->
      AriaHybridPlanner.plan(domain, state, todos,
        verbose: 1,
        scheduled_start_time: start_time,
        use_iso_format: true
      )
    end)

    # Extract and display absolute timeline
    absolute_lines = absolute_log
    |> String.split("\n")
    |> Enum.filter(&(String.contains?(&1, "2025-") or String.contains?(&1, ["Actions sequence:", "Total planned", "Scheduled start"])))

    Enum.each(absolute_lines, &IO.puts/1)

    # Verify both formats work
    assert relative_log =~ "t=0.0s"
    assert absolute_log =~ "2025-08-04T18:30:00Z"
    assert absolute_log =~ "Scheduled start time: #{start_time}"

    IO.puts("\n✓ Successfully demonstrated both relative and absolute time formatting")
  end
end
