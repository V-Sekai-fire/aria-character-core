# ADR-157: STN Consistency Test Recovery

<!-- @adr_serial R25W0062A76 -->

**Status:** Active (Paused)  
**Date:** June 23, 2025  
**Priority:** HIGH

## Context

After fixing fixed-point constraint violations (ADR-153), 11 STN consistency test failures remain in aria_temporal_planner. The STN consistency detection logic incorrectly marks valid micro-range constraints as inconsistent, preventing proper temporal reasoning validation.

**Current Issues:**

- STNs with valid micro-range constraints `{-1, 1}` marked as inconsistent
- Consistency checking logic doesn't handle micro-ranges properly
- Test failures prevent validation of core temporal reasoning functionality
- STN solver reports `consistent: false` for mathematically valid constraint sets

**Impact:**

- Cannot verify STN temporal reasoning works correctly
- Timeline functionality validation blocked
- Development workflow lacks feedback for temporal constraint changes
- Risk of undetected regressions in temporal planning algorithms

## Decision

Fix the STN consistency detection logic to properly handle micro-range constraints and restore reliable temporal reasoning validation.

## Implementation Plan

### Phase 1: Analyze Consistency Detection Logic (Day 1)

**Root Cause Investigation:**

- [ ] Examine STN consistency checking algorithm in `timeline/internal/stn/core.ex`
- [ ] Identify why micro-ranges `{-1, 1}` are marked as inconsistent
- [ ] Document expected vs actual behavior for consistency detection
- [ ] Map consistency failures to specific constraint patterns

**Consistency Algorithm Analysis:**

- [ ] Review Floyd-Warshall implementation for constraint propagation
- [ ] Check negative cycle detection logic
- [ ] Validate constraint intersection and tightening operations
- [ ] Identify mathematical correctness of micro-range handling

### Phase 2: Fix Consistency Detection (Day 1-2)

**File:** `apps/aria_temporal_planner/lib/timeline/internal/stn/core.ex`

- [ ] Fix consistency checking to properly handle micro-ranges
- [ ] Update negative cycle detection for small constraint ranges
- [ ] Ensure constraint propagation works correctly with `{-1, 1}` ranges
- [ ] Validate mathematical correctness of updated algorithm

**Consistency Logic Updates:**

```elixir
defp detect_negative_cycle(constraints) do
  # Updated logic to handle micro-ranges properly
  # Ensure {-1, 1} constraints don't trigger false negatives
end

defp propagate_constraints(stn) do
  # Fixed constraint propagation for micro-ranges
  # Maintain mathematical correctness while handling small ranges
end
```

### Phase 3: Update Constraint Intersection Logic (Day 2)

**File:** `apps/aria_temporal_planner/lib/timeline/internal/stn/operations.ex`

- [ ] Fix constraint intersection to handle micro-ranges correctly
- [ ] Update constraint tightening operations
- [ ] Ensure proper handling of constraint composition
- [ ] Validate intersection results for edge cases

**Intersection Improvements:**

- [ ] Handle `{-1, 1} ∩ {-1, 1} = {-1, 1}` correctly
- [ ] Ensure micro-range intersections don't create inconsistencies
- [ ] Validate constraint composition maintains consistency
- [ ] Fix any floating-point precision issues

### Phase 4: Validate Test Cases (Day 2-3)

**Test Analysis:**

- [ ] Identify specific test cases that fail consistency checks
- [ ] Document expected STN states for each failing test
- [ ] Validate that test expectations are mathematically correct
- [ ] Update test assertions if necessary

**Test Categories:**

- [ ] Basic STN consistency with micro-ranges
- [ ] Constraint propagation with small ranges
- [ ] Timeline integration with STN consistency
- [ ] Edge cases and boundary conditions

### Phase 5: Integration and Validation (Day 3-4)

**STN Validation:**

- [ ] Run `cd apps/aria_temporal_planner && mix test` to verify fixes
- [ ] Ensure all 11 consistency failures are resolved
- [ ] Validate STN consistency detection accuracy
- [ ] Test performance impact of consistency fixes

**Timeline Integration:**

- [ ] Test Timeline.consistent?/1 function with fixed STN
- [ ] Validate temporal reasoning workflows
- [ ] Ensure Bridge layer integration works correctly
- [ ] Test end-to-end temporal constraint solving

## Success Criteria

### Critical Success

- [ ] All 11 STN consistency test failures resolved
- [ ] STN consistency detection accurate for micro-range constraints
- [ ] Timeline.consistent?/1 returns correct results
- [ ] No false positive or false negative consistency reports

### Quality Success

- [ ] STN consistency checking performance maintained or improved
- [ ] Clear documentation of consistency algorithm behavior
- [ ] Comprehensive test coverage for consistency edge cases
- [ ] Reliable temporal reasoning validation workflow

## Implementation Strategy

### Step 1: Algorithm Analysis

1. Trace through failing test cases to identify exact failure points
2. Analyze Floyd-Warshall implementation for micro-range handling
3. Document mathematical requirements for consistency detection
4. Identify specific code changes needed

### Step 2: Consistency Logic Fixes

1. Update negative cycle detection for micro-ranges
2. Fix constraint propagation algorithm
3. Ensure mathematical correctness of updated logic
4. Test fixes with isolated constraint sets

### Step 3: Integration Testing

1. Run individual test cases to verify fixes
2. Test STN consistency with various constraint patterns
3. Validate Timeline integration with fixed STN
4. Ensure no regressions in temporal reasoning

## Technical Details

### STN Consistency Requirements

- **Negative Cycle Detection**: No negative cycles in constraint graph
- **Constraint Propagation**: Floyd-Warshall algorithm correctness
- **Micro-Range Handling**: Proper treatment of `{-1, 1}` constraints
- **Mathematical Validity**: Consistent with temporal logic requirements

### Micro-Range Considerations

- **Self-Reference Constraints**: `{-1, 1}` for point equality
- **Fixed Duration**: `{n-1, n+1}` for near-fixed timing
- **Allen Relations**: Micro-ranges for temporal adjacency
- **Constraint Composition**: Proper intersection and propagation

### Performance Requirements

- **Consistency Checking**: Sub-millisecond for typical constraint sets
- **Memory Usage**: Linear in number of time points
- **Scalability**: Handle hundreds of temporal constraints efficiently
- **Reliability**: Deterministic results for identical constraint sets

## Test Cases to Fix

### Basic Consistency Tests

- STN with only micro-range constraints
- Mixed micro-range and normal range constraints
- Self-referential constraints with micro-ranges
- Temporal adjacency with micro-ranges

### Integration Tests

- Timeline consistency with STN micro-ranges
- Bridge layer constraint generation validation
- End-to-end temporal reasoning workflows
- Performance tests with large constraint sets

### Edge Cases

- Empty STN consistency
- Single time point STN
- Highly connected constraint graphs
- Boundary conditions for constraint ranges

## Consequences

### Risks

- **Low:** Potential for introducing new consistency detection bugs
- **Low:** Performance impact from algorithm changes
- **Low:** Risk of breaking existing temporal reasoning functionality

### Benefits

- **High:** Reliable STN consistency validation restored
- **High:** Timeline temporal reasoning functionality validated
- **Medium:** Development workflow improved with accurate feedback
- **Medium:** Foundation for advanced temporal reasoning features

## Related ADRs

- **ADR-153**: STN Fixed-Point Constraint Prohibition (prerequisite)
- **ADR-152**: Complete Temporal Relations System Implementation (superseded parent)
- **ADR-154**: Timeline Module Namespace Aliasing Fixes (parallel testing work)
- **ADR-158**: Comprehensive Timeline Test Suite Validation (follow-up)

## Monitoring

- **Test Success Rate**: aria_temporal_planner STN test pass rate (target: 100%)
- **Consistency Accuracy**: Correct consistency detection for all constraint patterns
- **Performance**: STN consistency checking execution time
- **Reliability**: Deterministic consistency results across test runs

## Notes

This ADR addresses the remaining STN consistency issues after fixed-point constraint elimination. The consistency detection logic must properly handle micro-range constraints while maintaining mathematical correctness.

**Implementation Priority:** This is a high-priority follow-up to ADR-153 and is essential for validating temporal reasoning functionality.

**Mathematical Focus:** The consistency algorithm must be mathematically sound while handling the edge cases introduced by micro-range constraints.
