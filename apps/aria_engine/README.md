# AriaEngine

Temporal Game Engine for TimeStrike - Advanced planning with temporal reasoning capabilities.

## Overview

AriaEngine extends AriaEngineCore with comprehensive temporal planning capabilities designed for real-time tactical scenarios. It implements the temporal planner architecture defined in ADR-034 and validated through the canonical temporal backtracking problem in ADR-035.

## Key Features

### Temporal Planning Capabilities
- **Goal-Task-Network (GTN) Decomposition**: Breaks high-level goals into executable task hierarchies
- **Multi-Phase Backtracking**: Handles conflicts at information, coordination, opportunity, and emergency levels
- **Historical State Reconstruction**: Queries past states to inform future planning decisions
- **Future State Prediction**: Accurately predicts agent behavior from historical patterns

### Advanced Temporal Features
- **Imperfect Information Management**: Plans with limited agent knowledge and information acquisition
- **Dynamic Opportunity Exploitation**: Detects and exploits time-limited tactical advantages
- **Multi-Agent Coordination**: Synchronizes complex agent interactions with temporal dependencies
- **Real-Time Performance**: Sub-millisecond state queries and fast replanning capabilities

### Mathematical Guarantees
- **Temporal Consistency**: All agent timelines form valid temporal orderings
- **Optimality**: Solutions minimize execution time while ensuring goal achievement
- **Stability**: Plans remain robust under timing perturbations and information updates

## Architecture

AriaEngine follows the temporal planning paradigm:

```
Temporal State + Goals + Constraints → Temporal Planner → Coordinated Actions
```

- **Temporal State**: Time-indexed world state with historical and predictive capabilities
- **Goals**: High-level objectives requiring temporal decomposition
- **Constraints**: Temporal, spatial, and resource limitations
- **Temporal Planner**: GTN planner with backtracking and opportunity detection
- **Coordinated Actions**: Multi-agent action sequences with temporal dependencies

## Usage

```elixir
# Create temporal state
state = AriaEngine.new_temporal_state(0.0)
|> AriaEngine.TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0.0)

# Define temporal goal
goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 20.0}

# Plan with temporal constraints
{:ok, plan, final_state, metadata} = AriaEngine.plan_temporal_sequence(
  state, 
  goal, 
  temporal_constraints
)

# Verify temporal planner features
assert metadata.goal_decomposition_depth >= 2
assert metadata.backtrack_phases >= 3
assert metadata.historical_queries_count >= 2
```

## Relationship to AriaEngineCore

AriaEngine builds upon AriaEngineCore, extending its proven classical planning capabilities with temporal reasoning. The core state management and action primitives from AriaEngineCore remain unchanged, ensuring compatibility while adding temporal awareness.

## Applications

- **aria_timestrike**: Advanced temporal TimeStrike gameplay with Maya's Scorch Coordination
- **Real-time tactical simulations**: Any scenario requiring temporal planning
- **Multi-agent coordination**: Systems with complex temporal dependencies

## Documentation

- **ADR-034**: Definitive Temporal Planner Architecture
- **ADR-035**: Canonical Temporal Backtracking Problem Definition
- **Game Design**: `docs/readme.md` - Complete TimeStrike scenario specification
