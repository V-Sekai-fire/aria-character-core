# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TestDomains do
  @moduledoc """
  Test domain builders for AriaEngine testing.

  This module provides domain builders for logistics, blocks world,
  simple travel, backtracking, simple HGN, simple RPG, RPG, test domain,
  and acting error domains used in testing scenarios.
  """

  alias {Domain, StateV2, SimpleTravelActions, SimpleTravelMethods}

  @doc """
  Builds a logistics domain for testing.

  This creates a sample domain with basic logistics actions and methods.
  """
  @spec build_logistics_domain() :: domain()
  def build_logistics_domain do
    domain = Domain.new("logistics")

    # Add basic movement actions (with both naming conventions for compatibility)
    domain
    |> Domain.add_action(:drive, &LogisticsActions.drive_truck/2)
    |> Domain.add_action(:drive_truck, &LogisticsActions.drive_truck/2)
    |> Domain.add_action(:fly, &LogisticsActions.fly_plane/2)
    |> Domain.add_action(:fly_plane, &LogisticsActions.fly_plane/2)
    |> Domain.add_action(:load, &LogisticsActions.load_truck/2)
    |> Domain.add_action(:load_truck, &LogisticsActions.load_truck/2)
    |> Domain.add_action(:unload, &LogisticsActions.unload_truck/2)
    |> Domain.add_action(:unload_truck, &LogisticsActions.unload_truck/2)
    |> Domain.add_action(:load_plane, &LogisticsActions.load_plane/2)
    |> Domain.add_action(:unload_plane, &LogisticsActions.unload_plane/2)

    # Add task methods
    |> Domain.add_task_method("transport", &LogisticsMethods.transport/2)

    # Add unigoal methods
    |> Domain.add_unigoal_method("truck_at", &LogisticsMethods.truck_at/2)
    |> Domain.add_unigoal_method("plane_at", &LogisticsMethods.plane_at/2)
    |> Domain.add_unigoal_method("at", &LogisticsMethods.at_unigoal/2)
  end

  @doc """
  Builds a blocks world domain for testing.

  This creates a domain with the four basic blocks world actions and
  associated task and goal methods for complex block manipulation.
  """
  @spec build_blocks_world_domain() :: domain()
  def build_blocks_world_domain do
    domain = Domain.new("blocks_world")

    # Add basic blocks world actions
    domain
    |> Domain.add_action(:pickup, &BlocksWorldActions.pickup/2)
    |> Domain.add_action(:putdown, &BlocksWorldActions.putdown/2)
    |> Domain.add_action(:stack, &BlocksWorldActions.stack/2)
    |> Domain.add_action(:unstack, &BlocksWorldActions.unstack/2)

    # Add task methods
    |> Domain.add_task_method("move_block", &BlocksWorldMethods.move_block/2)
    |> Domain.add_task_method("get_block", &BlocksWorldMethods.get_block/2)
    |> Domain.add_task_method("clear_block", &BlocksWorldMethods.clear_block/2)
    |> Domain.add_task_method("build_tower", &BlocksWorldMethods.build_tower/2)

    # Add unigoal methods
    |> Domain.add_unigoal_method("on", &BlocksWorldMethods.on_unigoal/2)
    |> Domain.add_unigoal_method("on_table", &BlocksWorldMethods.on_table_unigoal/2)
    |> Domain.add_unigoal_method("clear", &BlocksWorldMethods.clear_unigoal/2)
  end

  @doc """
  Builds a blocks world Goal-Task-Network (GTN) domain for testing.

  This creates a blocks world domain that uses both goals and tasks,
  implementing the near-optimal algorithm from Gupta & Nau (1992).
  """
  @spec build_blocks_gtn_domain() :: domain()
  def build_blocks_gtn_domain do
    domain = Domain.new("blocks_gtn")

    # Add basic blocks world actions
    domain
    |> Domain.add_action(:pickup, &BlocksWorldActions.pickup/2)
    |> Domain.add_action(:putdown, &BlocksWorldActions.putdown/2)
    |> Domain.add_action(:stack, &BlocksWorldActions.stack/2)
    |> Domain.add_action(:unstack, &BlocksWorldActions.unstack/2)

    # Add task methods for take and put
    |> Domain.add_task_method("take", &BlocksWorldMethods.take_from_table/2)
    |> Domain.add_task_method("take", &BlocksWorldMethods.take_from_block/2)
    |> Domain.add_task_method("put", &BlocksWorldMethods.put_on_table/2)
    |> Domain.add_task_method("put", &BlocksWorldMethods.put_on_block/2)

    # Add unigoal methods for blocks positioning
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_table/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_block/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_in_hand/2)

    # Add multigoal methods
    |> Domain.add_multigoal_method(&BlocksWorldMethods.achieve_blocks_multigoal/2)
  end

  @doc """
  Builds a blocks world Hierarchical Goal Network (HGN) domain for testing.

  This creates a blocks world domain that uses only goals (no tasks),
  implementing the near-optimal algorithm from Gupta & Nau (1992).
  """
  @spec build_blocks_hgn_domain() :: domain()
  def build_blocks_hgn_domain do
    domain = Domain.new("blocks_hgn")

    # Add basic blocks world actions
    domain
    |> Domain.add_action(:pickup, &BlocksWorldActions.pickup/2)
    |> Domain.add_action(:putdown, &BlocksWorldActions.putdown/2)
    |> Domain.add_action(:stack, &BlocksWorldActions.stack/2)
    |> Domain.add_action(:unstack, &BlocksWorldActions.unstack/2)

    # Add unigoal methods only (no task methods)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_table/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_block/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_in_hand/2)

    # Add multigoal methods for complex goals
    |> Domain.add_multigoal_method(&BlocksWorldMethods.achieve_blocks_multigoal/2)
  end

  @doc """
  Builds a blocks world Goal Splitting domain for testing.

  This creates a blocks world domain that demonstrates goal splitting,
  using GTPyhop's built-in method to split multigoals into unigoals
  and achieve them sequentially.
  """
  @spec build_blocks_goal_splitting_domain() :: domain()
  def build_blocks_goal_splitting_domain do
    domain = Domain.new("blocks_goal_splitting")

    # Add basic blocks world actions
    domain
    |> Domain.add_action(:pickup, &BlocksWorldActions.pickup/2)
    |> Domain.add_action(:putdown, &BlocksWorldActions.putdown/2)
    |> Domain.add_action(:stack, &BlocksWorldActions.stack/2)
    |> Domain.add_action(:unstack, &BlocksWorldActions.unstack/2)

    # Add only basic unigoal methods (relies on built-in goal splitting)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_table/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_on_block/2)
    |> Domain.add_unigoal_method("pos", &BlocksWorldMethods.pos_in_hand/2)
    |> Domain.add_unigoal_method("clear", &BlocksWorldMethods.clear_block/2)
    |> Domain.add_unigoal_method("holding", &BlocksWorldMethods.holding_state/2)

    # Use built-in goal splitting method
    |> Domain.add_multigoal_method(&Multigoal.split_multigoal/2)
  end

  @doc """
  Builds a simple travel domain for testing.

  This creates a domain with basic travel actions (walk, call_taxi, ride_taxi, pay_driver)
  and associated task methods for travel planning.
  """
  @spec build_simple_travel_domain() :: domain()
  def build_simple_travel_domain do
    Domain.new("simple_travel")
    |> Domain.add_action(:walk, &SimpleTravelActions.walk/2)
    |> Domain.add_action(:call_taxi, &SimpleTravelActions.call_taxi/2)
    |> Domain.add_action(:ride_taxi, &SimpleTravelActions.ride_taxi/2)
    |> Domain.add_action(:pay_driver, &SimpleTravelActions.pay_driver/2)
    |> Domain.add_task_method("travel", &SimpleTravelMethods.do_nothing/2)
    |> Domain.add_task_method("travel", &SimpleTravelMethods.travel_by_foot/2)
    |> Domain.add_task_method("travel", &SimpleTravelMethods.travel_by_taxi/2)
    |> Domain.add_unigoal_method("loc", &SimpleTravelMethods.loc_unigoal/2)
  end

  @doc """
  Builds a Pyhop Simple Travel domain for testing backward compatibility.

  This creates a simpler version of the travel domain that maintains
  compatibility with the original Pyhop planner interface.
  """
  @spec build_pyhop_simple_travel_domain() :: domain()
  def build_pyhop_simple_travel_domain do
    domain = Domain.new("pyhop_simple_travel")

    # Add basic travel actions
    domain
    |> Domain.add_action(:walk, &SimpleTravelActions.walk/2)
    |> Domain.add_action(:call_taxi, &SimpleTravelActions.call_taxi/2)
    |> Domain.add_action(:ride_taxi, &SimpleTravelActions.ride_taxi_simple/2)
    |> Domain.add_action(:pay_driver, &SimpleTravelActions.pay_driver_simple/2)

    # Add task methods for travel
    |> Domain.add_task_method("travel", &SimpleTravelMethods.travel_by_foot_simple/2)
    |> Domain.add_task_method("travel", &SimpleTravelMethods.travel_by_taxi_simple/2)
  end

  @doc """
  Builds a backtracking HTN domain for testing.

  This creates a domain with flag manipulation actions and multiple
  task methods that demonstrate backtracking behavior.
  """
  @spec build_backtracking_domain() :: domain()
  def build_backtracking_domain do
    Domain.new("backtracking")
    |> Domain.add_action(:putv, &putv_action/2)
    |> Domain.add_action(:getv, &getv_action/2)
    |> Domain.add_task_method("put_it", &m_err/2)
    |> Domain.add_task_method("put_it", &m0/2)
    |> Domain.add_task_method("put_it", &m1/2)
    |> Domain.add_task_method("need0", &m_need0/2)
    |> Domain.add_task_method("need1", &m_need1/2)
    |> Domain.add_task_method("need01", &m_need0/2)
    |> Domain.add_task_method("need01", &m_need1/2)
    |> Domain.add_task_method("need10", &m_need1/2)
    |> Domain.add_task_method("need10", &m_need0/2)
  end

  @doc """
  Builds a simple HGN (goal-oriented) domain for testing.

  This creates a domain with travel actions and unigoal methods
  for goal-oriented planning.
  """
  @spec build_simple_hgn_domain() :: domain()
  def build_simple_hgn_domain do
    Domain.new("simple_hgn")
    |> Domain.add_action(:walk, &walk_action/2)
    |> Domain.add_action(:call_taxi, &call_taxi_action/2)
    |> Domain.add_action(:ride_taxi, &ride_taxi_action/2)
    |> Domain.add_action(:pay_driver, &pay_driver_action/2)
    |> Domain.add_unigoal_method("loc", &travel_by_foot/2)
    |> Domain.add_unigoal_method("loc", &travel_by_taxi/2)
  end

  @doc """
  Builds a simple HTN acting error domain for testing (actions version).

  This creates a domain with travel actions for planning that assumes
  taxis are always in good condition.
  """
  @spec build_simple_htn_acting_error_actions_domain() :: domain()
  def build_simple_htn_acting_error_actions_domain do
    Domain.new("simple_htn_acting_error_actions")
    |> Domain.add_action(:walk, &walk_action_htn/2)
    |> Domain.add_action(:call_taxi, &call_taxi_action_htn/2)
    |> Domain.add_action(:ride_taxi, &ride_taxi_action_htn/2)
    |> Domain.add_action(:pay_driver, &pay_driver_action_htn/2)
    |> Domain.add_task_method("travel", &do_nothing_htn/2)
    |> Domain.add_task_method("travel", &travel_by_foot_htn/2)
    |> Domain.add_task_method("travel", &travel_by_taxi_htn/2)
  end

  @doc """
  Builds a simple HTN acting error domain for testing (commands version).

  This creates a domain with travel commands for execution that checks
  taxi conditions and can fail if taxis are in bad condition.
  """
  @spec build_simple_htn_acting_error_commands_domain() :: domain()
  def build_simple_htn_acting_error_commands_domain do
    Domain.new("simple_htn_acting_error_commands")
    |> Domain.add_action(:walk, &walk_command_htn/2)
    |> Domain.add_action(:call_taxi, &call_taxi_command_htn/2)
    |> Domain.add_action(:ride_taxi, &ride_taxi_command_htn/2)
    |> Domain.add_action(:pay_driver, &pay_driver_command_htn/2)
    |> Domain.add_task_method("travel", &do_nothing_htn/2)
    |> Domain.add_task_method("travel", &travel_by_foot_htn/2)
    |> Domain.add_task_method("travel", &travel_by_taxi_htn/2)
  end

  @doc """
  Builds a simple RPG domain for basic planning tests.

  This creates a domain with move and pickup actions for simple planning scenarios.
  """
  @spec build_simple_rpg_domain() :: domain()
  def build_simple_rpg_domain do
    # Define simple actions
    move_action = fn state, [to] ->
      StateV2.set_fact(state, "player", "location", to)
    end

    pickup_action = fn state, [item] ->
      player_location = StateV2.get_fact(state, "player", "location")
      item_location = StateV2.get_fact(state, item, "location")

      if player_location == item_location do
        StateV2.set_fact(state, "player", "has", item)
      else
        false  # Can't pickup item not in same location
      end
    end

    # Create domain with actions
    Domain.new("simple_rpg")
    |> Domain.add_action(:move, move_action)
    |> Domain.add_action(:pickup, pickup_action)
  end

  @doc """
  Builds an RPG domain with task methods for planning tests.

  This creates a domain with move, pickup actions and a get_item task method.
  """
  @spec build_rpg_domain() :: domain()
  def build_rpg_domain do
    # Actions
    move_action = fn state, [to] ->
      StateV2.set_fact(state, "player", "location", to)
    end

    pickup_action = fn state, [item] ->
      player_location = StateV2.get_fact(state, "player", "location")
      item_location = StateV2.get_fact(state, item, "location")

      if player_location == item_location do
        StateV2.set_fact(state, "player", "has", item)
      else
        false
      end
    end

    # Task method: get item from another room
    get_item_method = fn state, [item] ->
      player_location = StateV2.get_fact(state, "player", "location")
      item_location = StateV2.get_fact(state, item, "location")

      if player_location == item_location do
        # Already in same room, just pickup
        [{:pickup, [item]}]
      else
        # Need to move then pickup
        [{:move, [item_location]}, {:pickup, [item]}]
      end
    end

    Domain.new("rpg")
    |> Domain.add_action(:move, move_action)
    |> Domain.add_action(:pickup, pickup_action)
    |> Domain.add_task_method("get_item", get_item_method)
  end

  @doc """
  Builds a simple test domain for domain tests.

  This creates a basic domain with move and pickup actions for testing domain functionality.
  """
  @spec build_test_domain() :: domain()
  def build_test_domain do
    move_action = fn state, [_from, to] ->
      StateV2.set_fact(state, "player", "location", to)
    end

    pickup_action = fn state, [item] ->
      StateV2.set_fact(state, "player", "has", item)
    end

    Domain.new("test")
    |> Domain.add_action(:move, move_action)
    |> Domain.add_action(:pickup, pickup_action)
  end

  # Helper functions for state creation

  @doc """
  Creates an initial state for simple travel domain testing.
  """
  @spec create_simple_travel_state() :: state()
  def create_simple_travel_state do
    StateV2.new()
    |> StateV2.set_fact("alice", "loc", "home_a")
    |> StateV2.set_fact("bob", "loc", "home_b")
    |> StateV2.set_fact("taxi1", "loc", "park")
    |> StateV2.set_fact("taxi2", "loc", "station")
    |> StateV2.set_fact("alice", "cash", 20)
    |> StateV2.set_fact("bob", "cash", 15)
    |> StateV2.set_fact("alice", "owe", 0)
    |> StateV2.set_fact("bob", "owe", 0)
  end

  @doc """
  Creates an initial state for backtracking domain testing.
  """
  @spec create_backtracking_state() :: state()
  def create_backtracking_state do
    StateV2.new()
    |> StateV2.set_fact("system", "flag", -1)
  end

  @doc """
  Creates an initial state for simple HGN domain testing.
  """
  @spec create_simple_hgn_state() :: state()
  def create_simple_hgn_state do
    StateV2.new()
    |> StateV2.set_fact("alice", "loc", "home_a")
    |> StateV2.set_fact("bob", "loc", "home_b")
    |> StateV2.set_fact("taxi1", "loc", "park")
    |> StateV2.set_fact("taxi2", "loc", "station")
    |> StateV2.set_fact("alice", "cash", 20)
    |> StateV2.set_fact("bob", "cash", 15)
    |> StateV2.set_fact("alice", "owe", 0)
    |> StateV2.set_fact("bob", "owe", 0)
  end

  @doc """
  Creates an initial state with good taxis for HTN acting error testing.
  """
  @spec create_good_taxi_state() :: state()
  def create_good_taxi_state do
    StateV2.new()
    |> StateV2.set_fact("alice", "loc", "home_a")
    |> StateV2.set_fact("bob", "loc", "home_b")
    |> StateV2.set_fact("taxi1", "loc", "park")
    |> StateV2.set_fact("taxi2", "loc", "station")
    |> StateV2.set_fact("alice", "cash", 20)
    |> StateV2.set_fact("bob", "cash", 15)
    |> StateV2.set_fact("alice", "owe", 0)
    |> StateV2.set_fact("bob", "owe", 0)
    |> StateV2.set_fact("taxi1", "taxi_condition", "good")
    |> StateV2.set_fact("taxi2", "taxi_condition", "good")
  end

  @doc """
  Creates an initial state with bad taxis for HTN acting error testing.
  """
  @spec create_bad_taxi_state() :: state()
  def create_bad_taxi_state do
    StateV2.new()
    |> StateV2.set_fact("alice", "loc", "home_a")
    |> StateV2.set_fact("bob", "loc", "home_b")
    |> StateV2.set_fact("taxi1", "loc", "park")
    |> StateV2.set_fact("taxi2", "loc", "station")
    |> StateV2.set_fact("alice", "cash", 20)
    |> StateV2.set_fact("bob", "cash", 15)
    |> StateV2.set_fact("alice", "owe", 0)
    |> StateV2.set_fact("bob", "owe", 0)
    |> StateV2.set_fact("taxi1", "taxi_condition", "bad")
    |> StateV2.set_fact("taxi2", "taxi_condition", "bad")
  end

  # Private helper functions for backtracking domain

  defp putv_action(state, [flag_val]) do
    StateV2.set_fact(state, "system", "flag", flag_val)
  end

  defp getv_action(state, [flag_val]) do
    current_flag = StateV2.get_fact(state, "system", "flag")
    if current_flag == flag_val do
      state
    else
      false
    end
  end

  defp m_err(_state, []) do
    [{"putv", [0]}, {"getv", [1]}]
  end

  defp m0(_state, []) do
    [{"putv", [0]}, {"getv", [0]}]
  end

  defp m1(_state, []) do
    [{"putv", [1]}, {"getv", [1]}]
  end

  defp m_need0(_state, []) do
    [{"getv", [0]}]
  end

  defp m_need1(_state, []) do
    [{"getv", [1]}]
  end

  # Private helper functions for simple HGN domain

  defp walk_action(state, [person, from, to]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    if current_loc == from do
      StateV2.set_fact(state, person, "loc", to)
    else
      false
    end
  end

  defp call_taxi_action(state, [person, taxi]) do
    person_loc = StateV2.get_fact(state, person, "loc")
    StateV2.set_fact(state, taxi, "loc", person_loc)
  end

  defp ride_taxi_action(state, [person, taxi, to]) do
    person_loc = StateV2.get_fact(state, person, "loc")
    taxi_loc = StateV2.get_fact(state, taxi, "loc")
    if person_loc == taxi_loc do
      state
      |> StateV2.set_fact(person, "loc", to)
      |> StateV2.set_fact(taxi, "loc", to)
    else
      false
    end
  end

  defp pay_driver_action(state, [person, taxi]) do
    fare = taxi_fare(StateV2.get_fact(state, person, "loc"), StateV2.get_fact(state, taxi, "loc"))
    cash = StateV2.get_fact(state, person, "cash")
    if cash >= fare do
      StateV2.set_fact(state, person, "cash", cash - fare)
    else
      false
    end
  end

  defp travel_by_foot(state, [["loc", person, destination]]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    distance = distance_between(current_loc, destination)
    if distance <= 2 do
      [{"walk", person, current_loc, destination}]
    else
      false
    end
  end

  defp travel_by_taxi(state, [["loc", person, destination]]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    taxis = ["taxi1", "taxi2"]

    case Enum.find(taxis, fn _taxi ->
      cash = StateV2.get_fact(state, person, "cash")
      fare = taxi_fare(current_loc, destination)
      cash >= fare
    end) do
      nil -> false
      taxi ->
        [
          {"call_taxi", person, taxi},
          {"ride_taxi", person, taxi, destination},
          {"pay_driver", person, taxi}
        ]
    end
  end

  # Private helper functions for HTN acting error domain

  defp walk_action_htn(state, [person, from, to]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    if current_loc == from do
      StateV2.set_fact(state, person, "loc", to)
    else
      false
    end
  end

  defp call_taxi_action_htn(state, [person, taxi]) do
    person_loc = StateV2.get_fact(state, person, "loc")
    StateV2.set_fact(state, taxi, "loc", person_loc)
  end

  defp ride_taxi_action_htn(state, [person, taxi, to]) do
    person_loc = StateV2.get_fact(state, person, "loc")
    taxi_loc = StateV2.get_fact(state, taxi, "loc")
    if person_loc == taxi_loc do
      state
      |> StateV2.set_fact(person, "loc", to)
      |> StateV2.set_fact(taxi, "loc", to)
    else
      false
    end
  end

  defp pay_driver_action_htn(state, [person, taxi]) do
    fare = taxi_fare(StateV2.get_fact(state, person, "loc"), StateV2.get_fact(state, taxi, "loc"))
    cash = StateV2.get_fact(state, person, "cash")
    if cash >= fare do
      StateV2.set_fact(state, person, "cash", cash - fare)
    else
      false
    end
  end

  defp walk_command_htn(state, [person, from, to]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    if current_loc == from do
      StateV2.set_fact(state, person, "loc", to)
    else
      false
    end
  end

  defp call_taxi_command_htn(state, [person, taxi]) do
    taxi_condition = StateV2.get_fact(state, taxi, "taxi_condition")
    if taxi_condition == "good" do
      person_loc = StateV2.get_fact(state, person, "loc")
      StateV2.set_fact(state, taxi, "loc", person_loc)
    else
      false
    end
  end

  defp ride_taxi_command_htn(state, [person, taxi, to]) do
    person_loc = StateV2.get_fact(state, person, "loc")
    taxi_loc = StateV2.get_fact(state, taxi, "loc")
    taxi_condition = StateV2.get_fact(state, taxi, "taxi_condition")

    if person_loc == taxi_loc and taxi_condition == "good" do
      state
      |> StateV2.set_fact(person, "loc", to)
      |> StateV2.set_fact(taxi, "loc", to)
    else
      false
    end
  end

  defp pay_driver_command_htn(state, [person, taxi]) do
    fare = taxi_fare(StateV2.get_fact(state, person, "loc"), StateV2.get_fact(state, taxi, "loc"))
    cash = StateV2.get_fact(state, person, "cash")
    if cash >= fare do
      StateV2.set_fact(state, person, "cash", cash - fare)
    else
      false
    end
  end

  defp do_nothing_htn(_state, ["travel", _person, _destination]), do: []

  defp travel_by_foot_htn(state, ["travel", person, destination]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    distance = distance_between(current_loc, destination)
    if distance <= 2 do
      [{"walk", person, current_loc, destination}]
    else
      false
    end
  end

  defp travel_by_taxi_htn(state, ["travel", person, destination]) do
    current_loc = StateV2.get_fact(state, person, "loc")
    taxis = ["taxi1", "taxi2"]

    case Enum.find(taxis, fn _taxi ->
      cash = StateV2.get_fact(state, person, "cash")
      fare = taxi_fare(current_loc, destination)
      cash >= fare
    end) do
      nil -> false
      taxi ->
        [
          {"call_taxi", person, taxi},
          {"ride_taxi", person, taxi, destination},
          {"pay_driver", person, taxi}
        ]
    end
  end

  # Utility functions

  defp distance_between(loc1, loc2) when loc1 == loc2, do: 0
  defp distance_between("home_a", "home_b"), do: 8
  defp distance_between("home_b", "home_a"), do: 8
  defp distance_between("home_a", "park"), do: 2
  defp distance_between("park", "home_a"), do: 2
  defp distance_between("home_b", "park"), do: 6
  defp distance_between("park", "home_b"), do: 6
  defp distance_between("home_a", "station"), do: 4
  defp distance_between("station", "home_a"), do: 4
  defp distance_between("home_b", "station"), do: 2
  defp distance_between("station", "home_b"), do: 2
  defp distance_between("park", "station"), do: 4
  defp distance_between("station", "park"), do: 4
  defp distance_between(_, _), do: 10

  defp taxi_fare(from, to) do
    distance = distance_between(from, to)
    1.5 + 0.5 * distance
  end
end
