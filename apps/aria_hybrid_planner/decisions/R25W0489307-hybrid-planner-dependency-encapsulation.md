# R25W0489307: Hybrid Planner Dependency Encapsulation

<!-- @adr_serial R25W0489307 -->

**Status:** Proposed  
**Date:** 2025-06-17  
**Priority:** High

## Context

I can see the current hybrid goal task reentrant temporal planner has some encapsulation issues. After analyzing the structure, here are the main problems and a proposed solution:

### Current Issues

**1. Mixed Responsibilities**

- `AriaEngine.Planner` handles both planning coordination and STN bridge validation
- `Plan.Core` contains all decomposition logic in one monolithic module
- Temporal constraints are tightly coupled with HTN planning logic

**2. Leaky Abstractions**

- Solution tree internals are exposed across multiple modules
- Domain interface requires conversion logic scattered throughout
- STN validation logic is mixed with planning logic

**3. Tight Coupling**

- HTN planning is directly coupled to STN temporal validation
- State management is mixed with planning logic
- No clear separation between planning and execution engines

The current HybridCoordinator has hard-coded dependencies on:

- `AriaEngine.Plan.{plan, replan, validate_plan, run_lazy_refineahead}`
- `AriaEngine.StateV2` for state management
- `AriaEngine.Domain.get_action_metadata` for domain queries
- `AriaEngine.TemporalPlanner.{STNPlanner, STNMethod, STNAction}` for temporal validation
- Direct `Logger` calls for logging
- Hard-coded execution logic in private ExecutionEngine

This violates the Function as Object pattern we've established and prevents the hybrid planner from being truly modular and testable.

## Decision

Implement comprehensive dependency encapsulation for the hybrid planner using the Function as Object pattern with dependency injection.

### Proposed Better Encapsulation

**A. Core Engine Separation**

```
AriaEngine.HybridPlanner/
├── PlanningEngine/     # Pure HTN planning without temporal concerns
├── TemporalEngine/     # STN constraint management 
├── HybridCoordinator/  # Coordinates planning + temporal
└── ExecutionEngine/    # Separate execution from planning
```

**B. Encapsulated Data Structures**

- **SolutionTree**: Clean public interface hiding internal structure
- **PlanningContext**: Encapsulate planning state separate from world state
- **TemporalConstraints**: Encapsulate STN management with clear APIs

**C. Plugin Architecture**

- **PlanningStrategy**: Pluggable algorithms (HTN, STRIPS, etc.)
- **TemporalStrategy**: Pluggable temporal reasoning (STN, CSP, etc.)
- **ExecutionStrategy**: Pluggable execution models (lazy, eager, etc.)
- **StateStrategy**: Pluggable state management approaches
- **DomainStrategy**: Pluggable domain query interfaces
- **LoggingStrategy**: Pluggable logging approaches

**D. Clear Interfaces**

- **DomainInterface**: Clean abstraction without conversion logic
- **StateInterface**: Separate planning state from execution state
- **ConstraintInterface**: Abstract temporal constraint management

## Implementation Plan

### Phase 1: Strategy Behavior Definitions

- [x] Define strategy behaviors/protocols for each dependency type
- [x] Create strategy behavior contracts for planning, temporal, state, domain, logging, execution
- [x] Establish clear interfaces and error handling patterns
  - ✅ Created comprehensive strategy behavior definitions in `AriaEngine.HybridPlanner.Strategies`
  - ✅ Defined 6 core strategy behaviors: PlanningStrategy, TemporalStrategy, StateStrategy, DomainStrategy, LoggingStrategy, ExecutionStrategy
  - ✅ Established clear callback contracts with proper error handling patterns
  - ✅ Added strategy composition utilities and validation functions

### Phase 2: Strategy Implementation Modules

- [x] Implement default strategy modules for existing functionality
- [x] Create HTNPlanningStrategy wrapping current Plan.Core logic
- [x] Create STNTemporalStrategy wrapping current temporal validation
- [x] Create StateV2Strategy wrapping current state management
- [x] Create DomainStrategy wrapping current domain operations
- [x] Create LoggerStrategy wrapping current logging
- [x] Create LazyExecutionStrategy wrapping current execution logic
  - ✅ Created comprehensive default strategy implementations in `AriaEngine.HybridPlanner.Strategies.Default`
  - ✅ All 6 strategies now have concrete implementations wrapping existing functionality
  - ✅ Each strategy maintains compatibility with current interfaces while providing clean abstractions
  - ✅ Strategies include metadata, capability reporting, and performance profiling
  - ✅ All strategies handle errors gracefully and provide verbose logging support

### Phase 3: HybridCoordinator Refactoring

- [x] Refactor HybridCoordinator to use injected strategies instead of direct module calls
- [x] Update constructor to accept strategy objects
- [x] Modify all planning, temporal, state, domain, and execution operations to use strategies
- [x] Remove direct module dependencies from HybridCoordinator
  - ✅ Created HybridCoordinatorV2 with complete strategy-based dependency injection
  - ✅ Implemented Function as Object pattern with composable strategy objects
  - ✅ All operations (planning, temporal validation, execution, replanning) now use injected strategies
  - ✅ Added runtime strategy swapping capabilities and strategy metadata access
  - ✅ Maintained functional equivalence while eliminating hard-coded dependencies

### Phase 4: Strategy Injection Infrastructure

- [x] Create strategy factory/registry for dynamic strategy selection
- [x] Implement strategy composition utilities
- [x] Add configuration-based strategy selection
- [x] Support runtime strategy swapping for adaptive planning
  - ✅ Created StrategyFactory with comprehensive strategy registration and management
  - ✅ Implemented strategy composition and configuration validation
  - ✅ Added StrategyConfig for configuration-based strategy selection from multiple sources
  - ✅ Enabled runtime strategy swapping and adaptive configuration based on environment
  - ✅ Supports loading from application config, environment variables, and configuration files

### Phase 5: Testing and Validation

- [ ] Create mock strategies for comprehensive testing
- [ ] Validate that existing functionality works with new architecture
- [ ] Test strategy composition and substitution
- [ ] Ensure performance is maintained with strategy indirection

## Benefits

- **True Modularity**: Each strategy can be developed, tested, and maintained independently
- **Testability**: Mock strategies enable comprehensive unit testing without external dependencies
- **Flexibility**: Different strategy combinations can be used for different problem types
- **Extensibility**: New strategies can be added without modifying core coordinator logic
- **Function as Object Compliance**: Strategies become first-class, manipulable objects
- **Reduced Coupling**: Clean interfaces eliminate tight dependencies between components

## Consequences

### Positive

- Clean separation of concerns with single responsibility per strategy
- Enhanced testability through dependency injection
- Greater flexibility for different planning scenarios
- Easier maintenance and debugging of individual components
- True Function as Object architecture throughout the planner

### Negative

- Additional abstraction layer may introduce slight performance overhead
- More complex initial setup and configuration
- Requires careful interface design to avoid leaky abstractions

## Success Criteria

1. **Strategy Isolation**: Each strategy can be tested independently without external dependencies
2. **Functional Equivalence**: Existing planning functionality works identically with new architecture
3. **Strategy Substitution**: Different strategy implementations can be swapped without coordinator changes
4. **Clean Interfaces**: No internal implementation details leak through strategy boundaries
5. **Composition Support**: Multiple strategies can be combined for complex planning scenarios

## Related ADRs

- **R25W017DEAF**: Definitive Temporal Planner Architecture (establishes hybrid planning foundation)
- **R25W041FBCD**: Domain Method Naming Refactor (relates to domain strategy interface design)

This encapsulation will transform the hybrid planner into a true Function as Object system where all dependencies are injectable strategy objects, enabling maximum modularity, testability, and flexibility.
