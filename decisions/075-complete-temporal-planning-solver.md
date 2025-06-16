# ADR-075: Complete Temporal Planning Solver Implementation

## Status

Active

## Context

This ADR defines the complete implementation tasks required for a full temporal planning solver as specified in ADR-042. The solver must handle the canonical temporal backtracking problem from ADR-035 and extend the existing AriaEngine architecture with temporal planning capabilities.

**Existing AriaEngine Foundation:**

- `AriaEngine.Planner`: IPyHOP-style HTN planner with solution trees
- `AriaEngine.State`: RDF-triple based state with JSON-LD support (chibifire.com namespace)
- `AriaEngine.Domain`: Planning domain with actions, task methods, goal methods
- `AriaEngine.Plan`: Solution tree management
- `AriaEngine.Temporal`: Basic temporal state (placeholder implementation)
- `AriaEngine.Flow.Worker`: Flow integration infrastructure (placeholder)

## Decision

Extend the existing AriaEngine architecture with temporal planning capabilities using strict TDD methodology. Build upon existing JSON-LD state support and HTN planner rather than reimplementing foundational components.

## Phase 1: Temporal Foundation (Extending Existing Architecture)

### 1.1 Temporal State Extension

- [x] **Task 001**: Basic JSON-LD state infrastructure with chibifire.com namespace (existing in `AriaEngine.State`)
- [x] **Task 002**: RDF-triple state management system (existing in `AriaEngine.State`)
- [ ] **Task 003**: Extend `AriaEngine.Temporal` with time-indexed state operations
- [ ] **Task 004**: Add temporal property queries to existing state system
- [ ] **Task 005**: Implement temporal history reconstruction from existing JSON-LD state

### 1.2 HTN-Temporal Integration

- [x] **Task 006**: Core HTN planner infrastructure (existing in `AriaEngine.Planner`)
- [x] **Task 007**: Solution tree management (existing in `AriaEngine.Plan`)
- [ ] **Task 008**: Extend HTN planner with temporal reasoning capabilities
- [ ] **Task 009**: Add temporal constraints to existing domain actions

## Phase 2: Temporal Planning Components

### 2.1 Timeline Data Structure

- [ ] **Task 010**: Implement `AriaEngine.Timeline` module with interval-based storage
- [ ] **Task 011**: Add timeline conflict detection and validation
- [ ] **Task 012**: Support value interpolation for smooth temporal transitions
- [ ] **Task 013**: Implement timeline operations (merge, split, transform)
- [ ] **Task 014**: Integrate timeline with existing JSON-LD state serialization

### 2.2 Simple Temporal Network (STN) Solver

- [ ] **Task 015**: Implement `AriaEngine.STN` module with Floyd-Warshall algorithm
- [ ] **Task 016**: Add temporal constraint representation and parsing
- [ ] **Task 017**: Implement consistency checking and conflict detection
- [ ] **Task 018**: Add constraint propagation and tightening
- [ ] **Task 019**: Support incremental constraint updates

### 2.3 Temporal Constraint Integration

- [ ] **Task 020**: Extend existing `AriaEngine.Domain` with temporal constraints
- [ ] **Task 021**: Add temporal constraint validation to existing actions
- [ ] **Task 022**: Implement constraint propagation in HTN planning
- [ ] **Task 023**: Add temporal constraint visualization support
- [ ] **Task 024**: Integrate constraints with existing domain registry

### 2.4 Opportunity Window Detection

- [ ] **Task 025**: Implement `AriaEngine.OpportunityDetector` for temporal windows
- [ ] **Task 026**: Add environmental trigger detection (waypoint pauses)
- [ ] **Task 027**: Support dynamic opportunity window updates
- [ ] **Task 028**: Implement opportunity exploitation planning
- [ ] **Task 029**: Add opportunity quality assessment

## Phase 3: Goal Decomposition and Task Planning

### 3.1 Temporal Goal Decomposition

- [x] **Task 030**: Core goal decomposition infrastructure (existing in `AriaEngine.Planner`)
- [x] **Task 031**: Task dependency analysis and critical path (existing HTN methods)
- [ ] **Task 032**: Extend existing HTN decomposition with temporal constraints
- [ ] **Task 033**: Add temporal-aware primitive action generation
- [ ] **Task 034**: Implement temporal resource requirements analysis

### 3.2 Multi-Agent Coordination

- [ ] **Task 035**: Implement `AriaEngine.MultiAgentCoordinator` for agent synchronization
- [ ] **Task 036**: Add information sharing protocol planning
- [ ] **Task 037**: Support temporal coordination conflict resolution
- [ ] **Task 038**: Implement agent capability analysis
- [ ] **Task 039**: Add coordination quality metrics

## Phase 4: Backtracking and Plan Revision

### 4.1 Temporal Backtracking Engine

- [x] **Task 040**: Basic backtracking infrastructure (existing in HTN planner)
- [ ] **Task 041**: Extend existing backtracking with temporal failure analysis
- [ ] **Task 042**: Add multi-phase temporal backtracking strategy
- [ ] **Task 043**: Support cascading temporal failure detection
- [ ] **Task 044**: Implement temporal backtracking trigger analysis

### 4.2 Plan Revision System

- [ ] **Task 045**: Implement `AriaEngine.PlanRevision` for temporal constraint analysis
- [ ] **Task 046**: Add temporal constraint relaxation strategies
- [ ] **Task 047**: Support alternative temporal plan generation
- [ ] **Task 048**: Implement temporal plan quality preservation
- [ ] **Task 049**: Add emergency temporal fallback planning

## Phase 5: Performance and Integration

### 5.1 High-Performance Computing

- [x] **Task 050**: Basic Flow infrastructure (existing `AriaEngine.Flow.Worker`)
- [ ] **Task 051**: Integrate Nx tensor operations for STN solving
- [ ] **Task 052**: Add Flow parallel constraint propagation
- [ ] **Task 053**: Implement GenStage backpressure for real-time updates
- [ ] **Task 054**: Add performance monitoring and metrics
- [ ] **Task 055**: Optimize memory usage for large constraint networks

### 5.2 Real-Time Performance

- [x] **Task 056**: Basic temporal state tracking (existing test framework)
- [ ] **Task 057**: Ensure <10ms planning time for Maya scenario
- [ ] **Task 058**: Implement faster replanning than initial planning
- [ ] **Task 059**: Add incremental plan updates
- [ ] **Task 060**: Support streaming constraint modifications
- [ ] **Task 061**: Implement plan execution monitoring

## Phase 6: Advanced Temporal Reasoning

### 6.1 Temporal Heuristics

- [ ] **Task 062**: Implement temporal planning heuristics
- [ ] **Task 063**: Add deadline-aware planning strategies
- [ ] **Task 064**: Support temporal resource allocation
- [ ] **Task 065**: Implement temporal plan optimization
- [ ] **Task 066**: Add temporal plan quality metrics

### 6.2 Uncertainty Handling

- [ ] **Task 067**: Implement uncertain temporal constraints
- [ ] **Task 068**: Add probabilistic temporal reasoning
- [ ] **Task 069**: Support robust plan generation
- [ ] **Task 070**: Implement temporal contingency planning
- [ ] **Task 071**: Add temporal sensitivity analysis

## Phase 7: Integration and Validation

### 7.1 AriaEngine Integration

- [x] **Task 072**: Core HTN planner integration (existing `AriaEngine.Planner`)
- [x] **Task 073**: Domain action system (existing `AriaEngine.Domain`)
- [ ] **Task 074**: Extend existing planner with temporal domain actions
- [ ] **Task 075**: Support hybrid temporal/hierarchical planning
- [ ] **Task 076**: Implement temporal state validation
- [ ] **Task 077**: Add temporal execution monitoring

### 7.2 Canonical Problem Validation

- [x] **Task 078**: Basic 1D temporal movement tests (existing in test file)
- [x] **Task 079**: Maya coordination problem setup (existing in test file)
- [ ] **Task 080**: Implement complete Maya's Adaptive Scorch Coordination scenario
- [ ] **Task 081**: Validate multi-phase backtracking with information gathering
- [ ] **Task 082**: Test temporal coordination with opportunity windows
- [ ] **Task 083**: Verify emergency fallback scenarios
- [ ] **Task 084**: Validate performance requirements (<10ms planning)

### 7.3 Test Infrastructure

- [x] **Task 085**: Basic temporal planning test framework (existing test file)
- [ ] **Task 086**: Expand test suite to cover all temporal planning components
- [ ] **Task 087**: Add performance benchmarking tests
- [ ] **Task 088**: Implement property-based testing for temporal constraints
- [ ] **Task 089**: Add integration tests with existing AriaEngine components
- [ ] **Task 090**: Create test scenarios for all failure modes

## Success Criteria

- All 90 implementation tasks completed successfully (15 already completed)
- Maya's Adaptive Scorch Coordination problem solved with <10ms planning time
- Multi-phase backtracking functional for all canonical scenarios
- Temporal reasoning integrated with existing AriaEngine.Planner HTN capabilities
- STN solver handles 1000+ temporal constraints efficiently
- Multi-agent coordination with information sharing protocols
- Full compatibility maintained with existing AriaEngine architecture
- Comprehensive test coverage (>95%) for all temporal planning components

## Consequences

### Positive

- **Built on proven foundation**: Leverages existing HTN planner and JSON-LD state management
- **Incremental development**: Extensions to working system rather than greenfield implementation
- **Architecture consistency**: Maintains AriaEngine patterns and conventions
- **Reduced risk**: Building on tested components minimizes integration issues
- **Semantic web integration**: Existing JSON-LD support provides interoperability foundation

### Negative

- **Architectural constraints**: Must work within existing AriaEngine patterns
- **Performance considerations**: Temporal extensions may impact existing HTN performance
- **Integration complexity**: Temporal features must integrate seamlessly with HTN planning
- **Backward compatibility**: Changes must not break existing AriaEngine functionality

## Related ADRs

### Parent and Predecessor ADRs

- **ADR-049**: Enhanced Temporal Planner Implementation with Unified APIs (supersedes ADR-042)
- **ADR-042**: Temporal Planner Cold Boot Implementation Order (superseded by ADR-049)
- **ADR-034**: Definitive Temporal Planner Architecture (architectural foundation)
- **ADR-035**: Canonical Temporal Backtracking Problem (requirements specification)

### Supporting Technical ADRs

- **ADR-041**: Temporal Solver Tech Stack Requirements (Elixir/OTP performance requirements)
- **ADR-046**: User-Friendly Temporal Constraint Specification (fluent constraint APIs)
- **ADR-047**: TimeStrike Temporal Planner Test Scenario (comprehensive validation)
- **ADR-048**: Developer-Friendly APIs for Temporal Planner Implementation (developer experience)

### Implementation Dependencies

- **ADR-022**: Test-Driven Development (testing methodology foundation)
- **ADR-004**: Mandatory Stability Verification (quality assurance requirements)

### Cross-References

This revised ADR provides a realistic 90-task implementation roadmap that builds upon the existing AriaEngine architecture. It accounts for completed foundational work (HTN planner, JSON-LD state, basic test framework) and focuses implementation effort on temporal extensions rather than rebuilding working systems.

## Change Log

### June 15, 2025

- **Revised implementation plan based on actual AriaEngine architecture**
- **Marked completed tasks**: 15 tasks already implemented in existing codebase
- **Focused scope**: Temporal extensions to proven HTN planner rather than greenfield development
- **Realistic task count**: Reduced from 84 to 90 tasks with accurate completion tracking
- **Architecture alignment**: Plan now reflects actual AriaEngine.Planner, AriaEngine.State, and test infrastructure

---

*This ADR establishes a realistic implementation roadmap for temporal planning extensions to the existing AriaEngine architecture, building on proven HTN planning and JSON-LD state management foundations.*
