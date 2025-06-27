# R25W10468CD: Replace AriaEngine.StateV2 with State

<!-- @adr_serial R25W10468CD -->

## Status

Completed (Started: June 22, 2025, Completed: June 22, 2025)

## Context

Following R25W103F87B's decision to delete StateV2 and migrate to State v1, the codebase still contains 300+ references to `AriaEngine.StateV2` throughout the system. These references need systematic replacement with `State` to complete the migration.

The `State` module is already implemented in `lib/state.ex` but contains outdated documentation examples that still reference `AriaEngine.StateV2`. Additionally, the entire codebase has extensive usage of the old StateV2 API that needs migration.

## Decision

Systematically replace all `AriaEngine.StateV2` references with `State` throughout the codebase, including documentation, type annotations, function calls, and test infrastructure.

## Implementation Plan

### Phase 1: Documentation and Examples (LOW RISK)

**File**: `lib/state.ex`

**Completed**:

- [x] Fix documentation examples to use `State` instead of `AriaEngine.StateV2`
  - ✅ Updated module docstring examples
  - ✅ Fixed function documentation examples
  - ✅ Update quantifier function examples

### Phase 2: Type Annotations (MEDIUM RISK)

**Files**: All modules with StateV2 type references

**Completed**:

- [x] Replace `AriaEngine.StateV2.t()` with `State.t()` in type specs
- [x] Update function parameter types
- [x] Fix return type annotations
- [x] Update struct field types

**Key Files**:

- `lib/aria_engine/convenience.ex`
- `lib/aria_engine/plan.ex`
- `lib/aria_engine/multigoal.ex`
- `lib/aria_engine/domain/actions.ex`
- `lib/aria_engine/hybrid_planner/` modules

### Phase 3: API Call Migration (HIGH RISK)

**Critical Parameter Order Change**:

- StateV2: `set_fact(state, subject, predicate, value)`
- State: `set_fact(state, predicate, subject, value)`

**Completed**:

- [x] Replace `AriaEngine.StateV2.new()` with `State.new()`
- [x] Fix `set_fact/4` parameter order throughout codebase
- [x] Fix `get_fact/3` parameter order throughout codebase
- [x] Update pattern matching on state structs
- [x] Fix quantifier function calls (`exists?`, `forall?`, etc.)

**Key Files**:

- `lib/aria_engine/convenience.ex` (convenience API)
- `lib/aria_engine/blocks_world/` modules
- `lib/aria_engine/hybrid_planner/strategies/` modules
- `lib/aria_engine/membrane/` modules

**Completed**:

- [x] `lib/aria_engine/plan/execution.ex` - Fixed StateV2 references in apply_action function
  - ✅ Updated type annotations from `AriaEngine.StateV2.t()` to `State.t()`
  - ✅ Fixed parameter order in `State.get_fact/3` call (predicate, subject)
  - ✅ Updated pattern matching from `%AriaEngine.StateV2{}` to `%State{}`
  - ✅ Fixed apply_action function type specs and implementation
- [x] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/planning_operations.ex` - Fixed StateV2 references
  - ✅ Updated type annotations from `AriaEngine.StateV2.t()` to `State.t()`
  - ✅ Fixed pattern matching from `%AriaEngine.StateV2{}` to `%State{}`
  - ✅ Updated plan/5 and validate_plan/4 function signatures
- [x] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/execution_operations.ex` - Fixed StateV2 references
  - ✅ Updated type annotations from `AriaEngine.StateV2.t()` to `State.t()`
  - ✅ Fixed pattern matching from `%AriaEngine.StateV2{}` to `%State{}`
  - ✅ Updated execute/5 function signature
- [x] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/replanning_operations.ex` - Fixed StateV2 references
  - ✅ Updated type annotations from `AriaEngine.StateV2.t()` to `State.t()`
  - ✅ Fixed pattern matching from `%AriaEngine.StateV2{}` to `%State{}`
  - ✅ Updated replan/6 function signature

### Phase 4: Test Infrastructure (HIGH RISK)

**Files**: Test modules and test utilities

**Completed**:

- [x] Update test domains in test files
- [x] Fix StateV2Mock references
- [x] Update test assertions and expectations
- [x] Fix coverage reports and test utilities

### Phase 5: Build and Documentation Cleanup

**Completed**:

- [x] Update ADR references to StateV2
- [x] Clean up build artifacts mentioning StateV2
- [x] Remove any remaining aliases or imports
- [x] Update crash dump references (if possible)

## Implementation Strategy

### Step 1: Documentation First

Start with low-risk documentation fixes to validate approach and establish patterns.

### Step 2: Type-Driven Migration

Use Elixir compiler warnings to systematically identify and fix type mismatches.

### Step 3: API Migration with Testing

Apply call-site → leaf-node testing pattern (INST-040):

1. Identify call sites for each StateV2 function
2. Trace to leaf node implementations
3. Write tests for leaf nodes before migration
4. Fix leaf nodes first, then work upward

### Step 4: Integration Verification

Test entire system after each phase to ensure no regressions.

## Critical Migration Points

**Parameter Order Reversal**: Every function call needs careful review:

- `StateV2.set_fact(state, subject, predicate, value)` → `State.set_fact(state, predicate, subject, value)`
- `StateV2.get_fact(state, subject, predicate)` → `State.get_fact(state, predicate, subject)`

**Quantifier Functions**: State v1 has different API signatures for `exists?` and `forall?`

**Struct References**: Pattern matching and struct creation needs updating

## Success Criteria

- [x] All compilation errors resolved
- [x] All tests passing with State v1 API
- [x] No remaining `AriaEngine.StateV2` references in source code
- [x] Documentation examples use `State` consistently
- [x] Build artifacts updated (where possible)

## Consequences

- **Simplified codebase**: Single state management system
- **Consistent API**: All modules use same state interface
- **Reduced confusion**: Clear migration path completed
- **Potential breaking changes**: External code using StateV2 will break

## Notes

- There are still some warnings about undefined functions in `lib/aria_engine/blocks_world/domain.ex` and `lib/aria_engine/domain/utils.ex`. These are due to missing modules `AriaEngine.BlocksWorld.Helpers` and `AriaEngine.BlocksWorld.Methods`, and a missing `Actions` module. These are outside the scope of the current task, which is to replace `StateV2` with `State`.

## Related ADRs

- **R25W103F87B**: Parent ADR for StateV2 deletion and migration strategy
