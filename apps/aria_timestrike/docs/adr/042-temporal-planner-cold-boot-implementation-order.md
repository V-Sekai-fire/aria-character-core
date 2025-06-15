# ADR-042: Temporal Planner Cold Boot Implementation Order

## Status

Accepted

## Date

2025-06-14

## Context

Based on the comprehensive analysis of ADRs 034-041, we need a precise Test-Driven Development (TDD) implementation order for the temporal planner that solves the canonical temporal backtracking problem defined in ADR-035. This ADR provides the exact cold boot sequence that builds from the existing codebase foundation toward the complete temporal planning capability.

The implementation must pass ADR-035's "Maya's Adaptive Scorch Coordination" problem, which requires multi-phase backtracking through information gathering, temporal coordination, opportunity windows, and emergency fallback scenarios. The solution builds incrementally using TDD principles with each component validated before proceeding.

**Key Architectural Insight**: The JSON-LD data structure with chibifire.com namespace IS the solution network itself. This semantic representation enables both human-readable temporal plans and machine-processable constraint networks, providing the foundation for all temporal reasoning operations.

## Decision

Implement the temporal planner using strict TDD methodology with the following exact cold boot order, where each step builds verified functionality before advancing to the next level.

## Cold Boot Implementation Order

### Phase 1: Foundation Data Structures (TDD Red-Green-Refactor)

#### Step 1.1: Temporal State Core
**Test First**: ADR-035 canonical problem state initialization
```elixir
# test/aria_engine/temporal_state_test.exs
defmodule AriaEngine.TemporalStateTest do
  use ExUnit.Case, async: true
  
  test "initializes Maya's Adaptive Scorch scenario state" do
    initial_state = TemporalState.new(0)
    |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
    |> TemporalState.set_temporal_object("vision_range", "maya", 8, 0)
    |> TemporalState.set_temporal_object("position", "alex", {4, 4, 0}, 0)
    |> TemporalState.set_temporal_object("position", "soldier2", {15, 5, 0}, 0)
    
    assert TemporalState.get_temporal_object(initial_state, "position", "maya", 0) == {3, 5, 0}
    assert TemporalState.get_temporal_object(initial_state, "vision_range", "maya", 0) == 8
  end
  
  test "supports time-based queries for state history" do
    state = TemporalState.new(0)
    |> TemporalState.set_temporal_object("position", "soldier2", {15, 5, 0}, 0)
    |> TemporalState.set_temporal_object("position", "soldier2", {14, 5, 0}, 10)
    |> TemporalState.set_temporal_object("position", "soldier2", {13, 5, 0}, 20)
    
    assert TemporalState.get_temporal_object(state, "position", "soldier2", 5) == {15, 5, 0}
    assert TemporalState.get_temporal_object(state, "position", "soldier2", 15) == {14, 5, 0}
    assert TemporalState.query_history(state, "position", "soldier2", 0, 25) == 
           [{0, {15, 5, 0}}, {10, {14, 5, 0}}, {20, {13, 5, 0}}]
  end
end
```

**Implementation**: Extend `apps/aria_timestrike_core/lib/aria_engine/temporal_state.ex`
- Add time-indexed storage for all game objects
- Implement temporal query functions
- Support historical state reconstruction
- Pass Maya scenario initialization tests

#### Step 1.2: Timeline Data Structure  
**Test First**: Basic timeline representation for state variables
```elixir
# test/aria_engine/timeline_test.exs
defmodule AriaEngine.TimelineTest do
  use ExUnit.Case, async: true
  
  test "creates timeline for soldier2 patrol behavior" do
    timeline = Timeline.new(:position, "soldier2")
    |> Timeline.add_interval(0, 33, {15, 5, 0})    # At start waypoint
    |> Timeline.add_interval(33, 43, :moving)       # Moving to {12,5,0}
    |> Timeline.add_interval(43, 53, {12, 5, 0})    # At second waypoint (10 tick pause)
    |> Timeline.add_interval(53, 63, :moving)       # Moving back to {15,5,0}
    
    assert Timeline.get_value_at(timeline, 5) == {15, 5, 0}
    assert Timeline.get_value_at(timeline, 45) == {12, 5, 0}
    assert Timeline.find_intervals_with_value(timeline, {12, 5, 0}) == [{43, 53}]
  end
  
  test "detects timeline conflicts and overlaps" do
    timeline = Timeline.new(:battery_level, "maya")
    |> Timeline.add_interval(0, 30, 100)
    |> Timeline.add_interval(25, 50, 75)  # Overlapping interval
    
    assert {:error, :overlap_conflict} = Timeline.validate(timeline)
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/timeline.ex`
- Core timeline data structure with intervals
- Conflict detection and validation
- Value queries at specific times
- Pass soldier2 patrol timeline tests

#### Step 1.4: JSON-LD Solution Network Foundation
**Test First**: JSON-LD serialization with chibifire.com namespace as the solution network
```elixir
# test/aria_engine/json_ld_solution_network_test.exs
defmodule AriaEngine.JsonLdSolutionNetworkTest do
  use ExUnit.Case, async: true
  
  test "serializes Maya scenario as JSON-LD solution network" do
    temporal_state = build_maya_scenario_state()
    timelines = build_maya_alex_timelines()
    constraints = build_maya_temporal_constraints()
    
    {:ok, solution_network} = JsonLdSolutionNetwork.serialize(temporal_state, timelines, constraints)
    
    # Verify chibifire.com namespace
    assert solution_network["@context"]["@vocab"] == "https://chibifire.com/vocab/aria/temporal#"
    assert solution_network["@context"]["Timeline"] == "https://chibifire.com/vocab/aria/temporal#Timeline"
    assert solution_network["@context"]["Constraint"] == "https://chibifire.com/vocab/aria/temporal#Constraint"
    
    # Verify solution network structure
    assert solution_network["@type"] == "TemporalSolutionNetwork"
    assert is_list(solution_network["timelines"])
    assert is_list(solution_network["constraints"])
    assert is_map(solution_network["agents"])
  end
  
  test "round-trip serialization preserves Maya scenario semantics" do
    original_state = build_maya_scenario_state()
    
    {:ok, json_ld} = JsonLdSolutionNetwork.serialize(original_state)
    {:ok, reconstructed_state} = JsonLdSolutionNetwork.deserialize(json_ld)
    
    # Verify semantic equivalence
    assert TemporalState.get_temporal_object(reconstructed_state, "position", "maya", 0) == {3, 5, 0}
    assert TemporalState.get_temporal_object(reconstructed_state, "vision_range", "maya", 0) == 8
    assert TemporalState.get_temporal_object(reconstructed_state, "position", "soldier2", 0) == {15, 5, 0}
  end
  
  test "solution network supports RDF queries and reasoning" do
    solution_network = build_maya_solution_network()
    
    # SPARQL-like queries on the solution network
    maya_timelines = JsonLdSolutionNetwork.query(solution_network, """
      SELECT ?timeline WHERE {
        ?timeline rdf:type <https://chibifire.com/vocab/aria/temporal#Timeline> .
        ?timeline <https://chibifire.com/vocab/aria/temporal#agent> "maya" .
      }
    """)
    
    assert length(maya_timelines) >= 2  # position timeline, vision timeline
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/json_ld_solution_network.ex`
- JSON-LD serialization with chibifire.com namespace
- RDF semantic representation of temporal plans
- Round-trip serialization/deserialization
- SPARQL-compatible query interface
- Pass Maya solution network serialization tests

#### Step 1.5: Simple Temporal Network (STN) Foundation
**Test First**: STN constraint representation and basic solving
```elixir
# test/aria_engine/stn_solver_test.exs  
defmodule AriaEngine.STNSolverTest do
  use ExUnit.Case, async: true
  
  test "solves basic temporal constraints for Maya's movement" do
    # Maya must reach position before soldier2 reaches bunker
    constraints = [
      # Maya movement time: 0 <= maya_arrive - start <= 25
      STNConstraint.new(:start, :maya_arrive, 0, 25),  
      # Soldier2 bunker time: 180 <= soldier2_bunker - start <= 200
      STNConstraint.new(:start, :soldier2_bunker, 180, 200),
      # Maya must act before soldier2 reaches safety
      STNConstraint.new(:maya_arrive, :soldier2_bunker, 5, :infinity)
    ]
    
    {:ok, solution} = STNSolver.solve(constraints)
    
    # Verify solution provides valid time bounds
    assert STNSolver.get_bounds(solution, :start, :maya_arrive) == {0, 25}
    assert STNSolver.get_bounds(solution, :maya_arrive, :soldier2_bunker) >= {5, :infinity}
    assert STNSolver.is_consistent?(solution) == true
  end
  
  test "detects inconsistent temporal constraints" do
    # Impossible constraints: Maya must arrive before she starts
    constraints = [
      STNConstraint.new(:maya_arrive, :start, 1, 10)  # Impossible
    ]
    
    assert {:error, :inconsistent} = STNSolver.solve(constraints)
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/stn_solver.ex` 
- Floyd-Warshall algorithm for STN solving
- Constraint representation and validation
- Inconsistency detection
- Pass Maya movement timing tests

### Phase 2: Goal-Task-Network (GTN) Core (Building on Phase 1)

#### Step 2.1: Goal Decomposition Engine
**Test First**: Decompose ADR-035's high-level goal into tasks
```elixir
# test/aria_engine/goal_decomposer_test.exs
defmodule AriaEngine.GoalDecomposerTest do
  use ExUnit.Case, async: true
  
  test "decomposes eliminate_soldier_patrol into executable tasks" do
    initial_state = build_maya_scenario_state()
    goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
    
    {:ok, task_network} = GoalDecomposer.decompose_goal(goal, initial_state)
    
    # Verify task breakdown matches ADR-035 specification
    assert length(task_network.tasks) >= 4
    assert Enum.any?(task_network.tasks, &(&1.type == :reconnaissance_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :historical_analysis_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :coordination_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :opportunity_exploitation_task))
    
    # Verify task dependencies
    recon_task = Enum.find(task_network.tasks, &(&1.type == :reconnaissance_task))
    coord_task = Enum.find(task_network.tasks, &(&1.type == :coordination_task))
    assert coord_task.depends_on == [recon_task.id]
  end
  
  test "generates primitive actions from task breakdown" do
    task_network = build_maya_task_network()
    
    {:ok, primitive_actions} = GoalDecomposer.generate_primitive_actions(task_network)
    
    assert length(primitive_actions) >= 4
    assert Enum.any?(primitive_actions, &(&1.type == :move_to))
    assert Enum.any?(primitive_actions, &(&1.type == :scout_area))
    assert Enum.any?(primitive_actions, &(&1.type == :cast_scorch))
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/goal_decomposer.ex`
- Goal-to-task decomposition logic
- Task dependency tracking
- Primitive action generation
- Pass Maya goal decomposition tests

#### Step 2.2: Multi-Agent Coordination
**Test First**: Maya and Alex coordination for the canonical problem
```elixir
# test/aria_engine/coordination_manager_test.exs
defmodule AriaEngine.CoordinationManagerTest do
  use ExUnit.Case, async: true
  
  test "coordinates Maya and Alex for information sharing" do
    initial_state = build_maya_scenario_state()
    agents = ["maya", "alex"]
    
    {:ok, coordination} = CoordinationManager.plan_coordination(agents, initial_state)
    
    # Alex scouts first, Maya acts on shared information
    alex_scout = Enum.find(coordination.actions, &(&1.agent == "alex" and &1.type == :scout_area))
    maya_position = Enum.find(coordination.actions, &(&1.agent == "maya" and &1.type == :move_to))
    
    assert alex_scout.end_time <= maya_position.start_time
    assert maya_position.preconditions[:scout_data_available] == true  
  end
  
  test "ensures no temporal conflicts in coordinated actions" do
    coordination = build_maya_alex_coordination()
    
    conflicts = CoordinationManager.detect_conflicts(coordination)
    
    assert conflicts == []  # No temporal conflicts allowed
  end
  
  test "synchronizes timing windows for opportunity exploitation" do
    # Archer1 blocks line of sight at tick 50, creating opportunity window
    coordination = build_opportunity_coordination()
    
    archer_block_action = find_action(coordination, :archer_movement_block)
    maya_reposition = find_action(coordination, :maya_stealth_reposition)
    
    assert maya_reposition.start_time == archer_block_action.start_time
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/coordination_manager.ex`
- Multi-agent action coordination
- Information sharing between agents
- Temporal conflict detection
- Pass Maya-Alex coordination tests

### Phase 3: Temporal Constraint Integration (Building on Phases 1-2)

#### Step 3.1: JSON-LD Solution Network Integration
**Test First**: Integrate temporal planning with JSON-LD solution network serialization  
```elixir
# test/aria_engine/solution_network_integration_test.exs
defmodule AriaEngine.SolutionNetworkIntegrationTest do
  use ExUnit.Case, async: true
  
  test "serializes complete Maya temporal plan as solution network" do
    initial_state = build_maya_scenario_state()
    goal = build_eliminate_soldier_patrol_goal()
    
    {:ok, temporal_plan} = TemporalPlanner.plan(goal, initial_state)
    {:ok, solution_network} = JsonLdSolutionNetwork.from_temporal_plan(temporal_plan)
    
    # Verify complete solution network with chibifire.com namespace
    assert solution_network["@context"]["@vocab"] == "https://chibifire.com/vocab/aria/temporal#"
    assert solution_network["@type"] == "TemporalSolutionNetwork"
    
    # Solution network contains all planning artifacts
    assert is_list(solution_network["timelines"])
    assert is_list(solution_network["constraints"]) 
    assert is_list(solution_network["backtrackingPhases"])
    assert is_map(solution_network["coordinationPlan"])
  end
  
  test "solution network enables plan replay and analysis" do
    solution_network = build_maya_complete_solution_network()
    
    {:ok, replay_plan} = JsonLdSolutionNetwork.to_temporal_plan(solution_network)
    
    # Verify plan reconstruction preserves semantics
    assert replay_plan.goal.type == :eliminate_soldier_patrol
    assert length(replay_plan.backtrack_phases) >= 3
    assert replay_plan.agents == ["maya", "alex"]
  end
end
```

**Implementation**: Extend JSON-LD solution network for complete temporal plans
- Serialize backtracking phases and plan revisions
- Integrate with temporal constraint solutions
- Support plan replay from solution network
- Pass complete solution network integration tests

#### Step 3.2: STN + Timeline Integration  
**Test First**: Combine STN solving with timeline constraints
```elixir
# test/aria_engine/temporal_planner_test.exs
defmodule AriaEngine.TemporalPlannerTest do
  use ExUnit.Case, async: true
  
  test "integrates STN constraints with timeline representation" do
    # Maya's movement timeline must satisfy temporal constraints
    maya_timeline = build_maya_movement_timeline()
    temporal_constraints = build_maya_temporal_constraints()
    
    {:ok, solution} = TemporalPlanner.solve_with_timelines(maya_timeline, temporal_constraints)
    
    # Timeline values must satisfy STN bounds
    maya_arrival_time = Timeline.find_transition(solution.maya_timeline, :position, {11, 5, 0})
    stn_bounds = STNSolver.get_bounds(solution.stn_solution, :start, :maya_arrive)
    
    assert maya_arrival_time >= elem(stn_bounds, 0)
    assert maya_arrival_time <= elem(stn_bounds, 1)
  end
  
  test "detects timeline violations of temporal constraints" do
    # Maya timeline that violates soldier2 deadline
    invalid_timeline = build_invalid_maya_timeline()
    constraints = build_deadline_constraints()
    
    assert {:error, :constraint_violation} = 
      TemporalPlanner.solve_with_timelines(invalid_timeline, constraints)
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/temporal_planner.ex`
- Integration layer between STN solver and timelines
- Constraint violation detection
- Solution validation
- Pass Maya timeline integration tests

#### Step 3.3: Resource and Synchronization Constraints
**Test First**: Handle vision range and patrol behavior constraints
```elixir
# test/aria_engine/resource_constraint_test.exs
defmodule AriaEngine.ResourceConstraintTest do
  use ExUnit.Case, async: true
  
  test "enforces Maya's vision range limitation" do
    maya_state = %{position: {3, 5, 0}, vision_range: 8}
    soldier2_state = %{position: {15, 5, 0}}  # 12 units away, outside vision
    
    visibility = ResourceConstraint.check_visibility(maya_state, soldier2_state)
    
    assert visibility == false
    assert ResourceConstraint.required_scouting?(maya_state, soldier2_state) == true
  end
  
  test "models soldier2 patrol behavior as synchronization constraint" do
    patrol_constraint = SyncConstraint.new(
      condition: {:position, "soldier2", {12, 5, 0}},
      consequence: {:pause_duration, 10},
      timepoints: [:patrol_waypoint_start, :patrol_waypoint_end]
    )
    
    timeline = build_soldier2_patrol_timeline()
    
    {:ok, activated_constraints} = 
      SyncConstraint.evaluate(patrol_constraint, timeline, 45)  # tick 45
    
    assert length(activated_constraints) == 1
    assert hd(activated_constraints).type == :duration_constraint
    assert hd(activated_constraints).min_duration == 10
  end
end
```

**Implementation**: Create resource and synchronization constraint modules
- Vision range and line-of-sight modeling
- Patrol behavior as synchronization constraints
- Dynamic constraint activation
- Pass Maya visibility and patrol tests

### Phase 4: Backtracking Engine (Building on Phases 1-3)

#### Step 4.1: Conflict Detection and Backtracking Triggers
**Test First**: Detect failures that require backtracking in ADR-035 scenario
```elixir
# test/aria_engine/backtracking_engine_test.exs
defmodule AriaEngine.BacktrackingEngineTest do
  use ExUnit.Case, async: true
  
  test "detects imperfect information conflict requiring reconnaissance" do
    initial_plan = build_naive_maya_plan()  # Maya directly attacks unseen target
    state = build_maya_scenario_state()
    
    {:error, conflict} = BacktrackingEngine.validate_plan(initial_plan, state)
    
    assert conflict.type == :imperfect_information_conflict
    assert conflict.agent == "maya"
    assert conflict.missing_information == [:target_position]
    assert conflict.suggested_backtrack == :deploy_reconnaissance
  end
  
  test "detects temporal coordination conflict with patrol timing" do
    coordination_plan = build_simple_coordination_plan()  # Ignores waypoint pauses
    
    {:error, conflict} = BacktrackingEngine.validate_plan(coordination_plan, state)
    
    assert conflict.type == :temporal_prediction_conflict
    assert conflict.failed_assumption == :linear_patrol_movement
    assert conflict.suggested_backtrack == :exploit_waypoint_pauses
  end
  
  test "triggers multi-phase backtracking for cascading failures" do
    failed_plan = build_cascading_failure_plan()
    
    {:ok, backtrack_phases} = BacktrackingEngine.analyze_failures(failed_plan)
    
    assert length(backtrack_phases) >= 3
    assert Enum.any?(backtrack_phases, &(&1.type == :information_gathering))
    assert Enum.any?(backtrack_phases, &(&1.type == :temporal_coordination))
    assert Enum.any?(backtrack_phases, &(&1.type == :opportunity_exploitation))
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/backtracking_engine.ex`
- Conflict detection for different failure types
- Backtracking trigger analysis
- Multi-phase backtracking planning
- Pass Maya conflict detection tests

#### Step 4.2: Plan Revision and Alternative Generation
**Test First**: Generate alternative plans through backtracking
```elixir
# test/aria_engine/plan_revision_test.exs
defmodule AriaEngine.PlanRevisionTest do
  use ExUnit.Case, async: true
  
  test "revises plan to include Alex reconnaissance mission" do
    failed_plan = build_imperfect_information_failure()
    
    {:ok, revised_plan} = PlanRevision.backtrack_and_revise(failed_plan)
    
    # New plan includes Alex scouting task
    alex_scout = find_task(revised_plan, :agent, "alex", :type, :scout_area)
    maya_attack = find_task(revised_plan, :agent, "maya", :type, :cast_scorch)
    
    assert alex_scout != nil
    assert maya_attack.start_time > alex_scout.end_time
    assert maya_attack.preconditions[:target_visible] == true
  end
  
  test "exploits waypoint pause timing in revised coordination" do
    temporal_failure_plan = build_temporal_coordination_failure()
    
    {:ok, revised_plan} = PlanRevision.backtrack_and_revise(temporal_failure_plan)
    
    # Maya positioned during soldier2's pause at {12,5,0}
    maya_position = find_task(revised_plan, :agent, "maya", :type, :move_to)
    soldier2_pause = find_constraint(revised_plan, :type, :waypoint_pause)
    
    assert maya_position.target_position == {11, 5, 0}  # Adjacent to pause location
    assert maya_position.arrival_time >= soldier2_pause.start_time
    assert maya_position.arrival_time <= soldier2_pause.end_time
  end
  
  test "generates emergency fallback for bunker approach scenario" do
    emergency_scenario = build_emergency_bunker_scenario()
    
    {:ok, fallback_plan} = PlanRevision.generate_emergency_fallback(emergency_scenario)
    
    # Direct interception before bunker reach
    interception = find_task(fallback_plan, :type, :direct_interception)
    bunker_reach = find_constraint(fallback_plan, :type, :bunker_deadline)
    
    assert interception.execution_time < bunker_reach.deadline
  end
end
```

**Implementation**: Create `apps/aria_timestrike/lib/aria_engine/plan_revision.ex`
- Plan revision algorithms
- Alternative plan generation
- Emergency fallback planning
- Pass Maya plan revision tests

### Phase 5: Performance and Integration (Building on Phases 1-4)

#### Step 5.1: High-Performance Computing Integration
**Test First**: Verify Nx/Flow optimization for large-scale temporal problems
```elixir
# test/aria_engine/high_performance_test.exs
defmodule AriaEngine.HighPerformanceTest do
  use ExUnit.Case, async: true
  
  @tag :performance
  test "Nx tensor operations for Floyd-Warshall optimization" do
    # Large STN with 1000 timepoints  
    large_constraints = build_large_stn_constraints(1000)
    
    {time, {:ok, solution}} = :timer.tc(fn ->
      STNSolver.solve_with_nx(large_constraints)
    end)
    
    # Nx should provide significant speedup
    time_ms = time / 1000
    assert time_ms <= 100.0  # Large STN solved within 100ms
    assert STNSolver.is_consistent?(solution) == true
  end
  
  @tag :performance
  test "Flow parallel constraint propagation" do
    # Multiple independent constraint sets
    constraint_sets = build_parallel_constraint_sets(10)
    
    {time, solutions} = :timer.tc(fn ->
      constraint_sets
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(&ConstraintPropagator.propagate/1)
      |> Enum.to_list()
    end)
    
    # Parallel processing improves throughput
    time_ms = time / 1000
    assert time_ms <= 50.0
    assert length(solutions) == 10
  end
  
  @tag :performance  
  test "GenStage backpressure for real-time constraint updates" do
    # Streaming constraint updates
    {:ok, producer} = ConstraintProducer.start_link([])
    {:ok, consumer} = ConstraintConsumer.start_link([])
    
    GenStage.sync_subscribe(consumer, to: producer)
    
    # High-frequency constraint updates handled with backpressure
    for i <- 1..1000 do
      ConstraintProducer.add_constraint(producer, build_constraint(i))
    end
    
    # All constraints processed without overflow
    :timer.sleep(100)
    assert ConstraintConsumer.processed_count(consumer) == 1000
  end
end
```

**Implementation**: Performance optimization with ADR-041 tech stack
- Nx tensor operations for Floyd-Warshall algorithm
- Flow parallel processing for constraint propagation
- GenStage backpressure for real-time updates
- Pass high-performance computing integration tests

#### Step 5.2: Real-Time Performance Requirements
**Test First**: Verify ADR-035's performance requirements are met
```elixir
# test/aria_engine/performance_test.exs
defmodule AriaEngine.PerformanceTest do
  use ExUnit.Case, async: true
  
  @tag :performance
  test "planning time within 10ms bound for Maya scenario" do
    state = build_maya_scenario_state()
    goal = build_eliminate_soldier_patrol_goal()
    
    {time, {:ok, _plan}} = :timer.tc(fn ->
      TemporalPlanner.plan(goal, state)
    end)
    
    planning_time_ms = time / 1000
    assert planning_time_ms <= 10.0
  end
  
  @tag :performance  
  test "replanning faster than initial planning" do
    initial_plan = build_initial_maya_plan()
    conflict = build_reconnaissance_conflict()
    
    {initial_time, _} = :timer.tc(fn -> TemporalPlanner.plan(goal, state) end)
    {replan_time, _} = :timer.tc(fn -> 
      TemporalPlanner.replan(initial_plan, conflict) 
    end)
    
    assert replan_time < initial_time
  end
  
  @tag :performance
  test "state queries respond within 1ms" do
    state = build_large_temporal_state()  # 1000+ temporal objects
    
    {time, _result} = :timer.tc(fn ->
      TemporalState.get_temporal_object(state, "position", "soldier2", 150)
    end)
    
    query_time_ms = time / 1000
    assert query_time_ms <= 1.0
  end
end
```

**Implementation**: Performance optimization across all modules
- STN solver optimization with sparse matrices
- Timeline indexing for fast queries
- Caching for repeated computations
- Pass all performance requirement tests

#### Step 5.3: Integration with Existing AriaEngine Architecture
**Test First**: Integration with existing game engine and TUI
```elixir
# test/aria_timestrike/temporal_integration_test.exs
defmodule AriaTimestrike.TemporalIntegrationTest do
  use ExUnit.Case, async: true
  
  test "integrates with existing game state management" do
    # Uses existing AriaEngine.TemporalState from aria_timestrike_core
    game_state = AriaTimestrike.GameSupervisor.get_current_state()
    temporal_state = TemporalState.from_game_state(game_state)
    
    assert %AriaEngine.TemporalState{} = temporal_state
    assert temporal_state.agents != %{}
  end
  
  test "executes temporal plans through existing action system" do
    plan = build_maya_temporal_plan()
    
    {:ok, execution_result} = AriaTimestrike.execute_temporal_plan(plan)
    
    # Actions executed through existing AriaEngine.GameActionJob
    assert execution_result.actions_executed > 0
    assert execution_result.total_time_ms < 100
  end
  
  test "displays temporal planning in TUI interface" do
    plan = build_maya_temporal_plan()
    
    tui_output = AriaTimestrike.TuiContentProvider.format_temporal_plan(plan)
    
    assert String.contains?(tui_output, "Maya:")
    assert String.contains?(tui_output, "Alex:")
    assert String.contains?(tui_output, "Timeline:")
  end
end
```

**Implementation**: Integration layer with existing AriaEngine
- Adapter for existing game state structures  
- Action execution through AriaEngine.GameActionJob
- TUI display for temporal plans
- OTP supervision tree integration per ADR-041
- Pass integration tests with existing system

## Verification Criteria

Each phase must pass all tests before proceeding to the next phase:

### Phase 1 Completion Criteria
- ✅ Temporal state initialization for Maya scenario
- ✅ Time-based queries and historical reconstruction
- ✅ Basic timeline representation and conflict detection
- ✅ JSON-LD solution network serialization with chibifire.com namespace
- ✅ STN constraint solving with Floyd-Warshall algorithm

### Phase 2 Completion Criteria  
- ✅ Goal decomposition into ADR-035's required tasks
- ✅ Multi-agent coordination for Maya and Alex
- ✅ Information sharing and timing synchronization
- ✅ Primitive action generation from tasks

### Phase 3 Completion Criteria
- ✅ JSON-LD solution network integration with temporal plans
- ✅ STN + Timeline integration with constraint satisfaction
- ✅ Vision range and line-of-sight modeling
- ✅ Patrol behavior as synchronization constraints
- ✅ Resource constraint validation

### Phase 4 Completion Criteria
- ✅ Conflict detection for all ADR-035 failure scenarios
- ✅ Multi-phase backtracking plan revision  
- ✅ Alternative plan generation through backtracking
- ✅ Emergency fallback planning

### Phase 5 Completion Criteria
- ✅ Nx/Flow high-performance computing integration
- ✅ Planning time ≤ 10ms for Maya scenario
- ✅ Replanning faster than initial planning
- ✅ State queries ≤ 1ms response time
- ✅ Integration with existing AriaEngine architecture

### Final Validation: ADR-035 Canonical Problem Solution

The complete implementation must successfully solve Maya's Adaptive Scorch Coordination:

```elixir
# Final integration test that proves TDD implementation success
test "solves Maya's Adaptive Scorch Coordination completely" do
  initial_state = build_maya_scenario_state()
  goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
  
  {:ok, solution} = TemporalPlanner.solve_canonical_problem(goal, initial_state)
  
  # Verify all ADR-035 requirements satisfied
  assert solution.backtrack_phases >= 3
  assert solution.conflict_types_addressed >= 3  
  assert solution.information_gathering_successful == true
  assert solution.temporal_coordination_successful == true
  assert solution.opportunity_exploitation_successful == true
  assert solution.planning_time_ms <= 10.0
  assert solution.soldier2_eliminated == true
  assert solution.maya_safety_maintained == true
end
```

## Implementation Schedule

**Strict TDD Order**: Each step must pass all tests before proceeding
- **Phase 1**: Foundation (Red-Green-Refactor for data structures)
- **Phase 2**: GTN Core (Red-Green-Refactor for planning logic)  
- **Phase 3**: Constraints (Red-Green-Refactor for temporal reasoning)
- **Phase 4**: Backtracking (Red-Green-Refactor for plan revision)
- **Phase 5**: Performance (Red-Green-Refactor for optimization)

**Success Criteria**: Complete solution to ADR-035's canonical temporal backtracking problem with all performance requirements met.

## Related ADRs

- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md) - **The definitive test case**
- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md) - **Architecture foundation**
- [ADR-040: Temporal Constraint Solver Selection](040-temporal-constraint-solver-selection.md) - **STN solver specification**
- [ADR-041: Temporal Solver Tech Stack Requirements](041-temporal-solver-tech-stack-requirements.md) - **Implementation tech stack**
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md) - **Timeline approach rationale**
- [ADR-038: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md) - **Deprecated**

This cold boot order ensures disciplined TDD implementation that builds verified functionality incrementally toward solving the complete canonical temporal backtracking problem.
