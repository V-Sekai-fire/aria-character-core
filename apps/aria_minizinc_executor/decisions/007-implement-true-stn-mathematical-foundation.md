# ADR-007: Implement True STN Mathematical Foundation

<!-- @adr_serial R25W0079465 -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The current STN (Simple Temporal Network) implementation in `aria_minizinc` is architecturally unsound and mixes different temporal modeling approaches:

### Current STN Implementation Issues

1. **Hybrid Approach**: Mixes interval-based scheduling (start/end times) with time point constraints
2. **Legacy Temporal Ordering**: Uses `temporal_ordering` flags from removed scheduling system
3. **Non-Standard Distance Constraints**: Uses min/max distance values instead of proper STN distance matrix
4. **Mathematical Inconsistency**: Not aligned with STN theory and Allen's Interval Algebra

### STN Theory Requirements

A mathematically sound Simple Temporal Network requires:

1. **Time Point Variables**: Activities represented as time points, not start/end intervals
2. **Distance Constraint Matrix**: All temporal relationships expressed as distance constraints between time points
3. **STN Consistency**: Proper STN constraint satisfaction using `time_point[j] - time_point[i] ≤ distance[i,j]` format
4. **Floyd-Warshall Algorithm**: Standard algorithm for STN consistency checking and solution finding

### Current Template Problems

The `stn_temporal.mzn.eex` template currently:

- Uses start_times/end_times arrays (interval approach)
- Includes duration arrays (legacy scheduling concept)
- Uses temporal_ordering logic (removed from other parts of system)
- Generates min/max distance constraints (non-standard STN format)

## Decision

Implement a mathematically sound Simple Temporal Network foundation that aligns with STN theory and supports Allen's Interval Algebra through proper time point constraints.

### STN Mathematical Foundation

**True STN Implementation:**

- **Time Point Variables**: Activities represented as time point pairs, not start/end intervals
- **Distance Constraint Matrix**: All temporal relationships expressed as distance constraints between time points
- **STN Consistency**: Proper STN constraint satisfaction using standard distance constraint format
- **No Legacy Scheduling Concepts**: Remove temporal_ordering and other legacy flags

**Data Transformation Requirements:**

- **STN Format**: Transform activities into time point pairs with distance constraints for durations and precedence
- Generate template-specific constraint formats and objective functions
- Validate data completeness for STN template requirements
- Remove legacy constraint generation logic

## Implementation Plan

### Phase 1: True STN Type Definitions ✅ PLANNED

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

### Phase 2: STN Distance Matrix Generation ✅ PLANNED

- [ ] **Implement STN distance matrix generation** (`generate_stn_distance_matrix/3`)
  - Create full distance constraint matrix between all time points
  - Add duration constraints: `end_point - start_point ≤ duration` and `start_point - end_point ≤ -duration`
  - Add precedence constraints: `start_B - end_A ≤ 0` for sequential activities
  - Remove legacy min_distance/max_distance concepts

- [ ] **Add STN consistency objective** (`generate_stn_objective/2`)
  - Focus on temporal consistency satisfaction
  - Optional makespan minimization using latest time point
  - Remove legacy scheduling optimization concepts

### Phase 3: True STN Template Implementation ✅ PLANNED

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

### Phase 4: STN Algorithm Implementation ✅ PLANNED

- [ ] **Implement Floyd-Warshall Algorithm** for STN consistency

  ```elixir
  @spec check_stn_consistency(distance_matrix :: [[integer()]]) ::
          {:consistent, [[integer()]]} | {:inconsistent, [non_neg_integer()]}
  def check_stn_consistency(distance_matrix) do
    # Floyd-Warshall algorithm implementation
    # Returns updated distance matrix or negative cycle
  end
  ```

- [ ] **Add STN solution extraction** (`extract_stn_solution/2`)
  - Find minimum makespan solution from consistent STN
  - Extract time point assignments
  - Convert back to activity start/end times for compatibility

- [ ] **STN validation functions**
  - Validate distance matrix properties
  - Check for negative cycles
  - Verify time point constraints

### Phase 5: Comprehensive STN Testing ✅ PLANNED

#### STN Mathematical Tests (`test/aria_minizinc/stn_mathematical_test.exs`)

- [ ] **STN Theory Compliance Tests**

  ```elixir
  test "converts activities to proper time point pairs"
  test "generates correct distance constraints for durations"
  test "generates correct precedence constraints"
  test "distance matrix satisfies STN properties"
  test "Floyd-Warshall detects inconsistent STNs"
  test "Floyd-Warshall finds shortest paths in consistent STNs"
  ```

- [ ] **STN Data Transformation Tests**

  ```elixir
  test "transforms goals to STN time points correctly"
  test "generates STN distance constraints from temporal relationships"
  test "handles complex precedence relationships"
  test "validates STN data completeness"
  ```

#### STN Template Tests (`test/aria_minizinc/stn_template_test.exs`)

- [ ] **Template Generation Tests**

  ```elixir
  test "generates valid MiniZinc STN model"
  test "STN template uses time point variables"
  test "STN template includes distance constraint matrix"
  test "STN template enforces consistency constraints"
  test "STN template optimizes makespan correctly"
  ```

#### STN Integration Tests (`test/aria_minizinc/stn_integration_test.exs`)

- [ ] **End-to-End STN Tests**

  ```elixir
  test "solves simple STN problem correctly"
  test "detects inconsistent STN problems"
  test "handles complex temporal relationships"
  test "produces solutions compatible with Allen's Interval Algebra"
  ```

## Implementation Strategy

### Step 1: STN Type Definitions (IMMEDIATE)

1. Define proper STN types and data structures
2. Create time point mapping functions
3. Add STN validation functions

### Step 2: Distance Matrix Implementation (HIGH PRIORITY)

1. Implement distance matrix generation
2. Add Floyd-Warshall algorithm for consistency checking
3. Create STN solution extraction functions

### Step 3: Template Replacement (CRITICAL PATH)

1. Replace current hybrid template with pure STN implementation
2. Update data transformation pipeline
3. Remove all legacy scheduling concepts

### Step 4: Comprehensive Testing (QUALITY ASSURANCE)

1. Create mathematical correctness tests
2. Add template generation tests
3. Implement end-to-end integration tests

## Success Criteria

**Mathematical Correctness:**

- [ ] STN implementation follows standard STN theory
- [ ] Distance constraints properly represent temporal relationships
- [ ] Floyd-Warshall algorithm correctly detects consistency
- [ ] Solutions satisfy all STN constraints

**Template Quality:**

- [ ] STN template uses pure time point approach
- [ ] Template generates valid MiniZinc syntax
- [ ] All legacy scheduling concepts removed
- [ ] Template supports Allen's Interval Algebra relationships

**Integration Success:**

- [ ] STN problems solve correctly end-to-end
- [ ] Solutions are compatible with existing systems
- [ ] Performance is acceptable for typical STN sizes
- [ ] Error handling works for inconsistent STNs

## Consequences

**Positive:**

- **Mathematical Soundness**: STN implementation aligns with established theory
- **Consistency**: Proper STN consistency checking and solution finding
- **Extensibility**: Foundation for Allen's Interval Algebra support
- **Performance**: Efficient algorithms for STN solving

**Negative:**

- **Breaking Changes**: Existing STN code will need updates
- **Complexity**: More complex mathematical implementation
- **Learning Curve**: Developers need to understand STN theory

**Risks:**

- **Algorithm Correctness**: Floyd-Warshall implementation must be correct
- **Performance Issues**: Distance matrix approach may be slower for large problems
- **Compatibility**: Solutions must remain compatible with existing systems

## Related ADRs

**Parent ADRs:**

- **ADR-002**: Implement Template Selection Logic (provides template selection foundation)
- **ADR-003**: Separate Goal Solving and STN Problem Domains (supports domain separation)

**Related Project ADRs:**

- **ADR-005**: Implement Fixpoint Fallback for STN Constraint Solving (will use this foundation)
- **ADR-078**: Timeline Module PC-2 STN Implementation (integrates with this work)
- **ADR-153**: STN Fixed Point Constraint Prohibition (aligns with this approach)

## Notes

This ADR addresses the fundamental mathematical issues in the current STN implementation by establishing a proper foundation based on STN theory. The implementation focuses on mathematical correctness and alignment with established algorithms and data structures.

The key insight is that STN problems require a fundamentally different approach from general constraint satisfaction problems. By implementing proper time point variables and distance constraint matrices, we create a foundation that supports advanced temporal reasoning capabilities.

The Floyd-Warshall algorithm is the standard approach for STN consistency checking and has O(n³) time complexity, which is acceptable for typical STN sizes but may require optimization for very large problems.

Success depends on careful implementation of the mathematical algorithms and thorough testing to ensure correctness and compatibility with existing systems.

## Current Status - June 24, 2025

### Architecture Issue Identified

**⚠️ Current Implementation Problems:**

- STN template uses hybrid interval/time-point approach
- Legacy temporal_ordering flags from removed scheduling system
- Non-standard distance constraint format (min/max values)
- Tests expect legacy constraint formats

**🔄 Refactoring Required:**

- Phase 1: Remove legacy temporal_ordering logic ✅ IMMEDIATE
- Phase 2: Implement true STN with time points and distance matrix ✅ HIGH PRIORITY  
- Phase 3: Replace STN template with pure time point approach ✅ CRITICAL PATH
- Phase 4: Update tests to expect true STN constraint formats ✅ QUALITY ASSURANCE

**📋 Next Actions:**

1. Remove temporal_ordering references from ProblemGenerator
2. Simplify STN constraint generation (remove min/max distance complexity)
3. Redesign STN template for pure time point variables
4. Update tests to expect true STN constraint formats
5. Implement distance matrix approach for STN problems

**🎯 Immediate Goal:**
Clean up legacy scheduling concepts and implement mathematically sound Simple Temporal Network support that aligns with STN theory and supports Allen's Interval Algebra through time point constraints.
