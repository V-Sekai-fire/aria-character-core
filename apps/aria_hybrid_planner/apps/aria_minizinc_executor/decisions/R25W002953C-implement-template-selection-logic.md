# ADR-002: Implement Template Selection Logic

<!-- @adr_serial R25W002953C -->

**Status:** Active (Paused)  
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The `aria_minizinc` app currently has multiple MiniZinc templates but lacks proper template selection logic:

### Current Template Situation

- **`goal_solving.mzn.eex`**: Used for general constraint satisfaction problems
- **`stn_temporal.mzn.eex`**: Used by `aria_temporal_planner` for STN problems
- **`@simple_temporal_network_template`**: Module attribute defined but needs proper integration

### Template Structure Analysis

**Goal Solving Template:**

- Handles general constraint satisfaction problems
- Uses structured variables (time_vars, location_vars, boolean_vars)
- Supports generic constraints and optimization objectives
- Template variables: `@variables`, `@constraints`, `@objective`, `@num_entities`

**STN Temporal Template:**

- Specialized for Simple Temporal Network problems (time points + distance constraints)
- Uses time point modeling with temporal distance constraints
- Optimizes for temporal consistency and makespan minimization
- Template variables: `@num_activities` (time points), `@durations`, `@constraints` (from/to/min/max format)

### Problem

1. **Unused Template Reference**: `@simple_temporal_network_template` generates compiler warning
2. **Missing Template Selection**: No logic to choose appropriate template based on problem type
3. **No Explicit Problem Type**: Template selection happens implicitly rather than explicitly

## Decision

Implement explicit template selection logic with clear problem type specification and no automatic defaults.

### Template Selection Strategy

**Explicit Selection Criteria (No Defaults):**

1. **STN Problems**: `options[:problem_type] == :stn` → Use `stn_temporal.mzn.eex`
2. **Goal-Solving Problems**: `options[:problem_type] == :goal_solving` → Use `goal_solving.mzn.eex`
3. **Multigoal Problems**: `options[:problem_type] == :multigoal` → Use `multigoal_optimization.mzn.eex` (future)
4. **Missing Problem Type**: Return error requiring explicit problem type specification

**External Integration API:**

- Explicit template selection: `%{problem_type: :stn}` or `%{problem_type: :goal_solving}`
- Clear documentation for problem type characteristics
- Consistent error handling across all template types
- No fallback between template types - explicit choice required

## Implementation Plan

### Phase 1: Template Selection Infrastructure ✅ PLANNED

- [ ] **Add template selection function** (`select_template/3`)
  - Analyze problem characteristics (goals, constraints, options)
  - Return appropriate template name based on selection criteria
  - Log template selection decisions for debugging

- [ ] **Create problem type detection logic** (`validate_problem_type/1`)
  - Check for explicit problem type in options
  - Return error for missing or invalid problem types
  - Simple, deterministic logic based on explicit specification

- [ ] **Update `build_minizinc_model/4`** to use template selection
  - Call template selection logic before data transformation
  - Branch to appropriate data transformation based on selected template
  - Maintain backward compatibility with existing functionality

### Phase 2: Template Registry System ✅ PLANNED

- [ ] **Create template registry** (`@available_templates`)
  - Map problem types to template files
  - Include template metadata (variables, constraints, objectives)
  - Support dynamic template discovery

- [ ] **Add template validation** (`validate_template/2`)
  - Verify template file exists
  - Check template variable requirements
  - Validate template syntax

- [ ] **Template loading optimization**
  - Cache compiled templates
  - Lazy loading for unused templates
  - Template compilation error handling

### Phase 3: API Integration ✅ PLANNED

- [ ] **Update public API** to require explicit problem type
  - Modify `generate_problem/4` to enforce problem type specification
  - Add clear error messages for missing problem type
  - Update documentation with problem type examples

- [ ] **Add convenience functions** for each problem type
  - `solve_goal_problem/4` - automatically sets `:goal_solving` type
  - `solve_stn_problem/4` - automatically sets `:stn` type
  - `solve_multigoal_problem/4` - automatically sets `:multigoal` type (future)

- [ ] **Template selection logging**
  - Log template selection decisions
  - Include problem type and template file in metadata
  - Debug information for template selection process

### Phase 4: Comprehensive Testing ✅ PLANNED

#### Template Selection Tests (`test/aria_minizinc/template_selection_test.exs`)

- [ ] **Template Selection Logic Tests**

  ```elixir
  test "selects goal_solving template for explicit goal_solving problem type"
  test "selects stn_temporal template for explicit stn problem type"
  test "returns error for missing problem type"
  test "returns error for invalid problem type"
  test "logs template selection decisions"
  ```

- [ ] **Template Registry Tests**

  ```elixir
  test "template registry contains all available templates"
  test "template validation succeeds for valid templates"
  test "template validation fails for missing templates"
  test "template loading handles compilation errors"
  ```

#### Integration Tests (`test/aria_minizinc/template_integration_test.exs`)

- [ ] **End-to-End Template Selection**

  ```elixir
  test "generates complete problem using goal_solving template"
  test "generates complete problem using stn_temporal template"
  test "template selection works with solver pipeline"
  test "convenience functions set correct problem types"
  ```

## Implementation Strategy

### Step 1: Template Selection Logic (IMMEDIATE)

1. Add `select_template/3` function with explicit selection criteria
2. Update `build_minizinc_model/4` to use template selection
3. Add problem type validation logic

### Step 2: Template Registry (HIGH PRIORITY)

1. Create template registry with metadata
2. Implement template validation and loading
3. Add template caching and optimization

### Step 3: API Integration (CRITICAL PATH)

1. Update public API to require explicit problem type
2. Add convenience functions for each problem type
3. Update documentation and examples

### Step 4: Testing (QUALITY ASSURANCE)

1. Create comprehensive template selection test suite
2. Add integration tests for template selection pipeline
3. Verify backward compatibility with existing functionality

## Success Criteria

**Template Selection:**

- [ ] `@simple_temporal_network_template` is actively used (no compiler warning)
- [ ] Template selection logic correctly identifies problem types
- [ ] All templates generate valid MiniZinc syntax
- [ ] Template selection is configurable via explicit options

**API Quality:**

- [ ] Explicit problem type specification required
- [ ] Clear error messages for missing or invalid problem types
- [ ] Convenience functions work correctly
- [ ] Template selection is logged and debuggable

**Testing Coverage:**

- [ ] Template selection logic has comprehensive test coverage (>90%)
- [ ] Integration tests cover end-to-end template selection
- [ ] All existing tests continue to pass (backward compatibility)
- [ ] Template registry and validation are thoroughly tested

## Consequences

**Positive:**

- **Template Utilization**: All templates actively used, eliminating compiler warnings
- **Explicit Selection**: Clear, intentional template selection based on explicit problem type
- **Extensibility**: Template registry supports future template additions
- **Debugging**: Template selection decisions are logged and traceable

**Negative:**

- **Breaking Changes**: Existing code must specify explicit problem type
- **API Complexity**: More options and configuration for template selection
- **Maintenance Overhead**: Template registry requires maintenance

**Risks:**

- **Backward Compatibility**: Risk of breaking existing functionality during API changes
- **Template Discovery**: Template registry may become complex with many templates
- **Performance Impact**: Template selection logic may add overhead

## Related ADRs

**Parent ADR:**

- **ADR-001**: Extract MiniZinc Functionality into Dedicated App (provides foundation)

**Successor ADRs:**

- **ADR-007**: Implement True STN Mathematical Foundation (STN-specific implementation)

**Related Project ADRs:**

- **ADR-003**: Separate Goal Solving and STN Problem Domains (supports template separation)
- **ADR-004**: Implement Multigoal Optimization Strategy (future template type)

## Notes

This ADR focuses specifically on the template selection infrastructure, providing a clean foundation for choosing appropriate templates based on explicit problem type specification. By requiring explicit problem type specification, we eliminate ambiguity and ensure intentional template selection.

The template registry system provides a foundation for future template additions while maintaining clear separation between template selection logic and domain-specific implementation details. The comprehensive testing approach ensures template selection works correctly and maintains backward compatibility.

Success depends on careful implementation of the template selection logic and thorough testing to ensure all templates work correctly with the new selection mechanism.

## Current Status - June 24, 2025

### Implementation Progress

**✅ Partial Implementation Discovered:**

- Template selection logic already implemented in ProblemGenerator
- Template integration working with both goal_solving and stn_temporal templates
- Tests passing with current template selection approach
- Compiler warning resolved (template is being used)

**🔄 Refinement Required:**

- Phase 1: Enhance template selection with explicit problem type validation ✅ HIGH PRIORITY
- Phase 2: Implement template registry system for better organization ✅ MEDIUM PRIORITY  
- Phase 3: Update API to require explicit problem type specification ✅ HIGH PRIORITY
- Phase 4: Add comprehensive testing for template selection logic ✅ QUALITY ASSURANCE

**📋 Next Actions:**

1. Add explicit problem type validation to existing template selection
2. Enhance error messages for missing or invalid problem types
3. Create template registry for better template management
4. Update API documentation to emphasize explicit problem type requirement
5. Add comprehensive tests for template selection edge cases

**🎯 Immediate Goal:**
Enhance the existing template selection implementation with explicit problem type validation and comprehensive error handling, ensuring clear and intentional template selection across all use cases.
