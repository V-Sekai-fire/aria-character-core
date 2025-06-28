# ADR-163: DateTime Type Consistency

<!-- @adr_serial R25W012737B -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

Multiple test failures are caused by inconsistent DateTime type handling throughout the bridge and timeline operations. Functions attempt to perform DateTime operations on ISO8601 strings or pass incorrect argument types to DateTime functions, causing `FunctionClauseError` exceptions.

### Failing Tests

1. **Timeline.TimelineBridgeTest** - "bridges_in_range/3 finds bridges within time range"

   ```
   ** (FunctionClauseError) no function clause matching in DateTime.compare/2
   The following arguments were given to DateTime.compare/2:
       # 1: ~U[2025-01-01 11:00:00Z]
       # 2: "2025-01-01T10:00:00Z"
   ```

2. **Timeline.TimelineBridgeTest** - "segment_by_bridges/1 handles overlapping intervals correctly"

   ```
   ** (FunctionClauseError) no function clause matching in DateTime.to_iso8601/3
   The following arguments were given to DateTime.to_iso8601/3:
       # 1: "2025-01-01T10:00:00Z"
   ```

### Root Cause Analysis

**Type Mixing Issues:**

- Functions receive DateTime structs but expect ISO8601 strings
- Functions receive ISO8601 strings but expect DateTime structs  
- Inconsistent type conversion between different parts of the system
- Test setup creates mixed types without proper conversion

**Specific Problem Areas:**

- `bridges_in_range/3` compares DateTime with string
- `DateTime.to_iso8601/3` called on string instead of DateTime
- Interval creation functions receive inconsistent time formats
- Bridge position comparisons mix DateTime and string types

## Decision

**Establish consistent DateTime type handling with clear conversion boundaries and standardized internal representation.**

We'll standardize on DateTime structs for all internal temporal operations while maintaining flexible input APIs that accept both DateTime and ISO8601 strings.

### Rationale

1. **Type Safety**: DateTime structs provide compile-time type checking
2. **Performance**: Avoid repeated string parsing in temporal operations
3. **API Clarity**: Clear distinction between input flexibility and internal consistency
4. **Error Prevention**: Eliminate type mismatch errors at runtime
5. **Standards Compliance**: DateTime is Elixir's canonical time representation

## Implementation Plan

### Phase 1: Input Normalization

- [ ] Add datetime normalization functions for consistent input handling
- [ ] Update all bridge functions to normalize inputs to DateTime
- [ ] Update all timeline functions to normalize time inputs
- [ ] Ensure all temporal comparison functions work with DateTime only

### Phase 2: Internal Type Consistency

- [ ] Audit all temporal operations to ensure DateTime usage
- [ ] Fix `bridges_in_range/3` to handle mixed input types properly
- [ ] Fix interval creation to normalize time inputs
- [ ] Update segment creation to use consistent DateTime handling

### Phase 3: Test Data Consistency

- [ ] Update test setup to use consistent DateTime creation
- [ ] Fix test cases that mix DateTime and string types
- [ ] Add helper functions for test DateTime creation
- [ ] Ensure all test assertions expect correct types

### Phase 4: API Documentation and Validation

- [ ] Document input type expectations for all functions
- [ ] Add runtime type validation where appropriate
- [ ] Update function specs to reflect DateTime requirements
- [ ] Add examples showing proper type usage

## Success Criteria

- [ ] All DateTime-related test failures are resolved
- [ ] No `FunctionClauseError` exceptions in temporal operations
- [ ] Consistent DateTime usage throughout bridge operations
- [ ] Clear input type normalization at API boundaries
- [ ] All temporal comparison functions work reliably
- [ ] Test suite uses consistent DateTime types

## Consequences

### Positive

- **Type Safety**: Eliminates runtime type mismatch errors
- **Performance**: Reduces repeated string parsing overhead
- **Reliability**: Temporal operations work consistently
- **Maintainability**: Clear type expectations throughout codebase

### Negative

- **Input Validation**: Additional overhead for type normalization
- **Breaking Changes**: Functions may reject previously accepted input types
- **Complexity**: More type conversion logic at API boundaries

## Related ADRs

- **ADR-158**: Comprehensive Timeline Test Suite Validation (parent issue)
- **ADR-159**: Bridge Position Type Consistency (related DateTime handling)

## Implementation Notes

### DateTime Normalization Pattern

```elixir
defp normalize_datetime(%DateTime{} = dt), do: dt
defp normalize_datetime(iso8601_string) when is_binary(iso8601_string) do
  {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
  datetime
end
```

### Function Update Pattern

```elixir
# Before: Mixed types cause errors
def bridges_in_range(timeline, start_time, end_time) do
  # DateTime.compare fails when types don't match
end

# After: Normalize inputs first
def bridges_in_range(timeline, start_time, end_time) do
  start_dt = normalize_datetime(start_time)
  end_dt = normalize_datetime(end_time)
  # Now all comparisons work reliably
end
```

### Test Helper Functions

```elixir
# Add to test support
def datetime(iso8601_string) do
  {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
  datetime
end
```

### Type Specification Updates

```elixir
@spec bridges_in_range(t(), DateTime.t() | String.t(), DateTime.t() | String.t()) :: [Bridge.t()]
```

This approach maintains API flexibility while ensuring internal type consistency and eliminating runtime type errors.
