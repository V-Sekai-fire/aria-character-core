# R25W10069A4: Align Unigoal Method Registration with Original GTPyhop Design

<!-- @adr_serial R25W10069A4 -->

**Status:** Active (Paused)  
**Date:** June 22, 2025  
**Priority:** HIGH

## Context

AriaEngine's current unigoal method registration diverges from the original GTPyhop design in a fundamental way that breaks established HTN planning patterns.

### Current AriaEngine Design (Subject-Based)

```elixir
|> Domain.add_unigoal_method("player", &achieve_has_item_unigoal/2)
|> Domain.add_unigoal_method("gltf_buffer", &achieve_status_unigoal/2)
```

**Registration by subject (entity)**: Methods are organized around specific entities like "player" or "gltf_buffer".

### Original GTPyhop Design (Predicate-Based)

```python
gtpyhop.declare_unigoal_methods('loc', travel_by_foot, travel_by_taxi)
gtpyhop.declare_unigoal_methods('at', m_load_truck, m_unload_truck)
gtpyhop.declare_unigoal_methods('status', achieve_status_completed)
```

**Registration by predicate (property type)**: Methods are organized around state variable types like 'loc', 'at', 'status'.

### Design Rationale Analysis

**GTPyhop's predicate-based approach provides:**

- **Property-type specialization**: Each state variable type gets specialized achievement strategies
- **Domain knowledge organization**: Methods are grouped by the type of property they handle
- **Established HTN patterns**: Follows proven hierarchical task network conventions
- **Method reusability**: Same property-handling logic works across different entities

**AriaEngine's subject-based approach provides:**

- **Entity-specific strategies**: Different entities can have different goal achievement approaches
- **RDF triple compatibility**: Natural fit for subject-predicate-object triples
- **Flexible entity behavior**: Each entity type can have custom goal handling

## Decision

**Switch from subject-based to predicate-based unigoal method registration** to align with GTPyhop's proven design patterns while maintaining RDF triple compatibility.

### Rationale

1. **Maintain HTN Compatibility**: Established HTN planning systems use predicate-based organization
2. **Proven Design**: GTPyhop's approach has been validated in multiple planning domains
3. **Better Abstraction**: Property types are more stable abstractions than specific entities
4. **Method Reusability**: Status achievement logic should work for any entity with status

## Implementation Plan

### Phase 1: Update Domain API

- [ ] Modify `Domain.add_unigoal_method/3` to register by predicate instead of subject
- [ ] Update internal unigoal method lookup to use predicate-based keys
- [ ] Ensure method signature remains `method(state, [subject, object])`

### Phase 2: Fix Software Development Domain

- [x] Change registration from subject-based to predicate-based:

  ```elixir
  # Old: Domain.add_unigoal_method("gltf_buffer", &achieve_status_unigoal/2)
  # New: Domain.add_unigoal_method("status", &achieve_status_unigoal/2)
  ```

- [x] Add unigoal methods for "status" and "typespecs" predicates
- [x] Update method implementations to handle any subject with the given predicate

### Phase 3: Update Test Cases

- [x] Fix `debug_temporal_planner_stn_bridge_test.exs` registration
- [ ] Update all other test files using unigoal methods
- [ ] Verify software development domain test passes

### Phase 4: Update Documentation

- [ ] Document the predicate-based registration pattern
- [ ] Update examples to show correct usage
- [ ] Add migration guide for existing code

## Migration Strategy

### Before (Subject-Based)

```elixir
domain
|> Domain.add_unigoal_method("player", &achieve_location_unigoal/2)
|> Domain.add_unigoal_method("gltf_buffer", &achieve_status_unigoal/2)

# Method called as: achieve_location_unigoal(state, ["location", "kitchen"])
# Method called as: achieve_status_unigoal(state, ["status", "completed"])
```

### After (Predicate-Based)

```elixir
domain
|> Domain.add_unigoal_method("location", &achieve_location_unigoal/2)
|> Domain.add_unigoal_method("status", &achieve_status_unigoal/2)

# Method called as: achieve_location_unigoal(state, ["player", "kitchen"])
# Method called as: achieve_status_unigoal(state, ["gltf_buffer", "completed"])
```

### Method Signature Changes

```elixir
# Before: method receives [predicate, object]
defp achieve_status_unigoal(state, ["status", target_status]) do
  # Logic here
end

# After: method receives [subject, object]  
defp achieve_status_unigoal(state, [subject, target_status]) do
  current_status = StateV2.get_fact(state, subject, "status")
  if current_status == target_status do
    []
  else
    case target_status do
      "completed" -> [{:implement_module, [subject]}]
      "tested" -> [{:test_implementation, [subject]}]
      "documented" -> [{:document_module, [subject]}]
    end
  end
end
```

## Success Criteria

- [ ] All existing tests pass with predicate-based registration
- [ ] Software development domain planning works correctly
- [ ] Unigoal methods can handle any subject with the registered predicate
- [ ] Method lookup performance remains acceptable
- [ ] RDF triple compatibility is maintained

## Consequences

### Positive

- **HTN Compatibility**: Aligns with established hierarchical task network patterns
- **Method Reusability**: Same property-handling logic works across entities
- **Proven Design**: Leverages GTPyhop's validated architecture
- **Better Abstraction**: Property types are more stable than specific entities

### Negative

- **Breaking Change**: Requires updating all existing unigoal method registrations
- **Migration Effort**: All test cases and domains need updates
- **Temporary Disruption**: Planning will break until migration is complete

### Risks

- **Test Failures**: Existing tests will fail until updated
- **Planning Disruption**: Current planning functionality will break during migration
- **Method Signature Confusion**: Developers need to understand the new parameter order

## Related ADRs

- **R25W089FC2D**: Unified Durative Action Specification and Planner Standardization
- **R25W091EA37**: Planner Standardization Open Problems
- **R25W0923F7E**: Unified Action Specification Examples

## Implementation Notes

The key insight is that GTPyhop's design organizes methods around **property types** (predicates) rather than **specific entities** (subjects). This provides better abstraction and reusability while maintaining the ability to handle RDF-style triples.

The method signature change from `[predicate, object]` to `[subject, object]` allows methods to be more flexible and handle any entity that has the registered property type.
