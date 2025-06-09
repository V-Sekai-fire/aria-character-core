#!/usr/bin/env elixir

# Simple standalone test for blocks world domain
IO.puts("Starting blocks world test...")

try do
  # Add the lib and test directories to the code path
  Code.prepend_path("apps/aria_engine/lib")
  Code.prepend_path("apps/aria_engine/test")

  # Compile and load modules in correct order
  modules = [
    "apps/aria_engine/lib/aria_engine/state.ex",
    "apps/aria_engine/lib/aria_engine/domain.ex", 
    "apps/aria_engine/lib/aria_engine/multigoal.ex",
    "apps/aria_engine/lib/aria_engine/plan.ex",
    "apps/aria_engine/test/support/blocks_world_actions.ex",
    "apps/aria_engine/test/support/blocks_world_methods.ex",
    "apps/aria_engine/lib/aria_engine.ex",
    "apps/aria_engine/test/support/test_domains.ex"
  ]

  Enum.each(modules, fn file ->
    IO.puts("Loading #{file}...")
    Code.compile_file(file)
  end)

  # Create alias for TestDomains module
  alias AriaEngine.TestDomains

  IO.puts("Testing blocks world functionality...")

  # Test 1: Create blocks world domain
  IO.puts("\n=== Test 1: Domain Creation ===")
  domain = TestDomains.build_blocks_world_domain()
  summary = AriaEngine.domain_summary(domain)
  IO.puts("Domain: #{summary.name}")
  IO.puts("Actions: #{inspect(summary.actions)}")
  IO.puts("Task methods: #{inspect(summary.task_methods)}")

  # Test 2: Basic action execution
  IO.puts("\n=== Test 2: Basic Actions ===")
  state = AriaEngine.create_state()
  |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
  |> AriaEngine.set_fact("on_table", "a", true)
  |> AriaEngine.set_fact("clear", "a", true)
  |> AriaEngine.set_fact("holding", "hand", nil)

  IO.puts("Initial state: A on table, clear, hand empty")

  # Test pickup
  pickup_state = AriaEngine.Domain.execute_action(domain, state, :pickup, ["a"])
  if pickup_state do
    holding = AriaEngine.get_fact(pickup_state, "holding", "hand")
    IO.puts("After pickup: holding #{holding}")
  else
    IO.puts("Pickup failed!")
  end

  # Test 3: Simple planning
  IO.puts("\n=== Test 3: Simple Planning ===")
  initial_state = AriaEngine.create_state()
  |> AriaEngine.set_fact("blocks", "list", ["a", "b"])
  |> AriaEngine.set_fact("on_table", "a", true)
  |> AriaEngine.set_fact("on_table", "b", true)
  |> AriaEngine.set_fact("clear", "a", true)
  |> AriaEngine.set_fact("clear", "b", true)
  |> AriaEngine.set_fact("holding", "hand", nil)

  IO.puts("Goal: stack A on B")
  goals = [{"on", "a", "b"}]

  case AriaEngine.plan(domain, initial_state, goals) do
    {:ok, plan} ->
      IO.puts("Plan found: #{inspect(plan)}")
    {:error, reason} ->
      IO.puts("Planning failed: #{reason}")
  end

  IO.puts("\n=== All tests completed! ===")
  
rescue
  error ->
    IO.puts("Error occurred: #{inspect(error)}")
    IO.puts("Stacktrace: #{inspect(__STACKTRACE__)}")
end
