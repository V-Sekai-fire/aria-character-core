# ADR-167: Comprehensive App Functionality Restoration

**Status:** Active  
**Date:** 2025-01-24  
**Priority:** CRITICAL

## Context

The aria-character-core umbrella project has five leaf apps that need to achieve 100% functionality:
- aria_hybrid_planner (existing)
- aria_temporal_planner (existing) 
- aria_membrane_pipeline (existing)
- aria_minizinc (existing)
- aria_engine_core (existing)

Current issues preventing 100% functionality:
1. **State format inconsistency**: Mixed usage of AriaEngine.State `{predicate, subject, object}` vs StateV2 `{subject, predicate, object}`
2. **Method lookup failures**: "No methods found for goal" errors due to state format mismatches
3. **MiniZinc template system**: 19 test failures in EEx template processing
4. **STN integration**: 28 test failures in temporal constraint solving
5. **Hybrid planner**: Disabled test infrastructure
6. **Pipeline integration**: Planner adapter integration issues
7. **Code quality**: Compilation warnings across apps

## Decision

Implement a phased approach to restore 100% functionality across all leaf apps, starting with critical state format standardization.

## Implementation Plan

### Phase 0: StateV2 Migration (CRITICAL - 2-3 days)
**Target:** Eliminate AriaEngine.State, standardize on StateV2 RDF format

**Current State Formats:**
- AriaEngine.State: `{predicate, subject, object}` (GTPyHOP format)
- StateV2: `{subject, predicate, object}` (RDF format)

**Decision:** Standardize on StateV2 `{subject, predicate, object}` for RDF compatibility

**Tasks:**
- [ ] **aria_engine_core**: Convert all AriaEngine.State creation to StateV2
- [ ] **aria_engine_core**: Adapt method registry lookup to extract predicate from position 1
- [ ] **aria_hybrid_planner**: Fix goal processing for StateV2 format
- [ ] **aria_hybrid_planner**: Update method lookup chain for RDF format
- [ ] **aria_temporal_planner**: Update state-based temporal reasoning to StateV2
- [ ] **All test suites**: Convert AriaEngine.State patterns to StateV2
- [ ] **Verify method lookup chain**: Ensure `{subject, predicate, object}` → extract predicate → method_registry[predicate] → domain_methods[[subject, object]]

**Method System (Unchanged):**
- Unigoal method registration: `method_registry[predicate] = function`
- Domain method registration: `domain_methods[[subject, value]] = method`
- Function signatures: `def achieve_at(subject, fact)` (unchanged)

### Phase 1: Fix MiniZinc Template System (CRITICAL - 2-3 days)
**Target:** aria_minizinc (19 test failures)

**Tasks:**
- [ ] Fix EEx template variable assignments
- [ ] Resolve template compilation errors
- [ ] Ensure proper MiniZinc model generation
- [ ] Verify all 19 tests pass
- [ ] Test STN constraint model generation

### Phase 2: Fix STN Integration (HIGH - 1-2 days)
**Target:** aria_temporal_planner (28 STN failures)

**Tasks:**
- [ ] Fix STN consistency test failures with working MiniZinc
- [ ] Verify temporal constraint solving
- [ ] Test integration with StateV2 format
- [ ] Ensure all 28 STN tests pass

### Phase 3: Restore Hybrid Planner (HIGH - 1-2 days)
**Target:** aria_hybrid_planner

**Tasks:**
- [ ] Re-enable test infrastructure
- [ ] Fix integration with StateV2 format
- [ ] Verify method lookup with temporal planner
- [ ] Test goal processing pipeline
- [ ] Ensure all hybrid planner tests pass

### Phase 4: Fix Pipeline Integration (MEDIUM - 1 day)
**Target:** aria_membrane_pipeline

**Tasks:**
- [ ] Fix planner adapter integration issues
- [ ] Test pipeline with restored hybrid planner
- [ ] Verify membrane pipeline functionality
- [ ] Ensure all pipeline tests pass

### Phase 5: Code Quality Cleanup (LOW - 1 day)
**Target:** All apps

**Tasks:**
- [ ] Fix compilation warnings across all apps
- [ ] Clean up unused code
- [ ] Verify clean compilation
- [ ] Final integration testing

## Success Criteria

**Phase 0 Success:**
- All apps use StateV2 `{subject, predicate, object}` format consistently
- Method lookup chain works: StateV2 → extract predicate → method registry → domain methods
- "No methods found for goal" errors eliminated
- All state-related tests pass

**Overall Success:**
- All 5 leaf apps achieve 100% test pass rate
- No compilation warnings
- Clean integration between all apps
- Hybrid planner fully functional with temporal reasoning
- MiniZinc solver working correctly
- Pipeline integration operational

## Timeline

**Total Estimated Duration:** 8-11 days

**Critical Path:**
1. Phase 0 (StateV2 migration) - blocks all other phases
2. Phase 1 (MiniZinc fixes) - blocks Phase 2
3. Phase 2 (STN integration) - blocks Phase 3
4. Phases 3-5 can run in parallel once dependencies are resolved

## Risks and Mitigation

**Risk:** StateV2 migration breaks existing functionality
**Mitigation:** Comprehensive testing at each step, maintain backup branches

**Risk:** Method lookup adaptation introduces new bugs
**Mitigation:** Focus testing on method resolution and goal processing

**Risk:** MiniZinc template fixes are more complex than expected
**Mitigation:** Isolate template issues, fix incrementally

## Related ADRs

- ADR-145: Delete statev2-migrate-to-state-v1
- ADR-146: Replace ariaengine-statev2-with-state
- ADR-147: Fix warnings and failures
- ADR-151: Strict encapsulation modular testing architecture

## Monitoring

Track progress through:
- Test pass rates for each app
- Compilation warning counts
- Integration test results
- Method lookup success rates

**Current Focus:** Phase 0 - StateV2 migration to resolve core state format inconsistencies blocking all other functionality.
