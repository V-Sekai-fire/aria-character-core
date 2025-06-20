# ADR-111: Convert schedule_activities to Plan Transformer

**Status:** Proposed  
**Date:** June 20, 2025  
**Priority:** HIGH  

## Context

### Current Architecture Problem

The current `schedule_activities` MCP tool mixes data transformation (MCP layer) with planning execution (domain layer), creating architectural issues:

```
Current: MCP Tool → validate → convert → AriaEngine.Scheduler → HybridCoordinatorV2 → [Strategies] → Result
```

**Problems with Current Approach:**
- **Mixed Concerns**: Data conversion and planning execution are coupled
- **Testing Difficulty**: Cannot test data conversion separately from planning logic
- **Reusability Issues**: Formatted data cannot be used in different execution contexts
- **Architectural Violation**: MCP layer should handle format conversion, not execution

### Plan Transformer Architecture Benefits

Converting to a pure data transformer creates clean separation:

```
Proposed: MCP Tool (plan transformer) → HybridCoordinatorV3 input format
          Domain Layer → HybridCoordinatorV3 → [Individual Strategies] → Result
```

**Benefits of Plan Transformer:**
1. **Pure Data Transformation**: MCP tools become pure functions that only format data
2. **Cleaner Testing**: Can test data conversion separately from planning execution
3. **Better Separation**: MCP layer handles format conversion, domain layer handles planning
4. **Reusability**: Formatted data can be used by different execution contexts
5. **Future Interface Discovery**: Focus on one tool until we understand what interface we need

### Related ADR Context

- **ADR-112**: HybridCoordinatorV3 Implementation with V2 Adapter (provides target interface)
- **ADR-110**: MCP Strategy Testing Interface - already incorporates plan transformer architecture
- **ADR-105**: Reconnect Scheduler to MCP - implemented current mixed-concern approach
- **ADR-097**: MCP Scheduler Interface Design - designed current implementation

## Decision

Convert `schedule_activities` from a full execution pipeline to a pure data transformer that outputs HybridCoordinatorV3-compatible input format.

**Note**: This ADR focuses on the plan transformer implementation. The HybridCoordinatorV3 interface and adapter implementation is covered in ADR-112.

### Implementation Strategy

**Phase 1: Create Plan Transformer Module**
- Extract data conversion logic from `AriaEngine.MCPTools`
- Create `AriaEngine.HybridPlanner.PlanTransformer` module
- Implement pure data transformation functions
- Preserve all existing validation and conversion logic

**Phase 2: Update MCP Tools**
- Modify `schedule_activities` to use plan transformer
- Return formatted coordinator input instead of execution results
- Add conversion metadata for debugging and traceability
- Maintain backward compatibility during transition

**Phase 3: Integration with HybridCoordinatorV3**
- Integrate with HybridCoordinatorV3 interface (from ADR-112)
- Verify plan transformer output works with V3 coordinator
- Add integration points for direct domain layer execution

### Plan Transformer Interface

**Module**: `AriaEngine.HybridPlanner.PlanTransformer`

```elixir
@type mcp_input :: map()
@type coordinator_input :: map()
@type conversion_result :: {:ok, coordinator_input()} | {:error, String.t()}

@spec convert_to_coordinator_input(mcp_input()) :: conversion_result()
def convert_to_coordinator_input(params) do
  case validate_mcp_params(params) do
    {:ok, validated_params} ->
      coordinator_input = %{
        schedule_name: validated_params["schedule_name"],
        activities: convert_activities(validated_params["activities"]),
        entities: convert_entities(validated_params["entities"] || []),
        resources: validated_params["resources"] || %{},
        constraints: validated_params["constraints"] || %{},
        options: extract_options(validated_params)
      }
      {:ok, coordinator_input}
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Updated MCP Tool Response

**New Response Format:**
```json
{
  "status": "success",
  "coordinator_input": {
    "schedule_name": "Project Alpha",
    "activities": [...],
    "entities": [...],
    "resources": {...},
    "constraints": {...},
    "options": [...]
  },
  "conversion_metadata": {
    "original_activities": 5,
    "converted_at": "2025-06-20T14:46:00Z",
    "input_format": "mcp_schedule_activities",
    "output_format": "hybrid_coordinator_v3"
  }
}
```

## Implementation Plan

### Phase 1: Plan Transformer Module Creation

- [ ] Create `lib/aria_engine/hybrid_planner/plan_transformer.ex`
- [ ] Extract validation logic from `AriaEngine.MCPTools.handle_schedule_activities_tool_call/1`
- [ ] Extract conversion functions: `convert_activities/1`, `convert_entities/1`, etc.
- [ ] Add comprehensive type specifications and documentation
- [ ] Create unit tests for plan transformer module

### Phase 2: MCP Tools Update

- [ ] Update `AriaEngine.MCPTools.handle_schedule_activities_tool_call/1`
- [ ] Replace scheduler execution with plan transformer call
- [ ] Update tool definition schema to reflect new output format
- [ ] Add conversion metadata to responses
- [ ] Update error handling for conversion failures

### Phase 3: Integration and Testing

- [ ] Verify plan transformer output is compatible with HybridCoordinatorV3 (ADR-112)
- [ ] Add integration tests for plan transformer → coordinator V3 flow
- [ ] Update existing tests to expect new response format
- [ ] Add performance benchmarks for conversion operations

### Phase 4: Documentation and Migration

- [ ] Update MCP tool documentation with new response format
- [ ] Create migration guide for existing MCP clients
- [ ] Add examples showing how to use converted data
- [ ] Document integration with domain layer execution

## Success Criteria

### Functional Requirements

- [ ] `schedule_activities` returns coordinator input format instead of execution results
- [ ] All existing validation and conversion logic is preserved
- [ ] Plan transformer handles all current input scenarios (empty lists, complex schedules)
- [ ] Converted data is compatible with HybridCoordinatorV3 (ADR-112)
- [ ] Error handling maintains same quality as current implementation

### Quality Requirements

- [ ] Plan transformer is a pure function with no side effects
- [ ] Conversion performance is equivalent to current implementation
- [ ] All edge cases (empty activities, invalid inputs) are handled correctly
- [ ] Comprehensive test coverage for conversion logic
- [ ] Clear separation between data transformation and execution

### Integration Requirements

- [ ] Existing MCP clients can adapt to new response format
- [ ] Domain layer can execute plans using converted data through HybridCoordinatorV3
- [ ] Strategy testing interface (ADR-110) can use same conversion logic
- [ ] No breaking changes to core scheduler functionality

## Consequences

### Positive

- **Clean Architecture**: Clear separation between data transformation and execution
- **Better Testability**: Can test conversion logic independently
- **Reusability**: Converted data can be used in multiple contexts
- **Strategy Testing**: Enables individual strategy testing capabilities
- **Maintainability**: Simpler, more focused components

### Negative

- **Breaking Change**: Existing MCP clients need updates for new response format
- **Additional Complexity**: Need to manage conversion module separately
- **Migration Effort**: Existing integrations require updates

### Risks

- **Client Compatibility**: Existing MCP clients might break with new response format
- **Data Loss**: Conversion might lose information during transformation
- **Performance Impact**: Additional conversion step might add latency

## Migration Strategy

### Backward Compatibility Approach

**Option 1: Versioned Tools**
- Add `schedule_activities_v2` tool with new format
- Maintain `schedule_activities` with current behavior
- Deprecate old tool after migration period

**Option 2: Response Format Flag**
- Add `output_format` parameter to control response type
- Default to current format for compatibility
- Allow clients to opt into new format

**Option 3: Direct Migration**
- Update tool immediately with new format
- Provide clear migration documentation
- Support clients during transition

**Recommended**: Option 1 (Versioned Tools) for safest migration

### Client Migration Support

- [ ] Create migration guide with before/after examples
- [ ] Provide helper functions for processing new format
- [ ] Offer consultation for complex integrations
- [ ] Monitor client adoption and provide support

## Monitoring

### Success Metrics

- **Conversion Performance**: < 10ms for typical inputs
- **Error Rate**: < 0.1% for valid inputs
- **Client Adoption**: > 80% migration to new format within 30 days
- **Test Coverage**: > 95% for plan transformer module

### Logging Strategy

- **Conversion Tracking**: Log input/output sizes and conversion time
- **Error Analysis**: Detailed logging for conversion failures
- **Usage Patterns**: Monitor which input formats are most common
- **Performance Monitoring**: Track conversion performance over time

## Related ADRs

### Primary Dependencies

- **ADR-112**: HybridCoordinatorV3 Implementation with V2 Adapter (provides target interface)

### ADRs to Update

- **ADR-105**: Reconnect Scheduler to MCP → Update to reflect plan transformer approach
- **ADR-097**: MCP Scheduler Interface Design → Update tool interface specification
- **ADR-110**: MCP Strategy Testing Interface → Align with plan transformer architecture

### ADRs to Deprecate/Pause

- **ADR-090**: Expose Aria via MCP Hermes → Pause (superseded by current MCP implementation)

### Related ADRs

- **ADR-091**: Hybrid Planner Dependency Encapsulation (planning engine)
- **ADR-034**: Definitive Temporal Planner Architecture (core planning)

## Examples

### Current Response Format

```json
{
  "status": "success",
  "reason": "Schedule generated successfully",
  "schedule": [
    {"activity": "task1", "start": "2025-06-20T10:00:00Z", "end": "2025-06-20T12:00:00Z"}
  ],
  "analysis": {
    "method": "Critical Path Method (CPM)",
    "activities_analyzed": 1
  }
}
```

### New Response Format

```json
{
  "status": "success",
  "coordinator_input": {
    "schedule_name": "Project Alpha",
    "activities": [
      {"id": "task1", "duration": "PT2H", "dependencies": []}
    ],
    "entities": [],
    "resources": {},
    "constraints": {},
    "options": []
  },
  "conversion_metadata": {
    "original_activities": 1,
    "converted_at": "2025-06-20T14:46:00Z",
    "input_format": "mcp_schedule_activities",
    "output_format": "hybrid_coordinator_v3"
  }
}
```

This ADR establishes the plan transformer component for clean architectural separation between data transformation and planning execution. The HybridCoordinatorV3 interface that consumes this output is defined in ADR-112.
