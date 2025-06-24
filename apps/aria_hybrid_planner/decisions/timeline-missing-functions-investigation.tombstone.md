# TOMBSTONE: Timeline Missing Functions Investigation

**Date:** 2025-06-23  
**Status:** TOMBSTONED - False Assumption  
**Related ADRs:** ADR-001, ADR-002

## What Was Tombstoned

Investigation into "missing" Timeline functions that were causing compilation errors in the hybrid planner.

## Why It Was Tombstoned

**FALSE ASSUMPTION:** Initial analysis incorrectly concluded that Timeline functions were missing and needed implementation.

**ACTUAL PROBLEM:** Namespace/import issue - all functions existed but were being called with wrong module reference.

## The False Investigation

### Assumed Missing Functions
- `Timeline.auto_insert_bridges/2`
- `Timeline.with_bridge_segmentation/1` 
- `Timeline.validate_all_bridge_placements/1`

### What Actually Existed
All functions were fully implemented in `apps/aria_temporal_planner/lib/timeline.ex`:

```elixir
def auto_insert_bridges(%__MODULE__{} = timeline, rules) when is_list(rules)
def with_bridge_segmentation(%__MODULE__{} = timeline)
def validate_all_bridge_placements(%__MODULE__{} = timeline)
```

## Root Cause of Confusion

**Compilation Errors:**
```
AriaEngine.Timeline.auto_insert_bridges/2 is undefined
AriaEngine.Timeline.with_bridge_segmentation/1 is undefined
AriaEngine.Timeline.validate_all_bridge_placements/1 is undefined
```

**Misleading Analysis:** Errors suggested functions didn't exist, but they existed under `Timeline.*` not `AriaEngine.Timeline.*`

## Actual Solution

**ADR-002** resolved the issue with a simple namespace alias:
```elixir
alias Timeline, as: AriaEngineTimeline
```

All function calls then worked correctly:
- `Timeline.auto_insert_bridges/2` → `AriaEngineTimeline.auto_insert_bridges/2`
- `Timeline.with_bridge_segmentation/1` → `AriaEngineTimeline.with_bridge_segmentation/1`
- `Timeline.validate_all_bridge_placements/1` → `AriaEngineTimeline.validate_all_bridge_placements/1`

## Lessons Learned

### For Future Investigations

1. **Search thoroughly** before assuming functions don't exist
2. **Distinguish namespace errors from missing implementations**
3. **Verify through multiple methods:**
   - Code search across all relevant files
   - Function signature analysis
   - Module inspection
4. **Check import/alias statements** in calling modules

### Red Flags to Watch For

- Compilation errors mentioning specific module paths
- Functions that "should exist" based on system architecture
- Errors that disappear with proper imports/aliases

### Investigation Best Practices

1. **Start with search:** `grep -r "function_name" apps/`
2. **Check module structure:** Look at the actual module files
3. **Verify imports:** Check calling module's import/alias statements
4. **Test namespace resolution:** Try different module references

## Impact

**Positive:** Prevented unnecessary implementation work and focused effort on actual problem

**Negative:** Initial ADR-001 contained incorrect analysis that needed correction

**Time Cost:** Investigation and correction effort, but prevented much larger implementation effort

## Related Files

- `apps/aria_hybrid_planner/decisions/001-timeline-module-function-implementation.md` - Corrected analysis
- `apps/aria_hybrid_planner/decisions/002-fix-timeline-namespace-references.md` - Actual solution
- `apps/aria_temporal_planner/lib/timeline.ex` - Contains all the "missing" functions

## Tombstone Reason

This investigation was based on a false assumption. All Timeline functions existed and were fully implemented. The compilation errors were due to namespace/import issues, not missing functionality.

**Resolution:** Namespace aliasing in ADR-002 resolved all compilation errors without any new implementation.
