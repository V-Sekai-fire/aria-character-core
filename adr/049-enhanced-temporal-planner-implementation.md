# ADR-049: Enhanced Temporal Planner Implementation with Unified APIs

## Status

Accepted (Supersedes ADR-042)

## Context

ADR-042 established a staged Test-Driven Development approach for temporal planner implementation, but several subsequent ADRs have introduced significant improvements that warrant a unified implementation strategy:

- **ADR-046**: User-Friendly Temporal Constraint Specification - introduced fluent constraint building APIs
- **ADR-047**: TimeStrike Temporal Planner Test Scenario - defined comprehensive validation scenarios
- **ADR-048**: Developer-Friendly APIs for Temporal Planner Implementation - enhanced developer experience

The original ADR-042 approach, while sound in methodology, lacks the usability improvements and comprehensive test framework that have since been developed. A unified implementation approach that leverages these enhancements from the start will provide better developer productivity and more robust validation.

## Decision

We will implement the temporal planner using an enhanced staged TDD approach that integrates the user-friendly APIs from ADR-046, the comprehensive TimeStrike test scenarios from ADR-047, and the developer experience improvements from ADR-048.

## Enhanced Implementation Stages

### Stage 1: TimeStrike Agent Movement with Fluent APIs

Replace low-level JSON-LD manipulation with semantic agent and constraint builders:

```elixir
defmodule AriaTimestrike.TemporalPlannerTest do
  use ExUnit.Case
  import AriaTimestrike.TestHelpers.TemporalScenario
  import AriaTimestrike.TestHelpers.TimeStrikeAgents

  test "Alex moves from spawn to hostage position within time constraints" do
    scenario = timestrike_scenario()
      |> add_player_agent(:alex, 
          position: {4, 4}, 
          hp: 120, 
          attack: 25, 
          defense: 15, 
          speed: 4.0,
          skills: [:delaying_strike])
      |> set_goal(:alex, :reach_position, {20, 5}, within: 12.0)
      |> add_temporal_constraint(:hostage_rescue_window, 0..12)
      |> add_obstacle(:soldier_1, at: {15, 4}, blocks_path: true)
      |> expect_plan_success()

    plan = assert_temporal_planning(scenario)
    
    # Validate using TimeStrike scenario requirements from ADR-047
    assert_agent_reaches_goal(plan, :alex, {20, 5}, within: 12.0)
    assert_plan_respects_movement_speed(plan, :alex, 4.0)
    assert_no_collision_with_obstacles(plan, :alex)
  end

  test "Maya uses Scorch to clear path for Alex's hostage rescue" do
    scenario = timestrike_scenario()
      |> add_player_agent(:maya, 
          position: {3, 5}, 
          hp: 80, 
          attack: 35, 
          defense: 5, 
          speed: 3.0,
          skills: [:scorch])
      |> add_player_agent(:alex, 
          position: {4, 4}, 
          hp: 120, 
          speed: 4.0)
      |> add_enemy_agent(:soldier_2, at: {15, 5}, hp: 70)
      |> set_goal(:alex, :reach_position, {20, 5}, within: 12.0)
      |> add_skill_constraint(:maya, :scorch, 
          cast_time: 2.0, 
          cooldown: 8.0, 
          area_effect: {3, 3})
      |> add_coordination_requirement(:maya_clears_path_for_alex)
      |> enable_visual_debugging()

    plan = assert_temporal_planning(scenario)
    
    # Validate temporal coordination using ADR-046 constraint specification
    assert_skill_used(plan, :maya, :scorch, before: :alex_movement)
    assert_temporal_sequence(plan, [
      {:maya_moves_to_casting_position, within: 10.0},
      {:maya_casts_scorch, duration: 2.0},
      {:alex_advances_through_cleared_area, after_scorch: true}
    ])
  end
end
```

### Stage 2: Multi-Agent Coordination with TimeStrike Conviction Choices

Implement the conviction choice mechanics from ADR-047 using fluent constraint APIs:

```elixir
defmodule AriaTimestrike.ConvictionChoiceTest do
  use ExUnit.Case
  import AriaTimestrike.TestHelpers.ConvictionScenarios

  test "Morality choice: rescue hostage with coordinated team tactics" do
    scenario = conviction_scenario(:morality)
      |> set_team_goal(:rescue_hostage, target: {20, 5}, deadline: 12.0)
      |> add_temporal_pressure(:hostage_execution, at: 12.0)
      |> add_enemy_resistance(:standard_patrol, strength: :medium)
      |> expect_coordinated_team_plan()

    plan = assert_temporal_planning(scenario, timeout: 5000)
    
    # Validate ADR-047 success conditions
    assert_conviction_goal_achieved(plan, :morality)
    assert_hostage_rescued_in_time(plan)
    assert_team_coordination_effective(plan)
    
    # Visual debugging from ADR-048
    if System.get_env("DEBUG_TEMPORAL_PLANS") do
      TemporalPlanner.Debug.visualize_timeline(plan, show_conviction_choice: true)
    end
  end

  test "Utility choice: destroy bridge with split operations" do
    scenario = conviction_scenario(:utility)
      |> set_team_goal(:destroy_bridge, 
          targets: [{10, 3}, {10, 7}], 
          target_hp: 150,
          before_reinforcements: 45.0)
      |> add_split_operation_requirement()
      |> add_defensive_positioning(:alex_jordan_line)
      |> add_destruction_sequence(:maya_pillar_assault)
      |> expect_complex_coordination()

    plan = assert_temporal_planning(scenario)
    
    # Validate bridge destruction using ADR-046 temporal relations
    assert_both_pillars_destroyed(plan)
    assert_temporal_relation(plan, :defensive_line, :during, :maya_assault)
    assert_temporal_relation(plan, :bridge_destruction, :before, :enemy_reinforcements)
  end

  test "Liberty choice: fighting retreat with temporal coordination" do
    scenario = conviction_scenario(:liberty)
      |> set_team_goal(:escape_to_zone, boundary: {x: 24}, all_agents: true)
      |> add_pursuit_pressure(:enemy_chase, intensity: :high)
      |> add_chokepoint_defense(:maya_scorch_barriers)
      |> add_temporal_sequence([
          {:defensive_actions, 0..15},
          {:fighting_retreat, 15..35},
          {:final_escape, 35..45}
        ])

    plan = assert_temporal_planning(scenario)
    
    # Validate escape success with temporal constraints
    assert_all_agents_escape(plan)
    assert_chokepoint_tactics_effective(plan)
    assert_retreat_timing_optimal(plan)
  end
end
```

### Stage 3: Complex Temporal Networks with Allen's Interval Algebra

Integrate ADR-045's interval algebra with ADR-046's fluent APIs:

```elixir
defmodule AriaTimestrike.ComplexTemporalTest do
  use ExUnit.Case
  import AriaTimestrike.TestHelpers.IntervalAlgebra

  test "Jordan's Now! skill creates temporal plan re-entrancy" do
    scenario = timestrike_scenario()
      |> add_player_agent(:jordan, 
          position: {4, 6}, 
          skills: [:now_skill])
      |> add_player_agent(:alex, 
          position: {4, 4}, 
          skills: [:delaying_strike])
      |> add_skill_constraint(:jordan, :now_skill, 
          cast_time: 0.5, 
          cooldown: 20.0, 
          effect: :reset_ally_action)
      |> add_temporal_network do
          interval(:alex_first_action, 0, 5)
          interval(:jordan_now_cast, 5, 5.5) 
          interval(:alex_second_action, 5.5, 10.5)
          
          # Using ADR-045 Allen's interval relations via ADR-046 API
          constraint(:alex_first_action, :meets, :jordan_now_cast)
          constraint(:jordan_now_cast, :meets, :alex_second_action)
          constraint(:alex_second_action, :enabled_by, :jordan_now_cast)
        end
      |> expect_re_entrant_planning()

    plan = assert_temporal_planning(scenario)
    
    # Validate re-entrancy using enhanced assertions from ADR-048
    assert_skill_resets_action(plan, :jordan, :now_skill, target: :alex)
    assert_temporal_interval_satisfaction(plan, using: :allen_algebra)
    assert_plan_handles_re_entrancy(plan)
  end

  test "Complex battlefield coordination with overlapping temporal constraints" do
    scenario = full_timestrike_scenario()
      |> add_all_player_agents()  # Alex, Maya, Jordan from ADR-047
      |> add_all_enemy_agents()   # Soldiers and Archers
      |> set_conviction_choice(:valor)  # Eliminate all enemies
      |> add_complex_temporal_network do
          # Parallel attack preparation
          parallel_group(:attack_preparation, 0, 10, [
            :alex_positioning,
            :maya_spell_preparation, 
            :jordan_support_setup
          ])
          
          # Sequential attack phases using ADR-046 shorthand
          sequence(:attack_execution, 10, [
            {:coordinated_assault, 5.0},
            {:enemy_response, 3.0},
            {:tactical_adjustment, 4.0},
            {:final_elimination, 8.0}
          ])
          
          # Conditional constraints from ADR-046
          conditional(:emergency_retreat, 
            trigger: :health_critical,
            during: :attack_execution,
            priority: :high)
        end

    plan = assert_temporal_planning(scenario, max_search_depth: 15)
    
    # Comprehensive validation using all ADR enhancements
    assert_conviction_goal_achieved(plan, :valor)
    assert_all_enemies_eliminated(plan)
    assert_temporal_network_satisfied(plan)
    assert_agent_coordination_optimal(plan)
    
    # Performance validation from ADR-048
    assert_planning_time_acceptable(plan, max_ms: 10000)
    assert_plan_execution_efficient(plan)
  end
end
```

### Stage 4: Production Integration with Type-Safe Configuration

Apply ADR-048's configuration management to real-world scenarios:

```elixir
defmodule AriaTimestrike.ProductionIntegrationTest do
  use ExUnit.Case
  import AriaTimestrike.TestHelpers.ProductionScenarios

  test "Production temporal planner with optimized configuration" do
    config = TemporalPlanner.Config.new()
      |> TemporalPlanner.Config.with_search_depth(20)
      |> TemporalPlanner.Config.with_timeout(15_000)
      |> TemporalPlanner.Config.set_constraint_solver(:incremental_pc2)
      |> TemporalPlanner.Config.enable_performance_profiling()
      |> TemporalPlanner.Config.set_timeline_resolution(0.1)

    scenario = production_timestrike_scenario()
      |> add_full_agent_roster()
      |> add_dynamic_environment_changes()
      |> add_player_choice_points(4)  # All conviction choices available
      |> with_config(config)
      |> expect_production_quality_plan()

    plan = assert_temporal_planning(scenario)
    
    # Production validation
    assert_plan_meets_production_requirements(plan)
    assert_performance_within_targets(plan)
    assert_memory_usage_acceptable(plan)
    assert_plan_serializable(plan)
  end

  test "Real-time plan adaptation with conviction choice changes" do
    scenario = adaptive_timestrike_scenario()
      |> start_with_conviction(:survival)
      |> add_mid_execution_choice_change(:morality, at: 15.0)
      |> expect_dynamic_replanning()

    initial_plan = assert_temporal_planning(scenario)
    
    # Simulate conviction choice change during execution
    updated_scenario = scenario
      |> trigger_conviction_change(:morality, context: :new_information)
      |> from_partial_execution(initial_plan, at: 15.0)

    new_plan = assert_temporal_replanning(updated_scenario, from: initial_plan)
    
    # Validate adaptation using ADR-047 mechanics
    assert_conviction_change_handled(new_plan, from: :survival, to: :morality)
    assert_plan_continuity_maintained(new_plan, from: initial_plan)
    assert_re_planning_time_acceptable(new_plan)
  end
end
```

## Enhanced Test Infrastructure

### TimeStrike Agent Builders (from ADR-047)

```elixir
defmodule AriaTimestrike.TestHelpers.TimeStrikeAgents do
  @moduledoc """
  Agent builders specific to TimeStrike scenario from ADR-047
  """

  def alex(opts \\ []) do
    create_agent(:alex, Keyword.merge([
      position: {4, 4},
      hp: 120,
      attack: 25,
      defense: 15,
      speed: 4.0,
      skills: [:delaying_strike]
    ], opts))
  end

  def maya(opts \\ []) do
    create_agent(:maya, Keyword.merge([
      position: {3, 5},
      hp: 80,
      attack: 35,
      defense: 5,
      speed: 3.0,
      skills: [:scorch]
    ], opts))
  end

  def jordan(opts \\ []) do
    create_agent(:jordan, Keyword.merge([
      position: {4, 6},
      hp: 95,
      attack: 10,
      defense: 10,
      speed: 3.0,
      skills: [:now_skill]
    ], opts))
  end
end
```

### Fluent Constraint Builders (from ADR-046)

```elixir
defmodule AriaTimestrike.TestHelpers.TemporalConstraints do
  @moduledoc """
  Fluent temporal constraint specification from ADR-046
  """

  def add_temporal_network(scenario, builder_fn) do
    network = TemporalConstraintNetwork.new()
    enhanced_network = builder_fn.(network)
    Map.put(scenario, :constraint_network, enhanced_network)
  end

  def parallel_group(network, name, start_time, end_time, actions) do
    network
    |> add_interval(name, start_time, end_time)
    |> add_parallel_actions(actions, start_time, end_time)
    |> add_containment(name, actions)
  end

  def sequence(network, name, start_time, action_durations) do
    {intervals, _final_time} = Enum.reduce(action_durations, {[], start_time}, 
      fn {action, duration}, {acc, time} ->
        interval = add_interval(network, action, time, time + duration)
        {[interval | acc], time + duration}
      end)
    
    intervals
    |> Enum.reverse()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(network, fn [prev, next], net ->
        add_constraint(net, prev, :meets, next)
      end)
  end
end
```

## Migration from ADR-042

### Advantages Over ADR-042

1. **Unified API Experience**: No transition from low-level to high-level APIs
2. **Comprehensive Test Coverage**: TimeStrike scenarios provide realistic validation from day one
3. **Enhanced Debugging**: Visual tools and semantic assertions reduce debugging time
4. **Type Safety**: Configuration errors caught at compile time rather than runtime
5. **Production Ready**: APIs designed for both testing and production use

### Backward Compatibility

Existing ADR-042 implementations can migrate incrementally:

```elixir
# ADR-042 style (still supported)
test "legacy temporal constraint test" do
  initial_state = JsonLdTemporalState.new(...)
  # ... manual setup
end

# ADR-049 style (recommended)
test "enhanced temporal constraint test" do
  scenario = timestrike_scenario()
    |> add_agent(...)
    |> set_goal(...)
  
  assert_temporal_planning(scenario)
end
```

## Implementation Requirements

### Core Components

1. **TemporalScenario Builder**: Unified scenario creation combining ADR-046 and ADR-047 APIs
2. **TimeStrike Agent Library**: Pre-configured agents matching ADR-047 specifications
3. **Enhanced Assertion Framework**: Semantic validation with clear error reporting
4. **Visual Debugging Integration**: Timeline visualization and plan explanation tools
5. **Type-Safe Configuration**: Production-ready planner configuration management

### Development Workflow

1. **Stage 1**: Implement basic agent movement with fluent APIs and TimeStrike agents
2. **Stage 2**: Add multi-agent coordination using conviction choice scenarios
3. **Stage 3**: Integrate complex temporal networks with Allen's interval algebra
4. **Stage 4**: Production deployment with optimized configuration and real-time adaptation

## Consequences

### Positive

- **Accelerated Development**: Fluent APIs and pre-built scenarios reduce implementation time
- **Better Test Coverage**: TimeStrike scenarios provide comprehensive edge case validation
- **Improved Maintainability**: Type-safe configuration and semantic APIs reduce runtime errors
- **Enhanced Debugging**: Visual tools and explanatory messages accelerate problem resolution
- **Production Readiness**: APIs designed for both development and production deployment

### Negative

- **Learning Curve**: Developers must understand multiple API layers (ADR-046, ADR-047, ADR-048)
- **Increased Complexity**: More abstraction layers may hide important implementation details
- **API Stability Risk**: Rapid evolution of multiple API layers may introduce breaking changes
- **Performance Overhead**: Additional abstraction may impact critical path performance

## Related ADRs

- **ADR-042**: Temporal Planner Cold Boot Implementation Order (superseded by this ADR)
- **ADR-046**: User-Friendly Temporal Constraint Specification (foundational API patterns)
- **ADR-047**: TimeStrike Temporal Planner Test Scenario (comprehensive test framework)
- **ADR-048**: Developer-Friendly APIs for Temporal Planner Implementation (developer experience)
- **ADR-045**: Allen's Interval Algebra for Temporal Relationships (constraint specification)

---

*This ADR supersedes ADR-042 by providing a unified implementation approach that integrates the user-friendly APIs, comprehensive test scenarios, and developer experience improvements established in subsequent ADRs, resulting in a more productive and robust temporal planner development process.*
