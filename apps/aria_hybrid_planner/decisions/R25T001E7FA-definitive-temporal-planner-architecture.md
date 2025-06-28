# ADR-034: Definitive Temporal Planner Architecture

<!-- @adr_serial R25T001E7FA -->

## Status

Accepted (Supersedes ADR-001 through ADR-033 for temporal planner concerns)

## Date

2025-06-14

## Context

The temporal planner architecture for AriaEngine's TimeStrike implementation has evolved through 33 individual Architecture Decision Records (ADR-001 through ADR-033). While this distributed approach provided detailed decision tracking during development, it has created fragmentation and complexity for understanding the overall temporal planner design.

The current architecture spans multiple concerns across dozens of ADRs:

- State architecture and data structures (ADR-001, ADR-019)
- Queue management evolution (ADR-002 → ADR-032)
- Real-time execution systems (ADR-006, ADR-009, ADR-012, ADR-013)
- Game mechanics integration (ADR-007, ADR-010, ADR-015, ADR-021)
- Implementation strategies (ADR-022, ADR-023, ADR-024, ADR-025)
- Interface approaches (ADR-027, ADR-028 → ADR-030)
- Strategic focus decisions (ADR-031, ADR-033)

This fragmentation makes it difficult for developers to understand the complete temporal planner architecture and creates maintenance overhead when architectural changes affect multiple related ADRs.

## Decision

**Consolidate and supersede all temporal planner architectural decisions into this single definitive ADR.** All previous ADRs (001-033) are hereby superseded for temporal planner concerns, though they remain valuable historical records of the decision-making process.

## Architecture Overview

### Core Temporal Planner Design

The AriaEngine temporal planner implements a **re-entrant Goal-Task-Network (GTN) planner** with the following foundational principles:

1. **Temporal State Architecture**: All game state is temporally indexed and supports time-based queries
2. **Membrane-Based Workflow Processing**: Custom workflow system replacing database-backed job queues
3. **Real-Time Execution**: Sub-millisecond response times for player actions
4. **Console TUI Interface**: Terminal-based user interface optimized for weekend implementation
5. **Test-Driven Development**: All components validated through comprehensive test coverage

### State Architecture

**Temporal State System** (Supersedes ADR-001, ADR-019):

- All game entities (agents, actions, effects) use temporal state structures
- 3D coordinates follow Godot conventions (Y-up, right-handed coordinate system)
- Time-based queries support historical state reconstruction and future state prediction
- No backwards compatibility with legacy state structures

```elixir
# Temporal state structure example
%TemporalState{
  timestamp: DateTime.t(),
  entities: %{entity_id => EntityState.t()},
  spatial_index: SpatialIndex.t(),
  event_log: [TemporalEvent.t()]
}
```

### Workflow Processing Architecture

**Membrane-Based Job Processing** (Supersedes ADR-002, ADR-032):

- In-memory job queues using Erlang `:queue` data structures
- Membrane Core for pipeline-based job processing
- GenServer-based coordination for job dispatch and worker management
- Oban compatibility layer (`AriaQueue.Oban`) maintains existing API contracts

**Queue Architecture**:

- **Sequential Actions**: Strict temporal ordering for time-dependent operations
- **Parallel Actions**: Concurrent execution for order-independent operations
- **Immediate Responses**: High-priority queue for player feedback

### Real-Time Execution System

**Game Engine Integration** (Supersedes ADR-006, ADR-009, ADR-012, ADR-013):

- Sub-millisecond job dispatch for real-time game actions
- Action duration calculations based on movement physics
- Opportunity window mechanics for dynamic gameplay
- Real-time input system with conviction choice mechanics

**Core Execution Loop**:

1. Player input processed through conviction choice system
2. Actions validated against temporal constraints
3. Effects calculated and applied to temporal state
4. State changes propagated to interested observers
5. Opportunity windows updated based on new state

### Game Mechanics Integration

**Domain Model** (Supersedes ADR-005, ADR-007, ADR-010, ADR-015, ADR-021):

- **TimeStrike**: Tactical combat domain optimizing for weekend implementation
- **Map & Terrain System**: 3D spatial reasoning with line-of-sight calculations
- **Imperfect Information**: Dynamic opportunity discovery based on agent knowledge
- **Realistic Tension**: Balanced pacing avoiding both tedium and overwhelming complexity

**Combat Mechanics**:

- Movement calculations based on realistic physics
- Terrain affects movement speed and action availability
- Agent perception systems create fog-of-war effects
- Dynamic opportunities emerge from agent interactions

### User Interface Architecture

**Web Interface Implementation** (Supersedes ADR-008, ADR-027, ADR-028, ADR-030; Updated per ADR-068, ADR-069):

- Phoenix LiveView-based web interface for Discord shareability
- Optimized for modern web deployment and easy demonstration sharing
- Real-time updates through WebSocket connections
- Modern web visualization suitable for tactical game display

**Interface Features**:

- Real-time game state visualization through Phoenix LiveView
- Web-based user interaction with click and keyboard input
- Responsive web layout for different screen sizes
- URL-based sharing for Discord demonstrations (per ADR-069)

### Development and Testing Strategy

**Implementation Approach** (Supersedes ADR-016, ADR-017, ADR-018, ADR-022, ADR-023, ADR-024, ADR-025, ADR-026):

- **Test-Driven Development**: All components implemented with comprehensive test coverage
- **Weekend Implementation Scope**: Achievable MVP within Friday-Sunday timeline
- **Incremental Development**: Builds on existing AriaEngine infrastructure
- **Risk Mitigation**: Concrete success criteria prevent scope creep

**Minimum Success Criteria**:

1. Basic agent movement and positioning
2. Simple combat action execution
3. Real-time state updates through TUI
4. Temporal state queries for game history
5. Multi-agent coordination primitives

### External Integration Strategy

**Development Tooling** (Supersedes ADR-029, ADR-031, ADR-033):

- **Strategic Focus**: TimeStrike implementation prioritized over tool integration
- **Interface Strategy**: Web-based interaction through Phoenix LiveView eliminates need for IDE integration
- **Quality Assurance**: Comprehensive testing focused on core game functionality

## Rationale

### Architectural Consolidation Benefits

1. **Single Source of Truth**: Eliminates confusion from distributed architectural decisions
2. **Easier Maintenance**: Changes to temporal planner architecture require updating only one document
3. **Better Onboarding**: New developers can understand the complete architecture from one comprehensive document
4. **Reduced Complexity**: Eliminates need to track dependencies between 33 separate ADRs

### Technical Architecture Benefits

1. **Performance**: Membrane-based workflow system provides sub-millisecond response times
2. **Reliability**: In-memory queues eliminate database dependencies and compatibility issues
3. **Simplicity**: Console TUI avoids web framework complexity while maintaining usability
4. **Testability**: Test-driven approach ensures all components work correctly
5. **Maintainability**: Clean temporal state architecture supports extensibility

## Implementation Details

### Project Structure

```
apps/aria_timestrike/
├── lib/
│   ├── temporal_planner/        # Core temporal planning logic
│   ├── game_engine/            # Real-time execution system
│   ├── spatial_reasoning/      # 3D coordinates and terrain
│   ├── agent_system/           # Agent behavior and coordination
│   ├── workflow/               # Membrane-based job processing
│   └── tui/                    # Console terminal interface
├── test/                       # Comprehensive test coverage
└── docs/
    ├── adr/                    # This ADR and historical records
    └── api/                    # Generated documentation
```

### Development Phases

**Phase 1: Core Infrastructure** (Weekend MVP)

- Temporal state system implementation
- Basic Membrane workflow processing
- Simple TUI with agent movement
- Fundamental test coverage

**Phase 2: Game Mechanics** (Post-MVP)

- Combat system implementation
- Advanced spatial reasoning
- Multi-agent coordination
- Enhanced TUI features

**Phase 3: Advanced Features** (Future)

- Complex opportunity mechanics
- Advanced AI behaviors
- Performance optimizations
- External integrations

## Consequences

### Positive

- **Architectural Clarity**: Single comprehensive document defines entire temporal planner
- **Development Velocity**: Clear implementation roadmap reduces decision overhead
- **Quality Assurance**: TDD approach ensures reliability from the start
- **Maintainability**: Consolidated architecture easier to modify and extend
- **Weekend Deliverable**: Realistic scope achievable within tight timeline

### Negative

- **Historical Fragmentation**: Previous ADR evolution process loses some decision context
- **Large Document**: Single ADR becomes substantial and requires careful maintenance
- **Migration Effort**: Existing code must be validated against consolidated architecture

## Related Decisions

This ADR consolidates and supersedes the following temporal planner architectural decisions:

**Core Architecture**: ADR-001 (State Architecture), ADR-003 (Game Engine Separation), ADR-004 (Stability Verification)

**Infrastructure**: ADR-002 (Oban Queues → ADR-032 Membrane Workflows), ADR-019 (3D Coordinates), ADR-020 (Design Consistency)

**Real-Time Systems**: ADR-006 (Game Engine Integration), ADR-009 (Action Duration), ADR-012 (Real-Time Input), ADR-013 (Opportunity Windows)

**Game Mechanics**: ADR-005 (TimeStrike Domain), ADR-007 (Conviction Choices), ADR-010 (Map System), ADR-015 (Imperfect Information), ADR-021 (Realistic Tension)

**Implementation Strategy**: ADR-016 (Weekend Scope), ADR-017 (LLM Development), ADR-018 (MVP Definition), ADR-022 (TDD), ADR-023 (MVP Timing), ADR-024 (Success Criteria), ADR-025 (Research Strategy), ADR-026 (Risk Mitigation)

**Interface Design**: ADR-008 (Web Interface), ADR-027 (Web Implementation), ADR-028 (Three.js Visualization), ADR-030 (Console TUI), ADR-068 (Remove TUI), ADR-069 (Discord Shareable Frontend)

**Strategic Focus**: ADR-011 (Idempotency), ADR-014 (Twitch Optimization), ADR-031 (Strategic Focus), ADR-068 (Web Interface), ADR-069 (LiveView Implementation)

All superseded ADRs remain in the repository as historical records of the architectural evolution process but should not be referenced for current implementation guidance.

## Change Log

### June 16, 2025

- Removed MCP (Model Context Protocol) integration references following ADR-029 and ADR-033 cancellation
- Updated Development Tooling section to reflect focus on web interface rather than IDE integration
- Updated Related ADRs section to reference ADR-068, ADR-069 instead of cancelled MCP ADRs

### January 27, 2025

- Updated User Interface Architecture section to reflect ADR-068 (aria_tui removal) and ADR-069 (web interface choice)
- Changed from Console TUI to Phoenix LiveView web interface approach
- Updated interface features to reflect web-based rather than terminal-based implementation

## Implementation Status

**Current Status**: Architecture defined, implementation in progress
**Next Steps**:

1. Validate existing code against consolidated architecture
2. Implement missing components identified in gap analysis
3. Complete weekend MVP as defined in success criteria
4. Update documentation to reference this definitive ADR

**Implementation Roadmap**: See ADR-075 (Complete Temporal Planning Solver Implementation) for the comprehensive 84-task implementation checklist derived from this architectural foundation.

---

*This ADR represents the definitive architectural decision for the AriaEngine temporal planner. All implementation and architectural questions should reference this document rather than the superseded historical ADRs.*
