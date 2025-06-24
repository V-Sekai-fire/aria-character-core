# ADR-034: Definitive Temporal Planner Architecture (MOVED)

**Status:** Moved to `apps/aria_temporal_planner/decisions/034-definitive-temporal-planner-architecture.md`  
**Date:** 2025-06-14  
**Moved:** 2025-06-23

This ADR has been moved to the aria_temporal_planner app as it specifically concerns temporal planning functionality and architecture.

**New Location:** `apps/aria_temporal_planner/decisions/034-definitive-temporal-planner-architecture.md`

For the current version of this ADR, please refer to the new location.

## Rationale for Move

This ADR defines the core temporal planner architecture and is directly implemented by the `aria_temporal_planner` app. Moving it to the app-specific decisions directory provides:

- **Logical Organization**: Architecture decisions co-located with implementation
- **Clear Ownership**: Temporal planner app becomes self-documenting
- **Reduced Cognitive Load**: Developers working on temporal planning find all relevant decisions in one place

## Related Moved ADRs

The following related temporal planning ADRs have also been moved to `apps/aria_temporal_planner/decisions/`:

- ADR-037: Timeline-based vs Durative Actions
- ADR-038: Timeline-based Temporal Planner Implementation  
- ADR-040: Temporal Constraint Solver Selection
- ADR-041: Temporal Solver Tech Stack Requirements
- ADR-075: Complete Temporal Planning Solver
- ADR-078: Timeline Module PC-2 STN Implementation
- ADR-083: STN Timeline Segmentation
- ADR-098: STN Timeline Encapsulation
- ADR-106: Canonical Time Unit Seconds and STN Units
- ADR-119: STN Method Bridge Segmentation
- ADR-128: STN Solver MiniZinc Fallback Implementation
- ADR-152: Critical Zero Duration Contract Violation
- ADR-153: STN Fixed-Point Constraint Prohibition
- ADR-154: Timeline Module Namespace Aliasing Fixes
- ADR-155: Hybrid Planner Test Suite Restoration
- ADR-156: Cross-App Scheduler Dependencies
- ADR-157: STN Consistency Test Recovery
- ADR-158: Comprehensive Timeline Test Suite Validation
