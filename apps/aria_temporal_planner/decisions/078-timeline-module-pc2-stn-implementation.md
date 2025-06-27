# ADR-078: Timeline Module with ~~PC-2~~ (Replaced with MiniZinc v0.2.0) STN Implementation

<!-- @adr_serial R25T0079D35 -->

**Status:** Deferred  
**Date:** June 15, 2025  
**Closure Date:** June 21, 2025  
**Extracted from:** ADR-075 Task 10

## Context

Task 10 from ADR-075 requires implementing `AriaEngine.Timeline` module with interval-based storage that uses the ~~Path Consistency (PC-2) algorithm~~ (Replaced with MiniZinc v0.2.0) for optimal Simple Temporal Network (STN) solving. This implementation must integrate findings from multiple ADRs regarding Allen's interval algebra, usability improvements, and the agent vs entity distinction.

### Key Requirements from ADR Review

**From ADR-040 (Temporal Constraint Solver Selection):**

- ~~PC-2 algorithm~~ (Replaced with MiniZinc v0.2.0) is mandatory for STN solving
- Must handle temporal constraint networks efficiently
- Algorithm provides optimal constraint propagation

**From ADR-045 (Allen's Interval Algebra):**

- Implement usability improvements to Allen's interval notation
- Provide fluent APIs for interval relationships
- Support user-friendly relation names and i18n
- Enable pipeline-based constraint building
- Add semantic sugar for agents/entities

**From ADR-037 (Timeline-based vs Durative Actions):**

- Timeline planning context for action scheduling
- Integration with existing workflow systems

## Decision

Implement `AriaEngine.Timeline` module with the following architecture:

### Core Components

1. **Timeline Storage**: Interval-based storage system
2. **~~PC-2~~ (Replaced with MiniZinc v0.2.0) STN Solver**: Path Consistency algorithm implementation
3. **Allen's Interval API**: Usability-enhanced interval relationship interface
4. **Constraint Builder**: Pipeline-based constraint construction
5. **Agent/Entity Support**: Semantic distinctions for timeline participants

### Implementation Approach

- Create modular design with clear separation of concerns
- Implement ~~PC-2 algorithm~~ (Replaced with MiniZinc v0.2.0) with optimal performance characteristics
- Provide both low-level and high-level APIs for different use cases
- Ensure integration with existing AriaEngine workflow systems

## Implementation Plan

### Phase 1: Core Timeline Structure

- [ ] Create `AriaEngine.Timeline` module with basic structure
- [ ] Implement interval-based storage data structures
- [ ] Add basic timeline creation and manipulation functions
- [ ] Create comprehensive test suite for core functionality

### Phase 2: ~~PC-2~~ (Replaced with MiniZinc v0.2.0) STN Solver Integration

- [ ] Implement ~~Path Consistency (PC-2) algorithm~~ (Replaced with MiniZinc v0.2.0)
- [ ] Create STN constraint representation system
- [ ] Add constraint propagation and consistency checking
- [ ] Implement temporal network solving functions
- [ ] Add performance optimization for constraint networks

### Phase 3: Allen's Interval Algebra Enhancement

- [ ] Implement fluent API for interval relationships
- [ ] Add user-friendly relation names and descriptions
- [ ] Create pipeline-based constraint building system
- [ ] Add semantic sugar for agent/entity distinctions
- [ ] Implement i18n support for interval relations

### Phase 4: Integration and Optimization

- [ ] Integrate with existing AriaEngine workflow systems
- [ ] Add comprehensive error handling and validation
- [ ] Implement performance monitoring and metrics
- [ ] Create usage examples and documentation
- [ ] Add integration tests with other AriaEngine modules

## Success Criteria

- [ ] `AriaEngine.Timeline` module successfully created and functional
- [ ] ~~PC-2 algorithm~~ (Replaced with MiniZinc v0.2.0) correctly implements STN solving with optimal performance
- [ ] Allen's interval algebra API provides all identified usability improvements
- [ ] Fluent APIs enable intuitive timeline constraint construction
- [ ] Agent/entity semantic distinctions are properly supported
- [ ] All tests pass with comprehensive coverage (>90%)
- [ ] Integration with existing workflow systems works correctly
- [ ] Performance meets or exceeds requirements for expected timeline sizes
- [ ] Documentation is complete and includes usage examples

## Technical Specifications

### ~~PC-2 Algorithm~~ (Replaced with MiniZinc v0.2.0) Requirements

- Implement full ~~Path Consistency algorithm~~ (Replaced with MiniZinc v0.2.0) for STN solving
- Ensure O(n³) time complexity for constraint propagation
- Support incremental constraint addition and removal
- Provide consistency checking and conflict detection

### API Design Principles

- Follow common use cases with extensible foundation (INST-018)
- Provide simple solutions for simple problems (INST-022)
- Implement targeted solutions over generalized systems (INST-017)
- Ensure local solutions over core modifications (INST-019)

### Integration Points

- AriaEngine workflow system compatibility
- Timeline event scheduling integration
- Temporal planner architecture alignment
- Real-time execution system coordination

## Consequences

### Benefits

- Optimal STN solving performance with ~~PC-2 algorithm~~ (Replaced with MiniZinc v0.2.0)
- Enhanced usability for temporal constraint modeling
- Improved developer experience with fluent APIs
- Better semantic modeling with agent/entity distinctions
- Solid foundation for advanced temporal planning features

### Risks

- Implementation complexity of ~~PC-2 algorithm~~ (Replaced with MiniZinc v0.2.0)
- Performance optimization challenges for large timelines
- Integration complexity with existing systems
- API design decisions affecting future extensibility

### Mitigation Strategies

- Implement comprehensive test coverage for algorithm correctness
- Profile and optimize performance early in development
- Design APIs with extensibility and backward compatibility in mind
- Create clear documentation and examples for complex features

## Related ADRs

- **ADR-075**: Complete Temporal Planner Architecture (parent ADR, Task 10)
- **ADR-040**: Temporal Constraint Solver Selection (PC-2 requirement)
- **ADR-045**: Allen's Interval Algebra Temporal Relationships (usability improvements)
- **ADR-037**: Timeline-based vs Durative Actions (planning context)
- **ADR-034**: Definitive Temporal Planner Architecture (overall architecture)

## Timeline

**Target Completion:** June 22, 2025  
**Estimated Effort:** 5-7 days  
**Priority:** High (Critical path for temporal planning system)

## Progress Notes

**June 21, 2025 - Segment Closure:**
This ADR is being deferred as part of the temporal planning segment closure. The core temporal planning infrastructure has been successfully implemented through HybridCoordinatorV2 with STN temporal strategies, providing the essential functionality needed for the current segment. This comprehensive timeline module with PC-2 implementation represents future enhancement work that can be pursued in subsequent development phases.

**Current Status:** Deferred to future development phases. Core temporal planning needs are met by existing HybridCoordinatorV2 infrastructure.
