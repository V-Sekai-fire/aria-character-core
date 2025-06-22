---
date: 2025-06-22
status: Active
---

# Remove unused batch_processor and convergence modules

## Context

The codebase contains two modules that are effectively unused and contain only placeholder implementations:

- `lib/aria_engine/batch_processor.ex` - Contains placeholder functions that raise "not implemented" errors
- `lib/aria_engine/convergence.ex` - Contains placeholder functions that raise "not implemented" errors

**Current State Analysis:**
- Both modules have minimal actual usage in the codebase
- Primary references are documentation cross-references and test infrastructure
- All core functions raise "not implemented" exceptions
- These modules add maintenance overhead without providing functionality

**References Found:**
- `convergence.ex` references `batch_processor` in documentation
- `test/aria_engine/test/support/flow_test_helpers.ex` uses convergence terminology
- `lib/aria_engine/timeline/internal/stn/operations.ex` has commented ConvergenceFlow code
- Cross-module documentation references

## Decision

Remove both modules to reduce codebase cruft and eliminate maintenance overhead for non-functional placeholder code.

## Implementation Plan

### Phase 1: Reference Cleanup (HIGH PRIORITY)
**Files**: Clean up cross-references and dependencies

- [ ] Update `convergence.ex` documentation to remove batch_processor references
- [ ] Clean up `test/aria_engine/test/support/flow_test_helpers.ex` convergence terminology
- [ ] Remove commented ConvergenceFlow code in `lib/aria_engine/timeline/internal/stn/operations.ex`
- [ ] Verify no import statements reference these modules

### Phase 2: Module Tombstoning (HIGH PRIORITY)
**Files**: Replace modules with tombstone documentation

- [ ] Replace `lib/aria_engine/batch_processor.ex` with tombstone explaining removal
- [ ] Replace `lib/aria_engine/convergence.ex` with tombstone explaining removal
- [ ] Document removal rationale and date in tombstones

### Phase 3: Documentation Updates (MEDIUM PRIORITY)
**Files**: Update related documentation

- [ ] Update ADR-118 typespecs list to remove these modules from Phase 4
- [ ] Remove references from any other ADRs or documentation
- [ ] Update module lists in relevant documentation

### Phase 4: Verification (HIGH PRIORITY)
**Files**: Ensure clean removal

- [ ] Verify compilation succeeds after removal
- [ ] Run test suite to ensure no broken dependencies
- [ ] Check for any remaining references in codebase
- [ ] Confirm no runtime errors from missing modules

## Implementation Strategy

### Step 1: Analyze Dependencies
1. Search for all references to BatchProcessor and Convergence modules
2. Identify which references are essential vs documentation
3. Plan cleanup approach for each reference type

### Step 2: Clean References
1. Update test helpers to remove convergence-specific terminology
2. Remove commented code that references these modules
3. Update documentation cross-references

### Step 3: Tombstone Modules
1. Replace module content with tombstone documentation
2. Explain removal rationale and date
3. Provide guidance for anyone looking for this functionality

### Step 4: Validate Removal
1. Compile codebase to ensure no broken imports
2. Run full test suite
3. Search for any remaining references

## Current Focus: Phase 1 - Reference Cleanup

Starting with cleaning up cross-references to prepare for safe module removal.

## Success Criteria

- [ ] Both modules replaced with tombstone documentation
- [ ] All cross-references cleaned up or updated
- [ ] Compilation succeeds without errors
- [ ] Test suite passes completely
- [ ] No remaining references to removed functionality
- [ ] Reduced codebase maintenance overhead

## Benefits

- **Reduced cruft:** Eliminates non-functional placeholder code
- **Cleaner codebase:** Removes modules that only raise exceptions
- **Lower maintenance:** Fewer files to maintain and update
- **Clear intent:** Tombstones document removal decision for future developers
- **Improved focus:** Removes distraction from actual functional modules

## Tombstone Content Template

```elixir
# TOMBSTONE: This module was removed on 2025-06-22
#
# Reason: Module contained only placeholder implementations that raised
# "not implemented" errors. No actual functionality was provided.
#
# Original purpose: [Brief description of intended functionality]
#
# If you need similar functionality, consider:
# - Using Elixir's built-in Flow library directly
# - Implementing specific convergence algorithms as needed
# - Creating focused modules for actual use cases
#
# See ADR-140 for full removal rationale and process.

defmodule AriaEngine.[ModuleName] do
  @moduledoc false
  # This module has been removed - see tombstone comment above
end
```

## Related ADRs

- **ADR-066**: Consolidate flow and queue into engine (completed via different approach)
- **ADR-118**: Add typespecs to all lib code (will be updated to remove these modules)
- **ADR-057**: Test cleanup and code maintenance

## Change Log

### June 22, 2025
- Created ADR for systematic removal of unused modules
- Identified cross-references requiring cleanup
- Planned tombstone approach for clean removal
