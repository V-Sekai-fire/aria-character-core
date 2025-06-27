# R25W0101F54: First Implementation Step - Test-Driven Development

<!-- @adr_serial R25W0101F54 -->

## Status

Accepted

## Context

The temporal planner implementation needs a clear starting point that ensures all components integrate properly while driving out exactly what's needed for the MVP.

## Decision

Start with writing tests - specifically the MVP acceptance test that drives out all required components.

## Rationale

- **Integration Focus**: Test-first approach prevents over-engineering and ensures component integration
- **Clear Requirements**: Failing test drives out exactly what's needed for MVP success
- **Momentum Building**: Each test pass provides concrete progress milestone
- **Risk Mitigation**: Comprehensive test prevents architectural issues and missing components

## Implementation

### First Test Strategy

- **Test File**: `test/aria_engine/conviction_crisis_integration_test.exs`
- **Test Scenario**: "Alex moves from {2,3} to {8,3} with real-time terminal display and SPACEBAR interruption"
- **Acceptance Criteria**: Matches exact 10-minute demo requirements from R25W009BCB5
- **Complete Integration**: Test forces all components to work together

### TDD Sequence

1. **Test Fails**: No modules exist yet
2. **Create Minimal**: Add just enough code to improve error messages
3. **Iterate**: Each test run reveals next missing piece
4. **Integrate**: Test forces all components to work together

### Implementation Order Driven by Test

1. `TemporalState` - As test needs state management
2. `GameActionJob` - As test needs action execution
3. `TimeStrike.WebInterface` - As test needs real-time display
4. `TimeStrike.GameEngine` - As test needs game loop
5. Mix task - As test needs entry point

## Test Structure

```elixir
test "MVP demo: Alex moves from {2,3} to {8,3} with real-time display and interruption" do
  # 1. Start game
  {:ok, game_pid} = TimeStrike.GameEngine.start_link()

  # 2. Verify Alex at {2,3}
  assert %{position: {2, 3, 0}} = TimeStrike.get_agent_state("alex")

  # 3. Verify auto-plan to {8,3}
  assert {:ok, plan} = TimeStrike.plan_to_goal({8, 3, 0})

  # 4. Watch real-time movement
  :timer.sleep(1000)
  assert %{position: {4, 3, 0}} = TimeStrike.get_agent_state("alex")

  # 5. Interrupt at {5,3}
  TimeStrike.interrupt_action("alex")

  # 6. Verify replanning
  assert {:ok, new_plan} = TimeStrike.get_current_plan()

  # 7. Complete movement to {8,3}
  :timer.sleep(2000)
  assert %{position: {8, 3, 0}} = TimeStrike.get_agent_state("alex")

  # 8. Verify "Mission Complete!"
  assert TimeStrike.mission_status() == :complete
end
```

## Alternative Starting Points Considered

### GameActionJob First

- **Risk**: Isolated component might not integrate properly
- **Benefit**: Lowest risk, builds on existing Oban infrastructure
- **Outcome**: Rejected in favor of integration-first approach

### TemporalState First

- **Risk**: Data structures might not match actual usage
- **Benefit**: Clear foundation for all other components
- **Outcome**: Rejected in favor of test-driven requirements

## Implementation Benefits

- **Exact Requirements**: Test defines exactly what needs to be built
- **No Over-Engineering**: Only build what's needed to pass the test
- **Integration Confidence**: Test proves all components work together
- **Clear Success Criteria**: Pass/fail test provides unambiguous milestone

## Consequences

### Positive

- Clear starting point with concrete success criteria
- Prevents over-engineering and scope creep
- Ensures component integration from the beginning
- Provides measurable progress milestones

### Negative

- Requires test-writing expertise before implementation
- May feel slow initially with failing tests
- Complex integration test may be harder to debug
- Requires complete understanding of desired behavior upfront

## Related Decisions

- Links to R25W009BCB5 (MVP Definition) for test scenario requirements
- Supports R25W00787B6 (Weekend Implementation Scope) with focused development
- Builds on R25W004DF1D (Mandatory Stability Verification) for validation approach
- Implements ADR-005 (TimeStrike Test Domain) as primary test scenario
- Enables R25W0135BA2 (Research Strategy) through implementation discovery
- Supports ADR-020 (Design Consistency Verification) with validated foundation
