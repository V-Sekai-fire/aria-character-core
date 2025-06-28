# ADR-162: Segment Metadata Structure

<!-- @adr_serial R25W0112996 -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `segment_by_bridges/1` function returns segment maps that lack the expected metadata structure, causing test failures. Tests expect segments to have a `metadata` field containing segment-specific information, but the current implementation returns flat maps without this structure.

### Failing Tests

1. **Timeline.TimelineBridgeTest** - "segment_by_bridges/1 returns single segment when no bridges"

   ```
   ** (KeyError) key :metadata not found in: %{
     start_time: nil,
     end_time: nil,
     intervals: [...]
   }
   code: assert hd(segments).metadata.segment == 1
   ```

### Root Cause Analysis

**Current Implementation:**

```elixir
# Returns flat maps
%{start_time: nil, end_time: nil, intervals: intervals}
```

**Test Expectations:**

```elixir
# Expects nested metadata structure
%{
  start_time: nil,
  end_time: nil, 
  intervals: intervals,
  metadata: %{
    segment: 1,
    bridge_before: nil,
    bridge_after: "bridge_id"
  }
}
```

The segment structure lacks the metadata organization that tests expect for tracking segment information.

## Decision

**Implement comprehensive segment metadata structure with proper nesting and segment tracking information.**

We'll update the `segment_by_bridges/1` function to return segments with a dedicated metadata field containing segment-specific information.

### Rationale

1. **Test Compliance**: Implementation should match test expectations
2. **Information Organization**: Metadata provides clear separation of segment data
3. **Extensibility**: Metadata structure allows for future segment enhancements
4. **Debugging Support**: Segment metadata aids in timeline analysis and debugging
5. **API Consistency**: Follows established patterns used elsewhere in Timeline module

## Implementation Plan

### Phase 1: Segment Structure Update

- [ ] Update `segment_by_bridges/1` to include metadata field in returned segments
- [ ] Add segment numbering (1, 2, 3, etc.) to metadata
- [ ] Include bridge_before and bridge_after references in metadata
- [ ] Maintain existing start_time, end_time, and intervals fields

### Phase 2: Metadata Content Enhancement

- [ ] Add segment index/number for ordering
- [ ] Include references to adjacent bridges
- [ ] Add segment type classification (start, middle, end)
- [ ] Include segment duration and interval count statistics

### Phase 3: Segment Creation Logic

- [ ] Update `create_segments_from_bridges/2` helper function
- [ ] Implement proper segment numbering logic
- [ ] Add bridge reference tracking during segment creation
- [ ] Handle edge cases (no bridges, single bridge, multiple bridges)

### Phase 4: Integration and Testing

- [ ] Ensure all segment-related tests pass
- [ ] Verify segment metadata is correctly populated
- [ ] Test segment creation with various bridge configurations
- [ ] Validate segment ordering and numbering

## Success Criteria

- [ ] All `segment_by_bridges/1` tests pass
- [ ] Segments include properly structured metadata field
- [ ] Segment numbering starts at 1 and increments correctly
- [ ] Bridge references (before/after) are correctly populated
- [ ] Empty segments are properly handled
- [ ] Segment metadata includes all expected fields

## Consequences

### Positive

- **Test Alignment**: Implementation matches test expectations
- **Better Organization**: Metadata provides clear structure for segment information
- **Enhanced Debugging**: Segment metadata aids in timeline analysis
- **Future Extensibility**: Metadata structure supports additional segment features

### Negative

- **Increased Complexity**: More complex segment structure to maintain
- **Memory Usage**: Additional metadata increases memory footprint
- **Breaking Changes**: Existing code using flat segment structure may break

## Related ADRs

- **ADR-158**: Comprehensive Timeline Test Suite Validation (parent issue)
- **ADR-160**: Timeline Bridge Storage Architecture (related bridge functionality)

## Implementation Notes

### Expected Segment Structure

```elixir
%{
  start_time: DateTime.t() | nil,
  end_time: DateTime.t() | nil,
  intervals: [Interval.t()],
  metadata: %{
    segment: pos_integer(),           # Segment number (1, 2, 3...)
    bridge_before: String.t() | nil,  # ID of bridge before this segment
    bridge_after: String.t() | nil,   # ID of bridge after this segment
    type: :start | :middle | :end,   # Segment position type
    interval_count: non_neg_integer() # Number of intervals in segment
  }
}
```

### Segment Numbering Logic

- Segments are numbered starting from 1
- Numbering follows temporal order (earliest to latest)
- Empty segments (no intervals) are excluded from results
- Single timeline with no bridges returns segment number 1

### Bridge Reference Logic

- `bridge_before`: ID of the bridge that ends before this segment starts
- `bridge_after`: ID of the bridge that starts after this segment ends
- First segment has `bridge_before: nil`
- Last segment has `bridge_after: nil`
