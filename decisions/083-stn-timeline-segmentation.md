# ADR-083: STN Timeline Segmentation Strategy

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

## Related ADRs

- **ADR-099**: STN Bridge Reentrant Planner Architecture (canonical, accurate description)
- **ADR-034**: Definitive Temporal Planner Architecture (actual planning context)
