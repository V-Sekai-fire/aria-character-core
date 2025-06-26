# VSEKAI_interactivity_planning Extension Outline

## I. Extension Overview

- **Purpose**: Add temporal planning capabilities to glTF scenes
- **Foundation**: Built on KHR_interactivity extension
- **Integration**: AriaEngine's unified durative action specification
- **Target**: Intelligent agent behavior and multi-agent coordination

## II. Core Planning Concepts

### A. Mental Model Shift (From Imperative to Declarative)

1. **Traditional Programming**: Direct function calls and step-by-step execution
2. **Planning Approach**: Describe capabilities, let planner decide execution
3. **Key Benefits**:
   - Multi-agent coordination
   - Temporal constraint satisfaction
   - Dynamic replanning and failure recovery

### B. Problems Planning Solves

1. **Multi-Agent Coordination**: Resource conflicts, capability matching
2. **Temporal Constraints**: Complex scheduling with dependencies
3. **Dynamic Replanning**: Automatic failure recovery and adaptation

## III. Entity-Capability System (ADR-181)

### A. Core Entity Model

1. **Entity Types**: Agents, tools, locations, consumables
2. **Capabilities**: Simple traits (cooking, heating, workspace)
3. **State Separation**: Capabilities vs dynamic properties

### B. Entity Structure

```json
{
  "type": "agent|appliance|location|consumable",
  "capabilities": ["trait1", "trait2"],
  "state": {
    "dynamic_property": "value"
  }
}
```

### C. Tombstoned Patterns

- ❌ Constraints in action metadata
- ❌ Properties field in entity requirements
- ❌ Rigid relations (redundant with capabilities)

## IV. Unified Action Specification (ADR-181)

### A. Action Structure

1. **Temporal Specification**: Duration or start/end times
2. **Entity Requirements**: Type and capabilities needed
3. **Mutual Exclusion**: Actions that cannot run simultaneously
4. **Temporal Constraints**: Before/after/during relationships

### B. Temporal Patterns (ADR-182)

1. **Floating Duration**: `"duration": "PT2H"`
2. **Fixed Schedule**: `"start": "...", "end": "..."`
3. **Open-ended Intervals**: Start-only or end-only
4. **Instant Actions**: Zero duration, anytime or specific time

### C. Validation Rules

- Duration XOR start/end (mutually exclusive)
- Precision preservation with Timex
- ISO 8601 format compliance

## V. IPyHOP Architecture Integration (ADR-183)

### A. Solution Tree Structure

1. **Node Types**: task, action, goal, multigoal, verify_goal, verify_multigoal
2. **Action Priority**: Actions execute immediately when selected
3. **Interleaved Planning**: No separate planning phase

### B. Blacklist System

1. **Failed Action Prevention**: Automatic blacklisting
2. **Scope Management**: Global, session, or subtree
3. **Intelligent Backtracking**: Avoid repeated failures

### C. Pure GTPyhop Multigoal Philosophy

1. **No Automatic Fallbacks**: Domain must define multigoal methods
2. **Explicit Handling**: split_multigoal and MinizinC as tools only
3. **Planning Failure**: If no domain methods exist

## VI. Commands vs Actions Separation (ADR-183)

### A. Planning-Time Actions

- Assume success for planning purposes
- Pure state transformation
- Entity requirements validation by planner

### B. Execution-Time Commands

- Handle real-world failures
- Trigger blacklisting and replanning
- Separate from planning logic

## VII. Goal Format Standardization (ADR-181)

### A. Required Format

- **ONLY**: `{subject, predicate, value}`
- **Tombstoned**: All other formats

### B. State Validation

- Direct fact checking with `AriaState.RelationalState.get_fact/3`
- No complex evaluation functions

## VIII. KHR_interactivity Integration

### A. CP-SAT Solver Node

1. **Custom Node**: `planning/cpsat`
2. **Inputs**: entities, actions, goals, constraints, timeout
3. **Outputs**: solution, isValid, cost
4. **Web Implementation**: MiniZinc on the web

### B. Standard Node Mapping

1. **Entity State**: pointer/get, pointer/set
2. **Temporal Reasoning**: math operations, flow/setDelay
3. **Goal Processing**: event nodes, flow/branch
4. **Action Execution**: flow/sequence, pointer/set

### C. Behavior Graph Integration

- Planning logic as KHR_interactivity graphs
- State access through pointer nodes
- Event-driven goal achievement

## IX. glTF Schema Integration

### A. Extension Root Structure

```json
{
  "extensions": {
    "VSEKAI_interactivity_planning": {
      "entities": {},
      "actions": {},
      "goals": {},
      "temporal_constraints": {},
      "planning_domain": {},
      "execution_context": {},
      "blacklist": {}
    }
  }
}
```

### B. Node Extensions

- Entity metadata and state
- Available actions
- Current goals

### C. Scene Extensions

- Domain configuration
- Execution strategy
- IPyHOP compatibility settings

## X. Implementation Patterns (ADR-184)

### A. Module-Based Domain Pattern

1. **Action Attributes**: @action with metadata
2. **Command Attributes**: @command for execution
3. **Method Attributes**: @task_method, @unigoal_method, @multigoal_method
4. **Function Enforcement**: Attributes required for planner integration

### B. JavaScript/WebGL Implementation

1. **Browser Compatibility**: Reference implementation
2. **Entity Validation**: Capability matching
3. **State Management**: KHR_interactivity integration
4. **Failure Handling**: Blacklisting and recovery

## XI. JSON Schema Definitions

### A. Entity Schema

- Type and capabilities (required)
- State (optional dynamic properties)
- No constraints in metadata

### B. Action Schema

- Temporal specification (duration XOR start/end)
- Entity requirements (type + capabilities only)
- Mutual exclusion and constraints

### C. Goal Schema

- Subject, predicate, value (required)
- No additional properties

### D. Planning Domain Schema

- Execution strategy
- IPyHOP compatibility flags
- Goal verification settings

## XII. Tombstoned Features (Comprehensive)

### A. Architectural Violations (ADR-181, ADR-183)

1. ❌ Constraints in action metadata
2. ❌ Automatic multigoal fallbacks
3. ❌ Rigid relations
4. ❌ Separate planning/execution phases
5. ❌ Properties field in entity requirements
6. ❌ Validation within action functions
7. ❌ Mixed goal formats
8. ❌ Command nodes in solution tree
9. ❌ Alternative planning APIs

### B. Rationale for Tombstoning

- **Separation of Concerns**: Action metadata vs state validation
- **Pure GTPyhop Philosophy**: Explicit multigoal handling
- **IPyHOP Compatibility**: Interleaved planning only
- **Architectural Integrity**: Prevent design violations

## XIII. Example Usage Scenarios

### A. Restaurant Kitchen Scene

1. **Entities**: Chef, oven, kitchen with capabilities
2. **Actions**: cook_meal, gather_ingredients with requirements
3. **Goals**: Location, status, availability goals
4. **Integration**: KHR_interactivity behavior graphs

### B. Multi-Agent Coordination

1. **Complex Workflow**: Multiple chefs, temporal constraints
2. **Resource Management**: Equipment sharing, conflict resolution
3. **Temporal Dependencies**: Appetizer before main course
4. **Quality Assurance**: Service rating goals

## XIV. Implementation Resources

### A. Known Implementations

1. **AriaEngine (Elixir)**: Reference implementation
2. **V-Sekai Godot Integration**: MCP server interface
3. **JavaScript/WebGL**: Browser compatibility layer

### B. Documentation References

1. **ADR-181**: Core specification
2. **ADR-182**: Technical implementation
3. **ADR-183**: Architecture and standards
4. **ADR-184**: Developer guide and examples

## XV. Future Considerations

### A. Extension Evolution

- Maintain ADR compliance
- Preserve tombstoned pattern prevention
- Enhance KHR_interactivity integration

### B. Implementation Guidance

- Follow module-based domain pattern
- Enforce function attribute requirements
- Maintain pure GTPyhop philosophy
- Preserve IPyHOP compatibility
