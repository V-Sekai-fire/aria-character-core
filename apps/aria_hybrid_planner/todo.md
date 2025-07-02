# Current State Analysis

**aria_engine_core** is essentially a thin wrapper that delegates to aria_hybrid_planner:

- Simple public API that just calls `AriaHybridPlanner.*` functions
- Has core types (Domain, State, Plan, etc.)
- Used by: aria_core, aria_membrane_pipeline, aria_blocks_world
- Heavy dependencies: aria_math, aria_state, aria_timeline, aria_ewbik, aria_minizinc_stn, aria_minizinc_goal, aria_minizinc_executor, aria_hybrid_planner

**aria_hybrid_planner** has the actual implementation:

- Complex planning logic with HTN coordinators, temporal planning, node expansion
- Lighter dependencies: aria_state, aria_timeline, aria_minizinc_stn
- More focused architecture

## Merge Plan

### Phase 1: Enhance aria_hybrid_planner

1. **Expand public API** - Move the clean public API from `AriaEngineCore` into `AriaHybridPlanner`
2. **Import core modules** - Move Domain, State, Plan, Utils modules from aria_engine_core to aria_hybrid_planner
3. **Update dependencies** - Add the additional dependencies that aria_engine_core had (aria_math, aria_ewbik, minizinc modules)
4. **Preserve compatibility** - Create module aliases so existing code continues to work

### Phase 2: Update dependent apps

1. **aria_core** - Change dependency from aria_engine_core to aria_hybrid_planner
2. **aria_membrane_pipeline** - Update imports and dependency declarations
3. **aria_blocks_world** - Update imports and dependency declarations
4. **Update umbrella mix.exs** - Remove aria_engine_core from umbrella dependencies

### Phase 3: Clean removal

1. **Remove aria_engine_core directory** entirely
2. **Update any remaining references** in documentation, configs, etc.

## Benefits

- **Simplified architecture** - One planning app instead of two
- **Clearer separation of concerns** - No more wrapper/implementation split
- **Easier maintenance** - All planning logic in one place
- **Better performance** - Eliminates extra delegation layer

## Risks & Mitigation

- **Breaking changes** - Mitigate with careful module aliasing and API preservation
- **Test failures** - Will need comprehensive test updates across multiple apps
- **Import dependencies** - Need to carefully merge dependency lists
