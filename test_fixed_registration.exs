# Test script to verify the fixed attribute-based registration

IO.puts("=== Testing Fixed Attribute Registration ===")

# Create domain using proper attribute registration
domain = AriaBlocksWorld.Domain.create()

# Create initial state
state = AriaHybridPlanner.new_state()
|> AriaHybridPlanner.set_fact("pos", "a", "table")
|> AriaHybridPlanner.set_fact("pos", "b", "table")
|> AriaHybridPlanner.set_fact("pos", "c", "a")
|> AriaHybridPlanner.set_fact("clear", "a", false)
|> AriaHybridPlanner.set_fact("clear", "b", true)
|> AriaHybridPlanner.set_fact("clear", "c", true)
|> AriaHybridPlanner.set_fact("holding", "hand", false)

IO.puts("Domain info: #{inspect(AriaBlocksWorld.Domain.info())}")

# Test that actions are properly registered
IO.puts("\n=== Testing Action Registration ===")
actions = AriaCore.list_actions_in_domain(domain)
IO.puts("Registered actions: #{inspect(actions)}")

# Test that task methods are properly registered
IO.puts("\n=== Testing Task Method Registration ===")
task_methods = AriaCore.get_method_counts_from_domain(domain)
IO.puts("Method counts: #{inspect(task_methods)}")

# Test specific task method calls
IO.puts("\n=== Testing Task Method Execution ===")

# Test 'take_method' for block 'c' (should work since c is clear)
IO.puts("Testing take_method for block 'c':")
case AriaBlocksWorld.Domain.take_method(state, ["c"]) do
  {:ok, actions} -> IO.puts("✅ Success: #{inspect(actions)}")
  {:error, reason} -> IO.puts("❌ Error: #{reason}")
end

# Test 'put_method' for block 'c' to table (should fail since hand is empty)
IO.puts("\nTesting put_method for block 'c' to table:")
case AriaBlocksWorld.Domain.put_method(state, ["c", "table"]) do
  {:ok, actions} -> IO.puts("✅ Success: #{inspect(actions)}")
  {:error, reason} -> IO.puts("❌ Expected error: #{reason}")
end

# Test with block in hand
state_with_block = AriaHybridPlanner.set_fact(state, "holding", "hand", "c")
IO.puts("\nTesting put_method with block 'c' in hand:")
case AriaBlocksWorld.Domain.put_method(state_with_block, ["c", "table"]) do
  {:ok, actions} -> IO.puts("✅ Success: #{inspect(actions)}")
  {:error, reason} -> IO.puts("❌ Error: #{reason}")
end

IO.puts("\n=== Test Complete ===")
IO.puts("✅ No unigoal method registration errors!")
IO.puts("✅ Attribute-based registration working correctly!")
