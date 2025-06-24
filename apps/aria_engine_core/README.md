# AriaEngineCore

Core state management and utilities for AriaEngine.

## Overview

AriaEngineCore provides the foundation layer for the AriaEngine system including:

- **State Management** - Core state structures and operations
- **Domain Management** - Domain definitions and utilities
- **Multigoal Support** - Goal management structures
- **MiniZinc Integration** - External solver execution
- **Core Utilities** - Shared utility functions

## Key Components

### State Management

- Core state structures (State, StateV2)
- State operations and transformations
- Validation and consistency checking

### Domain System

- Domain definitions and management
- Domain-specific operations
- Validation and verification

### MiniZinc Integration

- External process execution for MiniZinc solver
- Constraint problem solving
- Result parsing and validation

## Dependencies

- **jason** - JSON encoding/decoding
- **libgraph** - Graph data structures
- **porcelain** - External process execution

## Usage

```elixir
# Create new state
state = AriaEngine.State.new()

# Create multigoal structure
multigoal = AriaEngine.Multigoal.new()

# Execute MiniZinc solver
{:ok, result} = AriaEngine.MiniZinc.Executor.solve(problem)
```

## Testing

Run the test suite:

```bash
cd apps/aria_engine_core
mix test
```

## License

MIT License - see LICENSE.md for details.
