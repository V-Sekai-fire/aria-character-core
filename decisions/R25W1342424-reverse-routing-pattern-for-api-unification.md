# R25W1342424: Reverse Routing Pattern for API Unification

<!-- @adr_serial R25W1342424 -->

**Status:** Active  
**Date:** 2025-06-24  
**Priority:** Medium

## Context

When modernizing APIs and creating unified interfaces, there's often a tension between:

1. **Backward compatibility** - Existing code must continue working without changes
2. **API consistency** - New code should use clean, unified interfaces
3. **Risk management** - Changes to core functionality carry high risk of breaking existing systems
4. **Migration pressure** - Deprecation warnings create pressure to update working code

Traditional approaches typically route old APIs through new unified implementations, but this creates risk and forces migration.

## Decision

**Use reverse routing for API unification**: New unified interfaces route through existing proven APIs instead of the other way around.

### Reverse Routing Pattern

```elixir
# Traditional approach (risky):
def old_api(args) do
  IO.warn("deprecated...")
  new_unified_api(args)  # Routes to new implementation
end

# Reverse routing approach (safe):
def new_unified_api(args, opts \\ %{}) do
  case Map.get(opts, :type, :default) do
    :type_a -> old_proven_api_a(args)  # Routes to existing
    :type_b -> old_proven_api_b(args)  # Routes to existing
  end
end
```

## Implementation Strategy

### Phase 1: Identify Unification Candidates

Look for APIs that:

- Have inconsistent interfaces across similar functionality
- Would benefit from a unified entry point
- Have proven, stable existing implementations
- Are used by existing code that shouldn't be forced to migrate

### Phase 2: Create Unified Interface

1. **Design unified interface** that covers all use cases
2. **Route through existing APIs** - don't reimplement functionality
3. **Maintain explicit method names** for consistency
4. **Remove deprecation warnings** from existing APIs
5. **Test routing equivalence** - unified interface produces identical results

### Phase 3: Documentation and Adoption

1. **Document both interfaces** - old APIs remain valid, new interface available
2. **Gradual adoption** - new code can use unified interface
3. **No migration pressure** - existing code continues working unchanged

## Example: Domain Method Registration

**Before (inconsistent APIs):**

```elixir
Domain.add_task_method(domain, "move", &move/2)
Domain.add_unigoal_method(domain, "location", &achieve_location/2)  
Domain.add_multigoal_method(domain, &optimize/2)
```

**After (unified interface with reverse routing):**

```elixir
# New unified interface
Domain.add_method(domain, "move", &move/2)  # defaults to :task
Domain.add_method(domain, "achieve", &achieve/2, %{type: :unigoal, goal_type: "location"})
Domain.add_method(domain, "optimize", &optimize/2, %{type: :multigoal})

# Old APIs still work unchanged (no deprecation warnings)
Domain.add_task_method(domain, "move", &move/2)  # Still valid
```

**Implementation routes through existing APIs:**

```elixir
def add_method(domain, name, method_fn, opts \\ %{}) do
  case Map.get(opts, :type, :task) do
    :task -> add_task_method(domain, name, method_fn)      # Routes to existing
    :unigoal -> add_unigoal_method(domain, goal_type, method_fn)  # Routes to existing
    :multigoal -> add_multigoal_method(domain, method_fn)  # Routes to existing
  end
end
```

## When to Use Reverse Routing

### Ideal Scenarios

- **API standardization** across similar functionality
- **Interface unification** without breaking existing code
- **Gradual modernization** of inconsistent APIs
- **Zero-risk refactoring** of core functionality
- **Backward compatibility** requirements

### Not Suitable For

- **New functionality** that doesn't have existing implementations
- **Performance-critical paths** where routing overhead matters
- **Simple APIs** that don't need unification
- **Deprecated functionality** that should be removed

## Benefits

### Technical Benefits

- **Zero risk**: All existing code paths remain untouched
- **Battle-tested**: Routes through proven, working implementations
- **Easy rollback**: Can remove unified interface without affecting anything
- **No breaking changes**: Existing APIs continue working unchanged

### Development Benefits

- **Clean migration**: New code gets unified interface, old code keeps working
- **No pressure**: Developers aren't forced to migrate working code
- **Gradual adoption**: Teams can adopt unified interface at their own pace
- **Reduced support burden**: No deprecation warnings or migration issues

### Maintenance Benefits

- **Preserved knowledge**: Existing implementations retain their documentation and context
- **Reduced testing**: Don't need to re-test proven functionality
- **Clear boundaries**: New interface is clearly a convenience wrapper
- **Simplified debugging**: Issues route to well-understood existing code

## Risks and Mitigation

### Potential Risks

1. **Interface proliferation** - Multiple ways to do the same thing
2. **Documentation overhead** - Need to document both old and new interfaces
3. **Routing complexity** - Unified interface logic can become complex

### Mitigation Strategies

1. **Clear documentation** - Explain when to use each interface
2. **Consistent patterns** - Apply reverse routing consistently across similar APIs
3. **Simple routing logic** - Keep unified interface routing straightforward
4. **Regular review** - Periodically assess if old APIs can be simplified

## Success Criteria

- [ ] Unified interface provides clean, consistent API for new code
- [ ] All existing code continues working without changes
- [ ] No deprecation warnings or migration pressure
- [ ] Unified interface produces identical results to direct API calls
- [ ] Documentation clearly explains both interface options
- [ ] Test coverage verifies routing equivalence

## Related ADRs

- **R25W091EA37**: Planner Standardization Open Problems (context for API inconsistency)
- **R25W1096996**: Strict Encapsulation Modular Testing Architecture (testing approach)

## Implementation Notes

This pattern was discovered during domain method registration unification work. The key insight was that routing new interfaces through existing proven implementations provides all the benefits of API unification without any of the risks of changing core functionality.

The pattern is particularly valuable in mature codebases where existing APIs have been battle-tested and changing them would introduce unnecessary risk.
