# ADR-112: HybridCoordinatorV3 Implementation with V2 Adapter

**Status:** Proposed  
**Date:** June 20, 2025  
**Priority:** HIGH  

## Context

### Current Architecture

HybridCoordinatorV2 exists and works with current strategies, but we need a new interface (V3) that can accept plan transformer output from MCP tools while maintaining compatibility with existing V2 strategies.

```
Current: HybridCoordinatorV2 → [V2 Strategies] → Result
Proposed: HybridCoordinatorV3 → V2 Adapter → HybridCoordinatorV2 → [V2 Strategies] → Result
```

### Need for V3

- **Plan Transformer Compatibility**: V3 needs to accept formatted input from plan transformers
- **Strategy Compatibility**: Existing V2 strategies should continue working through adapters
- **Clean Interface**: V3 provides a cleaner interface for future development
- **Testing Support**: V3 enables individual strategy testing capabilities

## Decision

Create HybridCoordinatorV3 that adapts to HybridCoordinatorV2, maintaining full backward compatibility with existing strategies while providing a new interface for plan transformer output.

### Implementation Strategy

**Phase 1: Test HybridCoordinatorV2**
- Verify current V2 implementation works correctly
- Document V2 interface and behavior
- Identify all existing V2 strategies
- Create comprehensive test suite for V2 functionality

**Phase 2: Create HybridCoordinatorV3**
- Design V3 interface based on plan transformer output format
- Create `AriaEngine.HybridPlanner.HybridCoordinatorV3` module
- Implement V3 → V2 adapter pattern
- Ensure all V2 strategies work through adapter

**Phase 3: Strategy Adapter Interface**
- Create `AriaEngine.HybridPlanner.StrategyAdapter` behavior
- Implement adapters for existing V2 strategies:
  - Critical Path Method (CPM) adapter
  - PERT adapter
  - Resource leveling adapter
  - SAT-CP strategy adapter (mock implementation)
- Add comprehensive tests for adapter pattern

## Implementation Plan

### Phase 1: V2 Verification and Documentation

- [ ] Test HybridCoordinatorV2 functionality thoroughly
- [ ] Document V2 interface specifications
- [ ] Identify all existing V2 strategies and their interfaces
- [ ] Create test suite covering V2 behavior
- [ ] Document V2 input/output formats

### Phase 2: HybridCoordinatorV3 Creation

- [ ] Create `lib/aria_engine/hybrid_planner/hybrid_coordinator_v3.ex`
- [ ] Design V3 interface for plan transformer input
- [ ] Implement V3 → V2 adapter functionality
- [ ] Add comprehensive type specifications
- [ ] Create unit tests for V3 coordinator

### Phase 3: Strategy Adapter Implementation

- [ ] Create `lib/aria_engine/hybrid_planner/strategy_adapter.ex` behavior
- [ ] Implement V2 strategy adapters:
  - [ ] CPM strategy adapter
  - [ ] PERT strategy adapter
  - [ ] Resource leveling adapter
  - [ ] Other existing strategy adapters
- [ ] Add integration tests for adapter pattern
- [ ] Verify all V2 strategies work through adapters

### Phase 4: Integration and Testing

- [ ] Test V3 with plan transformer output
- [ ] Verify strategy execution through adapter chain
- [ ] Add performance benchmarks for adapter overhead
- [ ] Create comprehensive integration test suite

## HybridCoordinatorV3 Interface

### Input Format (from Plan Transformer)

```elixir
@type coordinator_input :: %{
  schedule_name: String.t(),
  activities: [activity()],
  entities: [entity()],
  resources: map(),
  constraints: map(),
  options: [option()]
}

@type activity :: %{
  id: String.t(),
  duration: String.t(),
  dependencies: [String.t()],
  # Additional activity fields
}
```

### V3 → V2 Adapter Pattern

```elixir
defmodule AriaEngine.HybridPlanner.HybridCoordinatorV3 do
  @spec execute(coordinator_input(), strategy_name()) :: result()
  def execute(coordinator_input, strategy_name) do
    # Convert V3 input to V2 format
    v2_input = convert_v3_to_v2(coordinator_input)
    
    # Execute through V2 coordinator
    AriaEngine.HybridPlanner.HybridCoordinatorV2.execute(v2_input, strategy_name)
  end
  
  defp convert_v3_to_v2(v3_input) do
    # Conversion logic from V3 format to V2 format
  end
end
```

## Strategy Adapter Interface

### Adapter Behavior

```elixir
defmodule AriaEngine.HybridPlanner.StrategyAdapter do
  @callback adapt_input(v3_input :: map()) :: v2_input :: map()
  @callback adapt_output(v2_output :: map()) :: v3_output :: map()
  @callback strategy_name() :: String.t()
end
```


## Success Criteria

### Functional Requirements

- [ ] HybridCoordinatorV3 accepts plan transformer input format
- [ ] V3 → V2 adapter maintains full compatibility with existing strategies
- [ ] All existing V2 strategies work through adapter pattern
- [ ] SAT-CP mock strategy provides OptimizerStrategy interface
- [ ] No breaking changes to existing V2 functionality

### Quality Requirements

- [ ] Adapter overhead is minimal (< 5ms additional latency)
- [ ] Comprehensive test coverage for V3 and adapter pattern
- [ ] Clear separation between V3 interface and V2 implementation
- [ ] Strategy adapter pattern is extensible for future strategies

### Integration Requirements

- [ ] V3 integrates seamlessly with plan transformer output
- [ ] Existing V2 strategies require no modifications
- [ ] Strategy testing interface can use V3 directly
- [ ] Performance is equivalent to direct V2 usage

## Consequences

### Positive

- **Backward Compatibility**: All existing V2 strategies continue working
- **Clean Interface**: V3 provides better interface for plan transformers
- **Strategy Testing**: Enables individual strategy testing capabilities
- **Future Flexibility**: V3 can evolve independently while maintaining V2 compatibility

### Negative

- **Additional Complexity**: Adapter layer adds complexity
- **Performance Overhead**: Minimal adapter overhead for V3 → V2 conversion
- **Maintenance Burden**: Need to maintain both V3 and V2 interfaces

### Risks

- **Adapter Bugs**: Conversion errors between V3 and V2 formats
- **Performance Impact**: Adapter overhead might affect performance
- **Interface Drift**: V3 and V2 interfaces might diverge over time

## Related ADRs

- **ADR-111**: Convert schedule_activities to Plan Transformer (depends on this ADR)
- **ADR-110**: MCP Strategy Testing Interface (uses V3 interface)
- **ADR-109**: Integrate Exhort OR-Tools Strategy (provides OptimizerStrategy interface)

## Examples

### V3 Input Format

```json
{
  "schedule_name": "Project Alpha",
  "activities": [
    {"id": "task1", "duration": "PT2H", "dependencies": []},
    {"id": "task2", "duration": "PT1H", "dependencies": ["task1"]}
  ],
  "entities": [],
  "resources": {},
  "constraints": {},
  "options": []
}
```

### V3 → V2 Conversion

```elixir
# V3 input gets converted to V2 format
v2_input = %{
  activities: [
    %{name: "task1", duration: 7200, predecessors: []},
    %{name: "task2", duration: 3600, predecessors: ["task1"]}
  ],
  # V2 specific format fields
}
```

This ADR establishes HybridCoordinatorV3 as an adapter layer that maintains full backward compatibility while providing a clean interface for plan transformer integration.
