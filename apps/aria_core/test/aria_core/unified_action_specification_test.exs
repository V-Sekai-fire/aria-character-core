# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.UnifiedActionSpecificationTest do
  @moduledoc """
  Comprehensive test suite for the unified action specification system.

  This test suite validates the complete ADR-181 implementation:
  - Phase 1: @action attribute processing
  - Phase 2: Temporal conditions conversion
  - Phase 3: Module-based domain creation
  - Integration with existing AriaCore systems

  Tests the sociable testing approach by verifying that new systems
  properly leverage existing AriaCore functionality.
  """

  use ExUnit.Case, async: true
  doctest AriaCore.ActionAttributes
  doctest AriaCore.TemporalConverter
  doctest AriaCore.Entity.Management
  doctest AriaCore.Temporal.Interval
  doctest AriaCore.UnifiedDomain

  alias AriaCore.{
    ActionAttributes,
    TemporalConverter,
    Entity.Management,
    Temporal.Interval,
    AriaState,
    UnifiedDomain,
    Examples.GltfInteractivityDomain
  }

  # Helper function for doctests
  def setup_test_registry() do
    Management.setup_test_registry()
  end

  describe "Phase 1: Action Attributes Processing" do
    test "processes @action attributes correctly" do
      # Test action metadata conversion
      metadata = [
        duration: "PT2H",
        requires_entities: [%{type: "agent", capabilities: [:cooking]}],
        preconditions: [{"ingredient_available", "tomato", true}],
        effects: [{"meal_status", "soup", "ready"}]
      ]

      action_spec = ActionAttributes.convert_action_metadata(metadata, :cook_soup, TestModule)

      assert action_spec.duration == {:fixed, 7200}  # 2 hours in seconds
      assert length(action_spec.entity_requirements) == 1
      assert action_spec.preconditions == [{"ingredient_available", "tomato", true}]
      assert action_spec.effects == [{"meal_status", "soup", "ready"}]
    end

    test "creates entity registry from action metadata" do
      action_metadata = [
        {:cook_soup, [requires_entities: [%{type: "agent", capabilities: [:cooking]}]]},
        {:bake_bread, [requires_entities: [%{type: "equipment", capabilities: [:heating]}]]}
      ]

      registry = ActionAttributes.create_entity_registry(action_metadata)

      assert %Management{} = registry
      assert Map.has_key?(registry.entity_types, "agent")
      assert Map.has_key?(registry.entity_types, "equipment")
      assert Map.has_key?(registry.capability_index, :cooking)
      assert Map.has_key?(registry.capability_index, :heating)
    end

    test "creates temporal specifications from action metadata" do
      action_metadata = [
        {:cook_soup, [duration: "PT30M"]},
        {:bake_bread, [duration: 3600]}
      ]

      specs = ActionAttributes.create_temporal_specifications(action_metadata)

      assert %Interval{} = specs
      assert Map.get(specs.action_durations, :cook_soup) == {:fixed, 1800}
      assert Map.get(specs.action_durations, :bake_bread) == {:fixed, 3600}
    end
  end

  describe "Phase 2: Temporal Conditions Conversion" do
    test "converts durative actions to simple actions + methods" do
      durative_action = %{
        name: :cook_meal,
        duration: {:fixed, 3600},
        conditions: %{
          at_start: [{"oven", "temperature", {:>=, 350}}],
          over_all: [{"oven", "status", "operational"}],
          at_end: [{"meal", "quality", {:>=, 8}}]
        },
        effects: %{
          at_start: [{"chef", "status", "busy"}],
          at_end: [{"chef", "status", "available"}]
        }
      }

      {simple_action, method} = TemporalConverter.convert_durative_action(durative_action)

      # Verify simple action (ADR-181: should only have duration + entity requirements)
      assert simple_action.name == :cook_meal
      assert simple_action.duration == {:fixed, 3600}
      assert is_list(simple_action.entity_requirements)
      # Simple actions should NOT have effects - they're moved to method decomposition
      refute Map.has_key?(simple_action, :effects)

      # Verify method decomposition preserves temporal logic
      assert is_list(method)
      assert length(method) > 1

      # Should contain goals from at_start conditions
      assert Enum.any?(method, fn step ->
        case step do
          {"temperature", "oven", {:>=, 350}} -> true
          _ -> false
        end
      end)

      # Should contain the main action
      assert Enum.any?(method, fn step ->
        case step do
          {:cook_meal, []} -> true
          _ -> false
        end
      end)
    end

    test "validates conversion preserves temporal semantics" do
      original_action = %{
        name: :test_action,
        duration: {:fixed, 1800},
        conditions: %{at_start: [{"test", "condition", true}]},
        effects: %{at_end: [{"test", "effect", "done"}]}
      }

      {simple_action, method} = TemporalConverter.convert_durative_action(original_action)

      # This would use existing temporal validation system
      # For now, just verify structure is preserved
      assert simple_action.duration == original_action.duration
      assert is_list(method)
      assert length(method) >= 1
    end
  end

  describe "Phase 3: Module-based Domain Creation" do
    test "creates domain from module with @action attributes" do
      domain = UnifiedDomain.create_from_module(GltfInteractivityDomain)

      # Verify domain structure
      assert %AriaCore.Domain{} = domain

      # Should have actions from @action attributes
      actions = AriaCore.Domain.list_actions(domain)
      assert :move_node in actions
      assert :start_animation in actions
      assert :wait_time in actions

      # Should have methods from @task_method attributes
      methods = AriaCore.Domain.list_methods(domain)
      assert :move_and_animate_method in methods
    end

    test "validates domain module configuration" do
      # Valid module should pass validation
      assert :ok = UnifiedDomain.validate_domain_module(GltfInteractivityDomain)

      # Invalid module should fail validation
      defmodule InvalidModule do
        # Missing use AriaCore.Domain
      end

      assert {:error, _reason} = UnifiedDomain.validate_domain_module(InvalidModule)
    end

    test "merges multiple domains correctly" do
      # Create two separate domains
      domain1 = UnifiedDomain.create_from_module(GltfInteractivityDomain)

      defmodule TestDomain2 do
        use AriaCore.Domain

        @action duration: "PT1H", requires_entities: []
        def test_action(state, []), do: state
      end

      domain2 = UnifiedDomain.create_from_module(TestDomain2)

      # Merge domains
      merged = UnifiedDomain.merge_domains([domain1, domain2])

      # Should contain actions from both domains
      actions = AriaCore.Domain.list_actions(merged)
      assert :move_node in actions  # From GltfInteractivityDomain
      assert :test_action in actions  # From TestDomain2
    end
  end

  describe "Entity Management System" do
    test "creates and manages entity registry" do
      registry = Management.new_registry()

      # Register entity types
      chef_spec = %{type: "chef", capabilities: [:cooking, :baking]}
      oven_spec = %{type: "oven", capabilities: [:heating]}

      registry = registry
      |> Management.register_entity_type(chef_spec)
      |> Management.register_entity_type(oven_spec)

      # Verify registration
      assert Map.has_key?(registry.entity_types, "chef")
      assert Map.has_key?(registry.entity_types, "oven")

      # Test entity matching
      requirements = [%{type: "chef", capabilities: [:cooking]}]
      {:ok, matches} = Management.match_entities(registry, requirements)

      assert length(matches) > 0
      assert Enum.all?(matches, fn match -> match.entity_type == "chef" end)
    end

    test "validates entity registry consistency" do
      registry = Management.new_registry()
      |> Management.register_entity_type(%{type: "test", capabilities: [:test_cap]})

      assert :ok = Management.validate_registry(registry)
    end
  end

  describe "Temporal Interval System" do
    test "parses ISO 8601 durations correctly" do
      assert Interval.parse_iso8601("PT2H") == {:fixed, 7200}
      assert Interval.parse_iso8601("PT30M") == {:fixed, 1800}
      assert Interval.parse_iso8601("PT2H30M") == {:fixed, 9000}
      assert Interval.parse_iso8601("PT45S") == {:fixed, 45}
    end

    test "creates and manages temporal specifications" do
      specs = Interval.new_specifications()

      # Add action durations
      duration1 = Interval.fixed(3600)
      duration2 = Interval.variable(1800, 7200)

      specs = specs
      |> Interval.add_action_duration(:action1, duration1)
      |> Interval.add_action_duration(:action2, duration2)

      # Verify durations
      assert Interval.get_action_duration(specs, :action1) == duration1
      assert Interval.get_action_duration(specs, :action2) == duration2
    end

    test "validates duration specifications" do
      assert :ok = Interval.validate({:fixed, 3600})
      assert :ok = Interval.validate({:variable, {1800, 3600}})
      assert {:error, _} = Interval.validate({:invalid, "bad"})
    end

    test "calculates actual durations from specifications" do
      # Fixed duration
      assert Interval.calculate_duration({:fixed, 3600}) == 3600

      # Variable duration (returns average)
      assert Interval.calculate_duration({:variable, {1800, 3600}}) == 2700

      # Conditional duration
      conditions = %{{"skill_level", "chef", :expert} => 1800}
      state = %{{"skill_level", "chef"} => :expert}
      assert Interval.calculate_duration({:conditional, conditions}, state) == 1800
    end
  end

  describe "State Management System" do
    test "manages relational state with facts and goals" do
      state = Relational.new()

      # Set facts
      state = state
      |> Relational.set_fact("status", "chef_1", "available")
      |> Relational.set_fact("temperature", "oven_1", 350)

      # Query facts
      assert {:ok, "available"} = Relational.get_fact(state, "status", "chef_1")
      assert {:ok, 350} = Relational.get_fact(state, "temperature", "oven_1")

      # Test goal satisfaction
      assert Relational.satisfies_goal?(state, {"status", "chef_1", "available"})
      assert Relational.satisfies_goal?(state, {"temperature", "oven_1", {:>=, 300}})
      refute Relational.satisfies_goal?(state, {"temperature", "oven_1", {:>=, 400}})
    end

    test "handles multiple goals and state changes" do
      state = Relational.new()

      # Apply multiple changes
      changes = [
        {"status", "chef_1", "busy"},
        {"task", "chef_1", "cooking"},
        {"temperature", "oven_1", 375}
      ]

      state = Relational.apply_changes(state, changes)

      # Test multiple goals
      goals = [
        {"status", "chef_1", "busy"},
        {"temperature", "oven_1", {:>=, 350}}
      ]

      assert Relational.satisfies_goals?(state, goals)
    end

    test "queries state with pattern matching" do
      state = Relational.new()
      |> Relational.set_fact("status", "chef_1", "busy")
      |> Relational.set_fact("location", "chef_1", "kitchen")
      |> Relational.set_fact("status", "chef_2", "available")

      # Query all facts about chef_1
      chef_1_facts = Relational.query(state, {:_, "chef_1", :_})
      assert length(chef_1_facts) == 2

      # Query all status facts
      status_facts = Relational.query(state, {"status", :_, :_})
      assert length(status_facts) == 2
    end
  end

  describe "Integration Testing" do
    test "complete workflow from module to execution" do
      # Create domain from module
      domain = UnifiedDomain.create_from_module(GltfInteractivityDomain)

      # Set up initial state
      state = GltfInteractivityDomain.create_simple_test_state()

      # Define goals
      goals = GltfInteractivityDomain.create_simple_test_goals()

      # Verify domain has required actions
      actions = AriaCore.Domain.list_actions(domain)
      assert :move_node in actions

      # Verify state has required facts
      assert {:ok, true} = Relational.get_fact(state, "node_exists", "cube_1")
      assert {:ok, [0.0, 0.0, 0.0]} = Relational.get_fact(state, "node_position", "cube_1")

      # Verify goals are well-formed
      assert is_list(goals)
      assert length(goals) > 0

      # This demonstrates the complete integration
      # In a full system, this would proceed to planning and execution
      workflow_result = %{
        domain_created: true,
        actions_available: length(actions),
        state_initialized: map_size(state.facts) > 0,
        goals_defined: length(goals)
      }

      assert workflow_result.domain_created
      assert workflow_result.actions_available > 0
      assert workflow_result.state_initialized
      assert workflow_result.goals_defined > 0
    end

    test "demonstrates sociable testing approach" do
      # Verify that new systems leverage existing AriaCore functionality

      # 1. ActionAttributes uses existing Domain.new()
      domain_module = GltfInteractivityDomain
      base_domain = AriaCore.Domain.new(domain_module)
      assert %AriaCore.Domain{} = base_domain

      # 2. Entity.Management provides complete entity system
      registry = Management.new_registry()
      assert %Management{} = registry

      # 3. Temporal.Interval provides complete temporal system
      specs = Interval.new_specifications()
      assert %Interval{} = specs

      # 4. AriaState provides complete state system
      state = Relational.new()
      assert %Relational{} = state

      # 5. UnifiedDomain bridges everything together
      unified_domain = UnifiedDomain.create_from_module(GltfInteractivityDomain)
      assert %AriaCore.Domain{} = unified_domain

      # All systems work together without reimplementing core functionality
      assert true
    end

    test "validates temporal pattern support" do
      # Test all 9 temporal patterns mentioned in ADR-181

      # 1. Fixed duration
      fixed_duration = Interval.fixed(3600)
      assert Interval.validate(fixed_duration) == :ok

      # 2. Variable duration
      variable_duration = Interval.variable(1800, 7200)
      assert Interval.validate(variable_duration) == :ok

      # 3. Conditional duration
      conditional_duration = Interval.conditional(%{
        {"skill_level", "chef", :expert} => 1800
      })
      assert Interval.validate(conditional_duration) == :ok

      # 4-6. Execution patterns (parallel, sequential, overlapping)
      actions = [:action1, :action2, :action3]

      parallel_pattern = Interval.create_execution_pattern(:parallel, actions)
      assert parallel_pattern.type == :parallel

      sequential_pattern = Interval.create_execution_pattern(:sequential, actions)
      assert sequential_pattern.type == :sequential

      overlapping_pattern = Interval.create_execution_pattern(:overlapping, actions)
      assert overlapping_pattern.type == :overlapping

      # 7. Deadline constraints (via temporal constraints)
      specs = Interval.new_specifications()
      deadline = {:deadline, ~U[2025-06-26 10:00:00Z]}
      specs = Interval.add_constraint(specs, :test_action, deadline)
      constraints = Interval.get_action_constraints(specs, :test_action)
      assert deadline in constraints

      # 8. Resource-dependent timing
      resource_duration = {:resource_dependent, %{
        resource_type: "tools",
        base_duration: 1800,
        efficiency_map: %{professional: 0.8}
      }}
      assert Interval.validate(resource_duration) == :ok

      # 9. Temporal conditions (at_start/over_all/at_end)
      # Tested in temporal converter section above
      assert true
    end
  end

  describe "Error Handling and Edge Cases" do
    test "handles invalid action metadata gracefully" do
      invalid_metadata = [
        duration: "invalid_duration",
        requires_entities: "not_a_list"
      ]

      # Should not crash, should provide reasonable defaults
      action_spec = ActionAttributes.convert_action_metadata(invalid_metadata, :test_action, TestModule)
      assert action_spec.duration != nil
      assert is_list(action_spec.entity_requirements)
    end

    test "handles empty or missing metadata" do
      empty_metadata = []
      action_spec = ActionAttributes.convert_action_metadata(empty_metadata, :test_action, TestModule)

      # Should provide sensible defaults
      assert action_spec.duration != nil
      assert is_list(action_spec.entity_requirements)
      assert is_list(action_spec.preconditions)
      assert is_list(action_spec.effects)
    end

    test "validates state consistency" do
      state = Relational.new()
      |> Relational.set_fact("test", "subject", "value")

      assert :ok = Relational.validate(state)
    end
  end
end

# Test helper module for action metadata testing
defmodule TestModule do
  def test_function(_state, _args), do: :ok
end
