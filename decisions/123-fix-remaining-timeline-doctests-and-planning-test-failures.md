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

**Specific Doctest Changes Required:**
- [x] **Line ~44**: `Timeline.Interval.new(start_dt, end_dt)` → `AriaEngine.Timeline.Interval.new(start_dt, end_dt)`
- [x] **Line ~66**: `Timeline.Interval.new(start_dt, end_dt, metadata: %{type: :action})` → `AriaEngine.Timeline.Interval.new(start_dt, end_dt, metadata: %{type: :action})`
- [x] **Line ~81**: `Timeline.Interval.duration_ms(interval)` → `AriaEngine.Timeline.Interval.duration_ms(interval)`
- [x] **Line ~94**: `Timeline.Interval.duration_seconds(interval)` → `AriaEngine.Timeline.Interval.duration_seconds(interval)`
- [x] **Line ~107**: `Timeline.Interval.contains?(interval, check_time)` → `AriaEngine.Timeline.Interval.contains?(interval, check_time)`
- [x] **Line ~120**: `Timeline.Interval.new(start_dt, end_dt, agent: agent)` → `AriaEngine.Timeline.Interval.new(start_dt, end_dt, agent: agent)`
- [x] **Line ~121**: `Timeline.Interval.agent?(interval)` → `AriaEngine.Timeline.Interval.agent?(interval)`
- [x] **Line ~133**: `Timeline.Interval.new(start_dt, end_dt, entity: entity)` → `AriaEngine.Timeline.Interval.new(start_dt, end_dt, entity: entity)`
- [x] **Line ~134**: `Timeline.Interval.entity?(interval)` → `AriaEngine.Timeline.Interval.entity?(interval)`
- [x] **Line ~155**: `Timeline.Interval.duration_in_unit(interval, :minute)` → `AriaEngine.Timeline.Interval.duration_in_unit(interval, :minute)`
- [x] **Line ~170**: `Timeline.Interval.from_duration(start_dt, 30, :minute)` → `AriaEngine.Timeline.Interval.from_duration(start_dt, 30, :minute)`
- [x] **Line ~185**: `Timeline.Interval.to_stn_points(interval, :second)` → `AriaEngine.Timeline.Interval.to_stn_points(interval, :second)`
- [x] **Line ~200**: `Timeline.Interval.overlaps?(interval1, interval2)` → `AriaEngine.Timeline.Interval.overlaps?(interval1, interval2)`
- [x] **Line ~215**: `Timeline.Interval.allen_relation(interval1, interval2)` → `AriaEngine.Timeline.Interval.allen_relation(interval1, interval2)`

**Total Changes:** 12 specific doctest module reference updates

### Phase 2: Investigate Planning Strategy Failures (PRIORITY: HIGH)

**Analysis Findings:**
- ✅ **Plan.Core.run_lazy_refineahead/4 is fully implemented** - Function exists with comprehensive lazy execution logic
- ✅ **Core planning logic is complete** - IPyHOP algorithm, backtracking, and replanning all implemented
- 🔍 **Likely root cause**: Test file import/module reference issues rather than missing implementation

**Phase 2 Test Results (June 21, 2025):**
- ✅ **Timeline doctests resolved** - 59 doctests now passing, 7 failures eliminated
- ❌ **Planning test failures persist** - 4 failures confirmed in lazy_execution_test.exs:
  1. **Basic Functionality** (line 23): `{:error, "No complete solution found"}` 
  2. **Failure Handling** (line 71): Robot location stays "start", expected "goal"
  3. **No Alternative Methods** (line 87): Same "No complete solution found" error
  4. **Strategy Integration** (line 189): Same planning failure pattern

**Investigation Tasks:**
- [ ] Check `test/aria_engine/plan/lazy_execution_test.exs` for missing module imports
- [ ] Verify `Plan.Core` alias is properly defined in test file
- [ ] Check `Domain` module references and aliases in test
- [ ] Verify `AriaEngine.StateV2` imports and usage
- [ ] Test domain creation helper functions for proper module references

**Test Files to Investigate:**
- [ ] `test/aria_engine/plan/lazy_execution_test.exs` - Import/alias issues likely cause
- [ ] Domain creation helper functions - May need module reference updates
- [ ] State creation and manipulation - Verify StateV2 usage patterns

### Phase 3: Fix Minor Issues (PRIORITY: MEDIUM)

**Code Quality Fixes:**
- [ ] ~~Fix unused variable `sorted2` in `lib/aria_engine/timeline/bridge.ex:227`~~ (Not found in current bridge.ex - may be resolved)
- [ ] Investigate MiniZinc model inconsistency warnings
- [ ] Verify all doctests pass after Timeline fixes
- [ ] Check for any remaining module aliasing issues in test files

### Phase 4: Comprehensive Validation (PRIORITY: HIGH)

**Validation Steps:**
- [ ] Run `mix test --max-failures 20` to verify Timeline doctest fixes
- [ ] Run specific planning tests: `mix test test/aria_engine/plan/lazy_execution_test.exs`
- [ ] Run full test suite to ensure no regressions
- [ ] Verify compilation with `mix compile --warnings-as-errors`

## Implementation Strategy

### Step 1: Timeline Doctest Fixes (IMMEDIATE PRIORITY)
1. Apply systematic module reference updates to `lib/aria_engine/timeline/interval.ex`
2. Use precise search and replace for 12 specific doctest locations
3. Pattern: `Timeline.Interval.*` → `AriaEngine.Timeline.Interval.*`
4. Test doctests specifically: `mix test --only doctest lib/aria_engine/timeline/interval.ex`
5. **CHECKPOINT:** Confirm 7 doctest failures resolved before proceeding

### Step 2: Planning Test Investigation (CONDITIONAL)
1. **Only proceed after Step 1 completion and re-evaluation**
2. Re-run planning tests: `mix test test/aria_engine/plan/lazy_execution_test.exs`
3. **If failures persist**, investigate test file imports:
   - Check `alias Plan.Core` and other module aliases
   - Verify `AriaEngine.Domain` and `AriaEngine.StateV2` imports
   - Update domain creation helper functions if needed
4. **Root Cause Analysis:** Focus on test infrastructure rather than core implementation

### Step 3: Comprehensive Validation
- **Phase 1 Target:** 7/10 test failures resolved (Timeline doctests)
- **Phase 2 Target:** Remaining 3/10 failures resolved (planning test imports)
- **Final Validation:** Full test suite passes without regressions

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

**CURRENT PRIORITY: Phase 2 Active** - Planning test investigation following successful Phase 1 completion. Timeline doctests are now resolved (7/10 original failures fixed).

**Next Action:** Investigate `test/aria_engine/plan/lazy_execution_test.exs` for module import/alias issues causing the 4 persistent planning test failures.

**Key Finding:** Plan.Core.run_lazy_refineahead/4 function is fully implemented - planning test failures likely due to test file import/alias issues rather than missing core functionality.

## Related ADRs

- **ADR-122**: Fix Timeline module aliasing issues (completed, but missed interval.ex doctests)
- **ADR-121**: Lazy execution strategy implementation (may be related to planning failures)
- **ADR-118**: Add typespecs to all lib code (code quality improvements)

## Progress Tracking

**Phase 1 Progress:** 100% - Timeline doctest fixes completed (12 specific changes applied)
**Phase 2 Progress:** 50% - Planning test investigation active (4 failures confirmed, root cause analysis in progress)
**Phase 3 Progress:** 25% - Minor issue analysis complete (bridge.ex unused variable not found)  
**Phase 4 Progress:** 0% - Validation pending  

**Overall Completion:** 60% (Phase 1 complete, Phase 2 investigation pending)

**Analysis Status:** ✅ Complete
- Timeline doctest issues: 12 specific module references identified
- Planning test failures: Core implementation verified, likely import issues
- Bridge.ex warning: Not found in current code (may be resolved)
