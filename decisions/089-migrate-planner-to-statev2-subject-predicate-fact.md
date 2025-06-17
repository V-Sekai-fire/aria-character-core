# ADR-089: Migrate Planner from State to StateV2 Subject-Predicate-Fact Format

**Status:** Active  
**Date:** June 17, 2025  
**Priority:** Critical - System Architecture Consistency

## Context

The AriaEngine planner system currently has a critical architectural inconsistency where two different state management formats coexist:

1. **Legacy State format**: Uses predicate-subject-fact pattern `State.get_fact(state, predicate, subject)`
2. **Modern StateV2 format**: Uses entity-first subject-predicate-fact pattern `StateV2.get_fact(state, subject, predicate)`

This inconsistency creates several problems:
- **API confusion**: Different modules use different parameter orders
- **Data integrity risks**: Conversion between formats can introduce bugs
- **Performance overhead**: Multiple conversions between formats
- **Developer confusion**: Unclear which format to use in new code
- **Entity-first architecture misalignment**: StateV2 supports Entity Timeline Graph Architecture (ADR-087) but planner doesn't use it

TimelineGraph has been correctly updated to use StateV2, but the core planning engine (`Plan.Core`, `NodeExpansion`, domain actions, etc.) still uses the legacy State format.

## Decision

Migrate the entire AriaEngine planner system to use StateV2's entity-first subject-predicate-fact format, ensuring consistent API patterns and supporting the Entity Timeline Graph Architecture.

## Implementation Plan

### Phase 1: Core Planner Migration (COMPLETED ✅)
- [x] Update `Plan.Core` to use StateV2 instead of State
- [x] Update `Plan.NodeExpansion` for entity-first goal checking  
- [x] Update goal validation logic to use subject-predicate-fact format
- [x] Update multigoal handling to use StateV2
- [x] Add StateV2 imports and remove State imports where appropriate
- [x] Update `Plan.Backtracking` to use StateV2
- [x] Update `Plan.Utils` to use StateV2
- [x] Update `Plan` facade to use StateV2
- [x] Update `Planning.CoreInterface` to use StateV2

### Phase 2: Domain Integration Migration
- [ ] Update domain actions in `actions.ex` to work with StateV2 format
- [ ] Update method precondition checking to use subject-predicate-fact
- [ ] Update effect application to use StateV2 API
- [ ] Update convenience functions to use StateV2
- [ ] Update domain utilities to use entity-first patterns

### Phase 3: Interface Migration
- [ ] Update `Planner.ex` facade to use StateV2
- [ ] Add conversion helpers for backward compatibility if needed
- [ ] Update all planning interfaces to accept StateV2
- [ ] Update tests to use StateV2 format

### Phase 4: Validation and Cleanup
- [ ] Run full test suite to ensure no regressions
- [ ] Update documentation to reflect StateV2 usage
- [ ] Remove legacy State usage where possible
- [ ] Add migration guide for external consumers

## Technical Migration Strategy

### State Conversion Pattern
```elixir
# OLD: Legacy State format (predicate-first)
State.get_fact(state, "location", "player")
State.set_fact(state, "location", "player", "room1")

# NEW: StateV2 format (entity-first)  
StateV2.get_fact(state, "player", "location")
StateV2.set_fact(state, "player", "location", "room1")
```

### Goal Format Migration
```elixir
# OLD: Goal checking (predicate-first)
{predicate, subject, fact_value} ->
  State.get_fact(state, predicate, subject) == fact_value

# NEW: Goal checking (entity-first)
{predicate, subject, fact_value} ->
  StateV2.get_fact(state, subject, predicate) == fact_value
```

### Backward Compatibility
- Use StateV2's `from_legacy_state/1` and `to_legacy_state/1` conversion functions
- Maintain external API compatibility where possible
- Provide clear migration path for domain definitions

## Success Criteria

- [ ] All planner modules use StateV2 exclusively
- [ ] No remaining usage of legacy State format in core planning
- [ ] Full test suite passes with StateV2 format
- [ ] Performance is maintained or improved
- [ ] Entity-first API patterns are consistent throughout
- [ ] Documentation reflects StateV2 usage patterns
- [ ] TimelineGraph integration works seamlessly with unified state format

## Consequences

### Benefits
- **Architectural consistency**: Single state format throughout the system
- **Entity-first alignment**: Supports Entity Timeline Graph Architecture (ADR-087)
- **Improved API clarity**: Consistent subject-predicate-fact parameter order
- **Better performance**: Eliminates format conversion overhead
- **Enhanced maintainability**: Single state management paradigm

### Risks
- **Breaking changes**: External consumers may need updates
- **Migration complexity**: Large codebase requires careful systematic migration
- **Temporary instability**: Risk of introducing bugs during migration
- **Testing burden**: Need comprehensive testing during transition

### Mitigation Strategies
- **Systematic migration**: Update modules one at a time with comprehensive testing
- **Backward compatibility**: Provide conversion functions where needed
- **Comprehensive testing**: Run full test suite after each module migration
- **Documentation**: Clear migration guide for external consumers

## Related ADRs
- **ADR-087**: Entity-Agent Timeline Graph Architecture (the motivation for entity-first state)
- **ADR-085**: Enhanced Scheduling System (already uses StateV2 via TimelineGraph)

---

**Next Steps**: Begin with Phase 1 by updating `Plan.Core` to use StateV2, then systematically migrate each planner module while maintaining test coverage.
