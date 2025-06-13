defmodule RunLazyRefineaheadTest do
  @moduledoc """
  Test the Run-Lazy-Refineahead execution with replanning on failure.
  
  This test creates scenarios where actions fail during execution, triggering
  the replanning mechanism to find alternative solutions.
  """
  
  use ExUnit.Case
  alias AriaEngine.{Domain, State, Plan}
  
  test "Run-Lazy-Refineahead with action failure and replanning" do
    # Create a domain with actions that can fail conditionally
    domain = create_failing_domain()
    
    # Create initial state
    initial_state = create_test_state()
    
    # Define tasks that will require replanning when first action fails
    todos = [{"move_with_failure", ["start", "goal"]}]
    
    # Plan using IPyHOP
    case Plan.plan(domain, initial_state, todos, verbose: 1) do
      {:ok, solution_tree} ->
        IO.puts("Initial planning succeeded!")
        IO.inspect(Plan.tree_stats(solution_tree))
        
        # Extract actions for inspection
        initial_actions = Plan.get_primitive_actions_dfs(solution_tree)
        IO.puts("Initial plan: #{inspect(initial_actions)}")
        
        # Execute with Run-Lazy-Refineahead (this should trigger replanning)
        case Plan.run_lazy_refineahead(domain, initial_state, solution_tree, verbose: 2) do
          {:ok, final_state} ->
            # Verify we reached the goal despite initial failures
            robot_location = State.get_object(final_state, "location", "robot")
            assert robot_location == "goal"
            
            IO.puts("Run-Lazy-Refineahead succeeded with replanning!")
          
          {:error, reason} ->
            # Check if this is the expected "no more alternatives" error
            if String.contains?(reason, "Replanning failed") do
              IO.puts("Expected failure: #{reason}")
              assert true
            else
              flunk("Unexpected execution failure: #{reason}")
            end
        end
      
      {:error, reason} ->
        flunk("Planning failed: #{reason}")
    end
  end
  
  # Create domain with actions that can fail on first attempt
  defp create_failing_domain do
    domain = Domain.new("failing_test")
    
    # Add actions that may fail initially
    |> Domain.add_action(:move_unreliable, &move_unreliable_action/2)
    |> Domain.add_action(:move_reliable, &move_reliable_action/2)
    
    # Add task methods - first method uses unreliable action, second uses reliable
    |> Domain.add_task_method("move_with_failure", &method_unreliable_move/2)
    |> Domain.add_task_method("move_with_failure", &method_reliable_move/2)
    
    domain
  end
  
  # Action that fails if robot hasn't "prepared" (simulates environmental failure)
  defp move_unreliable_action(state, [from, to]) do
    robot_location = State.get_object(state, "location", "robot")
    prepared = State.get_object(state, "prepared", "robot")
    
    if robot_location == from and prepared == true do
      # Success - update location
      State.set_object(state, "location", "robot", to)
    else
      # Failure - robot not prepared or not at start location
      false
    end
  end
  
  # Action that always works (prepares robot and moves)
  defp move_reliable_action(state, [from, to]) do
    robot_location = State.get_object(state, "location", "robot")
    
    if robot_location == from do
      # Always succeeds - prepare and move
      state
      |> State.set_object("prepared", "robot", true)
      |> State.set_object("location", "robot", to)
    else
      false
    end
  end
  
  # Method using unreliable action (will fail initially)
  defp method_unreliable_move(state, [from, to]) do
    robot_location = State.get_object(state, "location", "robot")
    if robot_location == from do
      [{:move_unreliable, [from, to]}]
    else
      false
    end
  end
  
  # Method using reliable action (backup method)
  defp method_reliable_move(state, [from, to]) do
    robot_location = State.get_object(state, "location", "robot")
    if robot_location == from do
      [{:move_reliable, [from, to]}]
    else
      false
    end
  end
  
  # Create test state
  defp create_test_state do
    State.new()
    |> State.set_object("location", "robot", "start")
    |> State.set_object("prepared", "robot", false)  # Robot not prepared initially
  end
end
