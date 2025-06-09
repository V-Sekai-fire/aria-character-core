# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TestDomains do
  @moduledoc """
  Test domain builders for AriaEngine testing.

  This module provides domain builders for logistics, blocks world,
  simple travel, backtracking, simple HGN, and acting error domains
  used in testing scenarios.
  """

  import AriaEngine
  alias AriaEngine.{State, SimpleTravelActions, SimpleTravelMethods}

  @doc """
  Builds a logistics domain for testing.

  This creates a sample domain with basic logistics actions and methods.
  """
  @spec build_logistics_domain() :: AriaEngine.domain()
  def build_logistics_domain do
    domain = create_domain("logistics")

    # Add basic movement actions (with both naming conventions for compatibility)
    domain
    |> add_action(:drive, &AriaEngine.LogisticsActions.drive_truck/2)
    |> add_action(:drive_truck, &AriaEngine.LogisticsActions.drive_truck/2)
    |> add_action(:fly, &AriaEngine.LogisticsActions.fly_plane/2)
    |> add_action(:fly_plane, &AriaEngine.LogisticsActions.fly_plane/2)
    |> add_action(:load, &AriaEngine.LogisticsActions.load_truck/2)
    |> add_action(:load_truck, &AriaEngine.LogisticsActions.load_truck/2)
    |> add_action(:unload, &AriaEngine.LogisticsActions.unload_truck/2)
    |> add_action(:unload_truck, &AriaEngine.LogisticsActions.unload_truck/2)
    |> add_action(:load_plane, &AriaEngine.LogisticsActions.load_plane/2)
    |> add_action(:unload_plane, &AriaEngine.LogisticsActions.unload_plane/2)

    # Add task methods
    |> add_task_method("transport", &AriaEngine.LogisticsMethods.transport/2)

    # Add unigoal methods
    |> add_unigoal_method("truck_at", &AriaEngine.LogisticsMethods.truck_at/2)
    |> add_unigoal_method("plane_at", &AriaEngine.LogisticsMethods.plane_at/2)
    |> add_unigoal_method("at", &AriaEngine.LogisticsMethods.at_unigoal/2)
  end

  @doc """
  Builds a blocks world domain for testing.

  This creates a domain with the four basic blocks world actions and
  associated task and goal methods for complex block manipulation.
  """
  @spec build_blocks_world_domain() :: AriaEngine.domain()
  def build_blocks_world_domain do
    domain = create_domain("blocks_world")

    # Add basic blocks world actions
    domain
    |> add_action(:pickup, &AriaEngine.BlocksWorldActions.pickup/2)
    |> add_action(:putdown, &AriaEngine.BlocksWorldActions.putdown/2)
    |> add_action(:stack, &AriaEngine.BlocksWorldActions.stack/2)
    |> add_action(:unstack, &AriaEngine.BlocksWorldActions.unstack/2)

    # Add task methods
    |> add_task_method("move_block", &AriaEngine.BlocksWorldMethods.move_block/2)
    |> add_task_method("get_block", &AriaEngine.BlocksWorldMethods.get_block/2)
    |> add_task_method("clear_block", &AriaEngine.BlocksWorldMethods.clear_block/2)
    |> add_task_method("build_tower", &AriaEngine.BlocksWorldMethods.build_tower/2)

    # Add unigoal methods
    |> add_unigoal_method("on", &AriaEngine.BlocksWorldMethods.on_unigoal/2)
    |> add_unigoal_method("on_table", &AriaEngine.BlocksWorldMethods.on_table_unigoal/2)
    |> add_unigoal_method("clear", &AriaEngine.BlocksWorldMethods.clear_unigoal/2)
  end

  @doc """
  Builds a simple travel domain for testing.

  This creates a domain with basic travel actions (walk, call_taxi, ride_taxi, pay_driver)
  and associated task methods for travel planning.
  """
  @spec build_simple_travel_domain() :: AriaEngine.domain()
  def build_simple_travel_domain do
    create_domain("simple_travel")
    |> add_action(:walk, &SimpleTravelActions.walk/2)
    |> add_action(:call_taxi, &SimpleTravelActions.call_taxi/2)
    |> add_action(:ride_taxi, &SimpleTravelActions.ride_taxi/2)
    |> add_action(:pay_driver, &SimpleTravelActions.pay_driver/2)
    |> add_task_method("travel", &SimpleTravelMethods.do_nothing/2)
    |> add_task_method("travel", &SimpleTravelMethods.travel_by_foot/2)
    |> add_task_method("travel", &SimpleTravelMethods.travel_by_taxi/2)
    |> add_unigoal_method("loc", &SimpleTravelMethods.loc_unigoal/2)
  end

  @doc """
  Builds a backtracking HTN domain for testing.

  This creates a domain with flag manipulation actions and multiple
  task methods that demonstrate backtracking behavior.
  """
  @spec build_backtracking_domain() :: AriaEngine.domain()
  def build_backtracking_domain do
    create_domain("backtracking")
    |> add_action(:putv, &putv_action/2)
    |> add_action(:getv, &getv_action/2)
    |> add_task_method("put_it", &m_err/2)
    |> add_task_method("put_it", &m0/2)
    |> add_task_method("put_it", &m1/2)
    |> add_task_method("need0", &m_need0/2)
    |> add_task_method("need1", &m_need1/2)
    |> add_task_method("need01", &m_need0/2)
    |> add_task_method("need01", &m_need1/2)
    |> add_task_method("need10", &m_need1/2)
    |> add_task_method("need10", &m_need0/2)
  end

  @doc """
  Builds a simple HGN (goal-oriented) domain for testing.

  This creates a domain with travel actions and unigoal methods
  for goal-oriented planning.
  """
  @spec build_simple_hgn_domain() :: AriaEngine.domain()
  def build_simple_hgn_domain do
    create_domain("simple_hgn")
    |> add_action(:walk, &walk_action/2)
    |> add_action(:call_taxi, &call_taxi_action/2)
    |> add_action(:ride_taxi, &ride_taxi_action/2)
    |> add_action(:pay_driver, &pay_driver_action/2)
    |> add_unigoal_method("loc", &travel_by_foot/2)
    |> add_unigoal_method("loc", &travel_by_taxi/2)
  end

  @doc """
  Builds a simple HTN acting error domain for testing (actions version).

  This creates a domain with travel actions for planning that assumes
  taxis are always in good condition.
  """
  @spec build_simple_htn_acting_error_actions_domain() :: AriaEngine.domain()
  def build_simple_htn_acting_error_actions_domain do
    create_domain("simple_htn_acting_error_actions")
    |> add_action(:walk, &walk_action_htn/2)
    |> add_action(:call_taxi, &call_taxi_action_htn/2)
    |> add_action(:ride_taxi, &ride_taxi_action_htn/2)
    |> add_action(:pay_driver, &pay_driver_action_htn/2)
    |> add_task_method("travel", &do_nothing_htn/2)
    |> add_task_method("travel", &travel_by_foot_htn/2)
    |> add_task_method("travel", &travel_by_taxi_htn/2)
  end

  @doc """
  Builds a simple HTN acting error domain for testing (commands version).

  This creates a domain with travel commands for execution that checks
  taxi conditions and can fail if taxis are in bad condition.
  """
  @spec build_simple_htn_acting_error_commands_domain() :: AriaEngine.domain()
  def build_simple_htn_acting_error_commands_domain do
    create_domain("simple_htn_acting_error_commands")
    |> add_action(:walk, &walk_command_htn/2)
    |> add_action(:call_taxi, &call_taxi_command_htn/2)
    |> add_action(:ride_taxi, &ride_taxi_command_htn/2)
    |> add_action(:pay_driver, &pay_driver_command_htn/2)
    |> add_task_method("travel", &do_nothing_htn/2)
    |> add_task_method("travel", &travel_by_foot_htn/2)
    |> add_task_method("travel", &travel_by_taxi_htn/2)
  end

  # Helper functions for state creation

  @doc """
  Creates an initial state for simple travel domain testing.
  """
  @spec create_simple_travel_state() :: AriaEngine.state()
  def create_simple_travel_state do
    create_state()
    |> set_fact("loc", "alice", "home_a")
    |> set_fact("loc", "bob", "home_b")
    |> set_fact("loc", "taxi1", "park")
    |> set_fact("loc", "taxi2", "station")
    |> set_fact("cash", "alice", 20)
    |> set_fact("cash", "bob", 15)
    |> set_fact("owe", "alice", 0)
    |> set_fact("owe", "bob", 0)
  end

  @doc """
  Creates an initial state for backtracking domain testing.
  """
  @spec create_backtracking_state() :: AriaEngine.state()
  def create_backtracking_state do
    create_state()
    |> set_fact("flag", "system", -1)
  end

  @doc """
  Creates an initial state for simple HGN domain testing.
  """
  @spec create_simple_hgn_state() :: AriaEngine.state()
  def create_simple_hgn_state do
    create_state()
    |> State.set_object("loc", "alice", "home_a")
    |> State.set_object("loc", "bob", "home_b")
    |> State.set_object("loc", "taxi1", "park")
    |> State.set_object("loc", "taxi2", "station")
    |> State.set_object("cash", "alice", 20)
    |> State.set_object("cash", "bob", 15)
    |> State.set_object("owe", "alice", 0)
    |> State.set_object("owe", "bob", 0)
  end

  @doc """
  Creates an initial state with good taxis for HTN acting error testing.
  """
  @spec create_good_taxi_state() :: AriaEngine.state()
  def create_good_taxi_state do
    create_state()
    |> State.set_object("loc", "alice", "home_a")
    |> State.set_object("loc", "bob", "home_b")
    |> State.set_object("loc", "taxi1", "park")
    |> State.set_object("loc", "taxi2", "station")
    |> State.set_object("cash", "alice", 20)
    |> State.set_object("cash", "bob", 15)
    |> State.set_object("owe", "alice", 0)
    |> State.set_object("owe", "bob", 0)
    |> State.set_object("taxi_condition", "taxi1", "good")
    |> State.set_object("taxi_condition", "taxi2", "good")
  end

  @doc """
  Creates an initial state with bad taxis for HTN acting error testing.
  """
  @spec create_bad_taxi_state() :: AriaEngine.state()
  def create_bad_taxi_state do
    create_state()
    |> State.set_object("loc", "alice", "home_a")
    |> State.set_object("loc", "bob", "home_b")
    |> State.set_object("loc", "taxi1", "park")
    |> State.set_object("loc", "taxi2", "station")
    |> State.set_object("cash", "alice", 20)
    |> State.set_object("cash", "bob", 15)
    |> State.set_object("owe", "alice", 0)
    |> State.set_object("owe", "bob", 0)
    |> State.set_object("taxi_condition", "taxi1", "bad")
    |> State.set_object("taxi_condition", "taxi2", "bad")
  end

  # Private helper functions for backtracking domain

  defp putv_action(state, [flag_val]) do
    State.set_object(state, "flag", "system", flag_val)
  end

  defp getv_action(state, [flag_val]) do
    current_flag = State.get_object(state, "flag", "system")
    if current_flag == flag_val do
      state
    else
      nil
    end
  end

  defp m_err(_state, ["put_it"]) do
    [{"putv", 0}, {"getv", 1}]
  end

  defp m0(_state, ["put_it"]) do
    [{"putv", 0}, {"getv", 0}]
  end

  defp m1(_state, ["put_it"]) do
    [{"putv", 1}, {"getv", 1}]
  end

  defp m_need0(_state, task) when task in [["need0"], ["need01"], ["need10"]] do
    [{"getv", 0}]
  end

  defp m_need1(_state, task) when task in [["need1"], ["need01"], ["need10"]] do
    [{"getv", 1}]
  end

  # Private helper functions for simple HGN domain

  defp walk_action(state, [person, from, to]) do
    current_loc = State.get_object(state, "loc", person)
    if current_loc == from do
      State.set_object(state, "loc", person, to)
    else
      false
    end
  end

  defp call_taxi_action(state, [person, taxi]) do
    person_loc = State.get_object(state, "loc", person)
    State.set_object(state, "loc", taxi, person_loc)
  end

  defp ride_taxi_action(state, [person, taxi, to]) do
    person_loc = State.get_object(state, "loc", person)
    taxi_loc = State.get_object(state, "loc", taxi)
    if person_loc == taxi_loc do
      state
      |> State.set_object("loc", person, to)
      |> State.set_object("loc", taxi, to)
    else
      false
    end
  end

  defp pay_driver_action(state, [person, taxi]) do
    fare = taxi_fare(State.get_object(state, "loc", person), State.get_object(state, "loc", taxi))
    cash = State.get_object(state, "cash", person)
    if cash >= fare do
      State.set_object(state, "cash", person, cash - fare)
    else
      false
    end
  end

  defp travel_by_foot(state, [["loc", person, destination]]) do
    current_loc = State.get_object(state, "loc", person)
    distance = distance_between(current_loc, destination)
    if distance <= 2 do
      [{"walk", person, current_loc, destination}]
    else
      false
    end
  end

  defp travel_by_taxi(state, [["loc", person, destination]]) do
    current_loc = State.get_object(state, "loc", person)
    taxis = ["taxi1", "taxi2"]

    case Enum.find(taxis, fn taxi ->
      cash = State.get_object(state, "cash", person)
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
    current_loc = State.get_object(state, "loc", person)
    if current_loc == from do
      State.set_object(state, "loc", person, to)
    else
      false
    end
  end

  defp call_taxi_action_htn(state, [person, taxi]) do
    person_loc = State.get_object(state, "loc", person)
    State.set_object(state, "loc", taxi, person_loc)
  end

  defp ride_taxi_action_htn(state, [person, taxi, to]) do
    person_loc = State.get_object(state, "loc", person)
    taxi_loc = State.get_object(state, "loc", taxi)
    if person_loc == taxi_loc do
      state
      |> State.set_object("loc", person, to)
      |> State.set_object("loc", taxi, to)
    else
      false
    end
  end

  defp pay_driver_action_htn(state, [person, taxi]) do
    fare = taxi_fare(State.get_object(state, "loc", person), State.get_object(state, "loc", taxi))
    cash = State.get_object(state, "cash", person)
    if cash >= fare do
      State.set_object(state, "cash", person, cash - fare)
    else
      false
    end
  end

  defp walk_command_htn(state, [person, from, to]) do
    current_loc = State.get_object(state, "loc", person)
    if current_loc == from do
      State.set_object(state, "loc", person, to)
    else
      false
    end
  end

  defp call_taxi_command_htn(state, [person, taxi]) do
    taxi_condition = State.get_object(state, "taxi_condition", taxi)
    if taxi_condition == "good" do
      person_loc = State.get_object(state, "loc", person)
      State.set_object(state, "loc", taxi, person_loc)
    else
      false
    end
  end

  defp ride_taxi_command_htn(state, [person, taxi, to]) do
    taxi_condition = State.get_object(state, "taxi_condition", taxi)
    if taxi_condition == "good" do
      person_loc = State.get_object(state, "loc", person)
      taxi_loc = State.get_object(state, "loc", taxi)
      if person_loc == taxi_loc do
        state
        |> State.set_object("loc", person, to)
        |> State.set_object("loc", taxi, to)
      else
        false
      end
    else
      false
    end
  end

  defp pay_driver_command_htn(state, [person, taxi]) do
    taxi_condition = State.get_object(state, "taxi_condition", taxi)
    if taxi_condition == "good" do
      fare = taxi_fare(State.get_object(state, "loc", person), State.get_object(state, "loc", taxi))
      cash = State.get_object(state, "cash", person)
      if cash >= fare do
        State.set_object(state, "cash", person, cash - fare)
      else
        false
      end
    else
      false
    end
  end

  defp do_nothing_htn(_state, ["travel", _person, _destination]), do: []

  defp travel_by_foot_htn(state, ["travel", person, destination]) do
    current_loc = State.get_object(state, "loc", person)
    distance = distance_between(current_loc, destination)
    if distance <= 2 do
      [{"walk", person, current_loc, destination}]
    else
      false
    end
  end

  defp travel_by_taxi_htn(state, ["travel", person, destination]) do
    current_loc = State.get_object(state, "loc", person)
    taxis = ["taxi1", "taxi2"]

    case Enum.find(taxis, fn taxi ->
      cash = State.get_object(state, "cash", person)
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
