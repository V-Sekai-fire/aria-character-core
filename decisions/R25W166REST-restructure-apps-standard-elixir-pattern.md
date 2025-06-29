# R25W166REST: Restructure Apps to Follow Standard Elixir Pattern

**Status:** Active  
**Date:** 2025-06-28  
**Priority:** HIGH

## Context

The current app structure violates standard Elixir conventions by mixing external modules with inner modules inconsistently. This creates confusion and makes the codebase harder to navigate.

### Current Problems

1. **Mixed module patterns**: Apps have both `aria_engine_core/` and `aria_engine/` directories
2. **Non-standard organization**: External modules scattered instead of being organized as inner modules
3. **Namespace confusion**: Unclear which modules belong to which app
4. **Import complexity**: Difficult to understand module relationships

### Current Structure Example (aria_engine_core)

```
apps/aria_engine_core/lib/
├── aria_engine_core.ex          # Main module ✓
├── aria_engine/                 # External modules ✗
│   ├── domain.ex
│   └── state.ex
└── aria_engine_core/            # Inner modules ✓
    ├── domain/
    ├── plan/
    └── *.ex files
```

### Standard Elixir Pattern

```
apps/aria_engine_core/lib/
├── aria_engine_core.ex          # Main module
└── aria_engine_core/            # All inner modules
    ├── domain.ex
    ├── state.ex
    ├── plan.ex
    └── subdirectories/
```

## Decision

Restructure all apps to follow the standard Elixir pattern:

1. **Single namespace per app**: Each app should have one main module namespace
2. **Inner modules only**: All functionality organized as inner modules
3. **Clear hierarchy**: Logical organization of related functionality
4. **Consistent naming**: Follow Elixir naming conventions throughout

## Implementation Plan

### Phase 1: Analyze Current Structure

- [x] Identify all apps with mixed module patterns
- [ ] Document current module dependencies
- [ ] Create migration mapping for each app

### Phase 2: AriaEngineCore Restructuring

- [ ] Move `aria_engine/domain.ex` → `aria_engine_core/domain.ex`
- [ ] Move `aria_engine/state.ex` → `aria_engine_core/state.ex`
- [ ] Update all import statements
- [ ] Update module references across codebase
- [ ] Test compilation and functionality

### Phase 3: AriaGltf Restructuring

- [ ] Verify AriaGltf follows standard pattern (appears correct)
- [ ] Fix any inconsistencies found

### Phase 4: Other Apps

- [ ] AriaHybridPlanner: Check for mixed patterns
- [ ] AriaTimeline: Check for mixed patterns
- [ ] All other apps: Systematic review and restructuring

### Phase 5: Validation

- [ ] All apps compile successfully
- [ ] All tests pass
- [ ] No broken module references
- [ ] Documentation updated

## Module Migration Mapping

### AriaEngineCore

```
aria_engine/domain.ex → aria_engine_core/domain.ex
aria_engine/state.ex → aria_engine_core/state.ex
```

### Module Name Changes

```
AriaEngine.Domain → AriaEngineCore.Domain
AriaEngine.State → AriaEngineCore.State
```

## Success Criteria

1. **Consistent structure**: All apps follow standard Elixir pattern
2. **Clear namespaces**: Each app has single, well-defined namespace
3. **Working compilation**: All apps compile without errors
4. **Functional tests**: All existing functionality preserved
5. **Clean imports**: No cross-app module confusion

## Risks and Mitigation

### Risk: Breaking Changes

- **Impact**: Existing code may break due to module renames
- **Mitigation**: Systematic find-and-replace with compilation verification

### Risk: Complex Dependencies

- **Impact**: Apps may have circular or complex dependencies
- **Mitigation**: Document dependencies before changes, update incrementally

### Risk: Test Failures

- **Impact**: Tests may fail due to module path changes
- **Mitigation**: Update test imports alongside module moves

## Related ADRs

- **R25W1398085**: Unified durative action specification (may need import updates)
- **R25W0329AE5**: Consolidate flow and queue into engine (related to module organization)

## Implementation Notes

- Use git mv to preserve file history
- Update imports in batches to maintain compilation
- Test each app individually after restructuring
- Update documentation to reflect new structure

This restructuring will significantly improve code organization and follow Elixir best practices for umbrella applications.
