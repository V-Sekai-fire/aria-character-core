# ADR-148: Membrane Planning System Implementation

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** HIGH  

## Context

The existing planning system was fragmented across multiple approaches (HybridCoordinatorV2, direct MiniZinc calls, etc.) without a unified interface or proper asynchronous execution. This ADR implements a complete membrane-based planning system that consolidates all strategies under a single, extensible architecture.

## Decision

Implement a unified membrane planning system with the following components:

### Core Architecture

1. **PlannerBin** - Main orchestration bin that coordinates all planning strategies
2. **StrategyRouterFilter** - Intelligent routing based on problem characteristics and user preferences
3. **Strategy Filters** - Individual filters for each planning strategy (HybridCoordinator, MiniZinc, etc.)
4. **Unified Formats** - Standardized request/response formats following ADR-134

### Key Features

- **Asynchronous Execution** - All planning operations run asynchronously with timeout handling
- **Strategy Fallback** - Automatic fallback to alternative strategies when primary fails
- **Performance Monitoring** - Comprehensive metrics collection and reporting
- **Unified Goal Format** - Standardized {subject, predicate, value} goal specification
- **Entity+Capability Model** - Consistent entity requirements following ADR-134

## Implementation Plan

### Phase 1: Core Infrastructure ✅
- [x] Create PlanningRequest format with unified goal validation
- [x] Create PlanningResponse format with comprehensive result structure
- [x] Create StrategyRequest format for internal routing
- [x] Implement PlannerBin with strategy orchestration
- [x] Implement StrategyRouterFilter with intelligent routing
- [x] Implement HybridCoordinatorFilter wrapping existing HybridCoordinatorV2

### Phase 2: Additional Strategy Filters
- [ ] Implement MiniZincSolverFilter for constraint satisfaction
- [ ] Implement LazyExecutionFilter for simple problems
- [x] Implement MockStrategyFilter for testing
- [x] Create RequestValidatorFilter for input validation
- [ ] Create RequestConverterFilter for format conversion

### Phase 3: Response Processing
- [ ] Implement ResponseAggregatorFilter for result collection
- [ ] Implement ResponseFormatterFilter for output formatting
- [ ] Add comprehensive error handling and recovery

### Phase 4: Integration and Testing
- [ ] Update existing planning interfaces to use membrane system
- [ ] Create comprehensive test suite
- [ ] Performance benchmarking and optimization
- [ ] Documentation and examples

## Technical Specifications

### Unified Goal Format (ADR-134 Compliance)

```elixir
# Goals follow subject-first format
goals = [
  {"player", "location", "room1"},
  {"chef", "task", "cooking"},
  {"oven", "temperature", 350}
]
```

### Action Specification

```elixir
# Actions use entity+capability model
Domain.add_action(:cook_meal, &cook_meal/2, %{
  duration: "PT2H",  # ISO 8601 duration
  requires_entities: [
    %{type: "agent", capabilities: [:cooking]},
    %{type: "oven", capabilities: [:heating]},
    %{type: "ingredients", capabilities: [:consumable]}
  ],
  description: "Prepare a meal using cooking equipment"
})
```

### Strategy Selection Logic

1. **User Preferences** - Honor explicit strategy preferences when valid
2. **Problem Analysis** - Route based on complexity, temporal constraints, goal count
3. **Strategy Validation** - Ensure selected strategy can handle problem characteristics
4. **Fallback Chain** - Automatic fallback to alternative strategies

### Performance Monitoring

- **Execution Time Tracking** - Per-strategy and overall execution metrics
- **Success/Failure Rates** - Strategy reliability statistics
- **Fallback Frequency** - Monitoring of fallback trigger patterns
- **Resource Usage** - Memory and CPU utilization tracking

## Benefits

### Unified Interface
- Single entry point for all planning operations
- Consistent request/response formats across strategies
- Simplified integration for client code

### Improved Reliability
- Automatic fallback handling reduces single points of failure
- Timeout protection prevents hanging operations
- Comprehensive error handling and recovery

### Better Performance
- Asynchronous execution enables concurrent operations
- Strategy selection optimization based on problem characteristics
- Performance monitoring enables continuous improvement

### Enhanced Maintainability
- Clear separation of concerns between strategies
- Standardized interfaces reduce coupling
- Extensible architecture for adding new strategies

## Consequences

### Positive
- **Unified Planning Interface** - Single, consistent API for all planning operations
- **Improved Reliability** - Fallback handling and timeout protection
- **Better Performance Monitoring** - Comprehensive metrics and statistics
- **Extensible Architecture** - Easy to add new strategies and features
- **ADR-134 Compliance** - Follows unified action specification standards

### Negative
- **Increased Complexity** - More components to understand and maintain
- **Migration Effort** - Existing code needs updates to use new interface
- **Memory Overhead** - Additional processes and message passing

### Risks
- **Performance Impact** - Message passing overhead vs direct function calls
- **Debugging Complexity** - Distributed execution makes debugging more challenging
- **Compatibility Issues** - Existing strategies may need adaptation

## Monitoring and Success Criteria

### Performance Metrics
- **Strategy Selection Accuracy** - Percentage of optimal strategy selections
- **Execution Time Improvement** - Comparison with direct strategy calls
- **Fallback Success Rate** - Percentage of successful fallback operations
- **Overall System Reliability** - Reduction in planning failures

### Success Criteria
- All existing planning functionality works through membrane system
- Performance within 10% of direct strategy calls
- Fallback success rate > 90%
- Zero data loss during strategy transitions

## Related ADRs

- **ADR-134**: Unified Durative Action Specification and Planner Standardization
- **ADR-113**: Membrane Planning Pipeline Integration (predecessor)
- **ADR-112**: Hybrid Coordinator V3 Implementation (related)

## Implementation Status

**Current Phase:** Phase 2 - Additional Strategy Filters  
**Completion:** 80% (8/10 core components implemented)  
**Next Steps:** Complete remaining filters and response processing components

### Completed Components
- PlanningRequest format with unified goal validation
- PlanningResponse format with comprehensive result structure  
- StrategyRequest format for internal routing
- PlannerBin with strategy orchestration and monitoring
- StrategyRouterFilter with intelligent problem analysis
- HybridCoordinatorFilter wrapping existing HybridCoordinatorV2
- MockStrategyFilter for testing and development
- RequestValidatorFilter for comprehensive input validation

### Remaining Work
- Additional strategy filters (MiniZinc, LazyExecution)
- Request conversion filter for format transformation
- Response aggregation and formatting filters
- Integration testing and performance optimization

This implementation provides a solid foundation for unified planning operations while maintaining compatibility with existing strategies and enabling future extensibility.
