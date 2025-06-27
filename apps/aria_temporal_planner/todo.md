I've analyzed the current `todo_item` implementation across the aria_hybrid_planner app and compared it with ADR-181's unified durative action specification. Here's what I found:

## Current State Analysis

**Current `todo_item` definitions in aria_hybrid_planner:**

1. **Plan.Core** (`apps/aria_hybrid_planner/lib/plan/core.ex`):
   ```elixir
   @type todo_item :: task() | goal() | AriaEngine.Multigoal.t()
   ```

2. **Plan.NodeExpansion** (`apps/aria_hybrid_planner/lib/plan/node_expansion.ex`):
   ```elixir
   @type todo_item :: task() | goal() | Multigoal.t()
   ```

3. **Plan.Blacklisting** (`apps/aria_hybrid_planner/lib/plan/blacklisting.ex`):
   ```elixir
   @type todo_item :: task() | goal() | AriaEngine.Multigoal.t()
   ```

**AriaEngine.Core reference:**
```elixir
@type todo_item :: Plan.todo_item()
```

## ADR-181 Compliance Issues

### Issue 1: Missing AriaEngine Namespace
The current definitions use `Multigoal.t()` instead of `AriaEngine.Multigoal.t()` in some places, creating inconsistency.

### Issue 2: Inconsistent Type Definitions
Different modules have slightly different `todo_item` definitions, which violates ADR-181's requirement for unified specifications.

### Issue 3: Missing ADR-181 Todo Item Types
ADR-181 introduces several new todo item types that aren't reflected in the current definitions:
- **Actions with temporal specifications** (duration, start, end)
- **Commands** (execution-time logic)
- **Task methods** (complex workflow decomposition)
- **Unigoal methods** (single predicate goals)
- **Multigoal methods** (multiple goal optimization)
- **Multitodo methods** (todo list optimization)

## Compliance Plan

### Phase 1: Standardize Current Types
- Update all `todo_item` definitions to use consistent AriaEngine namespacing
- Ensure all modules reference the same canonical type definition
- Fix the `Multigoal.t()` vs `AriaEngine.Multigoal.t()` inconsistency

### Phase 2: Extend Type Definition for ADR-181
Based on ADR-181's specification, the `todo_item` type should support:

```elixir
@type todo_item :: 
  task() |                           # {task_name, args}
  goal() |                           # {predicate, subject, value}
  AriaEngine.Multigoal.t() |         # Multiple goals
  action_spec() |                    # Actions with temporal specs
  command_spec() |                   # Execution-time commands
  task_method_spec() |               # Complex workflows
  unigoal_method_spec() |            # Single goal methods
  multigoal_method_spec() |          # Multi-goal methods
  multitodo_method_spec()            # Todo optimization methods
```

### Phase 3: Update Processing Logic
- Update node expansion logic to handle new todo item types
- Ensure blacklisting works with extended todo item types
- Update execution logic to properly handle temporal specifications

## Implementation Strategy

1. **Create canonical type definition** in AriaEngine.Core or a dedicated module
2. **Update all references** throughout aria_hybrid_planner to use the canonical type
3. **Extend processing logic** to handle ADR-181's new todo item types
4. **Add validation** to ensure todo items conform to ADR-181 specifications
5. **Update tests** to cover the extended todo item types

Would you like me to proceed with implementing this compliance plan? If so, please toggle to Act mode and I'll start with Phase 1: standardizing the current type definitions across all modules.