# R25W041FBCD: Domain Method Naming and STN Bridge Integration

<!-- @adr_serial R25W041FBCD -->

**Status:** Deferred  
**Date:** June 16, 2025  
**Closure Date:** June 21, 2025

## Context

The AriaEngine planner and domain modules have critical issues with method naming, blacklisting, and temporal planning integration that are causing test failures and Dialyzer warnings:

### Core Issues Identified

1. **Method Storage Mismatch**: The Domain module type definitions specify methods should be stored as `{method_name(), function()}` pairs, but the implementation stores them as raw function references
2. **String.Chars Protocol Errors**: Function references are being interpolated in string contexts without `inspect`, causing protocol errors
3. **Blacklisting Failures**: Method blacklisting expects method names (strings) but receives function references  
4. **Logging Inconsistencies**: Method names are needed for logging and debugging but are not available from function references in Elixir
5. **STN Bridge Architecture**: The planner references "STN bridge" concepts that are not fully implemented

### GTPyhop Alignment Requirements

Based on GTPyhop Python implementation research:

- Actions: stored as `{name -> function}` mappings
- Methods: stored as `{task_name -> [function_list]}` but method names are available via `__name__` attribute
- Method names: not required to be unique globally; multiple methods can exist for the same task
- Method names: essential for logging, blacklisting, and error reporting

### STN Bridge Integration

The planner comments reference STN bridges for:

- Non-temporal HTN operations (method selection, goal decomposition, blacklisting)
- Instantaneous decision points separating temporal execution segments
- Reentrant planning from failure points
- Temporal constraint propagation

## Decision

Refactor the Domain and planner modules to align with GTPyhop conventions and implement STN bridge architecture:

### Phase 1: Method Naming Foundation

- Update Domain module to store methods as `{method_name, function}` pairs
- Modify all method addition functions to require both name and function  
- Update planner logic to use method names for blacklisting and logging
- Fix String.Chars protocol errors by using method names instead of function interpolation

### Phase 2: STN Bridge Architecture  

- Design and implement STN bridge pattern for non-temporal operations
- Integrate temporal constraint propagation with bridge actions
- Support reentrant planning and solution tree updates with temporal validation
- Document the bridge architecture and its relationship to existing STN validation

### Phase 3: Temporal Integration

- Extend domain structure to support temporal actions, methods, and facts
- Implement temporal constraint updates during method execution
- Ensure STN consistency checking works with bridge-based planning

## Implementation Plan

### Phase 1 Tasks

- [ ] **Update Domain Type Structure**
  - Modify type definitions to enforce `named_method` tuples
  - Update struct field specifications

- [ ] **Refactor Method Addition Functions**
  - Update `add_task_method/3` to require method name
  - Update `add_unigoal_method/3` to require method name
  - Update `add_multigoal_method/2` to require method name
  - Create `add_task_methods/2` accepting list of `{name, function}` pairs

- [ ] **Update Method Retrieval Functions**
  - Modify `get_task_methods/2` to return `{name, function}` pairs
  - Modify `get_unigoal_methods/2` to return `{name, function}` pairs
  - Add helper functions to extract names or functions separately

- [ ] **Fix Planner Integration**
  - Update planner to iterate over `{name, function}` pairs
  - Use method names for blacklisting operations
  - Use method names for logging and error reporting
  - Apply functions correctly while preserving names

- [ ] **Update All Tests**
  - Fix method addition calls to include names
  - Update test expectations for new method structure
  - Add tests for proper name-function pairing

### Phase 2 Tasks (STN Bridge)

- [ ] **Research and Design STN Bridge Pattern**
  - Define bridge action types and their temporal properties
  - Design integration with existing solution tree architecture
  - Plan constraint propagation through bridge points

- [ ] **Implement Bridge Actions**
  - Method selection bridges
  - Goal decomposition bridges  
  - Blacklist check bridges
  - State validation bridges

- [ ] **Integrate Bridge Architecture**
  - Update planner to use bridge actions for non-temporal operations
  - Ensure temporal consistency through bridge transitions
  - Implement reentrant planning with bridge support

### Phase 3 Tasks (Full Temporal Integration)

- [ ] **Extend Domain for Temporal Support**
  - Add temporal action definitions
  - Add temporal method definitions
  - Add temporal fact management

- [ ] **Implement Temporal Constraint Updates**
  - Real-time constraint propagation during execution
  - Bridge-based temporal validation
  - Solution tree updates with temporal information

## Success Criteria

### Phase 1 Completion

- All tests pass without String.Chars protocol errors
- Method blacklisting works correctly with method names
- Logging shows readable method names instead of function references
- Dialyzer warnings related to method handling are resolved

### Phase 2 Completion  

- STN bridge architecture is documented and functional
- Non-temporal operations use bridge actions correctly
- Temporal constraint propagation works through bridges
- Reentrant planning supports bridge-based updates

### Phase 3 Completion

- Full temporal planning with actions, methods, and facts
- Real-time constraint updates during execution
- Complete STN-HTN integration with bridge architecture

## Consequences

### Benefits

- **Aligned with GTPyhop**: Proper method name handling matching Python implementation
- **Better Debugging**: Method names available for logging and error reporting
- **Correct Blacklisting**: Method names can be properly blacklisted and tracked
- **Temporal Integration**: STN bridge architecture enables proper temporal planning
- **Protocol Compliance**: No more String.Chars errors from function interpolation

### Risks

- **Breaking Changes**: All existing method definitions need updating
- **Migration Effort**: Extensive refactoring across planner and domain modules
- **Temporal Complexity**: STN bridge architecture adds significant complexity
- **Performance Impact**: Additional method name tracking may affect performance

### Mitigation

- **Incremental Implementation**: Phase-based approach reduces risk
- **Comprehensive Testing**: Update all tests to verify correct behavior
- **Documentation**: Clear documentation of new method patterns
- **Backward Compatibility**: Provide migration guides for existing code

## Related ADRs

- **R25W019FE5E**: Evolving AriaEngine Planner Blueprint
- **R25W0210AA3**: Timeline-based Temporal Planner Implementation  
- **R25W0365EF2**: Complete Temporal Planning Solver
- **apps/aria_timeline/decisions/R25W040602B**: STN Timeline Segmentation (Superseded)

## Segment Closure Note

**June 21, 2025:** This ADR is being deferred as part of the temporal planning segment closure. The current HybridCoordinatorV2 implementation provides stable temporal planning functionality with all tests passing (382 tests, 0 failures). While this refactoring would improve method naming and STN bridge integration, it represents enhancement work that can be pursued in future development phases when the core functionality requires these improvements.

**Current Status:** Deferred to future development phases. Core temporal planning functionality is stable and operational.

## Next Steps (Future Implementation)

1. Begin Phase 1 implementation with Domain module refactoring
2. Update method addition functions to require names
3. Fix planner integration to use method names correctly
4. Update all tests to use new method structure
5. Plan STN bridge architecture design for Phase 2
