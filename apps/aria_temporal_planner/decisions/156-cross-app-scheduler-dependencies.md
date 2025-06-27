# ADR-156: Cross-App Scheduler Dependencies

<!-- @adr_serial R25W00542DE -->

**Status:** Active (Paused)  
**Date:** June 23, 2025  
**Priority:** MEDIUM

## Context

The `aria_scheduler` app has 8 test failures out of 13 tests due to missing `AriaEngine.PlannerAdapter` dependency from `aria_hybrid_planner`. The scheduler cannot execute enhanced planning because the interface contract between apps is broken.

**Current Issues:**

- Error: "plan_tasks requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"
- Interface contract mismatch between scheduler and hybrid planner
- Integration layer broken between task scheduling and planning generation
- Cascading planning failures prevent task execution

**Impact:**

- Scheduler cannot convert planning goals into executable task schedules
- Planning pipeline broken across app boundaries
- Integration testing blocked for scheduling functionality
- Development workflow disrupted for scheduling features

## Decision

Restore the interface contract between aria_scheduler and aria_hybrid_planner by implementing the missing PlannerAdapter and fixing cross-app integration.

## Implementation Plan

### Phase 1: Analyze Interface Contract (Day 1)

**Contract Investigation:**

- [ ] Examine aria_scheduler code to understand PlannerAdapter requirements
- [ ] Identify expected interface methods and signatures
- [ ] Document current implementation gaps in aria_hybrid_planner
- [ ] Map scheduler expectations to hybrid planner capabilities

**Expected Interface Methods:**

- [ ] `plan_tasks/2` - Core planning function expected by scheduler
- [ ] Error handling and result formatting contracts
- [ ] Configuration and parameter passing interfaces
- [ ] State management and lifecycle methods

### Phase 2: Implement Missing PlannerAdapter (Day 1-2)

**File:** `apps/aria_hybrid_planner/lib/planner_adapter.ex`

- [ ] Create AriaEngine.PlannerAdapter module (maintaining legacy namespace for compatibility)
- [ ] Implement `plan_tasks/2` function with proper signature
- [ ] Add error handling and result formatting
- [ ] Ensure compatibility with scheduler expectations

**Interface Implementation:**

```elixir
defmodule AriaEngine.PlannerAdapter do
  @moduledoc """
  Adapter interface for aria_scheduler integration.
  Provides planning capabilities to the scheduler app.
  """
  
  def plan_tasks(goals, context) do
    # Implementation that bridges scheduler requests to hybrid planner
  end
  
  def validate_planning_request(request) do
    # Validation logic for scheduler requests
  end
  
  def format_planning_result(result) do
    # Result formatting for scheduler consumption
  end
end
```

### Phase 3: Fix Cross-App Integration (Day 2-3)

**Dependency Configuration:**

- [ ] Update `apps/aria_scheduler/mix.exs` to properly depend on aria_hybrid_planner
- [ ] Ensure aria_hybrid_planner exports PlannerAdapter in application module
- [ ] Fix any circular dependency issues between apps
- [ ] Validate dependency resolution in umbrella project

**Interface Bridging:**

- [ ] Implement adapter pattern to bridge scheduler and hybrid planner APIs
- [ ] Handle data format conversion between apps
- [ ] Add proper error propagation and handling
- [ ] Ensure graceful degradation when planning fails

### Phase 4: Restore Scheduler Test Suite (Day 3-4)

**Test Fixes:**

- [ ] Update scheduler tests to work with new PlannerAdapter interface
- [ ] Mock PlannerAdapter for isolated scheduler testing
- [ ] Add integration tests for scheduler-planner interaction
- [ ] Fix any remaining test failures in aria_scheduler

**Test Categories:**

- [ ] Unit tests for scheduler core functionality
- [ ] Integration tests for PlannerAdapter interface
- [ ] End-to-end tests for planning workflow
- [ ] Error handling and edge case tests

### Phase 5: Validation and Integration Testing (Day 4-5)

**Cross-App Testing:**

- [ ] Run `cd apps/aria_scheduler && mix test` to verify fixes
- [ ] Test scheduler functionality with real hybrid planner integration
- [ ] Validate planning pipeline works end-to-end
- [ ] Ensure proper error handling across app boundaries

**Performance and Reliability:**

- [ ] Test planning performance with realistic workloads
- [ ] Validate memory usage and resource management
- [ ] Ensure stable operation under various conditions
- [ ] Test recovery from planning failures

## Success Criteria

### Critical Success

- [ ] All 13 aria_scheduler tests pass consistently
- [ ] PlannerAdapter interface fully implemented and functional
- [ ] Scheduler can successfully execute enhanced planning workflows
- [ ] Cross-app integration stable and reliable

### Quality Success

- [ ] Clear interface contract documented between apps
- [ ] Proper error handling and graceful degradation
- [ ] Integration tests validate cross-app contracts
- [ ] Performance meets scheduling requirements

## Implementation Strategy

### Step 1: Interface Analysis

1. Examine scheduler code to understand exact PlannerAdapter requirements
2. Document expected method signatures and behavior
3. Identify data formats and error handling expectations
4. Map requirements to hybrid planner capabilities

### Step 2: Adapter Implementation

1. Create PlannerAdapter module with required interface
2. Implement core planning functionality
3. Add proper error handling and result formatting
4. Test adapter functionality in isolation

### Step 3: Integration Restoration

1. Fix dependency configuration between apps
2. Update scheduler to use new PlannerAdapter
3. Test cross-app communication and data flow
4. Validate end-to-end planning workflows

## Interface Contract Specification

### PlannerAdapter Interface

```elixir
@spec plan_tasks(goals :: list(), context :: map()) :: 
  {:ok, tasks :: list()} | {:error, reason :: term()}

@spec validate_planning_request(request :: map()) :: 
  :ok | {:error, validation_errors :: list()}

@spec format_planning_result(result :: term()) :: 
  {:ok, formatted_result :: map()} | {:error, reason :: term()}
```

### Data Formats

- **Goals**: List of planning objectives with constraints
- **Context**: Planning environment and resource information
- **Tasks**: Executable task list with timing and dependencies
- **Errors**: Structured error information for debugging

### Error Handling

- **Planning Failures**: Graceful degradation when planning impossible
- **Resource Constraints**: Clear error messages for resource conflicts
- **Validation Errors**: Detailed feedback for invalid requests
- **System Errors**: Proper error propagation across app boundaries

## Consequences

### Risks

- **Medium:** Interface changes may require updates to scheduler implementation
- **Low:** Performance impact from cross-app communication overhead
- **Low:** Potential for introducing new integration bugs

### Benefits

- **High:** Scheduler functionality restored with planning capabilities
- **High:** Integration testing enabled for scheduling workflows
- **Medium:** Clear interface contracts improve maintainability
- **Medium:** Foundation for future scheduler enhancements

## Related ADRs

- **ADR-151**: Strict Encapsulation Modular Testing Architecture (modularization foundation)
- **ADR-152**: Complete Temporal Relations System Implementation (superseded parent)
- **ADR-155**: Hybrid Planner Test Suite Restoration (related testing work)
- **ADR-154**: Timeline Module Namespace Aliasing Fixes (parallel testing work)

## Monitoring

- **Test Success Rate**: aria_scheduler test pass rate (target: 100%)
- **Integration Health**: Cross-app communication success rate
- **Planning Performance**: Time to complete planning requests
- **Error Rate**: Frequency of planning failures and error handling

## Notes

This ADR addresses a critical integration issue that prevents the scheduler from functioning properly. The PlannerAdapter interface is essential for bridging the scheduler and hybrid planner apps.

**Implementation Priority:** This work should proceed after or in parallel with hybrid planner test restoration (ADR-155), as both address related integration issues.

**Interface Focus:** The PlannerAdapter implementation should prioritize compatibility with existing scheduler expectations while providing a clean interface for future enhancements.
