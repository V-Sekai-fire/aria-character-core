# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the temporal planner component of aria_timestrike.

## Current Architecture

**All temporal planner architectural decisions are now consolidated in [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md).**

**The migration strategy from current AriaEngine to temporal AriaEngine is defined in [ADR-035: AriaEngine Temporal Migration Strategy with Control Theory Verification](035-aria-engine-temporal-migration-strategy.md).**

ADRs 001-033 have been superseded by ADR-034 and serve as historical records of the architectural evolution process. For current implementation guidance, reference ADR-034 and ADR-035 exclusively.

## Overview

These ADRs document the evolution of design decisions for the temporal, re-entrant goal-task-network (GTN) planner implementation. Each ADR follows a standard format and captures:

- **Status**: Current state (Proposed, Accepted, Superseded)
- **Context**: Background and problem statement
- **Decision**: What was decided
- **Rationale**: Why this decision was made
- **Implementation**: Technical details and approach
- **Consequences**: Positive and negative impacts

## ADR Index

### Current Architecture

- **034**: **Definitive Temporal Planner Architecture** _(Supersedes ADR-001 through ADR-033)_
- **035**: **AriaEngine Temporal Migration Strategy with Control Theory Verification** _(Migration path and verification framework)_
- **035**: **AriaEngine to Temporal AriaEngine Migration Strategy**

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

**Current Architecture**: All architectural decisions are consolidated in ADR-034. This ensures complete consistency and eliminates conflicts between distributed decisions.

**Historical Evolution**: The superseded ADRs (001-033) were verified for mutual consistency during their active period and demonstrate the incremental evolution of the temporal planner design.

## Maintenance

**Current Process**: All temporal planner architectural changes should be made to ADR-034. The historical ADRs (001-033) should not be modified.

When making architectural changes:

1. Update ADR-034 with the new decision and rationale
2. Ensure changes are consistent with the overall architecture
3. Update implementation status and consequences sections
4. Consider impacts on related systems and document accordingly

## History

These ADRs were migrated from the original `temporal_planner_design_resolutions.md` document on June 13, 2025, to provide better tracking and maintainability of individual architectural decisions.

On June 14, 2025, all temporal planner decisions were consolidated into ADR-034 to eliminate architectural fragmentation and provide a single source of truth for the temporal planner architecture.
