# Node Library Planner Test Fixes

## Overview
**Current State**: Tests mix direct execution and disabled planner tests
**Target State**: All tests use planner execution only

## Phase Breakdown

### Phase 1: Convert Unit Tests to Planner Execution (PRIORITY: HIGH)
**File**: `test/aria_engine/node_library/khr_interactivity/unit/math_nodes_test.exs`

**Current Issues**:
- [ ] Tests use direct function calls like `KHRInteractivityDomain.math_e(state, [0])`
- [ ] Need to convert to planner goals like `{"math/e", [0]}`
- [ ] Need to ensure domain registration includes task methods
- [ ] Need to verify all math operations work through planner

**Implementation Patterns Needed**:
- [ ] Goal-based test pattern: `goals = [{"math/e", [node_id]}]`
- [ ] Planner execution: `Planner.plan(domain, state, goals)`
- [ ] Plan execution loop to get final state

### Phase 2: Enable Integration Tests (PRIORITY: HIGH) 
**File**: `test/aria_engine/node_library/khr_interactivity/integration/planner_math_nodes_test.exs.disabled`

**Missing/Required**:
- [ ] Remove `.disabled` extension
- [ ] Fix any compilation or test issues
- [ ] Ensure domain registration includes both actions and task methods
- [ ] Verify planner can decompose KHR tasks

**Implementation Patterns Needed**:
- [ ] Domain setup with both `register_actions()` and `register_task_methods()`
- [ ] Goal-based math operation chains
- [ ] Plan execution and state verification

### Phase 3: Create Stack Test with KHR Nodes Only (PRIORITY: MEDIUM)
**File**: New test file for stack operations

**Missing/Required**:
- [ ] Stack implementation using only KHR variable and math nodes
- [ ] Push operation: get pointer, increment, set value at new position
- [ ] Pop operation: get pointer, get value, decrement pointer
- [ ] Stack-based calculator operations
- [ ] Complex expression evaluation using stack

**Implementation Patterns Needed**:
- [ ] Variable management goals: `{"variable/set", [var_name, value]}`
- [ ] Math operation goals: `{"math/add", [output_id, a, b]}`
- [ ] Sequential goal execution through planner
- [ ] State verification after each operation

## Implementation Strategy

### Step 1: Fix Domain Registration
1. Ensure KHRInteractivityDomain registers both actions and task methods
2. Verify task methods exist for all math operations
3. Update domain registration in tests

### Step 2: Convert Unit Tests
1. Replace direct calls with goal-based planning
2. Add domain setup with proper registration
3. Convert assertions to check final planned state

### Step 3: Enable Integration Tests
1. Remove `.disabled` extension
2. Fix any issues preventing compilation
3. Ensure tests pass with current planner implementation

### Step 4: Create Stack Test
1. Design stack operations using KHR nodes
2. Implement push/pop through planning goals
3. Create complex calculator test scenarios

## Current Focus: Fix Planner Task Method Registration
Discovered that planner execution is failing with "No methods found for goal: ok" - this suggests the task method registration or planner goal format is incorrect.

## Progress Made:
- [x] Added complete domain registration with both actions and task methods
- [x] Created new planner-based unit test file
- [x] Enabled integration tests (removed .disabled extension)
- [x] Fixed execute_plan helper function signature

## Issues Found:
- [ ] Planner.plan() returns error "No methods found for goal: ok"
- [ ] Both integration and unit planner tests fail
- [ ] Direct execution tests work fine
- [ ] Task method registration may not be working with current planner

## Next Steps:
1. Debug planner task method registration
2. Verify goal format matches planner expectations
3. Check if current planner supports task methods properly
4. Consider falling back to action-only approach if needed
