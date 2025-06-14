# ADR-006: Game Engine Integration & Real-time Execution

## Status
Accepted

## Context
The temporal planner needs to integrate with game execution in real-time, requiring precise timing and low-latency performance for responsive gameplay and streaming compatibility.

## Decision
Implement a high-frequency tick-based game loop with Oban integration for VR-style low latency.

## Rationale
- **Low Latency Requirements**: Game Engine runs on a 1ms tick cycle (1000 FPS) to achieve sub-7ms photon-to-photon latency
- **Latency Budget**: Total latency budget: 1ms tick + 2ms processing + 2ms display + 2ms buffer = ~7ms end-to-end
- **Real-time Integration**: Oban jobs execute actions at their scheduled times and update game state
- **Asynchronous Planning**: Re-planning occurs asynchronously without blocking game execution
- **Streaming Compatibility**: Sub-millisecond precision for temporal action scheduling supports streaming requirements

## Implementation
- **Tick-based Loop**: 1ms tick cycle for game state updates
- **Oban Scheduling**: Actions scheduled and executed via Oban jobs at precise times
- **Re-planning Triggers**: Goal changes, action failures, or significant state changes trigger replanning
- **Non-blocking Execution**: Game state changes queued and applied during tick updates
- **Precision Timing**: Sub-millisecond precision for temporal action scheduling

## Consequences
### Positive
- VR-level latency performance for responsive gameplay
- Precise temporal control over action execution
- Streaming-compatible real-time performance
- Clear separation between planning and execution

### Negative
- High CPU usage from 1000 FPS tick rate
- Complex timing coordination between systems
- Potential performance bottlenecks under high load
- Increased system complexity

## Related Decisions
- Links to ADR-002 (Oban Queue Design) for action execution
- Supports ADR-007 (Conviction Choice Mechanics) with real-time decision making
- Enables ADR-008 (Web Interface Implementation) with responsive updates
