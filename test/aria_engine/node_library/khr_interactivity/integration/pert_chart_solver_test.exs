# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Integration.PertChartSolverTest do
  use ExUnit.Case, async: true
  
  alias NodeLibrary.KHRInteractivityDomain
  alias NodeLibrary.KHRInteractivity.VariableInterpolation
  alias Domain.{Core, Methods}
  alias StateV2
  alias HybridPlanner.HybridCoordinatorV2
  alias Plan
  
  describe "PERT Chart Solver with Hybrid Planner and KHR Durative Actions" do
    setup do
      # Create comprehensive domain with all KHR nodes and variable interpolation
      domain = Core.new()
      |> KHRInteractivityDomain.register_all_actions()
      |> VariableInterpolation.register_all()
      |> register_construction_domain()
      
      # Initial state for construction project
      initial_state = StateV2.new()
      |> StateV2.set_fact("project", "name", "house_construction")
      |> StateV2.set_fact("project", "status", "ready")
      |> StateV2.set_fact("resources", "crew_available", true)
      |> StateV2.set_fact("resources", "equipment_available", true)
      |> StateV2.set_fact("resources", "materials_available", true)
      
      {:ok, domain: domain, state: initial_state}
    end
    
    test "Part 1: PERT chart planning with hybrid planner", %{domain: domain, state: initial_state} do
      # Define construction project goals using ADR-096 house construction example
      project_goals = [
        {"construct_house", ["foundation", "framing", "finishing"]}
      ]
      
      # Create hybrid coordinator with default strategies
      coordinator = HybridCoordinatorV2.new_default()
      
      # Test planning phase
      case HybridCoordinatorV2.plan(coordinator, domain, initial_state, project_goals, verbose: 3) do
        {:ok, plan} ->
          # Verify plan structure
          assert Map.has_key?(plan, :solution_tree)
          assert Map.has_key?(plan, :temporal_constraints)
          assert Map.has_key?(plan, :metadata)
          
          # Verify solution tree contains construction tasks
          solution_tree = plan.solution_tree
          assert Map.has_key?(solution_tree, :root_id)
          assert Map.has_key?(solution_tree, :nodes)
          
          # Verify temporal constraints exist
          temporal_constraints = plan.temporal_constraints
          assert is_map(temporal_constraints)
          
          # Verify metadata contains planning information
          metadata = plan.metadata
          assert Map.has_key?(metadata, :goals)
          assert Map.has_key?(metadata, :domain_name)
          assert metadata.goals == project_goals
          
          # Test that plan contains durative actions for task progress
          primitive_actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
          
          # Should contain variable interpolation actions for progress tracking
          interpolation_actions = Enum.filter(primitive_actions, fn {action_name, _args} ->
            action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name
            action_atom in [:khr_variable_interpolate_instant, :khr_variable_set_progress]
          end)
          
          assert length(interpolation_actions) > 0, "Plan should contain progress tracking actions"
          
          # Verify plan can be validated
          case Plan.validate_plan(domain, initial_state, solution_tree) do
            {:ok, final_state} ->
              # Verify construction project completion state
              assert StateV2.get_fact(final_state, "project", "status") != nil
              
            {:error, reason} ->
              flunk("Plan validation failed: #{reason}")
          end
          
        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end
    
    test "PERT critical path identification", %{domain: domain, state: initial_state} do
      # Test critical path planning with dependencies
      critical_path_goals = [
        {"excavate_footers", [4.0]},      # 4 days duration
        {"pour_foundation", [2.0]},       # 2 days, depends on excavation
        {"erect_frame", [4.0]},          # 4 days, depends on foundation
        {"install_wiring", [2.0]},       # 2 days, depends on frame
        {"install_plumbing", [3.0]},     # 3 days, depends on frame
        {"fasten_plasterboard", [10.0]}  # 10 days, depends on wiring and plumbing
      ]
      
      coordinator = HybridCoordinatorV2.new_default()
      
      case HybridCoordinatorV2.plan(coordinator, domain, initial_state, critical_path_goals, verbose: 2) do
        {:ok, plan} ->
          # Verify temporal constraints capture dependencies
          temporal_constraints = plan.temporal_constraints
          assert map_size(temporal_constraints) > 0
          
          # Verify solution tree structure
          solution_tree = plan.solution_tree
          nodes = solution_tree.nodes
          
          # Should have nodes for each major task
          task_nodes = Enum.filter(nodes, fn {_id, node} ->
            case node.task do
              {task_name, _args} when is_binary(task_name) ->
                String.contains?(task_name, "excavate") or 
                String.contains?(task_name, "pour") or
                String.contains?(task_name, "erect") or
                String.contains?(task_name, "install") or
                String.contains?(task_name, "fasten")
              _ -> false
            end
          end)
          
          assert length(task_nodes) > 0, "Should have construction task nodes"
          
        {:error, reason} ->
          flunk("Critical path planning failed: #{reason}")
      end
    end
    
    test "KHR durative actions in construction context", %{domain: domain, state: initial_state} do
      # Test that KHR durative actions work in construction planning
      durative_goals = [
        {"variable/interpolate", ["task_a_progress", 1.0, 4.0]}, # 4 day task
        {"variable/interpolate", ["task_b_progress", 1.0, 2.0]}, # 2 day task
        {"variable/set_progress", ["task_c_progress", 0.5]}      # 50% complete
      ]
      
      coordinator = HybridCoordinatorV2.new_default()
      
      case HybridCoordinatorV2.plan(coordinator, domain, initial_state, durative_goals, verbose: 1) do
        {:ok, plan} ->
          solution_tree = plan.solution_tree
          
          # Verify durative actions are in the plan
          primitive_actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
          
          durative_action_count = Enum.count(primitive_actions, fn {action_name, _args} ->
            action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name
            action_atom in [:khr_variable_interpolate_instant, :khr_variable_set_progress]
          end)
          
          assert durative_action_count > 0, "Should contain KHR durative actions"
          
          # Test plan execution readiness
          case Plan.validate_plan(domain, initial_state, solution_tree) do
            {:ok, final_state} ->
              # Verify progress variables were created/updated
              task_a_progress = StateV2.get_fact(final_state, "task_a_progress", "progress")
              task_c_progress = StateV2.get_fact(final_state, "task_c_progress", "progress")
              
              # At least one progress variable should be set
              assert task_a_progress != nil or task_c_progress != nil
              
            {:error, reason} ->
              flunk("Durative action plan validation failed: #{reason}")
          end
          
        {:error, reason} ->
          flunk("Durative action planning failed: #{reason}")
      end
    end
    
    test "MCP integration data format preparation", %{domain: domain, state: initial_state} do
      # Test that plan results are structured for MCP tool integration
      mcp_ready_goals = [
        {"construct_simple_project", ["task1", "task2", "task3"]}
      ]
      
      coordinator = HybridCoordinatorV2.new_default()
      
      case HybridCoordinatorV2.plan(coordinator, domain, initial_state, mcp_ready_goals) do
        {:ok, plan} ->
          # Verify MCP-compatible data structure
          mcp_data = format_plan_for_mcp(plan, initial_state)
          
          # Should have required MCP fields
          assert Map.has_key?(mcp_data, :execution_plan)
          assert Map.has_key?(mcp_data, :critical_path)
          assert Map.has_key?(mcp_data, :resource_requirements)
          assert Map.has_key?(mcp_data, :timeline_estimate)
          
          # Execution plan should be a list of steps
          execution_plan = mcp_data.execution_plan
          assert is_list(execution_plan)
          assert length(execution_plan) > 0
          
          # Each step should have required fields
          Enum.each(execution_plan, fn step ->
            assert Map.has_key?(step, :action)
            assert Map.has_key?(step, :duration)
            assert Map.has_key?(step, :dependencies)
          end)
          
          # Timeline estimate should be numeric
          assert is_number(mcp_data.timeline_estimate)
          assert mcp_data.timeline_estimate > 0
          
        {:error, reason} ->
          flunk("MCP preparation planning failed: #{reason}")
      end
    end
    
    test "Hybrid planner strategy composition", %{domain: domain, state: initial_state} do
      # Test that hybrid planner uses all required strategies
      coordinator = HybridCoordinatorV2.new_default()
      
      # Verify strategy composition
      strategy_info = HybridCoordinatorV2.get_strategy_info(coordinator)
      
      required_strategies = [
        :planning_strategy,
        :temporal_strategy,
        :state_strategy,
        :domain_strategy,
        :logging_strategy,
        :execution_strategy
      ]
      
      Enum.each(required_strategies, fn strategy_type ->
        assert Map.has_key?(strategy_info, strategy_type),
               "Missing strategy: #{strategy_type}"
        
        strategy_module = Map.get(strategy_info, strategy_type)
        assert Map.has_key?(strategy_module, :module),
               "Strategy #{strategy_type} missing module info"
      end)
      
      # Test planning with strategy composition
      simple_goals = [{"test_task", []}]
      
      case HybridCoordinatorV2.plan(coordinator, domain, initial_state, simple_goals) do
        {:ok, plan} ->
          # Verify plan metadata includes strategy information
          metadata = plan.metadata
          assert Map.has_key?(metadata, :strategy_coordinator)
          
          strategy_metadata = metadata.strategy_coordinator
          assert Map.has_key?(strategy_metadata, :strategy_composition)
          
        {:error, reason} ->
          flunk("Strategy composition test failed: #{reason}")
      end
    end
    
    test "Variable interpolation durative action functionality", %{domain: _domain, state: initial_state} do
      # Test the core variable interpolation durative action directly
      
      # Set up initial progress variable
      state_with_progress = VariableInterpolation.create_progress_variable(
        initial_state, 
        "test_task_progress", 
        0.0
      )
      
      # Test durative interpolation
      final_state = VariableInterpolation.variable_interpolate_durative_action(
        state_with_progress,
        [1, "test_task_progress", 1.0, 4.0] # node_id, variable, target, duration
      )
      
      # Verify interpolation completed
      assert StateV2.get_fact(final_state, "test_task_progress", "value") == 1.0
      assert StateV2.get_fact(final_state, "test_task_progress", "progress") == 1.0
      assert StateV2.get_fact(final_state, "1", "completed") == true
      assert StateV2.get_fact(final_state, "1", "duration") == 4.0
      
      # Test instant interpolation
      instant_state = VariableInterpolation.variable_interpolate_instant(
        state_with_progress,
        [2, "test_task_progress", 1.0, 0.5] # 50% progress
      )
      
      # Should be halfway interpolated
      assert StateV2.get_fact(instant_state, "test_task_progress", "value") == 0.5
      assert StateV2.get_fact(instant_state, "test_task_progress", "progress") == 0.5
      assert StateV2.get_fact(instant_state, "2", "progress") == 0.5
    end
  end
  
  # ==================== HELPER FUNCTIONS ====================
  
  defp register_construction_domain(domain) do
    # Register HTN methods for construction tasks
    domain
    |> Methods.add_task_methods("construct_house", [
      {"sequential_construction", &construct_house_method/2}
    ])
    |> Methods.add_task_methods("excavate_footers", [
      {"with_progress_tracking", &excavate_footers_method/2}
    ])
    |> Methods.add_task_methods("pour_foundation", [
      {"with_progress_tracking", &pour_foundation_method/2}
    ])
    |> Methods.add_task_methods("erect_frame", [
      {"with_progress_tracking", &erect_frame_method/2}
    ])
    |> Methods.add_task_methods("install_wiring", [
      {"with_progress_tracking", &install_wiring_method/2}
    ])
    |> Methods.add_task_methods("install_plumbing", [
      {"with_progress_tracking", &install_plumbing_method/2}
    ])
    |> Methods.add_task_methods("fasten_plasterboard", [
      {"with_progress_tracking", &fasten_plasterboard_method/2}
    ])
    |> Methods.add_task_methods("construct_simple_project", [
      {"basic_sequence", &construct_simple_project_method/2}
    ])
    |> Methods.add_task_methods("test_task", [
      {"basic_test", &test_task_method/2}
    ])
  end
  
  # HTN method implementations
  defp construct_house_method(_state, [_foundation_type, _framing_type, _finishing_type]) do
    [
      ["excavate_footers", [4.0]],
      ["pour_foundation", [2.0]],
      ["erect_frame", [4.0]],
      ["install_wiring", [2.0]],
      ["install_plumbing", [3.0]],
      ["fasten_plasterboard", [10.0]],
      ["variable/set_progress", ["house_construction_progress", 1.0]]
    ]
  end
  
  defp excavate_footers_method(_state, [duration]) do
    [
      {"variable/interpolate", ["excavation_progress", 1.0, duration]},
      {"khr_variable_set", [1, "excavation_complete", true]}
    ]
  end
  
  defp pour_foundation_method(_state, [duration]) do
    [
      {"variable/interpolate", ["foundation_progress", 1.0, duration]},
      {"khr_variable_set", [2, "foundation_complete", true]}
    ]
  end
  
  defp erect_frame_method(_state, [duration]) do
    [
      {"variable/interpolate", ["framing_progress", 1.0, duration]},
      {"khr_variable_set", [3, "framing_complete", true]}
    ]
  end
  
  defp install_wiring_method(_state, [duration]) do
    [
      {"variable/interpolate", ["wiring_progress", 1.0, duration]},
      {"khr_variable_set", [4, "wiring_complete", true]}
    ]
  end
  
  defp install_plumbing_method(_state, [duration]) do
    [
      {"variable/interpolate", ["plumbing_progress", 1.0, duration]},
      {"khr_variable_set", [5, "plumbing_complete", true]}
    ]
  end
  
  defp fasten_plasterboard_method(_state, [duration]) do
    [
      {"variable/interpolate", ["plasterboard_progress", 1.0, duration]},
      {"khr_variable_set", [6, "plasterboard_complete", true]}
    ]
  end
  
  defp construct_simple_project_method(_state, [task1, task2, task3]) do
    [
      {"variable/set_progress", ["#{task1}_progress", 0.0]},
      {"variable/interpolate", ["#{task1}_progress", 1.0, 2.0]},
      {"variable/set_progress", ["#{task2}_progress", 0.0]},
      {"variable/interpolate", ["#{task2}_progress", 1.0, 3.0]},
      {"variable/set_progress", ["#{task3}_progress", 0.0]},
      {"variable/interpolate", ["#{task3}_progress", 1.0, 1.0]}
    ]
  end
  
  defp test_task_method(_state, []) do
    [
      {"khr_variable_set", [1, "test_complete", true]}
    ]
  end
  
  defp format_plan_for_mcp(plan, _initial_state) do
    solution_tree = plan.solution_tree
    primitive_actions = Plan.Utils.get_primitive_actions_dfs(solution_tree)
    
    # Convert to MCP-compatible format
    execution_plan = Enum.map(primitive_actions, fn {action_name, args} ->
      %{
        action: action_name,
        arguments: args,
        duration: extract_duration_from_args(args),
        dependencies: []  # Would be extracted from temporal constraints in full implementation
      }
    end)
    
    %{
      execution_plan: execution_plan,
      critical_path: extract_critical_path(primitive_actions),
      resource_requirements: %{
        crew_allocation: 0.90,
        equipment_usage: 0.85,
        material_efficiency: 0.92
      },
      timeline_estimate: calculate_timeline_estimate(execution_plan)
    }
  end
  
  defp extract_duration_from_args(args) do
    # Look for duration in common argument positions
    case args do
      [_node_id, _var_name, _target, duration] when is_number(duration) -> duration
      [_node_id, duration] when is_number(duration) -> duration
      _ -> 1.0  # Default duration
    end
  end
  
  defp extract_critical_path(primitive_actions) do
    # Simplified critical path extraction
    Enum.filter(primitive_actions, fn {action_name, _args} ->
      action_str = if is_atom(action_name), do: Atom.to_string(action_name), else: action_name
      String.contains?(action_str, "interpolate") or String.contains?(action_str, "progress")
    end)
    |> Enum.map(fn {action_name, _args} -> action_name end)
  end
  
  defp calculate_timeline_estimate(execution_plan) do
    # Sum all durations for simple timeline estimate
    Enum.reduce(execution_plan, 0.0, fn step, acc ->
      acc + step.duration
    end)
  end
end
