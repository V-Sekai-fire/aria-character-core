# ADR-R25W1510C3F: Extract AriaEngineCore Implementation to Target Apps

**Status:** Active  
**Date:** 2025-06-30  
**Priority:** HIGH

## Context

`apps/aria_engine_core` is designed to be an external API that coordinates planning and execution across multiple apps in the umbrella project. However, it currently contains substantial implementation code that violates umbrella app architectural boundaries by mixing external API functionality with internal implementation details.

## Current Violations

### Implementation Code in External API App

**Files containing implementation that should be moved:**

- `lib/aria_engine_core/core.ex` - Core types and structs (should be simplified)
- `lib/aria_engine_core/planner.ex` - Full planner implementation (should delegate)
- `lib/aria_engine_core/domain/core.ex` - Domain implementation (should move to `aria_core`)
- `lib/aria_engine_core/domain/actions.ex` - Action execution (should move to `aria_core`)
- `lib/aria_engine_core/domain/methods.ex` - Method management (should move to `aria_core`)
- `lib/aria_engine_core/domain/utils.ex` - Domain utilities (should move to `aria_core`)
- `lib/aria_engine_core/plan/` directory - Plan structures and utilities (should move to `aria_hybrid_planner`)
- `lib/aria_engine_core/adapters/` directory - Planner adapters (should move to `aria_hybrid_planner`)
- `lib/aria_engine_core/behaviours/` directory - Planner behaviours (should move to `aria_hybrid_planner`)

### Correctly Delegating Modules

**Files already properly delegating:**

- `lib/aria_engine_core/math.ex` - Delegates to `AriaMath` ✅
- `lib/aria_engine_core/state.ex` - Delegates to `AriaState.RelationalState` ✅
- `lib/aria_engine_core/domain.ex` - External API delegating to internal modules (needs target migration)

## Decision

Extract all implementation code from `aria_engine_core` and move it to appropriate target apps, making `aria_engine_core` a pure external API that only delegates to other apps.

## Implementation Plan

### Phase 1: Domain Implementation Migration (PRIORITY: HIGH) ✅ COMPLETED

**Target App:** `aria_core`

**Files migrated:**

- [x] `lib/aria_engine_core/domain/core.ex` → Migrated to `apps/aria_core/lib/aria_core/domain_planning.ex`
- [x] `lib/aria_engine_core/domain/actions.ex` → Migrated to `apps/aria_core/lib/aria_core/action_execution.ex`
- [x] `lib/aria_engine_core/domain/methods.ex` → Migrated to `apps/aria_core/lib/aria_core/method_management.ex`
- [x] `lib/aria_engine_core/domain/utils.ex` → Migrated to `apps/aria_core/lib/aria_core/domain_utils.ex`

**Implementation Completed:**

- [x] Updated `AriaCore` external API to include domain planning functions
- [x] Migrated domain planning types and structs to `aria_core`
- [x] Updated `lib/aria_engine_core/domain.ex` to delegate to `AriaCore` instead of internal modules
- [x] Disabled old implementation files with `.disabled` extensions
- [x] Updated references to old `AriaEngineCore.Domain.Core` struct to use generic maps
- [x] Verified compilation succeeds across all apps

### Phase 2: Planner Implementation Migration (PRIORITY: HIGH) ✅ COMPLETED

**Target App:** `aria_hybrid_planner`

**Files migrated:**

- [x] `lib/aria_engine_core/planner.ex` implementation → `apps/aria_hybrid_planner/lib/aria_hybrid_planner/engine_integration.ex`
- [x] `lib/aria_engine_core/plan/` directory → `apps/aria_hybrid_planner/lib/aria_hybrid_planner/plan/`
- [x] `lib/aria_engine_core/adapters/` directory → `apps/aria_hybrid_planner/lib/aria_hybrid_planner/adapters/`
- [x] `lib/aria_engine_core/behaviours/` directory → `apps/aria_hybrid_planner/lib/aria_hybrid_planner/behaviours/`

**Implementation Completed:**

- [x] Added planning integration functions to `AriaHybridPlanner` external API
- [x] Created `AriaHybridPlanner.EngineIntegration` module for backward compatibility
- [x] Migrated solution tree and plan types to `AriaHybridPlanner.Plan`
- [x] Updated module namespaces and references for proper app boundaries
- [x] Verified compilation succeeds across all apps

### Phase 3: Core Types Simplification (PRIORITY: MEDIUM)

**Target:** Simplify `lib/aria_engine_core/core.ex`

**Implementation Required:**

- [ ] Remove implementation structs from `core.ex`
- [ ] Keep only type aliases that reference external app types
- [ ] Ensure all types delegate to appropriate external apps

### Phase 4: External API Validation (PRIORITY: MEDIUM)

**Validation Requirements:**

- [ ] `AriaEngineCore` external API functions only delegate to other apps
- [ ] No internal implementation modules remain in `aria_engine_core/lib/aria_engine_core/`
- [ ] All cross-app dependencies use external APIs only
- [ ] Compilation succeeds across all apps
- [ ] Tests pass with new delegation structure

## Migration Strategy

### Step 1: Target App API Enhancement

1. **Enhance AriaCore external API:**
   - Add domain planning functions that `AriaEngineCore.Domain` currently provides
   - Ensure all domain management functionality is available through `AriaCore`

2. **Enhance AriaHybridPlanner external API:**
   - Add engine integration functions for planning and execution
   - Ensure solution tree and plan types are exposed through external API

### Step 2: Implementation Migration

1. **Move domain files:**
   - Migrate `AriaEngineCore.Domain.*` modules to `AriaCore.Domain.*`
   - Update module names and namespaces
   - Update `AriaCore` external API to provide new functions

2. **Move planner files:**
   - Migrate `AriaEngineCore.Planner` and related modules to `AriaHybridPlanner`
   - Update module names and namespaces
   - Update `AriaHybridPlanner` external API to provide engine integration

### Step 3: Update Delegations

1. **Update AriaEngineCore external API:**
   - Change `lib/aria_engine_core/domain.ex` to delegate to `AriaCore`
   - Change `lib/aria_engine_core/planner.ex` to delegate to `AriaHybridPlanner`
   - Simplify `lib/aria_engine_core/core.ex` to type aliases only

### Step 4: Validation and Testing

1. **Compile all apps**
2. **Run test suites**
3. **Verify no internal module imports remain**

## Success Criteria

### External API Compliance

- [ ] `AriaEngineCore` contains no implementation modules in `lib/aria_engine_core/` subdirectories
- [ ] All `AriaEngineCore` functions delegate to external APIs of other apps
- [ ] No cross-app imports of internal modules (e.g., `AriaEngineCore.Domain.Core`)

### Functional Preservation

- [ ] All existing `AriaEngineCore` API functions continue to work
- [ ] Planning and execution functionality preserved
- [ ] Domain management functionality preserved
- [ ] All tests pass

### Architectural Compliance

- [ ] Clear separation between external API and implementation
- [ ] Domain implementation properly encapsulated in `aria_core`
- [ ] Planner implementation properly encapsulated in `aria_hybrid_planner`
- [ ] Clean umbrella app boundaries maintained

## Consequences

### Benefits

- **Clean architectural boundaries:** External API separated from implementation
- **Proper encapsulation:** Implementation details hidden in appropriate apps
- **Maintainable structure:** Changes to implementation don't affect external API consumers
- **Compliance with umbrella patterns:** Each app has focused responsibility

### Risks

- **Complex migration:** Multiple files and cross-app dependencies must be updated
- **Temporary instability:** Compilation may break during migration process
- **API surface changes:** External apps may need to provide new delegation functions

## Related ADRs

- **ADR-R25W1398085:** Unified durative action specification - requires domain functionality in `aria_core`
- **Apps todo management:** General umbrella app restructuring guidelines

## Implementation Status

**Current Focus:** Phase 1 - Domain implementation migration to `aria_core`

**Next Steps:**

1. Examine current `AriaCore` external API to identify missing functions
2. Migrate domain implementation modules from `aria_engine_core` to `aria_core`
3. Update delegations in `AriaEngineCore.Domain`
