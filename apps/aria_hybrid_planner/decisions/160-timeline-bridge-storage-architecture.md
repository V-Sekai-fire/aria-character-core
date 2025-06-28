# ADR-160: Timeline Bridge Storage Architecture

<!-- @adr_serial R25W0090F57 -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The Timeline module has an architectural inconsistency in how bridges are stored and accessed. Tests expect bridges to be stored in a `bridges` field directly on the Timeline struct, but the implementation stores them in `timeline.metadata.bridges`. This mismatch causes multiple test failures.

### Failing Tests

1. **Timeline.TimelineBridgeTest** - "add_bridge/2 adds a bridge to timeline"

   ```
   ** (KeyError) key :bridges not found in: %Timeline{...}
   code: assert Map.has_key?(updated_timeline.bridges, "decision_1")
   ```

2. **Timeline.TimelineBridgeTest** - "chain/1 preserves bridges from all timelines"

   ```
   code: assert map_size(chained.bridges) == 0
   ```

### Root Cause Analysis

**Current Implementation:**

- Bridges stored in `timeline.metadata.bridges` (nested map)
- Access via `Map.get(timeline.metadata, :bridges, %{})`

**Test Expectations:**

- Bridges stored in `timeline.bridges` (direct field)
- Access via `timeline.bridges["bridge_id"]`

This architectural mismatch indicates a design decision that wasn't consistently applied across the codebase.

## Decision

**Add a dedicated `bridges` field to the Timeline struct for direct bridge access.**

We'll modify the Timeline struct to include a `bridges` field alongside the existing metadata storage, providing both direct access and maintaining backward compatibility.

### Rationale

1. **API Clarity**: Direct field access is more intuitive than nested metadata access
2. **Performance**: Direct field access is faster than nested map lookups
3. **Type Safety**: Dedicated field can have proper type specifications
4. **Test Consistency**: Aligns implementation with test expectations
5. **Future Extensibility**: Dedicated field allows for bridge-specific optimizations

## Implementation Plan

### Phase 1: Timeline Struct Update

- [ ] Add `bridges: %{String.t() => Bridge.t()}` field to Timeline struct
- [ ] Update Timeline.new/1 to initialize empty bridges map
- [ ] Maintain metadata.bridges for backward compatibility during transition

### Phase 2: Bridge Management Functions Update

- [ ] Update `add_bridge/2` to store in both locations (bridges field + metadata)
- [ ] Update `remove_bridge/2` to remove from both locations
- [ ] Update `get_bridge/2` to read from bridges field
- [ ] Update `get_bridges/1` to read from bridges field
- [ ] Update `update_bridge/2` to update both locations

### Phase 3: Timeline Composition Functions

- [ ] Update `chain/1` to merge bridges from all timelines
- [ ] Update `parallel_join/1` to merge bridges appropriately
- [ ] Update `intersection/2` and `union/2` to handle bridge merging
- [ ] Update `compose/2` to handle bridge composition

### Phase 4: Migration and Cleanup

- [ ] Add migration logic to move bridges from metadata to field
- [ ] Update all bridge access patterns throughout codebase
- [ ] Remove metadata.bridges storage after transition period
- [ ] Update documentation to reflect new storage architecture

## Success Criteria

- [ ] All Timeline bridge management tests pass
- [ ] Timeline struct has dedicated `bridges` field
- [ ] Bridge access uses direct field rather than metadata nesting
- [ ] Timeline composition functions properly handle bridges
- [ ] No performance regression in bridge operations
- [ ] Backward compatibility maintained during transition

## Consequences

### Positive

- **Clearer API**: Direct field access is more intuitive
- **Better Performance**: Eliminates nested map lookups
- **Type Safety**: Dedicated field enables better type checking
- **Test Alignment**: Implementation matches test expectations

### Negative

- **Struct Changes**: Timeline struct modification affects serialization
- **Migration Complexity**: Need to handle existing metadata.bridges data
- **Temporary Duplication**: During transition, bridges stored in two places

## Related ADRs

- **ADR-158**: Comprehensive Timeline Test Suite Validation (parent issue)
- **ADR-161**: Bridge Validation Implementation (related bridge functionality)

## Implementation Notes

### Timeline Struct Definition

```elixir
defstruct intervals: %{}, 
          stn: STN.new(), 
          metadata: %{}, 
          bridges: %{}
```

### Migration Strategy

During the transition period, maintain both storage locations:

1. Write to both `bridges` field and `metadata.bridges`
2. Read from `bridges` field primarily
3. Fall back to `metadata.bridges` if `bridges` field is empty
4. Remove `metadata.bridges` after full migration
