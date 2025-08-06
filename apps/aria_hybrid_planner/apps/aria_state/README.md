# AriaState

State management for AriaEngine planning systems.

## Overview

AriaState provides two complementary APIs for managing world state in planning systems:

- **ObjectState**: Entity-centric API for domain developers (public API)
- **RelationalState**: Predicate-centric API for internal AriaEngine operations

## Public API (Domain Developers)

Use `AriaState.ObjectState` for all domain development:

```elixir
# Entity-centric, pipe-friendly API
state = AriaState.ObjectState.new()
|> AriaState.ObjectState.set_fact("chef_1", "status", "cooking")
|> AriaState.ObjectState.set_fact("meal_001", "status", "in_progress")
|> AriaState.ObjectState.set_fact("oven_1", "temperature", 375)

# Reading facts
chef_status = AriaState.ObjectState.get_fact(state, "chef_1", "status")
# => "cooking"

# Entity queries
available_entities = AriaState.ObjectState.get_subjects_with_fact(state, "status", "available")
```

## Convenience API

The main `AriaState` module delegates to `ObjectState` for convenience:

```elixir
# These are equivalent:
state = AriaState.new() |> AriaState.set_fact("chef_1", "status", "cooking")
state = AriaState.ObjectState.new() |> AriaState.ObjectState.set_fact("chef_1", "status", "cooking")
```

## Internal API (AriaEngine)

`AriaState.RelationalState` is used internally for performance-optimized queries:

```elixir
# Predicate-centric queries for planning
available_chefs = AriaState.RelationalState.get_subjects_with_fact(state, "status", "available")
```

## Architecture

Both APIs operate on the same underlying data structure but provide different query patterns:

- **ObjectState**: `{subject, predicate} -> value` (entity-first)
- **RelationalState**: `{predicate, subject} -> value` (predicate-first)

## Condition Evaluation

Both APIs support complex condition evaluation:

```elixir
# Exact matches
condition = {"chef_1", "status", "available"}
AriaState.ObjectState.evaluate_condition(state, condition)

# Existential quantifiers
condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
AriaState.ObjectState.evaluate_condition(state, condition)

# Universal quantifiers
condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
AriaState.ObjectState.evaluate_condition(state, condition)
```

## Testing

```bash
mix test
```

## Usage in Other Apps

Add `aria_state` as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:aria_state, in_umbrella: true}
  ]
end
```

Then use in your modules:

```elixir
defmodule MyDomain do
  alias AriaState.ObjectState

  def create_initial_state do
    ObjectState.new()
    |> ObjectState.set_fact("player", "location", "start_room")
    |> ObjectState.set_fact("player", "health", 100)
  end
end
