# ADR-009: Action Duration & Movement Calculations

## Status

Accepted

## Context

The temporal planner requires accurate action duration calculations to provide reliable timing estimates and enable meaningful player interventions.

## Decision

Use Euclidean distance with per-agent movement speed from agent stats.

## Rationale

- **Variable Speed**: Movement speed varies per agent (Alex: 4, Maya: 3, Jordan: 3 units per second)
- **Precise Calculation**: Duration formula: `distance = sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)`, time = distance / agent.move_speed
- **Interruption Support**: Interrupted actions store progress and resume from current position
- **Cooldown Management**: Cooldowns are absolute timers - remain active during re-planning
- **Validation**: Actions validate cooldown availability before being added to plan

## Implementation

- **Distance Formula**: Standard Euclidean distance calculation in 3D space
- **Agent-Specific Speed**: Per-agent movement statistics from game data
- **Progress Tracking**: Linear interpolation for interrupted action resumption
- **Cooldown Timers**: Absolute timing independent of planning cycles
- **Pre-validation**: Action availability checks before plan creation

## Technical Details

```elixir
# Duration calculation
duration = :math.sqrt(:math.pow(x2-x1, 2) + :math.pow(y2-y1, 2) + :math.pow(z2-z1, 2)) / agent.move_speed

# Progress tracking for interruptions
current_position = start_pos + (progress * (end_pos - start_pos))
```

## Consequences

### Positive

- Predictable and consistent action timing
- Realistic movement based on agent capabilities
- Support for tactical interruption and resumption
- Clear mathematical foundation for planning

### Negative

- Simplified movement model may not reflect complex terrain
- Linear interpolation may not match realistic movement patterns
- Requires accurate agent statistics for proper balance
- No support for dynamic speed changes during movement

## Related Decisions

- Links to ADR-023 (MVP Timing Implementation Strategy) for deterministic calculations
- Supports ADR-010 (Map & Terrain System) with coordinate-based movement
- Enables ADR-011 (Oban Queue Idempotency) with predictable action outcomes
