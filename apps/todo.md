# Apps Todo File Management

The `apps/todo.md` file serves as the central tracking document for umbrella app architectural restructuring. All apps must follow the standard Elixir pattern of one external module with nested internal modules, and cross-app communication must use external module APIs exclusively.

## Restructuring Progress

### Compliant Apps (✅)

- **aria_serial** - Has external API (`lib/aria_serial.ex`), proper structure
- **aria_membrane_pipeline** - Has external API (`lib/aria_membrane_pipeline.ex`), proper structure
- **aria_auth** - Has external API (`lib/aria_auth.ex`), proper structure
- **aria_engine_core** - Has external API (`lib/aria_engine_core.ex`), proper structure
- **aria_state** - Has external API (`lib/aria_state.ex`), proper structure
- **aria_hybrid_planner** - Has external API (`lib/aria_hybrid_planner.ex`), proper structure
- **aria_gltf** - Has external API (`lib/aria_gltf.ex`), proper structure
- **aria_security** - Has external API (`lib/aria_security.ex`), proper structure
- **aria_timeline_intervals** - Has external API (`lib/aria_timeline_intervals.ex`), proper structure
- **aria_minizinc_executor** - Has external API (`lib/aria_minizinc_executor.ex`), proper structure
- **aria_minizinc_goal** - Has external API (`lib/aria_minizinc_goal.ex`), proper structure
- **aria_minizinc_multiply** - Has external API (`lib/aria_minizinc_multiply.ex`), proper structure
- **aria_minizinc_stn** - Has external API (`lib/aria_minizinc_stn.ex`), proper structure
- **ast_migrate** - Has external API (`lib/ast_migrate.ex`), proper structure
- **aria_core** - Has external API (`lib/aria_core.ex`), proper structure ✅
- **aria_timeline** - Has external API (`lib/aria_timeline.ex`), proper structure ✅

- **aria_storage** - Has external API (`lib/aria_storage.ex`), proper structure ✅
- **aria_town** - Has external API (`lib/aria_town.ex`), proper structure ✅

### Needs External API (🔧)

*All apps now have external APIs! 🎉*

### Cross-App Dependencies to Update (📋)

- Update AriaEngine calls to use AriaCore external API ✅ (API now available)
- Migrate AriaHybridPlanner to use AriaTimeline external API ✅ (API now available)
- **Fix AriaEngine.Timeline violations in aria_timeline** ✅ (Fixed timeline_builder.ex, interval_operations.ex)
- **Fix AriaEngineCore violations in aria_hybrid_planner** ✅ (Fixed core.ex)
- Review and update remaining direct internal module imports across apps
- Ensure all cross-app communication goes through external APIs only

**Status:** Major cross-app dependency violations have been fixed. External APIs are available for all remaining migration work.

**Recent Progress:**
- Fixed `AriaEngine.Timeline.Interval` → `Timeline.Interval` in aria_timeline
- Fixed `AriaEngine.Timeline.IntervalOperations` → `AriaTimeline` calls in timeline_builder.ex
- Fixed `AriaEngineCore.Domain.Core` and `AriaEngineCore.State` → `AriaEngineCore` in aria_hybrid_planner

## Implementation Priority (Leaf Apps First)

### Phase 1: Infrastructure Apps (HIGH PRIORITY)

These apps are dependencies for other apps and should be restructured first:

1. **aria_core** - Core domain functionality, used by multiple apps
2. **aria_state** - Already compliant ✅
3. **aria_serial** - Already compliant ✅

### Phase 2: Storage and Data Apps (MEDIUM PRIORITY)

4. **aria_storage** - Storage abstraction layer
5. **aria_timeline** - Already compliant ✅
6. **aria_timeline_intervals** - Already compliant ✅

### Phase 3: Planning and Execution Apps (MEDIUM PRIORITY)

7. **aria_hybrid_planner** - Already compliant ✅
8. **aria_engine_core** - Already compliant ✅
9. **aria_minizinc_executor** - Already compliant ✅
10. **aria_minizinc_goal** - Already compliant ✅
11. **aria_minizinc_multiply** - Already compliant ✅
12. **aria_minizinc_stn** - Already compliant ✅

### Phase 4: Application Layer Apps (LOW PRIORITY)

13. **aria_town** - NPC and town management
14. **aria_gltf** - Already compliant ✅
15. **aria_auth** - Already compliant ✅
16. **aria_membrane_pipeline** - Already compliant ✅
17. **aria_security** - Already compliant ✅
18. **ast_migrate** - Already compliant ✅

## Standard Elixir App Pattern Requirements

### Mandatory App Structure

```
apps/app_name/
├── lib/
│   ├── app_name.ex          # External API module (REQUIRED)
│   └── app_name/            # Internal modules directory
│       ├── module_a.ex      # Internal implementation
│       ├── module_b.ex      # Internal implementation
│       └── subdirectory/    # Nested internal modules
├── test/
└── mix.exs
```

### External Module Responsibilities

- **Public API definition:** All functions that other apps need to call
- **Documentation:** Clear module documentation with examples
- **Delegation:** Delegate to internal modules for implementation
- **Abstraction:** Hide implementation details from external consumers

### Cross-App Communication Rules

**FORBIDDEN patterns:**

```elixir
# BAD: Direct import of internal modules from other apps
alias AriaCore.Domain.SomeInternalModule
alias AriaEngine.Planner.InternalStrategy

# BAD: Calling internal functions directly
AriaCore.Domain.SomeInternalModule.private_function()
```

**REQUIRED patterns:**

```elixir
# GOOD: Only use external module APIs
alias AriaCore
alias AriaEngine

# GOOD: Call through public API
AriaCore.process_domain_data(data)
AriaEngine.execute_plan(plan)
```

## Implementation Process

### For Each Non-Compliant App:

1. **Create external module file:** Add `lib/app_name.ex` with public API
2. **Identify public functions:** Determine which functions other apps need
3. **Design clean API:** Create intuitive, well-documented public interface
4. **Delegate to internals:** Have external module delegate to existing internal modules
5. **Update cross-app calls:** Modify other apps to use new external API
6. **Remove internal imports:** Eliminate direct imports of internal modules
7. **Update todo file:** Mark app as compliant and document API availability

### Current Focus: Cross-App Dependency Migration

**Rationale:** All external APIs are now complete. The next phase is migrating cross-app dependencies to use external APIs exclusively instead of internal module imports.

**Next Steps:**

1. Audit all apps for direct internal module imports from other apps
2. Replace internal imports with external API calls
3. Remove any remaining `alias AppName.Internal.Module` patterns
4. Ensure all cross-app communication uses `alias AppName` pattern
5. Test that all functionality works through external APIs
6. Update documentation to reflect the new API-based architecture

## Benefits

- **Clear boundaries:** Each app has a well-defined public interface
- **Maintainable code:** Changes to internal modules don't affect other apps
- **Better documentation:** External APIs force clear documentation of app capabilities
- **Easier refactoring:** Internal implementation can change without breaking other apps
- **Dependency management:** Clear understanding of what each app provides and consumes

## Enforcement Rules

**Code review requirements:**

- **No internal module imports:** Cross-app imports must only use external modules
- **API completeness:** External modules must provide all needed functionality
- **Documentation quality:** External APIs must have clear documentation and examples
- **Backward compatibility:** API changes must not break existing consumers

This restructuring ensures the umbrella project maintains clean architectural boundaries and supports long-term maintainability as the codebase grows.
