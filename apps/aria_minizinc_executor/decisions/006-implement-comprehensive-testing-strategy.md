# ADR-006: Implement Comprehensive Testing Strategy for MiniZinc and Fixpoint Solvers

<!-- @adr_serial R25W0066624 -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** MEDIUM

## Context

The `aria_minizinc` app now has multiple problem domains (Goal Solving, STN) and multiple solver implementations (MiniZinc, Fixpoint). With the implementation of the Fixpoint fallback for STN constraint solving (ADR-005), it's crucial to ensure that both solver implementations produce correct and consistent results.

### Current Testing Approach

1. **Limited Test Coverage**: Current tests focus primarily on basic functionality
2. **Manual Validation**: Correctness is often validated manually
3. **No Systematic Testing**: No structured approach to test different problem types and edge cases
4. **Limited Cross-Solver Testing**: Insufficient testing of consistency between MiniZinc and Fixpoint

### Testing Requirements

1. **Correctness Verification**: Verify that both solvers produce correct results for known problems
2. **Consistency Checking**: Ensure MiniZinc and Fixpoint produce consistent results
3. **Edge Case Handling**: Test boundary conditions and special cases
4. **Performance Benchmarking**: Measure and compare solver performance
5. **Regression Prevention**: Detect regressions when modifying solver implementations

## Decision

Implement a comprehensive testing strategy for the MiniZinc and Fixpoint solvers, with a focus on STN problems.

### Testing Principles

1. **Known-Solution Testing**: Test against problems with known solutions
2. **Cross-Solver Validation**: Compare results between MiniZinc and Fixpoint
3. **Property-Based Testing**: Use property-based testing for systematic exploration
4. **Benchmark Suite**: Create a benchmark suite for performance testing
5. **Continuous Integration**: Integrate tests into CI pipeline

### Implementation Strategy

1. **Test Suite Structure**:
   - Unit tests for individual components
   - Integration tests for solver pipelines
   - Property-based tests for systematic exploration
   - Benchmark tests for performance measurement

2. **Known-Solution Test Cases**:
   - Simple STN problems with known solutions
   - Complex STN problems from literature
   - Edge cases and boundary conditions

3. **Cross-Solver Validation**:
   - Test harness for comparing MiniZinc and Fixpoint results
   - Tolerance settings for numerical differences
   - Consistency metrics and reporting

4. **Benchmark Suite**:
   - Performance measurement infrastructure
   - Scalability tests with increasing problem sizes
   - Comparative benchmarks between solvers

## Implementation Plan

### Phase 1: Unit and Integration Tests ✅ PLANNED

1. **STN Solver Unit Tests**:

   ```elixir
   describe "AriaMiniZinc.Fixpoint.STNSolver" do
     test "solves simple STN problem correctly" do
       time_points = ["t1", "t2", "t3"]
       distance_matrix = [
         [0, 10, 20],
         [5, 0, 10],
         [15, 5, 0]
       ]
       horizon = 100
       
       {:ok, solution} = AriaMiniZinc.Fixpoint.STNSolver.solve(time_points, distance_matrix, horizon)
       
       assert solution.makespan <= 20
       assert Enum.at(solution.start_times, 1) - Enum.at(solution.start_times, 0) <= 10
       assert Enum.at(solution.start_times, 2) - Enum.at(solution.start_times, 1) <= 10
       assert Enum.at(solution.start_times, 0) - Enum.at(solution.start_times, 1) <= -5
     end
     
     test "detects inconsistent STN" do
       time_points = ["t1", "t2", "t3"]
       distance_matrix = [
         [0, 5, 10],
         [0, 0, 5],
         [-15, -5, 0]
       ]
       horizon = 100
       
       result = AriaMiniZinc.Fixpoint.STNSolver.solve(time_points, distance_matrix, horizon)
       
       assert {:error, message} = result
       assert String.contains?(message, "inconsistent")
     end
     
     test "handles empty STN" do
       time_points = []
       distance_matrix = []
       horizon = 100
       
       result = AriaMiniZinc.Fixpoint.STNSolver.solve(time_points, distance_matrix, horizon)
       
       assert {:ok, solution} = result
       assert solution.makespan == 0
     end
   end
   ```

2. **Integration Tests**:

   ```elixir
   describe "AriaMiniZinc.Solver with STN problems" do
     test "solves STN problem with MiniZinc when available" do
       problem_data = build_test_stn_problem()
       options = %{solver: :minizinc}
       
       result = AriaMiniZinc.Solver.solve(problem_data, options)
       
       assert {:ok, solution} = result
       assert solution.metadata.solver == :minizinc
       assert is_integer(solution.objective_value)
     end
     
     test "falls back to Fixpoint when MiniZinc unavailable" do
       problem_data = build_test_stn_problem()
       options = %{solver: :minizinc}
       
       # Mock MiniZinc unavailability
       with_mock AriaMiniZinc.Executor, [check_availability: fn -> {:error, "not found"} end] do
         result = AriaMiniZinc.Solver.solve(problem_data, options)
         
         assert {:ok, solution} = result
         assert solution.metadata.solver == :fixpoint
         assert is_integer(solution.objective_value)
       end
     end
     
     test "explicitly uses Fixpoint solver" do
       problem_data = build_test_stn_problem()
       options = %{solver: :fixpoint}
       
       result = AriaMiniZinc.Solver.solve(problem_data, options)
       
       assert {:ok, solution} = result
       assert solution.metadata.solver == :fixpoint
       assert is_integer(solution.objective_value)
     end
   end
   ```

### Phase 2: Known-Solution Test Cases ✅ PLANNED

1. **Simple STN Test Cases**:

   ```elixir
   describe "STN solver with known solutions" do
     test "simple chain problem" do
       # A -> B -> C with durations [10, 20]
       time_points = ["A_start", "A_end", "B_start", "B_end", "C_start", "C_end"]
       distance_matrix = build_chain_distance_matrix([10, 20])
       horizon = 100
       
       {:ok, solution} = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert solution.minizinc.makespan == 30
       assert solution.fixpoint.makespan == 30
       assert Enum.at(solution.minizinc.start_times, 5) - Enum.at(solution.minizinc.start_times, 0) == 30
     end
     
     test "parallel activities problem" do
       # A and B in parallel, followed by C
       # A: duration 10, B: duration 15, C: duration 5
       time_points = ["A_start", "A_end", "B_start", "B_end", "C_start", "C_end"]
       distance_matrix = build_parallel_distance_matrix([10, 15, 5])
       horizon = 100
       
       {:ok, solution} = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert solution.minizinc.makespan == 20
       assert solution.fixpoint.makespan == 20
     end
     
     test "complex precedence problem" do
       # Complex precedence relationships from literature
       time_points = ["t1", "t2", "t3", "t4", "t5", "t6"]
       distance_matrix = build_complex_precedence_matrix()
       horizon = 100
       
       {:ok, solution} = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert solution.minizinc.makespan == solution.expected_makespan
       assert solution.fixpoint.makespan == solution.expected_makespan
     end
   end
   ```

2. **Edge Case Test Cases**:

   ```elixir
   describe "STN solver with edge cases" do
     test "zero-duration activities" do
       time_points = ["A_start", "A_end", "B_start", "B_end"]
       distance_matrix = build_zero_duration_matrix()
       horizon = 100
       
       {:ok, solution} = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert solution.minizinc.makespan == 0
       assert solution.fixpoint.makespan == 0
     end
     
     test "tight constraints" do
       time_points = ["A_start", "A_end", "B_start", "B_end"]
       distance_matrix = build_tight_constraints_matrix()
       horizon = 100
       
       {:ok, solution} = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert solution.minizinc.makespan == 10
       assert solution.fixpoint.makespan == 10
     end
     
     test "maximum horizon" do
       time_points = ["A_start", "A_end", "B_start", "B_end"]
       distance_matrix = build_standard_matrix()
       horizon = 10
       
       result = solve_with_both_solvers(time_points, distance_matrix, horizon)
       
       assert {:error, _} = result
     end
   end
   ```

### Phase 3: Property-Based Testing ✅ PLANNED

1. **Generator Functions**:

   ```elixir
   defp generate_stn_problem do
     gen all
       num_points <- integer(2..10),
       time_points <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), length: num_points),
       distance_matrix <- generate_distance_matrix(num_points),
       horizon <- integer(100..1000)
     do
       {time_points, distance_matrix, horizon}
     end
   end
   
   defp generate_distance_matrix(n) do
     gen all
       matrix <- list_of(
         list_of(
           integer(-50..100),
           length: n
         ),
         length: n
       )
     do
       # Ensure diagonal is 0
       matrix
       |> Enum.with_index()
       |> Enum.map(fn {row, i} ->
         row
         |> Enum.with_index()
         |> Enum.map(fn {val, j} ->
           if i == j, do: 0, else: val
         end)
       end)
     end
   end
   ```

2. **Property Tests**:

   ```elixir
   property "consistent solvers for consistent STNs" do
     check all
       {time_points, distance_matrix, horizon} <- generate_consistent_stn_problem()
     do
       result_minizinc = solve_with_minizinc(time_points, distance_matrix, horizon)
       result_fixpoint = solve_with_fixpoint(time_points, distance_matrix, horizon)
       
       assert {:ok, solution_minizinc} = result_minizinc
       assert {:ok, solution_fixpoint} = result_fixpoint
       assert_solutions_consistent(solution_minizinc, solution_fixpoint)
     end
   end
   
   property "both solvers detect inconsistent STNs" do
     check all
       {time_points, distance_matrix, _horizon} <- generate_inconsistent_stn_problem()
     do
       result_minizinc = solve_with_minizinc(time_points, distance_matrix, 1000)
       result_fixpoint = solve_with_fixpoint(time_points, distance_matrix, 1000)
       
       assert {:error, _} = result_minizinc
       assert {:error, _} = result_fixpoint
     end
   end
   
   property "solutions respect distance constraints" do
     check all
       {time_points, distance_matrix, horizon} <- generate_consistent_stn_problem()
     do
       {:ok, solution} = solve_with_fixpoint(time_points, distance_matrix, horizon)
       
       assert_constraints_satisfied(solution, distance_matrix)
     end
   end
   ```

### Phase 4: Benchmark Suite ✅ PLANNED

1. **Benchmark Infrastructure**:

   ```elixir
   defmodule AriaMiniZinc.Benchmarks do
     use Benchfella
     
     setup_all do
       # Setup code
       {:ok, %{}}
     end
     
     teardown_all(_) do
       # Teardown code
     end
     
     bench "MiniZinc small STN (10 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(10)
       solve_with_minizinc(time_points, distance_matrix, horizon)
     end
     
     bench "Fixpoint small STN (10 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(10)
       solve_with_fixpoint(time_points, distance_matrix, horizon)
     end
     
     bench "MiniZinc medium STN (50 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(50)
       solve_with_minizinc(time_points, distance_matrix, horizon)
     end
     
     bench "Fixpoint medium STN (50 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(50)
       solve_with_fixpoint(time_points, distance_matrix, horizon)
     end
     
     bench "MiniZinc large STN (100 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(100)
       solve_with_minizinc(time_points, distance_matrix, horizon)
     end
     
     bench "Fixpoint large STN (100 points)" do
       {time_points, distance_matrix, horizon} = generate_stn(100)
       solve_with_fixpoint(time_points, distance_matrix, horizon)
     end
     
     # Helper functions
     defp generate_stn(size) do
       # Generate STN of specified size
     end
   end
   ```

2. **Scalability Tests**:

   ```elixir
   describe "solver scalability" do
     @tag timeout: 60_000
     test "MiniZinc scales with problem size" do
       sizes = [10, 20, 50, 100, 200]
       
       results = Enum.map(sizes, fn size ->
         {time_points, distance_matrix, horizon} = generate_stn(size)
         
         {time, result} = :timer.tc(fn ->
           solve_with_minizinc(time_points, distance_matrix, horizon)
         end)
         
         %{size: size, time_ms: time / 1000, result: result}
       end)
       
       # Log results
       Enum.each(results, fn %{size: size, time_ms: time} ->
         Logger.info("MiniZinc size #{size}: #{time} ms")
       end)
       
       # Assert all problems were solved successfully
       Enum.each(results, fn %{result: result} ->
         assert {:ok, _} = result
       end)
     end
     
     @tag timeout: 60_000
     test "Fixpoint scales with problem size" do
       sizes = [10, 20, 50, 100]
       
       results = Enum.map(sizes, fn size ->
         {time_points, distance_matrix, horizon} = generate_stn(size)
         
         {time, result} = :timer.tc(fn ->
           solve_with_fixpoint(time_points, distance_matrix, horizon)
         end)
         
         %{size: size, time_ms: time / 1000, result: result}
       end)
       
       # Log results
       Enum.each(results, fn %{size: size, time_ms: time} ->
         Logger.info("Fixpoint size #{size}: #{time} ms")
       end)
       
       # Assert all problems were solved successfully
       Enum.each(results, fn %{result: result} ->
         assert {:ok, _} = result
       end)
     end
   end
   ```

## Success Criteria

**Test Coverage:**

- [ ] Unit tests for all solver components
- [ ] Integration tests for solver pipelines
- [ ] Known-solution tests for verification
- [ ] Edge case tests for boundary conditions
- [ ] Property-based tests for systematic exploration

**Solver Validation:**

- [ ] Cross-solver consistency verification
- [ ] Correctness verification against known solutions
- [ ] Performance benchmarking and comparison
- [ ] Scalability testing with increasing problem sizes

**CI Integration:**

- [ ] Tests integrated into CI pipeline
- [ ] Benchmark results tracked over time
- [ ] Regression detection for performance and correctness

## Consequences

**Positive:**

- **Quality Assurance**: Comprehensive testing ensures solver correctness
- **Confidence**: Higher confidence in solver implementations
- **Performance Insights**: Benchmarks provide insights into solver performance
- **Regression Prevention**: Early detection of regressions

**Negative:**

- **Development Overhead**: Significant effort required to implement and maintain tests
- **CI Resources**: Comprehensive testing requires more CI resources
- **Maintenance Burden**: Tests need to be updated as solvers evolve

**Risks:**

- **False Positives**: Tests may incorrectly flag issues
- **Performance Variability**: Benchmark results may vary based on environment
- **Test Complexity**: Complex tests may be difficult to maintain

## Related ADRs

**Parent ADRs:**

- **ADR-003**: Separate Goal Solving and STN Problem Domains
- **ADR-005**: Implement Fixpoint Fallback for STN Constraint Solving

**Related Project ADRs:**

- **ADR-004**: Mandatory Stability Verification
- **ADR-022**: Test-Driven Development
- **ADR-157**: STN Consistency Test Recovery

## Notes

This ADR focuses on implementing a comprehensive testing strategy for the MiniZinc and Fixpoint solvers, with a particular emphasis on STN problems. The testing strategy is designed to ensure that both solvers produce correct and consistent results, and to detect regressions when modifying solver implementations.

The testing approach combines traditional unit and integration tests with property-based testing for systematic exploration of the problem space. Known-solution tests provide verification against problems with known correct answers, while edge case tests ensure that the solvers handle boundary conditions correctly.

The benchmark suite provides insights into solver performance and scalability, allowing for informed decisions about solver selection based on problem characteristics. By tracking benchmark results over time, we can detect performance regressions and ensure that solver optimizations actually improve performance.

The implementation of this testing strategy will require significant effort, but the benefits in terms of solver quality and reliability justify the investment. By ensuring that our solvers produce correct and consistent results, we can build more reliable systems on top of them.
