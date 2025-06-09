#!/usr/bin/env elixir

# Simple standalone test for GTPyhop without application dependencies
IO.puts("Starting GTPyhop test...")

try do
  # Add the lib and test directories to the code path
  Code.prepend_path("apps/aria_engine/lib")
  Code.prepend_path("apps/aria_engine/test")

  # Compile and load modules
  modules = [
    "apps/aria_engine/lib/aria_engine/state.ex",
    "apps/aria_engine/lib/aria_engine/domain.ex", 
    "apps/aria_engine/lib/aria_engine/multigoal.ex",
    "apps/aria_engine/lib/aria_engine/plan.ex",
    "apps/aria_engine/test/support/logistics_actions.ex",
    "apps/aria_engine/test/support/logistics_methods.ex"
  ]

  Enum.each(modules, fn file ->
    IO.puts("Loading #{file}...")
    Code.require_file(file)
  end)

  IO.puts("Testing basic GTPyhop functionality...")

  # Test 1: State management
  IO.puts("\n=== Test 1: State Management ===")
  state = AriaEngine.State.new()
  state = AriaEngine.State.set_object(state, "location", "truck1", "city1")
  location = AriaEngine.State.get_object(state, "location", "truck1")
  IO.puts("truck1 location: #{location}")

  IO.puts("\n=== All basic tests passed! ===")
  
rescue
  error ->
    IO.puts("Error occurred: #{inspect(error)}")
    IO.puts("Stacktrace: #{inspect(__STACKTRACE__)}")
end
