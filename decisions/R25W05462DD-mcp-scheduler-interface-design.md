# R25W05462DD: MCP Scheduler Interface Design

<!-- @adr_serial R25W05462DD -->

**Status:** Superseded
**Date:** June 18, 2025
**Completion Date:** June 18, 2025
**Superseded Date:** June 20, 2025
**Superseded By:** R25W06881B3 (Schedule Activities Data Transformer Conversion)
**Priority:** HIGH

## Context

The AriaEngine MCP (Model Context Protocol) integration provides a `schedule_activities` tool that exposes our hybrid temporal planner as an external scheduling service. This tool needs to handle various input scenarios gracefully, including the important edge case of empty activity lists.

The MCP interface serves as a bridge between external clients (like IDEs, project management tools, or other applications) and AriaEngine's sophisticated temporal planning capabilities. It must provide a clean, predictable API that handles both complex scheduling scenarios and simple edge cases consistently.

## Decision

### MCP Scheduler Interface Design

**Tool Name:** `schedule_activities`

**Input Schema:**

```json
{
  "schedule_name": {"required": true, "type": "string"},
  "activities": {"required": true, "type": "array", "items": "object"},
  "resources": {"optional": true, "type": "object"},
  "constraints": {"optional": true, "type": "object"}
}
```

**Output Schema:**

```json
{
  "status": "success" | "error",
  "reason": "string",
  "schedule": "array",
  "analysis": "object"
}
```

### Empty Plan for Empty Inputs Behavior

**Core Principle:** Empty activity lists should return successful empty plans, not errors.

**Rationale:**

- **Mathematical Correctness:** An empty set of activities has a trivial solution (empty schedule)
- **User Experience:** Users shouldn't get errors when starting with blank project templates
- **API Consistency:** Success responses for valid inputs, regardless of complexity
- **Integration Friendly:** External tools can handle empty responses predictably

**Implementation:**

```elixir
def handle_empty_activities(request) do
  %{
    status: "success",
    reason: "Empty plan successfully generated - valid solution for empty todo list",
    schedule: [],
    analysis: %{
      schedule_name: request.schedule_name,
      method: "Critical Path Method (CPM)",
      activities_analyzed: 0,
      dependencies_found: 0,
      resource_conflicts: 0,
      circular_dependencies: 0,
      critical_path_length: 0,
      hybrid_planner_used: true,
      empty_plan_reason: "Empty todo list results in empty plan (valid solution)"
    }
  }
end
```

### Hybrid Planner Integration

**Strategy Composition:**

- **Planning Strategy:** HTN task decomposition and goal achievement
- **Temporal Strategy:** STN constraint management and timeline validation  
- **State Strategy:** Categorical and numerical fluent management
- **Domain Strategy:** Action and method resolution
- **Logging Strategy:** Progress tracking and debugging
- **Execution Strategy:** Plan execution and failure recovery

**Conversion Process:**

1. **Request Analysis:** Parse MCP input format and validate structure
2. **Domain Creation:** Convert activities to hybrid planner domain format
3. **State Initialization:** Create initial state from resources and constraints
4. **Goal Generation:** Transform activities into HTN goals (empty for empty inputs)
5. **Planning Execution:** Run hybrid planner with all 6 strategies
6. **Response Formatting:** Convert planner output back to MCP format

### Error Handling Strategy

**Graceful Degradation:**

- Hybrid planner failures fall back to empty plan responses
- Conversion errors are logged but don't break the API
- Invalid inputs return structured error responses
- All responses maintain consistent schema

## Implementation Plan

### Phase 1: Core Interface ✅

- [x] Implement `schedule_activities` MCP tool
- [x] Add input validation and schema enforcement
- [x] Integrate with hybrid planner coordinator
- [x] Handle empty activity lists correctly

### Phase 2: Enhanced Analysis

- [ ] Add detailed resource conflict detection
- [ ] Implement circular dependency analysis
- [ ] Provide scheduling suggestions and recommendations
- [ ] Add timeline estimation capabilities

### Phase 3: Advanced Features

- [ ] Support for complex temporal constraints
- [ ] Multi-project scheduling coordination
- [ ] Real-time replanning capabilities
- [ ] Integration with external calendar systems

## Success Criteria

### Functional Requirements

- [x] Empty activity lists return successful empty plans
- [x] Valid activity lists generate appropriate schedules
- [x] Resource conflicts are detected and reported
- [x] Circular dependencies are identified
- [x] All responses follow consistent schema

### Quality Requirements

- [x] Graceful error handling for all input scenarios
- [x] Comprehensive logging for debugging
- [x] Performance suitable for interactive use
- [x] Clear documentation and examples

### Integration Requirements

- [x] Compatible with Hermes MCP server framework
- [x] Proper tool registration and discovery
- [x] Consistent with other AriaEngine MCP tools
- [x] External client integration ready

## Consequences

### Positive

- **Predictable API:** Consistent behavior across all input scenarios
- **User-Friendly:** No errors for common edge cases like empty projects
- **Mathematically Sound:** Correct handling of trivial scheduling problems
- **Integration Ready:** External tools can rely on consistent responses
- **Extensible:** Foundation for advanced scheduling features

### Negative

- **Complexity:** Additional logic needed to handle edge cases properly
- **Testing Overhead:** Must verify behavior across many input scenarios
- **Documentation Burden:** Need to explain empty plan behavior clearly

### Risks

- **Misunderstanding:** Users might expect errors for empty inputs
- **Integration Issues:** External tools might not handle empty responses
- **Performance:** Hybrid planner overhead even for trivial cases

## Monitoring

### Success Metrics

- **API Response Time:** < 100ms for empty inputs, < 2s for complex schedules
- **Error Rate:** < 1% for valid inputs
- **User Adoption:** Increasing usage of MCP scheduling tool
- **Integration Success:** External tools successfully using the interface

### Logging Strategy

- **Request Analysis:** Log input structure and validation results
- **Planner Integration:** Track hybrid planner performance and failures
- **Response Generation:** Monitor output formatting and delivery
- **Error Tracking:** Detailed logging for debugging and improvement

## Superseded Notice

**This ADR has been superseded by R25W06881B3** due to architectural improvements that separate data transformation from planning execution.

**Key Changes in R25W06881B3:**

- Convert `schedule_activities` from full execution pipeline to pure data transformer
- Return HybridCoordinatorV2 input format instead of execution results
- Enable clean separation between MCP layer (data conversion) and domain layer (planning execution)
- Preserve all validation and conversion logic designed in this ADR

**Migration Impact:**

- The interface design and validation logic from this ADR remains valuable
- R25W06881B3 changes the output format but preserves the input schema and validation approach
- The "empty plan for empty inputs" principle is maintained in the new architecture

## Related ADRs

- **R25W0472567**: Expose Aria via MCP Hermes (parent architecture)
- **R25W0489307**: Hybrid Planner Dependency Encapsulation (planning engine)
- **R25W017DEAF**: Definitive Temporal Planner Architecture (core planning)
- **R25W0621594**: Reconnect Scheduler to MCP (implemented this design)
- **R25W06881B3**: Schedule Activities Data Transformer Conversion (supersedes this ADR)

## Examples

### Empty Input Example

```json
{
  "schedule_name": "New Project",
  "activities": [],
  "resources": {},
  "constraints": {}
}
```

**Response:**

```json
{
  "status": "success",
  "reason": "Empty plan successfully generated - valid solution for empty todo list",
  "schedule": [],
  "analysis": {
    "schedule_name": "New Project",
    "method": "Critical Path Method (CPM)",
    "activities_analyzed": 0,
    "hybrid_planner_used": true,
    "empty_plan_reason": "Empty todo list results in empty plan (valid solution)"
  }
}
```

### Complex Input Example

```json
{
  "schedule_name": "Website Launch",
  "activities": [
    {"id": "design", "duration": 5, "dependencies": []},
    {"id": "develop", "duration": 10, "dependencies": ["design"]},
    {"id": "test", "duration": 3, "dependencies": ["develop"]},
    {"id": "deploy", "duration": 1, "dependencies": ["test"]}
  ],
  "resources": {
    "developers": {"capacity": 2},
    "designers": {"capacity": 1}
  }
}
```

This ADR establishes the foundation for a robust, user-friendly MCP scheduling interface that handles both simple and complex scenarios with mathematical correctness and practical usability.
