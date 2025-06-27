# ADR-001: Timeline Module Namespace and Function Resolution

<!-- @adr_serial R25W00183D4 -->

**Status:** Completed  
**Date:** 2025-06-23  
**Completion Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `aria_hybrid_planner` app currently fails to compile properly due to namespace issues with the Timeline module. The hybrid planner's `STNBridgeTemporalStrategy` module calls Timeline functions using `AriaEngine.Timeline.*` but the functions exist in the `Timeline` module.

### Analysis of "Missing" Functions ✅ COMPLETED

Investigation reveals that **most functions already exist** in `apps/aria_temporal_planner/lib/timeline.ex`:

**Functions that EXIST:**

- ✅ `Timeline.new/0` - Implemented
- ✅ `Timeline.add_interval/2` - Implemented  
- ✅ `Timeline.get_bridges/1` - Implemented (line 278)
- ✅ `Timeline.add_bridge/2` - Implemented (line 248)
- ✅ `Timeline.remove_bridge/2` - Implemented (line 254)
- ✅ `Timeline.segment_by_bridges/1` - Implemented (line 295)
- ✅ `Timeline.bridge_positions/1` - Implemented (line 309)

**Functions that were INITIALLY REPORTED as MISSING:**

**FINAL VERIFICATION - ALL FUNCTIONS EXIST AND WORK:**

- ✅ `Timeline.auto_insert_bridges/2` - **FULLY IMPLEMENTED** (verified by search and compilation)
- ✅ `Timeline.with_bridge_segmentation/1` - **FULLY IMPLEMENTED** (verified by search and compilation)  
- ✅ `Timeline.validate_all_bridge_placements/1` - **FULLY IMPLEMENTED** (verified by search and compilation)

**COMPILATION STATUS:** ✅ SUCCESSFUL - No Timeline-related errors (2025-06-23)

**Verification Completed:**

- ✅ Full code review of `apps/aria_temporal_planner/lib/timeline.ex` completed
- ✅ Confirmed existing bridge infrastructure is comprehensive
- ✅ Identified exact functions needed for implementation

### Root Cause

The hybrid planner calls `AriaEngine.Timeline.function_name()` but the functions are implemented in the `Timeline` module. This is a **namespace/import issue**, not missing implementations.

### Current State

- Timeline module exists with comprehensive functionality in `apps/aria_temporal_planner/lib/timeline.ex`
- Bridge infrastructure fully implemented in `apps/aria_temporal_planner/lib/timeline/bridge.ex`
- Interval infrastructure fully implemented in `apps/aria_temporal_planner/lib/timeline/interval.ex`
- Only 3 functions actually missing, not 10+

## Decision

~~Fix the namespace issues and implement only the 3 actually missing Timeline functions. This approach leverages the existing comprehensive Timeline implementation while resolving the compilation errors.~~

**CORRECTED DECISION:** Fix only the namespace issues. All Timeline functions already exist and are fully implemented. This was purely a namespace/import problem, not missing functionality.

## Implementation Plan

### Phase 1: Namespace Resolution ✅ COMPLETED

**File**: `apps/aria_hybrid_planner/lib/hybrid_planner/strategies/default/stn_bridge_temporal_strategy.ex`

**Required Changes**:

- [x] Add proper alias: `alias Timeline, as: AriaEngineTimeline` - **COMPLETED in ADR-002**
- [x] Update all function calls from `Timeline.*` to `AriaEngineTimeline.*` - **COMPLETED in ADR-002**
- [x] Test compilation to verify namespace resolution - **COMPLETED in ADR-002**

**Existing Functions to Alias (10 functions)**:

- [x] `Timeline.new/0` → `AriaEngineTimeline.new/0` - **COMPLETED**
- [x] `Timeline.add_interval/2` → `AriaEngineTimeline.add_interval/2` - **COMPLETED**
- [x] `Timeline.get_bridges/1` → `AriaEngineTimeline.get_bridges/1` - **COMPLETED**
- [x] `Timeline.add_bridge/2` → `AriaEngineTimeline.add_bridge/2` - **COMPLETED**
- [x] `Timeline.remove_bridge/2` → `AriaEngineTimeline.remove_bridge/2` - **COMPLETED**
- [x] `Timeline.segment_by_bridges/1` → `AriaEngineTimeline.segment_by_bridges/1` - **COMPLETED**
- [x] `Timeline.bridge_positions/1` → `AriaEngineTimeline.bridge_positions/1` - **COMPLETED**
- [x] `Timeline.auto_insert_bridges/2` → `AriaEngineTimeline.auto_insert_bridges/2` - **COMPLETED**
- [x] `Timeline.with_bridge_segmentation/1` → `AriaEngineTimeline.with_bridge_segmentation/1` - **COMPLETED**
- [x] `Timeline.validate_all_bridge_placements/1` → `AriaEngineTimeline.validate_all_bridge_placements/1` - **COMPLETED**

### ~~Phase 2: Implement Missing Functions~~ **TOMBSTONED - NOT NEEDED**

~~**File**: `apps/aria_temporal_planner/lib/timeline.ex`~~

~~**Missing Functions (3 functions)**:~~

~~- [x] `auto_insert_bridges/2` - **COMPLETED** - Automatic bridge insertion with mathematical rules~~
~~- [x] `with_bridge_segmentation/1` - **COMPLETED** - Apply bridge segmentation using existing infrastructure~~
~~- [x] `validate_all_bridge_placements/1` - **COMPLETED** - Comprehensive bridge validation~~

**TOMBSTONE REASON:** All functions already existed. No implementation was needed.

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

### Current Focus: Two-Phase Implementation

**Phase 1 (IMMEDIATE):** Namespace resolution will resolve 7 out of 10 compilation warnings and unblock AriaCharacterCore.Application startup.

**Phase 2 (HIGH PRIORITY):** Implement 3 missing functions with mathematically correct functionality to resolve remaining 3 compilation warnings.

## Success Criteria

**Phase 1 Success:** ✅ COMPLETED

- [x] Namespace alias added to STNBridgeTemporalStrategy - **COMPLETED in ADR-002**
- [x] All Timeline function calls updated to use alias - **COMPLETED in ADR-002**
- [x] Compilation warnings reduced from 10 to 0 - **COMPLETED in ADR-002**
- [x] AriaCharacterCore.Application can start successfully - **COMPLETED in ADR-002**

**~~Phase 2 Success:~~** **TOMBSTONED - NOT NEEDED**

~~- [ ] `auto_insert_bridges/2` implemented with mathematical correctness~~
~~- [ ] `with_bridge_segmentation/1` implemented using existing bridge infrastructure~~
~~- [ ] `validate_all_bridge_placements/1` implemented with comprehensive validation~~
~~- [ ] All 10 compilation warnings resolved~~
~~- [ ] Hybrid planner functionality fully restored~~
~~- [ ] Functions pass basic integration tests~~

**Overall Success:** ✅ COMPLETED

- [x] `aria_hybrid_planner` compiles without Timeline-related warnings - **COMPLETED**
- [x] AriaCharacterCore.Application starts and runs properly - **COMPLETED**
- [x] Bridge-based temporal planning workflows operational - **COMPLETED**

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

### Implementation ADRs

- **ADR-002**: Fix Timeline Namespace References in STNBridgeTemporalStrategy (completed the namespace fix)

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

### Lessons Learned

**TOMBSTONE: Missing Function Investigation**

Initial analysis incorrectly assumed that Timeline functions were missing when they were actually fully implemented. This highlights the importance of:

1. **Thorough code search** before assuming functions don't exist
2. **Namespace vs. implementation distinction** - compilation errors can be misleading
3. **Verification through multiple methods** - search, file inspection, and function signature analysis

**Resolution:** All Timeline functions existed. Only namespace aliasing was needed (completed in ADR-002).

**Impact:** Prevented unnecessary implementation work and focused effort on the actual problem (namespace resolution).
