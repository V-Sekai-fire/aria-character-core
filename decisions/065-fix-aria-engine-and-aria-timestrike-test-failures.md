# ADR-065: Fix `aria_engine` and `aria_timestrike` Test Failures

## Status

**Active** (Started: June 15, 2025)
**Priority**: High

## Context

After implementing the core API for `aria_flow` in ADR-064, the test suite reveals failures in two downstream applications: `aria_engine` and `aria_timestrike`. These failures prevent the completion of the `aria_flow` port and indicate unresolved integration issues.

### Failing Tests

- **`aria_engine`**: 6 failures in `AriaEngine.FlowBackflowTest` related to backpressure and demand signaling.
- **`aria_timestrike`**: 4 failures in `AriaTimestrike.BaselineTest` related to missing `AriaEngine.Temporal` functions and planner integration.

The presence of `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` suggests that the port from this backup file is incomplete.

## Decision

**Updated Approach (June 15, 2025)**: Instead of fixing integration issues directly, implement **Elixir behaviours as interfaces** to decouple `aria_engine`, `aria_queue`, and `aria_flow` components. This enables independent development and testing while avoiding tight coupling.

**Original Decision**: Address the test failures in `aria_engine` and `aria_timestrike` by completing the porting of logic from the `backflow_backup` file and ensuring the `aria_flow` API is correctly integrated with its consumers.

**Clarification**: We will not be using a `GenServer` in `aria_flow`. The `Flow` library already provides the necessary process management and concurrency, making a `GenServer` redundant. This approach simplifies the design and avoids unnecessary complexity.

## Implementation Plan

### Phase 1: Behaviour-Based Architecture (In Progress)

- [x] Create `AriaFlow.Behaviour` interface defining flow processing contract
- [x] Implement `AriaEngine.MockFlow` as testing implementation
- [x] Add `AriaEngine.FlowConfig` for implementation selection
- [x] Update test helpers to use behaviour-based interface
- [x] Add missing `process_with_backflow/3` callback to behaviour
- [x] Update `AriaEngine.FlowWorkflow` to use configurable implementation
- [ ] Complete `AriaFlow` main module to implement the behaviour
- [ ] Fix test return format expectations in mock implementation
- [ ] Address `AriaTimestrike.DomainProvider` missing functions

### Phase 2: Test Integration (Pending)

- [ ] Analyze the failing tests in `aria_engine` and `aria_timestrike` to identify the root causes.
- [ ] Fix the 5 failing tests in `aria_engine`:
  - [ ] Fix `AriaTimestrike.DomainProvider` missing functions (2 failures)
  - [ ] Fix Flow backflow processing return format issues (3 failures)
- [ ] Fix the failing tests in `aria_timestrike`.
- [ ] Run the full test suite to ensure all tests pass.

### Phase 3: Cleanup (Pending)

- [ ] Remove the `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` file.
- [ ] Update ADR-064 to reflect the completed implementation.

## Success Criteria

- **Architectural Decoupling**: `aria_engine` uses behaviour-based interface instead of direct `AriaFlow` calls
- **Independent Testing**: Mock implementation allows `aria_engine` testing without full `AriaFlow`
- **Configuration Flexibility**: Can switch between real and mock implementations via configuration
- All tests in the `aria_engine` and `aria_timestrike` applications pass.
- The `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` file is removed.
- ADR-064 is updated to reflect the completion of the `aria_flow` implementation.
- The entire project compiles without warnings and all tests pass.

## Current Status (June 15, 2025)

### ✅ Completed

- **Behaviour Definition**: `AriaFlow.Behaviour` exists with interface definitions
- **Mock Implementation**: `AriaEngine.MockFlow` implements the behaviour for testing
- **Configuration System**: `AriaEngine.FlowConfig` allows switching between implementations
- **Test Helpers**: Flow test helpers use the behaviour-based approach
- **Workflow Integration**: `FlowWorkflow` updated to use configurable implementation

### 🔧 In Progress

- **Missing Callback**: Added `process_with_backflow/3` to behaviour (just completed)
- **AriaFlow Implementation**: Main `AriaFlow` module needs to implement the behaviour
- **Test Format Issues**: Mock return formats need to match test expectations

### ⏳ Pending

- **5 Test Failures**: Need to fix `AriaTimestrike.DomainProvider` and return format issues
- **Final Integration**: Complete decoupling and verify all tests pass

### Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   aria_engine   │    │   aria_flow      │    │   aria_queue    │
│                 │    │                  │    │                 │
│ FlowConfig ──────────► AriaFlow.Behaviour│    │                 │
│ MockFlow        │    │ AriaFlow (impl)  │    │                 │
│ FlowWorkflow    │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Change Log

### June 15, 2025

- **Architectural Pivot**: Shifted from direct integration fixes to behaviour-based decoupling approach
- **Implementation Progress**: Created `AriaFlow.Behaviour`, `AriaEngine.MockFlow`, and configuration system
- **Rationale**: Behaviour-based interfaces provide better decoupling, independent testability, and follow Elixir best practices for interface definition
- **Status**: Major architectural components in place, focusing on completing test integration
