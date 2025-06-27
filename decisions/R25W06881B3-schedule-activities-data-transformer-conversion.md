# R25W06881B3: Extract Plan Transformer from schedule_activities

<!-- @adr_serial R25W06881B3 -->

**Status:** Active (Paused)  
**Date:** June 20, 2025  
**Priority:** HIGH  

## Context

### Current Architecture Problem

MCP tool `schedule_activities` mixes data conversion with planning execution.

```
Current: MCP Tool → validate → convert → AriaEngine.Scheduler → HybridCoordinatorV2
```

**Problems:**

- Mixed concerns: conversion coupled with execution
- Testing difficulty: cannot test conversion separately
- Architectural violation: MCP layer executes instead of converting

### Plan Transformer Solution

Extract conversion logic, use HybridCoordinatorV2 directly.

```
Proposed: MCP Tool → Plan Transformer → HybridCoordinatorV2 → [Strategies] → Result
```

**Benefits:**

- Pure data transformation: MCP tools only format data
- Clean testing: test conversion separately from execution
- Better separation: MCP converts, domain executes
- Simpler implementation: use proven V2 coordinator

## Decision

Extract plan transformer from `schedule_activities`, integrate directly with HybridCoordinatorV2.

### Implementation Strategy

**Phase 1: Plan Transformer Module**

- Extract validation/conversion logic from `AriaEngine.MCPTools`
- Create `lib/aria_engine/hybrid_planner/plan_transformer.ex`
- Convert MCP input → (domain, state, goals) format
- Preserve all existing validation logic

**Phase 2: MCP Integration**

- Update `schedule_activities` to use plan transformer
- Call HybridCoordinatorV2 directly with converted parameters
- Return MCP-formatted results
- Maintain existing error handling

### Plan Transformer Interface

**Module**: `AriaEngine.HybridPlanner.PlanTransformer`

```elixir
@type mcp_input :: map()
@type planning_params :: {Domain.Core.t(), AriaEngine.StateV2.t(), [term()]}
@type conversion_result :: {:ok, planning_params()} | {:error, String.t()}

@spec convert_to_planning_params(mcp_input()) :: conversion_result()
def convert_to_planning_params(params) do
  case validate_mcp_params(params) do
    {:ok, validated_params} ->
      domain = build_domain_from_activities(validated_params["activities"])
      state = build_initial_state(validated_params)
      goals = extract_goals(validated_params)
      {:ok, {domain, state, goals}}
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Updated MCP Flow

```elixir
def handle_schedule_activities_tool_call(params) do
  case PlanTransformer.convert_to_planning_params(params) do
    {:ok, {domain, state, goals}} ->
      coordinator = HybridCoordinatorV2.new_default()
      case HybridCoordinatorV2.plan(coordinator, domain, state, goals) do
        {:ok, plan} -> format_mcp_response(plan)
        {:error, reason} -> format_mcp_error(reason)
      end
    {:error, reason} -> format_mcp_error(reason)
  end
end
```

## Implementation Plan

### Phase 1: Plan Transformer Module

- [ ] Create `lib/aria_engine/hybrid_planner/plan_transformer.ex`
- [ ] Extract validation logic from `AriaEngine.MCPTools.handle_schedule_activities_tool_call/1`
- [ ] Extract conversion functions: `convert_activities/1`, `convert_entities/1`
- [ ] Add comprehensive type specifications and documentation
- [ ] Create unit tests for plan transformer module

### Phase 2: MCP Tools Integration

- [ ] Update `AriaEngine.MCPTools.handle_schedule_activities_tool_call/1`
- [ ] Replace scheduler execution with plan transformer call
- [ ] Call HybridCoordinatorV2 directly with converted parameters
- [ ] Update error handling for conversion failures
- [ ] Add integration tests for plan transformer → V2 flow

### Phase 3: Testing and Documentation

- [ ] Verify plan transformer output works with HybridCoordinatorV2
- [ ] Update existing tests to expect new flow
- [ ] Add performance benchmarks for conversion operations
- [ ] Update MCP tool documentation

## Success Criteria

### Functional Requirements

- [ ] Plan transformer converts MCP input to (domain, state, goals) format
- [ ] All existing validation and conversion logic preserved
- [ ] Plan transformer handles all current input scenarios
- [ ] Converted data works with HybridCoordinatorV2
- [ ] Error handling maintains same quality as current implementation

### Quality Requirements

- [ ] Plan transformer is pure function with no side effects
- [ ] Conversion performance equivalent to current implementation
- [ ] All edge cases handled correctly
- [ ] Comprehensive test coverage for conversion logic
- [ ] Clear separation between data transformation and execution

### Integration Requirements

- [ ] MCP tools use plan transformer → V2 flow
- [ ] Strategy testing can use V2 directly
- [ ] No breaking changes to core scheduler functionality
- [ ] Performance equivalent to current implementation

## Consequences

### Positive

- **Clean Architecture**: Clear separation between data transformation and execution
- **Better Testability**: Can test conversion logic independently
- **Simpler Implementation**: Use proven V2 coordinator directly
- **Maintainability**: Focused components with single responsibilities

### Negative

- **Migration Effort**: Existing integrations require updates
- **Additional Module**: Need to manage conversion module separately

### Risks

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

- **R25W069348D**: Plan Transformer with HybridCoordinatorV2 Direct Integration (defines implementation approach)
- **R25W0670D79**: MCP Strategy Testing Interface (uses V2 directly)
- **R25W0667494**: Integrate Exhort OR-Tools Strategy (~~provides OptimizerStrategy for V2~~ - Proposed, not implemented)
- **R25W0621594**: Reconnect Scheduler to MCP (current implementation to be updated)
- **R25W05462DD**: MCP Scheduler Interface Design (tool interface to be updated)

## Examples

### Current Flow

```elixir
# Current mixed approach
def handle_schedule_activities_tool_call(params) do
  # Validation and conversion mixed with execution
  case AriaEngine.Scheduler.schedule_activities(name, activities, opts) do
    {:ok, result} -> format_response(result)
    {:error, reason} -> format_error(reason)
  end
end
```

### New Flow

```elixir
# Plan transformer approach
def handle_schedule_activities_tool_call(params) do
  case PlanTransformer.convert_to_planning_params(params) do
    {:ok, {domain, state, goals}} ->
      coordinator = HybridCoordinatorV2.new_default()
      case HybridCoordinatorV2.plan(coordinator, domain, state, goals) do
        {:ok, plan} -> format_mcp_response(plan)
        {:error, reason} -> format_mcp_error(reason)
      end
    {:error, reason} -> format_mcp_error(reason)
  end
end
```

This ADR establishes plan transformer for clean architectural separation between data transformation and planning execution, using HybridCoordinatorV2 directly.
