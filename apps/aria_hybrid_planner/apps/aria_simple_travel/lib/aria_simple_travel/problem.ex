# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravel.Problem do
  @moduledoc """
  Problem definitions and initial states for the Simple Travel domain.

  This module provides the initial state setup and example problems
  based on the IPyHOP Simple Travel domain.
  """

  @doc """
  Get the initial state for the simple travel domain.

  The state includes:
  - People locations (alice, bob)
  - Taxi location
  - Cash amounts for each person
  - Debt amounts (initially 0)
  - Rigid facts (distances, types)
  """
  def get_initial_state do
    %{
      # Dynamic state - changes during planning
      loc: %{
        "alice" => "home_a",
        "bob" => "home_b",
        "taxi1" => "taxi_lot"
      },
      cash: %{
        "alice" => 20,
        "bob" => 15
      },
      owe: %{
        "alice" => 0,
        "bob" => 0
      },
      # Rigid state - never changes
      rigid: %{
        dist: %{
          {"home_a", "park"} => 8,
          {"park", "home_a"} => 8,
          {"home_b", "park"} => 2,
          {"park", "home_b"} => 2,
          {"home_a", "home_b"} => 6,
          {"home_b", "home_a"} => 6,
          {"taxi_lot", "home_a"} => 3,
          {"home_a", "taxi_lot"} => 3,
          {"taxi_lot", "home_b"} => 4,
          {"home_b", "taxi_lot"} => 4,
          {"taxi_lot", "park"} => 5,
          {"park", "taxi_lot"} => 5
        },
        types: %{
          person: ["alice", "bob"],
          location: ["home_a", "home_b", "park", "taxi_lot"],
          taxi: ["taxi1"]
        }
      }
    }
  end

  @doc """
  Get predefined example problems for testing and demonstration.
  """
  def get_example_problems do
    %{
      # Single person to single location
      goal1: [{"loc", "alice", "park"}],

      # Multiple people to same location
      goal2: [{"loc", "alice", "park"}, {"loc", "bob", "park"}],

      # Bob can walk (distance 2), Alice needs taxi (distance 8)
      mixed_transport: [{"loc", "alice", "park"}, {"loc", "bob", "park"}],

      # Test resource constraints
      expensive_trip: [{"loc", "alice", "home_b"}, {"loc", "bob", "home_a"}]
    }
  end

  @doc """
  Get expected solutions for the example problems.

  These are the expected action sequences that should be generated
  by the planner for each example problem.
  """
  def get_expected_solutions do
    %{
      # Alice takes taxi to park (distance 8, costs 5.5, has 20)
      goal1: [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"}
      ],

      # Alice takes taxi, Bob walks (distance 2)
      goal2: [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"},
        {"walk", "bob", "home_b", "park"}
      ],

      # Same as goal2 - mixed transportation based on distance/cost
      mixed_transport: [
        {"call_taxi", "alice", "home_a"},
        {"ride_taxi", "alice", "park"},
        {"pay_driver", "alice", "park"},
        {"walk", "bob", "home_b", "park"}
      ]
    }
  end
end
