# ADR-009: Fix MiniZinc Goal Test Failures and Enhanced Logging

<!-- @adr_serial R25W0093D9D -->

**Status:** Active  
**Date:** June 24, 2025  
**Priority:** HIGH

## Context

The aria_minizinc_goal tests are failing with MiniZinc syntax errors, and the executor needs enhanced logging for debugging. Two main issues need resolution:

### Test Failures

```
/tmp/minizinc_5948.mzn:38.1-8:
minimize max([time_robot_0, time_box_1]);
^^^^^^^^
Error: syntax error, unexpected minimize, expecting end of file
```

### Compilation Warning

```
warning: module attribute @version_cache_key was set but never used
```

### Missing Debug Visibility

The executor lacks detailed logging for debugging MiniZinc generation and execution, making it difficult to diagnose template and solver issues.

## Root Cause Analysis

1. **MiniZinc Syntax Error**: The objective statements (minimize/maximize) are being placed after constraints in the generated files, but MiniZinc expects them before the solve statement or as part of a proper solve block.

2. **Unused Module Attribute**: The `@version_cache_key` is defined but never referenced in the executor code.

3. **Insufficient Logging**: No debug output for generated script contents, command line arguments, or execution results.

## Decision

Implement a comprehensive fix addressing all three issues:

1. Fix MiniZinc template generation to produce valid syntax
2. Remove or properly use the unused module attribute
3. Add comprehensive Logger.debug statements for debugging visibility

## Implementation Plan

### Phase 1: MiniZinc Syntax Fix (PRIORITY: HIGH)

**File**: `apps/aria_minizinc_goal/lib/aria_minizinc_goal.ex`

**Missing/Required**:

- [x] Fix objective function placement in template generation
- [x] Ensure proper MiniZinc solve statement syntax
- [x] Add solve statement to template if missing
- [x] Validate generated MiniZinc syntax compliance

**Implementation Patterns Needed**:

- [x] Proper MiniZinc file structure: variables → constraints → solve + objective → output
- [x] Correct solve statement format: `solve minimize/maximize <expression>;`

### Phase 2: Template Structure Fix (PRIORITY: HIGH)

**File**: `apps/aria_minizinc_goal/priv/templates/goal_solving.mzn.eex`

**Missing/Required**:

- [x] Add solve statement section to template
- [x] Move objective into solve statement
- [x] Ensure proper MiniZinc syntax ordering

### Phase 3: Enhanced Logging (PRIORITY: MEDIUM)

**File**: `apps/aria_minizinc_executor/lib/aria_minizinc_executor/executor.ex`

**Missing/Required**:

- [x] Add Logger.debug for generated MiniZinc script contents
- [x] Add Logger.debug for full command line before execution
- [x] Add Logger.debug for command output (stdout and stderr)
- [x] Remove or properly use @version_cache_key attribute
- [x] Add Logger.debug for structured input data (template variables)
- [ ] Replace manual temporary file handling with `briefly` package
- [ ] Add `briefly` dependency to mix.exs for robust temp file management

**Implementation Patterns Needed**:

- [ ] Logger.debug statements at key execution points
- [ ] Proper log formatting for readability
- [ ] Conditional logging to avoid spam in production

### Phase 4: Test Logger Configuration (PRIORITY: MEDIUM)

**File**: `config/test.exs`

**Missing/Required**:

- [x] Add logger level configuration to enable debug logs in test environment
- [x] Ensure compatibility with existing TestOutput module for trace mode
- [x] Maintain silent-by-default behavior per INST-006 guidelines
- [x] Match default Elixir logger level (:debug) for consistency

### Phase 5: Test Validation (PRIORITY: MEDIUM)

**File**: `apps/aria_minizinc_goal/test/aria_minizinc_goal_test.exs`

**Missing/Required**:

- [ ] Verify all tests pass with fixed syntax
- [ ] Add test cases for different optimization types
- [ ] Validate generated MiniZinc files are syntactically correct
- [ ] Test logging output in debug mode

## Implementation Strategy

### Step 1: Fix MiniZinc Template Structure

1. Analyze current template generation in AriaMinizincGoal
2. Identify where objective is being placed incorrectly
3. Modify template to include proper solve statement
4. Update objective generation to work with solve statement

### Step 2: Enhance Executor Logging

1. Add Logger.debug for script contents before temp file write
2. Add Logger.debug for command line construction
3. Add Logger.debug for execution results
4. Remove unused @version_cache_key or implement caching

### Step 3: Validate and Test

1. Run tests to verify syntax errors are resolved
2. Test logging output with Logger level set to debug
3. Verify no compilation warnings remain

### Current Focus: MiniZinc Syntax Fix

Starting with the template structure fix because the syntax errors are blocking all test execution. The objective statements need to be properly integrated into solve statements rather than appearing as standalone statements.

## Success Criteria

- [x] All aria_minizinc_goal tests pass without syntax errors
- [x] No compilation warnings in aria_minizinc_executor
- [x] Logger.debug statements provide comprehensive debugging information
- [x] Generated MiniZinc files are syntactically valid
- [x] Command execution details are visible in debug logs
- [ ] Structured input data logging implemented
- [ ] Briefly package integrated for robust temp file management

## Risks and Consequences

**Risks:**

- Template changes might affect other MiniZinc apps
- Logging changes could impact performance if not properly conditional
- MiniZinc syntax requirements might vary between solvers

**Mitigation:**

- Test all MiniZinc apps after template changes
- Use Logger.debug (not info/warn) to avoid production noise
- Validate syntax against standard MiniZinc specification

## Change Log

### June 24, 2025

- Added logger level configuration to `config/test.exs` to enable debug logs in test environment
- Configuration matches default Elixir logger level (:debug) for consistency
- Maintains compatibility with existing TestOutput module for trace mode functionality
- Preserves silent-by-default test behavior per INST-006 guidelines

## Related ADRs

- **ADR-177**: Modular MiniZinc Architecture Refactoring (parent context)
- **ADR-003**: Separate Goal Solving and STN Problem Domains
- **ADR-006**: Implement Comprehensive Testing Strategy
