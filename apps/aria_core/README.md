# AriaCore

AriaCore is the foundational library for the Aria Character Core system, providing unified action specification, temporal reasoning, state management, and domain modeling capabilities.

## Overview

AriaCore implements a comprehensive system for defining and executing actions in AI planning domains. It provides:

- **Unified Action Specification**: Define actions using `@action` attributes with automatic conversion to planning-compatible formats
- **Temporal Reasoning**: Support for durative actions, intervals, and temporal constraints
- **State Management**: Relational state representation with goal satisfaction checking
- **Domain Modeling**: Module-based domain creation with validation and merging capabilities
- **Entity Management**: Type-safe entity registration and capability tracking

## Key Features

### Action Attributes System

Define actions declaratively using module attributes:

```elixir
defmodule CookingDomain do
  use AriaCore.Domain

  @action %{
    duration: {:fixed, 1800},  # 30 minutes
    entity_requirements: [chef: [:cooking]],
    preconditions: [
      {"oven", "temperature", {:>=, 350}},
      {"ingredients", "available", true}
    ],
    effects: [
      {"meal", "status", "ready"},
      {"chef", "status", "available"}
    ]
  }
  def cook_soup(state, _args) do
    # Implementation
    state
  end
end
```

### Temporal System

Support for various duration types and temporal reasoning:

```elixir
# Fixed duration
duration = AriaCore.Temporal.Interval.fixed(3600)  # 1 hour

# ISO 8601 duration parsing
duration = AriaCore.Temporal.Interval.parse_iso8601("PT30M")  # 30 minutes

# Open-ended intervals
duration = AriaCore.Temporal.Interval.open_start(end_time)
```

### State Management

Relational state representation with fact storage and goal checking:

```elixir
state = AriaCore.State.Relational.new()
state = AriaCore.State.Relational.set_fact(state, "chef_status", "chef_1", "available")

# Goal satisfaction checking
goal_satisfied = AriaCore.State.Relational.satisfies_goal?(state, 
  {"chef_status", "chef_1", "available"})
```

### Domain Creation and Validation

Create domains from modules with automatic validation:

```elixir
# Create domain from module
domain = AriaCore.UnifiedDomain.create_from_module(CookingDomain)

# Validate domain configuration
:ok = AriaCore.UnifiedDomain.validate_domain_module(CookingDomain)

# Merge multiple domains
unified = AriaCore.UnifiedDomain.merge_domains([cooking_domain, cleaning_domain])
```

## Architecture

AriaCore is organized into several key modules:

- **AriaCore.ActionAttributes**: Attribute-based action definition system
- **AriaCore.Domain**: Core domain modeling and action management
- **AriaCore.State.Relational**: Relational state representation
- **AriaCore.Temporal.Interval**: Temporal reasoning and interval handling
- **AriaCore.Entity.Management**: Entity type registration and management
- **AriaCore.UnifiedDomain**: High-level domain creation and validation
- **AriaCore.TemporalConverter**: Conversion between temporal formats

## Usage

### Basic Domain Creation

```elixir
# Create a new domain
domain = AriaCore.Domain.new(:my_domain)

# Add an action
action_spec = %{
  duration: AriaCore.Temporal.Interval.fixed(1800),
  entity_requirements: [],
  preconditions: [],
  effects: [],
  action_fn: fn state, _args -> state end
}

domain = AriaCore.Domain.add_action(domain, :my_action, action_spec)
```

### Module-based Domain Definition

```elixir
defmodule MyDomain do
  use AriaCore.Domain

  @action %{
    duration: {:fixed, 1800},
    entity_requirements: [worker: [:task_capability]],
    preconditions: [{"resource", "available", true}],
    effects: [{"task", "completed", true}]
  }
  def perform_task(state, _args) do
    # Task implementation
    AriaCore.State.Relational.set_fact(state, "task", "completed", true)
  end
end

# Create domain from module
domain = AriaCore.UnifiedDomain.create_from_module(MyDomain)
```

## Testing

Run the test suite:

```bash
cd apps/aria_core
mix test
```

## Examples

See `lib/aria_core/examples/restaurant_domain.ex` for a comprehensive example of a restaurant management domain with multiple action types and temporal constraints.

## Integration

AriaCore is designed to integrate with:

- **Aria Temporal Planner**: For temporal planning and scheduling
- **Aria Hybrid Planner**: For hybrid planning approaches
- **Aria Scheduler**: For action execution scheduling
- **Aria Engine Core**: For overall system coordination

## Development Status

AriaCore implements the unified action specification system defined in ADR-181, providing:

- ✅ Phase 1: @action attributes system
- ✅ Phase 2: State integration and temporal conditions
- ✅ Phase 3: Module-based domain creation
- ✅ Phase 4: Full integration capabilities

The system is ready for integration testing and production use.
