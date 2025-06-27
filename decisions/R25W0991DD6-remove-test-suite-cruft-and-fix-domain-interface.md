# R25W0991DD6: Remove Test Suite Cruft and Fix Domain Interface

<!-- @adr_serial R25W0991DD6 -->

## Status

**Active** (June 22, 2025)

## Context

The test suite is severely polluted with cruft that makes development difficult:

### Current Issues

1. **3 Test Failures** - All caused by missing `methods/0` function in `AriaEngine.SoftwareDevelopment.Domain`
   - `AriaEngine.SoftwareDevelopment.DomainTest`
   - `AriaEngine.SoftwareDevelopment.MinimalDomainTest`
   - `AriaEngine.GltfKhrInteractivity.PlanningTest`

2. **20+ Deprecation Warnings** - Timeline.Interval API using DateTime instead of ISO 8601 strings
   - `AriaEngine.Timeline.Interval.new/2` with DateTime structs is deprecated
   - `AriaEngine.Timeline.Interval.new/3` with DateTime structs is deprecated
   - Should use `new_fixed_schedule/2` and `new_fixed_schedule/3` with ISO 8601 strings

3. **Minor Warning Cruft** - Unused alias warnings in test files

### Root Cause Analysis

**Test Failures**: `AriaEngine.Domain.from_module/1` expects domain modules to implement both:

- `actions/0` function ✅ (exists)
- `methods/0` function ❌ (missing!)

**Deprecation Warnings**: Legacy Timeline.Interval API usage throughout test suite pollutes output and obscures real issues.

## Decision

Implement systematic cruft removal in three phases to restore clean test output and fix all test failures.

## Implementation Plan

### Phase 1: Fix Domain Interface (HIGH PRIORITY)

**File**: `lib/aria_engine/software_development/domain.ex`

**Missing/Required**:

- [ ] Add `methods/0` function returning method names list
- [ ] Return: `["develop_module", "develop_system", "achieve_goal"]`

**Expected Result**: Fixes all 3 test failures immediately

### Phase 2: Remove Timeline Deprecation Warnings (MEDIUM PRIORITY)

**Target Files**: Multiple test files using deprecated Timeline.Interval API

**Missing/Required**:

- [ ] Replace `AriaEngine.Timeline.Interval.new/2` with `new_fixed_schedule/2`
- [ ] Replace `AriaEngine.Timeline.Interval.new/3` with `new_fixed_schedule/3`
- [ ] Convert DateTime arguments to ISO 8601 strings
- [ ] Target files: timeline tests, bridge tests, scenario tests, entity manager

**Expected Result**: Eliminates 20+ deprecation warnings per test run

### Phase 3: Clean Minor Warnings (LOW PRIORITY)

**File**: `test/aria_engine/unified_durative_action_tdd_test.exs`

**Missing/Required**:

- [ ] Remove unused `alias AriaEngine.StateV2` on line 5

## Implementation Strategy

### Step 1: Domain Interface Fix

1. Add missing `methods/0` function to `SoftwareDevelopment.Domain`
2. Verify test failures are resolved
3. Commit domain interface fix

### Step 2: Systematic Deprecation Warning Cleanup

1. Identify all files using deprecated Timeline.Interval API
2. Replace deprecated calls with new ISO 8601 API
3. Convert DateTime arguments to ISO 8601 strings
4. Test and verify warnings are eliminated

### Step 3: Minor Warning Cleanup

1. Remove unused aliases and imports
2. Verify clean test output

### Current Focus: Phase 1 - Domain Interface Fix

**INVESTIGATION UPDATE (June 22, 2025)**:

After detailed investigation, the issue is **NOT** a missing `methods/0` function. The function exists and is working correctly. The real issue is deeper in the planner logic:

**Root Cause Discovered**:

1. ✅ `methods/0` function exists and returns correct method names
2. ✅ `develop_module` method is called successfully and returns correct task decomposition
3. ❌ **Planner fails to find complete solution** - Actions are never executed
4. ❌ **HTN Planning Strategy** reports "No complete solution found" during planning phase

**Evidence from Test Logs**:

```
DEVELOP_MODULE returning: [[implement_module: ["gltf_buffer"], test_implementation: ["gltf_buffer"], document_module: ["gltf_buffer"], verify_typespecs: ["gltf_buffer"]]]
Method succeeded, created 1 subtasks
PLAN_DECOMPOSITION_LOOP: No complete solution found after all nodes expanded.
```

**Real Issue**: The planner creates the correct task decomposition but fails to find a valid execution path through the actions. This suggests:

- Action preconditions may be too restrictive
- Planner forward search cannot determine action executability
- Missing goal state definition for planning termination

**Next Steps**:

1. Investigate action precondition logic
2. Check if planner needs explicit goal states
3. Verify action execution path validation

Starting with the domain interface fix as it immediately resolves all 3 test failures and unblocks development workflow.

## Success Criteria

- [ ] All 3 test failures resolved
- [ ] Zero deprecation warnings in test output  
- [ ] Zero unused alias warnings
- [ ] Clean, readable test results
- [ ] `mix test` runs without cruft pollution

## Consequences

### Positive

- **Clean Development Experience**: Test output becomes readable and actionable
- **Faster Issue Detection**: Real problems are immediately visible without noise
- **Improved Workflow**: Developers can focus on actual issues rather than filtering cruft
- **Future-Proof API Usage**: Modern Timeline.Interval API prevents future deprecation issues

### Risks

- **API Migration Effort**: Converting DateTime to ISO 8601 strings requires careful testing
- **Potential Breaking Changes**: Ensure new API calls maintain same functionality

## Related ADRs

- **R25W02708D3**: Test cleanup and code maintenance
- **R25W0765579**: Add typespecs to all lib code
- **R25W09080DB**: Fix duration handling precision loss

## Monitoring

Track progress through:

- Test failure count (target: 0)
- Deprecation warning count (target: 0)
- Test output cleanliness
- Developer feedback on test experience
