# ADR-005: Implement Fixpoint Fallback for STN Constraint Solving

<!-- @adr_serial R25W0055FF3 -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The `aria_minizinc` app currently has a fallback mechanism to use the Fixpoint solver when MiniZinc is unavailable, but the actual implementation is just a mock that generates placeholder data rather than using the Fixpoint library to solve constraint problems:

```elixir
# Fallback to pure Elixir constraint solving with Fixpoint
defp solve_with_fixpoint(problem_data, options) do
  Logger.debug("Using Fixpoint constraint solver fallback")

  # Generate a mock solution for now - in real implementation,
  # this would use Fixpoint to solve the constraint problem
  solution = generate_fixpoint_solution(problem_data, options)

  {:ok, solution}
end
```

### Current Limitations

1. **Mock Fixpoint Implementation**: The current Fixpoint fallback doesn't actually solve constraint problems; it just generates mock data.
2. **No STN-Specific Fixpoint Solver**: There's no implementation for solving STN problems with Fixpoint.
3. **Inconsistent Validation**: The validation process can't properly compare MiniZinc and Fixpoint solutions because the Fixpoint implementation is a mock.
4. **No Reliability**: System fails when MiniZinc is unavailable instead of gracefully falling back.

### Requirements

1. **Real Fixpoint Implementation**: Implement a proper Fixpoint solver for STN constraint problems.
2. **Seamless Fallback**: Ensure the fallback mechanism works transparently when MiniZinc is unavailable.
3. **Consistent Results**: The Fixpoint implementation should produce results compatible with the MiniZinc implementation.
4. **STN Focus**: Focus specifically on STN problems, following the domain separation principle from ADR-003.

## Decision

Implement a proper Fixpoint fallback for STN constraint solving using the Floyd-Warshall algorithm for STN consistency checking and solution finding.

### Architectural Principles

1. **Consistent Interface**: The Fixpoint implementation should have the same interface as the MiniZinc implementation.
2. **STN Focus**: Focus on implementing the Fixpoint solver specifically for STN problems.
3. **Mathematical Correctness**: Use proper STN algorithms (Floyd-Warshall) for consistency and solution finding.
4. **Validation Support**: Ensure the implementation supports validation by making results comparable between MiniZinc and Fixpoint.

### Implementation Strategy

1. **Fixpoint STN Solver**:
   - Implement a dedicated Fixpoint solver for STN problems
   - Use the Floyd-Warshall algorithm for STN consistency checking
   - Use the same data structures and interfaces as the MiniZinc implementation

2. **Fallback Mechanism**:
   - Update the fallback mechanism to use the real Fixpoint implementation
   - Ensure seamless transition between MiniZinc and Fixpoint
   - Maintain consistent result formats

3. **Validation Updates**:
   - Update the validation process to compare MiniZinc and Fixpoint solutions
   - Ensure validation works with the real Fixpoint implementation

## Implementation Plan

### Phase 1: Implement Fixpoint STN Solver ✅ PLANNED

1. **Create Fixpoint STN Module**:

   ```elixir
   defmodule AriaMiniZinc.Fixpoint.STNSolver do
     @moduledoc """
     Pure Elixir implementation of a Simple Temporal Network (STN) solver using Floyd-Warshall.
     
     This module provides a fallback when MiniZinc is unavailable, implementing
     the same functionality for STN problems using pure Elixir algorithms.
     """
     
     @doc """
     Solve an STN problem using Floyd-Warshall algorithm.
     
     ## Parameters
     - `time_points` - List of time point names
     - `distance_matrix` - Matrix of distance constraints between time points
     - `horizon` - Maximum time value
     - `options` - Solver options
     
     ## Returns
     - `{:ok, solution}` - Successfully solved problem
     - `{:error, reason}` - Failed to solve problem
     """
     def solve(time_points, distance_matrix, horizon, options \\ %{}) do
       # Implementation of Floyd-Warshall STN solver
     end
   end
   ```

2. **Implement Floyd-Warshall Algorithm**:

   ```elixir
   defp solve_stn(time_points, distance_matrix, horizon) do
     # Initialize distance matrix with constraints
     distances = initialize_distances(time_points, distance_matrix)
     
     # Apply Floyd-Warshall algorithm to find shortest paths
     distances = floyd_warshall(distances, length(time_points))
     
     # Check for negative cycles (inconsistency)
     case check_consistency(distances) do
       :consistent ->
         # Find solution with minimum makespan
         find_minimum_makespan_solution(distances, time_points, horizon)
       {:inconsistent, cycle} ->
         {:error, "STN is inconsistent, negative cycle detected: #{inspect(cycle)}"}
     end
   end
   
   defp floyd_warshall(distances, n) do
     # Floyd-Warshall algorithm implementation
     # For k = 1 to n:
     #   For i = 1 to n:
     #     For j = 1 to n:
     #       distances[i][j] = min(distances[i][j], distances[i][k] + distances[k][j])
   end
   
   defp check_consistency(distances) do
     # Check for negative cycles by examining diagonal elements
     # If distances[i][i] < 0 for any i, then there's a negative cycle
   end
   
   defp find_minimum_makespan_solution(distances, time_points, horizon) do
     # Find solution with minimum makespan using earliest start times
     # Start with time point 0 at time 0, then compute other time points
   end
   ```

3. **Add Result Conversion**:

   ```elixir
   defp convert_to_standard_solution(time_point_assignments, time_points, makespan) do
     # Convert internal solution to standard format compatible with MiniZinc results
     %{
       time_points: time_point_assignments,
       makespan: makespan,
       solver: :fixpoint,
       solve_time_ms: 0  # Fixpoint solving is typically very fast
     }
   end
   ```

### Phase 2: Update Fallback Mechanism ✅ PLANNED

1. **Update Solver Module**:

   ```elixir
   defp solve_with_fixpoint(problem_data, options) do
     Logger.debug("Using Fixpoint constraint solver fallback")
     
     case problem_data do
       %{time_points: time_points, distance_matrix: distance_matrix, horizon: horizon} ->
         # STN problem - use Floyd-Warshall solver
         AriaMiniZinc.Fixpoint.STNSolver.solve(time_points, distance_matrix, horizon, options)
       
       _ ->
         # Other problem types - return error for now
         {:error, "Fixpoint fallback only supports STN problems"}
     end
   end
   ```

2. **Update Problem Generator Integration**:

   ```elixir
   def generate_problem(domain, state, goals, options \\ %{}) do
     case Map.get(options, :problem_type) do
       :stn ->
         # Generate STN problem with Fixpoint-compatible format
         # Ensure data format works with both MiniZinc and Fixpoint
         generate_stn_problem(domain, state, goals, options)
       
       # Other problem types...
     end
   end
   ```

### Phase 3: Validation Integration ✅ PLANNED

1. **Update ValidationSolver**:

   ```elixir
   def validate_solver_consistency(params, state) do
     # Solve with MiniZinc
     minizinc_result = solve_stn_temporal(params, Map.put(state, :solver, :minizinc))
     
     # Solve with Fixpoint
     fixpoint_result = solve_stn_temporal(params, Map.put(state, :solver, :fixpoint))
     
     # Compare results
     compare_solutions(minizinc_result, fixpoint_result)
   end
   
   defp compare_solutions(minizinc_result, fixpoint_result) do
     # Compare solutions for consistency
     # Allow for small numerical differences due to different algorithms
     case {minizinc_result, fixpoint_result} do
       {{:ok, minizinc_sol}, {:ok, fixpoint_sol}} ->
         makespan_diff = abs(minizinc_sol.makespan - fixpoint_sol.makespan)
         if makespan_diff <= 1 do  # Allow 1 time unit difference
           {:ok, :consistent}
         else
           {:error, "Solver results differ significantly: MiniZinc=#{minizinc_sol.makespan}, Fixpoint=#{fixpoint_sol.makespan}"}
         end
       
       {{:error, _}, {:error, _}} ->
         {:ok, :both_failed}  # Both solvers agree problem is unsolvable
       
       _ ->
         {:error, "Solvers disagree on problem solvability"}
     end
   end
   ```

### Phase 4: Comprehensive Testing ✅ PLANNED

#### Fixpoint STN Tests (`test/aria_minizinc/fixpoint_stn_test.exs`)

- [ ] **Floyd-Warshall Algorithm Tests**

  ```elixir
  test "Floyd-Warshall correctly computes shortest paths"
  test "Floyd-Warshall detects negative cycles"
  test "Floyd-Warshall handles empty distance matrix"
  test "Floyd-Warshall produces correct all-pairs shortest paths"
  ```

- [ ] **STN Solving Tests**

  ```elixir
  test "solves simple STN problem correctly"
  test "detects inconsistent STN problems"
  test "finds minimum makespan solution"
  test "handles edge cases (single time point, zero durations)"
  ```

#### Fallback Integration Tests (`test/aria_minizinc/fallback_integration_test.exs`)

- [ ] **Fallback Mechanism Tests**

  ```elixir
  test "falls back to Fixpoint when MiniZinc unavailable"
  test "uses MiniZinc when available"
  test "produces consistent results between solvers"
  test "handles solver failures gracefully"
  ```

#### Validation Tests (`test/aria_minizinc/solver_validation_test.exs`)

- [ ] **Cross-Solver Validation Tests**

  ```elixir
  test "MiniZinc and Fixpoint produce consistent results for simple STN"
  test "MiniZinc and Fixpoint produce consistent results for complex STN"
  test "validation handles solver disagreements"
  test "validation allows for small numerical differences"
  ```

## Implementation Strategy

### Step 1: Floyd-Warshall Implementation (IMMEDIATE)

1. Implement Floyd-Warshall algorithm for STN consistency checking
2. Add negative cycle detection
3. Create minimum makespan solution finding

### Step 2: Fallback Integration (HIGH PRIORITY)

1. Update fallback mechanism to use real Fixpoint solver
2. Ensure data format compatibility between MiniZinc and Fixpoint
3. Add proper error handling and logging

### Step 3: Validation Updates (CRITICAL PATH)

1. Update validation process to compare real solver results
2. Add tolerance for numerical differences
3. Ensure validation works with both solvers

### Step 4: Comprehensive Testing (QUALITY ASSURANCE)

1. Create comprehensive test suite for Floyd-Warshall algorithm
2. Add integration tests for fallback mechanism
3. Implement cross-solver validation tests

## Success Criteria

**Functionality:**

- [ ] Fixpoint STN solver correctly implements the Floyd-Warshall algorithm
- [ ] Fixpoint solver produces valid solutions for all STN problems
- [ ] Fallback mechanism seamlessly switches between MiniZinc and Fixpoint
- [ ] System remains functional when MiniZinc is unavailable

**Consistency:**

- [ ] Fixpoint and MiniZinc solutions are comparable (within tolerance)
- [ ] Validation process correctly identifies inconsistencies
- [ ] Solution format is consistent between solvers
- [ ] Both solvers agree on problem solvability

**Performance:**

- [ ] Fixpoint solver performs adequately for small to medium STN problems
- [ ] Performance degradation compared to MiniZinc is acceptable
- [ ] Memory usage is reasonable
- [ ] Fallback mechanism adds minimal overhead

## Consequences

**Positive:**

- **Reliability**: System works even when MiniZinc is unavailable
- **Consistency**: Solutions are consistent between solvers
- **Mathematical Correctness**: Floyd-Warshall algorithm is proven correct for STN problems
- **Validation**: Proper validation between solvers ensures correctness

**Negative:**

- **Performance**: Fixpoint implementation may be slower than MiniZinc for large problems
- **Complexity**: Additional code to maintain
- **Limited Scope**: Fixpoint implementation only supports STN problems initially

**Risks:**

- **Algorithm Correctness**: Ensuring the Floyd-Warshall implementation correctly solves all STN problems
- **Performance Issues**: Fixpoint may be too slow for large problems (O(n³) complexity)
- **Inconsistent Results**: Differences between MiniZinc and Fixpoint solutions due to different algorithms

## Related ADRs

**Parent ADRs:**

- **ADR-007**: Implement True STN Mathematical Foundation (provides STN foundation)
- **ADR-003**: Separate Goal Solving and STN Problem Domains (supports domain focus)

**Related Project ADRs:**

- **ADR-128**: STN Solver MiniZinc Fallback Implementation
- **ADR-078**: Timeline Module PC-2 STN Implementation
- **ADR-153**: STN Fixed Point Constraint Prohibition

## Notes

This ADR focuses specifically on implementing a proper Fixpoint fallback for STN constraint solving. By using the Floyd-Warshall algorithm, we ensure mathematical correctness and compatibility with standard STN theory.

The Floyd-Warshall algorithm has O(n³) time complexity, where n is the number of time points. This is acceptable for small to medium-sized problems but may be a concern for very large STNs. However, for typical use cases, this should provide adequate performance while ensuring system reliability when MiniZinc is unavailable.

The implementation focuses on STN problems specifically, following the domain separation principle established in ADR-003. Future work could extend the Fixpoint fallback to other problem domains as needed.

## Current Status - June 24, 2025

### Implementation Requirements

**🔄 Dependencies:**

- Requires ADR-007 (True STN Mathematical Foundation) to be implemented first
- STN data structures and distance matrix format must be established
- Template selection logic from ADR-002 must be in place

**📋 Next Actions:**

1. Wait for ADR-007 implementation to establish STN foundation
2. Implement Floyd-Warshall algorithm using established STN data structures
3. Update fallback mechanism to use real Fixpoint solver
4. Add comprehensive testing for cross-solver validation
5. Integrate with validation pipeline for solver consistency checking

**🎯 Immediate Goal:**
Implement a mathematically correct Fixpoint fallback that uses the Floyd-Warshall algorithm to solve STN problems when MiniZinc is unavailable, ensuring system reliability and consistent results.
