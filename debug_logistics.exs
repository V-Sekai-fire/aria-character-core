#!/usr/bin/env elixir

Mix.install([
  {:aria_engine, path: "./apps/aria_engine"}  
])

alias AriaEngine.{Domain, TestDomains}

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

IO.puts("=== Domain Info ===")
summary = AriaEngine.domain_summary(domain)
IO.inspect(summary)

IO.puts("\n=== Initial State ===")
IO.puts("truck1 is at: #{AriaEngine.get_fact(state, "truck_at", "truck1")}")
IO.puts("location2 is in city: #{AriaEngine.get_fact(state, "in_city", "location2")}")
IO.puts("location3 is in city: #{AriaEngine.get_fact(state, "in_city", "location3")}")

IO.puts("\n=== Testing unigoal method directly ===")
method_result = AriaEngine.LogisticsMethods.truck_at(state, ["truck1", "location2"])
IO.puts("truck_at method result: #{inspect(method_result)}")

IO.puts("\n=== Planning with verbose output ===")
goals = [{"truck_at", "truck1", "location2"}]
result = AriaEngine.plan(domain, state, goals, verbose: 3)
IO.puts("Planning result: #{inspect(result)}")
