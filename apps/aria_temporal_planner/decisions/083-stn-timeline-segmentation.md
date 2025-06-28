# ADR-083: STN Timeline Segmentation Strategy

<!-- @adr_serial R25V0016FD2 -->

**Status:** Superseded (June 16, 2025)

**Superseded by:** [ADR-099: STN Bridge Reentrant Planner Architecture](099-stn-bridge-reentrant-planner-architecture.md)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related activities in this document are purely fictional game planning scenarios for the Aria character temporal reasoning system. These are not related to any real military events, actual operations, or real-world situations. This is entertainment software development for a fictional character AI system.

## Context

This ADR described a theoretical "STN bridge" architecture that was never implemented in the actual codebase. The real AriaEngine planner uses STN validation as a post-processing step for temporal consistency checking, with backtracking handled through blacklisting and replanning rather than specialized bridge structures.

## Decision

**Superseded.** The actual implementation uses solution tree planning with STN validation for temporal consistency, not "STN bridges" as described in this document.

## Implementation Details

The actual AriaEngine implementation uses:

1. **Solution tree planning** (AriaEngine.Planner) with HTN decomposition
2. **STN validation** as a post-processing step for temporal consistency  
3. **Blacklisting and replanning** for backtracking, not bridge structures
4. **Method selection** handled through standard HTN mechanisms
5. **Temporal constraint validation** using STNPlanner for consistency checking

## Evaluation: Sufficiency for Temporal Planning

**This ADR is NOT sufficient for temporal planning in the current codebase** for the following reasons:

1. **Architectural Mismatch**: The "STN bridge" approach described here was never implemented. The actual system uses direct HTN planning with STN validation, not bridge structures.

2. **Wrong Abstraction Level**: This ADR focused on timeline segmentation and bridge composition, while the real implementation operates at the level of solution trees and constraint validation.

3. **Incomplete Coverage**: The actual temporal planning involves complex interactions between:
   - HTN method selection and decomposition
   - Temporal constraint propagation during planning
   - Backtracking through blacklisting mechanisms
   - Real-time constraint validation
   - None of these are addressed by the STN bridge approach.

4. **Misleading Guidance**: Following this ADR would lead to implementing the wrong architecture entirely.

**For actual temporal planning guidance, refer to:**

- **ADR-099**: Canonical STN Bridge Reentrant Planner Architecture
- **ADR-034**: Definitive Temporal Planner Architecture
- The actual implementation in `AriaEngine.Planner` and `AriaEngine.TemporalPlanner.STNPlanner`

## Related ADRs

- **ADR-099**: STN Bridge Reentrant Planner Architecture (canonical, accurate description)
- **ADR-034**: Definitive Temporal Planner Architecture (actual planning context)
