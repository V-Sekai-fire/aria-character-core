# R25W006E842: Oban Queue Idempotency & Intent Rejection

<!-- @adr_serial R25W006E842 -->

## Status

Accepted

## Context

The temporal planner's action execution system must handle re-planning, interruptions, and state changes gracefully without causing inconsistencies or system failures.

## Decision

All Oban queue actions must be designed as idempotent intents that can be rejected at execution time.

## Rationale

- **Idempotent Design**: Each action job must be safe to execute multiple times without side effects
- **Intent-Based Architecture**: Actions are "intents to act" rather than guaranteed commands
- **Execution-Time Validation**: Actions verify state compatibility before applying effects
- **Graceful Failure**: Rejected actions don't crash the game loop and trigger appropriate re-planning

## Implementation

### Idempotent Action Design

- **State Validation**: Actions check current state validity before execution
- **Duplicate Safety**: Duplicate executions return early if action is already completed/obsolete
- **Atomic Transitions**: State transitions are conflict-resistant and atomic

### Intent-Based Execution

- **Sufficient Context**: Jobs carry context to validate execution conditions at runtime
- **Rejection Capability**: Actions can be rejected if preconditions are no longer valid
- **Logging**: Rejection reasons logged for debugging and re-planning triggers

### Execution-Time Validation

- **Position Validation**: Ensure agent is at expected location
- **Resource Checks**: Verify cooldowns, stamina, inventory availability
- **Environmental Validation**: Confirm target still exists, path still clear
- **Goal Relevance**: Verify action still supports current goal

### Cancellation Support

- **Re-planning Cancellation**: Actions can be cancelled before execution
- **Status Tracking**: Cancelled actions marked as `:cancelled` in job status
- **State Consistency**: Game state remains consistent during plan transitions

## Technical Details

```elixir
# Action job return values
{:ok, :completed}              # Action executed successfully
{:ok, :rejected, reason}       # Action rejected with reason
{:error, reason}               # Action failed with error

# Cancellation support
TemporalPlanner.cancel_action(action_id)
```

## Consequences

### Positive

- Robust handling of dynamic game state changes
- Graceful recovery from invalid actions
- Support for real-time re-planning scenarios
- Reduced system crashes from state inconsistencies

### Negative

- Increased complexity in action implementation
- Additional validation overhead at execution time
- More complex error handling and logging requirements
- Potential for action rejection cascades

## Related Decisions

- Links to R25W002DF48 (Oban Queue Design) for job execution framework
- Supports ADR-007 (Conviction Choice Mechanics) with re-planning capability
- Enables ADR-012 (Real-Time Input System) with action cancellation
