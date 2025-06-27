# ADR-159: Bridge Position Type Consistency

<!-- @adr_serial R25W00885D2 -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `AriaEngine.Timeline.Bridge.new/4` function has a type inconsistency issue that causes test failures. When creating bridges with ISO8601 string positions, the function internally converts them to `DateTime` structs, but tests expect the `position` field to remain as the original string format.

### Failing Tests

1. **AriaEngine.Timeline.BridgeTest** - "new/4 creates a bridge with required parameters"

   ```
   Assertion with == failed
   code:  assert bridge.position == position
   left:  ~U[2025-01-01 12:00:00Z]
   right: "2025-01-01T12:00:00Z"
   ```

### Root Cause Analysis

The Bridge module's `new/4` function has two clauses:

- `new(id, %DateTime{} = position, type, opts)` - stores DateTime directly
- `new(id, position, type, opts) when is_binary(position)` - converts string to DateTime

This creates inconsistent behavior where the internal representation differs from the input format, breaking test expectations.

## Decision

**Standardize on DateTime structs internally while maintaining API flexibility.**

The Bridge struct will always store `position` as a `DateTime` struct, but we'll update tests to expect this consistent internal representation.

### Rationale

1. **Type Safety**: DateTime structs provide better type safety and temporal operations
2. **Consistency**: All bridge operations (before?, after?, at?) work with DateTime internally
3. **Performance**: Avoids repeated string parsing in temporal comparisons
4. **Standards Compliance**: DateTime is the canonical time representation in Elixir

## Implementation Plan

### Phase 1: Test Updates

- [ ] Update `AriaEngine.Timeline.BridgeTest` to expect DateTime in position field
- [ ] Update all bridge creation in tests to use consistent expectations
- [ ] Verify all temporal comparison tests work with DateTime positions

### Phase 2: Documentation Updates  

- [ ] Update Bridge module documentation to clarify position storage format
- [ ] Add examples showing both string input and DateTime storage
- [ ] Update doctest examples to reflect DateTime storage

### Phase 3: Validation

- [ ] Run bridge-specific tests to ensure all pass
- [ ] Verify no regressions in temporal comparison functions
- [ ] Confirm API flexibility (string input) still works

## Success Criteria

- [ ] All `AriaEngine.Timeline.BridgeTest` tests pass
- [ ] Bridge position field consistently stores DateTime structs
- [ ] String inputs to `new/4` still work (converted to DateTime)
- [ ] All temporal comparison functions (before?, after?, at?) work correctly
- [ ] Documentation accurately reflects the implementation

## Consequences

### Positive

- **Type consistency**: All bridge positions are DateTime structs internally
- **Better temporal operations**: DateTime comparisons are more reliable
- **Clearer API contract**: Tests and docs reflect actual storage format

### Negative

- **Test updates required**: Existing tests need position expectation changes
- **Potential breaking change**: External code expecting string positions may break

## Related ADRs

- **ADR-158**: Comprehensive Timeline Test Suite Validation (parent issue)
- **ADR-163**: DateTime Type Consistency (related datetime handling)

## Implementation Notes

The key change is updating test expectations rather than changing the Bridge implementation, as the current DateTime storage approach is architecturally sound.
