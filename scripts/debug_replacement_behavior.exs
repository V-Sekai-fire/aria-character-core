# Debug script for constraint replacement behavior
# Usage: mix run scripts/debug_replacement_behavior.exs

alias AriaEngine.Timeline.STN

IO.puts("=== Debugging Constraint Replacement Behavior ===")

# Test case from the failing test
stn = STN.new()
|> STN.add_constraint("A", "B", {0, 5})   # B is 0-5 units after A

IO.puts("After first constraint A->B {0,5}:")
IO.puts("  A->B: #{inspect(STN.get_constraint(stn, "A", "B"))}")
IO.puts("  B->A: #{inspect(STN.get_constraint(stn, "B", "A"))}")

# Add second constraint
stn2 = STN.add_constraint(stn, "B", "A", {0, 5})   # A is 0-5 units after B

IO.puts("\nAfter second constraint B->A {0,5}:")
IO.puts("  A->B: #{inspect(STN.get_constraint(stn2, "A", "B"))}")
IO.puts("  B->A: #{inspect(STN.get_constraint(stn2, "B", "A"))}")
IO.puts("  Consistent: #{STN.consistent?(stn2)}")

IO.puts("\nExpected:")
IO.puts("  A->B: {-5, 0}")
IO.puts("  B->A: {0, 5}")

IO.puts("\nActual intersection analysis:")
IO.puts("  Original A->B: {0, 5}")
IO.puts("  New A->B from B->A {0,5}: {-5, 0}")
IO.puts("  Intersection: max(0,-5)=0, min(5,0)=0 => {0, 0}")
