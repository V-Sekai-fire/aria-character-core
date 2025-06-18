# ADR-090: Expose Aria Temporal Planner via MCP with KHR_interactivity

## Status

**Proposed** (June 17, 2025)

## Context

Aria's `AriaEngine.Planner` provides sophisticated Hierarchical Task Network (HTN) planning with Simple Temporal Network (STN) constraint solving. This temporal planner combines IPyHOP-style HTN planning with STN bridge actions for handling temporal constraints and non-temporal decisions.

The Model Context Protocol (MCP) provides a standardized way to expose planning capabilities to Large Language Models and AI assistants. [Hermes MCP](https://github.com/cloudwalk/hermes-mcp) is a high-performance Elixir MCP implementation that provides native integration with Elixir systems.

The glTF KHR_interactivity extension provides a standardized behavior graph specification for interactive 3D content. This includes math operations, control flow, state management, and event handling - providing a complete visual scripting environment with 400+ operations that can execute in any glTF-compliant runtime.

Currently, Aria's advanced temporal planning capabilities are only accessible through internal APIs. Exposing the planner through MCP using KHR_interactivity behavior graphs would enable universal AI assistant access while generating portable visual scripts that can execute anywhere.

## Decision

Implement a minimal MCP server using Hermes that exposes `AriaEngine.Planner` through 4 focused MCP tools using KHR_interactivity behavior graphs as the universal interface, providing language-independent access to Aria's temporal planning capabilities while generating portable visual scripts.

## KHR_interactivity Behavior Graph Architecture

The MCP server operates using KHR_interactivity behavior graphs as the universal interface:

### Input Domain: Planning Requests

AI assistants provide planning problems in any format, which are translated to Aria's internal representation:

- **Planning domains** with actions, methods, and temporal constraints
- **Initial state** with world facts and conditions
- **Goals** to achieve with optional temporal constraints
- **Planning options** and temporal context

### Output Plans: Portable Visual Scripts

Plans are generated as KHR_interactivity behavior graphs that function as portable visual scripts:

```json
{
  "behaviors": [
    {
      "type": "math/add",
      "inputs": { "a": "current_time", "b": "duration" },
      "outputs": { "result": "deadline" }
    },
    {
      "type": "flow/sequence",
      "inputs": { "actions": ["action1", "action2", "action3"] },
      "outputs": { "completion": "plan_finished" }
    },
    {
      "type": "variable/set",
      "inputs": { "name": "robot_position", "value": "target_location" },
      "outputs": { "success": "position_updated" }
    }
  ]
}
```

### Translation Layer Architecture

```
AI Request → Domain Translation → AriaEngine.Planner → Solution Tree → Behavior Graph
```

The server includes a bidirectional translation layer:

- **Input translation**: Converts planning requests to Aria domain format
- **State mapping**: Maps external state representations to AriaEngine StateV2
- **Output generation**: Translates solution trees to KHR_interactivity behavior graphs
- **Execution mapping**: Ensures behavior graphs can execute temporal plans correctly

## Implementation Plan

### Phase 1: MCP Server Foundation (1 day)

- [ ] Add `hermes_mcp` dependency to Aria umbrella project
- [ ] Create `AriaCore.MCPServer` module using `use Hermes.Server`
- [ ] Configure basic server with tools capability (no resources/prompts needed)
- [ ] Add OTP supervision integration with existing Aria supervision tree
- [ ] Implement STDIO transport for CLI-based AI assistant integration

### Phase 2: Behavior Graph Tool Implementation (2-3 days)

- [ ] Create `AriaCore.MCP.PlannerTool` component with 4 focused tools:
  - `plan_temporal_actions` - Generate KHR_interactivity behavior graphs from planning requests
  - `validate_temporal_plan` - Validate behavior graph plans against domain constraints
  - `execute_temporal_plan` - Execute behavior graphs with Run-Lazy-Refineahead
  - `get_plan_actions` - Extract primitive action sequences from behavior graphs
- [ ] Implement KHR_interactivity translation layer:
  - Planning domain to behavior graph conversion
  - State representation mapping between external formats and StateV2
  - Solution tree to behavior graph generation
  - Temporal constraint encoding in behavior graphs
- [ ] Add comprehensive input validation using Hermes schema macros
- [ ] Implement proper error handling and JSON serialization
- [ ] Add basic logging and telemetry

### Phase 3: Testing & Documentation (0.5 days)

- [ ] Create test suite for MCP tool validation
- [ ] Add client integration examples showing basic usage
- [ ] Document the 4 exposed tools with examples
- [ ] Verify integration with common AI assistants
