# ADR-098: STN Timeline Encapsulation

**Status:** Active  
**Date:** June 18, 2025  
**Priority:** High  

## Context

Currently, the Simple Temporal Network (STN) functionality is exposed as a separate public API (`Timeline.STN`) that external modules access directly. This creates tight coupling and violates encapsulation principles. External modules should only interact with the Timeline API, treating STN as an internal implementation detail.

## Current Architecture Issues

**External STN Dependencies Found:**
- `lib/aria_engine/temporal_planner/stn_action.ex` - Uses STN.new, add_constraint, consistent?, time_points, parallel_join, union, intersection
- `lib/aria_engine/temporal_planner/stn_method.ex` - Uses STN.new, apply_pc2, parallel_join, union, intersection, chain
- `lib/aria_engine/temporal_planner/stn_planner.ex` - Uses STN.new, add_constraint, intersection, consistent?, apply_pc2, parallel_join, chain
- `lib/aria_engine/timeline_graph.ex` - Uses STN.new, add_interval
- `lib/aria_engine/timeline/lod_adapter.ex` - Uses STN.intersection, union
- 5 test files directly test STN functionality

**Problems:**
1. **Tight Coupling**: External modules depend on STN internal structure
2. **API Fragmentation**: Two public APIs (Timeline and STN) for temporal operations
3. **Implementation Exposure**: STN implementation details are public
4. **Maintenance Burden**: Changes to STN affect multiple external modules

## Decision

Fully encapsulate STN within Timeline by:
1. Expanding Timeline's public API to cover all externally-used STN functionality
2. Moving STN modules to private internal namespace
3. Migrating all external STN usage to Timeline API
4. Making STN completely internal to Timeline

## Implementation Plan

### Phase 1: Timeline API Expansion ✅
- [x] Audit external STN usage patterns
- [x] Add missing Timeline wrapper methods for all external STN functions
- [x] Ensure Timeline API covers: new, add_constraint, consistent?, time_points, parallel_join, union, intersection, chain, apply_pc2, solve
- [x] Add migration compatibility functions (get_stn, from_stn)

### Phase 2: STN Module Restructuring ✅
- [x] Move `Timeline.STN.*` modules to `Timeline.Internal.*`
- [x] Update all internal module references
- [x] Add `@moduledoc false` to all internal modules
- [x] Update Timeline to use internal STN modules

### Phase 3: External Reference Migration
- [ ] Update `temporal_planner/stn_action.ex` to use Timeline API
- [ ] Update `temporal_planner/stn_method.ex` to use Timeline API  
- [ ] Update `temporal_planner/stn_planner.ex` to use Timeline API
- [ ] Update `timeline_graph.ex` to use Timeline API
- [ ] Update `timeline/lod_adapter.ex` to use Timeline API

### Phase 4: Test Migration
- [ ] Migrate STN-specific tests to test through Timeline interface
- [ ] Update test imports and aliases
- [ ] Ensure all STN functionality remains tested

### Phase 5: Documentation and Cleanup
- [ ] Update Timeline module documentation
- [ ] Remove public STN references from documentation
- [ ] Add migration guide for developers

## Success Criteria

- [ ] No external modules import or use `Timeline.STN` directly
- [ ] All STN functionality accessible through Timeline public API
- [ ] STN modules are private implementation details
- [ ] All tests pass with new encapsulated structure
- [ ] Timeline API provides clean, high-level temporal operations interface

## Consequences

**Benefits:**
- **Clean Architecture**: Single public API for temporal operations
- **Implementation Flexibility**: STN can be replaced without affecting external code
- **Reduced Coupling**: External modules depend only on Timeline's stable API
- **Better Abstraction**: Users work with Timeline concepts, not low-level STN details

**Risks:**
- **API Surface Growth**: Timeline's public API will expand significantly
- **Performance Impact**: Additional wrapper layer might affect performance
- **Breaking Changes**: External code requires updates to use Timeline API
- **Migration Effort**: Substantial refactoring across multiple modules

## Related ADRs

- **ADR-078**: Timeline Module PC-2 STN Implementation
- **ADR-079**: Timeline Module Implementation Progress
- **ADR-083**: STN Timeline Segmentation (superseded)
- **ADR-091**: Hybrid Planner Dependency Encapsulation
