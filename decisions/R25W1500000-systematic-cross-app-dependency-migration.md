# R25W1500000: Systematic Cross-App Dependency Migration

**Status:** Active  
**Date:** 2025-06-28  
**Priority:** HIGH

## Context

The AST migration tool has identified comprehensive cross-app dependency violations across the entire Aria Character Core umbrella project. Analysis shows that **201 out of 201 files** contain violations where apps directly import internal modules from other apps instead of using external APIs.

### Violation Analysis Results

- **Files processed:** 201
- **Files with violations:** 201 (100%)
- **Violation scope:** Every single Aria app has architectural boundary violations

### Common Violation Patterns Detected

1. **Legacy namespace violations:** `AriaEngine.*`, `AriaCore.*` patterns
2. **Internal module imports:** Direct `alias App.Internal.Module` across app boundaries  
3. **Timeline violations:** `AriaTimeline.TimelineCore.*` usage instead of `AriaTimeline` API
4. **Engine core violations:** `AriaEngineCore.*` direct usage instead of external API

### Example Violations

From `apps/aria_hybrid_planner/lib/aria_hybrid_planner/core.ex`:

```elixir
alias AriaEngineCore  # Should use AriaEngineCore external API
@type domain :: AriaEngineCore.domain()  # Direct internal type usage
@type state :: AriaEngineCore.state()    # Direct internal type usage
```

## Decision

Implement systematic cross-app dependency migration using the `ast_migrate` tool following INST-042 (Systematic cross-app dependency migration). This requires:

1. **Group-based fixing approach:** Fix by violation type, not by individual app
2. **AST-based analysis:** Use `ast_migrate` for all detection and transformation
3. **External API completeness:** Ensure all needed functions exist before fixing violations
4. **Dependency-order implementation:** Fix infrastructure apps first, application layer last

## Implementation Plan

### Phase 1: Comprehensive Violation Mapping (PRIORITY: HIGH)

**Status:** ✅ Complete

- [x] Use `ast_migrate` to identify all cross-app dependency patterns
- [x] Categorize violations by type (legacy namespace, internal imports, etc.)
- [x] Map dependency chains between apps
- [x] Quantify scope: 201 files with violations across all apps

### Phase 2: External API Audit and Completion (PRIORITY: HIGH)

**Status:** 🔄 In Progress

- [x] **Audit existing external APIs:** Check `lib/app_name.ex` files for completeness
- [x] **Identify API gaps:** Find functions that violations need but APIs don't provide
- [x] **Implement missing type functions:** Add required type accessor functions to external APIs
- [ ] **Implement missing delegation functions:** Add required delegation functions to external APIs
- [ ] **Document API coverage:** Ensure external APIs provide complete functionality

**Key findings:**

- `AriaEngineCore` - ✅ Added type accessor functions (`domain()`, `state()`, `todo_item()`)
- `AriaTimeline` - ✅ Has comprehensive external API, missing some internal functions
- `AriaCore` - ✅ Has comprehensive external API
- `AriaHybridPlanner` - ✅ Fixed type usage to use external API properly

**Compilation test results:**

- ✅ AriaHybridPlanner compiles successfully with external API types
- ⚠️ Many warnings about missing Timeline functions (need delegation implementation)

### Phase 3: Systematic Violation Fixing (PRIORITY: HIGH)

**Status:** ⏳ Pending API completion

**Fix by violation type (not by app):**

#### Type A: Legacy Namespace Violations

- [ ] **AriaEngine.Timeline.*** → `AriaTimeline` API calls
- [ ] **AriaEngine.*** → `AriaEngineCore` API calls  
- [ ] **AriaCore.*** → `AriaCore` API calls

#### Type B: Internal Module Imports

- [ ] **AriaTimeline.TimelineCore.*** → `AriaTimeline` API calls
- [ ] **AriaEngineCore.*** direct usage → `AriaEngineCore` API calls
- [ ] **Other internal imports** → appropriate external APIs

#### Type C: Cross-App Type Dependencies

- [ ] **AriaEngineCore.domain()** → `AriaEngineCore.domain_type()`
- [ ] **AriaEngineCore.state()** → `AriaEngineCore.state_type()`
- [ ] **Other type imports** → external API type functions

### Phase 4: Validation and Testing (PRIORITY: MEDIUM)

**Status:** ⏳ Pending violation fixes

- [ ] **Compilation verification:** All apps compile without errors
- [ ] **Test execution:** Run test suites to verify functionality preservation
- [ ] **Cross-app integration:** Verify app interactions work correctly
- [ ] **Performance validation:** Ensure no significant performance regressions

## Implementation Strategy

### AST Migration Tool Usage

**REQUIRED:** All analysis and transformation MUST use `ast_migrate`:

```bash
# Comprehensive violation detection
cd apps/ast_migrate && mix run -e "AstMigrate.apply_rule(:cross_app_dependency_detector, dry_run: true)"

# Apply systematic fixes (when ready)
cd apps/ast_migrate && mix run -e "AstMigrate.apply_rule(:cross_app_dependency_fixer, dry_run: false)"
```

### Dependency-Order Implementation

1. **Infrastructure apps first:** aria_core, aria_state, aria_serial
2. **Foundation apps second:** aria_timeline, aria_storage  
3. **Planning apps third:** aria_hybrid_planner, aria_engine_core
4. **Application layer last:** aria_town, aria_gltf, UI apps

### External API Pattern

```elixir
# In lib/app_name.ex - External API
def needed_function(args) do
  AppName.Internal.Module.needed_function(args)
end

@type domain_type :: AppName.Internal.Domain.t()
def domain_type, do: AppName.Internal.Domain
```

## Success Criteria

**Migration complete when:**

- [ ] **Zero cross-app internal imports:** No `alias App.Internal.Module` patterns across apps
- [ ] **Complete external APIs:** All needed functionality available through `lib/app_name.ex` files  
- [ ] **Full compilation:** All apps compile without warnings or errors
- [ ] **Functional preservation:** All tests pass and features work as before
- [ ] **Clean architecture:** Apps communicate only through external APIs

## Risks and Mitigation

### High Risk: Breaking Changes During Migration

**Risk:** Systematic changes across 201 files could introduce compilation errors or functional regressions.

**Mitigation:**

- Use AST-based transformations for accuracy
- Fix violations by type to maintain consistency
- Validate compilation after each violation type fix
- Maintain comprehensive test coverage throughout migration

### Medium Risk: Incomplete External APIs

**Risk:** External APIs may not provide all functionality needed by dependent apps.

**Mitigation:**

- Complete API audit before fixing violations
- Implement missing delegation functions systematically
- Document API coverage and gaps clearly
- Test API completeness with real usage patterns

### Medium Risk: Performance Impact

**Risk:** Additional delegation layers could impact performance.

**Mitigation:**

- Measure performance before and after migration
- Optimize delegation patterns where needed
- Consider inline delegation for performance-critical paths
- Monitor production performance post-migration

## Related ADRs

- **R25W026F0B7**: Todo encapsulation (establishes external API pattern)
- **R25W114A09B**: Cross-app scheduler dependencies (related dependency issues)
- **R25W1096996**: Strict encapsulation modular testing architecture

## Current Focus

**Immediate Priority:** Complete external API audit and implementation for core apps (AriaEngineCore, AriaTimeline, AriaCore) to enable systematic violation fixing.

The comprehensive scope (201 files with violations) requires systematic, tool-assisted migration to ensure architectural consistency and prevent missed violations.
