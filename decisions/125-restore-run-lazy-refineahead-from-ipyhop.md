# ADR-125: Restore run_lazy_refineahead from IPyHOP

**Status:** Active  
**Date:** 2025-06-21  
**Priority:** HIGH

## Context

During recent cleanup efforts (ADR-124), we removed the `run_lazy_refineahead` function from `AriaEngine.Plan.Execution`, replacing it with simple `Plan.validate_plan` calls. However, this was a mistake - `run_lazy_refineahead` implements a core algorithm from IPyHOP that provides true lazy refinement capabilities essential for hierarchical task network (HTN) planning.

### Current Problem

- The lazy execution strategy now uses `Plan.validate_plan` which doesn't provide incremental refinement
- We lost the sophisticated backtracking and method selection capabilities from IPyHOP
- The blacklisting functionality exists but isn't integrated with proper lazy execution
- Tests that depend on lazy refinement behavior are failing

### IPyHOP Algorithm Analysis

From examining `thirdparty/IPyHOP/ipyhop/planner.py`, the core `_planning` method implements:

1. **Iterative Refinement**: Processes nodes in the solution tree one at a time
2. **Backtracking**: When a node fails, backtracks to find alternative methods
3. **State Management**: Saves and restores state at each node for proper backtracking
4. **Method Selection**: Tries multiple methods for tasks/goals until one succeeds
5. **Blacklisting**: Prevents repeated attempts of failed actions
6. **Lazy Evaluation**: Only refines nodes as needed, not the entire plan upfront

## Decision

Restore `run_lazy_refineahead` in `AriaEngine.Plan.Execution` based on the IPyHOP `_planning` algorithm, adapted for Elixir and our existing data structures.

## Implementation Plan

### Phase 1: Core Algorithm Implementation (HIGH PRIORITY)

**File**: `lib/aria_engine/plan/execution.ex`

- [ ] Implement `run_lazy_refineahead/4` function signature
- [ ] Port IPyHOP's iterative refinement loop to Elixir
- [ ] Implement node status tracking (Open, Closed, Failed)
- [ ] Add state save/restore mechanism for backtracking
- [ ] Integrate with existing blacklisting functionality

**Implementation Patterns Needed**:
- [ ] Solution tree traversal using our existing tree structures
- [ ] Method iteration and selection logic
- [ ] Backtracking algorithm with proper state restoration
- [ ] Integration with `AriaEngine.StateV2` for state management

### Phase 2: Integration with Strategy System (MEDIUM PRIORITY)

**File**: `lib/aria_engine/hybrid_planner/strategies/default/lazy_execution_strategy.ex`

- [ ] Update lazy execution strategy to use restored `run_lazy_refineahead`
- [ ] Remove temporary `Plan.validate_plan` calls
- [ ] Ensure proper error handling and result formatting
- [ ] Add strategy metadata reflecting IPyHOP capabilities

### Phase 3: Testing and Validation (HIGH PRIORITY)

**File**: `test/aria_engine/plan/lazy_execution_test.exs`

- [ ] Restore comprehensive tests for lazy refinement
- [ ] Test backtracking behavior with method failures
- [ ] Test state save/restore during backtracking
- [ ] Test integration with blacklisting
- [ ] Test incremental refinement vs full plan validation

### Phase 4: Documentation and Integration (MEDIUM PRIORITY)

- [ ] Document the IPyHOP algorithm adaptation
- [ ] Update strategy documentation to reflect lazy capabilities
- [ ] Add examples of lazy vs eager execution differences
- [ ] Document blacklisting integration

## IPyHOP Algorithm Key Components

### Node Types and Processing

From IPyHOP analysis:
- **Task nodes ('T')**: Decomposed using task methods
- **Action nodes ('A')**: Executed directly, can be blacklisted
- **Goal nodes ('G')**: Achieved using goal methods
- **MultiGoal nodes ('M')**: Multiple goals processed together

### State Management

- Each node can save its state for backtracking
- State is restored when backtracking occurs
- Current state is updated as actions succeed

### Method Selection

- Each task/goal has multiple available methods
- Methods are tried in order until one succeeds
- Failed methods are skipped on backtracking

### Backtracking Logic

- When a node fails, algorithm backtracks to parent
- Parent node tries next available method
- Process continues until solution found or all methods exhausted

## Success Criteria

- [ ] `run_lazy_refineahead` successfully implements IPyHOP-style lazy refinement
- [ ] Backtracking works correctly with method failures
- [ ] State save/restore maintains consistency during backtracking
- [ ] Blacklisting prevents repeated execution of failed actions
- [ ] Integration with existing strategy system works seamlessly
- [ ] All lazy execution tests pass
- [ ] Performance is comparable to or better than previous implementation

## Consequences

### Benefits

- **True Lazy Execution**: Incremental refinement as intended by IPyHOP
- **Robust Backtracking**: Proper handling of method failures and alternatives
- **State Consistency**: Correct state management during planning
- **Algorithm Fidelity**: Faithful implementation of proven HTN algorithm
- **Blacklisting Integration**: Proper failure handling and learning

### Risks

- **Implementation Complexity**: IPyHOP algorithm is sophisticated
- **State Management**: Elixir immutability vs Python mutability differences
- **Performance**: Need to ensure efficient tree traversal and state handling
- **Integration**: Must work with existing AriaEngine data structures

## Related ADRs

- **ADR-121**: Lazy Execution Strategy Implementation (original implementation)
- **ADR-124**: Fix Planning Logic in Lazy Execution Tests (where removal occurred)
- **ADR-091**: Hybrid Planner Dependency Encapsulation (strategy architecture)

## Implementation Strategy

### Step 1: Algorithm Study and Design
1. Analyze IPyHOP `_planning` method in detail
2. Map IPyHOP concepts to AriaEngine data structures
3. Design Elixir-idiomatic implementation approach

### Step 2: Core Implementation
1. Implement basic refinement loop structure
2. Add node processing for different node types
3. Implement backtracking mechanism
4. Integrate state save/restore

### Step 3: Integration and Testing
1. Connect with lazy execution strategy
2. Add comprehensive test coverage
3. Validate against IPyHOP behavior
4. Performance testing and optimization

### Current Focus: Algorithm Study and Core Implementation

Starting with detailed analysis of IPyHOP's `_planning` method to understand the exact algorithm flow, then implementing the core refinement loop in Elixir with proper integration to our existing tree structures and state management.

The IPyHOP algorithm provides the sophisticated lazy refinement capabilities that are essential for proper HTN planning, and restoring this functionality is critical for the hybrid planner's effectiveness.
