# ADR-169: ARC Prize 2025 Technical Architecture

**Status:** Proposed  
**Date:** June 24, 2025  
**Priority:** HIGH  
**Parent ADR:** ADR-166 (ARC Prize 2025 - Two-Week Proof of Concept Sprint)

## Context

This ADR defines the complete technical architecture for the ARC Prize 2025 solution, structured as minimal viable architecture for the two-week sprint followed by full architecture for conditional implementation. The immediate focus is on rapid validation architecture that implements the Bitter Lesson principles defined in ADR-166.

## Phase 1: Evidence-Based Sprint Architecture (Maximum Scope)

**Critical Evidence:** Based on git history showing 40+ commits of architectural planning with zero implementation on June 24, 2025, the sprint architecture enforces strict scope limits to prevent analysis paralysis.

### Sprint Architecture Constraints

**Mandatory Scope Limits:**
- **2 apps maximum:** `aria_grid` + `aria_arc_coordinator` only
- **No architectural expansion:** Without proven implementation necessity
- **Implementation gates:** Working code required before any design changes
- **Complexity budget:** Each additional feature requires 2x timeline extension

**Evidence-Based App Structure:**

```
apps/
1. aria_grid/                       # Foundation Layer (MINIMAL)
│   ├── lib/aria_grid/
│   │   ├── grid.ex                 # Basic grid representation only
│   │   ├── transformations.ex      # 3 transformations: rotate, mirror, translate
│   │   └── arc_loader.ex           # ARC JSON task loading only
│   └── mix.exs
2. aria_arc_coordinator/            # Coordination Layer (MINIMAL)
    ├── lib/aria_arc_coordinator/
    │   ├── coordinator.ex          # Basic task orchestration
    │   ├── search_engine.ex        # Simple brute force search (10-50 sequences)
    │   ├── task_runner.ex          # ARC task processing
    │   └── validation.ex           # Basic accuracy measurement
    └── mix.exs
```

**Integration with Existing Aria (NO CHANGES):**

- **All existing apps:** No modifications during sprint
- **No integration:** Until basic functionality proven
- **No dependencies:** Sprint apps must be self-contained

### Evidence-Based Success Criteria

- **1%+ accuracy with working system:** Proceed to extended development
- **<0.5% accuracy or no working system:** Stop, valuable learning achieved
- **Working system priority:** Functionality over performance optimization

---

## Phase 2: Full Competition Architecture (Conditional Implementation)

**Activation Trigger:** Sprint achieves ≥5% accuracy
**Timeline:** 3-6 months of focused development
**Scope:** Complete 6-app umbrella architecture with full integration

### Evidence-Based Architecture Planning

**Development Velocity Analysis:**
- Git history shows heavy iteration cycles for complex features
- No actual umbrella apps created yet - all planning phase
- Integration complexity requires 3-5x longer than initial estimates
- Parallel development needed to meet competition timeline

## Why Aria is Perfect for ARC

Aria already has the key components needed for ARC:

- **Hybrid Planning** - Coordinates multiple solving approaches
- **Grid Reasoning** - Handles spatial transformations naturally  
- **Pattern Learning** - Discovers rules from examples
- **Strategy Coordination** - Combines different reasoning methods
- **Constraint Solving** - Handles complex spatial relationships

These existing capabilities provide a strong foundation for building an ARC solver that can leverage both symbolic reasoning (through the planning system) and neural approaches (through LLM integration) in a coordinated hybrid architecture.

## Technical Architecture

### Umbrella App Structure

Following Aria's established modular architecture, the ARC solver is decomposed into focused, single-responsibility apps (topological order):

```
apps/
1. aria_grid/                       # Foundation Layer (no internal deps)
│   ├── lib/aria_grid/
│   │   ├── grid.ex                 # Core grid representation
│   │   ├── transformations.ex      # Basic transformations (minimal set)
│   │   ├── pattern_matching.ex     # Shape detection and extraction
│   │   ├── color_mapping.ex        # Color transformations
│   │   └── spatial_analysis.ex     # Discrete 2D grid relationship analysis
│   └── mix.exs
2. aria_arc_domain/                 # ARC Planning Domain Layer (LEARNED CONTENT)
│   ├── lib/aria_arc_domain/
│   │   ├── domain.ex               # Module-based domain definition (ADR-133)
│   │   ├── action_synthesis.ex     # Generate actions through program synthesis
│   │   ├── method_learning.ex      # Learn planning methods from traces
│   │   ├── rule_discovery.ex       # Discover domain rules from feedback
│   │   ├── ast_executor.ex         # Execute learned code as data
│   │   ├── domain_evolution.ex     # Evolve domain through computational feedback
│   │   └── planner_interface.ex    # Standard interface to aria_hybrid_planner
│   └── mix.exs
3. aria_pattern_library/            # Pattern Analytics Layer (depends on aria_grid)
│   ├── lib/aria_pattern_library/
│   │   ├── duckdb_store.ex         # DuckDB analytics and discovery
│   │   ├── sqlite_store.ex         # SQLite competition runtime
│   │   ├── pattern_matcher.ex      # Template-based recognition
│   │   ├── analytics.ex            # Success rates and composition
│   │   ├── export.ex               # Parquet export for research
│   │   ├── pipeline.ex             # DuckDB ↔ SQLite data flow
│   │   ├── synthetic_data.ex       # Synthetic task generation
│   │   └── data_validation.ex      # Generated data quality assurance
│   └── mix.exs
4. aria_llm_client/                 # External Integration Layer (external deps only)
│   ├── lib/aria_llm_client/
│   │   ├── openrouter.ex           # OpenRouter client
│   │   ├── prompting.ex            # Model-specific prompts
│   │   ├── response_parser.ex      # Response validation
│   │   ├── ensemble.ex             # Multi-model coordination
│   │   └── api_management.ex       # API rate limiting and health monitoring
│   └── mix.exs
5. aria_program_synthesis/          # Reasoning Layer (depends on grid, domain, patterns)
│   ├── lib/aria_program_synthesis/
│   │   ├── search.ex               # Discrete program search
│   │   ├── constraints.ex          # Constraint-based synthesis
│   │   ├── optimization.ex         # Search space optimization
│   │   ├── validation.ex           # Program scoring
│   │   └── training.ex             # Active inference and model adaptation
│   └── mix.exs
6. aria_arc_coordinator/            # Orchestration Layer (depends on all others + existing Aria apps)
    ├── lib/aria_arc_coordinator/
    │   ├── coordinator.ex          # Main orchestration
    │   ├── strategy_factory.ex     # Strategy management
    │   ├── ensemble_voting.ex      # Result aggregation
    │   ├── task_loader.ex          # ARC task processing
    │   ├── testing.ex              # Testing and validation
    │   ├── competition.ex          # Competition packaging and compliance
    │   └── visualization.ex        # Debug visualization and analysis
    └── mix.exs
```

### App Dependencies

**Dependency Hierarchy (ordered by dependency depth):**

```
1. aria_grid
   └── (foundation layer - no internal deps)

2. aria_arc_domain
   └── aria_grid

3. aria_pattern_library
   └── aria_grid

4. aria_llm_client
   └── (external dependencies only)

5. aria_hybrid_planner (existing)
   └── aria_arc_domain (for ARC planning domain integration)

6. aria_program_synthesis
   ├── aria_grid
   ├── aria_arc_domain
   └── aria_pattern_library

7. aria_arc_coordinator
   ├── aria_grid
   ├── aria_arc_domain
   ├── aria_llm_client
   ├── aria_pattern_library
   ├── aria_program_synthesis
   ├── aria_hybrid_planner (existing)
   ├── aria_temporal_planner (existing)
   ├── aria_membrane_pipeline (existing)
   ├── aria_minizinc (existing)
   └── aria_engine_core (existing)
```

## Computational Learning Domain Architecture

**ARC Planning Domain:** The `aria_arc_domain` app contains ARC-specific planning actions, methods, and rules that integrate with `aria_hybrid_planner`. Following the Bitter Lesson, the domain content is **learned through computation** rather than hand-crafted, using program synthesis to discover actions, pattern analysis to learn methods, and feedback to evolve rules.

### Module-Based Domain (Following ADR-133 Solution)

```elixir
defmodule AriaArcDomain do
  use AriaEngine.Domain
  
  @domain_name "arc_reasoning"
  @description "ARC domain with learned transformations"
  
  # LEARNED ACTIONS (generated through program synthesis)
  @action duration: "PT0.1S"  # Instant grid transformations
  def rotate_90(state, [grid_id]) do
    # Implementation discovered through search
    new_state = StateV2.set_fact(state, grid_id, "orientation", "rotated_90")
    {:ok, new_state}
  end
  
  @action duration: "PT0.1S"
  def discovered_pattern_transform_1(state, [grid_id, pattern_params]) do
    # Action discovered through program synthesis
    # Implementation learned from successful ARC solutions
    case apply_learned_transformation(state, grid_id, pattern_params) do
      {:ok, new_state} -> {:ok, new_state}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # LEARNED UNIGOAL METHODS (pattern-driven decomposition)
  @unigoal_method goal_pattern: {"grid", "solved", :any}
  def achieve_grid_solution(state, {"grid", "solved", target_pattern}) do
    # Method learned from successful solution traces
    {:ok, [
      {"task_identify_pattern", [target_pattern]},
      {"task_apply_transformation", [target_pattern]},
      {"task_validate_solution", [target_pattern]}
    ]}
  end
  
  # LEARNED TASK METHODS (discovered through search)
  @task_method
  def task_identify_pattern(state, [pattern]) do
    # Method learned from pattern analysis
    if pattern_recognizable?(state, pattern) do
      {:ok, [
        {:analyze_colors, [pattern]},
        {:detect_shapes, [pattern]},
        {:find_symmetries, [pattern]}
      ]}
    else
      {:error, :pattern_not_recognizable}
    end
  end
  
  # MULTIGOAL METHODS (constraint-based optimization)
  @multigoal_method goal_patterns: [{"grid", "pattern", :any}, {"grid", "transformation", :any}]
  def optimize_pattern_and_transform(state, goals) do
    # Use MiniZinc to optimize multiple grid constraints simultaneously
    {:ok, [
      "achieve_pattern_recognition",  # Unigoal method
      "achieve_transformation_sequence"  # Unigoal method  
    ]}
  end
end
```

### Action Discovery Engine

```elixir
# In aria_arc_domain/action_synthesis.ex
defmodule AriaArcDomain.ActionSynthesis do
  def discover_new_actions(successful_traces, current_domain) do
    # Program synthesis to find new grid transformations
    # Generate thousands of candidate actions
    # Test against ARC training data
    # Add successful actions to domain as AST
    
    new_actions = 
      successful_traces
      |> extract_transformation_patterns()
      |> synthesize_action_candidates()
      |> validate_against_training_data()
      |> convert_to_domain_actions()
    
    # Dynamically add to domain using correct syntax
    Enum.reduce(new_actions, current_domain, fn {name, impl, metadata}, domain ->
      Domain.add_method(domain, name, impl, %{type: :action, duration: metadata.duration})
    end)
  end
end
```

### Method Learning from Traces

```elixir
# In aria_arc_domain/method_learning.ex
defmodule AriaArcDomain.MethodLearning do
  def learn_methods_from_solutions(solution_traces) do
    # Analyze successful planning episodes
    # Extract common decomposition patterns
    # Generate new unigoal and task methods
    
    learned_methods =
      solution_traces
      |> identify_successful_decompositions()
      |> extract_method_patterns()
      |> generate_method_implementations()
      |> validate_method_effectiveness()
    
    # Return methods in correct domain format
    Enum.map(learned_methods, fn {name, impl, type} ->
      case type do
        :unigoal -> {name, impl, %{type: :unigoal, goal_pattern: extract_goal_pattern(impl)}}
        :task -> {name, impl, %{type: :task}}
        :multigoal -> {name, impl, %{type: :multigoal, goal_patterns: extract_goal_patterns(impl)}}
      end
    end)
  end
end
```

### Bitter Lesson Integration: Computational Domain Evolution

**Stage 1: Computational Domain Bootstrap**

- Massive program synthesis to discover action space (10,000+ candidates)
- Generate transformation actions through search, not hand-coding
- Learn which combinations work through computational validation

**Stage 2: Pattern-Driven Method Learning**

- Analyze successful solution traces to learn planning methods
- Generate unigoal methods that capture successful reasoning patterns
- Use learning to discover domain structure, not engineer it

**Stage 3: Rule Evolution Through Feedback**

- Learn domain rules from planning success/failure
- Evolve preconditions and effects through experience
- Use computational feedback to refine domain knowledge

**Key Insight: Domain as Learned Interface**

The domain becomes the **computational learning interface** between:

- **Raw search/synthesis** (discovers transformations)
- **Pattern learning** (discovers methods)
- **Constraint optimization** (discovers rules)
- **Structured planning** (coordinates learned strategies)

This preserves our proven planner architecture while making the domain content itself the product of massive computation and learning, exactly as the Bitter Lesson suggests.

## Integration with Existing Aria Apps

### **`aria_hybrid_planner` (Strategy Coordination Only)**

**Core Responsibility:** Coordinate multiple strategies (unchanged)

**Minimal ARC Integration:**

- Add ARC strategy types to existing strategy factory
- Coordinate between aria_program_synthesis, aria_llm_client, and aria_dsl strategies
- Use existing ensemble coordination for ARC result voting

**What it does NOT do:** Grid reasoning, pattern analysis, active inference management

### **`aria_temporal_planner` (Temporal Planning Only)**

**Core Responsibility:** Plan sequences over time (unchanged)

**Minimal ARC Integration:**

- Accept grid transformation sequences as temporal planning input
- Optimize transformation order using existing temporal algorithms
- Output optimized sequence plans to aria_arc_coordinator

**What it does NOT do:** Pattern learning, spatial reasoning, constraint propagation

### **`aria_membrane_pipeline` (Data Pipeline Only)**

**Core Responsibility:** Process data through pipelines (unchanged)

**Minimal ARC Integration:**

- Add ARC task format as pipeline input type
- Process grid data through existing pipeline stages
- Output processed results to aria_arc_coordinator

**What it does NOT do:** Synthetic data generation, model training, competition packaging

### **`aria_minizinc` (Constraint Solving Only)**

**Core Responsibility:** Solve constraint satisfaction problems (unchanged)

**Minimal ARC Integration:**

- Accept grid constraint problems from aria_program_synthesis
- Solve using existing MiniZinc constraint engine
- Return solutions to requesting ARC apps

**What it does NOT do:** Ensemble optimization, pattern composition, resource allocation

### **`aria_engine_core` (Core Infrastructure Only)**

**Core Responsibility:** Provide shared infrastructure (unchanged)

**Minimal ARC Integration:**

- Add grid data structures to existing state management
- Provide shared utilities for ARC apps
- Maintain existing interface patterns

**What it does NOT do:** ARC-specific logic, strategy coordination, performance monitoring

## Multi-LLM Architecture

### OpenRouter Integration

**Model Diversity Strategy:**

- Primary: GRPO-fine-tuned Qwen3 for ARC-specific reasoning
- Secondary: GPT-4, Claude, Gemini for ensemble diversity
- Specialized prompting strategies per model type
- Cross-model validation and quality assurance

**GRPO Fine-Tuning Pipeline:**

```elixir
# In aria_llm_client/qwen3_fine_tuning.ex
defmodule AriaLLMClient.Qwen3FineTuning do
  def fine_tune_on_arc_data(computational_discovery_data) do
    # Use GRPO methodology for critic-less learning
    # Train on successful solution traces from Stages 1-3
    # Constrain output to valid temporal planning sequences
    # Score shorter successful sequences higher (information-theoretic compression)
    
    training_data = 
      computational_discovery_data
      |> extract_successful_solutions()
      |> convert_to_planning_sequences()
      |> add_grpo_scoring(fn sequence -> 
        case {sequence.success, length(sequence.actions)} do
          {true, action_count} -> 1.0 / action_count  # Shorter = better
          {false, _} -> 0.0
        end
      end)
    
    # Fine-tune using GRPO group-relative optimization
    GRPO.fine_tune(qwen3_model, training_data, %{
      group_comparison: :relative_scoring,
      output_constraint: :temporal_planning_sequences,
      validation: :planning_engine_execution
    })
  end
end
```

**Competition Compliance:**

- All LLM usage during development and training phases only
- Final submission runs completely offline
- No internet access during competition evaluation
- Self-contained model weights and dependencies

## Synthetic Data Generation Strategy

### Pattern Extraction Architecture

```elixir
# In aria_pattern_library/synthetic_data.ex
defmodule AriaPatternLibrary.SyntheticData do
  def generate_arc_tasks(pattern_library, count \\ 10_000) do
    # Extract patterns from successful solutions
    base_patterns = PatternLibrary.get_successful_patterns(pattern_library)
    
    # Generate variations using computational methods
    Enum.flat_map(1..count, fn _ ->
      base_pattern = Enum.random(base_patterns)
      
      # Generate multiple variations of each pattern
      [
        vary_colors(base_pattern),
        vary_size(base_pattern),
        vary_orientation(base_pattern),
        combine_patterns(base_pattern, Enum.random(base_patterns))
      ]
    end)
    |> validate_task_quality()
    |> filter_duplicates()
  end
  
  defp validate_task_quality(tasks) do
    # Ensure generated tasks follow ARC principles
    # Check for solvability and appropriate difficulty
    # Validate against known ARC patterns
    Enum.filter(tasks, &valid_arc_task?/1)
  end
end
```

### Multi-Model Generation

**Generation Pipeline:**

- Different LLMs generate diverse task variations
- Cross-model validation ensures quality
- Adversarial generation finds challenging cases
- Human expert integration for pattern validation

### Quality Assurance

**Validation Framework:**

- Automated validation against ARC principles
- Cross-model consistency checking
- Difficulty calibration and progression
- Overfitting prevention through diversity metrics

## Information-Theoretic Architecture

### GRPO Scoring Integration

```elixir
# In aria_pattern_library/grpo_learning.ex (existing)
defmodule AriaPatternLibrary.GRPOLearning do
  def compare_solution_groups(solutions_group_a, solutions_group_b) do
    # Natural information-theoretic scoring:
    # Shorter sequences that solve the task = higher score
    # Longer sequences that solve the task = lower score
    # Failed sequences = lowest score
    
    score_a = calculate_group_score(solutions_group_a)
    score_b = calculate_group_score(solutions_group_b)
    
    # GRPO learns to prefer shorter, more compressed solutions
    {score_a, score_b}
  end
  
  defp calculate_group_score(solutions) do
    solutions
    |> Enum.map(fn solution ->
      case solution.result do
        :success -> 1.0 / length(solution.action_sequence)  # Shorter = better
        :failure -> 0.0
      end
    end)
    |> Enum.sum()
    |> Kernel./(length(solutions))
  end
end
```

### Automatic Compression Benefits

**Natural Selection for Information Density:**

- GRPO compares groups of planning sequences for the same ARC task
- Shorter sequences that achieve correct results score higher than longer sequences
- GRPO learning naturally biases toward information-dense, minimal action sequences
- MiniZinc optimization provides additional automatic compression
- Interpretability emerges through forced compression to essential reasoning steps

## Tombstoned Approaches

### Physics Engine Integration (Rejected)

**Considered:** Integrating physics engines like MuJoCo for spatial analysis in `aria_grid`

**Rejection Rationale:**

- **Wrong abstraction level:** ARC problems are discrete 2D grid reasoning, not continuous physics simulation
- **Massive over-engineering:** Physics engines designed for 3D rigid body dynamics, collision detection, and force calculations
- **Computational overhead:** Unnecessary complexity for simple grid adjacency and pattern matching
- **Integration complexity:** Would add significant dependencies and maintenance burden
- **Mismatched requirements:** ARC needs discrete symbolic reasoning (adjacency, containment, pattern matching), not physics simulation

**Correct Approach:** Lightweight algorithmic spatial analysis with MiniZinc for complex constraint satisfaction when needed.

### Infinite App Decomposition (Rejected)

**Considered:** Continuously decomposing functionality into additional specialized apps (aria_arc_testing, aria_arc_competition, aria_arc_viz, aria_arc_datagen, aria_arc_training, aria_arc_config, etc.)

**Rejection Rationale:**

- **Analysis paralysis:** Infinite decomposition prevents actual implementation progress
- **Time constraints:** Competition deadline requires execution focus, not architectural perfection
- **Integration complexity:** Each additional app adds exponential integration testing burden
- **Diminishing returns:** Beyond 6 apps, additional decomposition adds overhead without benefit
- **Resource allocation:** Development time better spent on implementation than architecture refinement

**Final Architecture Decision:** **6 apps maximum** with expanded responsibilities per app to handle secondary concerns. No further decomposition permitted.

**Locked Architecture:**

1. `aria_grid` - Foundation grid operations
2. `aria_arc_domain` - ARC planning domain
3. `aria_llm_client` - External integration + API management
4. `aria_pattern_library` - Pattern analytics + synthetic data generation
5. `aria_program_synthesis` - Reasoning + search + training
6. `aria_arc_coordinator` - Orchestration + testing + competition + visualization

**Implementation Focus:** Build these 6 apps with expanded scope rather than creating additional specialized apps.

## Related ADRs

- **ADR-166**: ARC Prize 2025 Core Strategy (parent ADR)
- **ADR-168**: ARC Prize Implementation Plan
- **ADR-170**: ARC Prize Risk Analysis
- **ADR-036**: Evolving AriaEngine Planner Blueprint
- **ADR-112**: Hybrid Coordinator V3 Implementation
- **ADR-133**: Planner Standardization Open Problems
- **ADR-148**: Membrane Planning System Implementation
- **ADR-151**: Strict Encapsulation and Modular Testing Architecture

## Consequences

### Positive

- **Modular Architecture:** Clean separation of concerns enables independent development and testing
- **Computational Learning:** Domain content discovered through computation rather than engineering
- **Interpretable Execution:** Neural reasoning channeled through interpretable temporal planning
- **Scalable Integration:** Minimal changes to existing Aria apps preserve stability

### Negative

- **Integration Complexity:** 6 new apps + 5 existing apps = complex integration testing
- **Dependency Management:** Careful coordination required for app interdependencies
- **Learning Uncertainty:** Computational domain discovery may not produce effective results
- **Resource Requirements:** Significant computational resources needed for learning phases

### Neutral

- **Architecture Validation:** Tests Aria's umbrella app approach on complex reasoning tasks
- **Research Contribution:** Novel hybrid symbolic-neural architecture for abstract reasoning
- **Technology Transfer:** Components useful for other reasoning applications
- **Community Engagement:** Positions Aria in AI research community

This technical architecture provides a solid foundation for implementing the ARC Prize solution while maintaining the flexibility to adapt based on computational learning results and competition requirements.
