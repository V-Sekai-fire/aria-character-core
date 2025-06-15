# ADR-046: User-Friendly Temporal Constraint Specification

## Status

Accepted

## Date

2025-06-15

## Context

ADR-042 defines a comprehensive temporal planner implementation with JSON-LD foundations, but its constraint specification approach requires verbose boilerplate code for building temporal constraint networks. Developers must manually create intervals, add constraints, and manage the complex underlying temporal state representations.

ADR-045 introduces Allen's Interval Algebra with elegant shorthand notation for temporal relationships. This provides an opportunity to create pipeline-style methods that make temporal constraint network construction intuitive and concise.

The current approach in ADR-042 requires extensive manual setup:

- Manual interval creation with start/end times
- Separate constraint addition for each temporal relationship
- Complex state management for temporal networks
- High cognitive load for developers to build and modify temporal scenarios

## Decision

We will create user-friendly pipeline methods that use Allen's Interval Algebra notation (ADR-045) to dramatically simplify temporal constraint network construction as defined in ADR-042. This will provide fluent, chainable methods for building complex temporal scenarios.

## Agent vs Entity Distinction and API Design

### Terminology Clarification

The AriaTimestrike temporal planner distinguishes between two types of interactable objects in the game world:

- **Agents**: Autonomous actors with decision-making capabilities (NPCs, players, AI companions)
- **Entities**: Non-autonomous interactable objects (vehicles, buildings, projectiles, resources)

Both agents and entities can participate in temporal relationships, but they have different interaction patterns and constraints.

### Unified Implementation with Semantic Sugar

The API provides semantic sugar/aliases for both agents and entities, while using a unified underlying implementation:

```elixir
# Agent-focused API sugar - emphasizes autonomous decision-making
constraint_network = TemporalConstraintNetwork.new()
  |> add_agent("maya", type: :npc, capabilities: [:movement, :spellcasting])
  |> add_agent_action("maya", "scout", during: {15, 45})
  |> add_agent_behavior("maya", "adaptive_coordination", during: {0, 90})

# Entity-focused API sugar - emphasizes state changes and interactions
constraint_network = TemporalConstraintNetwork.new()
  |> add_entity("fireball", type: :projectile, properties: [:damage, :area_effect])
  |> add_entity_state("fireball", "traveling", during: {10, 25})
  |> add_entity_interaction("player", "fireball", "collision", at: 25)

# Both compile to the same underlying interval/constraint structure
constraint_network = TemporalConstraintNetwork.new()
  |> add_interval("maya", 0, 90)
  |> add_interval("maya_scout", 15, 45)
  |> add_constraint("maya_scout", :during, "maya")
  |> add_interval("fireball_travel", 10, 25)
  |> add_interval("collision_event", 25, 25)
```

### Benefits of the Dual API Approach

1. **Semantic Clarity**: Developers can express intent clearly based on object type
2. **Unified Implementation**: Single codebase maintains consistency and reduces complexity
3. **Domain-Appropriate Language**: Game designers can think in terms of agents and entities
4. **Flexible Composition**: Agent and entity constraints can be mixed in the same network

## Temporal Constraint Network Builder Pipeline

### Fluent Interface for Constraint Networks

Instead of verbose manual construction, temporal constraint networks are built using chainable pipeline methods:

```elixir
# Maya's Adaptive Scorch Coordination - Pipeline Style
constraint_network = TemporalConstraintNetwork.new()
  |> add_interval("information_gathering", 0, 45)
  |> add_interval("move_to_observation", 0, 15)
  |> add_interval("scout_soldier2", 15, 45)
  |> add_interval("coordination_setup", 45, 60)
  |> add_interval("attack_execution", 60, 90)
  |> add_interval("scorch_cast", 60, 75)
  |> add_interval("attack_move", 65, 85)
  # Add temporal relationships using Allen's notation
  |> add_constraint("information_gathering", :contains, "move_to_observation")
  |> add_constraint("information_gathering", :contains, "scout_soldier2")
  |> add_constraint("move_to_observation", :meets, "scout_soldier2")
  |> add_constraint("coordination_setup", :met_by, "information_gathering")
  |> add_constraint("attack_execution", :met_by, "coordination_setup")
  |> add_constraint("scorch_cast", :overlaps, "attack_move")
  |> add_constraint("attack_execution", :contains, "scorch_cast")
  |> add_constraint("attack_execution", :contains, "attack_move")
```

### Shorthand Methods for Common Patterns

```elixir
# Sequential action chains
constraint_network = TemporalConstraintNetwork.new()
  |> add_sequence(["move_to_position", "scout_area", "signal_ready"], [0, 15, 30])
  |> add_parallel_group(["scorch_cast", "attack_move"], 45, 75)
  |> add_containment("attack_phase", ["scorch_cast", "attack_move"])

# Conditional constraints
constraint_network = constraint_network
  |> add_conditional("emergency_retreat", 
       trigger: "health_critical", 
       during: "attack_phase")
```

### Type-Safe Constraint Building

```elixir
defmodule AriaTimestrike.TemporalConstraintNetwork do
  @type interval_id :: String.t()
  @type time_point :: non_neg_integer()
  
  # Temporal relation types - designed for internationalization and extensibility
  @type temporal_relation :: :before | :meets | :overlaps | :starts | :during | 
                            :finishes | :equals | :after | :met_by | :overlapped_by |
                            :started_by | :contains | :finished_by
  
  # Legacy alias for backward compatibility
  @type allen_relation :: temporal_relation()

  @spec add_interval(t(), interval_id(), time_point(), time_point()) :: t()
  def add_interval(network, id, start_time, end_time)

  @spec add_constraint(t(), interval_id(), temporal_relation(), interval_id()) :: t()
  def add_constraint(network, interval_a, relation, interval_b)

  @spec add_sequence(t(), [interval_id()], [time_point()]) :: t()
  def add_sequence(network, interval_ids, start_times)

  @spec add_parallel_group(t(), [interval_id()], time_point(), time_point()) :: t()
  def add_parallel_group(network, interval_ids, start_time, end_time)

  @spec add_containment(t(), interval_id(), [interval_id()]) :: t()
  def add_containment(network, container_id, contained_ids)
end
```

## Usability Improvements Over ADR-042

### Before (ADR-042 Style)

```elixir
# Complex JSON-LD structure definition
test "Maya's information gathering phase with temporal constraints" do
  initial_state = JsonLdTemporalState.new(%{
    "@context" => %{
      "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
      "position" => "https://chibifire.com/vocab/aria/temporal#position",
      "vision_range" => "https://chibifire.com/vocab/aria/temporal#vision_range"
    },
    "@type" => "TemporalState",
    "time" => 0,
    "agents" => %{
      "maya" => %{
        "position" => %{"@value" => [3, 5, 0], "time" => 0},
        "vision_range" => %{"@value" => 8, "time" => 0}
      }
      # ... extensive JSON-LD structure continues
    }
  })

  # Complex constraint network building
  constraint_network = TemporalConstraintNetwork.new()
  |> add_interval("information_gathering", 0, 45)
  |> add_interval("move_to_observation", 0, 15)
  |> add_interval("scout_soldier2", 15, 45)
  |> add_temporal_constraint("move_to_observation", "scout_soldier2", :meets)
  |> add_temporal_constraint("information_gathering", "move_to_observation", :contains)
  # ... many more constraint additions
end
```

### After (ADR-046 Style)

```elixir
# Clean pipeline-based constraint network building
test "Maya's information gathering phase" do
  initial_state = %{
    agents: %{
      "maya" => %{position: [3, 5, 0], vision_range: 8}
    }
  }

  constraint_network = TemporalConstraintNetwork.new()
    |> add_interval("information_gathering", 0, 45)
    |> add_interval("move_to_observation", 0, 15)
    |> add_interval("scout_soldier2", 15, 45)
    |> add_constraint("information_gathering", :contains, "move_to_observation")
    |> add_constraint("information_gathering", :contains, "scout_soldier2")
    |> add_constraint("move_to_observation", :meets, "scout_soldier2")
  
  {:ok, temporal_state} = TemporalConstraintNetwork.compile_to_json_ld(constraint_network, initial_state)
  assert TemporalConstraintNetwork.validate(constraint_network) == :ok
end
```

## Direct JSON-LD State Variable Methods

For scenarios requiring direct state manipulation, provide Allen's algebra methods that operate on JSON-LD temporal states:

```elixir
# Direct JSON-LD temporal state building
test "Maya's adaptive coordination with direct state methods" do
  temporal_state = JsonLdTemporalState.new()
    |> set_agent_position("maya", [3, 5, 0], at_time: 0)
    |> set_agent_position("maya", [8, 5, 0], at_time: 15)  # Moving to observation point
    |> set_agent_position("maya", [3, 5, 0], at_time: 45)  # Return after scouting
    |> add_agent_action("maya", "scout", target: "soldier2", during: {15, 45})
    |> add_agent_action("maya", "scorch_cast", target: "soldier2", during: {60, 75})
    |> add_temporal_constraint("scout", :meets, "scorch_cast")
    |> add_temporal_constraint("move_to_observation", :contains, "scout")
  
  assert JsonLdTemporalState.validate_temporal_consistency(temporal_state) == :ok
end
```

## Implementation Architecture

### 1. Pipeline-Based Constraint Network Builder

```elixir
defmodule AriaTimestrike.TemporalConstraintNetwork do
  @type t :: %__MODULE__{
    intervals: %{String.t() => interval()},
    constraints: [constraint()],
    metadata: map()
  }

  @type interval :: %{
    id: String.t(),
    start_time: non_neg_integer(),
    end_time: non_neg_integer(),
    properties: map()
  }

  @type constraint :: %{
    interval_a: String.t(),
    relation: allen_relation(),
    interval_b: String.t()
  }

  @spec add_interval(t(), String.t(), non_neg_integer(), non_neg_integer()) :: t()
  def add_interval(network, id, start_time, end_time)

  @spec add_constraint(t(), String.t(), allen_relation(), String.t()) :: t()
  def add_constraint(network, interval_a, relation, interval_b)

  @spec compile_to_json_ld(t(), map()) :: {:ok, JsonLdTemporalState.t()} | {:error, term()}
  def compile_to_json_ld(network, initial_state)
end
```

### 2. Enhanced JSON-LD Temporal State Methods

```elixir
defmodule AriaTimestrike.JsonLdTemporalState do
  @spec add_agent_action(t(), String.t(), String.t(), keyword()) :: t()
  def add_agent_action(state, agent_id, action_name, opts)

  @spec add_temporal_constraint(t(), String.t(), allen_relation(), String.t()) :: t()
  def add_temporal_constraint(state, action_a, relation, action_b)

  @spec set_agent_position(t(), String.t(), [number()], keyword()) :: t()
  def set_agent_position(state, agent_id, position, opts)

  @spec validate_temporal_consistency(t()) :: :ok | {:error, [term()]}
  def validate_temporal_consistency(state)
end
```

### 3. Shorthand Helper Methods

```elixir
defmodule AriaTimestrike.TemporalHelpers do
  @spec sequential_actions(TemporalConstraintNetwork.t(), [String.t()], [non_neg_integer()]) :: TemporalConstraintNetwork.t()
  def sequential_actions(network, action_ids, start_times)

  @spec parallel_actions(TemporalConstraintNetwork.t(), [String.t()], non_neg_integer(), non_neg_integer()) :: TemporalConstraintNetwork.t()
  def parallel_actions(network, action_ids, start_time, end_time)

  @spec containment_group(TemporalConstraintNetwork.t(), String.t(), [String.t()]) :: TemporalConstraintNetwork.t()
  def containment_group(network, container_id, contained_ids)
end
```

## Practical Examples

### Complex Multi-Agent Coordination

```elixir
# Maya's Adaptive Scorch Coordination using pipeline methods
def build_maya_scenario() do
  TemporalConstraintNetwork.new()
    # Phase 1: Information Gathering
    |> add_interval("information_gathering", 0, 45)
    |> add_interval("move_to_observation", 0, 15)
    |> add_interval("scout_soldier2", 15, 45)
    |> add_constraint("information_gathering", :contains, "move_to_observation")
    |> add_constraint("information_gathering", :contains, "scout_soldier2")
    |> add_constraint("move_to_observation", :meets, "scout_soldier2")
    
    # Phase 2: Coordination Setup
    |> add_interval("coordination_setup", 45, 60)
    |> add_interval("signal_ready", 45, 50)
    |> add_interval("wait_for_signal", 45, 50)
    |> add_constraint("coordination_setup", :met_by, "information_gathering")
    |> add_constraint("coordination_setup", :contains, "signal_ready")
    |> add_constraint("coordination_setup", :contains, "wait_for_signal")
    |> add_constraint("signal_ready", :equals, "wait_for_signal")
    
    # Phase 3: Attack Execution
    |> add_interval("attack_execution", 60, 90)
    |> add_interval("scorch_cast", 60, 75)
    |> add_interval("attack_move", 65, 85)
    |> add_constraint("attack_execution", :met_by, "coordination_setup")
    |> add_constraint("attack_execution", :contains, "scorch_cast")
    |> add_constraint("attack_execution", :contains, "attack_move")
    |> add_constraint("scorch_cast", :overlaps, "attack_move")
    
    # Emergency Fallback
    |> add_interval("emergency_retreat", 70, 95)
    |> add_constraint("emergency_retreat", :during, "attack_execution")
end
```

### Helper Methods for Common Patterns

```elixir
# Sequential action chains
network = TemporalConstraintNetwork.new()
  |> TemporalHelpers.sequential_actions(
      ["move_to_position", "scout_area", "signal_ready"], 
      [0, 15, 30]
    )

# Parallel execution groups  
network = network
  |> TemporalHelpers.parallel_actions(
      ["scorch_cast", "attack_move"], 
      45, 75
    )

# Containment relationships
network = network
  |> TemporalHelpers.containment_group(
      "attack_phase", 
      ["scorch_cast", "attack_move"]
    )
```

### Direct JSON-LD State Manipulation

For scenarios requiring fine-grained state control:

```elixir
def build_detailed_maya_state() do
  JsonLdTemporalState.new()
    |> set_agent_position("maya", [3, 5, 0], at_time: 0)
    |> set_agent_position("maya", [8, 5, 0], at_time: 15)
    |> set_agent_position("maya", [3, 5, 0], at_time: 45)
    |> add_agent_action("maya", "scout", 
        target: "soldier2", 
        during: {15, 45},
        properties: %{vision_range: 8})
    |> add_agent_action("maya", "scorch_cast", 
        target: "soldier2", 
        during: {60, 75},
        properties: %{damage: 45, range: 10})
    |> add_temporal_constraint("scout", :meets, "scorch_cast")
    |> add_temporal_constraint("information_gathering", :contains, "scout")
end
```

## Benefits

### Developer Experience
1. **Fluent Interface**: Chainable methods for intuitive constraint building
2. **Type Safety**: Compile-time validation of Allen's relationships
3. **Reduced Boilerplate**: 80% less code compared to manual JSON-LD construction  
4. **Clear Intent**: Method names directly express temporal relationships

### Maintainability
1. **Modular Construction**: Build constraint networks incrementally
2. **Reusable Patterns**: Helper methods for common temporal patterns
3. **Easy Debugging**: Clear method calls make issues traceable
4. **Flexible Approaches**: Both pipeline and direct state manipulation supported

### Technical Advantages
1. **Full Allen's Algebra**: All 13 temporal relationships as first-class methods
2. **Automatic Validation**: Constraint consistency checking built into pipeline
3. **JSON-LD Compilation**: Seamless integration with ADR-042's temporal state system
4. **Performance Optimized**: Constraint networks optimized during compilation
3. **Error Detection**: Syntax and semantic validation with clear error messages
4. **Backward Compatible**: Compiles to ADR-042's JSON-LD foundation

## Migration Path from ADR-042

### Phase 1: Parallel Implementation

- Implement constraint compiler alongside existing JSON-LD system
- Convert Maya scenario as proof of concept
- Maintain full backward compatibility

### Phase 2: Enhanced Tooling

- Add constraint syntax highlighting and validation to development tools
- Create scenario debugging and visualization tools
- Build constraint template library

### Phase 3: Full Adoption

- Convert all existing scenarios to shorthand notation
- Deprecate direct JSON-LD manipulation for scenario authoring
- Maintain JSON-LD as internal representation only

## Example: Maya Scenario Comparison

### ADR-042 Version (200+ lines of JSON-LD)

```elixir
# Extensive JSON-LD structure definition
initial_state = JsonLdTemporalState.new(%{
  "@context" => %{
    "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
    # ... 50+ lines of context definition
  },
  # ... 150+ lines of state initialization
})
```

### ADR-046 Version (20 lines of constraints)

```elixir
scenario = """
InformationGathering     contains    MoveTo(maya, observation_point)
Scout(maya, soldier2)   met-by      MoveTo(maya, observation_point)
CoordinationSetup        met-by      InformationGathering
AttackExecution          met-by      CoordinationSetup
ScorchCast(maya, soldier2) overlaps AttackMove(alex, soldier2)
"""

{:ok, temporal_state} = AriaTimestrike.compile_scenario(scenario, initial_agents)
```

This represents a **90% reduction in code complexity** while maintaining full expressiveness.

## Consequences

### Positive

- Dramatically improved developer productivity
- Lower barrier to entry for temporal scenario creation
- More maintainable and readable temporal constraints
- Faster iteration on scenario design
- Better collaboration between technical and non-technical team members
- Internationalization-ready temporal relation naming system
- Clear semantic distinction between agents and entities
- Extensible architecture for future temporal algebras

### Negative

- Additional compilation step adds slight runtime overhead
- New DSL to learn (though much simpler than JSON-LD manipulation)
- Potential debugging complexity when constraints compile incorrectly
- Risk of abstraction leakage if advanced JSON-LD features are needed
- Need to maintain backward compatibility during transition from `allen_relation` naming

## Related ADRs

- ADR-042: Temporal Planner Cold Boot Implementation Order (enhanced by this ADR)
- ADR-045: Allen's Interval Algebra for Temporal Relationships (foundation for this ADR)
- ADR-041: Temporal Solver Tech Stack Requirements
- ADR-034: TimeStrike Temporal Planner Enhancement

---

**Date**: 2025-06-15  
**Authors**: K. S. Ernest (iFire) Lee  
**Status**: Accepted  
**Impacts**: AriaTimestrike scenario authoring, developer productivity, temporal constraint specification

## Internationalization and Relation Naming

### Problem with Academic Terminology

The term "Allen relation" is English-specific and references a particular academic framework (James Allen's interval algebra from 1983). This creates several issues:

1. **Cultural Specificity**: The term is meaningful only to those familiar with Western academic computer science literature
2. **Translation Difficulties**: "Allen relation" doesn't translate meaningfully to other languages
3. **Cognitive Load**: Developers must learn specialized academic terminology to use basic temporal features
4. **Limited Extensibility**: The name implies a fixed set of relations tied to one researcher's work

### Solution: General Temporal Relation Naming

Instead of `allen_relation`, we use more general and extensible terminology:

```elixir
# Primary type for public APIs
@type temporal_relation :: atom()

# Specific implementations for different temporal algebras
@type interval_relation :: :before | :meets | :overlaps | :starts | :during | 
                          :finishes | :equals | :after | :met_by | :overlapped_by |
                          :started_by | :contains | :finished_by

# Future extensibility for other temporal frameworks
@type point_relation :: :before | :simultaneous | :after
@type fuzzy_temporal_relation :: {:fuzzy, atom(), float()}
```

### Extensible Relation System

```elixir
defmodule AriaTimestrike.TemporalRelations do
  @moduledoc """
  Extensible system for temporal relations supporting multiple algebras
  and internationalization.
  """
  
  # Core interval algebra (based on Allen's work but not named after him)
  defmodule IntervalAlgebra do
    @relations [:before, :meets, :overlaps, :starts, :during, :finishes, :equals,
               :after, :met_by, :overlapped_by, :started_by, :contains, :finished_by]
    
    def valid_relation?(relation), do: relation in @relations
  end
  
  # Future extension point for other temporal algebras
  defmodule PointAlgebra do
    @relations [:before, :simultaneous, :after]
    
    def valid_relation?(relation), do: relation in @relations
  end
  
  # Localization support
  defmodule I18n do
    def relation_name(relation, locale \\ :en) do
      case {relation, locale} do
        {:before, :en} -> "before"
        {:before, :es} -> "antes"
        {:before, :fr} -> "avant"
        # ... more translations
      end
    end
  end
end
```
