# R25W148122A: LLM Actions, Search Optimization, and Multitodo Enhancement for ARC Prize

<!-- @adr_serial R25W148122A -->

**Status:** Paused  
**Date:** 2025-06-25  
**Priority:** MEDIUM  
**Prerequisites:** R25W1298CE1 (Hybrid Planner Restoration) + R25W131C16E Phase 1 completion

## Context

Enhance the ARC Prize solving capability by integrating LLM-based reasoning directly into the puzzle-solving workflow. This extends beyond simple multitodo optimization to make LLM a first-class participant in pattern recognition, search guidance, and solution validation.

**Integration Points:**

- **LLM Actions**: Direct puzzle-solving reasoning within the planning workflow
- **LLM-Guided Search**: Intelligent exploration of transformation space
- **Blacklist Management**: Eliminate impossible transformations to improve efficiency
- **Working Element Strategy**: Balance exploration vs exploitation of promising approaches
- **Multitodo Optimization**: Task sequencing enhancement using search context

**Target**: Contribute to beating 34% llm success rate through hybrid LLM + computational approach.

## Decision

Implement comprehensive LLM integration using OpenRouter API (primary) with local Qwen3 fallback, integrated during Phase 2 of ARC Prize sprint (Week 4: July 15-22).

**Architecture Strategy:**

1. **LLM as reasoning partner** - participates in actual puzzle solving
2. **Search intelligence** - guides computational exploration efficiently  
3. **Constraint management** - learns from failures to avoid repeated mistakes
4. **Hybrid coordination** - planning system orchestrates LLM + computational workflow

## Implementation Plan

### Phase 2 Integration Timeline (Week 4: July 15-22)

**Day 11: LLM Actions Foundation**

- [ ] **LLM Backend Implementation**
  - [ ] Add HTTPoison dependency to `aria_arc/mix.exs`
  - [ ] Implement `AriaArc.LlmBackend` with OpenRouter API integration
  - [ ] Add local Qwen3 fallback backend
  - [ ] Create backend selection and availability checking

- [ ] **Core LLM Actions**
  - [ ] Implement `analyze_pattern/2` action for visual pattern recognition
  - [ ] Implement `generate_transformation_hypothesis/2` action for solution generation
  - [ ] Implement `validate_solution_approach/2` action for confidence assessment
  - [ ] Add structured prompt templates for each action type

**Day 12: Search Intelligence and Constraint Management**

- [ ] **Search State Management**
  - [ ] Implement `AriaArc.SearchState` for tracking blacklist and working elements
  - [ ] Add `update_search_blacklist/2` action for impossible transformation elimination
  - [ ] Add `manage_working_elements/2` action for repetition strategy
  - [ ] Implement `llm_guided_search_with_constraints/2` for intelligent exploration

- [ ] **Constraint-Aware Search**
  - [ ] Integrate blacklist filtering in search execution
  - [ ] Add working element tracking and repetition counting
  - [ ] Implement adaptive exploration vs exploitation balance
  - [ ] Create search budget allocation strategies

**Day 13-14: Hybrid Workflow Integration and Testing**

- [ ] **Complete Workflow Implementation**
  - [ ] Integrate LLM actions with Phase 1 computational search results
  - [ ] Implement `solve_arc_puzzle_with_constraints/2` method
  - [ ] Add multitodo optimization with search context awareness
  - [ ] Test complete hybrid LLM + search + optimization pipeline

- [ ] **Evaluation and Validation**
  - [ ] Test on ARC training tasks with accuracy measurement
  - [ ] Validate blacklist effectiveness and working element strategy
  - [ ] Measure contribution to 5%+ accuracy target for go/no-go decision
  - [ ] Document approach strengths and limitations

## Technical Architecture

### LLM Backend Abstraction

```elixir
defmodule AriaArc.LlmBackend do
  @behaviour AriaArc.LlmBackend.Behaviour
  
  def call(prompt, opts \\ []) do
    backend = select_backend(opts)
    backend.call(prompt, opts)
  end
  
  defp select_backend(opts) do
    case Keyword.get(opts, :backend, :auto) do
      :auto -> auto_select_backend()
      :openrouter -> AriaArc.LlmBackend.OpenRouter
      :qwen3 -> AriaArc.LlmBackend.Qwen3Local
    end
  end
  
  defp auto_select_backend do
    cond do
      openrouter_available?() -> AriaArc.LlmBackend.OpenRouter
      qwen3_available?() -> AriaArc.LlmBackend.Qwen3Local
      true -> raise "No LLM backend available"
    end
  end
end
```

### Core LLM Actions

```elixir
defmodule AriaArc.Domain do
  use AriaEngine.Domain
  
  # Pattern recognition and analysis
  @action
  def analyze_pattern(state, %{grid: grid, context: context}) do
    prompt = build_pattern_analysis_prompt(grid, context)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, analysis} -> 
        new_state = AriaState.RelationalState.add_fact(state, "pattern", "analysis", analysis)
        {:ok, new_state}
      {:error, reason} -> 
        {:error, "Pattern analysis failed: #{reason}"}
    end
  end
  
  # Transformation hypothesis generation
  @action  
  def generate_transformation_hypothesis(state, %{input_grid: input, output_grid: output, search_insights: insights}) do
    prompt = build_hypothesis_generation_prompt(input, output, insights)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, hypotheses} ->
        new_state = AriaState.RelationalState.add_fact(state, "transformation", "hypotheses", hypotheses)
        {:ok, new_state}
      {:error, reason} ->
        {:error, "Hypothesis generation failed: #{reason}"}
    end
  end
  
  # Solution validation and confidence assessment
  @action
  def validate_solution_approach(state, %{approach: approach, test_grid: test_grid}) do
    pattern_analysis = AriaState.RelationalState.get_fact(state, "pattern", "analysis")
    search_results = AriaState.RelationalState.get_fact(state, "search", "results")
    
    prompt = build_validation_prompt(approach, test_grid, pattern_analysis, search_results)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, validation} ->
        new_state = AriaState.RelationalState.add_fact(state, "solution", "validation", validation)
        {:ok, new_state}
      {:error, reason} ->
        {:error, "Solution validation failed: #{reason}"}
    end
  end
end
```

### Search Intelligence and Constraint Management

```elixir
defmodule AriaArc.SearchState do
  defstruct [
    :blacklist,           # MapSet of impossible transformations
    :working_elements,    # Map of successful/promising transformations with scores
    :repetition_counts,   # Map tracking how many times each approach was tried
    :search_budget,       # Remaining search evaluations
    :accuracy_history     # List of {approach, accuracy} tuples
  ]
end

defmodule AriaArc.Domain do
  # Blacklist management for impossible transformations
  @action
  def update_search_blacklist(state, %{failed_transformations: failed, reason: reason}) do
    current_blacklist = AriaState.RelationalState.get_fact(state, "search", "blacklist") || MapSet.new()
    
    prompt = build_blacklist_update_prompt(failed, reason, current_blacklist)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, blacklist_update} ->
        updated_blacklist = apply_blacklist_update(current_blacklist, blacklist_update)
        new_state = AriaState.RelationalState.add_fact(state, "search", "blacklist", updated_blacklist)
        {:ok, new_state}
      {:error, reason} ->
        {:error, "Blacklist update failed: #{reason}"}
    end
  end
  
  # Working element repetition strategy
  @action
  def manage_working_elements(state, %{current_accuracy: accuracy, search_budget: budget}) do
    working_elements = AriaState.RelationalState.get_fact(state, "search", "working_elements") || %{}
    repetition_counts = AriaState.RelationalState.get_fact(state, "search", "repetition_counts") || %{}
    
    prompt = build_repetition_strategy_prompt(accuracy, budget, working_elements, repetition_counts)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, repetition_strategy} ->
        new_state = AriaState.RelationalState.add_fact(state, "search", "repetition_strategy", repetition_strategy)
        {:ok, new_state}
      {:error, reason} ->
        {:error, "Working element management failed: #{reason}"}
    end
  end
  
  # Constrained search with blacklist and repetition awareness
  @action
  def llm_guided_search_with_constraints(state, %{search_budget: budget, focus_area: focus}) do
    blacklist = AriaState.RelationalState.get_fact(state, "search", "blacklist") || MapSet.new()
    repetition_strategy = AriaState.RelationalState.get_fact(state, "search", "repetition_strategy")
    pattern_analysis = AriaState.RelationalState.get_fact(state, "pattern", "analysis")
    
    prompt = build_constrained_search_prompt(budget, focus, blacklist, repetition_strategy, pattern_analysis)
    
    case AriaArc.LlmBackend.call(prompt) do
      {:ok, search_plan} ->
        search_results = AriaArc.Search.execute_constrained_search(state, search_plan, blacklist)
        updated_state = update_search_tracking(state, search_results)
        {:ok, updated_state}
      {:error, reason} ->
        {:error, "Constrained search failed: #{reason}"}
    end
  end
end
```

### Complete Hybrid Workflow

```elixir
defmodule AriaArc.Domain do
  # Comprehensive ARC puzzle solving with LLM + Search + Constraints
  @unigoal_method
  def solve_arc_puzzle_hybrid(state, goal) do
    [
      # Phase 1: LLM Pattern Analysis
      {:action, :analyze_pattern, %{
        grid: goal.input_grid, 
        context: "Initial puzzle analysis for ARC challenge"
      }},
      
      # Phase 2: Initial constrained search
      {:action, :llm_guided_search_with_constraints, %{
        search_budget: 400,
        focus_area: "initial_exploration"
      }},
      
      # Phase 3: Learn from initial failures
      {:action, :update_search_blacklist, %{
        failed_transformations: {:state_fact, "search", "failed_approaches"},
        reason: "initial_exploration_failures"
      }},
      
      # Phase 4: Develop working element strategy
      {:action, :manage_working_elements, %{
        current_accuracy: {:state_fact, "search", "best_accuracy"},
        search_budget: 600
      }},
      
      # Phase 5: Focused search on promising approaches
      {:action, :llm_guided_search_with_constraints, %{
        search_budget: 300,
        focus_area: "working_element_refinement"
      }},
      
      # Phase 6: Generate hypotheses from search insights
      {:action, :generate_transformation_hypothesis, %{
        input_grid: goal.input_grid,
        output_grid: goal.expected_output,
        search_insights: {:state_fact, "search", "constrained_results"}
      }},
      
      # Phase 7: Validate hypotheses with targeted search
      {:action, :llm_guided_search_with_constraints, %{
        search_budget: 300,
        focus_area: "hypothesis_validation"
      }},
      
      # Phase 8: Final solution validation
      {:action, :validate_solution_approach, %{
        approach: {:state_fact, "search", "best_solution"},
        test_grid: goal.test_grid
      }},
      
      # Phase 9: Apply validated transformation
      {:action, :apply_transformation, %{
        transformation: {:state_fact, "solution", "validated_approach"},
        target_grid: goal.test_grid
      }}
    ]
  end
  
  # Enhanced multitodo optimization with search context
  @multitodo_method
  def execute_todo_list(state, todo_list) do
    search_context = extract_comprehensive_search_context(state)
    
    strategies = [
      # Strategy 1: LLM optimization with full search context
      fn -> AriaArc.LlmOptimizer.optimize_with_search_context(state, todo_list, search_context) end,
      
      # Strategy 2: MinZinC constraint optimization
      fn -> AriaMinizincGoal.optimize_todo_list(state, todo_list) end,
      
      # Strategy 3: Sequential fallback
      fn -> {:ok, AriaEngine.TodoExecution.sequential_todo_execution(state, todo_list)} end
    ]
    
    try_strategies_with_timeout(strategies, timeout: 30_000)
  end
end
```

## Prompt Engineering Templates

### Pattern Analysis Prompt

```elixir
defp build_pattern_analysis_prompt(grid, context) do
  """
  Analyze this ARC puzzle grid for visual and logical patterns:
  
  Grid: #{format_grid_for_llm(grid)}
  Context: #{context}
  
  Identify all observable patterns:
  1. **Symmetries**: rotation, reflection, translation patterns
  2. **Color patterns**: systematic color transformations, mappings, gradients
  3. **Shape relationships**: scaling, morphing, combining, splitting operations
  4. **Spatial constraints**: alignment, positioning, distance relationships
  5. **Object detection**: distinct objects, boundaries, groupings
  6. **Repetition patterns**: tiling, copying, extending, sequence patterns
  
  For each pattern type, provide:
  - Specific observations with grid coordinates
  - Confidence level (0-100)
  - Potential transformation rules
  - Edge cases or exceptions
  
  Return structured analysis focusing on patterns most likely to be the puzzle's core rule.
  """
end
```

### Constrained Search Prompt

```elixir
defp build_constrained_search_prompt(budget, focus, blacklist, repetition_strategy, pattern_analysis) do
  """
  Plan constrained search for ARC puzzle transformation discovery:
  
  **Search Parameters:**
  - Budget: #{budget} evaluations remaining
  - Focus Area: #{focus}
  - Pattern Analysis: #{format_pattern_analysis(pattern_analysis)}
  
  **Constraints:**
  - Blacklisted Approaches: #{format_blacklist_for_prompt(blacklist)}
  - Repetition Strategy: #{format_repetition_strategy(repetition_strategy)}
  
  **Search Plan Requirements:**
  1. Avoid all blacklisted transformation types and parameter ranges
  2. Follow repetition strategy for working elements (balance exploration vs exploitation)
  3. Allocate budget efficiently across different approach categories
  4. Prioritize approaches with highest accuracy improvement potential
  
  **Generate search plan with:**
  - Transformation types to explore (avoiding blacklist)
  - Specific parameter ranges and variations to test
  - Budget allocation: X% for exploration, Y% for exploitation
  - Expected accuracy improvement for each approach category
  - Risk assessment for each planned approach
  
  Focus on strategies most likely to beat 34% llm baseline performance.
  """
end
```

## Configuration and Dependencies

### Dependencies

Add to `aria_arc/mix.exs`:

```elixir
defp deps do
  [
    {:httpoison, "~> 2.0"},
    {:jason, "~> 1.4"},
    # ... existing deps
  ]
end
```

### Configuration

Add to `aria_arc/config/config.exs`:

```elixir
import Config

config :aria_arc,
  # LLM backend configuration
  openrouter_api_key: System.get_env("OPENROUTER_API_KEY"),
  qwen3_binary_path: System.get_env("QWEN3_PATH") || "qwen3-chat",
  
  # Model preferences
  openrouter_models: [
    "qwen/qwen-2.5-7b-instruct",      # Primary: fast, good reasoning
    "anthropic/claude-3.5-sonnet",    # Premium: advanced reasoning
    "meta-llama/llama-3.1-8b-instruct" # Alternative: reliable fallback
  ],
  
  # Search configuration
  default_search_budget: 1000,
  blacklist_persistence: true,
  working_element_threshold: 0.1  # Minimum accuracy to consider "working"
```

## Success Criteria

### Phase 2 Success Metrics

- [ ] **LLM Actions Functional**: All three core actions (analyze, generate, validate) working
- [ ] **Search Intelligence**: Blacklist and working element management operational
- [ ] **Constraint Compliance**: Implementation fits within R25W1327B64's 2-app limit
- [ ] **Integration Success**: LLM actions coordinate with Phase 1 search results
- [ ] **Accuracy Contribution**: Measurable improvement toward 5%+ target

### Overall ARC Prize Contribution

- [ ] **Hybrid Workflow**: Complete LLM + computational + optimization pipeline functional
- [ ] **Efficiency Gains**: Blacklist reduces wasted computation on impossible approaches
- [ ] **Intelligence Enhancement**: LLM reasoning improves search strategy and solution quality
- [ ] **Go/No-Go Input**: Clear contribution to 5%+ accuracy decision for full competition

## Risk Mitigation

### Technical Risks

1. **LLM API Reliability**: OpenRouter API failures
   - **Mitigation**: Local Qwen3 fallback backend
2. **Prompt Engineering**: Inconsistent LLM responses
   - **Mitigation**: Structured prompts with validation and retry logic
3. **Search Complexity**: Constraint management overhead
   - **Mitigation**: Simple blacklist/working element data structures

### Integration Risks

1. **Timeline Pressure**: Phase 2 is only 4 days
   - **Mitigation**: Prioritize core LLM actions, defer advanced features
2. **Scope Creep**: Feature expansion beyond 2-app limit
   - **Mitigation**: Strict adherence to R25W1327B64 constraints
3. **Performance**: LLM calls may slow down search
   - **Mitigation**: Async LLM calls, timeout management

## Related ADRs

- **R25W1298CE1**: Hybrid Planner Complete Restoration and Standardization (prerequisite)
- **R25W130E6A7**: ARC Prize 2025 - Two-Week Proof of Concept Sprint (masthead)
- **R25W131C16E**: ARC Prize Implementation Plan (timeline integration)
- **R25W1327B64**: ARC Prize Technical Architecture (scope constraints)
- **R25W133C875**: ARC Prize Risk Analysis (risk context)
- **R25W1398085-184**: Unified Action Specification and Multitodo Methods (foundation)

## Consequences

**If Successful:**

- LLM becomes intelligent reasoning partner in ARC puzzle solving
- Search efficiency dramatically improved through blacklist and working element management
- Hybrid approach combines best of computational search and LLM reasoning
- Significant contribution to beating 34% llm success rate
- Establishes pattern for LLM integration in complex problem-solving domains

**If Failed:**

- Fallback to computational search + MinZinc optimization still available
- Learning value in LLM integration approaches for future work
- No impact on core ARC Prize computational foundation from Phase 1

This implementation transforms the LLM from a simple optimization tool into an intelligent reasoning partner that guides search, learns from failures, and contributes directly to puzzle-solving success.

---

**R25W148122A Status: PAUSED** - Awaiting completion of R25W1298CE1 and Phase 1 of ARC Prize sprint before implementation.
