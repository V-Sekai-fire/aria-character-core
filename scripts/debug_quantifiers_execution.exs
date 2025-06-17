#!/usr/bin/env elixir

# Debug script for quantifier execution issues

defmodule QuantifiersDebugger do
  alias AriaEngine.StateV2
  alias AriaEngine.Domain.{Core, DurativeAction, Actions}

  def test_existential_quantifier() do
    IO.puts("=== Testing Existential Quantifier ===")
    
    # Create test state
    state = StateV2.new()
    |> StateV2.set_fact("chair1", "type", "furniture")
    |> StateV2.set_fact("chair1", "status", "available")
    |> StateV2.set_fact("table1", "type", "furniture")
    |> StateV2.set_fact("table1", "status", "available")
    
    IO.puts("State: #{inspect(state)}")
    
    # Test the condition manually
    condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
    result = StateV2.evaluate_condition(state, condition)
    IO.puts("Existential condition result: #{result}")
    
    # Test get_subjects_with_fact
    subjects = StateV2.get_subjects_with_fact(state, "status", "available")
    IO.puts("Subjects with status=available: #{inspect(subjects)}")
    
    chairs = subjects |> Enum.filter(&String.contains?(&1, "chair"))
    IO.puts("Available chairs: #{inspect(chairs)}")
  end
  
  def test_universal_quantifier() do
    IO.puts("\n=== Testing Universal Quantifier ===")
    
    # Create test state with all doors locked
    state = StateV2.new()
    |> StateV2.set_fact("door1", "type", "entrance")
    |> StateV2.set_fact("door2", "type", "entrance")  
    |> StateV2.set_fact("door1", "status", "locked")
    |> StateV2.set_fact("door2", "status", "locked")
    |> StateV2.set_fact("window1", "type", "opening")
    |> StateV2.set_fact("window1", "status", "closed")
    
    IO.puts("State: #{inspect(state)}")
    
    # Test the condition manually
    condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
    result = StateV2.evaluate_condition(state, condition)
    IO.puts("Universal condition result: #{result}")
    
    # Test forall directly
    filter_fn = &String.contains?(&1, "door")
    forall_result = StateV2.forall?(state, filter_fn, "status", "locked")
    IO.puts("Direct forall? result: #{forall_result}")
  end
  
  def test_effects_application() do
    IO.puts("\n=== Testing Effects Application ===")
    
    state = StateV2.new()
    
    # Test setting facts with correct parameter order
    new_state = state
    |> StateV2.set_fact("security_npc", "activity", "patrol_complete")
    |> StateV2.set_fact("building", "security_status", "secure")
    
    IO.puts("New state: #{inspect(new_state)}")
    
    security_status = StateV2.get_fact(new_state, "building", "security_status")
    IO.puts("Security status: #{inspect(security_status)}")
    
    activity = StateV2.get_fact(new_state, "security_npc", "activity")
    IO.puts("Security NPC activity: #{inspect(activity)}")
  end
  
  def run_all_tests() do
    test_existential_quantifier()
    test_universal_quantifier()
    test_effects_application()
  end
end

QuantifiersDebugger.run_all_tests()
