#!/usr/bin/env elixir

# Debug script for action execution step by step

defmodule ActionExecutionDebugger do
  alias AriaEngine.StateV2
  alias AriaEngine.Domain.{Core, DurativeAction, Actions}

  def test_existential_seating_action() do
    IO.puts("=== Testing Existential Seating Action Step by Step ===")
    
    # Create domain with seating-finding action (exact copy from test)
    domain = Core.new("seating_domain")
    
    find_seating_action = %DurativeAction{
      name: :find_seating,
      duration: {:fixed, 5000},
      conditions: %{
        at_start: [
          {:exists, &String.contains?(&1, "chair"), "status", "available"}
        ],
        over_all: [],
        at_end: []
      },
      effects: %{
        at_start: [],
        at_end: [
          {"npc", "activity", "sitting"}
        ]
      },
      action_fn: fn state, _args ->
        available_chairs = StateV2.get_subjects_with_fact(state, "status", "available")
        |> Enum.filter(&String.contains?(&1, "chair"))
        
        case available_chairs do
          [chair | _] ->
            state
            |> StateV2.set_fact("npc", "activity", "sitting")
            |> StateV2.set_fact(chair, "status", "occupied")
            |> StateV2.set_fact("npc", "location", chair)
          [] ->
            false
        end
      end
    }
    
    domain = Core.add_durative_action(domain, :find_seating, find_seating_action)
    
    # Create test state (exact copy from test)
    state = StateV2.new()
    |> StateV2.set_fact("chair1", "type", "furniture")
    |> StateV2.set_fact("chair2", "type", "furniture") 
    |> StateV2.set_fact("table1", "type", "furniture")
    |> StateV2.set_fact("chair1", "status", "available")
    |> StateV2.set_fact("chair2", "status", "occupied")
    |> StateV2.set_fact("table1", "status", "available")
    |> StateV2.set_fact("npc", "activity", "standing")
    
    IO.puts("Initial state: #{inspect(state)}")
    
    # Test the condition manually first
    condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
    condition_result = StateV2.evaluate_condition(state, condition)
    IO.puts("Condition evaluation: #{condition_result}")
    
    # Get available chairs to verify
    available_subjects = StateV2.get_subjects_with_fact(state, "status", "available")
    IO.puts("All available subjects: #{inspect(available_subjects)}")
    
    available_chairs = available_subjects |> Enum.filter(&String.contains?(&1, "chair"))
    IO.puts("Available chairs: #{inspect(available_chairs)}")
    
    # Check if the action exists in the domain
    durative_action = Core.get_durative_action(domain, :find_seating)
    IO.puts("Durative action found: #{inspect(durative_action != nil)}")
    
    # Execute the action
    result = Actions.execute_action(domain, state, :find_seating, [])
    IO.puts("Action execution result: #{inspect(result)}")
    
    # If it succeeded, check the new state
    case result do
      {:ok, new_state} ->
        IO.puts("New state: #{inspect(new_state)}")
        activity = StateV2.get_fact(new_state, "npc", "activity")
        IO.puts("NPC activity: #{inspect(activity)}")
        chair1_status = StateV2.get_fact(new_state, "chair1", "status")
        IO.puts("Chair1 status: #{inspect(chair1_status)}")
      false ->
        IO.puts("Action failed")
      other ->
        IO.puts("Unexpected result: #{inspect(other)}")
    end
  end
  
  def test_universal_security_action() do
    IO.puts("\n=== Testing Universal Security Action Step by Step ===")
    
    domain = Core.new("security_domain")
    
    security_patrol_action = %DurativeAction{
      name: :security_patrol,
      duration: {:fixed, 30000},
      conditions: %{
        at_start: [
          {:forall, &String.contains?(&1, "door"), "status", "locked"}
        ],
        over_all: [],
        at_end: []
      },
      effects: %{
        at_start: [],
        at_end: [
          {"security_npc", "activity", "patrol_complete"},
          {"building", "security_status", "secure"}
        ]
      },
      action_fn: fn state, _args ->
        state
        |> StateV2.set_fact("security_npc", "activity", "patrol_complete")
        |> StateV2.set_fact("building", "security_status", "secure")
      end
    }
    
    domain = Core.add_durative_action(domain, :security_patrol, security_patrol_action)
    
    # Test state with all doors locked
    state = StateV2.new()
    |> StateV2.set_fact("door1", "type", "entrance")
    |> StateV2.set_fact("door2", "type", "entrance")
    |> StateV2.set_fact("door3", "type", "entrance")
    |> StateV2.set_fact("window1", "type", "opening")
    |> StateV2.set_fact("door1", "status", "locked")
    |> StateV2.set_fact("door2", "status", "locked")
    |> StateV2.set_fact("door3", "status", "locked")
    |> StateV2.set_fact("window1", "status", "closed")
    
    IO.puts("Initial state: #{inspect(state)}")
    
    # Test condition manually
    condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
    condition_result = StateV2.evaluate_condition(state, condition)
    IO.puts("Condition evaluation: #{condition_result}")
    
    # Check door subjects
    all_subjects = StateV2.get_subjects(state)
    doors = all_subjects |> Enum.filter(&String.contains?(&1, "door"))
    IO.puts("All doors: #{inspect(doors)}")
    
    door_statuses = doors |> Enum.map(fn door -> {door, StateV2.get_fact(state, door, "status")} end)
    IO.puts("Door statuses: #{inspect(door_statuses)}")
    
    # Execute action
    result = Actions.execute_action(domain, state, :security_patrol, [])
    IO.puts("Action execution result: #{inspect(result)}")
    
    case result do
      {:ok, new_state} ->
        IO.puts("New state: #{inspect(new_state)}")
        security_status = StateV2.get_fact(new_state, "building", "security_status")
        IO.puts("Building security status: #{inspect(security_status)}")
        activity = StateV2.get_fact(new_state, "security_npc", "activity")
        IO.puts("Security NPC activity: #{inspect(activity)}")
      false ->
        IO.puts("Action failed")
      other ->
        IO.puts("Unexpected result: #{inspect(other)}")
    end
  end
  
  def run_all_tests() do
    test_existential_seating_action()
    test_universal_security_action()
  end
end

ActionExecutionDebugger.run_all_tests()
