# ADR-001: Extract MiniZinc Functionality into Dedicated App

**Status:** Active  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

MiniZinc constraint solving functionality is currently scattered across multiple apps in the umbrella project:

### Current Distribution
- **aria_engine_core**: Core MiniZinc executor, problem generator, and solver interface
- **aria_temporal_planner**: STN-specific MiniZinc solver integration
- **aria_membrane_pipeline**: Validation pipeline MiniZinc solver and template filters
- **aria_hybrid_planner**: Direct MiniZinc calls in temporal strategies

### Problems with Current Architecture
- **Code Duplication**: Multiple MiniZinc solver implementations with similar functionality
- **Inconsistent APIs**: Different interfaces for the same underlying MiniZinc operations
- **Scattered Dependencies**: MiniZinc-related dependencies spread across multiple apps
- **Testing Fragmentation**: MiniZinc tests distributed without comprehensive coverage
- **Maintenance Burden**: Updates to MiniZinc integration require changes across multiple apps

### MiniZinc Usage Patterns Identified
1. **STN (Simple Temporal Network) Solving**: Temporal constraint solving for timeline planning
2. **Multi-goal Optimization**: Planning optimization with multiple competing objectives  
3. **Validation Pipeline**: Comparing solver results for validation and testing
4. **Direct Template Execution**: Custom MiniZinc model execution with EEx templates

### Integer CP-SAT Problem Domain
All problems have been transformed into **integer CP-SAT (Constraint Programming - Satisfiability)** style solves, focusing on:
- **Integer finite domains** (no continuous variables)
- **Boolean and integer constraint satisfaction**
- **Optimization over integer variables**
- **SAT-based constraint solving**

## Decision

Extract all MiniZinc functionality into a dedicated `aria_minizinc` app that provides a unified, reusable interface for constraint solving across the entire project.

### Fallback Strategy for Integer CP-SAT Problems

Implement a **two-tier fallback system** to ensure reliable constraint solving even when MiniZinc is unavailable:

1. **Primary Solver**: MiniZinc (optimal performance for complex problems)
2. **Fallback Solver**: fixpoint (pure Elixir constraint programming solver)

**fixpoint Library Benefits:**
- **Pure Elixir** implementation (no external dependencies)
- **Integer finite domain variables** (perfect for CP-SAT problems)
- **Supports both CSP and COP** (constraint satisfaction + optimization)
- **Active development** (latest release June 2025)
- **Parallel and distributed solving** capabilities
- **Well-documented** with extensive examples (TSP, N-Queens, Knapsack)

**Fallback Implementation:**
- Automatic detection of MiniZinc availability
- Graceful degradation to fixpoint when MiniZinc unavailable
- Consistent API regardless of underlying solver
- Performance monitoring and solver selection optimization

## Implementation Plan

### Phase 1: App Structure Creation ✅ COMPLETED
- [x] Generate new umbrella app: `mix new apps/aria_minizinc --sup`
- [x] Create decisions directory: `apps/aria_minizinc/decisions/`
- [x] Create directory structure for organized functionality
- [x] Set up initial project files

### Phase 2: Extract Core MiniZinc Components ✅ COMPLETED
**From `apps/aria_engine_core/lib/minizinc/`:**
- [x] `executor.ex` → `apps/aria_minizinc/lib/aria_minizinc/executor.ex`
- [x] `problem_generator.ex` → `apps/aria_minizinc/lib/aria_minizinc/problem_generator.ex`
- [x] `solver.ex` → `apps/aria_minizinc/lib/aria_minizinc/solver.ex`

**From `apps/aria_temporal_planner/lib/timeline/internal/stn/`:**
- [x] `minizinc_solver.ex` → `apps/aria_minizinc/lib/aria_minizinc/stn_solver.ex`

**From `apps/aria_membrane_pipeline/lib/membrane/validation_pipeline/`:**
- [ ] `minizinc_solver.ex` → `apps/aria_minizinc/lib/aria_minizinc/validation_solver.ex`

### Phase 3: Extract Templates and Resources 🔄 IN PROGRESS
**Template files:**
- [x] Extract EEx templates from `priv/templates/minizinc/` across apps
- [x] Consolidate into `apps/aria_minizinc/priv/templates/`
- [ ] Update template paths in code

**Template Types to Support:**
- [x] STN Temporal templates (`stn_temporal.mzn.eex`)
- [ ] Multigoal Optimization templates (`multigoal_optimization.mzn.eex`)
- [ ] ~~Widget Assembly templates (`widget_assembly.mzn.eex`)~~ **TOMBSTONED** - No longer needed
- [ ] Validation templates (`validation.mzn.eex`)

### Phase 4: Update Dependencies and References
**Update mix.exs files:**
- [ ] Add `aria_minizinc` dependency to consuming apps
- [ ] Add `{:fixpoint, "~> 0.11.6"}` as fallback solver dependency
- [ ] Remove MiniZinc deps from `aria_engine_core`
- [ ] Update dependency versions and requirements

**Update module references:**
- [ ] `AriaEngine.MiniZinc.*` → `AriaMiniZinc.*`
- [ ] Update all import/alias statements
- [ ] Fix function calls across codebase

### Phase 5: Consolidate and Clean Up API
**Create unified API:**
- [ ] Main `AriaMiniZinc` module with clean public interface
- [ ] Consistent error handling across all solvers
- [ ] Unified configuration system
- [ ] Standardized template rendering

**Remove duplicated code:**
- [ ] Merge similar solver implementations
- [ ] Standardize output parsing
- [ ] Consolidate template rendering logic

### Phase 6: Comprehensive Test Suite (Single Responsibility Principle)

**Template Test Coverage** - Each template gets dedicated test files:

#### STN Temporal Template Tests (`test/templates/stn_temporal_test.exs`)
- [ ] **Primary Responsibility**: Template rendering with STN variables
- [ ] Test: `renders STN temporal template with valid constraints`
- [ ] Test: `handles empty constraint sets gracefully`
- [ ] Test: `validates time point variable generation`

#### Multigoal Optimization Template Tests (`test/templates/multigoal_optimization_test.exs`)
- [ ] **Primary Responsibility**: Template rendering with optimization objectives
- [ ] Test: `renders multigoal template with multiple objectives`
- [ ] Test: `handles single objective optimization`
- [ ] Test: `validates constraint generation for competing goals`

#### ~~Widget Assembly Template Tests~~ **TOMBSTONED** - No longer needed

#### Validation Template Tests (`test/templates/validation_test.exs`)
- [ ] **Primary Responsibility**: Template rendering for solver comparison
- [ ] Test: `renders validation template for hybrid comparison`
- [ ] Test: `handles solver timeout scenarios`
- [ ] Test: `validates solution format consistency`

**Core Module Tests** - Each module gets focused test coverage:

#### Executor Tests (`test/aria_minizinc/executor_test.exs`)
- [ ] **Primary Responsibility**: Porcelain-based MiniZinc execution
- [ ] Test: `executes MiniZinc with valid model`
- [ ] Test: `handles MiniZinc unavailable gracefully`
- [ ] Test: `respects timeout configuration`
- [ ] Test: `parses JSON output correctly`

#### Problem Generator Tests (`test/aria_minizinc/problem_generator_test.exs`)
- [ ] **Primary Responsibility**: CSP generation from planning data
- [ ] Test: `generates valid MiniZinc model from goals`
- [ ] Test: `handles empty goal sets`
- [ ] Test: `validates constraint syntax`

#### STN Solver Tests (`test/aria_minizinc/stn_solver_test.exs`)
- [ ] **Primary Responsibility**: STN-specific solving logic
- [ ] Test: `solves simple temporal networks`
- [ ] Test: `detects inconsistent constraints`
- [ ] Test: `handles complex temporal relationships`

#### Validation Solver Tests (`test/aria_minizinc/validation_solver_test.exs`)
- [ ] **Primary Responsibility**: Solver comparison and validation
- [ ] Test: `compares solver results accurately`
- [ ] Test: `handles solver disagreements`
- [ ] Test: `validates solution equivalence`

**Integration Tests** - End-to-end functionality:

#### Integration Tests (`test/integration/minizinc_integration_test.exs`)
- [ ] **Primary Responsibility**: Full workflow testing
- [ ] Test: `complete STN solving workflow`
- [ ] Test: `complete multigoal optimization workflow`
- [ ] Test: `complete validation workflow`

#### Fixpoint Fallback Tests (`test/integration/fixpoint_fallback_test.exs`)
- [ ] **Primary Responsibility**: Fallback solver integration testing
- [ ] Test: `falls back to fixpoint when MiniZinc unavailable`
- [ ] Test: `fixpoint solves STN temporal constraints`
- [ ] Test: `fixpoint handles multigoal optimization`
- [ ] Test: `consistent results between MiniZinc and fixpoint`
- [ ] Test: `performance comparison between solvers`

#### Template System Tests (`test/templates/template_system_test.exs`)
- [ ] **Primary Responsibility**: Template discovery and validation
- [ ] Test: `discovers all available templates`
- [ ] Test: `validates template syntax`
- [ ] Test: `handles missing template variables`

### Phase 7: Update Documentation
**Create comprehensive README:**
- [ ] Document all solver types (STN, multigoal, validation)
- [ ] Usage examples for each solver
- [ ] Template system documentation
- [ ] Configuration options
- [ ] Installation and setup instructions

### Phase 8: Update Related ADRs
**Update consuming app ADRs** to reference the new `aria_minizinc` dependency:
- [ ] Update temporal planner ADRs
- [ ] Update hybrid planner ADRs
- [ ] Update membrane pipeline ADRs
- [ ] Add cross-references to this extraction ADR

## Implementation Strategy

### Step 1: Extract Core Components (IMMEDIATE)
1. Copy MiniZinc modules from source apps to new app
2. Update module names and namespaces
3. Fix internal references and dependencies

### Step 2: Consolidate APIs (HIGH PRIORITY)
1. Create unified `AriaMiniZinc` main module
2. Standardize function signatures across solvers
3. Implement consistent error handling

### Step 3: Template System (HIGH PRIORITY)
1. Create template discovery system
2. Implement EEx template rendering
3. Add template validation

### Step 4: Update Dependencies (CRITICAL PATH)
1. Add `aria_minizinc` to consuming app dependencies
2. Update all module references
3. Test compilation across all apps

### Step 5: Comprehensive Testing (QUALITY ASSURANCE)
1. Implement all template tests with single responsibilities
2. Add core module tests with focused coverage
3. Create integration tests for end-to-end workflows

## Success Criteria

**Phase Completion:**
- [ ] All MiniZinc functionality extracted to dedicated app
- [ ] No code duplication across apps
- [ ] Unified API with consistent interface
- [ ] Comprehensive test coverage (100% template coverage)
- [ ] All consuming apps compile and function correctly

**Quality Metrics:**
- [ ] Each template has dedicated test file with single responsibility
- [ ] Each core module has focused test coverage
- [ ] Integration tests cover all major workflows
- [ ] Documentation covers all functionality
- [ ] No MiniZinc-related code remains in source apps

**Integration Success:**
- [ ] `aria_temporal_planner` uses new MiniZinc app
- [ ] `aria_hybrid_planner` uses new MiniZinc app
- [ ] `aria_membrane_pipeline` uses new MiniZinc app
- [ ] All existing functionality preserved
- [ ] Performance maintained or improved

## Consequences

**Positive:**
- **Single Source of Truth**: All MiniZinc functionality in one place
- **Reusability**: Can be used by any app needing constraint solving
- **Maintainability**: Easier to update MiniZinc integration
- **Testing**: Centralized, comprehensive test coverage
- **API Consistency**: Unified interface across all use cases
- **Dependency Management**: Clean, focused dependencies

**Negative:**
- **Initial Complexity**: Significant refactoring required
- **Breaking Changes**: Module references need updates across apps
- **Testing Overhead**: Comprehensive test suite requires significant effort
- **Migration Risk**: Potential for introducing bugs during extraction

**Risks:**
- **Functionality Loss**: Risk of missing edge cases during extraction
- **Performance Impact**: Additional indirection through new app
- **Dependency Cycles**: Risk of circular dependencies between apps
- **Template Compatibility**: Risk of breaking existing template usage

## Related ADRs

**Source ADRs (to be updated):**
- **ADR-126**: MiniZinc Multigoal Optimization with Fallback
- **ADR-128**: STN Solver MiniZinc Fallback Implementation
- **ADR-078**: Timeline Module PC-2 STN Implementation

**Integration Dependencies:**
- **Temporal Planner ADRs**: Will reference new MiniZinc app
- **Hybrid Planner ADRs**: Will reference new MiniZinc app
- **Membrane Pipeline ADRs**: Will reference new MiniZinc app

## Notes

This extraction addresses a critical architectural need for consolidating scattered MiniZinc functionality. The comprehensive test suite with single responsibility principle ensures quality while the unified API provides consistency across all use cases.

The template system is particularly important as it provides the foundation for all constraint solving operations. Each template must have dedicated test coverage to ensure reliability.

Success depends on careful extraction of existing functionality while maintaining backward compatibility and improving the overall architecture.
