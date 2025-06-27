# R25W0013716: State Architecture Migration

<!-- @adr_serial R25W0013716 -->

## Status

**Superseded by R25W017DEAF: Definitive Temporal Planner Architecture**

*This ADR has been consolidated into R25W017DEAF along with all other temporal planner architectural decisions. See R25W017DEAF for current implementation guidance.*

## Date

2025-06-13

## Context

The existing state architecture in the temporal planner needs to be migrated to support time-based queries and scheduling for the temporal goal-task-network (GTN) planner implementation.

## Decision

Do NOT keep existing state. Migrate all code to use the new temporal state architecture.

## Rationale

- The temporal planner requires time-based queries and scheduling capabilities
- Old state structures are incompatible with temporal planning requirements
- Complete migration ensures consistency and eliminates legacy technical debt
- All game entities (agents, actions, effects) must work with the temporal state system

## Consequences

### Positive

- Clean temporal state architecture enables time-based queries
- No legacy state compatibility issues
- All modules use consistent temporal state approach
- Supports future temporal planning features

### Negative

- Requires migration of all existing code
- No backwards compatibility with old state
- Development effort required for complete migration

## Implementation Details

- Remove old state structures from existing code
- All modules must use the new temporal state defined in `temporal_planner_data_structures.md`
- Complete migration required - no backwards compatibility with old state
- Temporal state must support time-based queries and scheduling
- All game entities (agents, actions, effects) must work with temporal state system

## Related Decisions

- **Enables**: R25W002DF48 (Oban Queue Design) - temporal state supports time-ordered action queues
- **Links to**: ADR-006 (Game Engine Integration) - temporal state integrates with real-time execution
- **Supports**: R25W009BCB5 (MVP Definition) - extends existing AriaEngine.State for temporal capabilities
- **Links to**: R25W0101F54 (Test-Driven Development) - temporal state extensions drive test scenarios
