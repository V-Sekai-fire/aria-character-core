# ADR-120: Strategy Factory Validation Reactivation

**Status:** Proposed
**Date:** June 21, 2025  
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
- [ ] Analyze current module loading dependencies causing validation issues
- [ ] Identify circular dependencies between strategy modules and factory
- [ ] Design loading order that enables safe validation

### Phase 2: Validation Architecture
- [ ] Implement deferred validation system for compile-time safety
- [ ] Create behavior validation functions for each strategy type
- [ ] Add validation caching to avoid repeated checks

### Phase 3: Validation Implementation
- [ ] Re-enable `validate_strategy_module/2` function
- [ ] Implement behavior checking for all strategy types:
  - `PlanningStrategy` behavior validation
  - `TemporalStrategy` behavior validation  
  - `StateStrategy` behavior validation
  - `DomainStrategy` behavior validation
  - `LoggingStrategy` behavior validation
  - `ExecutionStrategy` behavior validation

### Phase 4: Error Handling and Testing
- [ ] Implement comprehensive error reporting
- [ ] Add validation tests for all strategy types
- [ ] Test module loading order scenarios
- [ ] Verify validation doesn't break existing functionality

## Success Criteria

- [ ] Strategy validation is re-enabled in `register_strategy/4`
- [ ] All strategy types have proper behavior validation
- [ ] Module loading order issues are resolved
- [ ] Validation provides clear, actionable error messages
- [ ] All existing strategy registrations continue to work
- [ ] Invalid strategy modules are properly rejected

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

- **ADR-091**: Hybrid planner dependency encapsulation
- **ADR-112**: Hybrid coordinator v3 implementation

## References

- `lib/aria_engine/hybrid_planner/strategy_factory.ex:109`
- Strategy behavior definitions in `lib/aria_engine/hybrid_planner/strategies/`
