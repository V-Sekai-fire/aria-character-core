# ADR-132: Fix Duration Handling Precision Loss

**Status:** Active
**Date:** 2025-06-22  
**Priority:** HIGH  
**Extracted from:** ADR-131

## ❌ TOMBSTONE WARNING: FALSE COMPLETION CLAIMS

**CRITICAL**: This ADR was previously marked as "Completed" but this was incorrect.
NO implementation work has been done. Status corrected to "Active".

**Misleading Claims Removed:**
- False "Completed" status 
- All phases remain incomplete (0% progress)
- No actual precision fixes implemented

**Actual Status**: All 5 phases require implementation. This is blocking ADR-131's completion.

## Context

AriaEngine.Utils loses microsecond precision through unnecessary `round()` calls, destroying Timex's built-in microsecond precision capabilities. This affects temporal accuracy across the entire system.

## Problem Identified

**Precision Loss Points in `lib/aria_engine/utils.ex`:**
- Line 95: `Duration.to_seconds(duration) |> round()` ❌ Destroys Timex microsecond precision
- Line 67: `seconds |> round() |> seconds_to_duration_struct()` ❌ Rounds float input
- Line 75: `min_seconds |> round() |> seconds_to_duration_struct()` ❌ Rounds range values  
- Line 83: `seconds |> round() |> seconds_to_duration_struct()` ❌ Rounds numeric input
- Line 280: `Duration.to_seconds(duration) |> round()` ❌ Rounds ISO8601 conversion

## Impact Analysis

**What gets lost:**
- Milliseconds: `1.500` seconds becomes `2` seconds
- Microseconds: `1.000001` seconds becomes `1` second
- Fractional durations: `PT1.5S` becomes `PT2S`

**Where this matters:**
- High-precision timing systems
- Animation/media synchronization
- Scientific calculations
- Financial time tracking
- Scheduling systems requiring sub-second accuracy

## Timex Precision Capabilities

**Timex.Duration** internally uses **microsecond precision** and preserves fractional seconds:

```elixir
# Timex.Duration.to_seconds/1 returns a float with microsecond precision
iex> duration = Timex.Duration.parse!("PT1.123456S")
iex> Timex.Duration.to_seconds(duration)
1.123456  # ← Float with microsecond precision preserved!

# Timex can handle fractional ISO8601 durations
iex> Timex.Duration.parse!("PT1.5H")  # 1.5 hours
iex> Timex.Duration.parse!("PT30.25M") # 30.25 minutes  
iex> Timex.Duration.parse!("PT45.123S") # 45.123 seconds
```

**The Problem:** We're throwing away Timex's precision by calling `round()`.

## Decision

Preserve Timex's microsecond precision throughout the entire duration conversion chain by:

1. **Stop rounding** `Duration.to_seconds()` results
2. **Use float seconds** in our duration structs
3. **Let Timex handle** the precision conversion

## Implementation Plan

### Phase 1: Remove Precision Loss Points
**Target locations where `round()` is destroying precision:**

- [ ] **Line 95**: `Duration.to_seconds(duration) |> round()` → Remove `round()`
- [ ] **Line 67**: `seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`  
- [ ] **Line 75**: `min_seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`
- [ ] **Line 83**: `seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`
- [ ] **Line 280**: `Duration.to_seconds(duration) |> round()` → Remove `round()`

### Phase 2: Update Duration Struct Format
**Change from integer-only to float-supporting:**

```elixir
# Before (precision loss):
%{hours: 1, minutes: 30, seconds: 45}

# After (precision preserved):
%{hours: 1, minutes: 30, seconds: 45.123456}
```

### Phase 3: Update Helper Functions
**Functions that need float support:**

- [ ] **`seconds_to_duration_struct/1`**: Accept float input, preserve fractional seconds
- [ ] **`duration_struct_to_seconds/1`**: Handle float seconds in calculation
- [ ] **`valid_duration?/1`**: Accept float seconds as valid
- [ ] **`duration_to_string/1`**: Format float seconds appropriately

### Phase 4: Update Type Specifications
**Fix typespecs to reflect new float support:**

```elixir
# Update @spec annotations to allow:
@spec seconds_to_duration_struct(number()) :: map()  # number() includes float
@spec duration_struct_to_seconds(map()) :: number()  # return float when needed
```

### Phase 5: Test Precision Preservation
**Verify end-to-end precision:**

- [ ] Test fractional seconds survive full conversion chain
- [ ] Test microsecond precision preservation
- [ ] Test backward compatibility with integer inputs
- [ ] Test edge cases with very small fractional values

```elixir
# Test case: Fractional seconds survive the full conversion chain
"PT1.123456S" 
|> normalize_duration()
|> iso8601_to_duration_struct()
|> duration_struct_to_iso8601()
# Should return "PT1.123456S" (not "PT1S")
```

## Technical Implementation Details

### Updated Duration Struct Format

```elixir
# Support float seconds while maintaining backward compatibility
@type duration_struct :: %{
  hours: non_neg_integer(),
  minutes: non_neg_integer(),
  seconds: number()  # Changed from integer() to number() (includes float)
}
```

### Helper Function Updates

```elixir
# seconds_to_duration_struct/1 - preserve fractional seconds
def seconds_to_duration_struct(total_seconds) when is_number(total_seconds) do
  hours = trunc(total_seconds / 3600)
  remaining_seconds = total_seconds - (hours * 3600)
  minutes = trunc(remaining_seconds / 60)
  seconds = remaining_seconds - (minutes * 60)  # Keep as float

  %{
    hours: hours,
    minutes: minutes,
    seconds: seconds  # Float with fractional part preserved
  }
end

# duration_struct_to_seconds/1 - handle float seconds
def duration_struct_to_seconds(duration) when is_map(duration) do
  hours = Map.get(duration, :hours, 0)
  minutes = Map.get(duration, :minutes, 0)
  seconds = Map.get(duration, :seconds, 0)

  hours * 3600 + minutes * 60 + seconds  # Result is float if seconds is float
end

# valid_duration?/1 - accept float seconds
def valid_duration?(duration) when is_map(duration) do
  hours = Map.get(duration, :hours, 0)
  minutes = Map.get(duration, :minutes, 0)
  seconds = Map.get(duration, :seconds, 0)

  is_integer(hours) and hours >= 0 and
    is_integer(minutes) and minutes >= 0 and minutes < 60 and
    is_number(seconds) and seconds >= 0 and seconds < 60  # Changed to number()
end
```

## Backward Compatibility Strategy

**Safe approach:** The changes are backward compatible because:
- Integer seconds still work (1 is a valid float)
- Existing callers get more precision, not less
- Duration struct format is internal to Utils module
- All existing APIs continue to work unchanged

## Success Criteria

- [ ] **Microsecond precision preserved** through entire conversion chain
- [ ] **Timex precision utilized** instead of discarded
- [ ] **No breaking changes** to existing API
- [ ] **Better temporal accuracy** for scheduling and timing systems
- [ ] **All existing tests pass** with enhanced precision
- [ ] **New tests verify** fractional second preservation

## Consequences

**Benefits:**
- Preserves Timex's microsecond precision capabilities
- Better temporal accuracy for scheduling systems
- Enhanced support for animation and media synchronization
- Improved scientific calculation accuracy
- No breaking changes to existing code

**Risks:**
- Slightly more complex arithmetic with floats
- Potential floating-point precision edge cases
- Need to update documentation and examples

**Mitigation:**
- Comprehensive test coverage for edge cases
- Clear documentation of precision capabilities
- Gradual rollout with monitoring

## Related ADRs

- **ADR-131**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Ready for implementation
**Next Steps:** Remove `round()` calls and update duration struct format
**Timeline:** High priority - affects temporal accuracy across entire system
