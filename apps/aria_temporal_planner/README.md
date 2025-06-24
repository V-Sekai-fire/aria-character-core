# AriaTemporalPlanner

Temporal planning and Simple Temporal Networks (STN) solving for AriaEngine.

## Overview

AriaTemporalPlanner provides temporal reasoning capabilities including:

- **STN (Simple Temporal Networks)** - Constraint solving for temporal relationships
- **Timeline Management** - Agent timelines, intervals, and Allen relations
- **Temporal Planning** - STN-based planning algorithms
- **MiniZinc Integration** - External solver integration for complex constraints

## Key Components

### STN Solver

- Core STN constraint solving
- MiniZinc fallback for complex problems
- Temporal unit conversion and validation

### Timeline System

- Agent and entity timeline management
- Interval operations and Allen relations
- Timeline graph construction and validation

### Temporal Planner

- STN-based planning methods
- Temporal action representation
- Constraint propagation and solving

## Dependencies

- **jason** - JSON encoding/decoding
- **libgraph** - Graph data structures
- **porcelain** - External process execution (MiniZinc)

## Usage

```elixir
# Create STN solver
stn = AriaTemporalPlanner.STN.new()

# Add temporal constraints
stn = AriaTemporalPlanner.STN.add_constraint(stn, :start, :end, {0, 100})

# Solve constraints
{:ok, solution} = AriaTemporalPlanner.STN.solve(stn)
```

## Testing

Run the test suite:

```bash
cd apps/aria_temporal_planner
mix test
```

## License

MIT License - see LICENSE.md for details.
