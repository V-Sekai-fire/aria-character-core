IO.puts("Testing Elixir output")
IO.puts("Loading AriaEngine modules...")

# Try to create a basic state
state = %{data: %{}}
IO.puts("Basic state created: #{inspect(state)}")

# Try to load a module file
try do
  Code.compile_file("apps/aria_engine/lib/aria_engine/state.ex")
  IO.puts("State module compiled successfully")
rescue
  error ->
    IO.puts("Error compiling State module: #{inspect(error)}")
end
