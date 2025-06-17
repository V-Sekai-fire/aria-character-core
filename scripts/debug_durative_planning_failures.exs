# Debug script for tracing durative action planning failures
# Usage: mix run scripts/debug_durative_planning_failures.exs

defmodule DurativePlanningDebug do
  alias AriaEngine.{Domain, StateV2, Planner}
  
  def debug_categorical_fluent_failure do
    IO.puts("=== Debugging Categorical Fluent Planning Failure ===")
    
    # Recreate the test scenario that's failing
    domain = create_robot_health_domain()
    initial_state = StateV2.new()
    |> StateV2.set_fact("robot", "health_status", :wounded)
    |> StateV2.set_fact("robot", "location", "clinic")
    
    goals = [{"health_status", "robot", :healthy}]
    
    IO.puts("Initial state:")
    IO.inspect(initial_state.data, pretty: true)
    
    IO.puts("\nGoals:")
    IO.inspect(goals, pretty: true)
    
    IO.puts("\nDomain methods:")
    IO.inspect(Domain.get_unigoal_methods(domain, "health_status"), pretty: true)
    
    # Try planning with maximum verbosity
    IO.puts("\n=== Starting Planning Process ===")
    result = Planner.plan(domain, initial_state, goals, verbose: 3)
    
    case result do
      {:ok, plan} ->
        IO.puts("SUCCESS: Plan found!")
        IO.inspect(plan, pretty: true)
      {:error, reason} ->
        IO.puts("FAILURE: #{reason}")
        debug_domain_methods(domain, initial_state, goals)
    end
  end
  
  defp create_robot_health_domain do
    domain = Domain.new()
    
    # Add heal action
    heal_action = fn state, [subject] ->
      IO.puts("DEBUG: heal_action called with subject: #{inspect(subject)}")
      IO.puts("DEBUG: Current state: #{inspect(state.data)}")
      
      # Check if robot is at clinic (entity-first format)
      location = StateV2.get_fact(state, subject, "location")
      IO.puts("DEBUG: Robot location: #{inspect(location)}")
      
      if location == "clinic" do
        new_state = StateV2.set_fact(state, subject, "health_status", :healthy)
        IO.puts("DEBUG: heal_action succeeded, new state: #{inspect(new_state.data)}")
        new_state
      else
        IO.puts("DEBUG: heal_action failed - robot not at clinic")
        false
      end
    end
    
    # Add the heal action to domain
    domain = Domain.add_action(domain, :heal, heal_action)
    
    # Add goal method for health_status
    heal_method = fn state, [subject, target_health] ->
      IO.puts("DEBUG: heal_method called with subject: #{inspect(subject)}, target: #{inspect(target_health)}")
      IO.puts("DEBUG: Method state: #{inspect(state.data)}")
      
      current_health = StateV2.get_fact(state, subject, "health_status")
      IO.puts("DEBUG: Current health: #{inspect(current_health)}, Target: #{inspect(target_health)}")
      
      if current_health == target_health do
        IO.puts("DEBUG: Already at target health")
        []  # Already satisfied
      else
        IO.puts("DEBUG: Need to heal - returning heal action")
        [{"heal", [subject]}]
      end
    end
    
    # Add unigoal method
    domain = Domain.add_unigoal_method(domain, "health_status", "heal_method", heal_method)
    
    domain
  end
  
  defp debug_domain_methods(domain, state, goals) do
    IO.puts("\n=== Debugging Domain Methods ===")
    
    Enum.each(goals, fn {predicate, subject, target_value} ->
      IO.puts("\nDebugging goal: #{predicate} #{subject} #{target_value}")
      
      # Check current value
      current_value = StateV2.get_fact(state, subject, predicate)
      IO.puts("Current value: #{inspect(current_value)}")
      IO.puts("Target value: #{inspect(target_value)}")
      IO.puts("Goal satisfied?: #{current_value == target_value}")
      
      # Check available methods
      methods = Domain.get_unigoal_methods(domain, predicate)
      IO.puts("Available methods: #{length(methods)}")
      
      Enum.each(methods, fn {method_name, method_fn} ->
        IO.puts("\nTesting method: #{method_name}")
        
        try do
          result = method_fn.(state, [subject, target_value])
          IO.puts("Method result: #{inspect(result)}")
          
          case result do
            false ->
              IO.puts("❌ Method failed preconditions")
            tasks when is_list(tasks) ->
              IO.puts("✅ Method succeeded with #{length(tasks)} tasks")
              
              # Test each task
              Enum.each(tasks, fn {action_name, args} ->
                IO.puts("  Testing action: #{action_name}(#{inspect(args)})")
                action_atom = String.to_atom(action_name)
                
                case Domain.execute_action(domain, state, action_atom, args) do
                  {:ok, new_state} ->
                    IO.puts("    ✅ Action succeeded")
                    IO.puts("    New state: #{inspect(new_state.data)}")
                  false ->
                    IO.puts("    ❌ Action failed")
                end
              end)
            other ->
              IO.puts("⚠️ Unexpected method result: #{inspect(other)}")
          end
        rescue
          e ->
            IO.puts("💥 Method crashed: #{inspect(e)}")
        end
      end)
    end)
  end
  
  def test_state_format_compatibility do
    IO.puts("=== Testing StateV2 Format Compatibility ===")
    
    state = StateV2.new()
    |> StateV2.set_fact("robot", "health_status", :wounded)
    |> StateV2.set_fact("robot", "location", "clinic")
    
    IO.puts("State data: #{inspect(state.data)}")
    
    # Test entity-first access
    health = StateV2.get_fact(state, "robot", "health_status")
    location = StateV2.get_fact(state, "robot", "location")
    
    IO.puts("Health (entity-first): #{inspect(health)}")
    IO.puts("Location (entity-first): #{inspect(location)}")
    
    # Test goal format
    goal = {"health_status", "robot", :healthy}
    {predicate, subject, target} = goal
    
    current = StateV2.get_fact(state, subject, predicate)
    IO.puts("Goal check: #{predicate} #{subject} #{target}")
    IO.puts("Current: #{inspect(current)}, Target: #{inspect(target)}")
    IO.puts("Satisfied?: #{current == target}")
  end
end

# Run the debug
DurativePlanningDebug.test_state_format_compatibility()
IO.puts("\n" <> String.duplicate("=", 60) <> "\n")
DurativePlanningDebug.debug_categorical_fluent_failure()
