hat# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the temporal planner component of aria_timestrike_core.

## Current Architecture

**The complete temporal planner architecture is defined through ADRs 034-041, 043-044, and 045-049:**

- **ADR-034**: Definitive Temporal Planner Architecture (foundation)
- **ADR-035**: Canonical Temporal Backtracking Problem (test case)
- **ADR-037**: Timeline-Based vs Durative Actions (approach selection)
- **ADR-040**: Temporal Constraint Solver Selection (algorithm choice)
- **ADR-041**: Temporal Solver Tech Stack Requirements (implementation stack)
- **ADR-043**: Total Order to Partial Order Transformation (optimization)
- **ADR-044**: Temporal Planner as Auto Battler AI (stakeholder communication)
- **ADR-045**: Allen's Interval Algebra for Temporal Relationships (constraint specification)
- **ADR-046**: User-Friendly Temporal Constraint Specification (developer productivity)
- **ADR-047**: TimeStrike Temporal Planner Test Scenario (comprehensive validation)
- **ADR-048**: Developer-Friendly APIs for Temporal Planner Implementation (enhanced developer experience)
- **ADR-049**: Enhanced Temporal Planner Implementation with Unified APIs (supersedes ADR-042)

ADRs 036, 038, and 039 are deprecated. ADRs 001-033 have been superseded by the current architecture and serve as historical records.

## History

These ADRs were migrated from the original `temporal_planner_design_resolutions.md` document on June 13, 2025, to provide better tracking and maintainability of individual architectural decisions.

On June 14, 2025, the temporal planner architecture was distributed across specialized ADRs (034-044) to provide focused, maintainable decision records for each architectural concern while maintaining cross-reference consistency.
