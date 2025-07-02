## Detailed Cleanup Plan

### Phase 1: Identify Redundant Files to Remove

**Files to DELETE (redundant/incomplete stubs):**

1. `lib/aria_hybrid_planner/core.ex` - Unnecessary delegation layer to HybridCoordinatorV2
2. `lib/planning/core_interface.ex` - Incomplete stub with TODOs
3. `lib/planning/internal.ex` - Simple helper only used by core_interface.ex
4. `lib/core.ex` - Root-level duplicate (if it exists)
5. `lib/stubs.ex` - Appears to be placeholder/stub code

**Potentially redundant files to investigate:**

- Files in `lib/aria_hybrid_planner/` that duplicate functionality from `lib/hybrid_planner/`
- Root-level files like `lib/multigoal.ex`, `lib/state.ex` that may duplicate `lib/aria_hybrid_planner/` versions

### Phase 2: Update AriaHybridPlanner Direct Delegation

**Current problematic flow:**

```
AriaHybridPlanner → AriaHybridPlanner.Core → HybridCoordinatorV2
```

**Target simplified flow:**

```
AriaHybridPlanner → HybridCoordinatorV2
AriaEngineCore (compatibility) → AriaHybridPlanner
```

**Changes needed in `lib/aria_hybrid_planner.ex`:**

1. Remove all references to `AriaHybridPlanner.Core`
2. Update delegation functions to call `HybridPlanner.HybridCoordinatorV2` directly
3. Update type definitions to reference the correct modules
4. Maintain the same public API (no breaking changes)

### Phase 3: Test Validation Strategy

**Pre-cleanup verification:**

1. Run existing test suite: `mix test apps/aria_hybrid_planner`
2. Compile entire umbrella: `mix compile`
3. Check cross-app usage: Search for imports of modules we're removing

**Post-cleanup verification:**

1. Ensure all tests still pass
2. Verify no compilation errors
3. Check that public API behavior is unchanged

### Phase 4: Implementation Steps

1. **First**: Remove unused stub modules (Planning.\*, stubs.ex)
2. **Second**: Update AriaHybridPlanner to delegate directly to HybridCoordinatorV2
3. **Third**: Remove AriaHybridPlanner.Core after updating main module
4. **Fourth**: Clean up any remaining duplicate files
5. **Finally**: Run comprehensive tests

### Risk Mitigation

- Keep AriaEngineCore compatibility layer intact (no breaking changes)
- Maintain exact same public API in AriaHybridPlanner
- Test after each major change rather than all at once
- Use git commits at each phase for easy rollback
