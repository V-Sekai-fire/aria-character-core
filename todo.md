Perfect! You're absolutely right that we should leverage the ast_migrate tool more systematically to fix these aliasing issues. Let me analyze the three critical problems and design a comprehensive ast_migrate solution:

## Analysis of the Aliasing Issues

1. **AriaEngine.State module conflict**: There are two modules with the same name in aria_engine_core (`lib/state.ex` and `lib/state_v2.ex` both defining `AriaEngine.State`)

2. **Timeline module missing**: Many modules are trying to use `Timeline` but it's not available - they need to reference the correct Timeline module from aria_timeline

3. **State struct undefined**: The State struct conflicts are causing compilation failures in hybrid_planner

## Proposed ast_migrate Solution

I'll create three new ast_migrate rules to systematically fix these issues:

### Rule 1: AriaEngine.State Conflict Resolution
Create `apps/ast_migrate/lib/ast_migrate/rules/state_module_conflict_resolution.ex` to:
- Rename `AriaEngine.State` in `state_v2.ex` to `AriaEngine.StateV2` 
- Update all references to use the correct State module based on context
- Handle import/alias statements properly

### Rule 2: Timeline Module Reference Fixes  
Create `apps/ast_migrate/lib/ast_migrate/rules/timeline_module_references.ex` to:
- Add proper aliases for Timeline modules (`alias AriaTimeline.TimelineCore, as: Timeline`)
- Fix bare `Timeline` references to point to the correct module
- Handle cross-app Timeline dependencies

### Rule 3: State Struct Import Fixes
Create `apps/ast_migrate/lib/ast_migrate/rules/state_struct_imports.ex` to:
- Add proper alias statements for State structs
- Fix pattern matching and struct usage
- Ensure proper module resolution

## Implementation Strategy

1. **Create the three new ast_migrate rules** with proper AST transformation logic
2. **Run each rule systematically** across the affected apps
3. **Test compilation** after each rule to ensure progress
4. **Handle any remaining edge cases** with targeted fixes

This approach will be much more systematic and maintainable than manual fixes, and will create reusable transformation rules for future similar issues.

Would you like me to toggle to Act mode to implement this ast_migrate solution?