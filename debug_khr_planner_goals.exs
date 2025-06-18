# Debug script for KHR Interactivity planner goal processing pipeline
# Usage: mix run debug_khr_planner_goals.exs

# Add test support path to load GLTFSceneMock
Code.append_path("test/aria_engine/test/support")

defmodule KHRPlannerGoalsDebug do
  alias StateV2
  alias NodeLibrary.KHRInteractivityDomain
  alias NodeLibrary.KHRInteractivity.Support.GLTFSceneMock
  alias Domain.Core
  alias Planner

  def run_all_tests do
    IO.puts("=== KHR Planner Goal Processing Pipeline Debug ===\n")
    
    test_domain_registration()
    test_goal_format_variations()
    test_method_resolution_tracing()
    test_direct_task_method_calls()
    test_planner_internals()
  end

  def test_domain_registration do
    IO.puts("=== Testing Domain Registration ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    # Count registered actions
    action_count = domain.actions |> Map.keys() |> length()
    IO.puts("Total actions registered: #{action_count}")
    
    # List KHR actions
    khr_actions = domain.actions
    |> Map.keys()
    |> Enum.filter(fn name -> String.starts_with?(Atom.to_string(name), "khr_") end)
    |> Enum.sort()
    
    IO.puts("KHR actions (#{length(khr_actions)}):")
    Enum.each(khr_actions, fn action -> IO.puts("  - #{action}") end)
    
    # Count registered task methods
    task_method_count = domain.task_methods |> Map.keys() |> length()
    IO.puts("\nTotal task methods registered: #{task_method_count}")
    
    # List task methods
    task_methods = domain.task_methods |> Map.keys() |> Enum.sort()
    IO.puts("Task methods:")
    Enum.each(task_methods, fn method -> IO.puts("  - #{method}") end)
    
    # Check specific math methods
    IO.puts("\nChecking specific math methods:")
    math_methods = ["math/pi", "math/e", "math/add", "math/mul", "math/div"]
    Enum.each(math_methods, fn method ->
      case Map.get(domain.task_methods, method) do
        nil -> IO.puts("  ❌ #{method} - NOT FOUND")
        methods_list -> IO.puts("  ✅ #{method} - #{length(methods_list)} method(s)")
      end
    end)
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
    domain
  end

  def test_goal_format_variations do
    IO.puts("=== Testing Goal Format Variations ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    
    # Test different goal formats for math/pi
    goal_formats = [
      # Current test format
      [{"math/pi", [1]}],
      
      # Alternative formats to try
      [{"math/pi", 1}],
      [{:math_pi, [1]}],
      [{:khr_math_pi, [1]}],
      [{"math/pi", []}],
      
      # With explicit parameters
      [{"math/pi", [1, :no_params]}],
      
      # Tuple format
      [{"math/pi", {1}}],
    ]
    
    Enum.with_index(goal_formats, 1) |> Enum.each(fn {goals, index} ->
      IO.puts("Format #{index}: #{inspect(goals)}")
      
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          IO.puts("  ✅ SUCCESS - Plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("  ❌ FAILED - Reason: #{inspect(reason)}")
      end
    end)
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end

  def test_method_resolution_tracing do
    IO.puts("=== Testing Method Resolution Tracing ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    
    # Test goal that should work
    goals = [{"math/pi", [1]}]
    
    IO.puts("Testing goal: #{inspect(goals)}")
    IO.puts("Available task methods for 'math/pi':")
    
    case Map.get(domain.task_methods, "math/pi") do
      nil -> 
        IO.puts("  ❌ No task methods found for 'math/pi'")
      methods_list ->
        IO.puts("  ✅ Found #{length(methods_list)} method(s):")
        Enum.with_index(methods_list, 1) |> Enum.each(fn {method, index} ->
          IO.puts("    #{index}. #{inspect(method)}")
        end)
    end
    
    # Try to manually call the task method
    IO.puts("\nTesting direct task method call:")
    case Map.get(domain.task_methods, "math/pi") do
      nil -> 
        IO.puts("  ❌ Cannot test - no methods found")
      [method_func | _] ->
        try do
          result = method_func.(state, [1])
          IO.puts("  ✅ Direct call succeeded: #{inspect(result)}")
        rescue
          error ->
            IO.puts("  ❌ Direct call failed: #{inspect(error)}")
        end
    end
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end

  def test_direct_task_method_calls do
    IO.puts("=== Testing Direct Task Method Calls ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    |> GLTFSceneMock.setup_state_with_scene()
    
    # Test various task methods directly
    test_cases = [
      {"math/pi", [1]},
      {"math/e", [0]},
      {"math/add", [25, 2.1, 3.5]},
      {"math/mul", [28, 3.0, 4.0]},
      {"math/div", [30, 5.0, 0.0]}
    ]
    
    Enum.each(test_cases, fn {method_name, params} ->
      IO.puts("Testing #{method_name} with params #{inspect(params)}:")
      
      case Map.get(domain.task_methods, method_name) do
        nil ->
          IO.puts("  ❌ Method not found")
        [method_func | _] ->
          try do
            result = method_func.(state, params)
            IO.puts("  ✅ Success: #{inspect(result)}")
            
            # Check if result follows expected format
            case result do
              [{:ok, new_state, actions}] ->
                IO.puts("    - Format: Correct HTN task method format")
                IO.puts("    - Actions: #{inspect(actions)}")
                
                # Check if state was updated
                [node_id | _] = params
                if is_integer(node_id) do
                  value = StateV2.get_fact(new_state, node_id, "value")
                  IO.puts("    - Node #{node_id} value: #{inspect(value)}")
                end
              _ ->
                IO.puts("    - Format: Unexpected format")
            end
          rescue
            error ->
              IO.puts("  ❌ Error: #{inspect(error)}")
          end
      end
    end)
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end

  def test_planner_internals do
    IO.puts("=== Testing Planner Internals ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    |> GLTFSceneMock.setup_state_with_scene()
    
    # Test with verbose planning to see internal steps
    goals = [{"math/pi", [1]}]
    
    IO.puts("Testing planner with verbose output:")
    IO.puts("Goals: #{inspect(goals)}")
    
    # Check if Planner module has verbose option
    try do
      case Planner.plan(domain, state, goals, verbose: 3) do
        {:ok, plan} ->
          IO.puts("✅ Verbose planning succeeded")
          IO.puts("Plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("❌ Verbose planning failed: #{inspect(reason)}")
      end
    rescue
      error ->
      IO.puts("❌ Verbose planning not supported or error: #{inspect(error)}")
      
      # Try regular planning
      case Planner.plan(domain, state, goals) do
        {:ok, plan} ->
          IO.puts("✅ Regular planning succeeded")
          IO.puts("Plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("❌ Regular planning failed: #{inspect(reason)}")
      end
    end
    
    # Test goal parsing
    IO.puts("\nTesting goal parsing:")
    goal = {"math/pi", [1]}
    {task_name, task_params} = goal
    IO.puts("Task name: #{inspect(task_name)}")
    IO.puts("Task params: #{inspect(task_params)}")
    IO.puts("Task name type: #{inspect(task_name.__struct__ || :not_struct)}")
    
    IO.puts("\n" <> String.duplicate("=", 50) <> "\n")
  end
end

KHRPlannerGoalsDebug.run_all_tests()
