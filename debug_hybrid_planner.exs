#!/usr/bin/env elixir

# Debug script to understand what the hybrid planner is returning

defmodule HybridPlannerDebug do
  alias HybridPlanner.HybridCoordinatorV2
  alias StateV2
  alias Domain
  
  def debug_simple_planning do
    IO.puts("=== Debugging Hybrid Planner Output ===")
    
    # Create a simple domain with one activity
    domain = Domain.new("test_domain")
    |> Domain.add_action(:execute_A, fn state, _args ->
      existing_triples = StateV2.to_triples(state)
      new_triples = [{"A", "status", "completed"}]
      StateV2.from_triples(existing_triples ++ new_triples)
    end, %{duration: 1})
    |> Domain.add_task_methods("schedule_all", [
      {"simple_method", &simple_method/2}
    ])
    
    # Create initial state
    state = StateV2.from_triples([
      {"A", "type", "activity"},
      {"A", "status", "pending"}
    ])
    
    # Create goals
    goals = [{"schedule_all", [%{"id" => "A", "duration" => 1}]}]
    
    IO.puts("Domain: #{inspect(domain)}")
    IO.puts("State: #{inspect(state)}")
    IO.puts("Goals: #{inspect(goals)}")
    
    # Create coordinator and plan
    coordinator = HybridCoordinatorV2.new_default()
    IO.puts("Coordinator: #{inspect(coordinator)}")
    
    case HybridCoordinatorV2.plan(coordinator, domain, state, goals) do
      {:ok, plan} ->
        IO.puts("✅ Planning succeeded!")
        IO.puts("Plan structure: #{inspect(plan, pretty: true, limit: :infinity)}")
        
        # Check for solution tree
        case Map.get(plan, :solution_tree) do
          nil ->
            IO.puts("❌ No solution_tree in plan")
          solution_tree ->
            IO.puts("✅ Solution tree found: #{inspect(solution_tree)}")
        end
        
        # Check for actions
        case Map.get(plan, :actions) do
          nil ->
            IO.puts("❌ No actions in plan")
          actions ->
            IO.puts("✅ Actions found: #{inspect(actions)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Planning failed: #{reason}")
    end
  end
  
  defp simple_method(_state, activities) when is_list(activities) do
    IO.puts("Simple method called with activities: #{inspect(activities)}")
    # Return subtasks for each activity
    subtasks = Enum.map(activities, fn activity ->
      activity_id = Map.get(activity, "id")
      {String.to_atom("execute_#{activity_id}"), []}
    end)
    IO.puts("Returning subtasks: #{inspect(subtasks)}")
    subtasks
  end
  defp simple_method(_state, _args) do
    IO.puts("Simple method called with non-list args")
    false
  end
end

HybridPlannerDebug.debug_simple_planning()
