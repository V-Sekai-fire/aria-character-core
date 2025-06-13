# Test script to debug truck_at planning issue
ExUnit.start()

# Import the relevant modules
import AriaEngine
alias AriaEngine.{TestDomains, LogisticsMethods}

IO.puts("Starting debug script...")

# Create the same setup as the test
domain = TestDomains.build_logistics_domain()

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

IO.puts("=== Debugging truck_at method ===")
IO.puts("Current truck1 location: #{AriaEngine.State.get_object(state, "truck_at", "truck1")}")
IO.puts("Target location: location2")
IO.puts("Current city of truck1: #{AriaEngine.State.get_object(state, "in_city", AriaEngine.State.get_object(state, "truck_at", "truck1"))}")
IO.puts("Target city: #{AriaEngine.State.get_object(state, "in_city", "location2")}")

# Test the method directly
result = LogisticsMethods.truck_at(state, ["truck1", "location2"])
IO.puts("Method result: #{inspect(result)}")

# Test basic planning
goals = [{"truck_at", "truck1", "location2"}]
IO.puts("\n=== Testing planning ===")

case AriaEngine.plan(domain, state, goals, verbose: 3) do
  {:ok, plan} ->
    IO.puts("Planning succeeded: #{inspect(plan)}")
  {:error, reason} ->
    IO.puts("Planning failed: #{reason}")
end
