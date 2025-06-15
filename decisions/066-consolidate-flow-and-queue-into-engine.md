---
date: 2025-06-15
status: Active
---

# Consolidate aria_flow and aria_queue into aria_engine

## Context

The current architecture includes three separate applications: `aria_engine`, `aria_flow`, and `aria_queue`. This separation has led to unnecessary complexity, increased maintenance overhead, and a fragmented dependency graph. To simplify the system, this ADR proposes consolidating the functionalities of `aria_flow` and `aria_queue` directly into `aria_engine`.

This change aligns with our principles of "Local solutions over core modifications" and "Targeted solutions over generalized systems" by placing the flow and queue logic directly where it is used, within the engine itself.

## Decision

We will merge the core functionalities of `aria_flow` and `aria_queue` into `aria_engine`. This involves:

1. Moving the essential logic from `aria_flow` and `aria_queue` into `aria_engine`.
2. Updating all applications that depend on `aria_flow` and `aria_queue` to point to `aria_engine` instead.
3. Removing the `aria_flow` and `aria_queue` applications from the project.

The initial implementation will focus on creating a `AriaEngine.Flow` behaviour and a `AriaEngine.Flow.Worker` without re-implementing the full `flow` functionality. The `flow` logic will be restored in a later phase.

## Implementation Plan

- [ ] Create `lib/aria_engine/flow.ex` to define the `AriaEngine.Flow` behaviour.
- [ ] Create `lib/aria_engine/flow/worker.ex` to define the `AriaEngine.Flow.Worker` module.
- [ ] Update `mix.exs` to remove the `aria_flow` and `aria_queue` dependencies.
- [ ] Update application code to use `AriaEngine.Flow` and `AriaEngine.Flow.Worker`.
- [ ] Remove the `apps/aria_flow` and `apps/aria_queue` directories.
- [ ] Run tests to ensure the consolidation was successful.

## Success Criteria

- The `aria_flow` and `aria_queue` applications are removed.
- All tests pass after the consolidation.
- The application successfully processes workflows using the new `AriaEngine.Flow` module.
