# AriaEngineCore Implementation - COMPLETED ✅

## Summary

Successfully restructured apps/aria_engine_core to make ADR R25W1398085 authoritative over the APIs and follow standard Elixir patterns.

## Completed Tasks ✅

### ✅ Updated ADR R25W1398085 API Specification
- Fixed `plan/3` function signature to only return solution tree (no state modification during planning)
- Maintained `run_lazy/3` and `run_lazy_tree/3` returning both state and solution tree (execution modifies state)
- Added API design rationale explaining the logical distinction

### ✅ Created AriaEngineCore.Plan Module
- Extracted and formalized solution_tree type from Plan.Utils
- Made it the authoritative definition for the entire system
- Implemented complete planning data structures and utilities
- Added comprehensive documentation and helper functions

### ✅ Replaced AriaEngineCore.Planner Implementation
- Completely replaced AriaHybridPlanner.Core dependency
- Implemented all three required functions with correct ADR signatures:
  - `plan/3` - Planning only, returns `{:ok, solution_tree}` 
  - `run_lazy/3` - Planning + execution, returns `{:ok, {state, solution_tree}}`
  - `run_lazy_tree/3` - Execute pre-made plan, returns `{:ok, {state, solution_tree}}`
- Added placeholder implementations with clear TODOs for future development

### ✅ Updated Main AriaEngineCore Module
- Implemented standard Elixir external API pattern with clean delegations
- Used ADR-specified types as the one definition rule:
  - `AriaEngine.Domain.t()`
  - `AriaState.t()`
  - `AriaEngine.todo_item()`
  - `AriaEngineCore.Plan.solution_tree()`
- Proper module documentation following R25W1398085 specification

### ✅ Standard Elixir Structure Achieved
- Main `AriaEngineCore` module with clean external API
- Inner modules: `AriaEngineCore.Plan`, `AriaEngineCore.Planner`
- Proper delegation pattern with exact ADR function signatures
- Removed conflicting dependencies and type definitions

## Final API (Now Matches ADR R25W1398085 Exactly)

```elixir
# Planning only - returns solution tree
@spec plan(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: 
  {:ok, AriaEngineCore.Plan.solution_tree()} | {:error, atom()}

# Planning + execution - returns final state and solution tree  
@spec run_lazy(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: 
  {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}

# Execute pre-made plan - returns final state and updated tree
@spec run_lazy_tree(AriaEngine.Domain.t(), AriaState.t(), AriaEngineCore.Plan.solution_tree()) :: 
  {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}
```

## Implementation Status

- ✅ **ADR R25W1398085 is now authoritative** over aria_engine_core APIs
- ✅ **API signatures corrected** and logically consistent
- ✅ **Standard Elixir structure** implemented
- ✅ **AriaHybridPlanner.Core dependency removed** completely
- ✅ **Compilation successful** with no errors
- ✅ **One definition rule enforced** - ADR is single source of truth

## Next Steps (Future Development)

The placeholder implementations in AriaEngineCore.Planner need actual planning logic:

1. **Planning Logic**: Implement domain method expansion and goal resolution
2. **Action Execution**: Implement actual action lookup and execution from domains
3. **Temporal Constraints**: Add temporal constraint handling and resource allocation
4. **Failure Recovery**: Implement replanning on execution failures

## Architecture Achieved

```
AriaEngineCore (main external API)
├── AriaEngineCore.Plan (authoritative solution tree types)
├── AriaEngineCore.Planner (internal planning implementation)
└── AriaEngineCore.State (existing state management)
```

This restructuring successfully makes ADR R25W1398085 the single source of truth for aria_engine_core APIs while following standard Elixir module organization patterns.
