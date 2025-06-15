# ADR-048: Developer-Friendly APIs for Temporal Planner Implementation

## Status

Proposed

## Context

ADR-042 established a comprehensive implementation roadmap for the temporal planner using staged Test-Driven Development. However, the implementation approach described in ADR-042 focuses primarily on the technical architecture and testing methodology without addressing developer productivity and API usability concerns.

Based on the success of ADR-046's user-friendly temporal constraint specification APIs, there is an opportunity to enhance the temporal planner implementation with developer-friendly interfaces that reduce cognitive load, improve code readability, and accelerate development velocity.

Key challenges identified in the ADR-042 implementation approach:

1. **Complex Module Interfaces**: Low-level APIs requiring deep understanding of temporal constraint internals
2. **Verbose Test Setup**: Repetitive boilerplate for creating temporal planning test scenarios  
3. **Limited Debugging Support**: Minimal introspection into planning decisions and constraint satisfaction
4. **Steep Learning Curve**: New developers must understand temporal planning theory before contributing
5. **Manual Error-Prone Configuration**: Complex setup of timeline states and constraint networks

## Decision

We will enhance the temporal planner implementation outlined in ADR-042 with developer-friendly APIs and tooling that maintain the staged TDD approach while dramatically improving developer experience.

## Enhanced API Design

### Fluent Test Builder for Temporal Scenarios

Instead of verbose manual test setup, provide chainable builders for common temporal planning scenarios:

```elixir
# Before (ADR-042 Style)
test "Maya's information gathering with complex temporal constraints" do
  initial_state = JsonLdTemporalState.new(%{
    "@context" => %{
      "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
      "agent_position" => %{"@type" => "@id"},
      "has_vision_range" => %{"@type" => "xsd:integer"}
    },
    "maya" => %{
      "@type" => "Agent",
      "agent_position" => "position_3_5",
      "has_vision_range" => 8
    }
  })
  
  goal_state = JsonLdTemporalState.new(%{
    "@context" => initial_state.context,
    "maya" => %{
      "@type" => "Agent", 
      "agent_position" => "position_15_5",
      "has_scouted" => true
    }
  })
  
  constraint_network = TemporalConstraintNetwork.new()
    |> add_interval("information_gathering", 0, 45)
    |> add_interval("move_to_observation", 0, 15)
    |> add_constraint("move_to_observation", :during, "information_gathering")
  
  {:ok, plan} = TemporalPlanner.plan(initial_state, goal_state, constraint_network)
  assert plan != nil
end

# After (Enhanced API)
test "Maya's information gathering with temporal constraints" do
  scenario = TemporalScenario.new()
    |> add_agent(:maya, at: {3, 5}, vision_range: 8)
    |> set_goal(:maya, :scout_position, {15, 5}, within: 45.0)
    |> add_temporal_constraint(:information_gathering, 0..45)
    |> add_temporal_constraint(:move_to_observation, 0..15, during: :information_gathering)
    |> expect_plan_success()
  
  assert_temporal_planning(scenario)
end
```

### Semantic Agent and Action Configuration

Provide domain-specific builders that handle JSON-LD complexity transparently:

```elixir
defmodule TemporalPlannerTest.Helpers do
  @moduledoc """
  Enhanced test helpers for temporal planner development following ADR-042's 
  staged implementation while providing developer-friendly APIs per ADR-048.
  """
  
  # Agent configuration with sensible defaults
  def create_scout_agent(name, opts \\ []) do
    Agent.new(name)
    |> Agent.set_position(Keyword.get(opts, :at, {0, 0}))
    |> Agent.set_vision_range(Keyword.get(opts, :vision, 8))
    |> Agent.set_movement_speed(Keyword.get(opts, :speed, 3.0))
    |> Agent.add_capability(:scouting)
    |> Agent.add_capability(:movement)
  end
  
  def create_combat_agent(name, opts \\ []) do
    Agent.new(name) 
    |> Agent.set_position(Keyword.get(opts, :at, {0, 0}))
    |> Agent.set_attack_range(Keyword.get(opts, :range, 2))
    |> Agent.set_damage(Keyword.get(opts, :damage, 25))
    |> Agent.add_capability(:combat)
    |> Agent.add_capability(:movement)
  end
  
  # Temporal constraint shortcuts
  def sequential_actions(actions, start_time \\ 0) do
    actions
    |> Enum.with_index()
    |> Enum.reduce({[], start_time}, fn {{action, duration}, idx}, {constraints, time} ->
      interval_id = "#{action}_#{idx}"
      constraint = temporal_interval(interval_id, time, time + duration)
      {[constraint | constraints], time + duration}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
  
  def parallel_actions(actions, start_time, end_time) do
    Enum.map(actions, fn action ->
      temporal_interval("#{action}_parallel", start_time, end_time)
    end)
  end
end
```

### Visual Timeline Debugging

Enhance the temporal planner with visual debugging capabilities:

```elixir
defmodule TemporalPlanner.Debug do
  @moduledoc """
  Developer debugging tools for temporal planner following ADR-042 implementation
  with enhanced developer experience per ADR-048.
  """
  
  def visualize_timeline(plan, opts \\ []) do
    width = Keyword.get(opts, :width, 80)
    show_constraints = Keyword.get(opts, :constraints, true)
    
    IO.puts("\n=== Temporal Plan Timeline ===")
    IO.puts(format_timeline_header(plan.duration, width))
    
    plan.actions
    |> Enum.each(&format_action_timeline(&1, plan.duration, width))
    
    if show_constraints do
      IO.puts("\n--- Temporal Constraints ---")
      plan.constraints
      |> Enum.each(&format_constraint(&1))
    end
    
    IO.puts("\n=== Plan Statistics ===")
    IO.puts("Total duration: #{plan.duration}s")
    IO.puts("Action count: #{length(plan.actions)}")
    IO.puts("Constraint count: #{length(plan.constraints)}")
    IO.puts("Parallelization factor: #{calculate_parallelization(plan)}")
  end
  
  def explain_planning_failure(result) do
    case result do
      {:error, :constraint_conflict, details} ->
        IO.puts("❌ Planning failed due to constraint conflict:")
        explain_constraint_conflict(details)
        
      {:error, :no_solution, search_stats} ->
        IO.puts("❌ No valid plan found:")
        IO.puts("  Search space explored: #{search_stats.nodes_visited}")
        IO.puts("  Max depth reached: #{search_stats.max_depth}")
        suggest_relaxation_strategies(search_stats)
        
      {:error, :timeout, partial_plan} ->
        IO.puts("⏱️  Planning timed out with partial solution:")
        visualize_timeline(partial_plan, width: 60)
    end
  end
end
```

### Type-Safe Configuration DSL

Provide compile-time validation for temporal planner configuration:

```elixir
defmodule TemporalPlanner.Config do
  @moduledoc """
  Type-safe configuration DSL for temporal planner setup following ADR-042
  with enhanced developer experience per ADR-048.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  # Compile-time validated planner configuration
  @primary_key false
  embedded_schema do
    field :max_search_depth, :integer, default: 10
    field :planning_timeout_ms, :integer, default: 5000
    field :constraint_solver, Ecto.Enum, values: [:pc2, :incremental_pc2], default: :pc2
    field :enable_debugging, :boolean, default: false
    field :timeline_resolution, :float, default: 0.1
    
    embeds_many :default_agent_capabilities, AgentCapability do
      field :name, :string
      field :duration_ms, :integer
      field :cooldown_ms, :integer, default: 0
    end
  end
  
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:max_search_depth, :planning_timeout_ms, :constraint_solver, 
                    :enable_debugging, :timeline_resolution])
    |> validate_required([:max_search_depth, :planning_timeout_ms])
    |> validate_number(:max_search_depth, greater_than: 0, less_than: 100)
    |> validate_number(:planning_timeout_ms, greater_than: 100)
    |> validate_number(:timeline_resolution, greater_than: 0.01, less_than: 1.0)
    |> cast_embed(:default_agent_capabilities)
  end
  
  # Fluent configuration builder
  def new() do
    %__MODULE__{}
  end
  
  def with_search_depth(config, depth) when is_integer(depth) and depth > 0 do
    %{config | max_search_depth: depth}
  end
  
  def with_timeout(config, timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    %{config | planning_timeout_ms: timeout_ms}
  end
  
  def enable_debug_mode(config) do
    %{config | enable_debugging: true}
  end
end

# Usage in tests following ADR-042 staged approach
test "Stage 1: Basic temporal constraint satisfaction with enhanced config" do
  config = TemporalPlanner.Config.new()
    |> TemporalPlanner.Config.with_search_depth(5)
    |> TemporalPlanner.Config.with_timeout(1000)
    |> TemporalPlanner.Config.enable_debug_mode()
  
  scenario = TemporalScenario.new()
    |> add_agent(:maya, at: {3, 5})
    |> set_goal(:maya, :move_to, {15, 5})
    |> with_config(config)
  
  assert_temporal_planning(scenario)
end
```

### Enhanced Test Assertion Helpers

Provide semantic assertions that improve test readability and error messages:

```elixir
defmodule TemporalPlannerTest.Assertions do
  @moduledoc """
  Enhanced assertions for temporal planner testing following ADR-042 methodology
  with improved developer experience per ADR-048.
  """
  
  import ExUnit.Assertions
  
  def assert_temporal_planning(scenario, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)
    
    case TemporalPlanner.plan(scenario, timeout: timeout) do
      {:ok, plan} ->
        validate_plan_correctness(plan, scenario)
        
      {:error, reason} ->
        TemporalPlanner.Debug.explain_planning_failure({:error, reason})
        flunk("Temporal planning failed: #{inspect(reason)}")
    end
  end
  
  def assert_plan_duration(plan, expected_duration, tolerance \\ 0.1) do
    actual_duration = TemporalPlan.total_duration(plan)
    
    assert abs(actual_duration - expected_duration) <= tolerance,
      """
      Plan duration mismatch:
      Expected: #{expected_duration}s (±#{tolerance}s)
      Actual: #{actual_duration}s
      
      #{TemporalPlanner.Debug.format_timeline_summary(plan)}
      """
  end
  
  def assert_agent_reaches_goal(plan, agent_id, goal_position, within_time) do
    agent_actions = TemporalPlan.actions_for_agent(plan, agent_id)
    final_position = TemporalPlan.final_position(agent_actions)
    completion_time = TemporalPlan.completion_time(agent_actions)
    
    assert final_position == goal_position,
      "Agent #{agent_id} did not reach goal position #{inspect(goal_position)}, ended at #{inspect(final_position)}"
    
    assert completion_time <= within_time,
      "Agent #{agent_id} took #{completion_time}s, exceeded limit of #{within_time}s"
  end
  
  def assert_constraints_satisfied(plan) do
    violations = TemporalConstraints.validate(plan)
    
    assert Enum.empty?(violations),
      """
      Temporal constraint violations detected:
      #{Enum.map(violations, &format_violation/1) |> Enum.join("\n")}
      
      #{TemporalPlanner.Debug.format_constraint_summary(plan.constraints)}
      """
  end
end
```

## Migration Strategy from ADR-042

The enhanced APIs build upon ADR-042's staged implementation without disrupting the existing roadmap:

### Stage 1 Enhancement: Basic Planning with Developer APIs

```elixir
# Original ADR-042 Stage 1
test "Maya moves from (3,5) to (15,5) in minimum time" do
  # Complex manual setup...
end

# Enhanced Stage 1 with ADR-048 APIs  
test "Maya moves from (3,5) to (15,5) in minimum time" do
  scenario = TemporalScenario.new()
    |> add_agent(:maya, at: {3, 5}, speed: 3.0)
    |> set_goal(:maya, :move_to, {15, 5})
    |> expect_minimum_time_solution()
  
  plan = assert_temporal_planning(scenario)
  assert_plan_duration(plan, 4.0, tolerance: 0.1) # distance 12 / speed 3.0
end
```

### Stage 2 Enhancement: Constraint Networks with Visual Debugging

```elixir
test "Maya's scouting mission with temporal constraints and debugging" do
  scenario = TemporalScenario.new()
    |> add_agent(:maya, at: {3, 5}, vision_range: 8)
    |> set_goal(:maya, :scout_and_return, start: {3, 5}, target: {15, 5})
    |> add_temporal_sequence([
        {:move_to_observation, 15.0},
        {:scout_area, 5.0}, 
        {:return_to_base, 15.0}
      ])
    |> enable_visual_debugging()
  
  plan = assert_temporal_planning(scenario)
  
  # Automatic timeline visualization in test output when debugging enabled
  # Visual constraint validation with clear error messages
  assert_constraints_satisfied(plan)
end
```

## Implementation Requirements

### Core Components

1. **TemporalScenario Builder**: Fluent API for test scenario creation
2. **Enhanced Test Assertions**: Semantic validation with clear error messages  
3. **Visual Debugging Tools**: Timeline visualization and constraint analysis
4. **Type-Safe Configuration**: Compile-time validated planner setup
5. **Agent/Action Builders**: Domain-specific configuration helpers

### Integration with ADR-042 Stages

- **Stage 1**: Add fluent scenario builders and basic assertions
- **Stage 2**: Integrate visual debugging and constraint visualization  
- **Stage 3**: Enhance with performance profiling and optimization hints
- **Stage 4**: Add production-ready configuration management

### Backward Compatibility

All enhanced APIs are additive and maintain full compatibility with ADR-042's implementation approach. Existing tests continue to work unchanged while new tests can leverage the improved developer experience.

## Consequences

### Positive

- **Reduced Development Time**: Fluent APIs eliminate repetitive boilerplate setup
- **Better Test Readability**: Semantic builders make test intent immediately clear
- **Faster Debugging**: Visual timeline tools accelerate problem identification
- **Lower Learning Curve**: New developers can contribute without deep temporal planning knowledge
- **Improved Maintainability**: Type-safe configuration prevents runtime errors
- **Enhanced Collaboration**: Clear, self-documenting test scenarios improve team velocity

### Negative

- **Additional Complexity**: More API surface area to maintain and document
- **Potential Over-Abstraction**: Risk of hiding important temporal planning details
- **Learning Overhead**: Developers must learn both low-level and high-level APIs
- **Testing Coverage**: Enhanced APIs themselves require comprehensive testing
- **Performance Implications**: Additional abstraction layers may impact performance

## Related ADRs

- **ADR-042**: Temporal Planner Cold Boot Implementation Order (foundation for staged development)
- **ADR-046**: User-Friendly Temporal Constraint Specification (API design patterns)
- **ADR-045**: Allen's Interval Algebra for Temporal Relationships (constraint specification)
- **ADR-034**: Definitive Temporal Planner Architecture (overall system architecture)

---

*This ADR enhances the temporal planner implementation roadmap established in ADR-042 with developer-friendly APIs that maintain the staged TDD approach while dramatically improving developer productivity and code maintainability.*
