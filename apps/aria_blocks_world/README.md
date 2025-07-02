# AriaBlocksWorldTest

A test application that implements and validates the classic blocks world planning domain from GTpyhop's `blocks_gtn` examples. This app serves as a comprehensive test suite for the AriaEngine planning system using the well-known blocks world domain.

## Purpose

This application provides:

1. **GTpyhop Compatibility Testing**: Validates that AriaEngine can handle the same problems as GTpyhop's blocks_gtn domain
2. **Planning System Validation**: Tests the core planning capabilities with a well-understood domain
3. **Example Problem Suite**: Provides classic planning problems including the Sussman Anomaly
4. **Integration Testing**: Verifies the integration between AriaEngine, AriaState, and AriaHybridPlanner

## Domain Overview

The blocks world domain includes:

### Predicates

- `pos(block, location)`: Position of blocks (on table, on other blocks, or in hand)
- `clear(block, boolean)`: Whether a block has nothing on top of it
- `holding(hand, block_or_false)`: What the robot hand is holding

### Actions

- `pickup(block)`: Pick up a block from the table
- `putdown(block)`: Put down a held block on the table
- `stack(block, target)`: Stack a held block on another block
- `unstack(block, from)`: Remove a block from on top of another block

### Task Methods

- `move_block(block, destination)`: High-level task to move a block
- `achieve_position(block, location)`: Achieve a specific position goal
- `achieve_clear(block, clear_state)`: Achieve a clear/not-clear state

## Example Problems

### Simple Pickup

Basic test of picking up a block from the table.

### Simple Stack

Basic test of stacking one block on another.

### Sussman Anomaly

The classic planning problem that demonstrates subgoal interaction:

- Initial: A on C, B on table, C on table
- Goal: A on B, B on C
- Requires careful ordering to avoid undoing progress

### Complex Multiblock

A more complex rearrangement problem:

- Initial: A on B on C (stack of 3)
- Goal: C on B on A (reverse the stack)

## Usage

```elixir
# Create a state
state = AriaBlocksWorldTest.create_state(%{
  pos: %{"a" => "table", "b" => "table"},
  clear: %{"a" => true, "b" => true},
  holding: %{"hand" => false}
})

# Create goals
goal = AriaBlocksWorldTest.create_multigoal(%{
  pos: %{"a" => "b"}
})

# Run planning
result = AriaBlocksWorldTest.solve_problem(state, [goal])

# Run predefined examples
{:ok, result} = AriaBlocksWorldTest.run_example(:sussman_anomaly)
```

## Testing

The app includes comprehensive test suites:

- `AriaBlocksWorldTestTest`: Basic functionality tests
- `AriaBlocksWorldTest.DomainTest`: Domain action and method tests
- `AriaBlocksWorldTest.GtpyhopExamplesTest`: GTpyhop compatibility tests

Run tests with:

```bash
mix test apps/aria_blocks_world_test
```

## Integration with AriaEngine

This app demonstrates the integration between:

- **AriaState.RelationalState**: For managing world state
- **AriaEngineCore**: For domain definition and action execution
- **AriaHybridPlanner**: For planning and goal achievement
- **AriaCore**: For multigoal handling

## GTpyhop Reference

This implementation is based on the `blocks_gtn` domain from GTpyhop, located in:
`thirdparty/GTPyhop/Examples/blocks_gtn/`

The goal is to maintain compatibility with GTpyhop's problem definitions while leveraging AriaEngine's capabilities for planning and execution.
