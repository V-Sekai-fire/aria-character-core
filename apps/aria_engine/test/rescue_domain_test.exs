defmodule RescueDomainTest do
  @moduledoc """
  Test the rescue domain with IPyHOP planning to validate Run-Lazy-Refineahead implementation.
  
  This test recreates the rescue domain from the IPyHOP examples to verify our
  goal-task-network planner works correctly.
  """
  
  use ExUnit.Case
  alias AriaEngine.{Domain, State, Plan}
  
  # Test case based on thirdparty/IPyHOP/examples/rescue/rescue_example.py
  test "rescue domain planning with IPyHOP" do
    # Create the rescue domain
    domain = create_rescue_domain()
    
    # Create initial state (based on rescue_problem_1.py)
    initial_state = create_initial_state()
    
    # Define the rescue task
    todos = [{"move_task", ["r1", {5, 5}]}]
    
    # Plan using IPyHOP
    case Plan.plan(domain, initial_state, todos, verbose: 1) do
      {:ok, solution_tree} ->
        IO.puts("Planning succeeded!")
        IO.inspect(Plan.tree_stats(solution_tree))
        
        # Verify the plan contains actions
        actions = Plan.get_primitive_actions_dfs(solution_tree)
        assert length(actions) > 0
        
        # Test Run-Lazy-Refineahead execution
        case Plan.run_lazy_refineahead(domain, initial_state, solution_tree, verbose: 1) do
          {:ok, final_state} ->
            # Verify the robot moved to the target location
            robot_location = State.get_object(final_state, "loc", "r1")
            assert robot_location == {5, 5}
          
          {:error, reason} ->
            flunk("Execution failed: #{reason}")
        end
      
      {:error, reason} ->
        flunk("Planning failed: #{reason}")
    end
  end
  
  # Create rescue domain with actions and methods
  defp create_rescue_domain do
    domain = Domain.new("rescue")
    
    # Add actions
    |> Domain.add_action(:a_move_euclidean, &a_move_euclidean/2)
    |> Domain.add_action(:a_move_manhattan, &a_move_manhattan/2)
    |> Domain.add_action(:a_move_curved, &a_move_curved/2)
    |> Domain.add_action(:a_move_fly, &a_move_fly/2)
    |> Domain.add_action(:a_move_alt_fly, &a_move_alt_fly/2)
    |> Domain.add_action(:a_free_robot, &a_free_robot/2)
    
    # Add task methods
    |> Domain.add_task_method("move_task", &tm1_move/2)
    |> Domain.add_task_method("move_task", &tm2_move/2)
    |> Domain.add_task_method("move_task", &tm3_move/2)
    |> Domain.add_task_method("move_task", &tm4_move/2)
    |> Domain.add_task_method("move_task", &tm5_move/2)
  end
  
  # Create initial state (based on rescue_problem_1.py)
  defp create_initial_state do
    State.new()
    |> State.set_object("loc", "r1", {1, 1})
    |> State.set_object("loc", "w1", {5, 5})
    |> State.set_object("loc", "p1", {2, 2})
    |> State.set_object("loc", "a1", {2, 1})
    |> State.set_object("robot_type", "r1", "wheeled")
    |> State.set_object("robot_type", "w1", "wheeled")
    |> State.set_object("robot_type", "a1", "uav")
    |> State.set_object("has_medicine", "a1", 0)
    |> State.set_object("has_medicine", "w1", 0)
    |> State.set_object("has_medicine", "r1", 0)
    |> State.set_object("status", "r1", "free")
    |> State.set_object("status", "w1", "free")
    |> State.set_object("status", "a1", "unk")
    |> State.set_object("status", "p1", "unk")
    |> State.set_object("altitude", "a1", "high")
  end
  
  # Action implementations (based on rescue_actions.py)
  
  defp a_move_euclidean(state, [robot, from_loc, to_loc, _dist]) do
    robot_type = State.get_object(state, "robot_type", robot)
    current_loc = State.get_object(state, "loc", robot)
    
    cond do
      current_loc == to_loc ->
        # Already at destination
        state
      
      robot_type == "wheeled" and current_loc == from_loc ->
        # Move the robot
        State.set_object(state, "loc", robot, to_loc)
      
      true ->
        false
    end
  end
  
  defp a_move_manhattan(state, [robot, from_loc, to_loc, _dist]) do
    robot_type = State.get_object(state, "robot_type", robot)
    current_loc = State.get_object(state, "loc", robot)
    
    cond do
      current_loc == to_loc ->
        state
      
      robot_type == "wheeled" and current_loc == from_loc ->
        State.set_object(state, "loc", robot, to_loc)
      
      true ->
        false
    end
  end
  
  defp a_move_curved(state, [robot, from_loc, to_loc, _dist]) do
    robot_type = State.get_object(state, "robot_type", robot)
    current_loc = State.get_object(state, "loc", robot)
    
    cond do
      current_loc == to_loc ->
        state
      
      robot_type == "wheeled" and current_loc == from_loc ->
        State.set_object(state, "loc", robot, to_loc)
      
      true ->
        false
    end
  end
  
  defp a_move_fly(state, [robot, from_loc, to_loc]) do
    robot_type = State.get_object(state, "robot_type", robot)
    current_loc = State.get_object(state, "loc", robot)
    
    cond do
      current_loc == to_loc ->
        state
      
      robot_type == "uav" and current_loc == from_loc ->
        State.set_object(state, "loc", robot, to_loc)
      
      true ->
        false
    end
  end
  
  defp a_move_alt_fly(state, [robot, from_loc, to_loc]) do
    robot_type = State.get_object(state, "robot_type", robot)
    current_loc = State.get_object(state, "loc", robot)
    
    cond do
      current_loc == to_loc ->
        state
      
      robot_type == "uav" and current_loc == from_loc ->
        State.set_object(state, "loc", robot, to_loc)
      
      true ->
        false
    end
  end
  
  defp a_free_robot(state, [robot]) do
    State.set_object(state, "status", robot, "free")
  end
  
  # Task method implementations (based on rescue_methods.py)
  
  defp tm1_move(state, [robot, target_loc]) do
    current_loc = State.get_object(state, "loc", robot)
    robot_type = State.get_object(state, "robot_type", robot)
    
    cond do
      current_loc == target_loc ->
        # Already at destination
        []
      
      robot_type == "wheeled" ->
        # Take the straight path
        [{"a_move_euclidean", [robot, current_loc, target_loc, nil]}]
      
      true ->
        false
    end
  end
  
  defp tm2_move(state, [robot, target_loc]) do
    current_loc = State.get_object(state, "loc", robot)
    robot_type = State.get_object(state, "robot_type", robot)
    
    cond do
      current_loc == target_loc ->
        []
      
      robot_type == "wheeled" ->
        # Take the manhattan path
        [{"a_move_manhattan", [robot, current_loc, target_loc, nil]}]
      
      true ->
        false
    end
  end
  
  defp tm3_move(state, [robot, target_loc]) do
    current_loc = State.get_object(state, "loc", robot)
    robot_type = State.get_object(state, "robot_type", robot)
    
    cond do
      current_loc == target_loc ->
        []
      
      robot_type == "wheeled" ->
        # Take the curved path
        [{"a_move_curved", [robot, current_loc, target_loc, nil]}]
      
      true ->
        false
    end
  end
  
  defp tm4_move(state, [robot, target_loc]) do
    current_loc = State.get_object(state, "loc", robot)
    robot_type = State.get_object(state, "robot_type", robot)
    
    cond do
      current_loc == target_loc ->
        []
      
      robot_type == "uav" ->
        # Fly to the location
        [{"a_move_fly", [robot, current_loc, target_loc]}]
      
      true ->
        false
    end
  end
  
  defp tm5_move(state, [robot, target_loc]) do
    current_loc = State.get_object(state, "loc", robot)
    robot_type = State.get_object(state, "robot_type", robot)
    
    cond do
      current_loc == target_loc ->
        []
      
      robot_type == "uav" ->
        # Alternative fly to the location
        [{"a_move_alt_fly", [robot, current_loc, target_loc]}]
      
      true ->
        false
    end
  end
end
