# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the temporal planner component of aria_timestrike.

## Overview

These ADRs document all design decisions for the temporal, re-entrant goal-task-network (GTN) planner implementation. Each ADR follows a standard format and captures:

- **Status**: Current state (Proposed, Accepted, Superseded)
- **Context**: Background and problem statement
- **Decision**: What was decided
- **Rationale**: Why this decision was made
- **Implementation**: Technical details and approach
- **Consequences**: Positive and negative impacts

## ADR Index

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
- **027**: Web Interface Implementation *(Superseded by ADR-030)*
- **028**: Three.js 3D Visualization Architecture *(Superseded by ADR-030)*
- **029**: MCP Integration for GitHub Copilot
- **030**: Console TUI Implementation *(Supersedes ADR-027, ADR-028)*

## Design Consistency

All ADRs have been verified for mutual consistency and compatibility. Key design strengths:

- **Self-Correcting**: ADR-021 explicitly corrects ADR-014
- **Incremental**: Builds on existing AriaEngine infrastructure
- **Balanced**: Weekend timeline balances ambition with achievability
- **Implementation-Ready**: All decisions supported by current codebase

## Maintenance

When adding new ADRs:
1. Check consistency against all existing decisions
2. Update cross-references in related ADRs
3. Follow the established numbering scheme
4. Include proper status, context, and consequences sections

## History

These ADRs were migrated from the original `temporal_planner_design_resolutions.md` document on June 14, 2025, to provide better tracking and maintainability of individual architectural decisions.
