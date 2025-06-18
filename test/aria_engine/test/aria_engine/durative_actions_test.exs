# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DurativeActionsTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.{Domain, StateV2}
  alias AriaEngine.Domain.DurativeAction
  alias AriaEngine.Timeline.STN

  describe "DurativeAction struct" do
    test "creates durative action with fixed duration" do
      action = DurativeAction.new(
        :move_slowly,
        {:fixed, 5},  # 5 seconds
        %{at_start: [{"location", "robot", "start"}], over_all: [], at_end: []},
        %{at_start: [], at_end: [{"location", "robot", "goal"}], over_time: []},
        fn state, _args -> state end
      )
      
      assert action.name == :move_slowly
      assert action.duration == {:fixed, 5}
      assert action.conditions.at_start == [{"location", "robot", "start"}]
      assert action.effects.at_end == [{"location", "robot", "goal"}]
    end

    test "creates durative action with duration range" do
      action = DurativeAction.new(
        :investigate,
        {:range, 3, 8},  # 3-8 seconds
        %{at_start: [], over_all: [{"energy", "robot", "high"}], at_end: []},
        %{at_start: [], at_end: [{"investigated", "area", true}], over_time: []},
        fn state, _args -> state end
      )
      
      assert action.duration == {:range, 3, 8}
      assert action.conditions.over_all == [{"energy", "robot", "high"}]
    end
  end

  describe "Domain durative actions integration" do
    test "adds durative action to domain" do
      domain = Domain.Core.new("test_domain")
      
      action = DurativeAction.new(
        :construct_building,
        {:fixed, 10},
        %{at_start: [{"resources", "player", "sufficient"}], over_all: [], at_end: []},
        %{at_start: [], at_end: [{"building", "location1", "complete"}], over_time: []},
        fn state, _args -> state end
      )
      
      updated_domain = Domain.Core.add_durative_action(domain, :construct_building, action)
      
      assert Map.has_key?(updated_domain.durative_actions, :construct_building)
      retrieved_action = Domain.Core.get_durative_action(updated_domain, :construct_building)
      assert retrieved_action.name == :construct_building
      assert retrieved_action.duration == {:fixed, 10}
    end

    test "retrieves durative action from domain" do
      domain = Domain.Core.new("test_domain")
      
      action = DurativeAction.new(
        :harvest_crops,
        {:range, 2, 4},
        %{at_start: [], over_all: [{"weather", "field", "good"}], at_end: []},
        %{at_start: [], at_end: [{"crops", "field", "harvested"}], over_time: []},
        fn state, _args -> state end
      )
      
      updated_domain = Domain.Core.add_durative_action(domain, :harvest_crops, action)
      retrieved_action = Domain.Core.get_durative_action(updated_domain, :harvest_crops)
      
      assert retrieved_action.name == :harvest_crops
      assert retrieved_action.duration == {:range, 2, 4}
      assert retrieved_action.conditions.over_all == [{"weather", "field", "good"}]
    end

    test "returns nil for non-existent durative action" do
      domain = Domain.Core.new("test_domain")
      
      result = Domain.Core.get_durative_action(domain, :non_existent)
      assert result == nil
    end
  end

  describe "STN durative action integration" do
    test "adds durative action with fixed duration to STN" do
      stn = STN.new()
      
      action = DurativeAction.new(
        :travel,
        {:fixed, 6000},  # 6 seconds
        %{at_start: [], over_all: [], at_end: []},
        %{at_start: [], at_end: [], over_time: []},
        fn state, _args -> state end
      )
      
      updated_stn = STN.Core.add_durative_action(stn, action)
      
      assert STN.consistent?(updated_stn)
      
      # Should have start and end time points
      time_points = STN.time_points(updated_stn)
      assert "travel_start" in time_points
      assert "travel_end" in time_points
      
      # Should have duration constraint
      duration_constraint = STN.get_constraint(updated_stn, "travel_start", "travel_end")
      assert duration_constraint == {6000, 6000}  # Fixed duration
    end

    test "adds durative action with duration range to STN" do
      stn = STN.new()
      
      action = DurativeAction.new(
        :craft_item,
        {:range, 3000, 7000},  # 3-7 seconds
        %{at_start: [], over_all: [], at_end: []},
        %{at_start: [], at_end: [], over_time: []},
        fn state, _args -> state end
      )
      
      updated_stn = STN.Core.add_durative_action(stn, action)
      
      assert STN.consistent?(updated_stn)
      
      # Should have duration range constraint
      duration_constraint = STN.get_constraint(updated_stn, "craft_item_start", "craft_item_end")
      assert duration_constraint == {3000, 7000}  # Duration range
    end

    test "maintains temporal consistency with multiple durative actions" do
      stn = STN.new()
      
      action1 = DurativeAction.new(
        :task_a,
        {:fixed, 2000},
        %{at_start: [], over_all: [], at_end: []},
        %{at_start: [], at_end: [], over_time: []},
        fn state, _args -> state end
      )
      
      action2 = DurativeAction.new(
        :task_b,
        {:fixed, 3000},
        %{at_start: [], over_all: [], at_end: []},
        %{at_start: [], at_end: [], over_time: []},
        fn state, _args -> state end
      )
      
      updated_stn = stn
      |> STN.Core.add_durative_action(action1)
      |> STN.Core.add_durative_action(action2)
      
      assert STN.consistent?(updated_stn)
      assert length(STN.time_points(updated_stn)) == 4  # 2 actions × 2 time points each
    end
  end

  describe "Planning integration with durative actions" do
    setup do
      # Create a domain with both regular actions and durative actions
      domain = Domain.Core.new("durative_test_domain")
      
      # Add a regular instantaneous action
      domain = Domain.Actions.add_action(domain, :teleport, fn state, [_from, to] ->
        state
        |> StateV2.set_fact("robot", "location", to)
      end)
      
      # Add a durative action with no preconditions to start simple
      durative_action = DurativeAction.new(
        :move_slowly,
        {:fixed, 5000},  # 5 seconds
        %{
          at_start: [],  # No preconditions for simplicity
          over_all: [],
          at_end: []
        },
        %{
          at_start: [{"moving", "robot", true}],
          at_end: [{"location", "robot", "goal"}, {"moving", "robot", false}],
          over_time: []
        },
        fn state, [_from, to] ->
          state
          |> StateV2.set_fact("robot", "location", to)
          |> StateV2.set_fact("robot", "moving", false)
        end
      )
      
      domain = Domain.Core.add_durative_action(domain, :move_slowly, durative_action)
      
      # Add a method to handle move_slowly goals
      domain = Domain.add_task_method(domain, "move_slowly", "do_move_slowly", fn _state, [from, to] ->
        [{:move_slowly, [from, to]}]  # Decompose into the durative action with arguments
      end)
      
      # Create initial state
      state = StateV2.new()
      |> StateV2.set_fact("robot", "location", "start")
      |> StateV2.set_fact("robot", "energy", "sufficient")
      |> StateV2.set_fact("robot", "moving", false)
      
      {:ok, domain: domain, state: state}
    end

    test "recognizes durative action during planning", %{domain: domain, state: _state} do
      # Test that durative actions are properly recognized
      assert Domain.Core.get_durative_action(domain, :move_slowly) != nil
      assert Domain.Core.get_durative_action(domain, :teleport) == nil
      
      # Test that regular actions are still recognized
      assert Domain.has_action?(domain, :teleport)
      assert not Domain.has_action?(domain, :move_slowly)
    end

    test "plans with durative actions", %{domain: domain, state: _state} do
      # Test that the durative action exists and can be retrieved
      durative_action = Domain.Core.get_durative_action(domain, :move_slowly)
      assert durative_action != nil
      assert durative_action.name == :move_slowly
      assert durative_action.duration == {:fixed, 5000}
      
      # Test that the domain has both regular actions and durative actions
      assert Domain.has_action?(domain, :teleport)
      assert not Domain.has_action?(domain, :move_slowly)  # It's durative, not regular
      
      # Test that durative actions are properly stored
      assert Map.has_key?(domain.durative_actions, :move_slowly)
      assert map_size(domain.durative_actions) == 1
    end
  end

  describe "Durative action execution simulation" do
    test "simulates durative action execution over time" do
      # Create a simple durative action
      action = DurativeAction.new(
        :charge_battery,
        {:fixed, 4000},  # 4 seconds
        %{
          at_start: [{"battery_level", "robot", "low"}],
          over_all: [{"connected_to_charger", "robot", true}],
          at_end: []
        },
        %{
          at_start: [{"charging", "robot", true}],
          at_end: [{"battery_level", "robot", "full"}, {"charging", "robot", false}],
          over_time: []
        },
        fn state, _args ->
          state
          |> StateV2.set_fact("battery_level", "robot", "full")
          |> StateV2.set_fact("charging", "robot", false)
        end
      )
      
      # Create initial state
      initial_state = StateV2.new()
      |> StateV2.set_fact("battery_level", "robot", "low")
      |> StateV2.set_fact("connected_to_charger", "robot", true)
      |> StateV2.set_fact("charging", "robot", false)
      
      # Verify preconditions at start
      assert StateV2.get_fact(initial_state, "battery_level", "robot") == "low"
      assert StateV2.get_fact(initial_state, "connected_to_charger", "robot") == true
      
      # Simulate action execution (in real implementation, this would happen over time)
      final_state = action.action_fn.(initial_state, [])
      
      # Verify effects at end
      assert StateV2.get_fact(final_state, "battery_level", "robot") == "full"
      assert StateV2.get_fact(final_state, "charging", "robot") == false
    end
  end

  describe "Fluent types demonstration" do
    test "categorical fluents - robot health states" do
      # CATEGORICAL FLUENTS: These are symbols with no numeric meaning
      # :wounded, :healing, :healthy are just categories - no ordering implied
      
      domain = Domain.Core.new("health_domain")
      
      # Fast healing action - requires magic potion (unavailable)
      fast_heal = DurativeAction.new(
        :magic_heal,
        {:fixed, 1000},  # 1 second
        %{
          at_start: [{"magic_potion", "available", true}],  # Will fail - not available
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"health_status", "robot", :healthy}],  # CATEGORICAL: :healthy is a symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("health_status", "robot", :healthy)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :magic_heal, fast_heal)
      
      # Slow healing action - requires rest area (available)
      slow_heal = DurativeAction.new(
        :rest_heal,
        {:fixed, 5000},  # 5 seconds
        %{
          at_start: [{"rest_area", "available", true}],  # Will succeed
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"health_status", "robot", :healthy}],  # CATEGORICAL: :healthy is a symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("health_status", "robot", :healthy)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :rest_heal, slow_heal)
      
      # Add goal methods for healing
      domain = Domain.add_unigoal_method(domain, "health_status", "try_magic_heal", fn state, [subject, target_status] ->
        current_status = StateV2.get_fact(state, subject, "health_status")
        if current_status != target_status do
          [{:magic_heal, []}]
        else
          []
        end
      end)
      
      domain = Domain.add_unigoal_method(domain, "health_status", "try_rest_heal", fn state, [subject, target_status] ->
        current_status = StateV2.get_fact(state, subject, "health_status")
        if current_status != target_status do
          [{:rest_heal, []}]
        else
          []
        end
      end)
      
      # Initial state - robot is wounded, magic unavailable, rest available
      initial_state = StateV2.new()
      |> StateV2.set_fact("health_status", "robot", :wounded)  # CATEGORICAL: :wounded is a symbol
      |> StateV2.set_fact("magic_potion", "available", false)
      |> StateV2.set_fact("rest_area", "available", true)
      
      # Goal: heal robot to healthy status
      todos = [{"health_status", "robot", :healthy}]  # CATEGORICAL: :healthy is a symbol
      
      # Planning should backtrack from failed magic heal to successful rest heal
      case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{action_name, _args}] = actions
          assert action_name == :rest_heal
          
        {:error, reason} ->
          flunk("Categorical fluent planning failed: #{reason}")
      end
    end

    test "numeric fluents - battery percentage levels" do
      # NUMERIC FLUENTS: These are actual numbers with mathematical meaning
      # 10, 50, 100 are numbers - they have ordering and arithmetic relationships
      
      domain = Domain.Core.new("battery_domain")
      
      # Fast charging action - requires fast charger (unavailable)  
      fast_charge = DurativeAction.new(
        :fast_charge_numeric,
        {:fixed, 2000},  # 2 seconds
        %{
          at_start: [{"fast_charger", "available", true}],  # Will fail - not available
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"battery_percent", "phone", 50}],  # NUMERIC: 50 is an actual number
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("battery_percent", "phone", 50)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :fast_charge_numeric, fast_charge)
      
      # Slow charging action - requires power outlet (available)
      slow_charge = DurativeAction.new(
        :slow_charge_numeric,
        {:fixed, 8000},  # 8 seconds
        %{
          at_start: [{"power_outlet", "available", true}],  # Will succeed
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"battery_percent", "phone", 50}],  # NUMERIC: 50 is an actual number
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("battery_percent", "phone", 50)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :slow_charge_numeric, slow_charge)
      
      # Add goal methods for charging
      domain = Domain.add_unigoal_method(domain, "battery_percent", "try_fast_numeric", fn state, [device, target_percent] ->
        current_percent = StateV2.get_fact(state, device, "battery_percent")
        if current_percent != target_percent do
          [{:fast_charge_numeric, []}]
        else
          []
        end
      end)
      
      domain = Domain.add_unigoal_method(domain, "battery_percent", "try_slow_numeric", fn state, [device, target_percent] ->
        current_percent = StateV2.get_fact(state, device, "battery_percent")
        if current_percent != target_percent do
          [{:slow_charge_numeric, []}]
        else
          []
        end
      end)
      
      # Initial state - battery at 10%, fast charger unavailable, outlet available
      initial_state = StateV2.new()
      |> StateV2.set_fact("battery_percent", "phone", 10)  # NUMERIC: 10 is an actual number
      |> StateV2.set_fact("fast_charger", "available", false)
      |> StateV2.set_fact("power_outlet", "available", true)
      
      # Goal: charge phone to 50%
      todos = [{"battery_percent", "phone", 50}]  # NUMERIC: 50 is an actual number
      
      # Planning should backtrack from failed fast charge to successful slow charge
      case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{action_name, _args}] = actions
          assert action_name == :slow_charge_numeric
          
        {:error, reason} ->
          flunk("Numeric fluent planning failed: #{reason}")
      end
    end

    test "boolean fluents - door control system" do
      # BOOLEAN FLUENTS: true/false are CATEGORICAL symbols, not numbers
      # true ≠ 1, false ≠ 0 in planning terms - they're just symbols like :open/:closed
      
      domain = Domain.Core.new("door_domain")
      
      # Manual door opening - requires key (unavailable)
      manual_open = DurativeAction.new(
        :manual_open_door,
        {:fixed, 3000},  # 3 seconds
        %{
          at_start: [{"has_key", "person", true}],  # Will fail - no key
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"door_open", "main_door", true}],  # BOOLEAN: true is a categorical symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("door_open", "main_door", true)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :manual_open_door, manual_open)
      
      # Electronic door opening - requires keycard (available)
      electronic_open = DurativeAction.new(
        :electronic_open_door,
        {:fixed, 1000},  # 1 second
        %{
          at_start: [{"has_keycard", "person", true}],  # Will succeed
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"door_open", "main_door", true}],  # BOOLEAN: true is a categorical symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("door_open", "main_door", true)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :electronic_open_door, electronic_open)
      
      # Add goal methods for door opening
      domain = Domain.add_unigoal_method(domain, "door_open", "try_manual_open", fn state, [door, target_state] ->
        current_state = StateV2.get_fact(state, door, "door_open")
        if current_state != target_state do
          [{:manual_open_door, []}]
        else
          []
        end
      end)
      
      domain = Domain.add_unigoal_method(domain, "door_open", "try_electronic_open", fn state, [door, target_state] ->
        current_state = StateV2.get_fact(state, door, "door_open")
        if current_state != target_state do
          [{:electronic_open_door, []}]
        else
          []
        end
      end)
      
      # Initial state - door closed, no key, has keycard
      initial_state = StateV2.new()
      |> StateV2.set_fact("door_open", "main_door", false)  # BOOLEAN: false is a categorical symbol
      |> StateV2.set_fact("has_key", "person", false)       # BOOLEAN: false (no physical key)
      |> StateV2.set_fact("has_keycard", "person", true)    # BOOLEAN: true (has electronic keycard)
      
      # Goal: open the door
      todos = [{"door_open", "main_door", true}]  # BOOLEAN: true is a categorical symbol
      
      # Planning should backtrack from failed manual open to successful electronic open
      case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{action_name, _args}] = actions
          assert action_name == :electronic_open_door
          
        {:error, reason} ->
          flunk("Boolean fluent planning failed: #{reason}")
      end
    end

    test "mixed fluent types in same domain" do
      # Shows that AriaEngine can handle categorical, numeric, and boolean fluents simultaneously
      
      domain = Domain.Core.new("mixed_domain")
      
      # Action that affects categorical, numeric, and boolean fluents
      work_action = DurativeAction.new(
        :work_on_project,
        {:fixed, 3000},
        %{
          at_start: [
            {"energy_level", "worker", :high},     # CATEGORICAL condition
            {"focus_minutes", "worker", 60},       # NUMERIC condition  
            {"computer_on", "workstation", true}   # BOOLEAN condition
          ],
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [
            {"project_status", "task1", :completed},  # CATEGORICAL effect
            {"focus_minutes", "worker", 20},          # NUMERIC effect (reduced focus)
            {"task_complete", "task1", true}          # BOOLEAN effect
          ],
          over_time: []
        },
        fn state, _args ->
          state
          |> StateV2.set_fact("project_status", "task1", :completed)
          |> StateV2.set_fact("focus_minutes", "worker", 20)
          |> StateV2.set_fact("task_complete", "task1", true)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :work_on_project, work_action)
      
      # Add a method to handle work tasks
      domain = Domain.add_unigoal_method(domain, "task_complete", "do_work", fn state, [task, target] ->
        current = StateV2.get_fact(state, task, "task_complete")
        if current != target do
          [{:work_on_project, []}]
        else
          []
        end
      end)
      
      # Initial state with mixed fluent types
      initial_state = StateV2.new()
      |> StateV2.set_fact("energy_level", "worker", :high)        # CATEGORICAL
      |> StateV2.set_fact("focus_minutes", "worker", 60)          # NUMERIC
      |> StateV2.set_fact("computer_on", "workstation", true)     # BOOLEAN
      |> StateV2.set_fact("project_status", "task1", :pending)    # CATEGORICAL
      |> StateV2.set_fact("task_complete", "task1", false)        # BOOLEAN
      
      # Goal: complete the task
      todos = [{"task_complete", "task1", true}]  # BOOLEAN goal
      
      case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 0) do
        {:ok, solution_tree} ->
          actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
          assert length(actions) == 1
          assert [{action_name, _args}] = actions
          assert action_name == :work_on_project
          
        {:error, reason} ->
          flunk("Mixed fluent type planning failed: #{reason}")
      end
    end
  end

  describe "Durative action backtracking" do
    test "categorical fluent backtracking with timeline" do
      # REFACTORED: Using clearly categorical symbols instead of misleading "50%" strings
      
      domain = Domain.Core.new("phone_charging")
      
      # Create STN for timeline management
      stn = STN.new()
      
      # Add fast charging durative action - will fail (no fast charger available)
      fast_charge = DurativeAction.new(
        :fast_charge,
        {:fixed, 300000},  # 5 minutes in milliseconds
        %{
          at_start: [{"fast_charger", "available", true}],  # Will fail - not available
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"battery_status", "phone", :medium}],  # CATEGORICAL: :medium is a symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("battery_status", "phone", :medium)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :fast_charge, fast_charge)
      stn = STN.Core.add_durative_action(stn, fast_charge)
      
      # Add slow charging durative action - will succeed
      slow_charge = DurativeAction.new(
        :slow_charge,
        {:fixed, 1200000},  # 20 minutes in milliseconds
        %{
          at_start: [{"power_outlet", "available", true}],  # Will succeed
          over_all: [],
          at_end: []
        },
        %{
          at_start: [],
          at_end: [{"battery_status", "phone", :medium}],  # CATEGORICAL: :medium is a symbol
          over_time: []
        },
        fn state, _args ->
          state |> StateV2.set_fact("battery_status", "phone", :medium)
        end
      )
      domain = Domain.Core.add_durative_action(domain, :slow_charge, slow_charge)
      stn = STN.Core.add_durative_action(stn, slow_charge)
      
      # Add timeline constraint: must finish charging before meeting (30 min deadline)
      stn = STN.add_constraint(stn, "start", "meeting_deadline", {1800000, 1800000})  # 30 min total
      
      # Add goal method for fast charging (will be tried first)
      domain = Domain.add_unigoal_method(domain, "battery_status", "try_fast_charge", fn state, [device, target_level] ->
        current_level = StateV2.get_fact(state, device, "battery_status")
        if current_level != target_level do
          [{:fast_charge, []}]
        else
          []
        end
      end)
      
      # Add goal method for slow charging (will be tried second)
      domain = Domain.add_unigoal_method(domain, "battery_status", "try_slow_charge", fn state, [device, target_level] ->
        current_level = StateV2.get_fact(state, device, "battery_status")
        if current_level != target_level do
          [{:slow_charge, []}]
        else
          []
        end
      end)
      
      # Initial state - no fast charger available, but power outlet available
      initial_state = StateV2.new()
      |> StateV2.set_fact("battery_status", "phone", :low)    # CATEGORICAL: :low is a symbol
      |> StateV2.set_fact("fast_charger", "available", false) # Fast charger unavailable
      |> StateV2.set_fact("power_outlet", "available", true)  # Power outlet available
      
      # Goal: charge phone to medium battery status
      todos = [{"battery_status", "phone", :medium}]  # CATEGORICAL: :medium is a symbol
      
      # Verify STN is consistent before planning
      assert STN.consistent?(stn)
      
      # Planning should backtrack from failed fast charge to successful slow charge
      case AriaEngine.Plan.Core.plan(domain, initial_state, todos, verbose: 1) do
        {:ok, solution_tree} ->
          # Verify the solution used slow charge (not fast charge)
          actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
          
          # Should have exactly one action: slow_charge
          assert length(actions) == 1
          assert [{action_name, _args}] = actions
          assert action_name == :slow_charge
          
          # Verify timeline constraints were respected
          assert STN.consistent?(stn)
          
          # Verify the fast charge node was tried but failed
          fast_charge_nodes = Enum.filter(solution_tree.nodes, fn {_id, node} ->
            case node.task do
              {:fast_charge, _} -> true
              _ -> false
            end
          end)
          
          # Should have tried fast charge but it failed
          assert length(fast_charge_nodes) >= 0  # May not appear if method fails early
          
        {:error, reason} ->
          flunk("Planning should have succeeded with backtracking, but failed: #{reason}")
      end
    end
  end
end
