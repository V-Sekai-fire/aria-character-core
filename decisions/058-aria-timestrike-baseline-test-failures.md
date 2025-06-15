# ADR-058: Resolve aria_timestrike BaselineTest Failures

## Status

Active (Started: June 15, 2025)
**Priority**: Critical - blocking test suite completion

## Context

The `aria_timestrike` application has 4 critical test failures in its BaselineTest suite that are preventing successful test execution. These failures were identified during the test cleanup initiative (ADR-057) and represent fundamental functionality gaps that need immediate resolution.

### Identified Failures

From test run analysis, the following specific failures were detected:

1. **`test aria_timestrike basic actions are callable`**
   - Error: Invalid position format error
   - Impact: Basic action system not functional

2. **`test baseline performance benchmarks`**
   - Error: AriaEngine.State.add_fact/4 undefined
   - Impact: Core state management function missing

3. **`test current AriaEngine basic planning works`**
   - Error: Planner not functional
   - Impact: Planning system completely broken

4. **`test aria_engine temporal module structure`**
   - Error: AriaEngine.Temporal module missing
   - Impact: Temporal functionality not available

### Architecture Context

These failures indicate that the `aria_timestrike` module, which serves as a test domain for the temporal planning system, has become disconnected from the core `AriaEngine` functionality during recent architectural changes. The failures suggest missing or incorrectly referenced modules and functions that are essential for basic operation.

## Decision

We will systematically resolve each BaselineTest failure by:

1. **Implementing missing core functions**: Add the required `AriaEngine.State.add_fact/4` function
2. **Creating missing modules**: Implement `AriaEngine.Temporal` module with required functionality
3. **Fixing data format issues**: Resolve position format validation problems
4. **Restoring planner functionality**: Ensure basic planning operations work correctly

## Implementation Plan

### Phase 1: Core Infrastructure (Immediate)

- [ ] **Create AriaEngine.State.add_fact/4 function**
  - Implement the missing state management function
  - Ensure proper type specifications and documentation
  - Add basic error handling

- [ ] **Implement AriaEngine.Temporal module**
  - Create module structure with required temporal functions
  - Ensure compatibility with existing temporal planning design
  - Add proper module documentation

### Phase 2: Functionality Restoration (Short-term)

- [ ] **Fix position format validation**
  - Identify correct position format requirements
  - Update validation logic in basic actions
  - Ensure consistency across the system

- [ ] **Restore planner functionality**
  - Debug and fix basic planning operations
  - Ensure planner can handle simple test cases
  - Verify integration with temporal constraints

### Phase 3: Verification (Final)

- [ ] **Run complete BaselineTest suite**
  - Verify all 4 tests pass consistently
  - Ensure no regression in other test suites
  - Validate performance characteristics

## Implementation Guidelines

### Test-Driven Approach

- Fix one test at a time, starting with the most fundamental
- Verify each fix doesn't break existing functionality
- Commit each successful fix separately with descriptive messages

### Minimal Change Principle

- Implement only what's necessary to make tests pass
- Avoid over-engineering or extensive refactoring
- Focus on restoring existing functionality rather than adding features

### Documentation Requirements

- Document all new functions and modules
- Include type specifications for public interfaces
- Add inline comments for complex logic

## Consequences

### Positive

- Functional `aria_timestrike` test suite providing confidence in temporal planning
- Restored core AriaEngine functionality for state management and temporal operations
- Clear baseline for future temporal planning development
- Reduced technical debt in test infrastructure

### Negative

- Time investment required to implement missing functionality
- Potential complexity in understanding original design intent
- Risk of introducing new bugs while fixing existing issues

### Risks

- Incorrect implementation of missing functions could break other systems
- Test fixes might not address underlying architectural issues
- Performance impact from new implementations

## Success Criteria

- All 4 BaselineTest failures resolved and tests passing consistently
- No regression in other test suites
- `AriaEngine.State.add_fact/4` function properly implemented and documented
- `AriaEngine.Temporal` module created with required functionality
- Position format validation working correctly
- Basic planner functionality restored and operational

## Monitoring

- Track test pass/fail rates after each change
- Monitor for any new test failures introduced by fixes
- Verify compilation warnings don't increase
- Ensure test execution time remains reasonable

## Related ADRs

- **ADR-057**: Test Cleanup and Code Maintenance Plan (parent ADR)
- **ADR-034**: Definitive Temporal Planner Architecture
- **ADR-049**: Enhanced Temporal Planner Implementation

## Completion Timeline

**Target**: Complete within 1-2 development sessions
**Dependencies**: None (can proceed independently)
**Blockers**: Understanding original design intent for missing components

This ADR will be marked as "Completed" when all BaselineTest failures are resolved and the test suite passes consistently without regression in other areas.
