Disconnect apps/aria_engine_core with the internal apis using :mox.

Do the disconnected with :mox. But make unit tests for using the internal dependencies with :mox.

Follow @adr_serial R25W1398085

## Implementation Plan for Mox-Based Dependency Injection

### Phase 1: Behavior Definitions (Priority: HIGH)

**File**: `lib/aria_engine_core/behaviours/`

**Missing/Required**:

- [x] Create `PlannerBehaviour` with `plan/4` callback
- [x] Create `ExecutorBehaviour` with `execute/4` callback  
- [x] Create `CoordinatorBehaviour` with `new_coordinator/0` callback
- [x] Add comprehensive typespecs for all behavior callbacks

**Implementation Patterns Needed**:

- [ ] Elixir behavior pattern with `@callback` definitions
- [ ] Type specifications matching ADR R25W1398085 format

### Phase 2: Adapter Implementations (Priority: HIGH)

**File**: `lib/aria_engine_core/adapters/`

**Missing/Required**:

- [x] `HybridPlannerAdapter` implementing `PlannerBehaviour`
- [x] `HybridExecutorAdapter` implementing `ExecutorBehaviour`
- [x] `HybridCoordinatorAdapter` implementing `CoordinatorBehaviour`
- [x] Error handling and logging for adapter failures

**Implementation Patterns Needed**:

- [ ] Adapter pattern wrapping existing `AriaHybridPlanner.Core` calls
- [ ] Consistent error handling across all adapters

### Phase 3: Mox Test Infrastructure (Priority: MEDIUM)

**File**: `test/test_helper.exs` and `test/mocks/`

**Missing/Required**:

- [x] Configure Mox in test_helper.exs
- [x] Create mock definitions for all behaviors
- [x] Add test utilities for common mock scenarios
- [x] Update existing tests to use mocked dependencies

**Implementation Patterns Needed**:

- [ ] Mox.defmock pattern for behavior mocking
- [ ] Test setup and teardown for mock state

### Phase 4: Dependency Injection (Priority: HIGH)

**File**: `lib/aria_engine_core/planner.ex`

**Missing/Required**:

- [x] Modify `AriaEngineCore.Planner` to accept injected dependencies
- [x] Add configuration-based dependency resolution
- [x] Maintain backward compatibility with existing API
- [x] Add runtime dependency validation

**Implementation Patterns Needed**:

- [ ] Application configuration for dependency selection
- [ ] Runtime dependency injection pattern

## Implementation Strategy

### Step 1: Create Behavior Definitions

1. Define clear interfaces matching current AriaHybridPlanner.Core usage
2. Add comprehensive documentation and typespecs
3. Ensure behaviors align with ADR R25W1398085 specification

### Step 2: Implement Adapters

1. Create adapters that wrap existing internal API calls
2. Add proper error handling and logging
3. Test adapters against real dependencies first

### Step 3: Add Mox Infrastructure

1. Configure Mox for test environment
2. Create comprehensive mock implementations
3. Update test suite to use mocks instead of real dependencies

### Step 4: Integrate Dependency Injection

1. Modify core modules to accept injected dependencies
2. Add configuration system for selecting implementations
3. Ensure seamless transition from current implementation

### Current Focus: Behavior Definitions

Starting with behavior definitions because they establish the contract that both real adapters and mocks must implement. This ensures consistency and makes the subsequent phases more straightforward.
