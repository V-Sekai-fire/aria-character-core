# ADR-166: ARC Prize 2025 Core Strategy

**Status:** Proposed  
**Date:** June 24, 2025  
**Priority:** HIGH

## Context

### The Challenge

The ARC Prize 2025 offers $1,000,000 for creating an AI system capable of solving grid transformation puzzles with few-shot learning: given 2-3 examples of a grid transformation puzzle, the AI must understand the underlying rule and apply it to solve new puzzles it's never seen before.

**Current State-of-the-Art:** 34% accuracy using active inference with language models

**The Core Challenge:** Grid transformation puzzles with few-shot learning - exactly the kind of hybrid symbolic-neural reasoning that Aria's architecture is designed for.

### Why Aria is Perfect for This Challenge

Aria's existing architecture provides an exceptional foundation for ARC:

- **Hybrid Planning System** - Coordinates multiple solving approaches simultaneously
- **Temporal Reasoning** - Handles sequences of grid transformations naturally
- **Constraint Solving** - MiniZinc integration for complex spatial relationships
- **Strategy Factory** - Pluggable reasoning approaches with ensemble coordination
- **Pipeline Processing** - Efficient data processing and validation
- **State Management** - Grid representation and transformation tracking

**Key Insight:** Aria's hybrid symbolic-neural architecture directly addresses ARC's core requirements while providing interpretable execution traces.

## Decision

### Simple Version

We're going to build a super-smart puzzle solver using Aria's existing tools, but following the "Bitter Lesson" principle: start with massive computation and learning, then add coordination and fallbacks.

### Technical Version

Develop a comprehensive ARC solver leveraging Aria's existing architecture through a computation-first approach: massive program synthesis and pattern learning drive domain discovery, with hybrid planning coordinating learned strategies rather than hand-crafted rules.

### Implementation Strategy

Create a learning-driven system where computational search discovers grid transformations, pattern analysis learns planning methods, and the hybrid planner coordinates learned strategies. The domain itself becomes the product of computation rather than human engineering.

### Bitter Lesson Integration

Following Rich Sutton's "Bitter Lesson," we prioritize:
1. **Computation over cleverness** - Massive search spaces over hand-crafted heuristics
2. **Learning over engineering** - Discovered patterns over pre-defined transformations  
3. **Scale over optimization** - More data and search over algorithmic efficiency
4. **General methods** - Learning and search that can discover domain structure

### Computational Discovery + Interpretable Execution

**The Key Architectural Insight:** We achieve the best of both worlds by using massive computation to discover what works, then channeling that knowledge through interpretable temporal planning execution.

**How It Works:**
- **Stages 1-3:** Computational discovery finds transformation patterns, learns domain actions, and discovers planning methods through massive search and GRPO learning
- **Stage 4:** GRPO-fine-tuned Qwen3 generates temporal planning sequences using computationally discovered vocabulary
- **Execution:** Temporal planner executes sequences with full interpretability, automatic MiniZinc optimization, and validation

**Competitive Advantages:**
- **Neural Power:** GRPO fine-tuning leverages critic-less reinforcement learning for ARC-specific reasoning
- **Computational Scale:** Massive search discovers patterns humans would hand-code
- **Interpretable Output:** All solutions become human-readable temporal planning sequences
- **Automatic Optimization:** Existing temporal planner provides MiniZinc constraint optimization for free
- **Error Detection:** Planning engine validates neural reasoning and catches errors through execution failure

**Example Flow:**
```
ARC Task → GRPO-Fine-Tuned Qwen3 → Temporal Planning Sequence → MiniZinc Optimization → Interpretable Execution Trace
```

This creates solutions that are both computationally discovered (following the Bitter Lesson) and fully interpretable (through temporal planning), giving judges clear reasoning chains while maintaining computational advantages.

### Information-Theoretic Compression Through GRPO

**Natural Shannon Information Reduction:** By scoring shorter successful planning sequences higher in GRPO group comparisons, we achieve automatic information-theoretic compression without explicit entropy calculations.

**How It Works:**
- GRPO compares groups of planning sequences for the same ARC task
- Shorter sequences that achieve correct results score higher than longer sequences
- GRPO learning naturally biases toward information-dense, minimal action sequences
- MiniZinc optimization provides additional automatic compression
- Interpretability emerges through forced compression to essential reasoning steps

**Information-Theoretic Benefits:**
- **Natural Quality Metric:** Shorter successful sequences indicate better pattern understanding
- **Automatic Compression:** GRPO drives toward minimal, information-dense solutions
- **Enhanced Interpretability:** Compressed sequences contain only essential reasoning steps
- **Computational Efficiency:** Shorter sequences require less execution time and resources

This approach achieves Shannon information theory principles through simple GRPO scoring preferences, creating natural selection for high-information-content solutions without complex validation systems.

## Implementation Plan: "Bicycle to Car" Progression (Bitter Lesson Aligned)

Following the Bitter Lesson, we prioritize computation and learning from Stage 1, building complete working systems that emphasize search and learning over hand-crafted engineering.

### Stage 1: "Skateboard" - Massive Search Foundation (Size: M, 1-2 weeks)

#### What We're Building (Simple)

Start with the most computational approach - massive program synthesis search - like building a skateboard with a rocket engine.

#### Computational Search Core (Technical)

Create computation-heavy foundation:

- [ ] Create `aria_grid` app with basic grid representation
- [ ] Create `aria_program_synthesis` app as PRIMARY strategy (not auxiliary)
- [ ] Implement discrete program search with huge search spaces (10,000+ candidates)
- [ ] Generate transformation programs through brute force search
- [ ] Create `aria_arc_coordinator` for basic task loading and search coordination
- [ ] Use computational validation against training examples (no hand-crafted rules)

#### Bitter Lesson Implementation (Technical)

Prioritize computation over cleverness:

- [ ] Massive search space generation (prioritize breadth over efficiency)
- [ ] Brute force program validation (test everything, keep what works)
- [ ] Minimal human knowledge injection (basic grid operations only)
- [ ] Scale through computation, not heuristics
- [ ] Random baseline as fallback only

#### Success Criteria (Measurable)

- [ ] Can generate and test 1000+ transformation programs per task
- [ ] Achieves 1-5% ± 2% accuracy through pure computational search
- [ ] Search space demonstrably larger than hand-crafted approaches
- [ ] Shows that computation can discover patterns humans would hand-code
- [ ] Establishes computational foundation for all future stages

#### Why This Matters (Expert)

Validates the Bitter Lesson principle immediately. Proves that massive search can discover transformations without human engineering. Establishes computational scale as the foundation rather than an afterthought.

### Stage 2: "Bicycle" - Learning-Driven Pattern Discovery (Size: M, 2-3 weeks)

#### What We're Adding (Simple)

Add massive pattern learning to guide the search - like adding smart navigation to our rocket-powered skateboard.

#### Pattern Learning Core (Technical)

Create learning-driven pattern discovery:

- [ ] Create `aria_pattern_library` app as CORE component (not auxiliary)
- [ ] Implement massive pattern extraction from successful searches
- [ ] Learn transformation patterns from computational discoveries
- [ ] Generate synthetic training data at scale (thousands of examples)
- [ ] Use pattern learning to guide program synthesis search
- [ ] Implement pattern-based search space pruning through learning

#### Computational Learning Integration (Technical)

Scale learning through computation:

- [ ] Generate 10,000+ synthetic ARC tasks for pattern learning
- [ ] Learn pattern-to-transformation mappings from search results
- [ ] Use learning to bias search toward successful pattern types
- [ ] Implement pattern similarity clustering through computation
- [ ] Scale pattern discovery through brute force analysis

#### Success Criteria (Measurable)

- [ ] May achieve 5-10% ± 3% accuracy through learned pattern guidance
- [ ] Pattern library contains 1000+ discovered transformation patterns
- [ ] Learning demonstrably improves search efficiency and success rate
- [ ] Shows computational pattern discovery outperforming hand-crafted patterns
- [ ] Synthetic data generation produces valid ARC-like tasks

### Stage 3: "Scooter" - Computational Domain Learning (Size: M, 2-3 weeks)

#### What We're Building (Simple)

Let computation discover the planning domain structure - like adding an AI brain that learns how to coordinate the rocket engine.

#### Learned Domain Architecture (Technical)

Create computationally discovered domain:

- [ ] Create `aria_arc_domain` app with LEARNED content (not hand-crafted)
- [ ] Implement action synthesis engine to discover grid transformations
- [ ] Learn planning methods from successful search traces
- [ ] Generate domain rules through computational feedback
- [ ] Integrate learned domain with `aria_hybrid_planner`
- [ ] Use AST execution for runtime domain modification

#### Computational Domain Discovery (Technical)

Discover domain structure through search and learning:

- [ ] Generate thousands of candidate actions through program synthesis
- [ ] Learn unigoal methods from successful solution decompositions
- [ ] Discover task methods through pattern analysis of search traces
- [ ] Evolve domain rules through computational feedback loops
- [ ] Use learning to discover optimal action compositions

#### Success Criteria (Measurable)

- [ ] May achieve 8-15% ± 3% accuracy through learned domain coordination
- [ ] Domain contains 100+ learned actions discovered through search
- [ ] Planning methods learned from computational traces, not engineered
- [ ] Shows learned domain outperforming hand-crafted domain rules
- [ ] Demonstrates computational discovery of planning structure

### Stage 4: "Motorcycle" - GRPO-Fine-Tuned Neural Reasoning (Size: M, 2-3 weeks)

#### What We're Adding (Simple)

Scale up neural computation with GRPO-fine-tuned Qwen3 as primary reasoner, generating interpretable planning sequences - like adding a smart rocket engine that explains its decisions.

#### GRPO-Fine-Tuned Qwen3 Primary Strategy (Technical)

Leverage DeepSeek's critic-less reinforcement learning architecture:

- [ ] Create `aria_llm_client` app with Qwen3 as primary neural reasoner
- [ ] Fine-tune Qwen3 on ARC tasks using GRPO methodology and computational discovery data
- [ ] Constrain Qwen3 output to valid temporal planning sequences for interpretability
- [ ] Use critic-less learning to avoid reward engineering problems
- [ ] Generate ARC-specific training data from computational discovery phases (Stages 1-3)
- [ ] Implement ensemble with other models (GPT-4, Claude) as secondary strategies

#### Interpretable Neural-Symbolic Bridge (Technical)

Force neural reasoning through interpretable execution:

- [ ] Train Qwen3 to output valid temporal planning sequences using learned domain vocabulary
- [ ] Constrain neural output to planning actions discovered through computational search
- [ ] Leverage existing temporal planner's MiniZinc optimization for automatic plan compression
- [ ] Generate interpretable execution traces from neural reasoning decisions
- [ ] Validate neural reasoning through planning engine execution
- [ ] Use planning validation to catch and correct neural reasoning errors

#### Success Criteria (Measurable)

- [ ] May achieve 12-20% ± 4% accuracy through GRPO-fine-tuned neural reasoning
- [ ] Qwen3 generates valid temporal planning sequences with >95% success rate
- [ ] Neural reasoning produces interpretable execution traces for all solutions
- [ ] Shows GRPO fine-tuning outperforming general-purpose LLM approaches
- [ ] Demonstrates seamless neural-symbolic integration through constrained output
- [ ] Planning engine validation catches neural reasoning errors effectively

### Stage 5: "Small Car" - Hybrid Computational Coordination (Size: L, 3-4 weeks)

#### What We're Combining (Simple)

Use computation to coordinate all our computational approaches - like building a smart car that optimally coordinates multiple engines.

#### Computational Strategy Coordination (Technical)

Learn optimal strategy coordination through computation:

- [ ] Implement computational meta-learning for strategy selection
- [ ] Learn optimal ensemble weights through massive validation
- [ ] Generate strategy coordination rules through computational feedback
- [ ] Scale coordination through brute force strategy combination testing
- [ ] Use computation to discover optimal task-to-strategy mappings

#### Advanced Computational Integration (Technical)

Scale coordination through computational methods:

- [ ] Test thousands of strategy combinations computationally
- [ ] Learn coordination patterns from successful ensemble results
- [ ] Generate meta-strategies through computational search
- [ ] Scale ensemble optimization through brute force validation
- [ ] Discover coordination rules through computational pattern analysis

#### Success Criteria (Measurable)

- [ ] May achieve 15-25% ± 4% accuracy through learned coordination
- [ ] Strategy coordination learned through computation, not engineered
- [ ] Shows computational coordination outperforming hand-tuned ensembles
- [ ] Demonstrates meta-learning of optimal strategy combinations
- [ ] Coordination rules discovered through massive computational validation

### Stage 6: "Sedan" - Self-Improving Computational System (Size: L, 4+ weeks)

#### What We're Building (Simple)

A system that uses computation to improve its own computational methods - like a car that rebuilds its own engine while driving.

#### Computational Self-Improvement (Technical)

Implement computational self-modification:

- [ ] Add computational analysis of own performance patterns
- [ ] Generate improvements to search algorithms through computation
- [ ] Learn better learning algorithms through computational feedback
- [ ] Scale self-improvement through massive computational validation
- [ ] Implement computational discovery of better computational methods

#### Meta-Computational Learning (Technical)

Use computation to improve computation:

- [ ] Learn better search strategies through computational analysis
- [ ] Generate improved pattern learning algorithms computationally
- [ ] Discover better ensemble methods through computational search
- [ ] Scale meta-learning through brute force method comparison
- [ ] Implement computational evolution of computational approaches

#### Success Criteria (Measurable)

- [ ] May achieve 20-30% ± 5% accuracy through computational self-improvement
- [ ] System demonstrably improves its own computational methods
- [ ] Shows computational discovery of better computational approaches
- [ ] Meta-learning produces genuinely improved reasoning methods
- [ ] Self-improvement validated through massive computational testing

### Stage 7: "SUV" - Production-Ready Competition System (Size: M, 2-3 weeks)

#### What We're Finalizing (Simple)

Making everything robust and ready for the actual competition - like upgrading to a reliable SUV that can handle any conditions.

#### Competition Preparation (Technical)

Prepare for offline competition execution:

- [ ] Package all models and dependencies for offline execution
- [ ] Implement comprehensive error handling and recovery
- [ ] Create resource management and timeout systems
- [ ] Add extensive logging and debugging capabilities
- [ ] Implement submission format validation

#### Performance Optimization (Technical)

Optimize for competition constraints:

1. [ ] Optimize grid operations for performance
2. [ ] Implement caching system for repeated patterns
3. [ ] Add parallel strategy execution where possible
4. [ ] Implement early termination criteria for time limits
5. [ ] Create memory management for large task sets

#### Success Criteria (Measurable)

- [ ] May achieve 15-25% ± 5% accuracy on public ARC dataset
- [ ] Runs reliably in offline competition environment
- [ ] Meets all competition timing and resource constraints
- [ ] Passes comprehensive validation and stress testing

### Stage 8: "Sports Car" - Advanced Research Features (Size: L, 4+ weeks)

#### What We're Adding (Simple)

Advanced features for research and maximum performance - like upgrading to a sports car with cutting-edge technology.

#### Advanced Capabilities (Technical)

Research-grade enhancements:

- [ ] Add synthetic data generation for training augmentation
- [ ] Implement active learning and test-time adaptation
- [ ] Create advanced pattern discovery and taxonomy
- [ ] Add research-grade analytics and visualization
- [ ] Implement novel reasoning architectures

#### Research Contributions (Technical)

Contribute to the broader ARC research community:

- [ ] Create comprehensive pattern analysis and sharing
- [ ] Implement novel hybrid reasoning approaches
- [ ] Add detailed performance analysis and insights
- [ ] Create reproducible research artifacts

#### Success Criteria (Measurable)

- [ ] May achieve 20-35% ± 6% accuracy on public ARC dataset (approaching SOTA)
- [ ] Contributes novel insights to ARC research community
- [ ] Demonstrates advanced reasoning capabilities
- [ ] Provides comprehensive analysis of approach effectiveness

### Stage 9: "Formula 1 Car" - Meta-Learning and Self-Improvement (Size: XL, 6+ weeks)

#### What We're Building (Simple)

A system that learns how to learn better - like a Formula 1 car with advanced telemetry and self-optimization.

#### Meta-Learning Implementation (Technical)

Advanced learning capabilities:

- [ ] Implement meta-learning algorithms for strategy adaptation
- [ ] Add self-modifying code generation for novel transformations
- [ ] Create automated hyperparameter optimization
- [ ] Implement curriculum learning for progressive difficulty
- [ ] Add online learning during competition execution

#### Advanced Reasoning (Technical)

Breakthrough reasoning capabilities:

- [ ] Implement causal reasoning for transformation understanding
- [ ] Add analogical reasoning between different task types
- [ ] Create compositional generalization beyond training patterns
- [ ] Implement abstract concept formation and manipulation
- [ ] Add recursive pattern discovery and application

#### Success Criteria (Measurable)

- [ ] May achieve 35-50% ± 8% accuracy on public ARC dataset (exceeding SOTA)
- [ ] Demonstrates genuine meta-learning and adaptation
- [ ] Shows emergent reasoning capabilities not explicitly programmed
- [ ] Generalizes to completely novel pattern types

### Stage 10: "Rocket Ship" - AGI-Level Abstract Reasoning (Size: XXL, 8+ weeks)

#### What We're Achieving (Simple)

Human-level abstract reasoning - like building a rocket ship that can reach the stars.

#### AGI-Level Capabilities (Technical)

Approaching artificial general intelligence:

- [ ] Implement consciousness-inspired attention mechanisms
- [ ] Add working memory and episodic learning systems
- [ ] Create hierarchical abstraction and concept formation
- [ ] Implement creative problem-solving and insight generation
- [ ] Add theory of mind for understanding puzzle creator intent

#### Breakthrough Architecture (Technical)

Revolutionary reasoning system:

- [ ] Integrate neurosymbolic reasoning with emergent properties
- [ ] Implement self-reflective reasoning and error correction
- [ ] Create dynamic strategy invention and validation
- [ ] Add cross-domain knowledge transfer and application
- [ ] Implement genuine understanding vs pattern matching

#### Success Criteria (Measurable)

- [ ] May achieve 50-70% ± 10% accuracy on public ARC dataset (human-competitive)
- [ ] Demonstrates reasoning indistinguishable from human cognition
- [ ] Shows creative problem-solving on completely novel tasks
- [ ] Exhibits genuine understanding and insight generation

### Stage 11: "Starship" - Prize-Winning Performance (Size: XXXL, 10+ weeks)

#### What We're Conquering (Simple)

Winning the ARC Prize - like building a starship capable of interstellar travel.

#### Prize-Winning Implementation (Technical)

Competition-dominating capabilities:

- [ ] Implement perfect pattern recognition and generalization
- [ ] Add flawless reasoning chain construction and validation
- [ ] Create optimal strategy selection and execution
- [ ] Implement robust error detection and recovery
- [ ] Add comprehensive edge case handling

#### Competition Mastery (Technical)

Unbeatable competition performance:

- [ ] Optimize for maximum accuracy on all task types
- [ ] Implement redundant validation and cross-checking
- [ ] Create adaptive difficulty scaling and response
- [ ] Add comprehensive test-time optimization
- [ ] Implement perfect submission format compliance

#### Success Criteria (Measurable)

- [ ] Achieve 70-85% ± 12% accuracy on public ARC dataset (prize-competitive)
- [ ] Consistently outperforms all existing SOTA approaches
- [ ] Demonstrates breakthrough AGI-level reasoning capabilities
- [ ] Ready for $1M Grand Prize competition submission

### Stage 12: "Warp Drive" - AGI Breakthrough (Size: XXXXL, 12+ weeks)

#### What We're Transcending (Simple)

Achieving artificial general intelligence - like inventing warp drive technology.

#### AGI Breakthrough (Technical)

Transcendent artificial intelligence:

- [ ] Implement perfect abstract reasoning across all domains
- [ ] Add creative insight generation beyond human capability
- [ ] Create self-improving recursive intelligence enhancement
- [ ] Implement universal problem-solving architecture
- [ ] Add consciousness-level self-awareness and reflection

#### Universal Intelligence (Technical)

Beyond human-level capabilities:

- [ ] Perfect generalization to any abstract reasoning task
- [ ] Creative solution generation for unseen problem types
- [ ] Self-modification and capability enhancement
- [ ] Universal pattern recognition and manipulation
- [ ] Transcendent understanding of abstract relationships

#### Success Criteria (Measurable)

- [ ] Achieve 85%+ ± 15% accuracy on public ARC dataset (AGI-level performance)
- [ ] Demonstrates capabilities beyond current human reasoning
- [ ] Shows creative problem-solving exceeding human insight
- [ ] Represents breakthrough in artificial general intelligence
- [ ] **WINS THE ARC PRIZE 2025 $1,000,000 GRAND PRIZE**

## Progressive App Introduction

**Apps Created by Stage:**

- **Stage 1-2:** `aria_grid`, `aria_arc_coordinator`
- **Stage 3:** Add `aria_arc_domain` (integrate with `aria_hybrid_planner`)
- **Stage 4:** Add `aria_llm_client`
- **Stage 5:** Add `aria_program_synthesis`
- **Stage 6:** Add `aria_pattern_library`
- **Stage 7:** Complete all apps with production features
- **Stage 8:** Advanced features across all apps

**Key Benefits:**

- **Always functional:** Each stage produces a working ARC solver
- **Risk mitigation:** Can submit whatever stage we reach by competition deadline
- **Rapid feedback:** Immediate accuracy measurements guide development priorities
- **Incremental complexity:** Add umbrella apps only when complexity demands them
- **Measurable progress:** Clear accuracy targets validate each stage's effectiveness

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

**ARC Planning Domain:** The `aria_arc_domain` app contains ARC-specific planning actions, methods, and rules that integrate with `aria_hybrid_planner`. Following the Bitter Lesson, the domain content is **learned through computation** rather than hand-crafted, using program synthesis to discover actions, pattern analysis to learn methods, and feedback to evolve rules.

### Computational Learning Domain Architecture

**Module-Based Domain (Following ADR-133 Solution):**

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

**Action Discovery Engine:**
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

**Method Learning from Traces:**
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

### Integration with Existing Aria Apps

#### **`aria_hybrid_planner` (Strategy Coordination Only)**

**Core Responsibility:** Coordinate multiple strategies (unchanged)

**Minimal ARC Integration:**

- Add ARC strategy types to existing strategy factory
- Coordinate between aria_program_synthesis, aria_llm_client, and aria_dsl strategies
- Use existing ensemble coordination for ARC result voting

**What it does NOT do:** Grid reasoning, pattern analysis, active inference management

#### **`aria_temporal_planner` (Temporal Planning Only)**

**Core Responsibility:** Plan sequences over time (unchanged)

**Minimal ARC Integration:**

- Accept grid transformation sequences as temporal planning input
- Optimize transformation order using existing temporal algorithms
- Output optimized sequence plans to aria_arc_coordinator

**What it does NOT do:** Pattern learning, spatial reasoning, constraint propagation

#### **`aria_membrane_pipeline` (Data Pipeline Only)**

**Core Responsibility:** Process data through pipelines (unchanged)

**Minimal ARC Integration:**

- Add ARC task format as pipeline input type
- Process grid data through existing pipeline stages
- Output processed results to aria_arc_coordinator

**What it does NOT do:** Synthetic data generation, model training, competition packaging

#### **`aria_minizinc` (Constraint Solving Only)**

**Core Responsibility:** Solve constraint satisfaction problems (unchanged)

**Minimal ARC Integration:**

- Accept grid constraint problems from aria_program_synthesis
- Solve using existing MiniZinc constraint engine
- Return solutions to requesting ARC apps

**What it does NOT do:** Ensemble optimization, pattern composition, resource allocation

#### **`aria_engine_core` (Core Infrastructure Only)**

**Core Responsibility:** Provide shared infrastructure (unchanged)

**Minimal ARC Integration:**

- Add grid data structures to existing state management
- Provide shared utilities for ARC apps
- Maintain existing interface patterns

**What it does NOT do:** ARC-specific logic, strategy coordination, performance monitoring

### Multi-LLM Architecture

**OpenRouter Integration:**

- Model diversity for different reasoning approaches
- Ensemble voting across multiple model outputs
- Specialized prompting strategies per model type
- Cross-model validation and quality assurance
- Development acceleration through Cline (VS Code extension) integration

**Competition Compliance:**

- All LLM usage during development and training phases only
- Final submission runs completely offline
- No internet access during competition evaluation
- Self-contained model weights and dependencies

## Synthetic Data Generation Strategy

### Pattern Extraction

- Automated analysis of public ARC datasets
- Transformation pattern identification and classification
- Difficulty progression modeling
- Edge case identification and generation

### Multi-Model Generation

- Different LLMs generate diverse task variations
- Cross-model validation ensures quality
- Adversarial generation finds challenging cases
- Human expert integration for pattern validation

### Quality Assurance

- Automated validation against ARC principles
- Cross-model consistency checking
- Difficulty calibration and progression
- Overfitting prevention through diversity metrics

## Success Criteria by Stage

### Stage 1: "Skateboard" Success (1-2 days)

- [ ] Can load ARC JSON task files without errors
- [ ] Applies basic transformations (rotate, mirror) to test inputs
- [ ] Generates valid competition submission format
- [ ] Achieves >0% accuracy on public ARC dataset
- [ ] Complete end-to-end pipeline functional

### Stage 2: "Bicycle" Success (1 week)

- [ ] Achieves 5-10% accuracy on public ARC dataset
- [ ] Correctly identifies basic patterns (color changes, rotations, mirroring)
- [ ] Shows measurable improvement over random guessing
- [ ] Handles at least 50% of task types without runtime errors
- [ ] Pattern recognition demonstrably working

### Stage 3: "Scooter" Success (1-2 weeks)

- [ ] Achieves 10-15% accuracy on public ARC dataset
- [ ] Successfully composes 2-3 step transformation sequences
- [ ] Handles tasks requiring multiple operations
- [ ] Shows systematic improvement over single-step approaches
- [ ] Planning integration with aria_hybrid_planner functional

### Stage 4: "Motorcycle" Success (2-3 weeks)

- [ ] Achieves 15-20% accuracy on public ARC dataset
- [ ] LLM strategy contributes meaningfully to ensemble performance
- [ ] Successfully handles novel patterns not covered by symbolic rules
- [ ] Shows complementary strengths between neural and symbolic approaches
- [ ] OpenRouter integration stable and reliable

### Stage 5: "Small Car" Success (2-3 weeks)

- [ ] Achieves 20-25% accuracy on public ARC dataset
- [ ] Each strategy (symbolic, neural, synthesis) contributes unique value
- [ ] Ensemble consistently outperforms individual strategies
- [ ] Successfully handles diverse task types with appropriate strategy selection
- [ ] Three-way ensemble coordination working effectively

### Stage 6: "Sedan" Success (3-4 weeks)

- [ ] Achieves 25-30% accuracy on public ARC dataset
- [ ] Pattern library demonstrably improves strategy performance
- [ ] System learns and adapts from previous task solutions
- [ ] Shows consistent improvement over time with more data
- [ ] Pattern-guided optimization working across all strategies

### Stage 7: "SUV" Success (2-3 weeks)

- [ ] Achieves 30%+ accuracy on public ARC dataset
- [ ] Runs reliably in offline competition environment
- [ ] Meets all competition timing and resource constraints
- [ ] Passes comprehensive validation and stress testing
- [ ] Competition submission package complete and validated

### Stage 8: "Sports Car" Success (4+ weeks)

- [ ] May achieve 20-35% ± 6% accuracy on public ARC dataset (approaching SOTA)
- [ ] Contributes novel insights to ARC research community
- [ ] Demonstrates advanced reasoning capabilities
- [ ] Provides comprehensive analysis of approach effectiveness

### Stage 9: "Formula 1 Car" Success (6+ weeks)

- [ ] May achieve 35-50% ± 8% accuracy on public ARC dataset (exceeding SOTA)
- [ ] Demonstrates genuine meta-learning and adaptation
- [ ] Shows emergent reasoning capabilities not explicitly programmed
- [ ] Generalizes to completely novel pattern types

### Stage 10: "Rocket Ship" Success (8+ weeks)

- [ ] May achieve 50-70% ± 10% accuracy on public ARC dataset (human-competitive)
- [ ] Demonstrates reasoning indistinguishable from human cognition
- [ ] Shows creative problem-solving on completely novel tasks
- [ ] Exhibits genuine understanding and insight generation

### Stage 11: "Starship" Success (10+ weeks)

- [ ] Achieve 70-85% ± 12% accuracy on public ARC dataset (prize-competitive)
- [ ] Consistently outperforms all existing SOTA approaches
- [ ] Demonstrates breakthrough AGI-level reasoning capabilities
- [ ] Ready for $1M Grand Prize competition submission

### Stage 12: "Warp Drive" Success (12+ weeks)

- [ ] Achieve 85%+ ± 15% accuracy on public ARC dataset (AGI-level performance)
- [ ] Demonstrates capabilities beyond current human reasoning
- [ ] Shows creative problem-solving exceeding human insight
- [ ] Represents breakthrough in artificial general intelligence
- [ ] **WINS THE ARC PRIZE 2025 $1,000,000 GRAND PRIZE**

### Overall Competition Goals

- **Minimum Viable (Stage 4):** 3-8% ± 2% accuracy - Basic competitive submission
- **Target Performance (Stage 6):** 10-20% ± 4% accuracy - Respectable showing
- **Stretch Goal (Stage 8):** 20-35% ± 6% accuracy - Approaching SOTA performance
- **Prize Contention:** 40-60% ± 10% accuracy - Competitive for $1M Grand Prize
- **Grand Prize Victory:** 85%+ accuracy - Breakthrough AGI-level performance (extremely unlikely)

### Risk-Adjusted Expectations

- **Most Likely Outcome:** Reach Stage 4-5 (3-15% accuracy)
- **Optimistic Scenario:** Reach Stage 6-7 (10-25% accuracy)
- **Pessimistic Scenario:** Reach Stage 2-3 (0-5% accuracy)
- **Failure Scenario:** Cannot achieve >3% accuracy due to fundamental approach limitations

## Critical Gaps and Failure Risks

### Fundamental Technical Gaps

**⚠️ HIGH RISK: No Proven ARC-Specific Reasoning**

- **Gap:** Aria's existing planning is for temporal/spatial domains, not abstract visual reasoning
- **Reality Check:** ARC requires understanding visual patterns humans find intuitive but are computationally hard
- **Failure Risk:** 90% - Core reasoning capabilities may be fundamentally insufficient

**⚠️ HIGH RISK: Symbolic-Neural Integration Unproven**

- **Gap:** No existing examples of successful symbolic-neural hybrid for ARC-like tasks
- **Reality Check:** Current SOTA (34%) uses pure neural approaches, not hybrid systems
- **Failure Risk:** 80% - Integration complexity may reduce rather than improve performance

**⚠️ CRITICAL: No Domain Expert Knowledge**

- **Gap:** Team lacks deep ARC research experience and cognitive science background
- **Reality Check:** Winning teams likely have years of ARC-specific research
- **Failure Risk:** 95% - Missing fundamental insights about what makes ARC hard

### Resource and Timeline Gaps

**⚠️ HIGH RISK: Computational Requirements Unknown**

- **Gap:** No analysis of computational costs for program synthesis at ARC scale
- **Reality Check:** Discrete program search may be computationally intractable
- **Failure Risk:** 70% - May hit computational limits before reaching competitive performance

**⚠️ CRITICAL: Unrealistic Development Timeline**

- **Gap:** T-shirt sizes don't account for research uncertainty and dead ends
- **Reality Check:** Each phase could take 3-10x longer due to fundamental research needs
- **Failure Risk:** 85% - Won't have working system by competition deadline

**⚠️ HIGH RISK: LLM Dependency Vulnerability**

- **Gap:** Heavy reliance on external LLM services during development
- **Reality Check:** OpenRouter costs could exceed budget, rate limits could block development
- **Failure Risk:** 60% - Development blocked by external service limitations

### Competition-Specific Gaps

**⚠️ CRITICAL: No Validation Against Real ARC Performance**

- **Gap:** Success criteria based on assumptions, not validated benchmarks
- **Reality Check:** 15% target may be optimistic given current SOTA struggles
- **Failure Risk:** 90% - May build complex system that performs worse than simple baselines

**⚠️ HIGH RISK: Offline Execution Complexity**

- **Gap:** No experience packaging complex AI systems for offline competition
- **Reality Check:** Dependency hell, model size limits, execution environment constraints
- **Failure Risk:** 70% - System works in development but fails in competition environment

**⚠️ MEDIUM RISK: Competition Rule Changes**

- **Gap:** Rules may change, evaluation criteria may shift
- **Reality Check:** Competition organizers often adjust rules based on submissions
- **Failure Risk:** 40% - System optimized for wrong evaluation criteria

### Architectural Reality Checks

**⚠️ HIGH RISK: Over-Engineering for Unproven Benefit**

- **Gap:** Complex umbrella app structure may add overhead without benefit
- **Reality Check:** Simple, focused solutions often outperform complex architectures
- **Failure Risk:** 60% - Complexity reduces development velocity and introduces bugs

**⚠️ MEDIUM RISK: Integration Testing Nightmare**

- **Gap:** 5 new apps + 5 existing apps = 25 integration points to test
- **Reality Check:** Integration bugs could consume majority of development time
- **Failure Risk:** 50% - System never reaches stable, testable state

### Honest Success Probability Assessment

**Realistic Outcome Probabilities:**

- **Complete Failure (0-5% accuracy):** 60% probability
- **Baseline Performance (5-15% accuracy):** 30% probability  
- **Competitive Performance (15-25% accuracy):** 8% probability
- **SOTA Performance (25%+ accuracy):** 2% probability

**Most Likely Scenario:**
System reaches basic functionality but performs poorly due to fundamental gaps in ARC-specific reasoning. Complex architecture becomes liability rather than asset.

**Recommended Risk Mitigation:**

1. **Start with minimal umbrella scope:** Begin with aria_grid + aria_arc_coordinator only, add other apps incrementally
2. **Validate core assumptions early:** Test basic grid reasoning on public ARC data within 2 weeks
3. **Plan for failure:** Have backup plan for simpler submission if complex approach fails
4. **Budget reality:** Assume 3-5x longer development time than estimated
5. **Expert consultation:** Engage ARC research community early for guidance

**Note:** Monolithic apps are not viable based on Aria's previous experience - they collapse under complexity. The umbrella architecture is necessary to prevent code collapse, but we can start with minimal scope and expand incrementally.

## Risk Mitigation

### Technical Risks (priority order)

1. **Grid representation limitations:** Fallback to multiple representation formats
2. **Performance constraints:** Parallel execution and optimization strategies
3. **LLM integration complexity:** Modular design allows individual strategy testing
4. **Overfitting to public data:** Diverse synthetic generation and validation

### Competition Risks (priority order)

1. **Rule compliance:** Early validation and testing of submission requirements
2. **Offline execution:** Comprehensive dependency packaging and testing
3. **Time constraints:** Phased development with working prototypes at each stage
4. **Novel test cases:** Emphasis on generalization through diverse training

### Development Risks (priority order)

1. **Scope creep:** Clear phase boundaries and success criteria
2. **Resource constraints:** Prioritize high-impact strategies first
3. **Integration complexity:** Leverage existing Aria patterns and architecture
4. **Team coordination:** Clear ownership and interface definitions

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

### Detailed Implementation ADRs

- **ADR-168**: ARC Prize Implementation Plan (detailed stage-by-stage implementation)
- **ADR-169**: ARC Prize Technical Architecture (umbrella app structure and integration)
- **ADR-170**: ARC Prize Risk Analysis (comprehensive risk assessment and mitigation)

### Supporting Aria ADRs

- **ADR-036**: Evolving AriaEngine Planner Blueprint
- **ADR-112**: Hybrid Coordinator V3 Implementation
- **ADR-133**: Planner Standardization Open Problems
- **ADR-148**: Membrane Planning System Implementation
- **ADR-151**: Strict Encapsulation and Modular Testing Architecture

## Consequences

### Positive

- **Breakthrough Application:** Demonstrates Aria's capabilities on world-class AI challenge
- **Architecture Validation:** Proves hybrid planning approach for complex reasoning
- **Research Impact:** Contributes to abstract reasoning and AGI research
- **Technical Advancement:** Pushes boundaries of symbolic-neural integration

### Negative

- **Resource Intensive:** Requires significant development and computational resources
- **High Risk:** No guarantee of competitive performance despite investment
- **Complexity:** Adds substantial complexity to Aria ecosystem
- **Maintenance:** Long-term maintenance burden for specialized components

### Neutral

- **Learning Opportunity:** Valuable experience regardless of competition outcome
- **Technology Transfer:** Components useful for other reasoning applications
- **Community Engagement:** Positions Aria in AI research community
- **Documentation:** Comprehensive documentation of advanced reasoning techniques

## Monitoring and Evaluation

### Development Metrics

- Code coverage and test completion rates
- Integration test success rates
- Performance benchmarks on validation sets
- Strategy effectiveness measurements

### Competition Metrics

- Accuracy on public ARC datasets
- Performance on held-out validation sets
- Execution time and resource usage
- Generalization to novel task types

### Success Indicators

- Consistent improvement across development phases
- Competitive performance relative to published baselines
- Successful offline deployment and execution
- Novel insights into abstract reasoning approaches

This ADR represents the most ambitious application of Aria's capabilities to date, targeting one of AI's grand challenges while demonstrating the power of hybrid symbolic-neural reasoning architectures.
