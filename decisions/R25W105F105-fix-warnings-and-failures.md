# R25W105F105: Fix Warnings and Failures

<!-- @adr_serial R25W105F105 -->

## Status

Active (Started: June 22, 2025)

## Context

After completing the migration from `StateV2` to `State` in R25W10468CD, there are still a number of warnings and test failures. This ADR will address these issues.

## Decision

Systematically fix all warnings and test failures.

## Implementation Plan

### Phase 1: Fix Compilation Warnings

- [x] Fix `unused alias` warnings in `test/aria_engine/blocks_world_domain_test.exs`
- [x] Create missing helper modules:
  - Created `lib/aria_engine/blocks_world/helpers.ex` with required functions
  - Created `lib/aria_engine/blocks_world/methods.ex` with required functions
- [x] Fix `undefined function` warnings in `lib/aria_engine/blocks_world/domain.ex`
- [x] Fix `undefined function` warnings in `lib/aria_engine/domain/utils.ex`
- [ ] Fix `defp ... is private, @doc attribute is always discarded` warnings.

### Phase 2: Fix Test Failures

- [x] Fix StateV2 references in `test/aria_engine/structure_multigoal_optimization_test.exs`
  - Replaced all `StateV2` module references with `State`
  - Updated all type specifications from `StateV2.t()` to `State.t()`
  - Fixed `StateV2.new()` calls to use `State.new()`
- [ ] Fix test failures related to incorrect parameter order in `set_fact` and `get_fact`.
- [ ] Fix any other test failures.

## Progress Notes

### June 22, 2025 - Session 1

- ✅ Fixed unused alias warning in blocks world domain test
- ✅ Created missing helper and methods modules for blocks world domain
- ✅ Fixed undefined function warnings by implementing required functions
- ✅ Completely migrated structure multigoal optimization test from StateV2 to State
- 🔄 Currently running compilation to verify fixes
