# AriaTimestrike

**Temporal Goal-Task-Network Planner Implementation**

This is the advanced temporal implementation of the TimeStrike tactical scenario featuring comprehensive temporal reasoning, multi-phase backtracking, and Goal-Task-Network planning capabilities.

## Architecture

- **Temporal State System**: Time-indexed state with historical queries and future prediction
- **Multi-Phase Backtracking**: Information gathering, coordination, opportunity exploitation phases
- **Goal-Task-Network Planning**: High-level goal decomposition into executable task hierarchies
- **Imperfect Information Management**: Vision limitations and reconnaissance mechanics
- **Dynamic Opportunity Windows**: Real-time tactical advantage detection and exploitation
- **Real-Time Performance**: Sub-millisecond state queries and fast replanning

## Canonical Test Problem

The implementation validates against Maya's Adaptive Scorch Coordination problem as defined in ADR-035, which requires:

- Multi-agent coordination with temporal dependencies
- Historical state reconstruction for pattern analysis
- Dynamic replanning based on emerging opportunities
- Mathematical guarantees for optimality and stability

## Documentation

- **Design Document**: `docs/readme.md` - Complete TimeStrike scenario specification
- **Architecture**: `docs/adr/034-definitive-temporal-planner-architecture.md`
- **Canonical Problem**: `docs/adr/035-canonical-temporal-backtracking-problem.md`
- **API Reference**: Generated ExDoc documentation

## Installation

```elixir
def deps do
  [
    {:aria_timestrike, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
# See docs/api_demonstration.exs for complete example
{:ok, task_network} = GameEngine.decompose_goal(initial_state, goal)
{:ok, plan, final_state, metadata} = GameEngine.plan_temporal_sequence(
  initial_state, 
  task_network, 
  temporal_constraints
)
```

## Related Applications

- **aria_timestrike_core**: Foundational implementation using classical planning
- **aria_engine**: Core planning engine with temporal extensions
- **aria_workflow**: Workflow execution system integration
