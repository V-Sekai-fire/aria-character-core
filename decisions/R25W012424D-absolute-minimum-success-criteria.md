# R25W012424D: Absolute Minimum Success Criteria

<!-- @adr_serial R25W012424D -->

## Status

Accepted

## Context

The weekend implementation must have clearly defined minimum success criteria that prove the temporal planner concept works, with fallback options if real-time execution proves too complex.

## Decision

Define the smallest possible demonstration that proves the temporal planner concept works.

## Rationale

- **Risk Management**: Ensure demonstrable success even if advanced features fail
- **Core Validation**: Focus on essential temporal planning capabilities
- **Fallback Strategy**: Provide alternative success criteria if real-time proves too complex
- **Weekend Viability**: Guarantee something working by Sunday evening

## Implementation

### Core Success Criteria (All Must Work)

1. **Temporal State**: Store "Alex is at {2,3} at time 10.5s"
2. **Scheduled Action**: Create "Move Alex to {5,3} starting at 12.0s"
3. **Oban Execution**: Action executes automatically at scheduled time
4. **State Update**: Alex's position updates correctly when action completes
5. **Simple CLI**: Terminal shows "Alex moving from {2,3} to {5,3} - ETA: 1.2s"
6. **Manual Verification**: Human can observe system working correctly

### Fallback Criteria (If Real-time Too Complex)

1. **Static Planning**: Print out a complete plan without executing it
2. **Timing Calculation**: Show estimated durations for each action
3. **State Display**: Show current state and planned future state
4. **Proof of Concept**: Demonstrate temporal planning logic without real-time execution

### Success Validation Requirements

- **Demonstrable**: Can show working system to others in 5 minutes
- **Temporal**: Involves time-based scheduling and execution
- **Plannable**: Shows intelligent sequencing of actions
- **Extensible**: Foundation for adding complexity later

## Weekend Acceptance Test

```bash
# Run the system
mix aria_engine.conviction_crisis

# Expected output:
# Alex at {2,3} - Planning movement to {8,3}
# Alex moving from {2,3} to {8,3} - ETA: 2.0s
# [Progress bar showing movement]
# Press SPACEBAR to interrupt...
# [User presses SPACEBAR at 50% progress]
# Alex interrupted at {5,3} - Replanning...
# Alex moving from {5,3} to {8,3} - ETA: 1.0s
# Mission Complete!
```

### Minimum Infrastructure Requirements

- **Temporal State Storage**: Basic data structure for time-aware state
- **Action Scheduling**: Simple Oban job creation and execution
- **Position Tracking**: Basic coordinate storage and updates
- **Terminal Display**: Simple text output showing progress
- **Input Handling**: Basic keyboard interrupt detection

## Risk Assessment

### Critical Dependencies

- **Oban Scheduling Precision**: Actions must execute at correct times
- **State Consistency**: Position updates must be accurate
- **Input Responsiveness**: SPACEBAR interrupt must work reliably
- **Display Updates**: Terminal must show current status

### Failure Points and Mitigation

- **Oban Timing Issues**: Fall back to static plan display
- **Real-time Display Problems**: Use simple periodic status prints
- **Input Handling Failures**: Remove interruption, show static plan
- **State Corruption**: Use simplified state management

## Success Metrics

### Core Demonstration

- System starts and shows initial state
- Action executes at correct time
- Position updates accurately
- User can observe the process working

### Enhanced Demonstration (If Time Permits)

- Smooth real-time display updates
- Responsive user interruption
- Accurate re-planning after interruption
- Professional terminal interface

## Consequences

### Positive

- Guaranteed working demonstration by weekend end
- Clear minimum requirements prevent scope creep
- Fallback options handle implementation risks
- Foundation for future enhancement

### Negative

- Minimum criteria may not fully showcase system capabilities
- Fallback options may not be compelling demonstrations
- Limited feature set may not justify complexity investment
- May require post-weekend work for professional presentation

## Related Decisions

- Links to R25W00787B6 (Weekend Implementation Scope) for timeline management
- Supports R25W009BCB5 (MVP Definition) with concrete success criteria
- Implements ADR-005 (TimeStrike Test Domain) as validation scenario
- Builds on R25W0101F54 (Test-Driven Development) for implementation approach
- Enables R25W0143F62 (Risk Mitigation) with fallback strategies
- Supports R25W011BD45 (MVP Timing Implementation Strategy) with clear success metrics
