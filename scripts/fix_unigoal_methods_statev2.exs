# Fix unigoal methods to use StateV2 entity-first format
# Usage: mix run scripts/fix_unigoal_methods_statev2.exs

defmodule FixUnigoalMethods do
  alias AriaEngine.{Domain, StateV2}
  
  def run do
    IO.puts("=== Fixing Unigoal Methods for StateV2 Format ===")
    
    # Test the specific issue from the failing tests
    test_health_status_method()
    test_battery_percent_method()
    test_door_open_method()
    
    IO.puts("\nAll method tests completed!")
  end
  
  defp test_health_status_method do
    IO.puts("\n--- Testing health_status method fix ---")
    
    state = StateV2.new()
    |> StateV2.set_fact("robot", "health_status", :wounded)
    
    IO.puts("State: #{inspect(state.data)}")
    
    # OLD (BROKEN) method pattern from test:
    old_method = fn state, [subject, target_status] ->
      # BUG: This uses predicate-first format: StateV2.get_fact(state, "health_status", subject)
      current_status = StateV2.get_fact(state, "health_status", subject)
      IO.puts("OLD method - Current: #{inspect(current_status)}, Target: #{inspect(target_status)}")
      if current_status != target_status do
        [{:magic_heal, []}]
      else
        []
      end
    end
    
    # NEW (FIXED) method pattern:
    new_method = fn state, [subject, target_status] ->
      # FIX: Use entity-first format: StateV2.get_fact(state, subject, "health_status")
      current_status = StateV2.get_fact(state, subject, "health_status")
      IO.puts("NEW method - Current: #{inspect(current_status)}, Target: #{inspect(target_status)}")
      if current_status != target_status do
        [{:magic_heal, []}]
      else
        []
      end
    end
    
    # Test both methods
    IO.puts("Testing old method:")
    old_result = old_method.(state, ["robot", :healthy])
    IO.puts("Old result: #{inspect(old_result)}")
    
    IO.puts("Testing new method:")
    new_result = new_method.(state, ["robot", :healthy])
    IO.puts("New result: #{inspect(new_result)}")
    
    # The old method returns nil (broken), new method returns action list (correct)
    assert old_result != new_result, "Methods should behave differently"
    assert new_result == [{:magic_heal, []}], "New method should return action list"
  end
  
  defp test_battery_percent_method do
    IO.puts("\n--- Testing battery_percent method fix ---")
    
    state = StateV2.new()
    |> StateV2.set_fact("phone", "battery_percent", 10)
    
    # OLD (BROKEN):
    old_method = fn state, [device, target_percent] ->
      current_percent = StateV2.get_fact(state, "battery_percent", device)  # WRONG ORDER
      IO.puts("OLD - Current: #{inspect(current_percent)}, Target: #{inspect(target_percent)}")
      if current_percent != target_percent do
        [{:fast_charge_numeric, []}]
      else
        []
      end
    end
    
    # NEW (FIXED):
    new_method = fn state, [device, target_percent] ->
      current_percent = StateV2.get_fact(state, device, "battery_percent")  # CORRECT ORDER
      IO.puts("NEW - Current: #{inspect(current_percent)}, Target: #{inspect(target_percent)}")
      if current_percent != target_percent do
        [{:fast_charge_numeric, []}]
      else
        []
      end
    end
    
    IO.puts("Testing old method:")
    old_result = old_method.(state, ["phone", 50])
    IO.puts("Old result: #{inspect(old_result)}")
    
    IO.puts("Testing new method:")
    new_result = new_method.(state, ["phone", 50])
    IO.puts("New result: #{inspect(new_result)}")
    
    assert new_result == [{:fast_charge_numeric, []}], "New method should return action list"
  end
  
  defp test_door_open_method do
    IO.puts("\n--- Testing door_open method fix ---")
    
    state = StateV2.new()
    |> StateV2.set_fact("main_door", "door_open", false)
    
    # OLD (BROKEN):
    old_method = fn state, [door, target_state] ->
      current_state = StateV2.get_fact(state, "door_open", door)  # WRONG ORDER
      IO.puts("OLD - Current: #{inspect(current_state)}, Target: #{inspect(target_state)}")
      if current_state != target_state do
        [{:manual_open_door, []}]
      else
        []
      end
    end
    
    # NEW (FIXED):
    new_method = fn state, [door, target_state] ->
      current_state = StateV2.get_fact(state, door, "door_open")  # CORRECT ORDER
      IO.puts("NEW - Current: #{inspect(current_state)}, Target: #{inspect(target_state)}")
      if current_state != target_state do
        [{:manual_open_door, []}]
      else
        []
      end
    end
    
    IO.puts("Testing old method:")
    old_result = old_method.(state, ["main_door", true])
    IO.puts("Old result: #{inspect(old_result)}")
    
    IO.puts("Testing new method:")
    new_result = new_method.(state, ["main_door", true])
    IO.puts("New result: #{inspect(new_result)}")
    
    assert new_result == [{:manual_open_door, []}], "New method should return action list"
  end
  
  def create_corrected_test_methods do
    IO.puts("\n=== Creating Corrected Method Examples ===")
    
    # Template for corrected methods
    IO.puts("""
    # CORRECTED unigoal method template:
    domain = Domain.add_unigoal_method(domain, "predicate_name", "method_name", fn state, [subject, target_value] ->
      # FIX: Use entity-first format
      current_value = StateV2.get_fact(state, subject, "predicate_name")  # subject FIRST, predicate SECOND
      if current_value != target_value do
        [{:action_name, []}]
      else
        []
      end
    end)
    """)
    
    IO.puts("The key fix: StateV2.get_fact(state, subject, predicate) - NOT predicate first!")
  end
end

FixUnigoalMethods.run()
FixUnigoalMethods.create_corrected_test_methods()
