# ADR-180: TDD Implementation - Unified Action Specification System

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH  
**Parent ADRs:** ADR-131, ADR-132, ADR-133, ADR-134

## Overview

**Current State**: ADRs 131-134 specify unified action system, but key components are missing from codebase  
**Target State**: Complete TDD implementation of module-based domain pattern with entity validation and enhanced planning

## Codebase Analysis Results

### ✅ Confirmed Existing (Build Upon)
- **Timex integration**: Comprehensive duration/datetime handling with microsecond precision
- **Blacklist system**: Fully implemented in `Plan.Blacklisting` with solution tree integration
- **StateV2**: Complete entity-first architecture with fact-based queries
- **Domain.Core**: Solid foundation for action/method registration
- **Goal verification**: `Domain.Utils.verify_goal/7` exists for manual verification
- **Commands**: Extensive `Actions` module with external command execution
- **Priority systems**: Timeline scheduling includes priority handling

### ❌ Confirmed Missing (Must Implement)
1. **Module-based domain pattern**: No `@action`, `@task_method`, `@unigoal_method`, `@multigoal_method` attributes
2. **`use AriaEngine.Domain` macro**: Does not exist
3. **EntityValidator**: No entity validation framework for planning-time validation
4. **Action priority in planning**: No action node prioritization in planning
5. **Automatic goal verification**: Current verification is manual only

### ❌ TOMBSTONED: Architectural Violations
1. **`@command` attributes**: Commands are execution-time functions, NOT domain attributes
2. **Command node types**: Solution tree only supports 6 node types from ADR-133
3. **Separate planning/execution phases**: IPyHOP uses interleaved planning/execution
4. **New planning APIs**: Enhance existing `Plan.Core.plan()`, don't create parallel APIs
5. **Validation in actions**: Actions assume preconditions met, validation is planning-time only

### Additional Unstated Known Knowns (Explicitly Tombstoned)

6. **❌ TOMBSTONE: Entity properties in action metadata** - Properties like `max_temp`, `quantity`, `size` belong in state, not action metadata
7. **❌ TOMBSTONE: Mixed goal formats** - ONLY `{subject, predicate, value}` format allowed, all other formats rejected
8. **❌ TOMBSTONE: Complex state evaluation functions** - Use direct `State.get_fact/3` queries instead of `State.evaluate_condition/2`
9. **❌ TOMBSTONE: Command registration in domains** - Commands are execution-time functions, not domain registration artifacts
10. **❌ TOMBSTONE: Solution tree node type expansion** - FIXED at 6 types: `:task | :action | :goal | :multigoal | :verify_goal | :verify_multigoal`
11. **❌ TOMBSTONE: Automatic multigoal resolution** - Domain authors must explicitly define ALL multigoal handling

## TDD Implementation Sequence

### Phase 1: Module-Based Domain Pattern (Foundation)

**Priority**: CRITICAL - Everything else depends on this

**Test-Driven Implementation:**

```elixir
# RED: Test the desired API that doesn't exist yet
defmodule AriaEngine.Domain.ModulePatternTest do
  use ExUnit.Case
  
  test "module-based domain creation with @action attributes" do
    domain = TestCookingDomain.create_domain()
    
    # Should extract metadata from @action attributes
    assert Domain.has_action?(domain, :cook_meal)
    metadata = Domain.get_action_metadata(domain, :cook_meal)
    assert metadata.duration == "PT2H"
    assert metadata.requires_entities != nil
  end
  
  test "@task_method attributes register task decomposition" do
    domain = TestCookingDomain.create_domain()
    
    # Should register task methods for decomposition
    assert Domain.has_task_method?(domain, :prepare_meal_method)
    methods = Domain.get_task_methods(domain, :prepare_meal)
    assert length(methods) > 0
  end
end

# The domain module this test drives us to create
defmodule TestCookingDomain do
  use AriaEngine.Domain  # This macro doesn't exist yet!
  
  @action duration: "PT2H", requires_entities: [
    %{type: "agent", capabilities: [:cooking]},
    %{type: "oven", capabilities: [:heating]}
  ]
  def cook_meal(state, [meal_type]) do
    # Planning-time logic - assumes success
    state
    |> State.set_fact("meal_status", meal_type, "cooking")
    |> State.set_fact("chef_status", "chef_1", "busy")
  end
  
  # ❌ TOMBSTONED: Commands are execution-time functions, not domain attributes
  # Commands are called during action node execution, not registered as domain metadata
  
  # Execution-time function (separate from domain registration)
  def cook_meal_command(state, [meal_type]) do
    # Real-world execution with potential failures
    case attempt_cooking_with_failure_chance(state, meal_type) do
      {:ok, new_state} -> {:ok, new_state}
      {:error, reason} -> {:error, reason}  # Triggers replanning
    end
  end
  
  @task_method
  def prepare_meal_method(state, [meal_type]) do
    [
      {:cook_meal, [meal_type]},
      {:set_table, []},
      {:serve_meal, [meal_type]}
    ]
  end
end
```

**Implementation Tasks:**
- [ ] Create `AriaEngine.Domain` macro module
- [ ] Implement attribute parsing (`@action`, `@task_method`, `@unigoal_method`, `@multigoal_method`)
- [ ] ❌ TOMBSTONED: `@command` attribute parsing (commands are functions, not attributes)
- [ ] Integrate with existing `Domain.Core` structure
- [ ] Add metadata extraction and storage
- [ ] Ensure backward compatibility with current domain API

### Phase 2: Entity Validation Framework (Depends on Phase 1)

**Priority**: HIGH - Required for action requirement validation

**Test-Driven Implementation:**

```elixir
# RED: Test entity validation that doesn't exist
defmodule AriaEngine.EntityValidatorTest do
  use ExUnit.Case
  
  test "validates action requirements against available entities" do
    state = create_state_with_chef_and_oven()
    action_metadata = %{requires_entities: [
      %{type: "agent", capabilities: [:cooking]},
      %{type: "oven", capabilities: [:heating]}
    ]}
    
    {:ok, entities} = EntityValidator.validate_requirements(state, action_metadata)
    assert length(entities) == 2
    assert Enum.any?(entities, fn e -> StateV2.get_fact(state, e, "type") == "agent" end)
  end
  
  test "fails validation when required entities unavailable" do
    state = create_empty_state()
    action_metadata = %{requires_entities: [
      %{type: "agent", capabilities: [:cooking]}
    ]}
    
    {:error, reason} = EntityValidator.validate_requirements(state, action_metadata)
    assert reason =~ "No available entity"
  end
  
  test "validates entity capabilities match requirements" do
    state = create_state_with_entities()
    
    # Chef has cooking capability
    {:ok, _} = EntityValidator.validate_requirements(state, %{
      requires_entities: [%{type: "agent", capabilities: [:cooking]}]
    })
    
    # Chef doesn't have flying capability
    {:error, _} = EntityValidator.validate_requirements(state, %{
      requires_entities: [%{type: "agent", capabilities: [:flying]}]
    })
  end
end
```

**Implementation Tasks:**
- [ ] Create `AriaEngine.EntityValidator` module
- [ ] Implement capability matching algorithms
- [ ] Add entity availability checking
- [ ] Integrate with StateV2 fact queries
- [ ] Add comprehensive error reporting

### Phase 3: Enhanced Planning with Action Priority (Depends on Phases 1-2)

**Priority**: MEDIUM - Enhances existing planning system

**Test-Driven Implementation:**

```elixir
# RED: Test action priority that doesn't exist in current planning
defmodule Plan.ActionPriorityTest do
  use ExUnit.Case
  
  test "action nodes have priority over task nodes in planning" do
    tree = create_solution_tree_with_mixed_nodes()
    
    # Should select action nodes before task nodes
    next_node = Plan.Core.find_next_node_with_priority(tree)
    node = tree.nodes[next_node]
    assert node.type == :action  # This field doesn't exist yet
  end
  
  test "planning validates entity requirements before action selection" do
    domain = TestDomain.create_domain()
    state = create_state_without_chef()
    
    # ❌ TOMBSTONED: plan_with_validation() - enhance existing plan(), don't create new APIs
    # Should integrate validation into existing planning, not create parallel APIs
    {:error, reason} = Plan.Core.plan(domain, state, [
      {:cook_meal, ["pasta"]}
    ])
    assert reason =~ "entity requirements not met"
  end
end
```

**Implementation Tasks:**
- [ ] Add node type tracking to solution trees
- [ ] Implement action priority in node selection
- [ ] Integrate entity validation into planning
- [ ] Enhance existing `Plan.Core` with validation
- [ ] Maintain backward compatibility

### Phase 4: Automatic Goal Verification (Depends on Phase 3)

**Priority**: MEDIUM - Enhances existing goal verification

**Test-Driven Implementation:**

```elixir
# RED: Test automatic verification that doesn't exist
defmodule Plan.AutoVerificationTest do
  use ExUnit.Case
  
  test "goal methods automatically add verification tasks" do
    domain = TestDomain.create_domain()
    state = create_test_state()
    
    # When goal method succeeds, verification task should be added
    {:ok, subtasks} = Domain.apply_unigoal_method(domain, state, {"meal_ready", "pasta", true})
    
    # Should include verification task
    assert Enum.any?(subtasks, fn task ->
      match?({:verify_goal, [{"meal_ready", "pasta", true}]}, task)
    end)
  end
  
  test "verification tasks validate goal achievement" do
    state = create_state_with_ready_meal()
    
    # ❌ TOMBSTONED: execute_verification_task() - verification uses standard node execution
    # Verification nodes execute like any other node type, no special functions needed
    {:ok, new_state} = Plan.Core.execute_node(domain, state, tree, verification_node_id)
    assert new_state == state  # No change when verification passes
  end
end
```

**Implementation Tasks:**
- [ ] Extend existing `Domain.Utils.verify_goal/7` for automation
- [ ] Add automatic verification task creation
- [ ] Integrate with solution tree node types
- [ ] Add verification failure handling
- [ ] Maintain compatibility with manual verification

### Phase 5: Commands vs Actions Separation (Depends on All Previous)

**Priority**: LOW - Architectural enhancement

**Test-Driven Implementation:**

```elixir
# RED: Test planning/execution separation that doesn't exist
defmodule AriaEngine.PlanningExecutionTest do
  use ExUnit.Case
  
  test "planning uses actions, execution uses commands" do
    domain = TestDomain.create_domain()
    state = create_test_state()
    
    # Planning phase uses actions (assume success)
    {:ok, plan} = Plan.Core.plan(domain, state, [
      {:cook_meal, ["pasta"]}
    ])
    
    # ❌ TOMBSTONED: Plan.Execution module - execution happens during action node processing
    # IPyHOP uses interleaved planning/execution, not separate phases
    {:ok, final_state} = Plan.Core.plan(domain, state, [
      {:cook_meal, ["pasta"]}
    ])
    assert StateV2.get_fact(final_state, "pasta", "meal_status") == "ready"
  end
  
  test "command failures trigger replanning" do
    domain = TestDomain.create_domain()
    state = create_test_state()
    
    # ❌ TOMBSTONED: execute_command() - commands called during action execution
    # Commands are called when action nodes execute, triggering blacklisting automatically
    {:error, reason} = Plan.Core.plan(domain, state, [
      {:cook_meal, ["pasta"]}  # This will call command and handle failures
    ])
    
    # Should trigger blacklisting and replanning
    assert reason =~ "cooking failed"
  end
end
```

**Implementation Tasks:**
- [ ] ❌ TOMBSTONED: `Plan.Execution` module (execution integrated into planning loop)
- [ ] Integrate command calling with existing blacklist system
- [ ] Add failure handling during action node execution
- [ ] ❌ TOMBSTONED: Separate phases (IPyHOP uses interleaved planning/execution)
- [ ] Document command calling patterns during action execution

## Integration Strategy

### Backward Compatibility Requirements

**Must preserve:**
- All existing `Domain.Core` functionality
- Current action registration patterns
- Existing planning algorithms
- StateV2 fact-based queries
- Timex duration handling
- Blacklist system behavior

**Integration approach:**
- New module pattern extends existing `Domain.add_action/3`
- Entity validation integrates with current state queries
- Action priority enhances existing node selection
- Automatic verification extends manual verification
- Commands system builds on existing `Actions` module

### Migration Path

**Phase 1**: Implement module pattern alongside existing domains
**Phase 2**: Add entity validation to new domains only
**Phase 3**: Enhance planning for domains that opt-in
**Phase 4**: Gradually migrate existing domains to new pattern
**Phase 5**: Deprecate old patterns after full migration

## Success Criteria

### Phase 1 Success Criteria
- [ ] `use AriaEngine.Domain` macro works
- [ ] `@action` attributes extract metadata correctly
- [ ] Integration with existing `Domain.Core` seamless
- [ ] All existing domain tests pass
- [ ] New module-based domains can be created

### Phase 2 Success Criteria
- [ ] Entity validation framework operational
- [ ] Capability matching algorithms work correctly
- [ ] Integration with StateV2 fact queries successful
- [ ] Validation errors provide clear feedback
- [ ] Performance impact minimal

### Phase 3 Success Criteria
- [ ] Action nodes prioritized in planning
- [ ] Entity validation integrated into planning
- [ ] Existing planning behavior preserved
- [ ] Enhanced planning provides better action selection
- [ ] Backward compatibility maintained

### Phase 4 Success Criteria
- [ ] Goal verification tasks added automatically
- [ ] Verification integrates with solution trees
- [ ] Manual verification still works
- [ ] Verification failures handled gracefully
- [ ] Performance impact acceptable

### Phase 5 Success Criteria
- [ ] Clear separation between planning and execution
- [ ] Command failures trigger appropriate replanning
- [ ] Integration with blacklist system works
- [ ] Execution behavior configurable
- [ ] Documentation clear for developers

## Risk Mitigation

### Technical Risks
- **Integration complexity**: Incremental implementation with extensive testing
- **Performance impact**: Benchmark each phase against existing system
- **Breaking changes**: Maintain strict backward compatibility
- **Macro complexity**: Keep macro implementation simple and well-tested

### Implementation Risks
- **Scope creep**: Stick to TDD sequence, implement only what tests require
- **Over-engineering**: Build minimal viable implementation first
- **Testing gaps**: Comprehensive test coverage for each phase
- **Documentation debt**: Document each phase as implemented

## Related ADRs

- **ADR-131**: Core Specification (parent ADR)
- **ADR-132**: Technical Implementation (duration handling)
- **ADR-133**: Architecture & Standards (IPyHOP integration)
- **ADR-134**: Developer Guide (usage examples)

## Implementation Status

**Status:** Active - Ready for TDD implementation

**Current Phase:** Phase 1 (Module-Based Domain Pattern)

**Timeline:** Incremental implementation following TDD sequence

**Dependencies:** None - builds on existing solid foundations

**Next Steps:** Begin Phase 1 implementation with `use AriaEngine.Domain` macro
