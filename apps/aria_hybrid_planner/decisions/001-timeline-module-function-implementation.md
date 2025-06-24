# ADR-001: Timeline Module Namespace and Function Resolution

**Status:** Active  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `aria_hybrid_planner` app currently fails to compile properly due to namespace issues with the Timeline module. The hybrid planner's `STNBridgeTemporalStrategy` module calls Timeline functions using `AriaEngine.Timeline.*` but the functions exist in the `Timeline` module.

### Analysis of "Missing" Functions

Investigation reveals that **most functions already exist** in `apps/aria_temporal_planner/lib/timeline.ex`:

**Functions that EXIST:**
- ✅ `Timeline.new/0` - Line 15
- ✅ `Timeline.add_interval/2` - Line 21  
- ✅ `Timeline.get_bridges/1` - Line 278
- ✅ `Timeline.add_bridge/2` - Line 248
- ✅ `Timeline.remove_bridge/2` - Line 254
- ✅ `Timeline.segment_by_bridges/1` - Line 295
- ✅ `Timeline.bridge_positions/1` - Line 309

**Functions that are ACTUALLY MISSING:**
- ❌ `Timeline.auto_insert_bridges/2` - Not implemented (verified by search)
- ❌ `Timeline.with_bridge_segmentation/1` - Not implemented (verified by search)
- ❌ `Timeline.validate_all_bridge_placements/1` - Only `validate_bridge_placement/2` exists (verified by search)

**Verification Performed:**
- Searched `apps/aria_temporal_planner/lib/timeline.ex` for `def (auto_insert_bridges|with_bridge_segmentation|validate_all_bridge_placements)` - **0 results**
- Searched entire `apps/aria_temporal_planner/lib/` for `def.*bridge.*segmentation` - **0 results**  
- Searched entire `apps/aria_temporal_planner/lib/` for `def.*auto.*insert` - **1 result** in `timeline_builder.ex` (different module, configuration-related)

### Root Cause

The hybrid planner calls `AriaEngine.Timeline.function_name()` but the functions are implemented in the `Timeline` module. This is a **namespace/import issue**, not missing implementations.

### Current State

- Timeline module exists with comprehensive functionality in `apps/aria_temporal_planner/lib/timeline.ex`
- Bridge infrastructure fully implemented in `apps/aria_temporal_planner/lib/timeline/bridge.ex`
- Interval infrastructure fully implemented in `apps/aria_temporal_planner/lib/timeline/interval.ex`
- Only 3 functions actually missing, not 10+

## Decision

Fix the namespace issues and implement only the 3 actually missing Timeline functions. This approach leverages the existing comprehensive Timeline implementation while resolving the compilation errors.

## Implementation Plan

### Phase 1: Namespace Resolution (HIGH PRIORITY)

**File**: `apps/aria_hybrid_planner/lib/hybrid_planner/strategies/default/stn_bridge_temporal_strategy.ex`

**Required Changes**:
- [ ] Add proper alias: `alias Timeline, as: AriaEngineTimeline` or similar
- [ ] Update all `AriaEngine.Timeline.*` calls to use correct module reference
- [ ] Verify function signatures match usage patterns

**Existing Functions to Alias**:
- [ ] `Timeline.new/0` → Fix namespace reference
- [ ] `Timeline.add_interval/2` → Fix namespace reference
- [ ] `Timeline.get_bridges/1` → Fix namespace reference
- [ ] `Timeline.add_bridge/2` → Fix namespace reference
- [ ] `Timeline.remove_bridge/2` → Fix namespace reference
- [ ] `Timeline.segment_by_bridges/1` → Fix namespace reference
- [ ] `Timeline.bridge_positions/1` → Fix namespace reference

### Phase 2: Implement Missing Functions (MEDIUM PRIORITY)

**File**: `apps/aria_temporal_planner/lib/timeline.ex`

**Actually Missing Functions**:
- [ ] `auto_insert_bridges/2` - Automatic bridge insertion with rules
- [ ] `with_bridge_segmentation/1` - Apply bridge segmentation to timeline
- [ ] `validate_all_bridge_placements/1` - Validate all bridges in timeline

**Implementation Patterns Needed**:
- [ ] Bridge insertion rules and logic
- [ ] Timeline segmentation application
- [ ] Comprehensive bridge validation

## Implementation Strategy

### Step 1: Fix Namespace Issues (IMMEDIATE)
1. Update hybrid planner imports to reference correct Timeline module
2. Add proper module aliases in `STNBridgeTemporalStrategy`
3. Test compilation to verify namespace resolution

### Step 2: Implement Missing Functions (QUICK WINS)
1. Implement `auto_insert_bridges/2` using existing bridge logic
2. Implement `with_bridge_segmentation/1` using existing segmentation
3. Implement `validate_all_bridge_placements/1` using existing validation

### Step 3: Integration Testing
1. Test hybrid planner compilation with namespace fixes
2. Verify function signatures match usage patterns
3. Test bridge insertion and segmentation workflows

### Current Focus: Phase 1 Namespace Resolution

The primary issue is namespace resolution, not missing implementations. This should resolve 7 out of 10 compilation warnings immediately.

## Success Criteria

- [ ] Namespace issues resolved in hybrid planner
- [ ] 3 actually missing Timeline functions implemented
- [ ] `aria_hybrid_planner` compiles without Timeline-related warnings
- [ ] Basic hybrid planner functionality restored
- [ ] Existing Timeline functions properly accessible via correct module references
- [ ] Test coverage for newly implemented functions

## Consequences

**Positive:**
- Hybrid planner becomes functional again
- Timeline module provides complete API for temporal planning
- Bridge-based planning workflows restored
- Foundation for advanced temporal planning features

**Negative:**
- Need to update module references in hybrid planner
- 3 functions still need implementation
- Risk of introducing bugs in new functions

**Risks:**
- Function signatures may not match hybrid planner expectations exactly
- Bridge insertion rules may be complex to implement correctly
- Namespace changes may affect other modules using Timeline

## Related ADRs

### Prerequisites
- **ADR-154**: Timeline Module Namespace Aliasing Fixes (foundation)
- **ADR-157**: STN Consistency Test Recovery (foundation)

### Integration Dependencies
- **ADR-158**: Comprehensive Timeline Test Suite Validation (testing framework)
- **ADR-159**: Bridge Position Type Consistency (data structure alignment)
- **ADR-160**: Timeline Bridge Storage Architecture (storage design)

## Notes

This ADR addresses the critical path issue preventing hybrid planner functionality. The implementation should prioritize getting basic functionality working quickly while building toward a comprehensive Timeline API.

The existing Bridge and Interval modules provide a solid foundation, but integration work is needed to create the unified Timeline interface expected by the hybrid planner.
