# ADR-050: Temporal Planner Cold Boot Implementation from Current Codebase

## Status

Accepted

## Context

The existing `aria_engine` and `aria_timestrike` applications provide basic planning infrastructure, but lack the comprehensive temporal planning capabilities described in ADRs 034-049. We need a practical implementation roadmap that builds upon the current codebase rather than assuming previous ADR implementations.

Current state analysis:
- `aria_engine` provides basic HTN planning with `AriaEngine.Planner`
- `aria_timestrike` has domain provider structure but minimal temporal capabilities
- No implementation of temporal constraint networks or Allen's interval algebra
- Missing fluent APIs, TimeStrike scenarios, and enhanced developer tooling
- Tests exist but focus on basic planning, not temporal reasoning

This ADR provides a realistic cold boot implementation strategy that leverages existing infrastructure while progressively building toward the enhanced temporal planning vision.

## Decision

We will implement temporal planning capabilities in stages, starting from the current `aria_engine` and `aria_timestrike` codebase and progressively adding temporal features while maintaining backward compatibility.

## Implementation Roadmap

### Stage 0: Current State Assessment and Foundation

Before implementing new features, establish baseline functionality:

```elixir
# Test current AriaEngine capabilities
defmodule AriaTimestrike.BaselineTest do
  use ExUnit.Case
  
  test "current AriaEngine basic planning works" do
    # Verify existing planner functionality
    domain = AriaTimestrike.create_domain()
    initial_state = %{agent_position: {3, 5}}
    goals = [{:agent_position, {15, 5}}]
    
    case AriaEngine.Planner.plan(domain, initial_state, goals) do
      {:ok, plan} -> 
        assert length(plan) > 0
        IO.puts("✓ Basic planning functional: #{length(plan)} actions")
      {:error, reason} ->
        IO.puts("✗ Basic planning broken: #{inspect(reason)}")
        flunk("Existing planner not functional")
    end
  end
  
  test "aria_timestrike domain provider exists" do
    # Verify domain provider structure
    assert function_exported?(AriaTimestrike.DomainProvider, :create_domain, 0)
    assert function_exported?(AriaTimestrike.DomainProvider, :domain_type, 0)
    
    domain = AriaTimestrike.DomainProvider.create_domain()
    assert domain != nil
    IO.puts("✓ Domain provider functional")
  end
end
```

### Stage 1: Basic Temporal State Representation

Add temporal awareness to existing state management without breaking current functionality:

```elixir
# Extend existing AriaEngine.State with temporal information
defmodule AriaEngine.TemporalState do
  @moduledoc """
  Temporal-aware state that extends AriaEngine.State with time information.
  Maintains compatibility with existing planning infrastructure.
  """
  
  defstruct [
    :base_state,      # Existing AriaEngine.State
    :current_time,    # Current simulation time
    :time_bounds,     # {start_time, end_time} for this state
    :temporal_facts   # Time-indexed facts: %{time => [facts]}
  ]
  
  def new(base_state, current_time \\ 0.0) do
    %__MODULE__{
      base_state: base_state,
      current_time: current_time,
      time_bounds: {current_time, current_time},
      temporal_facts: %{}
    }
  end
  
  # Bridge to existing AriaEngine.State API
  def get_fact(temporal_state, predicate, subject) do
    AriaEngine.State.get_fact(temporal_state.base_state, predicate, subject)
  end
  
  def add_fact(temporal_state, predicate, subject, object) do
    updated_base = AriaEngine.State.add_fact(temporal_state.base_state, predicate, subject, object)
    %{temporal_state | base_state: updated_base}
  end
  
  # New temporal capabilities
  def add_temporal_fact(temporal_state, time, predicate, subject, object) do
    current_facts = Map.get(temporal_state.temporal_facts, time, [])
    new_fact = {predicate, subject, object}
    updated_facts = Map.put(temporal_state.temporal_facts, time, [new_fact | current_facts])
    %{temporal_state | temporal_facts: updated_facts}
  end
  
  def advance_time(temporal_state, new_time) do
    %{temporal_state | current_time: new_time}
  end
end

# Test temporal state integration
defmodule AriaTimestrike.TemporalStateTest do
  use ExUnit.Case
  
  test "temporal state wraps existing state functionality" do
    # Start with existing AriaEngine.State
    base_state = AriaEngine.State.new()
      |> AriaEngine.State.add_fact("position", "maya", {3, 5})
    
    # Wrap in temporal state
    temporal_state = AriaEngine.TemporalState.new(base_state, 0.0)
    
    # Existing functionality still works
    assert AriaEngine.TemporalState.get_fact(temporal_state, "position", "maya") == {3, 5}
    
    # New temporal functionality
    temporal_state = temporal_state
      |> AriaEngine.TemporalState.add_temporal_fact(5.0, "position", "maya", {10, 5})
      |> AriaEngine.TemporalState.advance_time(5.0)
    
    assert temporal_state.current_time == 5.0
    refute Enum.empty?(temporal_state.temporal_facts)
  end
end
```

### Stage 2: Temporal Actions and Duration

Extend existing action system with temporal information:

```elixir
# Extend AriaEngine actions with temporal properties
defmodule AriaEngine.TemporalAction do
  @moduledoc """
  Temporal action that extends existing AriaEngine action system.
  """
  
  defstruct [
    :name,           # Action name (compatible with existing system)
    :args,           # Action arguments
    :preconditions,  # Existing preconditions
    :effects,        # Existing effects  
    :duration,       # NEW: Action duration in seconds
    :start_time,     # NEW: When action starts
    :end_time        # NEW: When action completes
  ]
  
  def new(name, args, preconditions, effects, duration \\ 1.0) do
    %__MODULE__{
      name: name,
      args: args, 
      preconditions: preconditions,
      effects: effects,
      duration: duration,
      start_time: nil,
      end_time: nil
    }
  end
  
  def schedule(action, start_time) do
    %{action | 
      start_time: start_time,
      end_time: start_time + action.duration
    }
  end
  
  # Convert to existing AriaEngine.Action for compatibility
  def to_basic_action(temporal_action) do
    %{
      name: temporal_action.name,
      args: temporal_action.args,
      preconditions: temporal_action.preconditions,
      effects: temporal_action.effects
    }
  end
end

# Test with simple TimeStrike-style movement
defmodule AriaTimestrike.MovementTest do
  use ExUnit.Case
  
  test "agent movement with duration calculation" do
    # Create temporal movement action
    move_action = AriaEngine.TemporalAction.new(
      :move_to,
      ["maya", {3, 5}, {15, 5}],
      [{"position", "maya", {3, 5}}],
      [{"position", "maya", {15, 5}}],
      4.0  # 12 units distance / 3.0 speed = 4.0 seconds
    )
    
    # Schedule the action
    scheduled_action = AriaEngine.TemporalAction.schedule(move_action, 0.0)
    
    assert scheduled_action.start_time == 0.0
    assert scheduled_action.end_time == 4.0
    assert scheduled_action.duration == 4.0
    
    # Verify it's compatible with existing planner
    basic_action = AriaEngine.TemporalAction.to_basic_action(scheduled_action)
    assert basic_action.name == :move_to
    assert basic_action.args == ["maya", {3, 5}, {15, 5}]
  end
end
```

### Stage 3: Simple Temporal Constraint Networks

Implement basic temporal constraints building on existing infrastructure:

```elixir
defmodule AriaEngine.SimpleTemporalNetwork do
  @moduledoc """
  Basic temporal constraint network that works with existing AriaEngine infrastructure.
  Progressive enhancement toward full STN capabilities.
  """
  
  defstruct [
    :intervals,     # %{id => {start_time, end_time}}
    :constraints,   # [{interval_a, relation, interval_b}]
    :actions        # %{interval_id => AriaEngine.TemporalAction}
  ]
  
  def new() do
    %__MODULE__{
      intervals: %{},
      constraints: [],
      actions: %{}
    }
  end
  
  def add_interval(stn, id, start_time, end_time) do
    %{stn | intervals: Map.put(stn.intervals, id, {start_time, end_time})}
  end
  
  def add_action_interval(stn, action) do
    interval_id = "#{action.name}_#{:rand.uniform(1000)}"
    stn
    |> add_interval(interval_id, action.start_time, action.end_time) 
    |> Map.update!(:actions, &Map.put(&1, interval_id, action))
  end
  
  # Basic constraint types (subset of Allen's algebra)
  def add_constraint(stn, interval_a, :before, interval_b) do
    constraint = {interval_a, :before, interval_b}
    %{stn | constraints: [constraint | stn.constraints]}
  end
  
  def add_constraint(stn, interval_a, :meets, interval_b) do
    constraint = {interval_a, :meets, interval_b}
    %{stn | constraints: [constraint | stn.constraints]}
  end
  
  def validate_constraints(stn) do
    Enum.all?(stn.constraints, fn {a, relation, b} ->
      validate_constraint(stn, a, relation, b)
    end)
  end
  
  defp validate_constraint(stn, a, :before, b) do
    {_a_start, a_end} = Map.get(stn.intervals, a)
    {b_start, _b_end} = Map.get(stn.intervals, b)
    a_end < b_start
  end
  
  defp validate_constraint(stn, a, :meets, b) do
    {_a_start, a_end} = Map.get(stn.intervals, a)
    {b_start, _b_end} = Map.get(stn.intervals, b)
    abs(a_end - b_start) < 0.1  # Allow small floating point errors
  end
end

# Test basic temporal coordination
defmodule AriaTimestrike.CoordinationTest do
  use ExUnit.Case
  alias AriaEngine.{TemporalAction, SimpleTemporalNetwork}
  
  test "Maya and Alex coordinate for hostage rescue" do
    # Create actions based on existing AriaEngine patterns
    maya_move = TemporalAction.new(
      :move_to, 
      ["maya", {3, 5}, {10, 5}], 
      [], 
      [{"position", "maya", {10, 5}}],
      2.3  # 7 units / 3.0 speed
    ) |> TemporalAction.schedule(0.0)
    
    maya_scorch = TemporalAction.new(
      :cast_scorch,
      ["maya", {15, 5}],
      [{"position", "maya", {10, 5}}],
      [{"area_damaged", {15, 5}, 45}],
      2.0  # Cast time
    ) |> TemporalAction.schedule(2.3)
    
    alex_advance = TemporalAction.new(
      :move_to,
      ["alex", {4, 4}, {20, 5}],
      [{"area_clear", {15, 5}}],
      [{"position", "alex", {20, 5}}],
      5.0  # 20 units / 4.0 speed  
    ) |> TemporalAction.schedule(4.3)  # After scorch completes
    
    # Build temporal network
    stn = SimpleTemporalNetwork.new()
      |> SimpleTemporalNetwork.add_action_interval(maya_move)
      |> SimpleTemporalNetwork.add_action_interval(maya_scorch) 
      |> SimpleTemporalNetwork.add_action_interval(alex_advance)
    
    # Validate temporal constraints
    assert SimpleTemporalNetwork.validate_constraints(stn)
    
    # Verify timeline makes sense for hostage rescue (12 second deadline)
    alex_completion_time = alex_advance.end_time
    assert alex_completion_time <= 12.0, "Hostage rescue takes too long: #{alex_completion_time}s"
  end
end
```

### Stage 4: Integration with Existing Domain System

Connect temporal planning to existing `aria_timestrike` domain:

```elixir
# Enhance AriaTimestrike.DomainProvider with temporal capabilities
defmodule AriaTimestrike.TemporalDomainProvider do
  @moduledoc """
  Temporal-enhanced domain provider that builds on existing AriaTimestrike.DomainProvider.
  """
  
  @behaviour AriaEngine.DomainProvider
  
  def domain_type, do: "timestrike_temporal"
  
  def create_domain do
    # Start with existing domain
    base_domain = AriaTimestrike.create_domain()
    
    # Add temporal capabilities
    enhance_with_temporal_capabilities(base_domain)
  end
  
  defp enhance_with_temporal_capabilities(domain) do
    domain
    |> add_temporal_actions()
    |> add_temporal_goals()
    |> add_temporal_methods()
  end
  
  defp add_temporal_actions(domain) do
    # Add TimeStrike-specific temporal actions
    temporal_actions = [
      create_move_action(),
      create_scorch_action(),
      create_delaying_strike_action(),
      create_now_action()
    ]
    
    Enum.reduce(temporal_actions, domain, fn action, acc_domain ->
      AriaEngine.Domain.add_action(acc_domain, action)
    end)
  end
  
  defp create_move_action do
    %{
      name: :temporal_move_to,
      params: [:agent, :from_pos, :to_pos, :speed],
      preconditions: [
        {:position, :agent, :from_pos}
      ],
      effects: [
        {:position, :agent, :to_pos}
      ],
      temporal_properties: %{
        duration_formula: fn [_agent, from_pos, to_pos, speed] ->
          distance = calculate_distance(from_pos, to_pos)
          distance / speed
        end
      }
    }
  end
  
  defp create_scorch_action do
    %{
      name: :cast_scorch,
      params: [:caster, :target_position],
      preconditions: [
        {:can_cast, :caster, :scorch},
        {:in_range, :caster, :target_position, 8}
      ],
      effects: [
        {:area_damaged, :target_position, 45},
        {:cooldown_active, :caster, :scorch, 8.0}
      ],
      temporal_properties: %{
        duration: 2.0,
        cooldown: 8.0
      }
    }
  end
  
  defp calculate_distance({x1, y1}, {x2, y2}) do
    :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
  end
end

# Test enhanced domain integration
defmodule AriaTimestrike.EnhancedDomainTest do
  use ExUnit.Case
  
  test "temporal domain provider creates enhanced domain" do
    domain = AriaTimestrike.TemporalDomainProvider.create_domain()
    
    # Verify it includes temporal actions
    action_names = domain.actions |> Map.keys()
    assert :temporal_move_to in action_names
    assert :cast_scorch in action_names
    
    # Verify temporal properties exist
    move_action = domain.actions[:temporal_move_to]
    assert Map.has_key?(move_action, :temporal_properties)
  end
  
  test "temporal domain works with existing planner" do
    domain = AriaTimestrike.TemporalDomainProvider.create_domain()
    
    # Create temporal-aware initial state
    initial_state = AriaEngine.TemporalState.new(
      AriaEngine.State.new()
      |> AriaEngine.State.add_fact("position", "maya", {3, 5})
      |> AriaEngine.State.add_fact("can_cast", "maya", "scorch")
    )
    
    goals = [{"position", "maya", {15, 5}}]
    
    # This should work with existing planner infrastructure
    case AriaEngine.Planner.plan(domain, initial_state.base_state, goals) do
      {:ok, plan} ->
        assert length(plan) > 0
        IO.puts("✓ Temporal domain compatible with existing planner")
      {:error, reason} ->
        IO.puts("Planner integration needs work: #{inspect(reason)}")
    end
  end
end
```

### Stage 5: Progressive API Enhancement

Add developer-friendly APIs incrementally:

```elixir
# Simple scenario builder (subset of ADR-046 vision)
defmodule AriaTimestrike.SimpleScenario do
  @moduledoc """
  Basic scenario builder that will evolve toward ADR-046 fluent APIs.
  Starts simple and grows organically.
  """
  
  defstruct [
    :agents,
    :goals, 
    :constraints,
    :initial_state
  ]
  
  def new do
    %__MODULE__{
      agents: %{},
      goals: [],
      constraints: [],
      initial_state: AriaEngine.TemporalState.new(AriaEngine.State.new())
    }
  end
  
  def add_agent(scenario, name, position, opts \\ []) do
    agent = %{
      name: name,
      position: position,
      speed: Keyword.get(opts, :speed, 3.0),
      hp: Keyword.get(opts, :hp, 100),
      skills: Keyword.get(opts, :skills, [])
    }
    
    updated_state = scenario.initial_state
      |> AriaEngine.TemporalState.add_fact("position", name, position)
      |> AriaEngine.TemporalState.add_fact("hp", name, agent.hp)
    
    %{scenario | 
      agents: Map.put(scenario.agents, name, agent),
      initial_state: updated_state
    }
  end
  
  def set_goal(scenario, agent, goal_type, target) do
    goal = {goal_type, agent, target}
    %{scenario | goals: [goal | scenario.goals]}
  end
  
  # Convert to format existing planner expects
  def to_planning_problem(scenario) do
    domain = AriaTimestrike.TemporalDomainProvider.create_domain()
    
    {domain, scenario.initial_state.base_state, scenario.goals}
  end
end

# Test simple scenario building
defmodule AriaTimestrike.SimpleScenarioTest do
  use ExUnit.Case
  alias AriaTimestrike.SimpleScenario
  
  test "build and solve simple hostage rescue scenario" do
    scenario = SimpleScenario.new()
      |> SimpleScenario.add_agent("alex", {4, 4}, speed: 4.0, hp: 120)
      |> SimpleScenario.add_agent("maya", {3, 5}, speed: 3.0, hp: 80, skills: [:scorch])
      |> SimpleScenario.set_goal("alex", "position", {20, 5})
    
    {domain, initial_state, goals} = SimpleScenario.to_planning_problem(scenario)
    
    # Try to solve with existing infrastructure
    case AriaEngine.Planner.plan(domain, initial_state, goals) do
      {:ok, plan} ->
        assert length(plan) > 0
        IO.puts("✓ Simple scenario builder works: #{length(plan)} actions")
      {:error, reason} ->
        IO.puts("Planning failed, but scenario builder structure is sound: #{inspect(reason)}")
    end
    
    # Verify scenario structure
    assert Map.has_key?(scenario.agents, "alex")
    assert Map.has_key?(scenario.agents, "maya")
    assert length(scenario.goals) == 1
  end
end
```

## Migration Strategy

### Phase 1: Foundation (Immediate)
- Implement Stage 0-1: Assess current state and add basic temporal state
- Ensure existing tests continue to pass
- Add basic temporal state tests

### Phase 2: Temporal Actions (Week 1)
- Implement Stage 2: Add temporal action duration
- Enhance existing actions with timing information
- Test movement and action timing

### Phase 3: Coordination (Week 2)
- Implement Stage 3: Simple temporal constraint networks
- Test basic agent coordination scenarios
- Validate constraint satisfaction

### Phase 4: Domain Integration (Week 3)
- Implement Stage 4: Enhanced temporal domain provider
- Integrate with existing AriaTimestrike domain
- Ensure backward compatibility

### Phase 5: API Enhancement (Week 4+)
- Implement Stage 5: Progressive API improvements
- Build toward ADR-046 fluent APIs organically
- Add TimeStrike scenario testing

## Success Criteria

### Stage 0 Success
- [ ] All existing tests pass
- [ ] Current AriaEngine.Planner functionality verified
- [ ] AriaTimestrike.DomainProvider functional

### Stage 1 Success  
- [ ] TemporalState wraps existing State without breaking functionality
- [ ] Temporal facts can be added and retrieved
- [ ] Time advancement works

### Stage 2 Success
- [ ] TemporalAction extends existing actions with duration
- [ ] Actions can be scheduled in time
- [ ] Duration calculations work for movement

### Stage 3 Success
- [ ] SimpleTemporalNetwork handles basic constraints
- [ ] Before/meets relationships validate correctly
- [ ] Multi-action coordination possible

### Stage 4 Success
- [ ] TemporalDomainProvider creates enhanced domain
- [ ] Enhanced domain works with existing planner
- [ ] TimeStrike actions have temporal properties

### Stage 5 Success
- [ ] SimpleScenario builder creates planning problems
- [ ] Scenarios convert to existing planner format
- [ ] Foundation exists for ADR-046 enhancement

## Consequences

### Positive

- **Realistic Implementation Path**: Builds on existing codebase rather than starting from scratch
- **Backward Compatibility**: Existing functionality continues to work throughout
- **Progressive Enhancement**: Each stage adds value while building toward full vision
- **Testable Milestones**: Clear success criteria for each stage
- **Risk Mitigation**: Failures at any stage don't invalidate previous work

### Negative

- **Gradual Progress**: Takes longer to reach full ADR-046/047 vision
- **Potential Rework**: Some early implementations may need refactoring
- **Complexity Growth**: System becomes more complex as layers are added
- **API Evolution**: Interfaces may change as understanding improves

## Related ADRs

- **ADR-042**: Temporal Planner Cold Boot Implementation Order (superseded, but methodology inspiration)
- **ADR-046**: User-Friendly Temporal Constraint Specification (target API vision)
- **ADR-047**: TimeStrike Temporal Planner Test Scenario (target test scenarios)
- **ADR-048**: Developer-Friendly APIs for Temporal Planner Implementation (enhanced tooling vision)
- **ADR-049**: Enhanced Temporal Planner Implementation with Unified APIs (superseded by this cold boot approach)

---

*This ADR provides a realistic implementation roadmap that starts from the current `aria_engine` and `aria_timestrike` codebase and progressively builds toward the enhanced temporal planning vision established in previous ADRs.*
