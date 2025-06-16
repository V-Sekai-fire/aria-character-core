---
applyTo: "**"
textId: "INST-031"
---

## Debug scripts for complex algorithms

When debugging complex algorithms, planning systems, or multi-step processes, create dedicated debug scripts instead of trying to trace through the logic conversationally with the LLM.

### The principle

Complex algorithmic debugging requires systematic observation of intermediate states, method calls, and decision points. Debug scripts provide repeatable, detailed analysis that is far more effective than attempting to reason through the logic in conversation.

### When to create debug scripts

**Always use debug scripts for:**

- **Multi-step algorithms:** Planning systems, search algorithms, optimization routines
- **State-dependent logic:** Systems where current state affects future decisions  
- **Method resolution:** When multiple methods or strategies can be selected
- **Backtracking systems:** Algorithms that need to undo and retry decisions
- **Tree or graph traversal:** Any system that navigates complex data structures

**Also consider for:**

- **Performance analysis:** When you need to measure timing or resource usage
- **Integration testing:** Testing interactions between multiple components
- **Edge case exploration:** Systematically testing boundary conditions

### Implementation approach

1. **Create a standalone script:** Use `debug_[feature].exs` naming convention
2. **Include multiple test scenarios:** Cover normal cases, edge cases, and failure modes
3. **Add detailed logging:** Show intermediate states, decisions, and transitions
4. **Test individual components:** Isolate and test methods, functions, or modules separately
5. **Simulate step-by-step execution:** Walk through the algorithm manually with logging

### Debug script structure

```elixir
# Debug script for [feature] behavior
# Usage: mix run debug_[feature].exs

defmodule [Feature]Debug do
  alias ProjectModule.{Component1, Component2}
  
  def test_normal_case do
    IO.puts("=== Testing normal case ===")
    # Setup, execution, detailed logging
  end
  
  def test_edge_cases do
    IO.puts("=== Testing edge cases ===")
    # Multiple edge case scenarios
  end
  
  def test_individual_components do
    IO.puts("=== Testing components individually ===")
    # Isolate and test each component
  end
  
  defp detailed_trace(state, action, result) do
    IO.puts("Action: #{action}")
    IO.puts("  Before: #{inspect(state)}")
    IO.puts("  Result: #{inspect(result)}")
  end
  
  def run_all_tests do
    test_normal_case()
    test_edge_cases()  
    test_individual_components()
  end
end

[Feature]Debug.run_all_tests()
```

### Benefits of debug scripts

- **Repeatable analysis:** Run the same test scenarios multiple times
- **Detailed visibility:** Log every intermediate state and decision
- **Isolation testing:** Test individual components separately from the whole
- **Version control:** Track debugging progress and findings over time
- **Faster iteration:** Modify and re-run tests quickly without conversation overhead

### What to avoid

- **Debugging through conversation:** Don't try to trace complex algorithms by discussing them
- **Single-shot debugging:** Avoid one-time debug sessions that can't be repeated
- **Incomplete logging:** Don't skip intermediate states or decision points
- **Monolithic scripts:** Split complex debugging into focused test scenarios

### Integration with development workflow

1. **Create debug script first:** Before discussing the problem, create a script to observe it
2. **Share findings:** Use script output to discuss specific issues and solutions
3. **Iterate solutions:** Modify the algorithm, then re-run the debug script to verify
4. **Preserve debugging:** Keep successful debug scripts for regression testing

### Example scenarios

**HTN Planning debugging:**

```elixir
def test_backtracking_scenario do
  IO.puts("=== Testing backtracking with method alternatives ===")
  
  domain = TestDomains.build_backtracking_domain()
  state = TestDomains.create_initial_state()
  goals = [{"task1", []}, {"task2", []}]
  
  IO.puts("Initial state: #{inspect(state)}")
  IO.puts("Goals: #{inspect(goals)}")
  
  case Planner.plan(domain, state, goals, verbose: 3) do
    {:ok, plan} ->
      IO.puts("Plan succeeded: #{inspect(plan)}")
      simulate_execution(domain, state, plan)
    {:error, reason} ->
      IO.puts("Plan failed: #{reason}")
  end
end
```

**State machine debugging:**

```elixir
def test_state_transitions do
  IO.puts("=== Testing state machine transitions ===")
  
  machine = StateMachine.new(:initial_state)
  events = [:event1, :event2, :event3]
  
  Enum.reduce(events, machine, fn event, current_machine ->
    IO.puts("Event: #{event}")
    IO.puts("  Current state: #{current_machine.state}")
    
    case StateMachine.handle_event(current_machine, event) do
      {:ok, new_machine} ->
        IO.puts("  New state: #{new_machine.state}")
        new_machine
      {:error, reason} ->
        IO.puts("  Transition failed: #{reason}")
        current_machine
    end
  end)
end
```

This approach transforms debugging from slow conversational analysis into fast, systematic observation and testing.
