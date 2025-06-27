# R25W102F0BF: Remove Automatic Action-to-Task Conversion

<!-- @adr_serial R25W102F0BF -->

**Status:** Active (Paused)  
**Date:** 2025-06-22  
**Priority:** HIGH

## Context

AriaEngine currently implements automatic action-to-task conversion in the `Domain.resolve/2` function. When an action atom (e.g., `:pickup`) is not found in the actions registry, the system automatically falls back to looking for a task method with the string equivalent (e.g., `"pickup"`). This violates GTpyHOP's design principle of strict separation between actions and tasks.

### Current Problematic Behavior

```elixir
def resolve(name, domain) when is_atom(name) do
  case get_action(domain, name) do
    nil ->
      # PROBLEMATIC: Automatic fallback to task methods
      task_name = Atom.to_string(name)
      case get_task_methods(domain, task_name) do
        [] -> nil
        [method | _] -> {:task_method, elem(method, 1)}
      end
    action_fn ->
      {:action, action_fn}
  end
end
```

### GTpyHOP Design Principles

In GTpyHOP:

- **Actions** are primitive operations that directly modify state
- **Tasks** are higher-level operations that decompose into subtasks/actions  
- **No automatic conversion** between them - they exist in separate namespaces
- **Explicit declarations** are required for both actions and tasks

## Decision

Remove automatic action-to-task conversion while maintaining backward compatibility by generating explicit primitive task methods for any actions that are currently being used as tasks.

## Implementation Plan

### Phase 1: Audit Current Dependencies

- [ ] Search codebase for places relying on action→task conversion
- [ ] Identify affected domains (blocks_world, software_development, etc.)
- [ ] Map which actions are being used as tasks through automatic conversion
- [ ] Document current usage patterns

### Phase 2: Generate Primitive Task Methods

For each action that's being used as a task, create explicit primitive task methods:

```elixir
# Before (automatic conversion):
# resolve(:pickup, domain) falls back to task "pickup" if action :pickup not found

# After (explicit primitive task):
def build do
  domain
  |> add_action(:pickup, &pickup_action/2)
  |> add_task_method("pickup", "primitive_pickup", fn state, args ->
    # Primitive task that just calls the action
    [{:pickup, args}]
  end)
end
```

### Phase 3: Update Domain Builders

- [ ] Scan existing domain modules for actions needing primitive task wrappers
- [ ] Auto-generate primitive task method declarations
- [ ] Update domain `build/0` functions with explicit task method declarations
- [ ] Ensure naming consistency (action `:pickup` → task `"pickup"`)

### Phase 4: Remove Automatic Conversion

- [x] Update `Domain.resolve/2` to remove fallback logic
- [x] Ensure strict action/task separation in resolution
- [ ] Update error messages to be clear about namespace separation
- [ ] Update planning logic to handle strict separation

### Phase 5: Update Execution Logic

- [ ] Review `Plan.Execution` for any action→task conversion dependencies
- [ ] Ensure execution properly distinguishes actions from tasks
- [ ] Update error handling for missing actions vs missing tasks
- [ ] Verify primitive task methods work correctly in execution

### Phase 6: Testing & Validation

- [ ] Create tests for strict action/task separation
- [ ] Verify all existing functionality continues to work
- [ ] Test primitive task method generation and execution
- [ ] Add validation to prevent future automatic conversion
- [ ] Update documentation to clarify action vs task usage

## Success Criteria

1. **Zero Breaking Changes**: All existing code continues to work without modification
2. **Strict Separation**: Actions and tasks exist in completely separate namespaces
3. **Explicit Semantics**: Clear distinction between what's an action vs what's a task
4. **GTpyHOP Compliance**: Full alignment with GTpyHOP's design principles
5. **Maintainable Code**: Clear understanding of action vs task responsibilities

## Example Transformation

**Current (with automatic conversion):**

```elixir
# Domain has action :pickup but no task "pickup"
# resolve(:pickup) → {:action, pickup_fn}
# resolve("pickup") → {:task_method, pickup_fn} (automatic fallback)
```

**Target (explicit primitive tasks):**

```elixir
# Domain has both action :pickup AND task "pickup"
domain
|> add_action(:pickup, &pickup_action/2)
|> add_task_method("pickup", "primitive_pickup", fn state, args ->
  [{:pickup, args}]  # Returns action to execute
end)

# resolve(:pickup) → {:action, pickup_fn}
# resolve("pickup") → {:task_method, primitive_task_fn}
```

## Consequences

### Positive

- **GTpyHOP Compliance**: Full alignment with established planning patterns
- **Clear Semantics**: Explicit distinction between actions and tasks
- **Better Error Messages**: Clear feedback when something isn't found in the right namespace
- **Maintainable Code**: Developers understand what's an action vs task
- **Future-Proof**: Prevents confusion as the codebase grows

### Negative

- **Initial Complexity**: Need to audit and update existing domains
- **More Boilerplate**: Explicit primitive task methods for simple actions
- **Migration Effort**: Requires systematic update of domain definitions

### Risks

- **Breaking Changes**: If audit misses dependencies on automatic conversion
- **Performance**: Slight overhead from additional primitive task methods
- **Developer Confusion**: Need to educate team on new explicit requirements

## Related ADRs

- **R25W089FC2D**: Unified Durative Action Specification and Planner Standardization
- **R25W10069A4**: Align Unigoal Method Registration with GTpyHOP Design
- **R25W1015A2E**: Port GTpyHOP Blocks GTN to AriaEngine

## Implementation Notes

### Primitive Task Method Pattern

```elixir
# Standard pattern for primitive task methods
def add_primitive_task_for_action(domain, action_name) do
  task_name = Atom.to_string(action_name)
  method_name = "primitive_#{task_name}"
  
  add_task_method(domain, task_name, method_name, fn state, args ->
    [{action_name, args}]
  end)
end
```

### Domain Builder Helper

```elixir
# Helper function to automatically generate primitive tasks for all actions
def add_primitive_tasks_for_all_actions(domain) do
  Enum.reduce(domain.actions, domain, fn {action_name, _action_fn}, acc_domain ->
    add_primitive_task_for_action(acc_domain, action_name)
  end)
end
```

This migration ensures AriaEngine fully embraces GTpyHOP's design principles while maintaining complete backward compatibility through explicit primitive task method generation.
