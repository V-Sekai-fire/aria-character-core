#!/usr/bin/env elixir

# Add the lib directory to the path
Code.prepend_path("apps/aria_engine/lib")
Code.prepend_path("apps/aria_engine/test")

# Load the modules
[
  "apps/aria_engine/lib/aria_engine/state.ex",
  "apps/aria_engine/lib/aria_engine/domain.ex", 
  "apps/aria_engine/lib/aria_engine/multigoal.ex",
  "apps/aria_engine/lib/aria_engine/plan.ex",
  "apps/aria_engine/test/support/logistics_actions.ex",
  "apps/aria_engine/test/support/logistics_methods.ex",
  "apps/aria_engine/lib/aria_engine.ex",
  "apps/aria_engine/test/support/test_domains.ex"
]
|> Enum.each(&Code.compile_file/1)

# Create alias and logistics domain
alias AriaEngine.TestDomains

# Create logistics domain and test
domain = TestDomains.build_logistics_domain()

# Create initial state matching the C++ test
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

# Test domain summary
IO.puts("Domain summary:")
summary = AriaEngine.domain_summary(domain)
IO.inspect(summary)

# Test individual action execution
IO.puts("\nTesting action execution:")
try do
  result_state = AriaEngine.Domain.execute_action(domain, state, :drive_truck, ["truck1", "location1"])
  truck_location = AriaEngine.get_fact(result_state, "truck_at", "truck1")
  IO.puts("After drive_truck: truck1 at #{truck_location}")
rescue
  e -> IO.puts("Action execution failed: #{inspect(e)}")
end

# Test goal planning
IO.puts("\nTesting goal planning:")
goals = [{"truck_at", "truck1", "location2"}]

IO.puts("Planning for goals: #{inspect(goals)}")
case AriaEngine.plan(domain, state, goals, verbose: 2) do
  {:ok, plan} ->
    IO.puts("Plan found: #{inspect(plan)}")
  {:error, reason} ->
    IO.puts("Planning failed: #{reason}")
end
