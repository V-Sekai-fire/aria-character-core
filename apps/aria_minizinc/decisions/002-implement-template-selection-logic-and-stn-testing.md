# ADR-002: Implement Template Selection Logic and STN Testing

**Status:** Active  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The `aria_minizinc` app currently has two MiniZinc templates but lacks proper template selection logic:

### Current Template Situation
- **`goal_solving.mzn.eex`**: Used for general constraint satisfaction problems
- **`stn_temporal.mzn.eex`**: Used by `aria_temporal_planner` for true STN problems
- **`@simple_temporal_network_template`**: Module attribute defined but never referenced in `aria_minizinc`

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
- Currently used by `Timeline.Internal.STN.MiniZincSolver` in `aria_temporal_planner`

### Problem

1. **Unused Template Reference**: `@simple_temporal_network_template` generates compiler warning in `aria_minizinc`
2. **Missing Template Selection**: No logic to choose appropriate template based on problem type
3. **Incomplete STN Support**: `aria_minizinc` cannot generate STN problems despite having access to STN template
4. **Limited Problem Coverage**: Only goal-solving problems supported, missing STN temporal constraint problems

## Decision

Implement explicit template selection logic with a mathematically sound Simple Temporal Network (STN) implementation alongside the existing goal-solving template.

### Template Selection Strategy

**Explicit Selection Criteria (No Defaults):**
1. **STN Problems**: `options[:problem_type] == :stn` → Use `stn_temporal.mzn.eex`
2. **Goal-Solving Problems**: `options[:problem_type] == :goal_solving` → Use `goal_solving.mzn.eex`
3. **Missing Problem Type**: Return error requiring explicit problem type specification

**True STN Implementation:**
- **Time Point Variables**: Activities represented as time points, not start/end intervals
- **Distance Constraint Matrix**: All temporal relationships expressed as distance constraints between time points
- **STN Consistency**: Proper STN constraint satisfaction using `time_point[j] - time_point[i] ≤ distance[i,j]` format
- **No Legacy Scheduling Concepts**: Remove temporal_ordering and other legacy flags from previous scheduling implementations

**Data Transformation Requirements:**
- **STN Format**: Transform activities into time point pairs with distance constraints for durations and precedence
- **Goal-Solving Format**: Use existing structured variables (time_vars, location_vars, boolean_vars)
- Generate template-specific constraint formats and objective functions
- Validate data completeness for each template type

**External Integration API:**
- Explicit template selection: `%{problem_type: :stn}` or `%{problem_type: :goal_solving}`
- Clear documentation for STN vs goal-solving problem characteristics
- Consistent error handling across both template types
- No fallback between template types - explicit choice required

## Implementation Plan

### Phase 1: Template Selection Infrastructure ✅ PLANNED
- [ ] **Add template selection function** (`select_template/3`)
  - Analyze problem characteristics (goals, constraints, options)
  - Return appropriate template name based on selection criteria
  - Log template selection decisions for debugging

- [ ] **Create STN detection logic** (`is_stn_problem?/3`)
  - Check for explicit `:stn` problem type in options
  - Return boolean for template selection
  - Simple, deterministic logic based on problem type

- [ ] **Update `build_minizinc_model/4`** to use template selection
  - Call template selection logic before data transformation
  - Branch to appropriate data transformation based on selected template
  - Maintain backward compatibility with existing functionality

### Phase 2: True STN Data Transformation ✅ PLANNED
- [ ] **Add True STN type definitions**
  ```elixir
  @type stn_time_point :: non_neg_integer()  # Time point index
  
  @type stn_distance_constraint :: %{
    from_point: non_neg_integer(),
    to_point: non_neg_integer(),
    distance: integer()  # Maximum distance: to_point - from_point ≤ distance
  }
  
  @type stn_problem_data :: %{
    num_time_points: non_neg_integer(),
    time_point_names: [String.t()],  # Human-readable names for time points
    distance_matrix: [[integer()]],  # Full distance constraint matrix
    horizon: non_neg_integer()       # Maximum time value
  }
  ```

- [ ] **Create STN time point mapping** (`extract_stn_time_points/2`)
  - Convert activities to time point pairs (start_point, end_point)
  - Generate time point indices and name mappings
  - Create time point relationships for temporal reasoning

- [ ] **Implement STN distance matrix generation** (`generate_stn_distance_matrix/3`)
  - Create full distance constraint matrix between all time points
  - Add duration constraints: `end_point - start_point ≤ duration` and `start_point - end_point ≤ -duration`
  - Add precedence constraints: `start_B - end_A ≤ 0` for sequential activities
  - Remove legacy min_distance/max_distance concepts

- [ ] **Add STN consistency objective** (`generate_stn_objective/2`)
  - Focus on temporal consistency satisfaction
  - Optional makespan minimization using latest time point
  - Remove legacy scheduling optimization concepts

### Phase 3: True STN Template Integration ✅ PLANNED
- [ ] **Create True STN template** (`stn_temporal.mzn.eex`)
  - Replace current hybrid template with pure STN implementation
  - Use time point variables: `array[1..num_time_points] of var 0..horizon: time_points`
  - Use distance constraint matrix: `array[1..num_time_points, 1..num_time_points] of int: distance_matrix`
  - Add STN consistency constraint: `constraint forall(i,j in 1..num_time_points)(time_points[j] - time_points[i] <= distance_matrix[i,j])`

- [ ] **Remove legacy STN elements**
  - Remove start_times/end_times arrays (use time_points instead)
  - Remove durations array (encode as distance constraints)
  - Remove temporal_ordering logic and min/max distance concepts
  - Remove makespan optimization (focus on consistency)

- [ ] **Update STN data transformation pipeline** (`transform_to_stn_format/4`)
  - Convert activities to time point pairs with distance matrix
  - Generate proper STN template variables (num_time_points, distance_matrix, horizon)
  - Remove legacy constraint generation logic

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
  test "converts goals to STN time points"
  test "generates STN distance constraints from temporal relationships"
  test "transforms structured variables to time point format"
  test "handles malformed STN data gracefully"
  ```

#### STN Integration Tests (`test/aria_minizinc/stn_integration_test.exs`)
- [ ] **End-to-End STN Problem Generation**
  ```elixir
  test "generates complete STN problem from temporal goals"
  test "solves simple temporal network with time point constraints"
  test "optimizes temporal consistency for STN problem"
  test "handles complex STN with multiple distance constraints"
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
  test "benchmark STN vs goal-solving generation time"
  test "measure memory usage for both template types"
  ```

- [ ] **Performance Benchmarking Requirements**
  - Measure template selection time (target: <1ms)
  - Compare STN vs goal-solving data transformation time
  - Track memory usage for both template types
  - Generate performance reports for optimization decisions

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
- **Explicit Selection**: Clear, intentional template selection based on explicit problem type
- **Performance Optimization**: STN-specific optimizations for temporal constraint problems
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

## Current Status - June 24, 2025

### Implementation Progress

**✅ Partial Implementation Discovered:**
- Template selection logic already implemented in ProblemGenerator
- STN template integration partially working with hybrid approach
- Tests passing but using legacy temporal_ordering concepts
- Compiler warning resolved (template is being used)

**⚠️ Architecture Issue Identified:**
- Current STN implementation is hybrid (start/end times + distance constraints)
- Uses legacy temporal_ordering flags from removed scheduling system
- Not mathematically sound STN (mixes interval and time point approaches)
- Tests expect legacy constraint formats (min/max distance values)

**🔄 Refactoring Required:**
- Phase 1: Remove legacy temporal_ordering logic ✅ IMMEDIATE
- Phase 2: Implement true STN with time points and distance matrix ✅ HIGH PRIORITY  
- Phase 3: Update STN template to pure time point approach ✅ CRITICAL PATH
- Phase 4: Refactor tests to match true STN expectations ✅ QUALITY ASSURANCE

**📋 Next Actions:**
1. Remove temporal_ordering references from ProblemGenerator
2. Simplify STN constraint generation (remove min/max distance complexity)
3. Redesign STN template for pure time point variables
4. Update tests to expect true STN constraint formats
5. Implement distance matrix approach for STN problems

**🎯 Immediate Goal:**
Clean up legacy scheduling concepts and implement mathematically sound Simple Temporal Network support that aligns with STN theory and supports Allen's Interval Algebra through time point constraints.
