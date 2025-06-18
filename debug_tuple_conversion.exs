# Debug tuple conversion issue
# Usage: mix run debug_tuple_conversion.exs

Code.append_path("test/support")

defmodule TupleConversionDebug do
  alias StateV2
  alias NodeLibrary.KHRInteractivityDomain
  alias Domain.Core
  alias Plan
  alias GLTFSceneMock

  def test_tuple_processing do
    IO.puts("=== Testing Tuple Processing ===")
    
    domain = Core.new()
    |> KHRInteractivityDomain.register_complete_domain()
    
    state = StateV2.new()
    
    # Test the exact goal that's failing
    original_goal = {"math/pi", [1]}
    goals = [original_goal]
    
    IO.puts("Original goal: #{inspect(original_goal)}")
    IO.puts("Goals list: #{inspect(goals)}")
    
    # Test pattern matching directly
    IO.puts("\n--- Pattern Matching Test ---")
    case original_goal do
      {task_name, args} when is_binary(task_name) and is_list(args) ->
        IO.puts("✅ Matches TASK pattern: task_name=#{inspect(task_name)}, args=#{inspect(args)}")
      {task_name, args} when is_binary(task_name) ->
        IO.puts("✅ Matches TASK pattern (non-list): task_name=#{inspect(task_name)}, args=#{inspect(args)}")
      {subject, predicate, fact_value} ->
        IO.puts("❌ Matches GOAL pattern: subject=#{inspect(subject)}, predicate=#{inspect(predicate)}, fact_value=#{inspect(fact_value)}")
      _ ->
        IO.puts("❓ No pattern match")
    end
    
    # Test what happens when we create the solution tree
    IO.puts("\n--- Solution Tree Creation ---")
    solution_tree = Plan.Utils.create_initial_solution_tree(goals, state)
    root_node = solution_tree.nodes[solution_tree.root_id]
    IO.puts("Root node task: #{inspect(root_node.task)}")
    
    case root_node.task do
      {:root, todos} ->
        IO.puts("Root contains todos: #{inspect(todos)}")
        Enum.with_index(todos, 1) |> Enum.each(fn {todo, index} ->
          IO.puts("  Todo #{index}: #{inspect(todo)}")
          IO.puts("    Tuple size: #{tuple_size(todo)}")
          case todo do
            {a, b} -> IO.puts("    2-tuple: #{inspect(a)}, #{inspect(b)}")
            {a, b, c} -> IO.puts("    3-tuple: #{inspect(a)}, #{inspect(b)}, #{inspect(c)}")
            _ -> IO.puts("    Other type")
          end
        end)
      _ ->
        IO.puts("Unexpected root task format")
    end
    
    # Test planning with verbose output
    IO.puts("\n--- Planning with Verbose Output ---")
    try do
      case Plan.Core.plan(domain, state, goals, verbose: 3) do
        {:ok, plan} ->
          IO.puts("✅ Planning succeeded")
          IO.puts("Plan: #{inspect(plan)}")
        {:error, reason} ->
          IO.puts("❌ Planning failed: #{inspect(reason)}")
      end
    rescue
      error ->
        IO.puts("❌ Planning crashed: #{inspect(error)}")
        IO.puts("Stacktrace: #{inspect(__STACKTRACE__)}")
    end
  end
end

TupleConversionDebug.test_tuple_processing()
