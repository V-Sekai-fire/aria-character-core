hat# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the temporal planner component of aria_timestrike_core.

## Current Architecture

**The complete temporal planner architecture is defined through ADRs 034-047:**

- **ADR-034**: Definitive Temporal Planner Architecture (foundation)
- **ADR-035**: Canonical Temporal Backtracking Problem (test case)
- **ADR-037**: Timeline-Based vs Durative Actions (approach selection)
- **ADR-040**: Temporal Constraint Solver Selection (algorithm choice)
- **ADR-041**: Temporal Solver Tech Stack Requirements (implementation stack)
- **ADR-042**: Temporal Planner Cold Boot Implementation Order (TDD roadmap)
- **ADR-043**: Total Order to Partial Order Transformation (optimization)
- **ADR-044**: Temporal Planner as Auto Battler AI (stakeholder communication)
- **ADR-045**: Allen's Interval Algebra for Temporal Relationships (constraint specification)
- **ADR-046**: User-Friendly Temporal Constraint Specification (developer productivity)
- **ADR-047**: TimeStrike Temporal Planner Test Scenario (comprehensive validation)

ADRs 036, 038, and 039 are deprecated. ADRs 001-033 have been superseded by the current architecture and serve as historical records.

## Overview

These ADRs document the evolution of design decisions for the temporal, re-entrant goal-task-network (GTN) planner implementation. Each ADR follows a standard format and captures:

- **Status**: Current state (Proposed, Accepted, Superseded)
- **Context**: Background and problem statement
- **Decision**: What was decided
- **Rationale**: Why this decision was made
- **Implementation**: Technical details and approach
- **Consequences**: Positive and negative impacts

## ADR Index

### Current Architecture (034-044)

- **034**: **Definitive Temporal Planner Architecture** _(Architecture foundation)_
- **035**: **Canonical Temporal Backtracking Problem** _(Definitive test case for temporal reasoning)_
- **037**: **Timeline-Based vs Durative Actions** _(Timeline planning approach selection)_
- **040**: **Temporal Constraint Solver Selection** _(PC-2 algorithm for STN solving)_
- **041**: **Temporal Solver Tech Stack Requirements** _(Pure Elixir implementation stack)_
- **042**: **Temporal Planner Cold Boot Implementation Order** _(TDD implementation roadmap)_
- **043**: **Total Order to Partial Order Transformation** _(Optimization algorithm for constraint solving)_
- **044**: **Temporal Planner as Auto Battler AI** _(Stakeholder communication framework)_

### Enhanced User Experience & Testing (045-047)

- **045**: **Allen's Interval Algebra for Temporal Relationships** _(Interval constraint specification)_
- **046**: **User-Friendly Temporal Constraint Specification** _(Developer productivity enhancements)_
- **047**: **TimeStrike Temporal Planner Test Scenario** _(Comprehensive planner validation scenario)_

### Deprecated Current Architecture

- **036**: **Evolving AriaEngine Planner Blueprint** _(Deprecated by ADR-042)_
- **038**: **Timeline-Based Temporal Planner Implementation** _(Deprecated by ADR-042)_
- **039**: **Temporal Planner Reentrancy & Stability** _(Marked not necessary)_

### Historical Evolution (Superseded)

The following ADRs document the historical evolution of the temporal planner architecture. They have been superseded by ADR-034 but remain for historical reference.

### Core Architecture (001-004)

- **001**: State Architecture Migration
- **002**: Oban Queue Design
- **003**: Game Engine Separation
- **004**: Mandatory Stability Verification

### Domain & Testing (005)

- **005**: TimeStrike as Test Domain

### Real-time Systems (006-013)

- **006**: Game Engine Integration & Real-time Execution
- **007**: Conviction Choice Mechanics
- **008**: Web Interface Implementation Details
- **009**: Action Duration & Movement Calculations
- **010**: Map & Terrain System
- **011**: Oban Queue Idempotency & Intent Rejection
- **012**: Real-Time Input System
- **013**: Opportunity Window Mechanics

### User Experience (014-015, 021)

- **014**: Twitch Streaming Optimization
- **015**: Imperfect Information & Dynamic Opportunities
- **021**: Realistic Tension Pacing (Corrects ADR-014)

### Project Management (016-018)

- **016**: Friday-Sunday Implementation Scope
- **017**: LLM-Assisted Development Time Uncertainty
- **018**: Concrete MVP Definition

### Technical Infrastructure (019-020, 022-030)

- **019**: 3D Coordinates with Godot Conventions
- **020**: Design Consistency Verification
- **022**: First Implementation Step - Test-Driven Development
- **023**: MVP Timing Implementation Strategy
- **024**: Absolute Minimum Success Criteria
- **025**: Research Question Resolution Strategy
- **026**: Implementation Risk Mitigation
- **027**: Web Interface Implementation _(Superseded by ADR-030)_
- **028**: Three.js 3D Visualization Architecture _(Superseded by ADR-030)_
- **029**: MCP Integration for GitHub Copilot
- **030**: Console TUI Implementation _(Supersedes ADR-027, ADR-028)_
- **031**: Strategic Focus - TimeStrike vs Tool Integration

## Design Consistency

**Current Architecture**: The temporal planner architecture is distributed across ADRs 034-044, with each ADR focusing on a specific aspect:

- **ADR-034**: Overall architecture and requirements
- **ADR-035**: Canonical test problem for validation
- **ADR-037**: Timeline vs durative action planning approach
- **ADR-040-041**: Constraint solver and tech stack selection
- **ADR-042**: Implementation order and TDD methodology
- **ADR-043**: Performance optimization through parallelization
- **ADR-044**: Stakeholder communication through gaming analogies

**Cross-Reference Consistency**: All active ADRs maintain proper cross-references to ensure architectural coherence.

**Historical Evolution**: The superseded ADRs (001-033) were verified for mutual consistency during their active period and demonstrate the incremental evolution toward the final temporal planner design.

## Maintenance

**Current Process**: Architectural changes should be made to the appropriate ADR in the 034-047 series based on the concern:

- **ADR-034**: Core architecture modifications
- **ADR-035**: Test case updates or new canonical problems
- **ADR-037**: Timeline planning approach changes
- **ADR-040-041**: Solver algorithm or tech stack changes
- **ADR-042**: Implementation order or TDD methodology updates
- **ADR-043**: Performance optimization changes
- **ADR-044**: Stakeholder communication improvements
- **ADR-045**: Temporal constraint specification changes
- **ADR-046**: Developer productivity and usability improvements
- **ADR-047**: Test scenario and validation framework updates

When making architectural changes:

1. Identify the appropriate ADR based on the type of change
2. Update the relevant ADR with the new decision and rationale
3. Ensure changes are consistent with cross-referenced ADRs
4. Update cross-references in other ADRs if the change affects them
5. Consider impacts on related systems and document accordingly

**Historical ADRs**: The superseded ADRs (001-033) should not be modified.

## History

These ADRs were migrated from the original `temporal_planner_design_resolutions.md` document on June 13, 2025, to provide better tracking and maintainability of individual architectural decisions.

On June 14, 2025, the temporal planner architecture was distributed across specialized ADRs (034-044) to provide focused, maintainable decision records for each architectural concern while maintaining cross-reference consistency.
