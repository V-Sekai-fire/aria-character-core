# ADR-171: Hybrid Planner Complete Restoration and Standardization

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** CRITICAL (Blocking ARC Prize work)  
**Timeline:** 2 weeks (June 24 - July 8, 2025)

## Context

The hybrid planner is currently in a non-functional state that blocks ARC Prize development:

**Critical Issues Identified:**
- **Zero test coverage**: All tests disabled (`.disabled` extensions)
- **Compilation warnings**: Type violations and unused variables in `lazy_execution.ex`
- **Missing ADR-133 standardization**: Legacy method registration patterns still in use
- **No functional verification**: Cannot confirm basic planning workflow works

**Dependency Chain:**
ARC Prize → Hybrid Planner → Engine Core + Temporal Planner

**Git Commit Analysis:**
Previous work shows 40+ planning commits with minimal implementation, indicating need for focused, capped restoration scope to avoid analysis paralysis.

## Decision

Implement complete hybrid planner restoration in two phases with strict scope limits before any ARC Prize work begins.

## Implementation Plan

### Phase 1: Core Functionality Restoration (Week 1: June 24-30)

**Day 1-2: Compilation Stability**
- [ ] Fix type violation in `lazy_execution.ex:66` (unreachable error clause)
- [ ] Fix unused variable warnings across all modules
- [ ] Achieve clean `mix compile --warnings-as-errors`
- [ ] Document all compilation fixes with rationale

**Day 3-4: Test Suite Restoration**
- [ ] Re-enable `test/planner_filter_test.exs.disabled`
- [ ] Re-enable `test/hybrid_planner/strategies/default/stn_temporal_strategy_test.exs.disabled`
- [ ] Fix all test failures and compilation issues
- [ ] Add missing test dependencies and setup
- [ ] Achieve passing `mix test` with meaningful assertions

**Day 5-7: Core Planning Verification**
- [ ] Create integration test: Domain creation → Goal setting → Plan generation
- [ ] Test strategy pattern functionality (domain, state, planning strategies)
- [ ] Verify HTN decomposition workflow
- [ ] Test backtracking and error handling
- [ ] Validate state management and goal processing
- [ ] Document core planning workflow with examples

**Phase 1 Success Criteria:**
- ✅ Clean compilation with `mix compile --warnings-as-errors`
- ✅ Full test suite passing with `mix test`
- ✅ Basic planning workflow functional end-to-end
- ✅ Integration with aria_engine_core and aria_temporal_planner verified

### Phase 2: ADR-133 Standardization (Week 2: July 1-8)

**Day 8-10: Method Registration Unification**
- [ ] Implement `Domain.add_method/4` with options map pattern
- [ ] Add deprecation warnings for `add_task_method/3-4`, `add_unigoal_method/3-4`
- [ ] Update existing domain registrations to new pattern
- [ ] Create comprehensive tests for unified registration system
- [ ] Document migration guide for existing domains

**Day 11-12: Module-Based Domain Pattern**
- [ ] Implement `use AriaEngine.Domain` macro system
- [ ] Add `@action`, `@unigoal_method`, `@task_method` attribute support
- [ ] Generate `create_domain/0` function automatically
- [ ] Test with sample cooking/movement domains
- [ ] Create domain creation examples and documentation

**Day 13-14: Error Handling Standardization**
- [ ] Replace all `false` returns with `{:error, reason}` tuples
- [ ] Update backtracker logic to handle `{:ok, result}` pattern only
- [ ] Add descriptive error atoms for debugging
- [ ] Update all strategy implementations for new error pattern
- [ ] Create comprehensive error handling tests

**Phase 2 Success Criteria:**
- ✅ ADR-133 solutions fully implemented
- ✅ Module-based domain creation functional
- ✅ Unified method registration working
- ✅ Standardized error handling throughout
- ✅ Migration path documented and tested

## ARC Prize Integration Readiness

**Pre-ARC Checklist (Must be 100% complete):**
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix test` passes with comprehensive coverage
- [ ] Core planning workflow: Domain → Goals → Plan → Execution
- [ ] ADR-133 standardization implemented and tested
- [ ] Integration tests with dependencies passing
- [ ] Documentation updated with new patterns
- [ ] Sample domains working with new patterns

## Risk Mitigation

**High-Risk Areas:**
1. **Test restoration complexity**: Disabled tests may have deep integration issues
2. **Type system violations**: Current warnings indicate structural problems
3. **Dependency integration**: Changes may break aria_engine_core integration
4. **Timeline pressure**: 2 weeks is aggressive for complete restoration

**Mitigation Strategies:**
- **Daily compilation checks**: Ensure no regressions during development
- **Incremental test restoration**: Fix one test file at a time
- **Integration testing**: Test with dependencies after each major change
- **Rollback plan**: Keep working branches for each phase
- **Scope enforcement**: No feature additions beyond restoration requirements

## Success Criteria

**Phase 1 Complete:**
- Hybrid planner compiles cleanly and tests pass
- Basic planning functionality verified end-to-end
- Integration with other apps confirmed

**Phase 2 Complete:**
- ADR-133 standardization fully implemented
- Module-based domain pattern functional
- Error handling standardized throughout
- Ready for ARC Prize domain integration

**Overall Success:**
- Hybrid planner is 100% functional and tested
- ARC Prize development can begin with confidence
- Technical debt eliminated, not accumulated

## Timeline Impact on ARC Prize

**Original ARC Timeline**: 2 weeks (July 8-22)
**New ARC Timeline**: 2 weeks (July 8-22) - **unchanged**
**Total Project Timeline**: 4 weeks (2 weeks restoration + 2 weeks ARC)

The restoration work is **prerequisite** to ARC success, not optional. Attempting ARC work with a broken hybrid planner would result in failure.

## Related ADRs

- **ADR-133**: Planner Standardization Open Problems (solutions to implement)
- **ADR-155**: Hybrid Planner Test Suite Restoration (previous attempt)
- **ADR-172-175**: ARC Prize ADR series (dependent on this restoration)

## Consequences

**If Successful:**
- Hybrid planner becomes reliable foundation for ARC Prize work
- ADR-133 standardization enables clean domain integration
- Technical debt eliminated rather than accumulated

**If Failed:**
- ARC Prize work cannot proceed
- Technical debt continues to accumulate
- Planning system remains unreliable

This restoration is the critical path to ARC Prize success.
