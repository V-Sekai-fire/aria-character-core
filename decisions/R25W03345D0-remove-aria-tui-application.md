---
date: 2025-06-15
status: completed
---

# Remove Aria TUI Application

<!-- @adr_serial R25W03345D0 -->

## Context

The `aria_tui` application is no longer required for the project's core functionality. To simplify the architecture and reduce maintenance overhead, it will be removed.

## Implementation Plan

- [x] Remove the `aria_tui` application directory
- [x] Update `mix.exs` to remove the application from the project
- [x] Remove references to `aria_tui` from configuration files
- [x] Delete the `aria_tui` entry from `.github/CODEOWNERS`
- [x] Remove any other lingering references to `aria_tui`

## Success Criteria

- The `aria_tui` application is completely removed from the codebase
- The project compiles and runs successfully without the `aria_tui` application
- All references to `aria_tui` are removed

## Outcome

The `aria_tui` application has been successfully removed from the project. All related files and references have been deleted, and the test suite passes without any errors, confirming that the removal did not introduce any regressions.
