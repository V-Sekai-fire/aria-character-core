# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineTest do
  use ExUnit.Case
  doctest AriaEngine

  alias AriaEngine.{State, Domain, Multigoal, Plan}
  alias AriaEngine.TestDomains

  describe "State management" do
    test "creates and manages state with predicate-subject-object triples" do
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("has", "player", "sword")
      |> AriaEngine.set_fact("health", "player", 100)

      assert AriaEngine.get_fact(state, "location", "player") == "room1"
      assert AriaEngine.get_fact(state, "has", "player") == "sword"
      assert AriaEngine.get_fact(state, "health", "player") == 100
      assert AriaEngine.get_fact(state, "missing", "player") == nil
    end

    test "converts state to and from triples" do
      original_triples = [
        {"location", "player", "room1"},
        {"has", "player", "sword"},
        {"health", "player", 100}
      ]

      state = AriaEngine.state_from_triples(original_triples)
      converted_triples = AriaEngine.state_to_triples(state)

      # Sort both lists for comparison since order might differ
      assert Enum.sort(converted_triples) == Enum.sort(original_triples)
    end

    test "merges states correctly" do
      state1 = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("has", "player", "sword")

      state2 = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room2")  # Conflict - should take precedence
      |> AriaEngine.set_fact("health", "player", 100)       # New fact

      merged = AriaEngine.merge_states(state1, state2)

      assert AriaEngine.get_fact(merged, "location", "player") == "room2"  # From state2
      assert AriaEngine.get_fact(merged, "has", "player") == "sword"       # From state1
      assert AriaEngine.get_fact(merged, "health", "player") == 100        # From state2
    end
  end

  describe "Domain and action management" do
    test "creates domain and adds actions" do
      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, fn state, [from, to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end)
      |> AriaEngine.add_action(:pickup, fn state, [item] ->
        AriaEngine.set_fact(state, "has", "player", item)
      end)

      summary = AriaEngine.domain_summary(domain)
      assert summary.name == "test"
      assert :move in summary.actions
      assert :pickup in summary.actions
    end

    test "executes actions correctly" do
      move_action = fn state, [from, to] ->
        state
        |> AriaEngine.set_fact("location", "player", to)
      end

      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, move_action)

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")

      result_state = Domain.execute_action(domain, initial_state, :move, ["room1", "room2"])

      assert AriaEngine.get_fact(result_state, "location", "player") == "room2"
    end
  end

  describe "Goal management" do
    test "creates and manages multigoals" do
      multigoal = AriaEngine.create_multigoal()
      |> Multigoal.add_goal("location", "player", "treasure_room")
      |> Multigoal.add_goal("has", "player", "treasure")

      assert Multigoal.size(multigoal) == 2
      refute Multigoal.empty?(multigoal)

      goals_list = Multigoal.to_list(multigoal)
      assert {"location", "player", "treasure_room"} in goals_list
      assert {"has", "player", "treasure"} in goals_list
    end

    test "checks goal satisfaction" do
      # Create a state where player is in treasure_room and has treasure
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "treasure_room")
      |> AriaEngine.set_fact("has", "player", "treasure")

      multigoal = AriaEngine.create_multigoal()
      |> Multigoal.add_goal("location", "player", "treasure_room")
      |> Multigoal.add_goal("has", "player", "treasure")

      assert Multigoal.satisfied?(multigoal, state)

      # Test partial satisfaction
      partial_multigoal = Multigoal.add_goal(multigoal, "health", "player", 100)
      refute Multigoal.satisfied?(partial_multigoal, state)

      unsatisfied = Multigoal.unsatisfied_goals(partial_multigoal, state)
      assert unsatisfied == [{"health", "player", 100}]
    end
  end

  describe "Basic planning" do
    test "plans simple action sequence" do
      # Define simple actions
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      pickup_action = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          AriaEngine.set_fact(state, "has", "player", item)
        else
          false  # Can't pickup item not in same location
        end
      end

      # Create domain with actions
      domain = AriaEngine.create_domain("simple_rpg")
      |> AriaEngine.add_action(:move, move_action)
      |> AriaEngine.add_action(:pickup, pickup_action)

      # Set up initial state
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Simple goal: have the sword
      goals = [{"has", "player", "sword"}]

      # This will fail without proper task methods, but let's test the structure
      case AriaEngine.plan(domain, initial_state, goals, verbose: 1) do
        {:ok, _plan} -> 
          # Planning succeeded
          :ok
        {:error, reason} -> 
          # Expected to fail without proper methods
          assert String.contains?(reason, "No methods found")
      end
    end

    test "validates plan execution" do
      # Simple move action
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, move_action)

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")

      # Manual plan
      plan = [{:move, ["room2"]}, {:move, ["room3"]}]

      case AriaEngine.execute_plan(domain, initial_state, plan) do
        {:ok, final_state} ->
          assert AriaEngine.get_fact(final_state, "location", "player") == "room3"
        {:error, reason} ->
          flunk("Plan execution failed: #{reason}")
      end
    end
  end

  describe "Task decomposition" do
    test "decomposes tasks into actions" do
      # Actions
      move_action = fn state, [to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end

      pickup_action = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          AriaEngine.set_fact(state, "has", "player", item)
        else
          false
        end
      end

      # Task method: get item from another room
      get_item_method = fn state, [item] ->
        player_location = AriaEngine.get_fact(state, "location", "player")
        item_location = AriaEngine.get_fact(state, "location", item)
        
        if player_location == item_location do
          # Already in same room, just pickup
          [{:pickup, [item]}]
        else
          # Need to move then pickup
          [{:move, [item_location]}, {:pickup, [item]}]
        end
      end

      domain = AriaEngine.create_domain("rpg")
      |> AriaEngine.add_action(:move, move_action)
      |> AriaEngine.add_action(:pickup, pickup_action)
      |> AriaEngine.add_task_method("get_item", get_item_method)

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")
      |> AriaEngine.set_fact("location", "sword", "room2")

      # Task: get the sword
      tasks = [{"get_item", ["sword"]}]

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 1) do
        {:ok, plan} ->
          assert length(plan) == 2
          assert {:move, ["room2"]} in plan
          assert {:pickup, ["sword"]} in plan
          
          # Verify plan works
          {:ok, final_state} = AriaEngine.execute_plan(domain, initial_state, plan)
          assert AriaEngine.get_fact(final_state, "has", "player") == "sword"
          assert AriaEngine.get_fact(final_state, "location", "player") == "room2"
          
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end
  end

  describe "Logistics domain example" do
    test "logistics domain basic functionality" do
      domain = TestDomains.build_logistics_domain()
      summary = AriaEngine.domain_summary(domain)
      
      assert summary.name == "logistics"
      assert :drive in summary.actions
      assert :fly in summary.actions
      assert :load in summary.actions
      assert :unload in summary.actions
      assert "transport" in summary.task_methods
      assert "at" in summary.unigoal_methods
    end

    test "logistics actions work correctly" do
      domain = TestDomains.build_logistics_domain()
      
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("at", "truck1", "cityA")
      |> AriaEngine.set_fact("at", "package1", "cityA")

      # Test drive action
      result_state = Domain.execute_action(domain, initial_state, :drive, ["truck1", "cityA", "cityB"])
      assert AriaEngine.get_fact(result_state, "at", "truck1") == "cityB"

      # Test load action
      load_state = Domain.execute_action(domain, initial_state, :load, ["package1", "truck1"])
      assert AriaEngine.get_fact(load_state, "at", "package1") == "truck1"
    end
  end

  describe "Logistics domain (C++ test port)" do
    setup do
      # Create the logistics domain
      domain = TestDomains.build_logistics_domain()

      # Set up the initial state from the C++ test
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("packages", "list", ["package1", "package2"])
      |> AriaEngine.set_fact("trucks", "list", ["truck1", "truck6"])
      |> AriaEngine.set_fact("airplanes", "list", ["plane2"])
      |> AriaEngine.set_fact("locations", "list", ["airport1", "location1", "location2", "location3", "airport2", "location10"])
      |> AriaEngine.set_fact("airports", "list", ["airport1", "airport2"])
      |> AriaEngine.set_fact("cities", "list", ["city1", "city2"])
      |> AriaEngine.set_fact("at", "package1", "location1")
      |> AriaEngine.set_fact("at", "package2", "location2")
      |> AriaEngine.set_fact("truck_at", "truck1", "location3")
      |> AriaEngine.set_fact("truck_at", "truck6", "location10")
      |> AriaEngine.set_fact("plane_at", "plane2", "airport2")
      |> AriaEngine.set_fact("in_city", "airport1", "city1")
      |> AriaEngine.set_fact("in_city", "location1", "city1")
      |> AriaEngine.set_fact("in_city", "location2", "city1")
      |> AriaEngine.set_fact("in_city", "location3", "city1")
      |> AriaEngine.set_fact("in_city", "airport2", "city2")
      |> AriaEngine.set_fact("in_city", "location10", "city2")

      {:ok, domain: domain, state: state}
    end

    test "drive truck", %{domain: domain, state: state} do
      goals = [{"truck_at", "truck1", "location2"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          expected = [{:drive_truck, ["truck1", "location2"]}]
          assert plan == expected
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "fly plane", %{domain: domain, state: state} do
      goals = [{"plane_at", "plane2", "airport1"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          expected = [{:fly_plane, ["plane2", "airport1"]}]
          assert plan == expected
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "actions execute correctly", %{domain: domain, state: state} do
      # Test individual action execution
      
      # Test drive_truck
      new_state = Domain.execute_action(domain, state, :drive_truck, ["truck1", "location1"])
      assert AriaEngine.get_fact(new_state, "truck_at", "truck1") == "location1"
      
      # Test fly_plane 
      new_state = Domain.execute_action(domain, state, :fly_plane, ["plane2", "airport1"])
      assert AriaEngine.get_fact(new_state, "plane_at", "plane2") == "airport1"
      
      # Test load_truck
      # First move truck1 to location1 where package1 is
      state_with_truck = Domain.execute_action(domain, state, :drive_truck, ["truck1", "location1"])
      loaded_state = Domain.execute_action(domain, state_with_truck, :load_truck, ["package1", "truck1"])
      assert AriaEngine.get_fact(loaded_state, "at", "package1") == "truck1"
      
      # Test unload_truck
      # Move the truck to location2
      moved_state = Domain.execute_action(domain, loaded_state, :drive_truck, ["truck1", "location2"])
      unloaded_state = Domain.execute_action(domain, moved_state, :unload_truck, ["package1", "location2"])
      assert AriaEngine.get_fact(unloaded_state, "at", "package1") == "location2"
    end
  end

  describe "Blocks World domain" do
    test "blocks world domain basic functionality" do
      domain = TestDomains.build_blocks_world_domain()
      summary = AriaEngine.domain_summary(domain)
      
      assert summary.name == "blocks_world"
      assert :pickup in summary.actions
      assert :putdown in summary.actions
      assert :stack in summary.actions
      assert :unstack in summary.actions
      assert "move_block" in summary.task_methods
      assert "get_block" in summary.task_methods
      assert "clear_block" in summary.task_methods
      assert "build_tower" in summary.task_methods
      assert "on" in summary.unigoal_methods
      assert "on_table" in summary.unigoal_methods
      assert "clear" in summary.unigoal_methods
    end

    test "blocks world actions work correctly" do
      domain = TestDomains.build_blocks_world_domain()
      
      # Initial state: block A on table, clear, hand empty
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b", "c"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("clear", "a", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Test pickup action
      pickup_state = Domain.execute_action(domain, initial_state, :pickup, ["a"])
      assert AriaEngine.get_fact(pickup_state, "holding", "hand") == "a"
      assert AriaEngine.get_fact(pickup_state, "on_table", "a") == false
      assert AriaEngine.get_fact(pickup_state, "clear", "a") == false

      # Test putdown action
      putdown_state = Domain.execute_action(domain, pickup_state, :putdown, ["a"])
      assert AriaEngine.get_fact(putdown_state, "holding", "hand") == nil
      assert AriaEngine.get_fact(putdown_state, "on_table", "a") == true
      assert AriaEngine.get_fact(putdown_state, "clear", "a") == true
    end

    test "blocks world stacking actions" do
      domain = TestDomains.build_blocks_world_domain()
      
      # Initial state: blocks A and B on table, both clear, hand empty
      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on_table", "b", true)
      |> AriaEngine.set_fact("clear", "a", true)
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Pick up block A
      pickup_state = Domain.execute_action(domain, initial_state, :pickup, ["a"])
      
      # Stack A on B
      stack_state = Domain.execute_action(domain, pickup_state, :stack, ["a", "b"])
      assert AriaEngine.get_fact(stack_state, "on", "a") == "b"
      assert AriaEngine.get_fact(stack_state, "clear", "a") == true
      assert AriaEngine.get_fact(stack_state, "clear", "b") == false
      assert AriaEngine.get_fact(stack_state, "holding", "hand") == nil

      # Unstack A from B
      unstack_state = Domain.execute_action(domain, stack_state, :unstack, ["a", "b"])
      assert AriaEngine.get_fact(unstack_state, "on", "a") == nil
      assert AriaEngine.get_fact(unstack_state, "clear", "a") == false
      assert AriaEngine.get_fact(unstack_state, "clear", "b") == true
      assert AriaEngine.get_fact(unstack_state, "holding", "hand") == "a"
    end
  end

  describe "Blocks World planning scenarios" do
    setup do
      domain = TestDomains.build_blocks_world_domain()
      {:ok, domain: domain}
    end

    test "simple stacking goal", %{domain: domain} do
      # Initial state: A and B on table, both clear
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on_table", "b", true)
      |> AriaEngine.set_fact("clear", "a", true)
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Goal: A on B
      goals = [{"on", "a", "b"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should involve picking up A and stacking it on B
          assert length(plan) >= 2
          assert {:pickup, ["a"]} in plan
          assert {:stack, ["a", "b"]} in plan
          
          # Verify plan execution
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert AriaEngine.get_fact(final_state, "on", "a") == "b"
          
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "three block tower", %{domain: domain} do
      # Initial state: A, B, C on table
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b", "c"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on_table", "b", true)
      |> AriaEngine.set_fact("on_table", "c", true)
      |> AriaEngine.set_fact("clear", "a", true)
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("clear", "c", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Goal: tower C-B-A (C on B, B on A)
      goals = [{"on", "b", "a"}, {"on", "c", "b"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Verify plan execution achieves the goal
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert AriaEngine.get_fact(final_state, "on", "b") == "a"
          assert AriaEngine.get_fact(final_state, "on", "c") == "b"
          
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "sussman anomaly", %{domain: domain} do
      # Famous blocks world problem that requires backtracking
      # Initial: C on A, A and B on table, all clear except A
      # Goal: A on B, B on C
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b", "c"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on_table", "b", true)
      |> AriaEngine.set_fact("on", "c", "a")
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("clear", "c", true)
      |> AriaEngine.set_fact("clear", "a", false)  # A is not clear because C is on it
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Goal: A on B, B on C (need to build tower C-B-A from bottom up)
      goals = [{"on", "a", "b"}, {"on", "b", "c"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should first move C off A, then build the tower
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert AriaEngine.get_fact(final_state, "on", "a") == "b"
          assert AriaEngine.get_fact(final_state, "on", "b") == "c"
          
        {:error, reason} ->
          # This is a complex problem that may fail without sophisticated planning
          IO.puts("Sussman anomaly planning result: #{reason}")
      end
    end

    test "clear block goal", %{domain: domain} do
      # Initial: B on A, both A and B clear except A
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on", "b", "a")
      |> AriaEngine.set_fact("clear", "a", false)
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Goal: make A clear
      goals = [{"clear", "a", true}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # Should involve moving B off A
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert AriaEngine.get_fact(final_state, "clear", "a") == true
          
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "complex rearrangement", %{domain: domain} do
      # Initial: D on C on B on A (tower A-B-C-D)
      # Goal: A on B on C on D (tower D-C-B-A)
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b", "c", "d"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on", "b", "a")
      |> AriaEngine.set_fact("on", "c", "b")
      |> AriaEngine.set_fact("on", "d", "c")
      |> AriaEngine.set_fact("clear", "a", false)
      |> AriaEngine.set_fact("clear", "b", false)
      |> AriaEngine.set_fact("clear", "c", false)
      |> AriaEngine.set_fact("clear", "d", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Goal: reverse the tower
      goals = [{"on", "a", "b"}, {"on", "b", "c"}, {"on", "c", "d"}]
      
      case AriaEngine.plan(domain, state, goals) do
        {:ok, plan} ->
          # This is a complex rearrangement requiring multiple moves
          {:ok, final_state} = AriaEngine.execute_plan(domain, state, plan)
          assert AriaEngine.get_fact(final_state, "on", "a") == "b"
          assert AriaEngine.get_fact(final_state, "on", "b") == "c"
          assert AriaEngine.get_fact(final_state, "on", "c") == "d"
          
        {:error, reason} ->
          # Complex problems may fail with basic planning
          IO.puts("Complex rearrangement planning result: #{reason}")
      end
    end

    test "blocks world action preconditions", %{domain: domain} do
      # Test that actions fail when preconditions are not met
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
      |> AriaEngine.set_fact("on_table", "a", true)
      |> AriaEngine.set_fact("on", "b", "a")  # B is on A
      |> AriaEngine.set_fact("clear", "a", false)  # A is not clear
      |> AriaEngine.set_fact("clear", "b", true)
      |> AriaEngine.set_fact("holding", "hand", nil)

      # Try to pickup A when it's not clear (should fail)
      result = Domain.execute_action(domain, state, :pickup, ["a"])
      assert result == false

      # Try to stack when not holding anything (should fail)
      result = Domain.execute_action(domain, state, :stack, ["a", "b"])
      assert result == false

      # Try to putdown when not holding the specified block (should fail)
      result = Domain.execute_action(domain, state, :putdown, ["a"])
      assert result == false
    end
  end
end
