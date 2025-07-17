# R25W0852AD9: Runtime-Informed Multigoal Optimization During Lazy Execution

<!-- @adr_serial R25W0852AD9 -->

**Status:** Paused  
**Date:** 2025-06-22  
**Priority:** HIGH  
**Dependencies:** R25W0849E89 (MiniZinc Multigoal Optimization), R25W0839F8C (run_lazy_refineahead)

## Context

R25W0849E89 provides excellent static multigoal optimization before execution begins, achieving 18.8-50% efficiency improvements through constraint-based optimization. However, during `run_lazy_refineahead` execution, we have access to rich runtime information that is unavailable during static planning, creating an opportunity for even more sophisticated optimization.

### The Gap Between Static and Runtime Optimization

**Current Static Optimization (R25W0849E89):**

- Optimizes multigoals based on initial state and predicted execution patterns
- Uses estimated action costs, movement distances, and resource availability
- Cannot account for actual execution performance or dynamic state changes
- Provides excellent baseline optimization but lacks adaptability

**Available Runtime Information During Lazy Execution:**

1. **Execution State Context** - actual current state vs. predicted state during execution
2. **Performance Metrics** - real action execution times, movement costs, resource access patterns
3. **Method Failure History** - which methods have been blacklisted and failure reasons
4. **Dynamic Goal Status** - goals already satisfied during execution progression
5. **Resource Availability** - actual resource contention vs. predicted availability
6. **Execution Statistics** - step counts, timing, success rates from execution context
7. **Backtracking History** - which paths failed and required replanning

### Current Multigoal Processing Limitations

In `AriaEngine.Plan.Execution.process_multigoal_node/4`, multigoal optimization currently:

- Uses only the current execution state
- Cannot leverage execution history or performance metrics
- Applies static optimization methods without runtime context
- Misses opportunities for dynamic re-optimization based on execution patterns

### The Opportunity

During `run_lazy_refineahead`, when encountering multigoal nodes, we can:

- Use actual execution performance to refine optimization constraints
- Leverage method failure patterns to avoid problematic approaches
- Dynamically adjust goal priorities based on execution progress
- Re-optimize remaining goals using real resource availability data
- Apply execution-informed heuristics for better method selection

## Decision

Implement **Runtime-Informed Multigoal Optimization** that enhances lazy execution with dynamic multigoal re-optimization using runtime execution context, providing superior optimization compared to static planning alone.

### Architecture Approach

**Hierarchical Optimization Strategy:**

1. **Static Optimization** (R25W0849E89): Initial multigoal optimization before execution
2. **Runtime Re-optimization** (This ADR): Dynamic optimization during lazy execution
3. **Fallback Chain**: Runtime → Static → Naive splitting

**Integration Strategy:**

- Extend existing multigoal processing in `plan/execution.ex`
- Enhance R25W0849E89's optimizer interface to accept runtime context
- Maintain backward compatibility with current lazy execution behavior
- Provide graceful fallback to static optimization when runtime optimization fails

## Implementation Plan

### Phase 1: Runtime Context Collection and Integration

**File**: `lib/aria_engine/plan/execution.ex`

**Runtime Context Structure:**

- [ ] Design `RuntimeContext` data structure with execution metrics
- [ ] Modify `process_multigoal_node/4` to collect runtime execution context
- [ ] Extend multigoal method interface to accept execution context parameters
- [ ] Create execution metrics tracking throughout lazy execution

**Implementation Tasks:**

- [ ] Create `RuntimeContext` struct with execution state, performance metrics, failure history
- [ ] Integrate context collection in `execute_from_node/2` and related functions
- [ ] Pass runtime context to multigoal methods in `try_multigoal_methods/4`
- [ ] Add execution statistics tracking (timing, success rates, resource usage)

### Phase 2: Enhanced Optimizer Interface

**File**: `lib/aria_engine/multigoal/optimizer.ex`

**Runtime-Aware Optimization:**

- [ ] Extend `optimize/3` to accept optional runtime context parameter
- [ ] Create runtime-specific optimization logic that uses execution data
- [ ] Implement cost-benefit analysis for when to trigger re-optimization
- [ ] Add runtime optimization caching to avoid redundant constraint solving

**Implementation Tasks:**

- [ ] Add `runtime_optimize/4` function for context-aware optimization
- [ ] Create runtime context validation and preprocessing
- [ ] Implement re-optimization triggers (state changes, method failures, performance deviations)
- [ ] Add optimization decision logic (when to re-optimize vs. continue current plan)

### Phase 3: Runtime-Informed Constraint Building

**File**: `lib/aria_engine/multigoal/constraint_builder.ex`

**Execution-Informed Constraints:**

- [ ] Create runtime-aware constraint building that incorporates execution data
- [ ] Use actual action execution times vs. estimated times in optimization
- [ ] Apply real movement costs based on execution history
- [ ] Incorporate dynamic resource availability and contention patterns
- [ ] Use method failure patterns and success probabilities

**Implementation Tasks:**

- [ ] Add `build_runtime_constraints/3` function for execution-informed constraint generation
- [ ] Create constraint templates that use runtime performance data
- [ ] Implement dynamic resource modeling based on actual availability
- [ ] Add method reliability scoring based on execution history

### Phase 4: Adaptive MiniZinc Templates

**File**: `lib/aria_engine/multigoal/template_renderer.ex`

**Runtime-Informed Templates:**

- [ ] Create MiniZinc templates that incorporate runtime execution data
- [ ] Add template selection logic based on execution patterns
- [ ] Implement dynamic constraint generation using execution metrics
- [ ] Create execution-aware optimization objectives

**Implementation Tasks:**

- [ ] Create `runtime_multigoal_optimization.mzn.eex` template
- [ ] Add runtime data binding in template rendering
- [ ] Implement execution-informed objective functions
- [ ] Create adaptive constraint generation based on runtime patterns

### Phase 5: New Supporting Modules

**Runtime Context Management:**

- [ ] `AriaEngine.Multigoal.RuntimeContext` - context data structure and collection
- [ ] `AriaEngine.Multigoal.RuntimeOptimizer` - runtime-specific optimization logic
- [ ] `AriaEngine.Multigoal.ExecutionMetrics` - performance tracking and analysis
- [ ] `AriaEngine.Multigoal.AdaptiveConstraints` - runtime-informed constraint building

### Phase 6: Integration Testing and Validation

**Testing Framework:**

- [ ] Create runtime optimization test scenarios
- [ ] Validate performance improvements over static optimization
- [ ] Test fallback behavior when runtime optimization fails
- [ ] Ensure backward compatibility with existing lazy execution

**Performance Validation:**

- [ ] Measure additional efficiency gains beyond R25W0849E89's static optimization
- [ ] Validate re-optimization timing and performance impact
- [ ] Test scalability with different multigoal complexity levels
- [ ] Verify graceful degradation and fallback behavior

## Success Criteria

### Quantifiable Improvements Over Static Optimization

**Additional Performance Gains Beyond R25W0849E89:**

- **Action Efficiency**: 15-25% additional reduction in total actions beyond static optimization
- **Resource Utilization**: 20-30% better resource scheduling through runtime-informed decisions
- **Method Selection**: 10-20% reduction in method failures through execution-informed selection
- **Temporal Optimization**: 15-25% additional improvement in completion time through dynamic re-optimization

**Runtime Performance Requirements:**

- **Re-optimization Time**: Sub-second constraint solving for runtime re-optimization
- **Memory Overhead**: <10% additional memory usage for runtime context tracking
- **Execution Impact**: <5% overhead on lazy execution performance

### Integration and Reliability Requirements

**Backward Compatibility:**

- **Zero Breaking Changes**: No impact on existing lazy execution behavior
- **Graceful Fallback**: 100% success rate falling back to static optimization when runtime optimization fails
- **Fallback Chain**: Maintain R25W0849E89's fallback sequence (runtime → static → naive splitting)

**Robustness:**

- **Context Collection**: Reliable runtime context gathering without execution failures
- **Re-optimization Triggers**: Intelligent decision-making for when to re-optimize
- **Performance Monitoring**: Track optimization success rates and performance impact

## Technical Architecture

### Runtime Context Data Structure

```elixir
defmodule AriaEngine.Multigoal.RuntimeContext do
  @type t :: %__MODULE__{
    # Current execution state and history
    execution_stats: ExecutionStats.t(),
    current_state: AriaEngine.StateV2.t(),
    execution_timeline: [execution_event()],
    
    # Method and action performance tracking
    method_performance: %{method_name() => method_metrics()},
    action_performance: %{action_name() => action_metrics()},
    blacklisted_methods: MapSet.t(method_name()),
    
    # Resource and goal tracking
    resource_contention: %{resource_id() => resource_metrics()},
    goal_satisfaction_history: [satisfied_goal()],
    remaining_goals: [goal()],
    
    # Optimization context
    optimization_history: [optimization_result()],
    last_optimization_time: integer(),
    re_optimization_triggers: [trigger_reason()]
  }
end
```

### Enhanced Optimizer Interface

```elixir
defmodule AriaEngine.Multigoal.Optimizer do
  @spec optimize_multigoal(StateV2.t(), [goal()], keyword()) :: 
    {:ok, optimization_result()} | {:error, term()}
  def optimize_multigoal(state, goals, opts \\ []) do
    case Keyword.get(opts, :runtime_context) do
      nil -> 
        # Static optimization (R25W0849E89 behavior)
        static_optimize_multigoal(state, goals, opts)
      
      %RuntimeContext{} = context -> 
        # Runtime-informed optimization (this ADR)
        runtime_optimize_multigoal(state, goals, context, opts)
    end
  end
  
  @spec runtime_optimize_multigoal(StateV2.t(), [goal()], RuntimeContext.t(), keyword()) ::
    {:ok, optimization_result()} | {:error, term()}
  defp runtime_optimize_multigoal(state, goals, context, opts) do
    # Use runtime context for enhanced optimization
    with {:ok, should_reoptimize} <- should_trigger_reoptimization(context, opts),
         {:ok, runtime_constraints} <- build_runtime_constraints(state, goals, context),
         {:ok, optimized_sequence} <- solve_runtime_constraints(runtime_constraints, opts) do
      {:ok, optimized_sequence}
    else
      {:error, reason} -> 
        # Fallback to static optimization
        static_optimize_multigoal(state, goals, opts)
    end
  end
end
```

### Integration Points in Plan Execution

**Modified Functions in `lib/aria_engine/plan/execution.ex`:**

```elixir
# Enhanced multigoal processing with runtime context
defp process_multigoal_node(execution_state, node_id, node, multigoal) do
  # Collect runtime context from execution state
  runtime_context = collect_runtime_context(execution_state, node_id)
  
  # Pass context to multigoal methods
  enhanced_opts = [
    runtime_context: runtime_context,
    execution_state: execution_state
  ]
  
  # Try runtime-informed multigoal methods
  try_multigoal_methods_with_context(execution_state, node_id, node, multigoal, enhanced_opts)
end

# Runtime context collection
defp collect_runtime_context(execution_state, node_id) do
  %RuntimeContext{
    execution_stats: calculate_execution_stats(execution_state),
    current_state: execution_state.current_state,
    method_performance: execution_state.method_performance_tracker,
    blacklisted_methods: execution_state.blacklisted_commands,
    resource_contention: analyze_resource_usage(execution_state),
    optimization_history: execution_state.optimization_history
  }
end
```

### Runtime-Informed MiniZinc Templates

**Template**: `priv/templates/minizinc/runtime_multigoal_optimization.mzn.eex`

```minizinc
% Runtime-informed multigoal optimization template
% Uses actual execution data for enhanced constraint modeling

% Decision variables (same as static optimization)
array[1..num_goals] of var 1..max_time: goal_completion_time;
array[1..num_goals] of var 1..num_locations: goal_locations;

% Runtime-informed constraints
% Use actual action execution times from runtime context
array[1..num_actions] of int: actual_action_times = [<%= for time <- runtime_action_times do %><%= time %>, <% end %>];

% Use real resource contention patterns
array[1..num_resources] of float: resource_availability = [<%= for avail <- runtime_resource_availability do %><%= avail %>, <% end %>];

% Method reliability based on execution history
array[1..num_methods] of float: method_success_rates = [<%= for rate <- runtime_method_success_rates do %><%= rate %>, <% end %>];

% Runtime-informed objective function
% Minimize completion time weighted by actual performance data
solve minimize sum(i in 1..num_goals)(
  goal_completion_time[i] * actual_action_times[goal_action_mapping[i]] * 
  (1.0 - method_success_rates[goal_method_mapping[i]])
);
```

## Consequences

### Benefits

**Superior Optimization Performance:**

- **Adaptive Intelligence**: Optimization improves based on actual execution experience
- **Dynamic Responsiveness**: Re-optimization responds to changing execution conditions
- **Execution-Informed Decisions**: Uses real performance data rather than estimates
- **Continuous Learning**: Method and action performance tracking improves over time

**Enhanced System Capabilities:**

- **Runtime Adaptability**: System adapts to unexpected execution patterns
- **Performance Optimization**: Leverages actual execution data for better decisions
- **Failure Recovery**: Uses failure patterns to avoid problematic optimization paths
- **Resource Intelligence**: Optimizes based on real resource availability patterns

### Risks and Mitigation Strategies

**Implementation Complexity:**

- **Risk**: Runtime optimization adds significant complexity to lazy execution
- **Mitigation**: Comprehensive testing framework and graceful fallback to static optimization

**Performance Overhead:**

- **Risk**: Runtime context collection and re-optimization may impact execution performance
- **Mitigation**: Intelligent re-optimization triggers and performance monitoring with thresholds

**Integration Challenges:**

- **Risk**: Complex integration with existing lazy execution and static optimization systems
- **Mitigation**: Backward compatibility requirements and extensive integration testing

**Runtime Optimization Failures:**

- **Risk**: Runtime optimization may fail more frequently than static optimization
- **Mitigation**: Robust fallback chain and comprehensive error handling

### Long-term Implications

**System Evolution:**

- **Learning System**: Creates foundation for machine learning-enhanced optimization
- **Performance Intelligence**: Builds execution performance database for future improvements
- **Adaptive Planning**: Enables planning systems that improve through execution experience
- **Runtime Analytics**: Provides rich data for system performance analysis and optimization

## Scope and Boundaries

### What This ADR Covers (Runtime Multigoal Optimization)

**Primary Responsibility:**

- **Runtime-informed multigoal re-optimization** during lazy execution using execution context
- **Dynamic constraint adjustment** based on actual execution performance and patterns
- **Execution context integration** with multigoal optimization systems
- **Adaptive optimization** using method failure patterns, performance metrics, and resource availability

**Specific Implementation Areas:**

- Enhanced `AriaEngine.Multigoal.Optimizer.optimize_multigoal/3` with runtime context support
- Runtime context collection and management during lazy execution
- Execution-informed MiniZinc templates and constraint generation
- Re-optimization triggers and decision logic for when to adapt plans
- Performance tracking and execution metrics integration

### What This ADR Does NOT Cover (Tombstoned Responsibilities)

**Static Optimization (→ R25W0849E89):**

- ❌ **Pre-execution multigoal optimization** using initial state and predicted patterns
- ❌ **Static constraint modeling** with fixed parameters and template-based optimization
- ❌ **Basic MiniZinc integration** and template system foundation
- ❌ **Domain registration and method blacklisting** for static optimization
- ❌ **Fallback mechanisms** from optimization to naive splitting (handled by R25W0849E89)

**Lazy Execution Engine (→ R25W0839F8C):**

- ❌ **Core lazy execution implementation** and backtracking logic
- ❌ **Plan execution strategies** and basic execution context management
- ❌ **Solution tree processing** and node execution logic
- ❌ **Method and action execution** during plan execution

**Rationale for Boundaries:**
This ADR builds on R25W0849E89's proven static optimization foundation (18.8-50% efficiency gains) to add adaptive intelligence during execution. It requires R25W0849E89's static optimization to be stable and R25W0839F8C's lazy execution to be mature before adding runtime optimization complexity. The goal is 15-25% additional efficiency gains beyond static optimization through execution-informed decisions.

## Related ADRs

- **R25W0849E89**: MiniZinc Multigoal Optimization with Fallback (provides static optimization foundation that this ADR enhances with runtime intelligence)
- **R25W0839F8C**: Restore run_lazy_refineahead from IPyHOP (provides lazy execution foundation where runtime optimization occurs)
- **R25W0489307**: Hybrid Planner Dependency Encapsulation (strategy architecture framework)
- **apps/aria_timeline/decisions/R25W0389D35**: Timeline Module PC-2 STN Implementation (temporal constraint foundation)

## Implementation Strategy

### Current Focus: Architecture Design and Planning

This ADR is currently **paused** to allow for:

1. **R25W0849E89 Stabilization**: Ensure static multigoal optimization is fully stable and performant
2. **Lazy Execution Maturity**: Allow `run_lazy_refineahead` implementation to mature and stabilize
3. **Performance Baseline**: Establish clear performance baselines with static optimization
4. **Architecture Refinement**: Refine runtime optimization architecture based on static optimization experience

### Future Implementation Approach

When resumed, implementation will follow a careful, incremental approach:

1. **Phase 1**: Runtime context collection without optimization (data gathering)
2. **Phase 2**: Simple runtime re-optimization triggers and basic enhanced constraints
3. **Phase 3**: Full runtime-informed MiniZinc template system
4. **Phase 4**: Advanced adaptive optimization with machine learning integration

### Success Metrics for Resumption

**Prerequisites for resuming this ADR:**

- R25W0849E89 static optimization demonstrates consistent 15%+ improvements in production
- `run_lazy_refineahead` execution is stable and performant across diverse scenarios
- Clear performance baselines established for comparison with runtime optimization
- Development team capacity available for complex optimization system enhancement

**Resumption Triggers:**

- Production deployment reveals optimization opportunities that require runtime context
- User scenarios demonstrate clear need for adaptive optimization during execution
- System performance analysis shows significant potential for runtime-informed improvements
- Technical foundation (R25W0849E89, R25W0839F8C) proves stable and ready for enhancement

This approach ensures that runtime-informed optimization builds on a solid foundation of proven static optimization and stable lazy execution, maximizing the likelihood of successful implementation when the work resumes.
