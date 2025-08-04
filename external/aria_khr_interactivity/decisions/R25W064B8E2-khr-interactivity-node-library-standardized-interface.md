# KHR_interactivity Node Library - Standardized Interface Implementation

<!-- @adr_serial R25W064B8E2 -->

**Status:** Proposed

## Context

The glTF KHR_interactivity specification requires a standardized, composable interface for node actions within the Aria Engine. The goal is to achieve perfect glTF compatibility while enabling higher-level interactive behaviors and comprehensive testing. The current implementation covers math constants and arithmetic, with further categories planned.

## Decision

Adopt a two-layer architecture for the node library:

- **Layer 1: KHR Primitives (Explicit Node Addressing)**
  - Direct glTF node control using explicit node indexing.
  - Pattern: `action(state, [node_index, ...inputs])`
  - Ensures strict glTF spec compliance.
  - Used for direct node graph execution, debugging, and testing.

- **Layer 2: Task Abstraction (Flow Control)**
  - Abstracts node ID management behind a task interface.
  - Pattern: `task: calculate_sequence([{:add, [5, 3]}, {:multiply, [:result, 2]}])`
  - Supports HTN planning and composition of KHR primitives.
  - Used for interactive behavior planning and complex workflows.

All KHR primitives must follow a standardized interface contract:

```elixir
def khr_action_name(state, [node_index | inputs]) do
  state
  |> StateV2.set_fact(Integer.to_string(node_index), "value", computed_result)
end
```

## Implementation Plan

- [x] Implement math constants and arithmetic primitives with standardized interface.
- [ ] Implement advanced math (trigonometry, vector, matrix, quaternion operations).
- [ ] Implement control flow and event nodes.
- [ ] Implement temporal operations.
- [ ] Implement state management, type conversion, and debug nodes.
- [ ] Ensure every node:
  - Uses standardized interface `[node_index, ...inputs]`
  - Has unit and integration tests
  - Is compatible with StateV2
  - Is registered via `register_all_actions/1`
  - Includes metadata: domain, category, khr_node_type, description

## Consequences/Risks

- Ensures exact glTF node addressing and compatibility.
- Provides composable primitives for higher-level behaviors.
- Requires ongoing maintenance to keep all categories up to date.
- Complexity may increase as more categories are implemented.

## Success Criteria

- All KHR primitives use the standardized interface.
- Unit and integration tests exist for each node.
- StateV2 compatibility is maintained.
- Domain registration and metadata are complete for all nodes.
- Math constants and arithmetic are fully implemented; advanced categories are in progress.

## Change Log

### June 19, 2025

- Initial ADR created from node library README to formalize architecture and implementation plan.
