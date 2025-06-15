# ADR-057: Test Cleanup and Code Maintenance Plan

## Status

Active (Started: June 15, 2025)

## Context

The aria-character-core codebase currently has several maintenance issues that need to be addressed:

1. **Test Failures**: Multiple test suites are failing, particularly in `aria_engine` (FlowBackflowTest) and `aria_timestrike` (BaselineTest)
2. **Legacy Code**: A backup file `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` contains behavior that needs to be migrated to proper tests
3. **Architecture Migration**: The codebase has moved from GenServer-based architecture to direct method calls, requiring test updates
4. **Test Noise**: Some tests produce unnecessary log output when passing
5. **Documentation Gaps**: Some umbrella apps lack proper README files
6. **Code Organization**: Some files may be too large and need splitting

## Progress Tracking

## Decision

We will implement a systematic maintenance approach with the following prioritized phases:

### Phase 1: Critical Test Fixes (Immediate)

- [ ] Fix failing tests in `aria_engine` (FlowBackflowTest)
- [ ] Fix failing tests in `aria_timestrike` (BaselineTest)
- [ ] Migrate behavior from backup file to proper tests in aria_flow
- [ ] Update tests to work with direct method calls instead of GenServer patterns
- [ ] Ensure tests are silent when passing (reduce log spam)

### Phase 2: Code Organization (Short-term)

- [x] Remove obsolete test files (membrane_workflow_test_old.exs, membrane_workflow_test_new.exs)
- [ ] Split overly large code files into smaller logical units
- [ ] Create proper type annotations and documentation
- [ ] Update imports and references when files are split
- [ ] Backup original files before major restructuring

### Phase 3: Documentation Updates (Ongoing)

- [ ] Create/update README files for each umbrella app
- [ ] Update design changelogs when notable changes occur
- [x] Document architecture decisions in ADR format (this document)
- [ ] Maintain temporal planner design resolutions

### Phase 4: Commit Strategy (Continuous)

- [x] Use descriptive commit messages in professional vtuber style
- [x] Group logically related changes into separate commits
- [x] Avoid conventional commit message style
- [x] Double-check spelling and grammar in all commit messages
- [x] Test and compile after each commit to ensure stability

## Implementation Guidelines

### Test Fixing Protocol

- [ ] Identify one failing test or warning at a time
- [ ] Fix the issue with minimal necessary changes
- [ ] Commit the fix with descriptive message
- [ ] Repeat for next issue
- [ ] Bundle related fixes only when it reduces rate limiting

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

- [ ] Ensure passing tests are silent (no log output)
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
