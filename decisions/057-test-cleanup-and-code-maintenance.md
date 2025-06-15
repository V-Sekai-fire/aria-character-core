# ADR-057: Test Cleanup and Code Maintenance Plan

## Status

Active (Started: June 15, 2025)
**Phase 1**: Partially Complete - Instruction framework established, some test fixes applied
**Next Priority**: Resolve BaselineTest failures in aria_timestrike

## Context

The aria-character-core codebase currently has several maintenance issues that need to be addressed:

1. **Test Failures**: Multiple test suites are failing, particularly in `aria_engine` (FlowBackflowTest) and `aria_timestrike` (BaselineTest)
2. **Legacy Code**: A backup file `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` contains behavior that needs to be migrated to proper tests
3. **Architecture Migration**: The codebase has moved from GenServer-based architecture to direct method calls, requiring test updates
4. **Test Noise**: Some tests produce unnecessary log output when passing
5. **Documentation Gaps**: Some umbrella apps lack proper README files
6. **Code Organization**: Some files may be too large and need splitting

## Progress Tracking

Started implementation on June 15, 2025. Current status: **Phase 1 - Foundation Complete, Critical Issues Remain**

**✅ Infrastructure Completed:**

- Comprehensive instruction framework established (INST-016 through INST-023)
- All instruction files restructured with Godot best practices
- Commit message completeness checks implemented (INST-015)
- Test fixing protocols established (INST-001, INST-003, INST-006)
- FlowWorkflow API improved for common use cases
- Some FlowBackflowTest failures resolved

**❌ Critical Work Remaining:**

- **BaselineTest failures in aria_timestrike** (4 failures - highest priority)
- Legacy code migration from backup files
- File splitting and code organization
- README creation for umbrella apps
- Remaining test failures resolution

**📊 Completion Status:**

- Phase 1 (Critical Test Fixes): ~30% complete
- Phase 2 (Code Organization): ~10% complete  
- Phase 3 (Documentation): ~20% complete
- Phase 4 (Commit Strategy): ~90% complete

**Current Focus**: Making the common case common in FlowWorkflow API design

- Common case: Simple data processing functions (`process_actions_with_backflow`, `process_actions_with_convergence`)  
- Escape hatch: Advanced pipeline creation with GenServer processes for complex scenarios

### Identified Issues from Test Run

**aria_engine (FlowBackflowTest)**: 5 failures

- `test Backflow Signal Handling demand increase signals boost processing capacity` - GenServer process not alive
- `test Flow Backflow Processing demand-driven processing prevents oversubscription` - Logic error in expected results  
- `test Flow Backflow Processing backflow optimization reduces computation cost` - Missing backflow optimization
- `test Flow Backflow Processing GPU convergence patterns with hierarchical processing` - Convergence logic not working
- `test Backflow Signal Handling backpressure signals reduce processing demand` - GenServer process not alive

**aria_timestrike (BaselineTest)**: 4 failures

- `test aria_timestrike basic actions are callable` - Invalid position format error
- `test baseline performance benchmarks` - AriaEngine.State.add_fact/4 undefined
- `test current AriaEngine basic planning works` - Planner not functional
- `test aria_engine temporal module structure` - AriaEngine.Temporal module missing

**Legacy Files Found**:

- `debug_planner_structures.exs.disabled`
- Disabled test files in aria_queue and aria_timestrike

## Decision

We will implement a systematic maintenance approach with the following prioritized phases:

### Phase 1: Critical Test Fixes (Immediate)

- [x] Fix some failing tests in `aria_engine` (FlowBackflowTest) - **Partially Complete**
- [ ] Fix failing tests in `aria_timestrike` (BaselineTest) - **4 failures remain**
- [ ] Migrate behavior from backup file to proper tests in aria_flow
- [x] Update some tests to work with direct method calls instead of GenServer patterns
- [x] Ensure tests are silent when passing (reduce log spam) - **Instruction added**

### Phase 2: Code Organization (Short-term)

- [ ] Remove obsolete test files (membrane_workflow_test_old.exs, membrane_workflow_test_new.exs)  
- [ ] Split overly large code files into smaller logical units
- [ ] Create proper type annotations and documentation
- [ ] Update imports and references when files are split
- [ ] Backup original files before major restructuring

### Phase 3: Documentation Updates (Ongoing)

- [ ] Create/update README files for each umbrella app
- [x] Update design changelogs when notable changes occur - **Instruction exists**
- [x] Document architecture decisions in ADR format (this document)
- [ ] Maintain temporal planner design resolutions

### Phase 4: Commit Strategy (Continuous)

- [x] Use descriptive commit messages with completeness checks - **INST-015 added**
- [x] Group logically related changes into separate commits - **Instructions exist**
- [x] Professional and timeless language in commits - **Instructions exist**
- [x] Double-check spelling and grammar in all commit messages
- [x] Test and compile after each commit to ensure stability

## Implementation Guidelines

### Test Fixing Protocol

- [x] Identify one failing test or warning at a time - **Single Fix Principle (INST-001)**
- [x] Fix the issue with minimal necessary changes
- [x] Commit the fix with descriptive message - **Commit completeness (INST-015)**
- [x] Repeat for next issue
- [x] Bundle related fixes only when it reduces rate limiting - **Debugger tips (INST-003)**

### File Splitting Protocol

- [ ] Identify files that are too large or have too much responsibility
- [ ] Backup the original file
- [ ] Split into smaller logical units with type annotations
- [ ] Create new files for each logical unit
- [ ] Update original file to reference new files
- [ ] Test changes thoroughly
- [ ] Remove original file if no longer needed
- [ ] Commit with descriptive message
- [ ] Document changes in relevant documentation

### Code Quality Standards

- [x] Ensure passing tests are silent (no log output) - **INST-006 added**
- [ ] Verify only failing tests or those with explicit verbose flags produce output
- [ ] Add proper documentation to all modules
- [ ] Include type annotations for all public interfaces

## Consequences

### Positive

- Improved test reliability and faster CI/CD pipeline
- Better code organization and maintainability
- Clearer documentation for current and future developers
- Reduced cognitive load when working with the codebase
- Proper migration from GenServer to direct method call architecture

### Negative

- Initial time investment required for cleanup
- Potential temporary instability during refactoring
- Need for careful coordination to avoid merge conflicts

### Risks

- Breaking existing functionality during refactoring
- Introducing new bugs while fixing tests
- Incomplete migration leaving mixed architectural patterns

## Monitoring

- Track test pass/fail rates after each change
- Monitor compilation warnings
- Ensure all umbrella apps maintain their README files
- Verify that design changelog updates accompany notable changes

## Success Criteria

- All tests pass consistently
- No compilation warnings
- Each umbrella app has an updated README
- Code files are appropriately sized and well-organized
- Test output is clean and informative only when needed
- Architecture is consistently using direct method calls

## Next Steps for Completion

To complete this ADR, the following critical tasks must be addressed:

### Immediate Priority (Phase 1 Completion)

1. **Resolve BaselineTest failures** in aria_timestrike (4 critical failures)
   - Fix invalid position format error
   - Implement missing AriaEngine.State.add_fact/4 function
   - Make planner functional for basic planning
   - Add missing AriaEngine.Temporal module

2. **Migrate legacy code** from backup files to proper test structure

### Medium Priority (Phase 2)

3. **Code organization cleanup**
   - Remove obsolete test files
   - Split large files following INST-009 guidelines
   - Add proper type annotations

### Long-term (Phase 3)

4. **Documentation completion**
   - Create README files for all umbrella apps following INST-011

**Completion Criteria**: This ADR will be marked as "Completed" when all tests pass consistently and the critical maintenance issues identified in the Context section have been resolved.
