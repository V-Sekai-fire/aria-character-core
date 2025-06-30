Perfect! That's a wise decision. Let's focus on the structural migration first and defer the naming to a separate effort. This keeps our current migration scope manageable and reduces complexity.

## Final Migration Plan: Structural Changes Only

### **Scope:** Keep `aria_engine_core` name, focus on architectural compliance

**Phase 1: Domain Implementation Migration to `aria_core`**

- Move `AriaEngineCore.Domain.*` implementation to `AriaCore.*`
- Update `AriaCore` external API to include domain planning functions
- Update `AriaEngineCore.Domain` to delegate to `AriaCore`

**Phase 2: Planning Implementation Migration to `aria_hybrid_planner`**

- Move `AriaEngineCore.Planner` and related implementation to `AriaHybridPlanner.*`
- Update `AriaHybridPlanner` external API to include engine integration functions
- Update `AriaEngineCore.Planner` to delegate to `AriaHybridPlanner`

**Phase 3: External API Cleanup**

- Simplify `AriaEngineCore.Core` to type aliases only
- Remove all 3+ level module nesting
- Ensure `AriaEngineCore` becomes pure delegation layer

**Phase 4: Validation**

- Verify no internal module imports across apps
- Ensure all tests pass
- Confirm architectural compliance

### **Future Technical Debt:**

- **Naming inconsistency:** `aria_engine_core` vs `aria_core` naming conflict
- **Potential rename:** Consider `aria_engine` or `aria_orchestrator` in future iteration
- **Documentation:** Update ADRs to note naming as future improvement

## Implementation Strategy

I'll use the systematic AST-based approach:

1. **Use `ast_migrate`** for comprehensive violation detection
2. **Group-based fixing** by violation type across all apps
3. **External API enhancement first** before moving implementation
4. **Continuous validation** after each phase

## Ready to Proceed?

The plan is now focused and manageable:

- **Clear scope:** Structural migration only, no renaming
- **Systematic approach:** Phase-by-phase with validation
- **Risk mitigation:** AST-based tools and incremental changes
- **Future flexibility:** Naming can be addressed in separate effort

Should I proceed with this structural migration plan? I can start with Phase 1 (Domain Implementation Migration) and work systematically through each phase while maintaining the current `aria_engine_core` name throughout.

Would you like me to toggle to Act mode and begin the implementation?
