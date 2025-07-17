# R25W065D930: Fix Non-Deterministic Base DateTime in Scheduler Timing Calculations

<!-- @adr_serial R25W065D930 -->

**Status:** Active (Paused)  
**Date:** June 20, 2025  
**Priority:** HIGH - Critical Bug

## Context

The scheduler's timing constraint functions currently use `DateTime.utc_now()` as a base datetime for relative timing calculations. This creates several critical problems:

### Current Problematic Code

```elixir
def fix_timing_constraints(scheduled_activities, original_activities) do
  # BUG: Non-deterministic base datetime
  base_datetime = DateTime.utc_now()
  # ... rest of function uses this for relative calculations
end
```

### Problems Identified

1. **Non-deterministic scheduling:** Each call to the function produces different timing results because the base datetime changes
2. **Testing impossibility:** Tests cannot verify consistent timing behavior since results vary by execution time
3. **Debugging nightmare:** Timing issues become unreproducible and impossible to debug systematically
4. **Lost temporal context:** We lose the relationship to actual planned execution times or user-specified scheduling windows
5. **Violation of temporal consistency:** Scheduling should be deterministic given the same inputs

### Impact

- Scheduler tests fail unpredictably
- Timeline integration produces inconsistent results
- Production scheduling behavior is unreliable
- Debugging temporal constraint issues is impossible

## Decision

Implement proper base datetime handling with explicit error propagation:

1. **Require explicit base datetime parameter** in all timing calculation functions
2. **Return error tuples** when base datetime is unknown or invalid
3. **Propagate temporal context** through the entire call chain
4. **Provide deterministic fallbacks** only for testing scenarios

## Implementation Plan

### Phase 1: Function Signature Updates

- [ ] Update `fix_timing_constraints/3` to require base datetime parameter
- [ ] Update `convert_plan_to_enhanced_schedule/5` to pass base datetime through
- [ ] Update `convert_simulation_to_schedule/6` to handle base datetime properly

### Phase 2: Error Handling Implementation

- [ ] Return `{:error, :missing_base_datetime}` when base datetime is nil or invalid
- [ ] Add validation for base datetime parameter (must be valid DateTime)
- [ ] Implement proper error propagation through call chain

### Phase 3: Callsite Fixes

- [ ] Fix all callsites to pass proper base datetime
- [ ] Update scheduler core to provide base datetime from scheduling context
- [ ] Ensure MCP interface passes base datetime correctly

### Phase 4: Testing and Validation

- [ ] Add tests for error conditions (missing/invalid base datetime)
- [ ] Add tests for deterministic behavior with fixed base datetime
- [ ] Verify Timeline integration works with explicit base datetime
- [ ] Test error propagation through entire call chain

## Success Criteria

1. **Deterministic scheduling:** Same inputs always produce same timing results
2. **Proper error handling:** Functions return clear error tuples for invalid temporal context
3. **All tests pass:** Scheduler tests work reliably with fixed base datetime
4. **Timeline integration:** STN solving works correctly with explicit temporal reference

## Implementation Strategy

### Step 1: Update Function Signatures

```elixir
# Before (problematic)
def fix_timing_constraints(scheduled_activities, original_activities)

# After (explicit base datetime)
def fix_timing_constraints(scheduled_activities, original_activities, base_datetime)
```

### Step 2: Add Error Handling

```elixir
def fix_timing_constraints(scheduled_activities, original_activities, base_datetime) do
  case validate_base_datetime(base_datetime) do
    {:ok, validated_datetime} ->
      # Proceed with timing calculations using validated_datetime
      {:ok, updated_activities}
    {:error, reason} ->
      {:error, reason}
  end
end

defp validate_base_datetime(nil), do: {:error, :missing_base_datetime}
defp validate_base_datetime(%DateTime{} = dt), do: {:ok, dt}
defp validate_base_datetime(_), do: {:error, :invalid_base_datetime}
```

### Step 3: Update Call Chain

Ensure base datetime flows through:

- Scheduler.Core → PlanConverter
- MCP interface → Scheduler functions
- Test fixtures provide deterministic base datetime

## Consequences

### Positive

- **Deterministic scheduling behavior** enables reliable testing and debugging
- **Clear error handling** makes temporal context requirements explicit
- **Better API design** forces callers to think about temporal reference points
- **Timeline integration reliability** improves with explicit temporal context

### Negative

- **Breaking change** requires updating all callsites
- **Additional parameter** increases function complexity slightly
- **Migration effort** needed to fix existing code

## Related ADRs

- **R25W063FA55**: Canonical Time Unit Seconds and STN Units
- **apps/aria_timeline/decisions/R25W0556B01**: STN Timeline Encapsulation
- **apps/aria_timeline/decisions/R25W0389D35**: Timeline Module PC-2 STN Implementation

## Current Focus

Fix the non-deterministic base datetime bug by implementing explicit base datetime parameters and proper error handling throughout the scheduler timing calculation chain.
