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

Address the test failures in `aria_engine` and `aria_timestrike` by completing the porting of logic from the `backflow_backup` file and ensuring the `aria_flow` API is correctly integrated with its consumers.

**Clarification**: We will not be using a `GenServer` in `aria_flow`. The `Flow` library already provides the necessary process management and concurrency, making a `GenServer` redundant. This approach simplifies the design and avoids unnecessary complexity.

## Implementation Plan

- [ ] Analyze the failing tests in `aria_engine` and `aria_timestrike` to identify the root causes.
- [ ] Complete the port of the backflow logic from the `.bak` file to the new `aria_flow` modules.
- [ ] Fix the failing tests in `aria_engine`.
- [ ] Fix the failing tests in `aria_timestrike`.
- [ ] Remove the `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` file.
- [ ] Run the full test suite to ensure all tests pass.
- [ ] Update ADR-064 to reflect the completed implementation.

## Success Criteria

- All tests in the `aria_engine` and `aria_timestrike` applications pass.
- The `apps/aria_flow/lib/aria_flow/backflow_backup_20250615_084737.ex.bak` file is removed.
- ADR-064 is updated to reflect the completion of the `aria_flow` implementation.
- The entire project compiles without warnings and all tests pass.
