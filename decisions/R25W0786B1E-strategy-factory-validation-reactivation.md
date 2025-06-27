# R25W0786B1E: Strategy Factory Validation Reactivation

<!-- @adr_serial R25W0786B1E -->

**Status:** Completed
**Date:** June 21, 2025  
**Completion Date:** June 21, 2025
**Priority:** MEDIUM

## Context

The `HybridPlanner.StrategyFactory` module currently has disabled strategy validation due to module loading order issues. The TODO comment on line 109 indicates the need to re-enable validation after addressing these compilation dependencies.

Currently, the `register_strategy/4` function has commented out validation code:

```elixir
# TODO: Re-enable validation after addressing module loading order
# case validate_strategy_module(strategy_type, strategy_module) do
#   :ok -> :ok
#   {:error, reason} -> raise ArgumentError, "Strategy validation failed: #{reason}"
# end
```

This creates a potential runtime safety issue where invalid strategy modules could be registered without proper behavior validation.

## Decision

Implement a robust strategy validation system that:

1. Resolves module loading order dependencies
2. Validates strategy modules implement required behaviors
3. Provides clear error messages for validation failures
4. Supports both compile-time and runtime validation modes

## Implementation Plan

### Phase 1: Module Loading Analysis

- [x] Analyze current module loading dependencies causing validation issues
  - ✅ Found that validation was disabled due to compilation order between StrategyFactory and strategy modules
  - ✅ Strategy behaviors are defined in `HybridPlanner.Strategies` module with clear callback definitions
  - ✅ All strategy implementations use `@behaviour` declarations correctly
- [x] Identify circular dependencies between strategy modules and factory
  - ✅ No actual circular dependencies found - issue was premature validation during module loading
  - ✅ Strategy modules don't depend on StrategyFactory, only StrategyFactory references strategy modules
- [x] Design loading order that enables safe validation
  - ✅ Use deferred validation approach: validate during coordinator creation, not registration
  - ✅ Cache validation results to avoid repeated behavior checks

### Phase 2: Validation Architecture

- [x] Implement deferred validation system for compile-time safety
  - ✅ Added validation_cache field to StrategyFactory struct
  - ✅ Implemented validate_strategy_module/3 with caching
  - ✅ Created perform_strategy_validation/2 for actual validation logic
- [x] Create behavior validation functions for each strategy type
  - ✅ Added get_behavior_module_for_strategy_type/1 mapping function
  - ✅ Implemented validate_behavior_implementation/2 for callback checking
  - ✅ Added get_behavior_callbacks/1 with all required callbacks for each strategy type
- [x] Add validation caching to avoid repeated checks
  - ✅ Validation results cached in factory.validation_cache
  - ✅ Cache checked before performing validation to avoid repeated work

### Phase 3: Validation Implementation

- [x] Re-enable `validate_strategy_module/2` function
  - ✅ Implemented validate_strategy_module/3 with caching support
  - ✅ Added validate_all_strategy_modules/2 for coordinator creation
  - ✅ Integrated validation into create_coordinator/3 function
- [x] Implement behavior checking for all strategy types:
  - ✅ `PlanningStrategy` behavior validation (plan/4, replan/5, validate_plan/3, strategy_info/0)
  - ✅ `TemporalStrategy` behavior validation (add_temporal_constraints/3, validate_temporal_consistency/2, update_constraints/3, get_temporal_schedule/2)
  - ✅ `StateStrategy` behavior validation (apply_action/4, query_state/3, create_checkpoint/3, rollback_to_checkpoint/3)
  - ✅ `DomainStrategy` behavior validation (get_action_metadata/3, get_task_methods/3, get_goal_methods/3, validate_domain/2)
  - ✅ `LoggingStrategy` behavior validation (log/4, log_progress/3, log_error/3, configure/2)
  - ✅ `ExecutionStrategy` behavior validation (execute_plan/4, execute_step/4, handle_execution_failure/4)

### Phase 4: Error Handling and Testing

- [x] Implement comprehensive error reporting
  - ✅ Clear error messages for missing callbacks and validation failures
  - ✅ Proper exception handling in validation functions
  - ✅ Detailed error context including strategy module and behavior type
- [x] Add validation tests for all strategy types
  - ✅ Created strategy_factory_validation_test.exs with comprehensive test coverage
  - ✅ Tests validate all default configurations and strategy types
  - ✅ Tests verify validation caching functionality
- [x] Test module loading order scenarios
  - ✅ Deferred validation approach resolves compilation order issues
  - ✅ All tests pass without module loading conflicts
- [x] Verify validation doesn't break existing functionality
  - ✅ All existing strategy registrations continue to work
  - ✅ All default configurations create coordinators successfully

## Success Criteria

- [x] Strategy validation is re-enabled in `create_coordinator/3` (deferred validation approach)
- [x] All strategy types have proper behavior validation
- [x] Module loading order issues are resolved
- [x] Validation provides clear, actionable error messages
- [x] All existing strategy registrations continue to work
- [x] Invalid strategy modules are properly rejected (validation system in place)

## Consequences

**Benefits:**

- Improved runtime safety through strategy validation
- Better error messages for invalid strategy configurations
- Prevents registration of incompatible strategy modules
- Maintains strategy interface contracts

**Risks:**

- Potential compilation issues if module loading order isn't properly resolved
- Performance impact from validation checks
- Possible breaking changes if existing strategies don't meet validation requirements

## Implementation Strategy

### Deferred Validation Approach

Use a deferred validation system where:

1. Strategies are registered immediately for compilation compatibility
2. Validation occurs during first coordinator creation
3. Validation results are cached for subsequent uses

### Behavior Validation Methods

- Use `function_exported?/3` to check required callback implementations
- Validate strategy module attributes and metadata
- Test strategy initialization with sample parameters

## Related ADRs

- **R25W0489307**: Hybrid planner dependency encapsulation
- **R25W069348D**: Hybrid coordinator v3 implementation

## References

- `lib/aria_engine/hybrid_planner/strategy_factory.ex:109`
- Strategy behavior definitions in `lib/aria_engine/hybrid_planner/strategies/`
