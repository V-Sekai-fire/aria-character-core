# R25W1652B8A: Aria Hybrid Planner Unification

<!-- @adr_serial R25W1652B8A -->

**Status:** Active  
**Date:** 2025-06-27  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Context

The `aria_hybrid_planner` app currently has a fragmented architecture with multiple overlapping APIs, inconsistent module organization, and conflicting interfaces. This creates confusion for developers and makes the codebase difficult to maintain.

### Current Problems

1. **Multiple Conflicting APIs**:
   - `AriaHybridPlanner.PlanCore` (delegates to `Plan.Core`)
   - `AriaHybridPlanner.PlanningCore` (delegates to `Planning.CoreInterface`)
   - `HybridPlanner.HybridCoordinatorV2` (monolithic implementation)
   - `Planning.CoreInterface` (stub implementations calling `AriaEngine.PlannerAdapter`)

2. **Inconsistent Module Naming**:
   - Mix of `AriaHybridPlanner.*`, `HybridPlanner.*`, `Plan.*`, and `Planning.*` namespaces
   - No clear hierarchy or organization principle

3. **Fragmented Functionality**:
   - Planning logic scattered across multiple modules
   - Temporal planning in separate `temporal_planner/` directory
   - Core planning functions duplicated with different interfaces

4. **Incomplete Integration**:
   - `Planning.CoreInterface` has stub implementations
   - `HybridCoordinatorV2` is monolithic but doesn't integrate with other modules
   - Multiple execution patterns (simple executor vs coordinator execution)

## Decision

Unify the `aria_hybrid_planner` app into a coherent, single-API architecture that follows the IPyHOP pattern and provides clear module boundaries.

## Implementation Plan

### Phase 1: Dependency Reversal ✅

**Priority:** HIGH

- [x] Update aria_engine_core/mix.exs to depend on aria_hybrid_planner ✅ (already done)
- [x] Remove aria_engine_core dependency from aria_hybrid_planner/mix.exs ✅ (already done)
- [x] Make aria_hybrid_planner self-contained by replacing all AriaEngine module references ✅
- [x] Ensure aria_hybrid_planner compiles independently ✅
- [x] Create local implementations of Domain.Core, Multigoal, State, and Plan.Utils ✅
- [x] Replace all AriaEngine.PlannerAdapter calls with stub implementations ✅

### Phase 2: Reorganize Module Structure

**Priority:** HIGH

- [ ] Restructure modules into logical hierarchy:

  ```
  lib/aria_hybrid_planner/
  ├── core.ex                    # Main unified API
  ├── planning/
  │   ├── htn_planner.ex        # HTN planning logic
  │   ├── temporal_planner.ex   # Temporal constraint handling
  │   └── executor.ex           # Unified execution
  ├── coordination/
  │   └── hybrid_coordinator.ex # Simplified coordinator
  └── support/
      ├── blacklisting.ex       # Planning blacklists
      ├── backtracking.ex       # Planning backtracking
      └── data_structures.ex    # Shared types
  ```

- [ ] Move existing modules to new structure
- [ ] Update all internal references
- [ ] Ensure clean module dependencies

### Phase 3: Consolidate Execution Patterns

**Priority:** HIGH

- [ ] Merge `Plan.SimpleExecutor` and coordinator execution
- [ ] Standardize execution interface following IPyHOP pattern
- [ ] Remove duplicate execution logic
- [ ] Align with R25W1547587 (IPyHOP pattern compliance)

### Phase 4: External API Migration ✅

**Priority:** HIGH

- [x] Create clean external API in `AriaEngine.Planner` ✅
- [x] Implement R25W1398085 specification with `run_lazy` and `plan` functions ✅
- [x] Update `AriaEngine.PlannerAdapter` to delegate to new API ✅
- [x] Verify all external references use correct API ✅
- [x] Test API accessibility and functionality ✅

### Phase 5: Integrate Temporal Planning

**Priority:** MEDIUM

- [ ] Move `temporal_planner/` modules into main structure
- [ ] Create unified temporal constraint API
- [ ] Integrate with `aria_minizinc_stn` dependency
- [ ] Ensure temporal planning follows unified patterns

### Phase 6: Clean Up Legacy Code

**Priority:** MEDIUM

- [ ] Remove deprecated modules and functions
- [ ] Update all external references
- [ ] Clean up test suite to match new structure
- [ ] Update documentation and README

### Phase 7: Validation and Testing

**Priority:** HIGH

- [ ] Verify all existing functionality works
- [ ] Add comprehensive test coverage for unified API
- [ ] Test backward compatibility
- [ ] Performance validation

## Success Criteria

### API Unification

- [ ] Single, clear API entry point (`AriaHybridPlanner.Core`)
- [ ] No conflicting or duplicate interfaces
- [ ] Consistent function signatures across all modules
- [ ] Clear documentation of unified API

### Module Organization

- [ ] Logical module hierarchy with clear responsibilities
- [ ] Consistent naming conventions throughout
- [ ] Clean dependency relationships
- [ ] No circular dependencies

### Functionality Preservation

- [ ] All existing planning capabilities maintained
- [ ] IPyHOP pattern compliance preserved
- [ ] Temporal planning integration working
- [ ] Execution patterns unified and functional

### Code Quality

- [ ] Clean compilation without warnings
- [ ] Comprehensive test coverage
- [ ] Clear documentation
- [ ] Maintainable code structure

## Consequences

### Positive

- **Simplified API**: Single entry point for all hybrid planning functionality
- **Better Organization**: Clear module hierarchy and responsibilities
- **Improved Maintainability**: Easier to understand and modify
- **Consistent Patterns**: Unified approach throughout the codebase
- **Better Integration**: Seamless temporal planning integration

### Negative

- **Breaking Changes**: Existing code using old APIs will need updates
- **Migration Effort**: Significant refactoring required
- **Temporary Complexity**: During transition, both old and new APIs may coexist

### Risks

- **Functionality Loss**: Risk of breaking existing features during refactoring
- **Integration Issues**: Potential problems with external dependencies
- **Performance Impact**: Possible performance changes during restructuring

## Related ADRs

- **R25W1547587**: Align Hybrid Planner Execution with IPyHOP Pattern (execution compliance)
- **R25W1398085**: Unified Durative Action Specification (action specification compliance)
- **R25W153B3FE**: Hybrid Coordinator V2 Monolithic Refactoring (coordinator context)

## Implementation Strategy

Following the "call site → leaf node testing pattern":

1. **Identify Call Sites**: Map all external usage of hybrid planner APIs
2. **Trace Dependencies**: Document current module interactions
3. **Test-First Approach**: Write tests for unified API before implementation
4. **Bottom-Up Migration**: Start with leaf modules and work upward
5. **Maintain Compatibility**: Provide migration path during transition

## Current Implementation Status

**Status:** Phase 1 Complete, Phase 2 In Progress  
**Last Updated:** 2025-06-27

### ✅ **Completed Work**

**Phase 1: Unified Core API**

- ✅ Created `AriaHybridPlanner.Core` as single API entry point
- ✅ Consolidated planning, execution, and replanning functions
- ✅ Maintained backward compatibility with existing interfaces
- ✅ Added comprehensive documentation and type specifications

### 🔧 **Current Work**

**Phase 2: Module Reorganization**

- 🔄 Restructuring module hierarchy
- 🔄 Moving existing modules to new locations
- 🔄 Updating internal references

### 📋 **Next Steps**

1. Complete module reorganization
2. Consolidate execution patterns
3. Integrate temporal planning
4. Clean up legacy code
5. Comprehensive testing and validation

## Benefits Achieved

- **Single API Surface**: Developers now have one clear entry point
- **Consistent Interface**: All functions follow the same patterns
- **Better Documentation**: Clear API documentation with examples
- **Type Safety**: Comprehensive type specifications
- **Backward Compatibility**: Existing code continues to work during transition
