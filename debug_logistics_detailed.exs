defmodule LogisticsDebugTest do
  alias AriaEngine.{Domain, TestDomains, LogisticsMethods}
  
  def debug_logistics_step_by_step do
    # Create the logistics domain
    domain = TestDomains.build_logistics_domain()
    
    # Set up the initial state from the C++ test
    state = AriaEngine.create_state()
    |> AriaEngine.set_fact("trucks", "list", ["truck1", "truck6"])
    |> AriaEngine.set_fact("locations", "list", ["location1", "location2", "location3"])
    |> AriaEngine.set_fact("truck_at", "truck1", "location3")
    |> AriaEngine.set_fact("in_city", "location2", "city1")
    |> AriaEngine.set_fact("in_city", "location3", "city1")
    
    IO.puts("=== Step 1: Check domain setup ===")
    summary = AriaEngine.domain_summary(domain)
    IO.puts("Domain: #{summary.name}")
    IO.puts("Unigoal methods: #{inspect(summary.unigoal_methods)}")
    
    IO.puts("\n=== Step 2: Check method directly ===")
    truck_at_methods = Domain.get_unigoal_methods(domain, "truck_at")
    IO.puts("truck_at methods count: #{length(truck_at_methods)}")
    
    if length(truck_at_methods) > 0 do
      [method | _] = truck_at_methods
      result = method.(state, ["truck1", "location2"])
      IO.puts("Method result: #{inspect(result)}")
    end
    
    IO.puts("\n=== Step 3: Check goal satisfaction ===")
    current_location = AriaEngine.get_fact(state, "truck_at", "truck1")
    target_location = "location2"
    IO.puts("Current location: #{current_location}")
    IO.puts("Target location: #{target_location}")
    IO.puts("Goal satisfied: #{current_location == target_location}")
    
    IO.puts("\n=== Step 4: Try planning with maximum verbosity ===")
    goals = [{"truck_at", "truck1", "location2"}]
    result = AriaEngine.plan(domain, state, goals, verbose: 3)
    IO.puts("Planning result: #{inspect(result)}")
    
    IO.puts("\n=== Step 5: Check action execution directly ===")
    action_result = Domain.execute_action(domain, state, :drive_truck, ["truck1", "location2"])
    case action_result do
      {:ok, new_state} ->
        new_location = AriaEngine.get_fact(new_state, "truck_at", "truck1")
        IO.puts("Direct action execution succeeded - new location: #{new_location}")
      false ->
        IO.puts("Direct action execution failed")
    end
  end
end

LogisticsDebugTest.debug_logistics_step_by_step()
