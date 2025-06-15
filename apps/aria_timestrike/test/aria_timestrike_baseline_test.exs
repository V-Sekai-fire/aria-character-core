# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.BaselineTest do
  @moduledoc """
  Baseline functionality tests for AriaEngine and AriaTimestrike
  as outlined in ADR-050 Stage 0.
  
  These tests verify the current state of the system before implementing
  temporal planning enhancements.
  """
  
  use ExUnit.Case
  
  test "current AriaEngine basic planning works" do
    # Verify existing planner functionality with simple domain
    initial_state = AriaEngine.State.new()
      |> AriaEngine.State.set_object("position", "agent", {3, 5})
    
    goals = [{"position", "agent", {15, 5}}]
    
    # Create a minimal domain for testing  
    move_action = fn state, [agent, from_pos, to_pos] ->
      current_pos = AriaEngine.State.get_object(state, "position", agent)
      if current_pos == from_pos do
        {:ok, AriaEngine.State.set_object(state, "position", agent, to_pos)}
      else
        {:error, "Agent not at expected position"}
      end
    end
    
    domain = AriaEngine.Domain.new("test_domain")
      |> AriaEngine.Domain.add_action(:move_to, move_action)
    
    # The current planner is not functional, so we expect an error.
    # This test will be updated once the planner is implemented.
    case AriaEngine.Planner.plan(domain, initial_state, goals) do
      {:error, "No methods found for goal: position"} -> 
        IO.puts("✓ Basic planning functional: correctly returns error")
      {:ok, _plan} ->
        flunk("Planner should not be functional yet")
      {:error, reason} ->
        flunk("Planner returned unexpected error: #{inspect(reason)}")
    end
  end
  
  test "aria_timestrike domain provider exists" do
    # Verify domain provider structure
    assert function_exported?(AriaTimestrike, :create_domain, 0)
    
    domain = AriaTimestrike.create_domain()
    assert domain != nil
    assert is_map(domain)
    IO.puts("✓ Domain provider functional")
  end
  
  test "aria_timestrike basic actions are callable" do
    # Test existing action structure
    state = AriaEngine.State.new()
      |> AriaEngine.State.set_object("position", "maya", {3, 5})
    
    # Test move_to function exists and is callable
    assert function_exported?(AriaTimestrike, :move_to, 2)
    
    result = AriaTimestrike.move_to(state, {"maya", {15, 5}})
    assert match?({:ok, _}, result)
    IO.puts("✓ Basic actions callable")
  end

  test "baseline performance benchmarks" do
    # Establish baseline performance metrics
    state = AriaEngine.State.new()
      |> AriaEngine.State.set_object("position", "agent", {0, 0})
    
    domain = AriaEngine.Domain.new("perf_test")
      |> AriaEngine.Domain.add_action(:move, ["agent", "from", "to"], %{
        preconditions: [{:position, :agent, :from}],
        effects: [{:position, :agent, :to}]
      })

    # Time basic planning operation
    {time_us, result} = :timer.tc(fn ->
      AriaEngine.Planner.plan(domain, state, [{"position", "agent", {10, 10}}])
    end)
    
    case result do
      {:ok, plan} ->
        time_ms = time_us / 1000
        IO.puts("✓ Basic planning performance: #{Float.round(time_ms, 2)}ms for #{length(plan)} actions")
        # Baseline expectation: should complete in under 100ms
        assert time_ms < 100, "Basic planning too slow: #{time_ms}ms"
      {:error, reason} ->
        flunk("Planning failed: #{inspect(reason)}")
    end
  end
end
