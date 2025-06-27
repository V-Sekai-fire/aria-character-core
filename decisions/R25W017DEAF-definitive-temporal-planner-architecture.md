# R25W017DEAF: Definitive Temporal Planner Architecture (MOVED)

<!-- @adr_serial R25W017DEAF -->

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

- R25W0206D9D: Timeline-based vs Durative Actions
- R25W0210AA3: Timeline-based Temporal Planner Implementation  
- R25W02297A7: Temporal Constraint Solver Selection
- R25W023C3DB: Temporal Solver Tech Stack Requirements
- R25W0365EF2: Complete Temporal Planning Solver
- R25W0389D35: Timeline Module PC-2 STN Implementation
- R25W040602B: STN Timeline Segmentation
- R25W0556B01: STN Timeline Encapsulation
- R25W063FA55: Canonical Time Unit Seconds and STN Units
- R25W0773270: STN Method Bridge Segmentation
- R25W086088D: STN Solver MiniZinc Fallback Implementation
- R25W1108E80: Critical Zero Duration Contract Violation
- R25W1110FC5: STN Fixed-Point Constraint Prohibition
- R25W1123610: Timeline Module Namespace Aliasing Fixes
- R25W113CC67: Hybrid Planner Test Suite Restoration
- R25W114A09B: Cross-App Scheduler Dependencies
- R25W11580B8: STN Consistency Test Recovery
- R25W11617B8: Comprehensive Timeline Test Suite Validation
