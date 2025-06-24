# AriaHybridPlanner

Hybrid planning coordination system providing strategy-based planning with temporal reasoning integration.

## Overview

AriaHybridPlanner implements a flexible hybrid planning architecture that coordinates multiple planning strategies:

- **HTN Planning Strategy**: Hierarchical task network decomposition
- **Temporal Strategy**: STN-based temporal reasoning integration  
- **State Management**: StateV2-based state tracking
- **Execution Strategy**: Lazy refinement execution
- **Logging Strategy**: Structured progress tracking

## Core Components

### HybridCoordinatorV2

Central coordination system that orchestrates planning strategies and manages the planning lifecycle.

### Strategy System

Pluggable strategy architecture supporting:

- Planning strategies (HTN, goal-based)
- Temporal reasoning strategies (STN integration)
- State management strategies (StateV2)
- Execution strategies (lazy, eager)
- Logging strategies (structured output)

### Plan Management

Core planning logic including:

- Backtracking and search algorithms
- Plan execution and validation
- Node expansion and goal achievement
- Utility functions for plan manipulation

## Dependencies

- **aria_engine_core**: Core state management and domain utilities
- **aria_temporal_planner**: Temporal reasoning and STN solving
- **libgraph**: Graph data structures for plan representation
- **jason**: JSON encoding/decoding
- **telemetry**: Event tracking and monitoring

## Usage

```elixir
# Create hybrid coordinator with default strategies
coordinator = HybridPlanner.HybridCoordinatorV2.new()

# Plan with tasks and goals
result = HybridPlanner.HybridCoordinatorV2.plan(coordinator, tasks, goals, opts)

# Access planning results
case result do
  {:ok, plan} -> # Handle successful planning
  {:error, reason} -> # Handle planning failure
end
```

## Architecture

The hybrid planner follows a layered architecture:

1. **Coordination Layer**: HybridCoordinatorV2 orchestrates planning
2. **Strategy Layer**: Pluggable strategies for different aspects
3. **Core Planning**: Fundamental planning algorithms and utilities
4. **Integration Layer**: Interfaces with temporal and state systems

## Testing

Run the test suite:

```bash
cd apps/aria_hybrid_planner
mix test
```

## Extraction History

**Extracted:** 2025-06-23  
**Source:** `lib/aria_engine/hybrid_planner/`, `lib/aria_engine/plan/`, `lib/aria_engine/planning/`  
**ADR Reference:** ADR-151 Strict Encapsulation and Modular Testing Architecture

This module was extracted to maintain strict encapsulation boundaries and enable independent testing of hybrid planning functionality.
