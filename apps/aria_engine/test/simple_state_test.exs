#!/usr/bin/env elixir

# Very simple test
IO.puts("Testing basic Elixir functionality...")

# Test basic compilation
try do
  Code.prepend_path("apps/aria_engine/lib")
  
  # Try to compile just the state module first
  IO.puts("Compiling State module...")
  Code.compile_file("apps/aria_engine/lib/aria_engine/state.ex")
  IO.puts("State compiled successfully!")
  
  # Test creating a state
  state = AriaEngine.State.new()
  IO.puts("State created: #{inspect(state)}")
  
  # Set a simple fact
  state = AriaEngine.State.set_object(state, "test", "key", "value")
  value = AriaEngine.State.get_object(state, "test", "key")
  IO.puts("Set and retrieved value: #{value}")
  
  IO.puts("Basic test completed successfully!")
  
rescue
  error ->
    IO.puts("Error: #{inspect(error)}")
    IO.puts("Stacktrace: #{inspect(__STACKTRACE__)}")
end
