# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule LogisticsDebug do
  alias AriaEngine.{Domain, TestDomains, LogisticsMethods}
  
  def debug_logistics_planning do
    # Create the logistics domain
    domain = TestDomains.build_logistics_domain()
    
    # Set up the initial state
    state = AriaEngine.create_state()
    |> AriaEngine.set_fact("trucks", "list", ["truck1", "truck6"])
    |> AriaEngine.set_fact("locations", "list", ["location1", "location2", "location3"])
    |> AriaEngine.set_fact("truck_at", "truck1", "location3")
    |> AriaEngine.set_fact("in_city", "location2", "city1")
    |> AriaEngine.set_fact("in_city", "location3", "city1")
    
    IO.puts("=== Initial State ===")
    IO.puts("truck1 is at: #{AriaEngine.get_fact(state, "truck_at", "truck1")}")
    IO.puts("location2 is in city: #{AriaEngine.get_fact(state, "in_city", "location2")}")
    IO.puts("location3 is in city: #{AriaEngine.get_fact(state, "in_city", "location3")}")
    
    IO.puts("\n=== Testing unigoal method directly ===")
    method_result = LogisticsMethods.truck_at(state, ["truck1", "location2"])
    IO.puts("truck_at method result: #{inspect(method_result)}")
    
    IO.puts("\n=== Testing goal satisfaction ===")
    current_truck_at = AriaEngine.get_fact(state, "truck_at", "truck1")
    IO.puts("Current truck1 location: #{current_truck_at}")
    IO.puts("Target location: location2")
    IO.puts("Goal satisfied? #{current_truck_at == "location2"}")
    
    IO.puts("\n=== Planning with verbose output ===")
    goals = [{"truck_at", "truck1", "location2"}]
    
    # Try planning with verbose output
    case AriaEngine.plan(domain, state, goals, verbose: 2) do
      {:ok, plan} ->
        IO.puts("Planning succeeded: #{inspect(plan)}")
      {:error, reason} ->
        IO.puts("Planning failed: #{reason}")
    end
  end
end

LogisticsDebug.debug_logistics_planning()
