# ADR-008: Tombstone Widget Assembly Functionality

<!-- @adr_serial R25W008F4FE -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** MEDIUM

## Context

The `aria_minizinc` app contains widget assembly functionality that is no longer needed and should be removed to simplify the codebase:

### Current Widget Assembly Code

1. **Widget Assembly in ValidationSolver**: The `ValidationSolver` module contains widget assembly logic that appears to be unused or obsolete.
2. **Unused Widget Types**: Various widget-related types and functions that don't align with current MiniZinc problem domains.
3. **Legacy Code**: Widget assembly appears to be legacy code from earlier iterations of the system.

### Problems with Current Widget Assembly

1. **Unused Functionality**: Widget assembly doesn't appear to be used by any current problem domains (Goal Solving, STN).
2. **Code Complexity**: The widget assembly code adds unnecessary complexity to the ValidationSolver module.
3. **Maintenance Burden**: Unused code requires maintenance effort without providing value.
4. **Confusion**: Widget assembly concepts don't align with current MiniZinc problem domains.

### Domain Alignment

Following ADR-003 (Separate Goal Solving and STN Problem Domains), the current problem domains are:

- **Goal Solving**: General constraint satisfaction problems
- **STN (Simple Temporal Networks)**: Temporal constraint problems

Widget assembly doesn't fit into either of these domains and appears to be legacy functionality.

## Decision

Remove widget assembly functionality from the `aria_minizinc` app to simplify the codebase and focus on the core problem domains.

### Removal Strategy

1. **Identify Widget Assembly Code**: Locate all widget assembly related code in the codebase.
2. **Remove Widget Assembly Functions**: Remove unused widget assembly functions and types.
3. **Update ValidationSolver**: Simplify the ValidationSolver module by removing widget assembly logic.
4. **Update Tests**: Remove or update tests that depend on widget assembly functionality.
5. **Clean Up Dependencies**: Remove any dependencies that were only used for widget assembly.

### Preservation Strategy

1. **Git History**: All removed code will be preserved in git history for future reference.
2. **Documentation**: Document what was removed and why in this ADR.
3. **Migration Path**: If widget assembly is needed in the future, it can be restored from git history.

## Implementation Plan

### Phase 1: Code Identification ✅ PLANNED

- [ ] **Audit widget assembly code**
  - Search for widget-related functions and types
  - Identify dependencies and usage patterns
  - Document what will be removed

- [ ] **Analyze impact**
  - Check if any current functionality depends on widget assembly
  - Identify tests that need updating
  - Verify no external dependencies

### Phase 2: Widget Assembly Removal ✅ PLANNED

- [ ] **Remove widget assembly functions**
  - Remove widget assembly logic from ValidationSolver
  - Remove widget-related types and specifications
  - Remove unused helper functions

- [ ] **Update ValidationSolver**
  - Simplify ValidationSolver to focus on Goal Solving and STN domains
  - Remove widget assembly validation logic
  - Clean up module documentation

- [ ] **Clean up imports and dependencies**
  - Remove unused imports related to widget assembly
  - Update module dependencies
  - Remove any widget-specific dependencies from mix.exs

### Phase 3: Test Updates ✅ PLANNED

- [ ] **Update test suite**
  - Remove tests that depend on widget assembly
  - Update integration tests to focus on current domains
  - Ensure all remaining tests pass

- [ ] **Update test documentation**
  - Update test descriptions to reflect current functionality
  - Remove widget assembly examples from test documentation
  - Add comments explaining what was removed

### Phase 4: Documentation Cleanup ✅ PLANNED

- [ ] **Update module documentation**
  - Remove widget assembly references from module docs
  - Update function documentation to reflect current scope
  - Clean up examples and usage patterns

- [ ] **Update README and guides**
  - Remove widget assembly examples from README
  - Update usage guides to focus on current domains
  - Add migration notes if needed

## Implementation Strategy

### Step 1: Code Audit (IMMEDIATE)

1. Search codebase for widget-related code
2. Identify all functions, types, and dependencies
3. Document current usage (if any)

### Step 2: Safe Removal (HIGH PRIORITY)

1. Remove widget assembly code in small, focused commits
2. Update tests after each removal
3. Ensure compilation succeeds after each step

### Step 3: Cleanup (MEDIUM PRIORITY)

1. Clean up imports and dependencies
2. Update documentation
3. Verify no references remain

### Step 4: Validation (QUALITY ASSURANCE)

1. Run full test suite
2. Verify all functionality still works
3. Check for any missed references

## Success Criteria

**Code Simplification:**

- [ ] All widget assembly code removed from ValidationSolver
- [ ] No widget-related types or functions remain
- [ ] Module complexity reduced
- [ ] Codebase focuses on current domains (Goal Solving, STN)

**Functionality Preservation:**

- [ ] All current functionality continues to work
- [ ] Goal Solving validation works correctly
- [ ] STN validation works correctly
- [ ] No regressions introduced

**Documentation Quality:**

- [ ] Module documentation updated to reflect current scope
- [ ] No references to widget assembly remain
- [ ] Examples focus on current domains
- [ ] Migration path documented if needed

## Consequences

**Positive:**

- **Simplified Codebase**: Removing unused code reduces complexity
- **Focused Functionality**: Code focuses on current problem domains
- **Reduced Maintenance**: Less code to maintain and test
- **Clearer Purpose**: Module purpose is clearer without legacy functionality

**Negative:**

- **Lost Functionality**: Widget assembly capability is removed
- **Potential Future Need**: May need to restore functionality if requirements change
- **Migration Effort**: If widget assembly is needed later, it will require restoration effort

**Risks:**

- **Hidden Dependencies**: Widget assembly code might be used in unexpected places
- **Test Coverage**: Removing tests might reduce overall test coverage
- **Breaking Changes**: Removal might break external code that depends on widget assembly

## Related ADRs

**Parent ADRs:**

- **ADR-003**: Separate Goal Solving and STN Problem Domains (supports domain focus)
- **ADR-001**: Extract MiniZinc Functionality into Dedicated App (provides context)

**Related ADRs:**

- **ADR-002**: Implement Template Selection Logic (benefits from simplified codebase)
- **ADR-007**: Implement True STN Mathematical Foundation (benefits from focused codebase)

## Notes

This ADR focuses on code cleanup and simplification by removing unused widget assembly functionality. The removal aligns with the domain separation established in ADR-003 and helps focus the codebase on the current problem domains.

Widget assembly appears to be legacy functionality that doesn't align with current MiniZinc problem domains. By removing this code, we reduce maintenance burden and make the codebase easier to understand and work with.

The removal is safe because:

1. Widget assembly doesn't appear to be used by current functionality
2. All code is preserved in git history for future restoration if needed
3. The removal is done incrementally with testing at each step

## Current Status - June 24, 2025

### Cleanup Requirements

**🔍 Investigation Needed:**

- Audit ValidationSolver module for widget assembly code
- Search codebase for widget-related functions and types
- Identify any external dependencies on widget assembly
- Check test suite for widget assembly tests

**📋 Next Actions:**

1. Search codebase for "widget" references
2. Identify specific functions and types to remove
3. Check if any current tests depend on widget assembly
4. Plan incremental removal strategy
5. Update ValidationSolver to focus on Goal Solving and STN domains

**🎯 Immediate Goal:**
Identify and safely remove all widget assembly functionality from the aria_minizinc app, simplifying the codebase and focusing on the core problem domains of Goal Solving and STN constraint solving.

**⚠️ Caution:**
Ensure thorough investigation before removal to avoid breaking any hidden dependencies or removing functionality that might still be in use.
