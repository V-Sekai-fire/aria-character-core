# R25W0031F1C: Game Engine Separation

<!-- @adr_serial R25W0031F1C -->

## Status

Accepted

## Date

2025-06-13

## Context

The temporal planner and game engine have different responsibilities and should be architected as separate concerns to maintain clean separation and enable independent development.

## Decision

Separate GameEngine from the planner.

## Rationale

- Clear separation of concerns improves maintainability
- GameEngine focuses on game-specific logic and state
- Planner focuses on temporal planning algorithms and stability
- Independent development and testing of each component

## Consequences

### Positive

- Clean architectural boundaries
- Independent development and testing
- Easier maintenance and debugging
- Clear responsibility allocation

### Negative

- Additional interface complexity between components
- Coordination required between game engine and planner

## Implementation Details

- GameEngine handles game-specific logic and state management
- Planner focuses on temporal planning algorithms and stability verification
- Well-defined interfaces between components
- Each component can be developed and tested independently

## Related Decisions

- **Integrates with**: R25W0013716 (State Architecture Migration) - separated components share temporal state
- **Links to**: R25W002DF48 (Oban Queue Design) - game engine uses queues for action execution
- **Supports**: ADR-006 (Game Engine Integration) - defines boundaries for real-time execution
- **Enables**: R25W009BCB5 (MVP Definition) - separation allows focused temporal planner development
