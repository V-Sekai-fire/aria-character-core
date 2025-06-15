# ADR-051: Continuous Simulation Looping Scenario

## Status

**Accepted**

## Date

2025-06-15

## Context

The TimeStrike temporal planner needs a self-resetting, looping scenario that can play continuously for demonstration and testing purposes without requiring manual restarts. Current scenarios (like the hostage rescue in ADR-047) are one-time events that end in success or failure states, making them unsuitable for continuous simulation.

A looping scenario is essential for:

- **Continuous Demonstration**: Running the temporal planner indefinitely at conferences, demos, or showcases
- **Long-term Testing**: Stress testing the temporal planner over extended periods
- **Performance Monitoring**: Observing system behavior and performance characteristics over time
- **Development Workflow**: Having a scenario that continues running during development iterations

## Decision

Implement a **"Training Ground"** scenario that automatically resets itself upon completion, creating a continuous loop of tactical engagement suitable for demonstration and testing.

### Scenario Design: Training Ground

**Setting**: A military training facility with rotating exercise configurations.

**Core Loop Pattern**:

1. **Setup Phase** (0-2s): Initialize training exercise with random configuration
2. **Engagement Phase** (2-20s): Execute tactical scenario with temporal constraints  
3. **Evaluation Phase** (20-22s): Assess performance and log results
4. **Reset Phase** (22-24s): Clean up and prepare for next iteration
5. **Loop Back**: Return to Setup Phase with new configuration

### Tactical Scenarios Pool

The training ground randomly selects from multiple sub-scenarios:

**Scenario A: Perimeter Defense**

- 3 defenders protect a central facility
- 2-4 attackers attempt infiltration from random entry points
- Success: Facility secured for 12 seconds
- Failure: Facility breached

**Scenario B: Asset Extraction**

- 2 operatives must extract valuable intel from contested zone
- 2-3 opponents guard the area with patrol patterns
- Success: Intel extracted within 15 seconds
- Failure: Operatives eliminated or time exceeded

**Scenario C: Convoy Ambush**

- 1 convoy vehicle follows predetermined route
- 2-3 ambushers position for optimal attack timing
- Success: Convoy eliminated or stopped
- Failure: Convoy reaches destination safely

### Self-Reset Mechanism

```elixir
# Training Ground State Cycle
defmodule TrainingGroundScenario do
  @cycle_duration 24.0  # seconds per complete cycle
  @engagement_duration 18.0  # active tactical phase
  
  def setup_phase(cycle_number) do
    scenario_type = select_random_scenario(cycle_number)
    initial_positions = generate_random_positions(scenario_type)
    objectives = create_scenario_objectives(scenario_type)
    
    %{
      scenario: scenario_type,
      positions: initial_positions,
      objectives: objectives,
      start_time: current_time(),
      cycle: cycle_number
    }
  end
  
  def check_reset_condition(state, current_time) do
    cycle_elapsed = current_time - state.start_time
    objectives_complete = all_objectives_resolved?(state.objectives)
    
    cond do
      objectives_complete -> :reset_immediately
      cycle_elapsed >= @cycle_duration -> :reset_timeout
      true -> :continue
    end
  end
end
```

### Continuous Metrics Collection

The looping scenario maintains running statistics:

- **Cycles Completed**: Total number of training iterations
- **Average Cycle Duration**: Time per complete cycle
- **Success Rates**: Win/loss ratios by scenario type
- **Performance Metrics**: Planning time, action execution efficiency
- **Agent Behavior Patterns**: Learning and adaptation over time

### Visual and Logging Considerations

**Console Output Pattern**:

```
[Cycle 1] Training Ground - Perimeter Defense
  → Setup complete (2.1s)
  → Engagement: Defenders positioned, attackers advancing
  → Resolution: Facility secured (14.3s total)
  → Performance: Planning 0.8s, Execution 13.5s
  → Reset initiated...

[Cycle 2] Training Ground - Asset Extraction  
  → Setup complete (1.9s)
  → Engagement: Operatives infiltrating, guards patrolling
  → Resolution: Intel extracted (12.1s total)
  → Performance: Planning 1.2s, Execution 10.9s
  → Reset initiated...
```

**Quiet Mode**: Configurable to reduce log spam during long-running demonstrations.

## Rationale

### Why Training Ground vs Other Looping Scenarios?

- **Thematically Consistent**: Military training exercises naturally reset and repeat
- **Variability**: Multiple sub-scenarios prevent repetitive demonstrations
- **Realistic Timing**: 24-second cycles provide sufficient complexity without being tedious
- **Performance Isolation**: Each cycle is independent, making performance measurement clean

### Why Self-Reset vs External Control?

- **Simplicity**: No external orchestration or manual intervention required
- **Reliability**: Eliminates potential for "stuck" states requiring manual restart
- **Demonstration Ready**: Can run indefinitely without supervision
- **Testing Utility**: Provides consistent, repeatable test conditions

### Benefits for Development

1. **Temporal Planner Testing**: Continuous stress testing of planning algorithms
2. **Performance Regression Detection**: Long-running performance monitoring
3. **Demo Readiness**: Always have a working demonstration available
4. **Development Feedback**: Immediate visibility into system behavior changes

## Implementation Priority

**Phase 1** (Immediate): Implement basic Training Ground with single scenario type
**Phase 2** (Near-term): Add multiple scenario types with random selection
**Phase 3** (Future): Add performance analytics and visualization

## Integration with Existing ADRs

- **Builds on ADR-047**: Uses similar timing patterns and agent interactions
- **Leverages ADR-045**: Utilizes Allen's Interval Algebra for scenario transitions
- **Supports ADR-048**: Provides continuous testing ground for developer-friendly APIs
- **Implements ADR-049**: Serves as practical application of enhanced temporal planner

## Consequences

### Positive

- Enables continuous demonstration and testing capabilities
- Provides comprehensive temporal planner validation
- Creates engaging, dynamic demonstration content
- Supports long-term system performance monitoring

### Negative  

- Additional complexity in scenario management
- Requires careful resource management to prevent memory leaks
- May mask temporal planner issues due to scenario variety

### Neutral

- Adds another scenario type to maintain alongside hostage rescue
- Requires configuration options for demonstration vs development use

## Success Criteria

1. **Continuous Operation**: Runs for 24+ hours without intervention
2. **Performance Stability**: No memory leaks or performance degradation over time
3. **Scenario Variety**: Multiple sub-scenarios with different tactical challenges
4. **Clean Metrics**: Clear performance and outcome tracking per cycle
5. **Demo Quality**: Visually engaging for presentations and showcases

The Training Ground scenario provides the foundation for continuous temporal planner operation, enabling both practical demonstration and comprehensive long-term testing of the TimeStrike tactical planning system.
