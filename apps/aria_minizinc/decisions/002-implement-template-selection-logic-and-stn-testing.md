# ADR-002: Implement Template Selection Logic and STN Testing

**Status:** Active  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `aria_minizinc` app currently has two MiniZinc templates but only uses one:

### Current Template Situation
- **`goal_solving.mzn.eex`**: Currently used for all problem generation
- **`stn_temporal.mzn.eex`**: Exists but unused, causing compiler warning
- **`@simple_temporal_network_template`**: Module attribute defined but never referenced

### Template Structure Analysis

**Goal Solving Template:**
- Handles general constraint satisfaction problems
- Uses structured variables (time_vars, location_vars, boolean_vars)
- Supports generic constraints and optimization objectives
- Template variables: `@variables`, `@constraints`, `@objective`, `@num_entities`

**STN Temporal Template:**
- Specialized for Simple Temporal Network problems
- Uses activity-based modeling with durations and temporal constraints
- Optimizes for makespan minimization
- Template variables: `@num_activities`, `@durations`, `@constraints` (from/to/min/max format)

### Problem

1. **Unused Template Warning**: `@simple_temporal_network_template` generates compiler warning
2. **Missing Template Selection**: No logic to choose appropriate template based on problem type
3. **Incomplete STN Support**: STN template exists but no data transformation or testing
4. **Limited Problem Coverage**: Only goal-solving problems supported, missing STN-specific optimizations

## Decision

Implement comprehensive template selection logic that automatically chooses the appropriate MiniZinc template based on problem characteristics, with full STN support and testing coverage.

### Template Selection Strategy

**Selection Criteria:**
1. **Explicit Problem Type**: `options[:problem_type] == :stn` → Use STN template
2. **Temporal Constraint Detection**: Multiple activities with temporal constraints → Use STN template
3. **Activity-Based Problems**: Problems with durations and scheduling → Use STN template
4. **Default Fallback**: All other problems → Use goal_solving template

**Data Transformation Requirements:**
- Convert between goal-solving and STN data formats
- Transform structured variables to activity-based variables
- Generate STN-compatible constraints with from/to/min/max distances
- Create appropriate objective functions for each template type

## Implementation Plan

### Phase 1: Template Selection Infrastructure ✅ PLANNED
- [ ] **Add template selection function** (`select_template/3`)
  - Analyze problem characteristics (goals, constraints, options)
  - Return appropriate template name based on selection criteria
  - Log template selection decisions for debugging

- [ ] **Create STN detection logic** (`is_stn_problem?/3`)
  - Check for explicit `:stn` problem type in options
  - Detect temporal constraints with activity relationships
  - Identify duration-based scheduling problems

- [ ] **Update `build_minizinc_model/4`** to use template selection
  - Call template selection logic before data transformation
  - Branch to appropriate data transformation based on selected template
  - Maintain backward compatibility with existing functionality

### Phase 2: STN Data Transformation ✅ PLANNED
- [ ] **Add STN-specific type definitions**
  ```elixir
  @type stn_activity :: %{
    id: non_neg_integer(),
    name: String.t(),
    duration: non_neg_integer()
  }
  
  @type stn_constraint :: %{
    from_activity: non_neg_integer(),
    to_activity: non_neg_integer(),
    min_distance: integer(),
    max_distance: integer()
  }
  
  @type stn_problem_data :: %{
    num_activities: non_neg_integer(),
    activities: [stn_activity()],
    durations: [non_neg_integer()],
    constraints: [stn_constraint()]
  }
  ```

- [ ] **Create STN variable extraction** (`extract_stn_variables/2`)
  - Convert goals to activities with durations
  - Generate activity IDs and names
  - Extract duration information from goals or defaults

- [ ] **Implement STN constraint generation** (`generate_stn_constraints/3`)
  - Transform temporal constraints to from/to/min/max format
  - Generate precedence constraints between activities
  - Add duration constraints and resource constraints

- [ ] **Add STN objective generation** (`generate_stn_objective/2`)
  - Minimize makespan (default for STN problems)
  - Support alternative objectives (minimize cost, maximize efficiency)

### Phase 3: STN Template Integration ✅ PLANNED
- [ ] **Create STN data transformation pipeline** (`transform_to_stn_format/4`)
  - Convert structured goal-solving data to STN format
  - Generate STN-compatible template variables
  - Validate STN data structure completeness

- [ ] **Update template rendering logic**
  - Support both template formats in `render_template/2`
  - Handle different template variable structures
  - Maintain error handling for both template types

- [ ] **Add STN template validation**
  - Verify STN template variables are complete
  - Validate constraint format compatibility
  - Check activity and duration consistency

### Phase 4: Comprehensive STN Testing ✅ PLANNED

#### STN Unit Tests (`test/aria_minizinc/stn_template_test.exs`)
- [ ] **Template Selection Tests**
  ```elixir
  test "selects STN template for explicit STN problem type"
  test "selects STN template for temporal constraint problems"
  test "selects goal_solving template for general problems"
  test "handles template selection edge cases"
  ```

- [ ] **STN Data Transformation Tests**
  ```elixir
  test "converts goals to STN activities with durations"
  test "generates STN constraints from temporal relationships"
  test "transforms structured variables to activity format"
  test "handles malformed STN data gracefully"
  ```

#### STN Integration Tests (`test/aria_minizinc/stn_integration_test.exs`)
- [ ] **End-to-End STN Problem Generation**
  ```elixir
  test "generates complete STN problem from temporal goals"
  test "solves simple temporal network with 3 activities"
  test "optimizes makespan for scheduling problem"
  test "handles complex STN with multiple constraints"
  ```

- [ ] **Template Comparison Tests**
  ```elixir
  test "equivalent problems produce consistent results across templates"
  test "STN template produces valid MiniZinc syntax"
  test "goal_solving template maintains existing functionality"
  ```

#### STN Performance Tests (`test/aria_minizinc/stn_performance_test.exs`)
- [ ] **Template Selection Performance**
  ```elixir
  test "template selection completes within acceptable time"
  test "STN data transformation scales with problem size"
  test "template rendering performance comparison"
  ```

### Phase 5: Documentation and Integration ✅ PLANNED
- [ ] **Update module documentation**
  - Document template selection criteria and usage
  - Add examples for both template types
  - Explain STN vs goal-solving problem characteristics

- [ ] **Create usage examples**
  - STN problem generation examples
  - Template selection option examples
  - Performance comparison guidelines

- [ ] **Update existing tests**
  - Ensure existing tests continue to pass
  - Add template selection options to existing test cases
  - Verify backward compatibility

## Implementation Strategy

### Step 1: Template Selection Logic (IMMEDIATE)
1. Add `select_template/3` function with selection criteria
2. Update `build_minizinc_model/4` to use template selection
3. Add basic STN detection logic

### Step 2: STN Data Transformation (HIGH PRIORITY)
1. Create STN type definitions and data structures
2. Implement STN variable extraction and constraint generation
3. Add STN template variable transformation

### Step 3: STN Testing (CRITICAL PATH)
1. Create comprehensive STN test suite
2. Add integration tests for end-to-end STN functionality
3. Verify template selection logic with test coverage

### Step 4: Validation and Documentation (QUALITY ASSURANCE)
1. Validate both templates work correctly
2. Update documentation with template selection usage
3. Ensure backward compatibility with existing functionality

## Success Criteria

**Template Selection:**
- [ ] `@simple_temporal_network_template` is actively used (no compiler warning)
- [ ] Template selection logic correctly identifies STN vs goal-solving problems
- [ ] Both templates generate valid MiniZinc syntax
- [ ] Template selection is configurable via options

**STN Functionality:**
- [ ] STN problems can be generated from temporal goals
- [ ] STN template produces solvable MiniZinc models
- [ ] STN optimization (makespan minimization) works correctly
- [ ] STN data transformation handles edge cases gracefully

**Testing Coverage:**
- [ ] STN template has dedicated test coverage (>90%)
- [ ] Template selection logic is thoroughly tested
- [ ] Integration tests cover end-to-end STN functionality
- [ ] Performance tests validate template selection efficiency

**Quality Metrics:**
- [ ] All existing tests continue to pass (backward compatibility)
- [ ] No compiler warnings for unused template attributes
- [ ] Documentation covers both template types with examples
- [ ] Code coverage maintains or improves current levels

## Consequences

**Positive:**
- **Template Utilization**: Both templates actively used, eliminating compiler warnings
- **Problem Coverage**: Support for both general CSP and specialized STN problems
- **Automatic Selection**: Intelligent template selection based on problem characteristics
- **Performance Optimization**: STN-specific optimizations for temporal scheduling problems
- **Comprehensive Testing**: Full test coverage for both template types

**Negative:**
- **Increased Complexity**: More complex data transformation and template selection logic
- **Maintenance Overhead**: Two template types require separate maintenance
- **Testing Burden**: Comprehensive test coverage requires significant test development
- **API Surface**: Additional options and configuration for template selection

**Risks:**
- **Template Compatibility**: Risk of breaking existing functionality during template selection implementation
- **Data Transformation**: Complex transformation between goal-solving and STN formats
- **Performance Impact**: Template selection logic may add overhead to problem generation
- **Test Coverage**: Incomplete STN testing could lead to runtime failures

## Related ADRs

**Parent ADR:**
- **ADR-001**: Extract MiniZinc Functionality into Dedicated App (provides foundation for this work)

**Related Project ADRs:**
- **ADR-126**: MiniZinc Multigoal Optimization with Fallback (template selection supports multigoal)
- **ADR-128**: STN Solver MiniZinc Fallback Implementation (STN template supports this use case)
- **ADR-078**: Timeline Module PC-2 STN Implementation (STN template integrates with timeline work)

## Notes

This ADR addresses the immediate compiler warning while significantly expanding the capability of the `aria_minizinc` app to handle specialized STN problems. The template selection logic provides a foundation for future template additions (multigoal optimization, validation templates, etc.).

The comprehensive testing approach ensures both templates work correctly and maintains the high quality standards established in ADR-001. The automatic template selection reduces the burden on consuming applications while providing explicit control when needed.

Success depends on careful implementation of data transformation logic and thorough testing of both template types to ensure reliability and performance.

## Current Status - June 23, 2025

### Implementation Progress

**✅ Planning Complete:**
- Comprehensive analysis of template structure and requirements
- Detailed implementation plan with clear phases and success criteria
- Template selection criteria and STN data transformation strategy defined

**🔄 Ready for Implementation:**
- Phase 1: Template Selection Infrastructure (next immediate step)
- Phase 2: STN Data Transformation (high priority)
- Phase 3: STN Template Integration (critical path)
- Phase 4: Comprehensive STN Testing (quality assurance)

**📋 Next Actions:**
1. Implement `select_template/3` function with selection criteria
2. Add STN detection logic (`is_stn_problem?/3`)
3. Update `build_minizinc_model/4` to use template selection
4. Create STN type definitions and data structures
5. Begin STN test suite development

This ADR provides the roadmap for eliminating the unused template warning while significantly expanding MiniZinc problem-solving capabilities.
