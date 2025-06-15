# ADR-070: Aria Timestrike Startup Initialization and Forever Loop

## Status

Accepted

## Context

Aria Timestrike is designed as the core temporal planning and execution engine that coordinates character actions within the game world. When the system starts up, it needs a clear initialization sequence and operational pattern that ensures consistent temporal reference points and continuous operation.

The system must establish a temporal baseline from which all future calculations and planning operations are measured. This initialization must be deterministic and provide a stable foundation for the temporal planning algorithms.

## Decision

When Aria Timestrike starts:

1. **Set Start Time**: The system immediately captures the current system time as the canonical start time reference point
2. **Initialize Components**: All temporal planning components, state managers, and coordination systems are initialized in the proper sequence
3. **Enter Forever Loop**: The system enters an indefinite execution loop, continuously processing temporal plans and coordinating actions until explicitly instructed to stop

### Initialization Sequence

- Capture `System.system_time(:millisecond)` as the canonical start time
- Initialize the temporal planner state
- Initialize action coordination systems
- Initialize any required monitoring and logging systems
- Begin the main execution loop

### Forever Loop Behavior

- The system runs continuously, processing temporal plans and executing actions
- The loop continues indefinitely unless:
  - Explicit shutdown signal is received
  - Critical system error requires termination
  - External process termination

## Consequences

### Positive

- **Consistent Temporal Reference**: All temporal calculations have a single, well-defined reference point
- **Predictable Startup**: Clear initialization sequence ensures system components are ready before execution begins
- **Continuous Operation**: Forever loop design matches the expected behavior of a game engine that should run until told to stop
- **Deterministic Behavior**: Start time establishment provides deterministic foundation for temporal planning

### Negative

- **Resource Consumption**: Forever loop requires careful resource management to prevent memory leaks or resource exhaustion
- **Shutdown Management**: Requires proper signal handling to ensure clean shutdown when needed
- **Testing Complexity**: Forever loops require special testing strategies to verify behavior without infinite test execution

### Neutral

- **System Time Dependency**: Start time is dependent on system clock accuracy, which is acceptable for game timing purposes
- **Process Lifecycle**: Matches standard expectations for long-running service processes

## Implementation Notes

- Start time should be stored in a supervision tree-accessible location for other components to reference
- The forever loop should include appropriate error handling and recovery mechanisms
- Monitoring and observability should be built into the loop to track system health
- The loop should be designed to handle graceful shutdown signals

## Related Decisions

- ADR-034: Definitive Temporal Planner Architecture
- ADR-047: Timestrike Temporal Planner Test Scenario
- ADR-006: Game Engine Real-Time Execution
