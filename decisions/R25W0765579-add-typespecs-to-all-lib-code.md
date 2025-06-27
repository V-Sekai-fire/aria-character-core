# R25W0765579: Add Typespecs to All Lib Code

<!-- @adr_serial R25W0765579 -->

**Status:** Active (Paused) (June 22, 2025)
**Date:** June 21, 2025  
**Priority:** HIGH

## Context

The codebase currently lacks comprehensive typespec coverage across all lib modules. Adding typespecs will improve:

- **Code documentation:** Clear function signatures and return types
- **Developer experience:** Better IDE support and autocomplete
- **Static analysis:** Enhanced Dialyzer warnings and error detection
- **Maintainability:** Explicit contracts between modules

## Decision

Systematically add `@spec` annotations to all public and private functions across all lib modules, following Elixir typespec best practices.

## Implementation Plan

### Phase 1: Core Modules (HIGH PRIORITY)

**Files**: Core application modules

- [x] `lib/aria_character_core.ex`
- [x] `lib/aria_engine.ex`
- [x] `lib/aria_auth.ex`

### Phase 2: Engine Core (HIGH PRIORITY)

**Files**: `lib/aria_engine/` core modules

- [x] `lib/aria_engine/core.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/state_v2.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/state.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain.ex` (added comprehensive typespecs for all delegated functions)
- [x] `lib/aria_engine/plan.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/planning.ex` (added typespecs for all delegated functions)
- [x] `lib/aria_engine/scheduler.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/timeline.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/timeline_graph.ex` (added typespecs for all delegated functions)

### Phase 3: Engine API Modules (HIGH PRIORITY)

**Files**: API and interface modules

- [x] `lib/aria_engine/domain_api.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/goal_api.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain_behaviour.ex` (behaviour module with proper callbacks)
- [x] `lib/aria_engine/planner_adapter.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/validation.ex` (already had comprehensive typespecs)

### Phase 4: Engine Utilities (MEDIUM PRIORITY)

**Files**: Utility and helper modules

- [x] `lib/aria_engine/actions.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/convenience.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/info.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/multigoal.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/train_scheduling_converter.ex` (file does not exist)
- [x] `lib/aria_engine/utils.ex` (already had comprehensive typespecs)

**Note**: `batch_processor.ex` and `convergence.ex` were removed (see ADR-140)

### Phase 5: Domain Modules (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/domain/` modules

- [x] `lib/aria_engine/domain/actions.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain/behaviour_impl.ex` (file does not exist)
- [x] `lib/aria_engine/domain/core.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain/durative_action.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain/methods.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/domain/utils.ex` (already had comprehensive typespecs)

### Phase 6: Hybrid Planner (MEDIUM PRIORITY) ✅

**Files**: `lib/aria_engine/hybrid_planner/` modules

- [x] `lib/aria_engine/hybrid_planner/data_structures.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/strategies.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/strategy_config.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/strategy_coordinator.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/strategy_factory.ex` (already had comprehensive typespecs)
- [x] `lib/aria_engine/hybrid_planner/strategy_registry.ex` (already had comprehensive typespecs)

### Phase 7: Hybrid Planner V2 (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/` modules

- [ ] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/constructor.ex`
- [ ] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/execution_operations.ex`
- [ ] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/planning_operations.ex`
- [ ] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/replanning_operations.ex`
- [ ] `lib/aria_engine/hybrid_planner/hybrid_coordinator_v2/strategy_management.ex`

### Phase 8: Strategy Implementations (MEDIUM PRIORITY)

**Files**: Strategy implementation modules

- [ ] `lib/aria_engine/hybrid_planner/strategies/default/domain_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/htn_planning_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/lazy_execution_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/logger_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/statev2_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/default/stn_temporal_strategy.ex`
- [ ] `lib/aria_engine/hybrid_planner/strategies/mock/mock_planning_strategy.ex`

### Phase 9: Timeline Modules (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/timeline/` modules

- [ ] `lib/aria_engine/timeline/agent_entity.ex`
- [ ] `lib/aria_engine/timeline/allen_relations.ex`
- [ ] `lib/aria_engine/timeline/interval.ex`
- [ ] `lib/aria_engine/timeline/time_converter.ex`

### Phase 10: Timeline Agent Entity (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/timeline/agent_entity/` modules

- [ ] `lib/aria_engine/timeline/agent_entity/agent_management.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/capability_management.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/entity_management.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/ownership_management.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/property_management.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/state_transitions.ex`
- [ ] `lib/aria_engine/timeline/agent_entity/validation.ex`

### Phase 11: Timeline Internal (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/timeline/internal/` modules

- [ ] `lib/aria_engine/timeline/internal/stn.ex`
- [ ] `lib/aria_engine/timeline/internal/stn/core.ex`
- [ ] `lib/aria_engine/timeline/internal/stn/minizinc_solver.ex`
- [ ] `lib/aria_engine/timeline/internal/stn/operations.ex`
- [ ] `lib/aria_engine/timeline/internal/stn/units.ex`

### Phase 12: Timeline Graph (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/timeline_graph/` modules

- [ ] `lib/aria_engine/timeline_graph/entity_manager.ex`
- [ ] `lib/aria_engine/timeline_graph/environmental_processes.ex`
- [ ] `lib/aria_engine/timeline_graph/lod_manager.ex`
- [ ] `lib/aria_engine/timeline_graph/scheduler.ex`
- [ ] `lib/aria_engine/timeline_graph/time_converter.ex`

### Phase 13: Scheduler Modules (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/scheduler/` modules

- [ ] `lib/aria_engine/scheduler/core.ex`
- [ ] `lib/aria_engine/scheduler/domain_converter.ex`
- [ ] `lib/aria_engine/scheduler/entity_manager.ex`
- [ ] `lib/aria_engine/scheduler/plan_converter.ex`
- [ ] `lib/aria_engine/scheduler/resource_manager.ex`
- [ ] `lib/aria_engine/scheduler/state_manager.ex`

### Phase 14: Scheduler Domain Converter (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/scheduler/domain_converter/` modules

- [ ] `lib/aria_engine/scheduler/domain_converter/activity_actions.ex`
- [ ] `lib/aria_engine/scheduler/domain_converter/durative_actions.ex`
- [ ] `lib/aria_engine/scheduler/domain_converter/goal_methods.ex`
- [ ] `lib/aria_engine/scheduler/domain_converter/htn_methods.ex`
- [ ] `lib/aria_engine/scheduler/domain_converter/khr_primitives.ex`

### Phase 15: Temporal Planner (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/temporal_planner/` modules

- [ ] `lib/aria_engine/temporal_planner/stn_action.ex`
- [ ] `lib/aria_engine/temporal_planner/stn_method.ex`
- [ ] `lib/aria_engine/temporal_planner/stn_planner.ex`

### Phase 16: Plan Modules (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/plan/` modules

- [ ] `lib/aria_engine/plan/backtracking.ex`
- [ ] `lib/aria_engine/plan/blacklisting.ex`
- [ ] `lib/aria_engine/plan/core.ex`
- [ ] `lib/aria_engine/plan/execution.ex`
- [ ] `lib/aria_engine/plan/node_expansion.ex`
- [ ] `lib/aria_engine/plan/utils.ex`

### Phase 17: Planning Modules (MEDIUM PRIORITY)

**Files**: `lib/aria_engine/planning/` modules

- [ ] `lib/aria_engine/planning/core_interface.ex`
- [ ] `lib/aria_engine/planning/internal.ex`

### Phase 18: Membrane Modules (LOW PRIORITY)

**Files**: `lib/aria_engine/membrane/` modules

- [ ] `lib/aria_engine/membrane/format_transformer_filter.ex`
- [ ] `lib/aria_engine/membrane/minizinc_solver_filter.ex`
- [ ] `lib/aria_engine/membrane/minizinc_template_filter.ex`
- [ ] `lib/aria_engine/membrane/planner_filter.ex`
- [ ] `lib/aria_engine/membrane/testing_filter.ex`

### Phase 19: Membrane Format (LOW PRIORITY)

**Files**: `lib/aria_engine/membrane/format/` modules

- [ ] `lib/aria_engine/membrane/format/planning_params.ex`
- [ ] `lib/aria_engine/membrane/format/planning_request.ex`
- [ ] `lib/aria_engine/membrane/format/planning_response.ex`

### Phase 20: MiniZinc (LOW PRIORITY)

**Files**: `lib/aria_engine/minizinc/` modules

- [ ] `lib/aria_engine/minizinc/executor.ex`

### Phase 21: Auth Modules (LOW PRIORITY)

**Files**: `lib/aria_auth/` modules

- [ ] `lib/aria_auth/accounts.ex`
- [ ] `lib/aria_auth/application.ex`
- [ ] `lib/aria_auth/macaroons.ex`
- [ ] `lib/aria_auth/repo.ex`
- [ ] `lib/aria_auth/sessions.ex`
- [ ] `lib/aria_auth/accounts/user.ex`
- [ ] `lib/aria_auth/sessions/session.ex`

### Phase 22: Character Core (LOW PRIORITY)

**Files**: `lib/aria_character_core/` modules

- [ ] `lib/aria_character_core/application.ex`

### Phase 23: PNG Generator (LOW PRIORITY)

**Files**: `lib/aria_png_generator/` modules

- [ ] `lib/aria_png_generator/png_generator.ex`

### Phase 24: Security Modules (LOW PRIORITY)

**Files**: `lib/aria_security/` modules

- [ ] `lib/aria_security/application.ex`
- [ ] `lib/aria_security/openbao.ex`
- [ ] `lib/aria_security/secrets_interface.ex`
- [ ] `lib/aria_security/secrets_mock.ex`
- [ ] `lib/aria_security/secrets.ex`
- [ ] `lib/aria_security/softhsm.ex`

### Phase 25: Storage Modules (LOW PRIORITY)

**Files**: `lib/aria_storage/` modules

- [ ] `lib/aria_storage/application.ex`
- [ ] `lib/aria_storage/casync_decoder.ex`
- [ ] `lib/aria_storage/chunk_store.ex`
- [ ] `lib/aria_storage/chunk_uploader.ex`
- [ ] `lib/aria_storage/chunks.ex`
- [ ] `lib/aria_storage/file.ex`
- [ ] `lib/aria_storage/index.ex`
- [ ] `lib/aria_storage/sqlite_repo.ex`
- [ ] `lib/aria_storage/storage.ex`
- [ ] `lib/aria_storage/utils.ex`
- [ ] `lib/aria_storage/waffle_adapter.ex`
- [ ] `lib/aria_storage/waffle_chunk_store.ex`
- [ ] `lib/aria_storage/waffle_config.ex`
- [ ] `lib/aria_storage/waffle_example.ex`

### Phase 26: Storage Chunks (LOW PRIORITY)

**Files**: `lib/aria_storage/chunks/` modules

- [ ] `lib/aria_storage/chunks/assembly.ex`
- [ ] `lib/aria_storage/chunks/compression.ex`
- [ ] `lib/aria_storage/chunks/core.ex`
- [ ] `lib/aria_storage/chunks/rolling_hash.ex`

### Phase 27: Storage Parsers (LOW PRIORITY)

**Files**: `lib/aria_storage/parsers/` modules

- [ ] `lib/aria_storage/parsers/casync_format.ex`
- [ ] `lib/aria_storage/parsers/casync_format/archive_parser.ex`
- [ ] `lib/aria_storage/parsers/casync_format/chunk_parser.ex`
- [ ] `lib/aria_storage/parsers/casync_format/constants.ex`
- [ ] `lib/aria_storage/parsers/casync_format/encoder.ex`
- [ ] `lib/aria_storage/parsers/casync_format/index_parser.ex`
- [ ] `lib/aria_storage/parsers/casync_format/utilities.ex`

### Phase 28: Town Modules (LOW PRIORITY)

**Files**: `lib/aria_town/` modules

- [ ] `lib/aria_town/application.ex`
- [ ] `lib/aria_town/context_schema.ex`
- [ ] `lib/aria_town/iri_helpers.ex`
- [ ] `lib/aria_town/json_encoders.ex`
- [ ] `lib/aria_town/npc_manager.ex`
- [ ] `lib/aria_town/persistence_manager.ex`
- [ ] `lib/aria_town/time_manager.ex`

### Phase 29: Mix Tasks (LOW PRIORITY)

**Files**: `lib/mix/` modules

- [ ] `lib/mix/tasks/app.ex`
- [ ] `lib/mix/tasks/aria.ex`
- [ ] `lib/mix/tasks/aria.pipeline.ex`
- [ ] `lib/mix/tasks/aria.schedule.ex`
- [ ] `lib/mix/tasks/aria.validate.ex`
- [ ] `lib/mix/tasks/schedule/samples.ex`
- [ ] `lib/mix/tasks/schedule/samples/entity_capabilities.ex`
- [ ] `lib/mix/tasks/schedule/samples/helpers.ex`
- [ ] `lib/mix/tasks/schedule/samples/resource_constraints.ex`
- [ ] `lib/mix/tasks/schedule/samples/sequential.ex`

## Implementation Strategy

### Step 1: Analyze Current State

1. Survey existing typespec coverage across all modules
2. Identify patterns and common types used throughout codebase
3. Document any existing custom types that should be reused

### Step 2: Define Common Types

1. Create shared type definitions for commonly used data structures
2. Establish consistent naming conventions for types
3. Document type patterns for complex data structures

### Step 3: Systematic Implementation

1. Work through phases in priority order
2. Add typespecs to all public functions first, then private functions
3. Include comprehensive documentation for complex types
4. Test compilation and Dialyzer warnings after each phase

### Step 4: Validation

1. Run `mix dialyzer` after each phase to catch type errors
2. Verify all functions have appropriate typespecs
3. Ensure type consistency across module boundaries

## Current Focus: Phase 7 - Hybrid Planner V2

Phase 6 hybrid planner modules are complete. Moving to hybrid planner v2 modules.

### Progress Summary

- **Phase 1**: ✅ Completed - Core modules already had typespecs
- **Phase 2**: ✅ Completed - Engine core modules already had typespecs  
- **Phase 3**: ✅ Completed - API modules already had typespecs
- **Phase 4**: ✅ Completed - Utility modules (8/8 complete)
- **Phase 5**: ✅ Completed - Domain modules (6/6 complete)
- **Phase 6**: ✅ Completed - Hybrid planner modules (7/7 complete)
- **Phase 7+**: ⏳ Pending - Specialized modules

## Success Criteria

- [ ] All public functions have `@spec` annotations
- [ ] All private functions have `@spec` annotations  
- [ ] Custom types are defined with `@type` where appropriate
- [ ] Dialyzer runs without warnings related to missing typespecs
- [ ] Type documentation is clear and comprehensive
- [ ] Consistent type naming conventions across all modules

## Benefits

- **Improved documentation:** Function signatures serve as inline documentation
- **Better IDE support:** Enhanced autocomplete and error detection
- **Static analysis:** Dialyzer can catch more potential issues
- **Code quality:** Explicit contracts improve maintainability
- **Developer experience:** Clear expectations for function inputs and outputs

## Related ADRs

- **R25W02708D3**: Test cleanup and code maintenance
- **R25W034AB64**: Project status summary comprehensive review
