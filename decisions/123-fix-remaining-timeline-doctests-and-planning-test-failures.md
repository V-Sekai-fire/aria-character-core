# ADR-123: Fix Remaining Timeline Doctests and Planning Test Failures

**Status:** Active  
**Date:** June 21, 2025  
**Priority:** HIGH

## Context

Test suite evaluation reveals two critical categories of failures that need immediate attention:

### Timeline Doctest Issues (7 failures)
Despite ADR-122 completion, `lib/aria_engine/timeline/interval.ex` still contains doctests using the old `Timeline.Interval.*` module references instead of `AriaEngine.Timeline.Interval.*`. These cause UndefinedFunctionError failures.

**Affected Doctests:**
- `Timeline.Interval.new/2` and `new/3` calls
- `Timeline.Interval.duration_ms/1`, `duration_seconds/1`, `duration_in_unit/2`
- `Timeline.Interval.contains?/2`, `agent?/1`, `entity?/1`
- `Timeline.Interval.to_stn_points/2`, `overlaps?/2`, `allen_relation/2`
- `Timeline.Interval.from_duration/3`

### Planning Strategy Test Failures (3 failures)
`test/aria_engine/plan/lazy_execution_test.exs` shows systematic failures in Plan.Core.run_lazy_refineahead functionality:

**Failed Tests:**
1. **Basic Functionality** - `{:error, "No complete solution found"}` instead of successful planning
2. **Failure Handling** - Robot location remains "start" instead of reaching "goal"  
3. **Strategy Integration** - Same "No complete solution found" error

### Additional Issues
- **Unused variable warning** in `lib/aria_engine/timeline/bridge.ex:227` (`sorted2`)
- **Model inconsistency warnings** from MiniZinc temporal solver

## Decision

**Implement sequential fixes prioritizing Timeline doctests first, then re-evaluate planning strategy failures** to restore test suite health using the established fully qualified module naming strategy from ADR-122.

### Sequential Implementation Strategy

**Phase 1 (IMMEDIATE):** Fix all Timeline doctest issues using ADR-122's "no aliases" approach  
**Phase 2 (CONDITIONAL):** Re-evaluate planning failures only after Phase 1 completion to determine if issues persist independently

## Implementation Plan

### Phase 1: Fix Timeline Interval Doctests (PRIORITY: HIGH)

**File to Update:**
- [ ] `lib/aria_engine/timeline/interval.ex` - Convert all remaining doctest examples

**Doctest Conversion Patterns:**
- [ ] Replace `Timeline.Interval.new/2` → `AriaEngine.Timeline.Interval.new/2`
- [ ] Replace `Timeline.Interval.new/3` → `AriaEngine.Timeline.Interval.new/3`
- [ ] Replace `Timeline.Interval.duration_ms/1` → `AriaEngine.Timeline.Interval.duration_ms/1`
- [ ] Replace `Timeline.Interval.duration_seconds/1` → `AriaEngine.Timeline.Interval.duration_seconds/1`
- [ ] Replace `Timeline.Interval.contains?/2` → `AriaEngine.Timeline.Interval.contains?/2`
- [ ] Replace `Timeline.Interval.agent?/1` → `AriaEngine.Timeline.Interval.agent?/1`
- [ ] Replace `Timeline.Interval.entity?/1` → `AriaEngine.Timeline.Interval.entity?/1`
- [ ] Replace `Timeline.Interval.duration_in_unit/2` → `AriaEngine.Timeline.Interval.duration_in_unit/2`
- [ ] Replace `Timeline.Interval.from_duration/3` → `AriaEngine.Timeline.Interval.from_duration/3`
- [ ] Replace `Timeline.Interval.to_stn_points/2` → `AriaEngine.Timeline.Interval.to_stn_points/2`
- [ ] Replace `Timeline.Interval.overlaps?/2` → `AriaEngine.Timeline.Interval.overlaps?/2`
- [ ] Replace `Timeline.Interval.allen_relation/2` → `AriaEngine.Timeline.Interval.allen_relation/2`

### Phase 2: Investigate Planning Strategy Failures (PRIORITY: HIGH)

**Analysis Tasks:**
- [ ] Examine Plan.Core.plan/3 implementation for "No complete solution found" errors
- [ ] Review lazy execution strategy integration with HybridCoordinatorV2
- [ ] Check domain and initial state setup in failing tests
- [ ] Verify task decomposition and goal achievement logic

**Test Files to Investigate:**
- [ ] `test/aria_engine/plan/lazy_execution_test.exs` - All 3 failing tests
- [ ] `lib/aria_engine/plan/core.ex` - Core planning logic
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/lazy_execution_strategy.ex` - Strategy implementation

### Phase 3: Fix Minor Issues (PRIORITY: MEDIUM)

**Code Quality Fixes:**
- [ ] Fix unused variable `sorted2` in `lib/aria_engine/timeline/bridge.ex:227`
- [ ] Investigate MiniZinc model inconsistency warnings
- [ ] Verify all doctests pass after Timeline fixes

### Phase 4: Comprehensive Validation (PRIORITY: HIGH)

**Validation Steps:**
- [ ] Run `mix test --max-failures 20` to verify Timeline doctest fixes
- [ ] Run specific planning tests: `mix test test/aria_engine/plan/lazy_execution_test.exs`
- [ ] Run full test suite to ensure no regressions
- [ ] Verify compilation with `mix compile --warnings-as-errors`

## Implementation Strategy

### Step 1: Timeline Doctest Fixes (IMMEDIATE PRIORITY)
1. Apply ADR-122's "no aliases" strategy to `lib/aria_engine/timeline/interval.ex`
2. Use systematic search and replace: `Timeline.Interval.*` → `AriaEngine.Timeline.Interval.*`
3. Test doctests specifically: `mix test --only doctest`
4. Verify no remaining `Timeline.Interval.*` references
5. **CHECKPOINT:** Confirm 7 doctest failures resolved before proceeding

### Step 2: Re-evaluate Planning Strategy (CONDITIONAL)
1. **Only proceed after Step 1 completion**
2. Re-run full test suite to assess remaining failures
3. If planning failures persist, then investigate:
   - Plan.Core.plan/3 logic and error conditions
   - Domain setup and initial state in failing tests
   - Lazy execution strategy integration issues
4. **Decision Point:** Determine if planning issues are independent or were Timeline-related

### Step 3: Sequential Validation Approach
- **Phase 1 Complete:** Timeline doctests fixed, 7/10 failures resolved
- **Phase 2 Assessment:** Re-evaluate if 3 planning failures still exist
- **Targeted Investigation:** Only investigate planning if issues persist independently

## Success Criteria

- [ ] All Timeline.Interval doctests pass without UndefinedFunctionError
- [ ] Plan.Core.run_lazy_refineahead tests execute successfully
- [ ] Robot reaches "goal" location in failure handling test
- [ ] No "No complete solution found" errors in basic planning scenarios
- [ ] Unused variable warning eliminated
- [ ] Full test suite runs without the current 10 failures
- [ ] `mix compile --warnings-as-errors` passes cleanly

## Risks and Mitigation

**Risk:** Planning failures indicate deeper architectural issues
**Mitigation:** Start with simple test case analysis and incremental debugging

**Risk:** Timeline fixes might reveal additional module reference issues
**Mitigation:** Use comprehensive search patterns and test thoroughly

**Risk:** MiniZinc inconsistencies might affect temporal planning
**Mitigation:** Document temporal solver issues for future investigation

## Current Focus

**IMMEDIATE PRIORITY: Phase 1 Only** - Timeline doctest fixes using ADR-122's fully qualified strategy. Phase 2 planning investigation is **CONDITIONAL** and will only proceed after Phase 1 completion and re-evaluation of remaining test failures.

**Next Action:** Apply systematic `Timeline.Interval.*` → `AriaEngine.Timeline.Interval.*` replacements in `lib/aria_engine/timeline/interval.ex` doctests.

## Related ADRs

- **ADR-122**: Fix Timeline module aliasing issues (completed, but missed interval.ex doctests)
- **ADR-121**: Lazy execution strategy implementation (may be related to planning failures)
- **ADR-118**: Add typespecs to all lib code (code quality improvements)

## Progress Tracking

**Phase 1 Progress:** 0% - Timeline doctest fixes pending  
**Phase 2 Progress:** 0% - Planning strategy investigation pending  
**Phase 3 Progress:** 0% - Minor issue fixes pending  
**Phase 4 Progress:** 0% - Validation pending  

**Overall Completion:** 0% (All tasks pending)
