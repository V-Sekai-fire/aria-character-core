# ADR-039: Domain-Aware Primitive Task Detection

**Status:** Active  
**Date:** June 16, 2025

## Context

The HTN planner's `is_primitive_task?/1` function currently uses simple heuristics to determine if a task is primitive (an action vs. a composite task):

```elixir
defp is_primitive_task?({name, _args}) when is_atom(name), do: true
defp is_primitive_task?({name, _args}) when is_binary(name), do: false
defp is_primitive_task?(_), do: false
```

This approach fails when:

1. Actions are referenced with string names (e.g., `{"putv", [0]}`) in task method outputs
2. The domain defines actions with atom keys (e.g., `:putv`)
3. The planner incorrectly assumes string-named actions are composite tasks

The backtracking tests fail because `"putv"` and `"getv"` are not recognized as primitive actions during initial solution tree construction, even though `try_expand_node/5` correctly handles the domain lookup later.

## Decision

Replace the heuristic-based `is_primitive_task?/1` function with a domain-aware version that consults the actual domain definition to determine primitiveness.

## Implementation Plan

- [x] **Analyze the current architecture** and identify the core issue
- [ ] **Update `is_primitive_task?/1` signature** to accept domain parameter
- [ ] **Implement domain-aware primitive detection** that handles both string and atom action names
- [ ] **Update all call sites** that use `is_primitive_task?/1` to pass domain parameter
- [ ] **Verify backtracking tests pass** after the fix
- [ ] **Run full test suite** to ensure no regressions

## Technical Approach

The new function will:

1. **Normalize action names:** Convert strings to atoms consistently
2. **Consult domain directly:** Use `Domain.has_action?/2` as the authoritative source
3. **Handle both formats:** Support both `{:action, args}` and `{"action", args}` formats
4. **Maintain backward compatibility:** Preserve existing behavior for non-action tasks

```elixir
@spec is_primitive_task?(Domain.t(), todo_item()) :: boolean()
defp is_primitive_task?(domain, {name, _args}) when is_atom(name) do
  Domain.has_action?(domain, name)
end

defp is_primitive_task?(domain, {name, _args}) when is_binary(name) do
  action_atom = String.to_atom(name)
  Domain.has_action?(domain, action_atom)
end

defp is_primitive_task?(_domain, _task), do: false
```

## Consequences

**Positive:**

- **Accurate primitive detection:** Actions are correctly identified regardless of name format
- **Domain consistency:** Single source of truth for what constitutes a primitive action
- **Test reliability:** Backtracking tests will pass with correct action classification
- **Architecture clarity:** Clear separation between domain definition and planning logic

**Negative:**

- **Breaking change:** Function signature changes require updating all call sites
- **Slight performance cost:** Domain lookup for each task during tree construction
- **Increased coupling:** Planning logic becomes more tightly coupled to domain structure

## Success Criteria

- [ ] All backtracking tests pass
- [ ] No regression in existing test suite
- [ ] Domain-aware primitive detection works for both string and atom action names
- [ ] Planning performance remains acceptable (< 5% impact)

## Related ADRs

- **ADR-035**: Canonical temporal backtracking problem (the issue this fixes)
- **ADR-034**: Definitive temporal planner architecture (architectural context)
