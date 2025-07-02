# AriaBacktrackingTest

Backtracking test application for validating HTN planning failure recovery in the Aria planning system.

This application implements the GTPyhop `backtracking_htn.py` example in Elixir, providing a simple domain specifically designed to test backtracking behavior and failure recovery mechanisms.

## Overview

The backtracking test domain provides a minimal state with a single flag value and actions that can deliberately fail to trigger backtracking scenarios. This is perfect for testing:

- Method selection and ordering
- Action failure detection
- Backtracking to alternative methods
- Blacklisting of failed methods
- ReentrantExecutor failure recovery

## Domain Description

### State

Simple state structure with a single integer flag:

```elixir
%AriaBacktrackingTest.State{flag: -1}  # Default initial state
```

### Actions

- `putv(state, flag_val)` - Sets the flag to a specific value (always succeeds)
- `getv(state, flag_val)` - Succeeds only if the current flag matches the expected value

### Methods

**For task `put_it`:**
- `m_err` - Deliberately broken: `[("putv", 0), ("getv", 1)]` (sets flag to 0, then tries to get 1)
- `m0` - Working method: `[("putv", 0), ("getv", 0)]`
- `m1` - Working method: `[("putv", 1), ("getv", 1)]`

**For other tasks:**
- `need0` - Requires flag to be 0
- `need1` - Requires flag to be 1
- `need01` - Can use either need0 or need1 method
- `need10` - Can use either need1 or need0 method (different order)

## Test Scenarios

The app includes test scenarios from the original Python example:

1. **Single backtrack**: `[("put_it", []), ("need0", [])]`
   - Tries `m_err` first, fails on `getv(1)`, backtracks to `m0`

2. **Method choice**: `[("put_it", []), ("need01", [])]`
   - Tests method selection logic

3. **Double backtrack**: `[("put_it", []), ("need10", [])]`
   - Backtracks on both tasks

4. **Complex backtrack**: `[("put_it", []), ("need1", [])]`
   - Tries `m_err` (fails), then `m0` (fails need1), then `m1` (succeeds)

## Usage

### Basic Usage

```elixir
# Create initial state
state = AriaBacktrackingTest.State.new()

# Solve a problem that requires backtracking
{:ok, {final_state, plan}} = AriaBacktrackingTest.solve_problem(state, [{"put_it", []}, {"need0", []}])

# Check the result
AriaBacktrackingTest.State.get_flag(final_state)  # Should be 0
```

### Running All Test Scenarios

```elixir
# Run all test scenarios (quiet)
:ok = AriaBacktrackingTest.run_examples()

# Run with verbose output
:ok = AriaBacktrackingTest.run_examples(true)
```

### Testing Individual Actions

```elixir
state = AriaBacktrackingTest.State.new()

# Test putv action
{:ok, new_state} = AriaBacktrackingTest.Domain.putv(state, 42)
AriaBacktrackingTest.State.get_flag(new_state)  # 42

# Test getv action
{:ok, _} = AriaBacktrackingTest.Domain.getv(new_state, 42)  # Succeeds
{:error, _} = AriaBacktrackingTest.Domain.getv(new_state, 99)  # Fails
```

## Integration with Aria Planning System

This app integrates with the broader Aria planning system:

- Uses `AriaState.RelationalState` for state representation
- Integrates with `AriaHybridPlanner` for planning and execution
- Tests the `ReentrantExecutor` backtracking mechanisms
- Validates blacklisting infrastructure

## Testing

Run the test suite:

```bash
mix test apps/aria_backtracking_test
```

The tests include:
- All four backtracking scenarios from the Python example
- Individual action and method tests
- State conversion tests
- Integration tests with the planning system

## Expected Results

When working correctly, the test scenarios should produce these results:

- **Single backtrack**: Final flag = 0, plan includes backtrack from `m_err` to `m0`
- **Method choice**: Final flag = 0, demonstrates method selection
- **Double backtrack**: Final flag = 0, shows backtracking on multiple tasks
- **Complex backtrack**: Final flag = 1, demonstrates multiple method attempts

## Development

This app serves as a reference implementation for:

1. **Simple HTN domains** - Clean, minimal domain structure
2. **Backtracking test cases** - Comprehensive failure scenarios
3. **Integration patterns** - How to connect with the Aria planning system
4. **Test organization** - Well-structured test suites for planning domains

The simplicity of this domain makes it ideal for debugging planning system issues and validating new backtracking mechanisms.
