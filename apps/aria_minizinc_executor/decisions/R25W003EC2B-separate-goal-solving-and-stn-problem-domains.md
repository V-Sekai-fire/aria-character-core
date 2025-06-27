# ADR-003: Separate Goal Solving and STN Problem Domains

<!-- @adr_serial R25W003EC2B -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The `aria_minizinc` app currently handles two fundamentally different constraint problem domains:

### Current Implementation

1. **Goal Solving Problems**:
   - Use structured variables (time_vars, location_vars, boolean_vars)
   - Focus on general constraint satisfaction
   - Use the `goal_solving.mzn.eex` template

2. **Simple Temporal Network (STN) Problems**:
   - Use time points and distance constraints
   - Focus specifically on temporal consistency
   - Use the `stn_temporal.mzn.eex` template

### Architectural Issue

The current implementation in `problem_generator.ex` attempts to **transform goal solving data to STN format** in the `transform_to_stn_format/4` function. This is architecturally unsound because:

1. **Domain Mismatch**: Goal solving and STN are fundamentally different problem domains with different mathematical foundations
2. **Forced Transformation**: The current code forces an unnatural transformation between unrelated data structures
3. **Conceptual Confusion**: Treating these as transformable variants of the same problem type creates conceptual confusion
4. **Maintenance Burden**: Changes to one domain may inadvertently affect the other due to the shared transformation logic

### Problem Analysis

The root issue is that the current architecture treats STN as a variant of goal solving that can be derived through transformation, when in reality:

- **Goal Solving**: General constraint satisfaction with arbitrary variables and constraints
- **STN**: Specialized temporal reasoning with time points and distance constraints

This architectural misalignment leads to:

- Brittle code that tries to bridge incompatible domains
- Increased complexity in the transformation logic
- Potential bugs when one domain evolves independently of the other
- Difficulty in maintaining and extending each domain separately

## Decision

Completely separate the Goal Solving and STN problem domains with distinct data generation pipelines and no transformation between them.

### Architectural Principles

1. **Domain Separation**: Each problem domain (Goal Solving, STN) should have its own complete pipeline from input to MiniZinc model
2. **No Cross-Domain Transformation**: Eliminate any transformation between domains
3. **Explicit Problem Type**: Require explicit problem type specification with no automatic conversion
4. **Specialized Interfaces**: Provide domain-specific interfaces for each problem type

### Implementation Strategy

1. **Separate Generation Functions**:
   - `generate_goal_solving_problem/4` - Specifically for goal solving problems
   - `generate_stn_problem/4` - Specifically for STN problems

2. **Domain-Specific Data Structures**:
   - Keep the existing structured variables for goal solving
   - Create proper STN-specific data structures for time points and distance constraints

3. **Template Selection**:
   - Use the existing template selection logic to route to the appropriate generation function
   - Maintain explicit problem type specification with no defaults

4. **Public API**:
   - Update the public API to make the domain separation clear
   - Add domain-specific convenience functions for common use cases

## Implementation Plan

### Phase 1: Refactor Problem Generator ✅ PLANNED

1. **Create Domain-Specific Generation Functions**:

   ```elixir
   @spec generate_goal_solving_problem(domain(), state(), [goal()], options()) ::
           {:ok, goal_solving_problem_data()} | {:error, String.t()}
   def generate_goal_solving_problem(domain, state, goals, options \\ %{}) do
     # Goal solving specific implementation
     # No STN transformation
   end

   @spec generate_stn_problem(domain(), state(), [goal()], options()) ::
           {:ok, stn_problem_data()} | {:error, String.t()}
   def generate_stn_problem(domain, state, goals, options \\ %{}) do
     # STN specific implementation
     # No goal solving transformation
   end
   ```

2. **Update Main Generation Function**:

   ```elixir
   def generate_problem(domain, state, goals, options \\ %{}) do
     case Map.get(options, :problem_type) do
       :goal_solving -> generate_goal_solving_problem(domain, state, goals, options)
       :stn -> generate_stn_problem(domain, state, goals, options)
       nil -> {:error, "Problem type must be explicitly specified (:goal_solving or :stn)"}
       unknown -> {:error, "Unknown problem type: #{inspect(unknown)}"}
     end
   end
   ```

3. **Remove Transformation Functions**:
   - Remove `transform_to_stn_format/4`
   - Remove `extract_stn_time_points/2`
   - Remove other cross-domain transformation functions

### Phase 2: Create Domain-Specific Data Structures ✅ PLANNED

1. **Goal Solving Data Structures**:

   ```elixir
   @type goal_solving_problem_data :: %{
     model: String.t(),
     variables: structured_variables(),
     constraints: [constraint()],
     objective: String.t(),
     metadata: problem_metadata()
   }
   ```

2. **STN Data Structures**:

   ```elixir
   @type stn_problem_data :: %{
     model: String.t(),
     time_points: [time_point()],
     distance_matrix: [[integer()]],
     objective: String.t(),
     metadata: problem_metadata()
   }

   @type time_point :: %{
     id: non_neg_integer(),
     name: String.t(),
     domain: Range.t()
   }
   ```

3. **Update Type Specifications**:
   - Update all function specs to use the appropriate domain-specific types
   - Add clear documentation about which functions are for which domain

### Phase 3: Update Template Rendering ✅ PLANNED

1. **Goal Solving Template Rendering**:

   ```elixir
   defp build_goal_solving_model(variables, constraints, objective, generation_start) do
     # Goal solving specific template rendering
     # No STN concepts
   end
   ```

2. **STN Template Rendering**:

   ```elixir
   defp build_stn_model(time_points, distance_matrix, objective, generation_start) do
     # STN specific template rendering
     # No goal solving concepts
   end
   ```

3. **Remove Shared Template Logic**:
   - Eliminate any shared template rendering logic
   - Keep template selection but route to completely separate rendering functions

### Phase 4: Update Public API ✅ PLANNED

1. **Add Domain-Specific Convenience Functions**:

   ```elixir
   def solve_goal_problem(domain, state, goals, options \\ %{}) do
     options = Map.put(options, :problem_type, :goal_solving)
     with {:ok, problem} <- generate_problem(domain, state, goals, options),
          {:ok, solution} <- solve(problem, options) do
       {:ok, solution}
     end
   end

   def solve_stn_problem(domain, state, goals, options \\ %{}) do
     options = Map.put(options, :problem_type, :stn)
     with {:ok, problem} <- generate_problem(domain, state, goals, options),
          {:ok, solution} <- solve(problem, options) do
       {:ok, solution}
     end
   end
   ```

2. **Update Documentation**:
   - Clearly document the domain separation
   - Provide examples for each domain
   - Explain when to use each problem type

### Phase 5: Comprehensive Testing ✅ PLANNED

1. **Goal Solving Tests**:

   ```elixir
   describe "generate_goal_solving_problem/4" do
     test "generates valid goal solving problem"
     test "handles structured variables correctly"
     test "generates appropriate constraints"
     test "returns error for invalid inputs"
   end
   ```

2. **STN Tests**:

   ```elixir
   describe "generate_stn_problem/4" do
     test "generates valid STN problem"
     test "creates proper time points"
     test "builds correct distance matrix"
     test "returns error for invalid inputs"
   end
   ```

3. **Integration Tests**:

   ```elixir
   describe "domain separation" do
     test "goal solving pipeline works end-to-end"
     test "STN pipeline works end-to-end"
     test "explicit problem type is required"
   end
   ```

## Success Criteria

**Domain Separation:**

- [ ] No transformation between goal solving and STN domains
- [ ] Separate, complete pipelines for each domain
- [ ] Domain-specific data structures and functions
- [ ] Clear, explicit problem type specification

**Code Quality:**

- [ ] Reduced complexity in problem generation
- [ ] Improved maintainability with clear separation of concerns
- [ ] Better type specifications for each domain
- [ ] Comprehensive test coverage for each domain

**User Experience:**

- [ ] Clear documentation on when to use each problem type
- [ ] Explicit error messages when problem type is not specified
- [ ] Domain-specific convenience functions for common use cases
- [ ] Consistent API across both domains

## Consequences

**Positive:**

- **Conceptual Clarity**: Clear separation between fundamentally different problem domains
- **Reduced Complexity**: Simpler, more focused code for each domain
- **Improved Maintainability**: Changes to one domain won't affect the other
- **Better Extensibility**: Each domain can evolve independently
- **Stronger Type Safety**: Domain-specific types for better static analysis

**Negative:**

- **Breaking Changes**: Existing code that relies on automatic transformation will need updates
- **Increased API Surface**: More functions and types to document and maintain
- **Migration Effort**: Existing code will need to be updated to specify problem type
- **Potential Duplication**: Some utility functions may need to be duplicated for each domain

**Risks:**

- **Backward Compatibility**: Existing code may break if it doesn't specify problem type
- **Learning Curve**: Users need to understand which problem type to use
- **Documentation Burden**: Need to clearly explain the differences between domains
- **Testing Coverage**: Need comprehensive tests for each domain

## Related ADRs

**Parent ADRs:**

- **ADR-001**: Extract MiniZinc Functionality into Dedicated App
- **ADR-002**: Implement Template Selection Logic and STN Testing

**Related Project ADRs:**

- **ADR-126**: MiniZinc Multigoal Optimization with Fallback
- **ADR-128**: STN Solver MiniZinc Fallback Implementation
- **ADR-078**: Timeline Module PC-2 STN Implementation

## Notes

This ADR addresses a fundamental architectural issue in the current implementation. By properly separating the goal solving and STN domains, we create a more maintainable, conceptually clear, and extensible codebase.

The key insight is recognizing that these are fundamentally different problem domains that should not be transformed between each other. This separation will allow each domain to evolve independently and be optimized for its specific use cases.

The implementation plan focuses on creating clean, separate pipelines for each domain while maintaining a consistent API and explicit problem type specification. This approach balances the need for architectural correctness with practical considerations for existing code.
