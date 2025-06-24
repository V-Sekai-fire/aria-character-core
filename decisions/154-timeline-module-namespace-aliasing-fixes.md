# ADR-154: Timeline Module Namespace Aliasing Fixes

**Status:** Active  
**Date:** June 23, 2025  
**Priority:** HIGH

## Context

After the modularization effort in ADR-151, timeline test files contain namespace conflicts that prevent proper test execution. Test files reference `AriaEngine.Timeline` but the module is now located at `Timeline` in the `aria_temporal_planner` app.

**Current Issues:**
- Test imports use outdated `AriaEngine.Timeline` references
- Module aliasing conflicts in test helper files
- Compilation errors preventing test suite execution
- Inconsistent namespace usage across test files

**Impact:**
- Timeline test suite cannot execute properly
- Development workflow blocked for timeline functionality
- Quality assurance gaps in temporal planning system

## Decision

Systematically update all timeline test files to use the correct `Timeline` namespace and resolve module aliasing conflicts throughout the test suite.

## Implementation Plan

### Phase 1: Identify Namespace Issues (Day 1)

**File Analysis Required:**
- `apps/aria_temporal_planner/test/timeline/interval_iso8601_test.exs`
- `apps/aria_temporal_planner/test/timeline/internal/stn/operations_test.exs`
- `apps/aria_temporal_planner/test/temporal_planner/stn_method_test.exs`
- `apps/aria_temporal_planner/test/timeline/timeline_stn_capabilities_test.exs`
- All other test files in `apps/aria_temporal_planner/test/`

**Detection Patterns:**
- [ ] Find all `AriaEngine.Timeline` references
- [ ] Identify `alias AriaEngine.Timeline` statements
- [ ] Locate `import AriaEngine.Timeline` statements
- [ ] Check for mixed namespace usage within files

### Phase 2: Update Import Statements (Day 1)

**Namespace Corrections:**
- [ ] Replace `AriaEngine.Timeline` → `Timeline`
- [ ] Replace `AriaEngine.Timeline.Interval` → `Timeline.Interval`
- [ ] Replace `AriaEngine.Timeline.AgentEntity` → `Timeline.AgentEntity`
- [ ] Update any remaining `AriaEngine.*` temporal references

**Test Helper Updates:**
- [ ] Update `apps/aria_temporal_planner/test/test_helper.exs`
- [ ] Fix any shared test utilities with namespace conflicts
- [ ] Ensure consistent aliasing across all test files

### Phase 3: Verify Test Compilation (Day 1-2)

**Compilation Validation:**
- [ ] Run `cd apps/aria_temporal_planner && mix compile` to check for errors
- [ ] Fix any remaining compilation issues
- [ ] Ensure all test files compile without warnings

**Test Execution Validation:**
- [ ] Run `cd apps/aria_temporal_planner && mix test` to verify test execution
- [ ] Identify any runtime namespace errors
- [ ] Fix module resolution issues during test execution

### Phase 4: Clean Up Inconsistencies (Day 2)

**Consistency Improvements:**
- [ ] Standardize alias patterns across all test files
- [ ] Remove unused import statements
- [ ] Ensure consistent module reference style
- [ ] Update any documentation references in test comments

**Quality Assurance:**
- [ ] Run full test suite to verify no regressions
- [ ] Check for any remaining namespace-related warnings
- [ ] Validate test isolation and independence

## Success Criteria

### Critical Success
- [ ] All timeline test files compile without namespace errors
- [ ] Test suite executes without module resolution failures
- [ ] No `AriaEngine.Timeline` references remain in test files
- [ ] Consistent namespace usage across all test files

### Quality Success
- [ ] Clean compilation with zero warnings related to namespaces
- [ ] Test execution time improved (no module resolution overhead)
- [ ] Clear, consistent import patterns for future development
- [ ] Documentation updated to reflect correct namespace usage

## Implementation Strategy

### Step 1: Automated Detection
1. Use `grep -r "AriaEngine.Timeline" apps/aria_temporal_planner/test/` to find all references
2. Create comprehensive list of files requiring updates
3. Identify patterns for systematic replacement

### Step 2: Systematic Replacement
1. Update import and alias statements first
2. Replace module references in test code
3. Fix any qualified function calls using old namespace

### Step 3: Validation and Testing
1. Compile after each file update to catch issues early
2. Run individual test files to verify functionality
3. Execute full test suite to ensure no regressions

## Files Requiring Updates

**Primary Test Files:**
- `test/timeline/interval_iso8601_test.exs`
- `test/timeline/internal/stn/operations_test.exs`
- `test/temporal_planner/stn_method_test.exs`
- `test/timeline/timeline_stn_capabilities_test.exs`

**Supporting Files:**
- `test/test_helper.exs`
- Any additional test utilities or shared modules

**Documentation:**
- Test file comments and documentation strings
- README files referencing timeline testing

## Consequences

### Risks
- **Low:** Potential for introducing new test failures during updates
- **Low:** Risk of missing some namespace references in complex test files
- **Low:** Temporary test suite instability during transition

### Benefits
- **High:** Timeline test suite becomes executable and reliable
- **High:** Development workflow restored for timeline functionality
- **Medium:** Consistent namespace usage improves code maintainability
- **Medium:** Foundation for additional timeline testing improvements

## Related ADRs

- **ADR-151**: Strict Encapsulation Modular Testing Architecture (modularization foundation)
- **ADR-152**: Complete Temporal Relations System Implementation (superseded parent)
- **ADR-153**: STN Fixed-Point Constraint Prohibition (parallel timeline work)
- **ADR-155**: Hybrid Planner Test Suite Restoration (related testing issue)

## Monitoring

- **Compilation Success:** Zero namespace-related compilation errors
- **Test Execution:** Successful test suite execution without module resolution failures
- **Code Quality:** Consistent namespace usage across all timeline test files
- **Development Velocity:** Improved timeline development workflow efficiency

## Notes

This ADR addresses the immediate testing infrastructure issue that blocks timeline development. The namespace aliasing fixes are essential for restoring the timeline test suite and enabling further timeline testing improvements.

**Implementation Priority:** This is a prerequisite for all other timeline testing work and should be completed before proceeding with STN consistency fixes or other timeline improvements.

**Quick Win Potential:** These are straightforward find-and-replace operations that will immediately improve the timeline testing situation.
