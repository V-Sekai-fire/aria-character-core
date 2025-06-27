# ADR-155: Hybrid Planner Test Suite Restoration

<!-- @adr_serial R25W00443D0 -->

**Status:** Active (Paused)  
**Date:** June 23, 2025  
**Priority:** MEDIUM

## Context

The `aria_hybrid_planner` app has no test suite ("There are no tests to run"), indicating that the test migration during modularization (ADR-151) was incomplete. This creates a critical quality assurance gap for hybrid planning functionality.

**Current Issues:**

- Complete absence of test coverage for hybrid planner functionality
- No validation for PlannerAdapter interface that aria_scheduler depends on
- Missing test suite prevents verification of hybrid planner extraction
- Quality assurance gap for multi-goal optimization and temporal planning

**Impact:**

- Cannot verify hybrid planner functionality works correctly
- Integration issues with aria_scheduler cannot be debugged effectively
- Risk of undetected regressions in planning algorithms
- Development workflow lacks feedback for hybrid planner changes

## Decision

Restore comprehensive test coverage for the hybrid planner by migrating existing tests and creating new test suites for extracted functionality.

## Implementation Plan

### Phase 1: Locate Original Test Files (Day 1)

**Test Archaeology:**

- [ ] Search for hybrid planner tests in git history before modularization
- [ ] Check `test/aria_engine/` directories in previous commits
- [ ] Identify test files that should have been migrated to `apps/aria_hybrid_planner/test/`
- [ ] Document test coverage gaps that need new implementation

**Expected Test Categories:**

- [ ] Strategy factory and coordination tests
- [ ] Multi-goal optimization algorithm tests
- [ ] PlannerAdapter interface contract tests
- [ ] Hybrid planning workflow integration tests

### Phase 2: Create Test Infrastructure (Day 1-2)

**Test Directory Structure:**

```
apps/aria_hybrid_planner/test/
├── test_helper.exs
├── hybrid_planner/
│   ├── strategy_test.exs
│   ├── factory_test.exs
│   └── coordinator_test.exs
├── plan/
│   ├── execution_test.exs
│   ├── backtracking_test.exs
│   └── optimization_test.exs
└── planner_adapter_test.exs
```

**Test Helper Setup:**

- [ ] Create `apps/aria_hybrid_planner/test/test_helper.exs`
- [ ] Configure ExUnit for hybrid planner testing
- [ ] Set up test dependencies and aliases
- [ ] Ensure proper test isolation

### Phase 3: Migrate Existing Tests (Day 2-3)

**Test Migration Strategy:**

- [ ] Recover hybrid planner tests from git history
- [ ] Update namespace references for modularized structure
- [ ] Fix dependency imports for new app structure
- [ ] Adapt tests for current hybrid planner API

**Key Test Areas to Migrate:**

- [ ] Strategy pattern tests for different planning approaches
- [ ] Factory pattern tests for strategy instantiation
- [ ] Coordination tests for multi-goal planning
- [ ] Integration tests for planning workflow

### Phase 4: Create Missing Test Coverage (Day 3-4)

**PlannerAdapter Interface Tests:**

- [ ] Test contract compliance for aria_scheduler integration
- [ ] Validate `plan_tasks/2` function implementation
- [ ] Test error handling and edge cases
- [ ] Verify interface stability and backwards compatibility

**Strategy Factory Tests:**

- [ ] Test strategy selection logic
- [ ] Validate strategy instantiation patterns
- [ ] Test factory configuration and customization
- [ ] Verify strategy lifecycle management

**Hybrid Coordination Tests:**

- [ ] Test multi-goal optimization algorithms
- [ ] Validate temporal constraint coordination
- [ ] Test resource allocation and scheduling
- [ ] Verify planning result consistency

### Phase 5: Integration and Validation (Day 4-5)

**Test Suite Validation:**

- [ ] Run `cd apps/aria_hybrid_planner && mix test` to verify execution
- [ ] Ensure all tests pass with current implementation
- [ ] Fix any test failures or implementation gaps
- [ ] Validate test isolation and independence

**Cross-App Integration Tests:**

- [ ] Test hybrid planner integration with aria_temporal_planner
- [ ] Validate PlannerAdapter contract with aria_scheduler
- [ ] Test end-to-end planning workflows
- [ ] Verify proper error propagation between apps

## Success Criteria

### Critical Success

- [ ] Hybrid planner has comprehensive test suite with >80% coverage
- [ ] All tests pass consistently without flakiness
- [ ] PlannerAdapter interface fully tested and validated
- [ ] Test suite executes in under 10 seconds for fast feedback

### Quality Success

- [ ] Test coverage includes all major hybrid planner functionality
- [ ] Integration tests validate cross-app contracts
- [ ] Test suite provides clear feedback for development workflow
- [ ] Documentation explains test organization and execution

## Implementation Strategy

### Step 1: Archaeological Recovery

1. Use `git log --follow --patch` to trace test file history
2. Identify commits where hybrid planner tests existed
3. Extract relevant test code from historical commits
4. Document test coverage that was lost during modularization

### Step 2: Test Infrastructure Setup

1. Create proper test directory structure
2. Set up test helper with appropriate configuration
3. Ensure test isolation and proper dependency management
4. Configure test execution environment

### Step 3: Systematic Test Creation

1. Start with PlannerAdapter tests (critical for aria_scheduler)
2. Add strategy factory tests for core functionality
3. Implement coordination tests for multi-goal planning
4. Create integration tests for end-to-end workflows

## Test Categories and Coverage

### Core Functionality Tests

- **Strategy Pattern**: Different planning approaches and algorithms
- **Factory Pattern**: Strategy instantiation and configuration
- **Coordination Logic**: Multi-goal optimization and resource allocation
- **Planning Execution**: Workflow orchestration and result generation

### Interface Contract Tests

- **PlannerAdapter**: aria_scheduler integration contract
- **Temporal Integration**: aria_temporal_planner coordination
- **Error Handling**: Graceful failure and recovery patterns
- **Configuration**: Planning parameter validation and defaults

### Integration Tests

- **Cross-App Workflows**: End-to-end planning scenarios
- **Dependency Validation**: Proper app boundary respect
- **Performance**: Planning algorithm efficiency and scalability
- **Regression**: Prevention of functionality degradation

## Consequences

### Risks

- **Medium:** Time investment required to recreate comprehensive test coverage
- **Low:** Potential for discovering implementation gaps during test creation
- **Low:** Risk of test suite becoming maintenance burden if over-engineered

### Benefits

- **High:** Quality assurance restored for critical planning functionality
- **High:** Development workflow improved with fast feedback
- **Medium:** Integration issues with aria_scheduler can be debugged effectively
- **Medium:** Foundation for future hybrid planner enhancements

## Related ADRs

- **ADR-151**: Strict Encapsulation Modular Testing Architecture (modularization foundation)
- **ADR-152**: Complete Temporal Relations System Implementation (superseded parent)
- **ADR-154**: Timeline Module Namespace Aliasing Fixes (parallel testing work)
- **ADR-156**: Cross-App Scheduler Dependencies (related integration issue)

## Monitoring

- **Test Coverage**: Percentage of hybrid planner code covered by tests
- **Test Execution Time**: Fast feedback for development workflow
- **Test Stability**: Consistent pass rate without flakiness
- **Integration Health**: Cross-app contract validation success rate

## Notes

This ADR addresses a critical quality assurance gap that was created during the modularization process. The hybrid planner is a core component for multi-goal optimization and temporal planning, making comprehensive test coverage essential.

**Implementation Priority:** This work should proceed in parallel with namespace fixes (ADR-154) and can help identify integration issues with the scheduler (ADR-156).

**Quality Focus:** The test suite should prioritize the PlannerAdapter interface first, as this is blocking aria_scheduler functionality.
