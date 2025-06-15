# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.LogisticsTest do
  use ExUnit.Case
  doctest AriaEngine

  alias AriaEngine.{Domain, TestDomains}

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
      result_state_drive = Domain.execute_action(domain, initial_state, :drive, ["truck1", "cityA", "cityB"])
      case result_state_drive do
        {:ok, final_state_drive} ->
          assert AriaEngine.get_fact(final_state_drive, "at", "truck1") == "cityB"
        false ->
          flunk("Drive action failed")
      end

      # Test load action
      result_state_load = Domain.execute_action(domain, initial_state, :load, ["package1", "truck1"])
      case result_state_load do
        {:ok, final_state_load} ->
          assert AriaEngine.get_fact(final_state_load, "at", "package1") == "truck1"
        false ->
          flunk("Load action failed")
      end
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
      drive_truck_result = Domain.execute_action(domain, state, :drive_truck, ["truck1", "location1"])
      case drive_truck_result do
        {:ok, new_state_drive} ->
          assert AriaEngine.get_fact(new_state_drive, "truck_at", "truck1") == "location1"
        false ->
          flunk("drive_truck action failed")
      end
      
      # Test fly_plane 
      fly_plane_result = Domain.execute_action(domain, state, :fly_plane, ["plane2", "airport1"])
      case fly_plane_result do
        {:ok, new_state_fly} ->
          assert AriaEngine.get_fact(new_state_fly, "plane_at", "plane2") == "airport1"
        false -> 
          flunk("fly_plane action failed")
      end
      
      # Test load_truck
      # First move truck1 to location1 where package1 is
      drive_for_load_result = Domain.execute_action(domain, state, :drive_truck, ["truck1", "location1"])
      case drive_for_load_result do
        {:ok, state_after_first_drive} ->
          # Now load the truck
          load_result = Domain.execute_action(domain, state_after_first_drive, :load_truck, ["package1", "truck1"])
          case load_result do
            {:ok, state_after_load} ->
              assert AriaEngine.get_fact(state_after_load, "at", "package1") == "truck1"

              # Test unload_truck: requires state_after_load
              # Move the truck to location2
              drive_for_unload_result = Domain.execute_action(domain, state_after_load, :drive_truck, ["truck1", "location2"])
              case drive_for_unload_result do
                {:ok, state_after_second_drive} ->
                  unload_result = Domain.execute_action(domain, state_after_second_drive, :unload_truck, ["package1", "location2"])
                  case unload_result do
                    {:ok, state_after_unload} ->
                      assert AriaEngine.get_fact(state_after_unload, "at", "package1") == "location2"
                    false ->
                      flunk("unload_truck action failed")
                  end
                false ->
                  flunk("drive_truck (for unload) action failed")
              end
            false ->
              flunk("load_truck action failed")
          end
        false ->
          flunk("drive_truck (for load) action failed")
      end
    end
  end
end
