# AriaBlocksWorld

A blocks world domain implementation for the Aria planning system, based on the GTpyhop blocks_gtn domain.

## Overview

AriaBlocksWorld provides a complete implementation of the classic blocks world planning domain using the AriaEngine framework. It demonstrates the unified durative action specification (R25W1398085) and serves as a test case for the GTpyhop blocks_gtn domain examples.

## Features

- **Complete blocks world domain** with pickup, unstack, putdown, and stack actions
- **Task methods** for complex block movement operations
- **Unigoal methods** for position and clear goals
- **State management** using AriaState.RelationalState
- **Example problems** including the famous Sussman anomaly
- **Comprehensive test suite** with 42 passing tests

## Domain Actions

### Primitive Actions

- `pickup(state, [block])` - Pick up a block from the table
- `unstack(state, [block1, block2])` - Remove block1 from on top of block2
- `putdown(state, [block])` - Put down the held block on the table
- `stack(state, [block1, block2])` - Put block1 on top of block2

### Task Methods

- `move_block(state, [block, destination])` - Move a block to a specific position

### Unigoal Methods

- `achieve_position(state, {block, destination})` - Handle position goals
- `achieve_clear(state, {block, true})` - Handle clear goals

## State Representation

The blocks world state uses three main predicates:

- `{"pos", block, position}` - Position of block (table, hand, or another block)
- `{"clear", block, boolean}` - Whether block is clear (true/false)
- `{"holding", "hand", block_or_false}` - What the hand is holding (block name or false)

## Usage

### Basic Domain Creation

```elixir
# Create domain
domain = AriaBlocksWorld.Domain.create()

# Create initial state
state = AriaBlocksWorld.State.create(%{
  pos: %{"a" => "table", "b" => "table"},
  clear: %{"a" => true, "b" => true},
  holding: %{"hand" => false}
})

# Define goals
goals = [{"pos", "a", "b"}]

# Plan and execute
{:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)
```

### Running Examples

```elixir
# Run predefined examples
{:ok, result} = AriaBlocksWorld.Examples.run(:simple_pickup)
{:ok, result} = AriaBlocksWorld.Examples.run(:simple_stack)
{:ok, result} = AriaBlocksWorld.Examples.run(:sussman_anomaly)

# Or through the main module
{:ok, result} = AriaBlocksWorld.run_example(:simple_pickup)
```

### Available Examples

- `:simple_pickup` - Basic pickup operation test
- `:simple_stack` - Basic stacking operation: A on B
- `:sussman_anomaly` - Classic subgoal interaction problem: A on B, B on C
- `:complex_multiblock` - Complex rearrangement: reverse a 3-block stack

## Testing

Run the test suite:

```bash
mix test apps/aria_blocks_world
```

The test suite includes:

- **Domain functionality tests** (18 tests) - Basic domain operations
- **Integration tests** (24 tests) - Full planning and execution scenarios
- **GTpyhop compatibility tests** - Verification against original examples

## Architecture

AriaBlocksWorld follows the R25W1398085 unified durative action specification:

- **Entity-capability model** with hand (manipulation) and table (support)
- **Standardized action specifications** with clear preconditions and effects
- **Relational state management** using AriaState.RelationalState
- **Integration with AriaEngineCore** for planning and execution

## Files

- `lib/aria_blocks_world.ex` - Main module and external API
- `lib/aria_blocks_world/domain.ex` - Domain definition with actions and methods
- `lib/aria_blocks_world/state.ex` - State management utilities
- `lib/aria_blocks_world/examples.ex` - Predefined example problems
- `test/aria_blocks_world/domain_test.exs` - Domain-specific tests
- `test/aria_blocks_world_test.exs` - Integration and example tests

## Dependencies

- `aria_core` - Core domain functionality
- `aria_state` - State management system
- `aria_engine_core` - Planning and execution engine

## References

Based on the GTpyhop blocks_gtn domain, which implements the near-optimal planning algorithm described in:

> N. Gupta and D. S. Nau. On the complexity of blocks-world planning.
> Artificial Intelligence 56(2-3):223–254, 1992.

## License

Copyright (c) 2025-present K. S. Ernest (iFire) Lee  
SPDX-License-Identifier: MIT
