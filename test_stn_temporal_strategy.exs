#!/usr/bin/env elixir

# Test script for STN Temporal Strategy
Mix.install([
  {:jason, "~> 1.4"}
])

defmodule STNTemporalStrategyTest do
  @moduledoc """
  Simple test script to verify STN Temporal Strategy functionality.
  """

  def run_test do
    IO.puts("🔧 Testing STN Temporal Strategy...")

    # Test 1: Basic temporal constraint addition
    test_add_temporal_constraints()

    # Test 2: Temporal consistency validation
    test_validate_temporal_consistency()

    # Test 3: Schedule generation
    test_get_temporal_schedule()

    IO.puts("✅ All tests completed!")
  end

  defp test_add_temporal_constraints do
    IO.puts("\n📋 Test 1: Adding temporal constraints")

    # Create some test actions
    actions = [
      {"action1", %{duration: 5}},
      {"action2", %{duration: 3}},
      {"action3", %{duration: 2}}
    ]

    # Test with empty constraints
    case HybridPlanner.Strategies.Default.STNTemporalStrategy.add_temporal_constraints(
           %{},
           actions,
           verbose: 2
         ) do
      {:ok, constraints} ->
        IO.puts("✅ Successfully added temporal constraints")
        IO.inspect(constraints, label: "Constraints")

      {:error, reason} ->
        IO.puts("❌ Failed to add temporal constraints: #{reason}")
    end
  end

  defp test_validate_temporal_consistency do
    IO.puts("\n📋 Test 2: Validating temporal consistency")

    # Create a temporal problem with some constraints
    temporal_problem = %{
      actions: [
        {"action1", %{duration: 5}},
        {"action2", %{duration: 3}}
      ],
      constraints: [
        {:before, "action1", "action2"}
      ],
      current_time: 0
    }

    constraints = %{temporal_problem: temporal_problem}

    case HybridPlanner.Strategies.Default.STNTemporalStrategy.validate_temporal_consistency(
           constraints,
           verbose: 2
         ) do
      {:ok, is_consistent} ->
        IO.puts("✅ Consistency check completed: #{is_consistent}")

      {:error, reason} ->
        IO.puts("❌ Consistency check failed: #{reason}")
    end
  end

  defp test_get_temporal_schedule do
    IO.puts("\n📋 Test 3: Generating temporal schedule")

    # Create a temporal problem
    temporal_problem = %{
      actions: [
        {"action1", %{duration: 5}},
        {"action2", %{duration: 3}},
        {"action3", %{duration: 2}}
      ],
      constraints: [
        {:before, "action1", "action2"},
        {:before, "action2", "action3"}
      ],
      current_time: 0
    }

    constraints = %{temporal_problem: temporal_problem}

    case HybridPlanner.Strategies.Default.STNTemporalStrategy.get_temporal_schedule(
           constraints,
           verbose: 2
         ) do
      {:ok, schedule_result} ->
        IO.puts("✅ Schedule generated successfully")
        IO.inspect(schedule_result, label: "Schedule")

      {:error, reason} ->
        IO.puts("❌ Schedule generation failed: #{reason}")
    end
  end
end

# Run the test
STNTemporalStrategyTest.run_test()
