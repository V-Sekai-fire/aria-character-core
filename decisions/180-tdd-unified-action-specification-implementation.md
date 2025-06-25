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
12. **❌ TOMBSTONE: `quantity` field in action metadata** - Quantities are state fluents, not action metadata
13. **❌ TOMBSTONE: Separate `resources` map with `consumables`, `tools`, `locations`** - Everything is entities with capabilities
14. **❌ TOMBSTONE: `properties` field in entity requirements** - Use capabilities instead
15. **❌ TOMBSTONE: Separate `requires_agent` field** - Agents are entities with capabilities
16. **❌ TOMBSTONE: `location` field in action metadata** - Locations are entities in `requires_entities`
17. **❌ TOMBSTONE: `constraints` field in entity requirements** - Quantities, availability, and dynamic properties are state fluents, not action metadata
18. **❌ TOMBSTONE: Requirement validation in action functions** - Actions assume planner has already validated requirements
19. **❌ TOMBSTONE: Old unigoal API patterns** - ONLY predicate-based registration allowed

## Testing Philosophy

This implementation follows Martin Fowler's testing styles to ensure appropriate test isolation and integration coverage:

### Classic Style (Sociable Tests) - Domain Integration Testing
**Use for:** Testing how domain components work together in realistic scenarios
- **Real dependencies:** StateV2, Domain.Core, EntityValidator working together
- **Integration boundaries:** Full action workflow from planning to execution
- **Realistic scenarios:** Complete cooking domain with actual state management
- **Trade-offs:** Slower execution but higher confidence in component interactions

### Mockist Style (Solitary Tests) - Isolated Component Testing  
**Use for:** Testing individual components in isolation with clear boundaries
- **Mocked dependencies:** Isolated testing of EntityValidator, macro parsing, etc.
- **Unit boundaries:** Single component behavior without external dependencies
- **Focused scenarios:** Specific validation logic, attribute parsing, error handling
- **Trade-offs:** Faster feedback but requires careful mock management

### Decision Criteria
- **Domain integration (Phases 1-2):** Classic style - test real component interactions
- **Component validation (Phases 3-5):** Mockist style - test isolated component logic
- **Performance testing:** Classic style - measure real system behavior
- **Error handling:** Mockist style - test specific failure scenarios

## TDD Implementation Sequence

### Phase 1: Module-Based Domain Pattern (Foundation)

**Priority**: CRITICAL - Everything else depends on this  
**Testing Style**: Classic (Sociable) - Domain integration with real components

**Test-Driven Implementation:**

```elixir
# RED: Test domain integration with real StateV2 and Domain.Core
defmodule AriaEngine.Domain.IntegrationTest do
  use ExUnit.Case
  
  test "complete domain workflow with real state management" do
    # Classic style: Real StateV2, real Domain.Core, real action execution
    state = StateV2.new()
            |> StateV2.set_fact("chef_1", "type", "agent")
            |> StateV2.set_fact("chef_1", "capabilities", [:cooking])
            |> StateV2.set_fact("oven_1", "type", "oven")
            |> StateV2.set_fact("oven_1", "capabilities", [:heating])
    
    domain = TestCookingDomain.create_domain()
    
    # Test full integration: domain creation → action execution → state changes
    {:ok, new_state} = Domain.apply_action(domain, state, :cook_meal, ["pasta"])
    
    # Verify real state changes through actual StateV2 queries
    assert StateV2.get_fact(new_state, "pasta", "meal_status") == "cooking"
    assert StateV2.get_fact(new_state, "chef_1", "chef_status") == "busy"
  end
  
  test "domain registration integrates with existing Domain.Core" do
    # Classic style: Test real integration with existing Domain.Core
    domain = TestCookingDomain.create_domain()
    
    # Should work with existing Domain.Core functions
    assert Domain.has_action?(domain, :cook_meal)
    assert Domain.has_task_method?(domain, :prepare_meal_method)
    
    # Metadata should be accessible through existing APIs
    metadata = Domain.get_action_metadata(domain, :cook_meal)
    assert metadata.duration == "PT2H"
    assert length(metadata.requires_entities) == 2
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
      {:ok, new_state} -> 
        Logger.info("cook_meal_command succeeded for #{meal_type}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("cook_meal_command failed: #{reason}")
        {:error, reason}  # Triggers blacklisting and replanning
    end
  end
  
  @task_method
  def prepare_meal_method(state, [meal_type]) do
    {:ok, [
      {:cook_meal, [meal_type]},
      {:set_table, []},
      {:serve_meal, [meal_type]}
    ]}
  end
  
  @unigoal_method predicate: "location"
  def travel_to_location(state, [subject, target]) do
    current = StateV2.get_fact(state, subject, "location")
    if current == target do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:walk_to_location, [subject, target]},
        {:verify_goal, [{subject, "location", target}]}  # Auto-verification
      ]}
    end
  end
  
  @multigoal_method goal_pattern: :cooking_workflow
  def handle_cooking_workflow(state, multigoal) do
    # Domain author explicitly chooses strategy
    case custom_cooking_optimization(state, multigoal.goals) do
      {:ok, plan} -> {:ok, plan}
      {:error, _} ->
        # Domain author EXPLICITLY chooses fallback
        Logger.debug("Custom optimization failed, using split_multigoal")
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
  
  # Domain creation with command registration
  def create_domain(opts \\ %{}) do
    domain = __MODULE__.create_base_domain()
    
    # Register commands for execution-time behavior
    domain = AriaEngine.Domain.declare_commands(domain, [
      &cook_meal_command/2
    ])
    
    # Initialize blacklist system
    domain = %{domain | blacklist: MapSet.new()}
    
    domain
  end
end
```

**Implementation Tasks:**
- [ ] Create `AriaEngine.Domain` macro module
- [ ] Implement attribute parsing (`@action`, `@task_method`, `@unigoal_method`, `@multigoal_method`)
- [ ] Integrate with existing `Domain.Core` structure
- [ ] Add metadata extraction and storage
- [ ] Ensure backward compatibility with current domain API

### Phase 2: Entity Validation Framework (Depends on Phase 1)

**Priority**: HIGH - Required for action requirement validation  
**Testing Style**: Classic (Sociable) - Domain integration with real state management

**Test-Driven Implementation:**

```elixir
# RED: Test entity validation integration with real StateV2 and Domain
defmodule AriaEngine.EntityValidation.IntegrationTest do
  use ExUnit.Case
  
  test "validates action requirements in complete domain workflow" do
    # Classic style: Real StateV2 with actual entity data
    state = StateV2.new()
            |> StateV2.set_fact("chef_1", "type", "agent")
            |> StateV2.set_fact("chef_1", "capabilities", [:cooking, :cleaning])
            |> StateV2.set_fact("chef_1", "status", "available")
            |> StateV2.set_fact("oven_1", "type", "oven")
            |> StateV2.set_fact("oven_1", "capabilities", [:heating])
            |> StateV2.set_fact("oven_1", "status", "ready")
    
    domain = TestCookingDomain.create_domain()
    
    # Test full integration: domain → validation → action execution
    {:ok, new_state} = Domain.apply_action_with_validation(domain, state, :cook_meal, ["pasta"])
    
    # Verify validation worked and action executed with real state changes
    assert StateV2.get_fact(new_state, "pasta", "meal_status") == "cooking"
    assert StateV2.get_fact(new_state, "chef_1", "status") == "busy"
    assert StateV2.get_fact(new_state, "oven_1", "status") == "in_use"
  end
  
  test "validation failure prevents action execution in real workflow" do
    # Classic style: Real StateV2 without required entities
    state = StateV2.new()
            |> StateV2.set_fact("dishwasher_1", "type", "appliance")
            |> StateV2.set_fact("dishwasher_1", "capabilities", [:cleaning])
    
    domain = TestCookingDomain.create_domain()
    
    # Should fail validation and prevent action execution
    {:error, reason} = Domain.apply_action_with_validation(domain, state, :cook_meal, ["pasta"])
    
    # Verify real error handling through actual StateV2 queries
    assert reason =~ "No available entity of type 'agent' with capabilities [:cooking]"
    assert StateV2.get_fact(state, "pasta", "meal_status") == nil  # No state change
  end
  
  test "entity capability matching with real state queries" do
    # Classic style: Real StateV2 with complex capability scenarios
    state = StateV2.new()
            |> StateV2.set_fact("chef_1", "type", "agent")
            |> StateV2.set_fact("chef_1", "capabilities", [:cooking])
            |> StateV2.set_fact("intern_1", "type", "agent") 
            |> StateV2.set_fact("intern_1", "capabilities", [:cleaning])
    
    domain = TestCookingDomain.create_domain()
    
    # Should find chef_1 for cooking, not intern_1
    {:ok, new_state} = Domain.apply_action_with_validation(domain, state, :cook_meal, ["pasta"])
    
    # Verify correct entity selection through real state management
    assert StateV2.get_fact(new_state, "chef_1", "status") == "busy"
    assert StateV2.get_fact(new_state, "intern_1", "status") != "busy"
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
**Testing Style**: Mockist (Solitary) - Isolated component testing with mocked dependencies

**Test-Driven Implementation:**

```elixir
# RED: Test isolated action priority logic with mocked dependencies
defmodule Plan.ActionPriority.UnitTest do
  use ExUnit.Case
  import Mox
  
  test "action nodes selected before task nodes in isolation" do
    # Mockist style: Mock solution tree structure
    mock_tree = %SolutionTree{
      nodes: %{
        1 => %{type: :task, status: :pending},
        2 => %{type: :action, status: :pending},
        3 => %{type: :task, status: :pending}
      }
    }
    
    # Test only the priority selection logic in isolation
    next_node = Plan.Core.find_next_node_with_priority(mock_tree)
    assert next_node == 2  # Should select action node first
  end
  
  test "entity validation logic isolated from state management" do
    # Mockist style: Mock EntityValidator and state dependencies
    MockEntityValidator
    |> expect(:validate_requirements, fn _state, _metadata ->
      {:error, "No available entity of type 'agent'"}
    end)
    
    MockDomain
    |> expect(:get_action_metadata, fn _domain, :cook_meal ->
      %{requires_entities: [%{type: "agent", capabilities: [:cooking]}]}
    end)
    
    # Test only the validation integration logic
    result = Plan.Core.validate_action_requirements(mock_domain, mock_state, :cook_meal)
    assert {:error, _reason} = result
  end
  
  test "priority calculation algorithm in isolation" do
    # Mockist style: Test pure priority calculation logic
    action_node = %{type: :action, complexity: 5}
    task_node = %{type: :task, complexity: 3}
    
    # Test only the priority calculation without external dependencies
    action_priority = Plan.Core.calculate_node_priority(action_node)
    task_priority = Plan.Core.calculate_node_priority(task_node)
    
    assert action_priority > task_priority
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
**Testing Style**: Mockist (Solitary) - Isolated verification logic testing

**Test-Driven Implementation:**

```elixir
# RED: Test isolated verification logic with mocked dependencies
defmodule Plan.AutoVerification.UnitTest do
  use ExUnit.Case
  import Mox
  
  test "verification task generation logic in isolation" do
    # Mockist style: Mock domain and goal method responses
    mock_goal = {"meal_ready", "pasta", true}
    mock_subtasks = [
      {:cook_meal, ["pasta"]},
      {:serve_meal, ["pasta"]}
    ]
    
    # Test only the verification task injection logic
    enhanced_subtasks = Plan.Core.add_verification_tasks(mock_subtasks, [mock_goal])
    
    # Should add verification task without external dependencies
    verification_task = {:verify_goal, [mock_goal]}
    assert verification_task in enhanced_subtasks
    assert length(enhanced_subtasks) == length(mock_subtasks) + 1
  end
  
  test "verification failure handling in isolation" do
    # Mockist style: Mock verification utilities
    MockDomainUtils
    |> expect(:verify_goal, fn _domain, _state, _goal, _args ->
      {:error, "Goal not achieved: meal_ready"}
    end)
    
    # Test only the verification failure logic
    result = Plan.Core.execute_verification_node(mock_domain, mock_state, mock_goal)
    assert {:error, reason} = result
    assert reason =~ "Goal not achieved"
  end
  
  test "verification success logic without state dependencies" do
    # Mockist style: Mock successful verification
    MockDomainUtils
    |> expect(:verify_goal, fn _domain, _state, _goal, _args ->
      {:ok, :verified}
    end)
    
    # Test only the success path logic
    result = Plan.Core.execute_verification_node(mock_domain, mock_state, mock_goal)
    assert {:ok, :verified} = result
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
**Testing Style**: Mockist (Solitary) - Isolated command/action logic testing

**Test-Driven Implementation:**

```elixir
# RED: Test isolated command calling logic with mocked dependencies
defmodule AriaEngine.CommandExecution.UnitTest do
  use ExUnit.Case
  import Mox
  
  test "action node execution calls command functions in isolation" do
    # Mockist style: Mock command function and blacklist system
    MockActions
    |> expect(:cook_meal_command, fn _state, _args ->
      {:ok, %{meal_status: "ready"}}
    end)
    
    # Test only the command calling logic
    result = Plan.Core.execute_action_node_command(:cook_meal, mock_state, ["pasta"])
    assert {:ok, new_state} = result
    assert new_state.meal_status == "ready"
  end
  
  test "command failure triggers blacklisting in isolation" do
    # Mockist style: Mock failing command and blacklist system
    MockActions
    |> expect(:cook_meal_command, fn _state, _args ->
      {:error, "Oven malfunction"}
    end)
    
    MockBlacklist
    |> expect(:add_to_blacklist, fn _tree, _node_id, _reason ->
      {:ok, updated_tree}
    end)
    
    # Test only the failure handling logic
    result = Plan.Core.handle_command_failure(mock_tree, mock_node_id, "Oven malfunction")
    assert {:ok, _updated_tree} = result
  end
  
  test "command vs action selection logic in isolation" do
    # Mockist style: Test pure selection logic
    action_node = %{type: :action, name: :cook_meal}
    
    # Test only the command function name generation
    command_name = Plan.Core.get_command_function_name(action_node)
    assert command_name == :cook_meal_command
    
    # Test action vs command distinction
    assert Plan.Core.is_planning_phase?(action_node) == false
    assert Plan.Core.is_execution_phase?(action_node) == true
  end
end
```

**Implementation Tasks:**
- [ ] Create `AriaEngine.CommandExecution` module
- [ ] Implement command function name generation
- [ ] Add blacklist integration for command failures
- [ ] Create planning vs execution phase detection
- [ ] Maintain separation between actions and commands

## Backward Compatibility Strategy

**Preserve existing functionality:**
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
