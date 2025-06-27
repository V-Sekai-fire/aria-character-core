# ADR-004: Implement Multigoal Optimization Strategy

<!-- @adr_serial R25W00427C2 -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** MEDIUM

## Context

The `aria_minizinc` app currently supports two problem domains:

1. **Goal Solving Problems**: General constraint satisfaction with structured variables
2. **STN Problems**: Temporal consistency with time points and distance constraints

However, there's a need for a third problem domain that focuses on optimizing multiple competing objectives simultaneously. This is referenced in ADR-001 as "Multigoal Optimization" and in ADR-126 as "MiniZinc Multigoal Optimization with Fallback".

### Current Limitations

1. **Single Objective Optimization**: Both existing problem domains only support single-objective optimization:
   - Goal Solving: Minimizes time, distance, or maximizes efficiency
   - STN: Minimizes makespan (latest time point)

2. **No Support for Competing Objectives**: Cannot handle scenarios where multiple objectives compete (e.g., minimize time while also minimizing resource usage)

3. **Limited Optimization Strategies**: No support for weighted objectives, Pareto optimization, or lexicographic ordering

### Use Cases for Multigoal Optimization

1. **Resource-Constrained Planning**: Optimize for both time and resource usage
2. **Quality-Speed Tradeoffs**: Balance solution quality against computation time
3. **Multi-Agent Scheduling**: Optimize for both individual and collective goals
4. **Preference Satisfaction**: Maximize satisfaction of multiple competing preferences

### Technical Challenges

1. **Objective Representation**: How to represent multiple objectives with different units and scales
2. **Solution Comparison**: How to compare solutions with different tradeoffs
3. **Solver Integration**: How to leverage MiniZinc's multi-objective capabilities
4. **Fallback Strategy**: How to implement multi-objective optimization in the fixpoint fallback solver

## Decision

Implement a dedicated Multigoal Optimization problem domain with its own data structures, generation functions, and template.

### Architectural Principles

1. **Separate Problem Domain**: Following ADR-003, treat Multigoal Optimization as a distinct problem domain
2. **No Cross-Domain Transformation**: No transformation between Multigoal and other domains
3. **Explicit Problem Type**: Require explicit `:multigoal` problem type specification
4. **Weighted Objective Model**: Support weighted combination of objectives with normalization

### Implementation Strategy

1. **Multigoal Data Structures**:
   - Define multigoal-specific types for objectives, weights, and solutions
   - Support multiple objective functions with weights and normalization factors

2. **Multigoal Template**:
   - Create a dedicated `multigoal_optimization.mzn.eex` template
   - Support weighted sum, lexicographic, and Pareto optimization methods

3. **Generation Functions**:
   - Implement `generate_multigoal_problem/4` specifically for multigoal problems
   - Add objective extraction and normalization logic

4. **Solution Interpretation**:
   - Add functions to interpret and compare multigoal solutions
   - Provide utilities for analyzing tradeoffs between objectives

## Implementation Plan

### Phase 1: Multigoal Data Structures ✅ PLANNED

1. **Define Multigoal Types**:

   ```elixir
   @type objective :: %{
     name: String.t(),
     expression: String.t(),
     weight: float(),
     normalize: boolean(),
     direction: :minimize | :maximize
   }

   @type multigoal_problem_data :: %{
     model: String.t(),
     variables: [variable()],
     constraints: [constraint()],
     objectives: [objective()],
     optimization_method: :weighted_sum | :lexicographic | :pareto,
     metadata: problem_metadata()
   }
   ```

2. **Update Problem Generator Types**:
   - Add multigoal-specific types to problem_generator.ex
   - Update type specifications for multigoal functions

### Phase 2: Multigoal Template ✅ PLANNED

1. **Create Template File**:
   - Create `priv/templates/minizinc/multigoal_optimization.mzn.eex`
   - Implement template with support for multiple objectives

2. **Template Structure**:

   ```
   % Generated MiniZinc Model - Multigoal Optimization
   % Objectives: <%= length(@objectives) %>
   % Generated at: <%= @generation_start %>

   % Variables
   <%= for var <- @variables do %>
   <%= var.type %>: <%= var.domain %> = <%= var.name %>;
   <% end %>

   % Constraints
   <%= for constraint <- @constraints do %>
   <%= constraint %>
   <% end %>

   % Objective Functions
   <%= for objective <- @objectives do %>
   var float: <%= objective.name %> = <%= objective.expression %>;
   <% end %>

   % Optimization Method: <%= @optimization_method %>
   <%= case @optimization_method do %>
   <% :weighted_sum -> %>
   solve minimize <%= Enum.map_join(@objectives, " + ", fn obj -> "#{obj.weight} * #{obj.name}" end) %>;
   <% :lexicographic -> %>
   solve 
     :: int_search([<%= Enum.map_join(@objectives, ", ", fn obj -> obj.name end) %>], input_order, indomain_min)
     minimize <%= Enum.at(@objectives, 0).name %>;
   <% :pareto -> %>
   solve 
     :: multi_objective([<%= Enum.map_join(@objectives, ", ", fn obj -> obj.name end) %>])
     satisfy;
   <% end %>

   % Output
   output [
     "solution = ", show(solution), ";\n",
     <%= for objective <- @objectives do %>
     "<%= objective.name %> = ", show(<%= objective.name %>), ";\n",
     <% end %>
   ];
   ```

### Phase 3: Generation Functions ✅ PLANNED

1. **Implement Multigoal Generation**:

   ```elixir
   @spec generate_multigoal_problem(domain(), state(), [goal()], options()) ::
           {:ok, multigoal_problem_data()} | {:error, String.t()}
   def generate_multigoal_problem(domain, state, goals, options \\ %{}) do
     # Capture generation start time
     generation_start = Timex.now() |> Timex.format!("{ISO:Extended}")

     try do
       # Extract variables from goals and state
       variables = extract_variables(goals, state)

       # Generate constraints from domain and goals
       constraints = generate_constraints(domain, state, goals, options)

       # Extract multiple objectives with weights
       objectives = extract_objectives(goals, options)

       # Determine optimization method
       optimization_method = determine_optimization_method(options)

       # Build multigoal MiniZinc model
       model = build_multigoal_model(variables, constraints, objectives, 
                                    optimization_method, generation_start)

       # Calculate metadata
       generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
       generation_duration = calculate_duration(generation_start, generation_end)

       # Create problem data structure
       problem_data = %{
         model: model,
         variables: variables,
         constraints: constraints,
         objectives: objectives,
         optimization_method: optimization_method,
         metadata: %{
           goal_count: length(goals),
           variable_count: length(variables),
           constraint_count: length(constraints),
           objective_count: length(objectives),
           generation_start: generation_start,
           generation_end: generation_end,
           generation_duration: generation_duration
         }
       }

       {:ok, problem_data}
     rescue
       error ->
         {:error, "Multigoal problem generation failed: #{Exception.message(error)}"}
     end
   end
   ```

2. **Extract Objectives Function**:

   ```elixir
   @spec extract_objectives([goal()], options()) :: [objective()]
   defp extract_objectives(goals, options) do
     # Get explicit objectives from options
     explicit_objectives = Map.get(options, :objectives, [])

     # Generate implicit objectives from goals
     implicit_objectives = goals
     |> Enum.filter(fn {_subject, predicate, _value} -> 
       predicate in ["optimize", "minimize", "maximize"] 
     end)
     |> Enum.map(fn {subject, predicate, value} ->
       direction = case predicate do
         "maximize" -> :maximize
         _ -> :minimize
       end

       %{
         name: "#{subject}_#{predicate}",
         expression: generate_objective_expression(subject, value),
         weight: 1.0,
         normalize: true,
         direction: direction
       }
     end)

     # Combine and normalize weights
     all_objectives = explicit_objectives ++ implicit_objectives
     normalize_objective_weights(all_objectives)
   end
   ```

3. **Optimization Method Selection**:

   ```elixir
   defp determine_optimization_method(options) do
     case Map.get(options, :optimization_method, :weighted_sum) do
       :weighted_sum -> :weighted_sum
       :lexicographic -> :lexicographic
       :pareto -> :pareto
       _ -> :weighted_sum
     end
   end
   ```

### Phase 4: Update Public API ✅ PLANNED

1. **Add Multigoal Convenience Function**:

   ```elixir
   @doc """
   Solve a multigoal optimization problem.

   ## Parameters
   - `domain` - The planning domain
   - `state` - Current state
   - `goals` - List of goals including optimization objectives
   - `options` - Options including weights and optimization method

   ## Returns
   - `{:ok, solution}` - Successfully solved problem
   - `{:error, reason}` - Failed to solve problem
   """
   def solve_multigoal_problem(domain, state, goals, options \\ %{}) do
     options = Map.put(options, :problem_type, :multigoal)
     with {:ok, problem} <- generate_problem(domain, state, goals, options),
          {:ok, solution} <- solve(problem, options) do
       {:ok, solution}
     end
   end
   ```

2. **Update Main Generation Function**:

   ```elixir
   def generate_problem(domain, state, goals, options \\ %{}) do
     case Map.get(options, :problem_type) do
       :goal_solving -> generate_goal_solving_problem(domain, state, goals, options)
       :stn -> generate_stn_problem(domain, state, goals, options)
       :multigoal -> generate_multigoal_problem(domain, state, goals, options)
       nil -> {:error, "Problem type must be explicitly specified"}
       unknown -> {:error, "Unknown problem type: #{inspect(unknown)}"}
     end
   end
   ```

### Phase 5: Comprehensive Testing ✅ PLANNED

1. **Multigoal Unit Tests**:

   ```elixir
   describe "generate_multigoal_problem/4" do
     test "generates valid multigoal problem"
     test "handles multiple objectives correctly"
     test "applies correct weights to objectives"
     test "supports different optimization methods"
     test "returns error for invalid inputs"
   end
   ```

2. **Integration Tests**:

   ```elixir
   describe "multigoal optimization" do
     test "solves weighted sum optimization problem"
     test "solves lexicographic optimization problem"
     test "solves Pareto optimization problem"
     test "handles competing objectives correctly"
   end
   ```

3. **Performance Tests**:

   ```elixir
   describe "multigoal performance" do
     test "scales with number of objectives"
     test "handles large variable sets efficiently"
     test "compares optimization methods performance"
   end
   ```

## Success Criteria

**Functionality:**

- [ ] Support for multiple competing objectives
- [ ] Multiple optimization methods (weighted sum, lexicographic, Pareto)
- [ ] Objective normalization and weighting
- [ ] Solution comparison and analysis

**Integration:**

- [ ] Consistent API with other problem domains
- [ ] Clear documentation and examples
- [ ] Comprehensive test coverage
- [ ] Fallback to fixpoint for multigoal problems

**Performance:**

- [ ] Acceptable performance with up to 10 competing objectives
- [ ] Efficient solution comparison
- [ ] Reasonable memory usage for large problems

## Consequences

**Positive:**

- **Enhanced Capability**: Support for complex multi-objective optimization problems
- **Flexible Optimization**: Multiple methods for different use cases
- **Solution Analysis**: Tools for comparing and analyzing tradeoffs
- **Consistent Architecture**: Follows the domain separation principle from ADR-003

**Negative:**

- **Increased Complexity**: More complex API and implementation
- **Performance Challenges**: Multi-objective optimization is computationally intensive
- **Usability Concerns**: Users need to understand tradeoffs between optimization methods
- **Testing Burden**: More complex test scenarios required

**Risks:**

- **Solver Limitations**: MiniZinc may have limitations for certain multi-objective problems
- **Fallback Complexity**: Implementing multi-objective optimization in fixpoint may be challenging
- **Solution Quality**: Different optimization methods may produce significantly different results
- **Performance Degradation**: Multi-objective optimization may be significantly slower

## Related ADRs

**Parent ADRs:**

- **ADR-001**: Extract MiniZinc Functionality into Dedicated App
- **ADR-003**: Separate Goal Solving and STN Problem Domains

**Related Project ADRs:**

- **ADR-126**: MiniZinc Multigoal Optimization with Fallback
- **ADR-127**: Runtime-Informed Multigoal Optimization During Lazy Execution

## Notes

This ADR builds on the domain separation principle established in ADR-003 by adding a third distinct problem domain for multigoal optimization. By treating this as a separate domain with its own data structures and generation functions, we maintain architectural consistency while adding powerful new capabilities.

The implementation focuses on flexibility, allowing users to choose between different optimization methods depending on their specific needs. The weighted sum approach provides a simple, efficient method for most cases, while lexicographic and Pareto optimization offer more sophisticated approaches for complex scenarios.

The success of this implementation depends on careful attention to performance considerations, as multi-objective optimization can be computationally intensive. The fallback to fixpoint will be particularly important for ensuring reliability when MiniZinc is unavailable.
