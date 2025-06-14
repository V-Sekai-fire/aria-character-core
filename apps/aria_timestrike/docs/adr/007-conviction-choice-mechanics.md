# ADR-007: Conviction Choice Mechanics

## Status
Accepted

## Context
Player decision-making needs to occur under realistic time pressure without pausing gameplay, creating authentic tactical stress while maintaining streaming entertainment value.

## Decision
Implement choice as a real-time decision with time pressure and default fallback.

## Rationale
- **Realistic Pressure**: Conviction Choice triggers after initial survive_encounter goal is set
- **Continuous Gameplay**: Game continues running at normal speed (no pause) with a 5-second decision window
- **Time Pressure**: CLI displays choice menu with countdown timer (5.0s, 4.9s, 4.8s...)
- **Immediate Response**: User input (1-4 keys) immediately triggers re-planning with new goal
- **Default Fallback**: If no choice made within 5 seconds, defaults to "Morality" (rescue_hostage)
- **Tactical Stress**: Time pressure creates realistic tactical decision-making stress

## Implementation
- **5-Second Window**: Fixed decision time limit with visual countdown
- **Real-time Display**: Countdown timer shows remaining decision time
- **Immediate Processing**: User input triggers instant re-planning
- **Default Action**: Automatic fallback to predetermined choice
- **Optional Enhancement**: Add "slow-motion mode" option (0.5x speed) during choice for tactical consideration

## Consequences
### Positive
- Creates authentic tactical decision-making pressure
- Maintains continuous gameplay flow
- Supports streaming entertainment with visible tension
- Provides clear decision windows for players

### Negative
- May stress players unused to time pressure
- Requires precise timing implementation
- Could disadvantage players with slower reaction times
- Adds complexity to input handling system

## Related Decisions
- Builds on ADR-006 (Real-time Execution) for continuous gameplay
- Links to ADR-012 (Real-Time Input System) for responsive controls
- Supports ADR-013 (Opportunity Window Mechanics) with time-pressured decisions
