# R25W103F87B: Delete StateV2 and Migrate to State v1

<!-- @adr_serial R25W103F87B -->

## Status

Active (Started: June 22, 2025)

## Context

The codebase currently has two state management systems:

- **State v1** (`State`): Predicate-first API with `{predicate, subject} -> fact_value`
- **StateV2** (`AriaEngine.StateV2`): Entity-first API with `{subject, predicate} -> fact_value`

This duplication creates confusion and complexity. StateV2 was an experimental approach that added entity-first semantics, but State v1 is simpler and more stable.

## Decision

Delete StateV2 completely and migrate all usage back to State v1.

## Implementation Plan

### Phase 1: Core State Migration ✅

- [x] Update type annotations from `AriaEngine.StateV2.t()` to `State.t()`
- [x] Fix API calls - State v1 uses `{predicate, subject}` order vs StateV2's `{subject, predicate}`
- [x] Replace StateV2 module references with `State`
- [x] Fix Plan.Core module StateV2 references
- [x] Fix Plan.Backtracking module StateV2 references

### Phase 2: Blocks World Domain Fix

- [ ] Convert StateUtils to use State v1 API with correct parameter order
- [ ] Update Actions module to use State v1
- [ ] Create missing Methods and Helpers modules for State v1
- [ ] Fix test suite to use State v1

### Phase 3: Test Infrastructure

- [ ] Update test domains in `test_domains.ex` (heavily uses StateV2)
- [ ] Remove StateV2Mock and related test infrastructure
- [ ] Update all test assertions to use State v1 API

### Phase 4: Cleanup

- [ ] Delete StateV2 module completely
- [ ] Update documentation and ADRs that reference StateV2
- [ ] Clean up any remaining references

## Critical Migration Points

- **Parameter order reversal**: Every `StateV2.set_fact(state, subject, predicate, value)` becomes `State.set_fact(state, predicate, subject, value)`
- **Quantifier functions**: State v1 has different quantifier API signatures
- **Timeline integration**: Needs careful migration due to entity-first vs predicate-first approach

## Success Criteria

- [ ] All compilation errors resolved
- [ ] All tests passing
- [ ] StateV2 module deleted
- [ ] No remaining StateV2 references in codebase
- [ ] Blocks World domain working with State v1

## Consequences

- **Simplified architecture**: Single state management system
- **Reduced confusion**: Clear API without competing approaches
- **Better maintainability**: Less code to maintain
- **Potential breaking changes**: Any external code using StateV2 will break
