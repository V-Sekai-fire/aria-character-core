# Test script to verify unigoal method lookup works correctly
# Run with: elixir -S mix run test_unigoal_fix.exs

IO.puts("=== Testing Unigoal Method Fix ===\n")

# Create a domain with the fixed registration
domain = AriaBlocksWorld.Domain.create()

# Create a test state
state = AriaCore.new_state()
|> AriaCore.set_fact("pos", "a", "table")
|> AriaCore.set_fact("pos", "b", "table")
|> AriaCore.set_fact("clear", "a", true)
|> AriaCore.set_fact("clear", "b", true)

IO.puts("Created test state with blocks a and b on table")

# Test goal that should trigger unigoal method lookup
goal = {"pos", "a", "b"}  # Move block a onto block b
IO.puts("Testing goal: #{inspect(goal)}")

# Test the hybrid planner's goal expansion using the public API
try do
  result = AriaHybridPlanner.plan(domain, state, [goal], verbose: 1)
  IO.puts("✓ Planning succeeded: #{inspect(result)}")
rescue
  error ->
    IO.puts("✗ Planning failed: #{inspect(error)}")
    IO.puts("Error message: #{Exception.message(error)}")
end

# Test direct unigoal method lookup
IO.puts("\n--- Direct Method Lookup Test ---")
pos_methods = AriaCore.get_unigoal_methods_from_domain(domain, "pos")
IO.puts("Methods for 'pos' predicate: #{inspect(pos_methods)}")

clear_methods = AriaCore.get_unigoal_methods_from_domain(domain, "clear")
IO.puts("Methods for 'clear' predicate: #{inspect(clear_methods)}")

# Test if the method can be called directly
if Map.has_key?(pos_methods, :achieve_position) do
  IO.puts("\n--- Direct Method Call Test ---")
  method_fn = pos_methods[:achieve_position]

  try do
    result = method_fn.(state, {"a", "b"})
    IO.puts("✓ Direct method call succeeded: #{inspect(result)}")
  rescue
    error ->
      IO.puts("✗ Direct method call failed: #{inspect(error)}")
  end
else
  IO.puts("✗ achieve_position method not found in pos methods")
end

IO.puts("\n=== Test Complete ===")
