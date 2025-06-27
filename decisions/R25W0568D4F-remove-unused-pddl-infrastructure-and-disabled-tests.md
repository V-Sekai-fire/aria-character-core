---
date: 2025-06-18
status: Completed
completed: 2025-06-18
---

# Remove Unused PDDL Infrastructure and Disabled Tests

<!-- @adr_serial R25W0568D4F -->

## Context

Analysis of the codebase reveals significant unused infrastructure that adds complexity without providing value:

1. **PDDL Infrastructure**: Complete PDDL (Planning Domain Definition Language) system with 15+ modules
2. **Disabled Test Files**: Multiple test files explicitly disabled due to implementation issues
3. **Development Utilities**: Tools like PddlFuzzer that are not used in production

These components increase maintenance overhead, compilation time, and cognitive load without contributing to the project's core functionality.

## Analysis Results

### PDDL Infrastructure Usage

- **Location**: `lib/aria_engine/pddl/` directory (15+ files)
- **Test Coverage**: Zero tests found using PDDL modules
- **External Usage**: Only referenced in `planning/core_interface.ex` which itself appears unused
- **Status**: Complete infrastructure with no active usage

### Disabled Test Files

From `test/DISABLED_TESTS.md`:

- AriaStorage: `rolling_hash_test.exs.disabled`, `chunks_test.exs.disabled`
- AriaEngine: `durative_actions_test.exs.disabled`, `function_as_object_demo_test.exs.disabled`
- Timeline: `stn_test.exs.disabled`
- Hybrid Planner: `hybrid_coordinator_v2_test.exs.disabled`
- Temporal Planning: `temporal_planning_test.exs.disabled`

### Development Utilities

- **PddlFuzzer**: Random PDDL generation for testing (unused)
- **PngGenerator**: PNG generation for timeline visualization (required - keep)

## Decision

Remove the following unused components:

1. **Complete PDDL infrastructure** (`lib/aria_engine/pddl/` directory)
2. **PDDL-related utilities** (`pddl_fuzzer.ex`, `pddl/domain_adapter.ex`)
3. **All disabled test files** (`.disabled` extension files)
4. **Unused development utilities** (excluding `png_generator.ex` which is required)

## Implementation Plan

### Phase 1: Remove Disabled Tests

- [x] Remove all `.disabled` test files
- [x] Update `test/DISABLED_TESTS.md` to reflect removal
- [x] Verify test suite still passes

### Phase 2: Remove PDDL Infrastructure

- [x] Remove `lib/aria_engine/pddl/` directory and all contents
- [x] Remove `lib/aria_engine/pddl_fuzzer.ex`
- [x] Remove PDDL references from `planning/core_interface.ex`
- [x] Update any imports or aliases that reference PDDL modules

### Phase 3: Review Unused Utilities

- [x] Review `lib/aria_engine/png_generator.ex` - **KEPT** (required for timeline visualization)
- [x] Confirm no other unused utilities remain

### Phase 4: Verification

- [x] Compile project to ensure no broken dependencies
- [x] Run full test suite to verify functionality
- [x] Update documentation if necessary

## Benefits

- **Reduced complexity**: Eliminates 20+ unused modules
- **Faster compilation**: Fewer modules to compile
- **Cleaner codebase**: Removes confusing unused infrastructure
- **Better maintainability**: Focus on actually used components
- **Reduced cognitive load**: Developers don't need to understand unused systems

## Risks

- **Potential future need**: PDDL infrastructure might be needed later
- **Hidden dependencies**: Some usage might not be immediately visible

## Mitigation

- **Git history preservation**: All removed code remains in git history
- **Documentation**: This ADR documents what was removed and why
- **Incremental approach**: Remove in phases to catch any issues early

## Success Criteria

- All disabled test files removed
- Complete PDDL infrastructure removed
- Project compiles successfully
- Test suite passes without errors
- No broken imports or references remain
