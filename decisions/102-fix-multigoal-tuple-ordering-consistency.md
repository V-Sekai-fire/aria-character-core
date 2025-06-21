# ADR-102: Fix Multigoal Tuple Ordering Consistency

**Status:** Completed (June 18, 2025)

## Context

Investigation of the Multigoal.ex module revealed a critical tuple ordering inconsistency with StateV2 that creates fragile, confusing code and potential integration issues.

### The Problem

**StateV2 uses:** `{subject, predicate, fact_value}` (entity-first)
**Multigoal uses:** `{predicate, subject, fact_value}` (~~predicate-first~~ - Replaced with subject-predicate-fact v0.2.0)

This inconsistency was noted in ADR-101 and creates several issues:

1. **Type Definition Mismatch**: Multigoal declares goals as `{predicate, subject, fact_value}` (~~predicate-first~~ - Fixed to subject-predicate-fact v0.2.0) but StateV2 expects `{subject, predicate, fact_value}`
2. **Function Parameter Confusion**: Multigoal functions use `(predicate, subject, fact_value)` order while StateV2 uses `(subject, predicate, fact_value)`
3. **Fragile Integration**: Current code "works" only because tests use wrong parameter order and `satisfied?()` accidentally compensates
4. **Future Bug Risk**: Any new code using correct StateV2 format with Multigoal will break

### Evidence

**StateV2.ex (CORRECT format):**

```elixir
# Functions expect: (state, subject, predicate, fact_value)
StateV2.set_fact(state, "player", "location", "treasure_room")

# Triples are: {subject, predicate, fact_value}
def to_triples(%__MODULE__{data: data}) do
  Enum.map(data, fn {{subject, predicate}, fact_value} ->
    {subject, predicate, fact_value}  # ← SUBJECT FIRST
  end)
end
```

**Multigoal.ex (INCORRECT format):**

```elixir
@type goal :: {StateV2.predicate(), StateV2.subject(), AriaEngine.StateV2.fact_value()}

# Functions use: (multigoal, predicate, subject, fact_value)
Multigoal.add_goal(multigoal, "location", "player", "treasure_room")
```

**Test Evidence:**

```elixir
# Test creates state with StateV2 (subject-first):
StateV2.set_fact("player", "location", "treasure_room")

# But creates goals with Multigoal (predicate-first):
Multigoal.add_goal("location", "player", "treasure_room")
```

## Decision

Fix Multigoal.ex to use consistent StateV2 tuple ordering: `{subject, predicate, fact_value}` throughout.

## Implementation Plan

### Phase 1: Fix Core Structure ✅ COMPLETED

- [x] Update type definitions to use subject-first format
- [x] Fix all function signatures to match StateV2 conventions  
- [x] Update internal tuple creation and matching logic
- [x] Fix documentation examples to use correct format

### Phase 2: Update Tests ✅ COMPLETED

- [x] Fix all test calls to use correct parameter order
- [x] Verify goal satisfaction logic works correctly
- [x] Ensure tests pass with new consistent format

### Phase 3: Verify Integration ✅ COMPLETED

- [x] Check hybrid planner integration still works
- [x] Ensure scheduler domain converter compatibility
- [x] Run full test suite to verify no regressions

## Success Criteria

- Multigoal type definitions match StateV2 format exactly
- All function signatures use subject-first parameter order
- All tests pass with corrected parameter order
- Integration with hybrid planner remains functional
- No breaking changes to external APIs that use correct format

## Consequences

### Positive

- **Consistent API**: Multigoal now matches StateV2 conventions exactly
- **Reduced confusion**: Developers can use the same tuple order everywhere
- **Better integration**: Seamless compatibility with hybrid planner and scheduler
- **Future-proof**: New code using StateV2 format will work correctly with Multigoal

### Risks

- **Breaking change**: Any external code using the incorrect predicate-first format will break
- **Test updates required**: All existing tests need parameter order corrections

## Mitigation

- **Comprehensive testing**: Verify all functionality works with new format
- **Documentation updates**: Update all examples to show correct usage
- **Integration verification**: Ensure scheduler and hybrid planner still work correctly

## Related ADRs

- **ADR-101**: Reconnect scheduler with hybrid planner (identified this issue)
- **ADR-089**: Migrate planner to StateV2 subject predicate fact

## Completion Summary

**Completed:** June 18, 2025

### What Was Accomplished

1. **Type Definition Fixed**: Updated `@type goal` to use `{subject, predicate, fact_value}` format
2. **Function Signatures Corrected**: All functions now use subject-first parameter order:
   - `add_goal(multigoal, subject, predicate, fact_value)`
   - `remove_goal(multigoal, subject, predicate, fact_value)`
3. **Internal Logic Updated**: All tuple creation and matching uses correct format
4. **Documentation Fixed**: All examples and docstrings use consistent StateV2 format
5. **Tests Corrected**: Updated test calls to use proper parameter order
6. **Integration Verified**: Confirmed scheduler and hybrid planner compatibility

### Key Changes Made

- **multigoal.ex**: Complete rewrite of tuple handling to use subject-first format
- **goal_test.exs**: Updated all test calls to use correct parameter order
- **Documentation**: Fixed all examples to show proper StateV2 integration

### Current State

Multigoal.ex now provides complete consistency with StateV2:

- Type definitions match exactly
- Function signatures follow StateV2 conventions
- All internal logic uses subject-first tuples
- Tests verify correct behavior
- Integration with planning systems works seamlessly

### Test Results

All tests pass with the corrected tuple ordering, confirming that the fix maintains functionality while providing consistency.
