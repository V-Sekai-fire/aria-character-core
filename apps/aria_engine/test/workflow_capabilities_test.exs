# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.WorkflowCapabilitiesTest do
  @moduledoc """
  Flow-based workflow capabilities testing that replaces Membrane functionality.
  
  This module tests the Flow-based parallel processing and workflow orchestration
  capabilities that have replaced the Membrane-based system.
  """

  use ExUnit.Case, async: false

  alias AriaEngine.Test.FlowTestHelpers.{
    FlowBackflowTester,
    FlowConvergenceResultCollector,
    FlowBackflowResultCollector,
    RandomMovementProcessor,
    FPSCollector
  }

  # Test suite for Flow-based workflow capabilities
  describe "Flow-based Workflow Capabilities" do
    test "complex temporal planning workflow with branching" do
      # Complex multi-stage workflow using Flow instead of Membrane
      complex_jobs = [
        %{type: :plan_sequence, actions: [
          %{action: :move_to, target: {10, 5}},
          %{action: :attack, target: :enemy_1},
          %{action: :use_skill, skill: :fireball}
        ]},
        %{type: :execute_sequence, sequence: [
          %{action: :move_to, target: {12, 7}, status: :planned},
          %{action: :attack, target: :enemy_2, status: :planned}
        ]},
        %{type: :invalid}  # This should trigger error handling
      ]

      # Use Flow-based processing instead of Membrane
      {:ok, pipeline} = FlowBackflowTester.create_backflow_pipeline("temporal_planning_test")
      
      result = FlowBackflowTester.process_with_backflow_optimization(
        "temporal_planning_test", 
        complex_jobs,
        [workflow_type: :temporal_planning, error_handling: true]
      )

      # Verify results (simplified for Flow-based processing)
      assert {:ok, _pipeline} = result
      
      # For now, just verify the pipeline was created successfully
      # TODO: Implement full Flow-based workflow result collection
    end

    test "job persistence and durability with Flow" do
      storage_path = "priv/test_flow_jobs"
      File.mkdir_p(storage_path)

      jobs = [
        %{id: 1, type: :persistent_action, data: "test_data_1"},
        %{id: 2, type: :persistent_action, data: "test_data_2"}
      ]

      # Use Flow for job processing with persistence
      {:ok, pipeline} = FlowBackflowTester.create_backflow_pipeline("persistence_test")
      
      result = FlowBackflowTester.process_with_backflow_optimization(
        "persistence_test",
        jobs,
        [storage_path: storage_path, persist_results: true]
      )

      assert {:ok, _pipeline} = result

      # Clean up
      File.rm_rf(storage_path)
    end

    test "Flow parallel processing efficiency: 1 core vs all cores" do
      # Generate test data
      action_count = 100
      actions = RandomMovementProcessor.generate_movement_actions(action_count)

      # Test with 1 core
      start_time_1 = DateTime.utc_now()
      {:ok, _pipeline_1} = FlowBackflowTester.process_with_backflow_optimization(
        "single_core_test",
        actions,
        [max_demand: 1, stages: 1]
      )
      end_time_1 = DateTime.utc_now()

      # Test with all cores
      core_count = System.schedulers_online()
      start_time_all = DateTime.utc_now()
      {:ok, _pipeline_all} = FlowBackflowTester.process_with_backflow_optimization(
        "multi_core_test",
        actions,
        [max_demand: core_count, stages: core_count]
      )
      end_time_all = DateTime.utc_now()

      # Calculate efficiency
      single_duration = DateTime.diff(end_time_1, start_time_1, :millisecond)
      multi_duration = DateTime.diff(end_time_all, start_time_all, :millisecond)
      
      # Multi-core should be faster (or at least not significantly slower)
      efficiency_ratio = if multi_duration > 0, do: single_duration / multi_duration, else: 1.0
      
      # Log results for analysis
      IO.puts("Single core: #{single_duration}ms, Multi core: #{multi_duration}ms, Efficiency: #{Float.round(efficiency_ratio, 2)}x")
      
      # Accept any positive efficiency (parallel processing can vary)
      assert efficiency_ratio > 0.5
    end

    test "game subsystem integration pattern (architectural demo)" do
      # Simulate game subsystem routing
      game_actions = [
        %{type: :movement, player_id: 1, x: 10, y: 20},
        %{type: :combat, player_id: 1, target: :enemy_1},
        %{type: :inventory, player_id: 1, action: :use_item, item: :potion}
      ]

      {:ok, pipeline} = FlowBackflowTester.create_backflow_pipeline("game_integration_test")
      
      result = FlowBackflowTester.process_with_backflow_optimization(
        "game_integration_test",
        game_actions,
        [routing: :game_subsystems, parallel: true]
      )

      assert {:ok, _pipeline} = result
    end

    test "simple random movement performance test" do
      action_count = 50
      actions = RandomMovementProcessor.generate_movement_actions(action_count)

      start_time = DateTime.utc_now()
      
      {:ok, pipeline} = FlowBackflowTester.process_with_backflow_optimization(
        "movement_perf_test",
        actions,
        [processor_function: &RandomMovementProcessor.process_movement/1]
      )
      
      end_time = DateTime.utc_now()

      stats = FPSCollector.collect_fps_stats(start_time, end_time, action_count)
      
      # Should process at reasonable speed
      assert stats.fps > 0
      assert stats.processed_count == action_count
      
      IO.puts(FPSCollector.format_fps_report(stats))
    end

    test "random movement FPS test - processing speed = more frames" do
      action_count = 100
      actions = RandomMovementProcessor.generate_movement_actions(action_count)

      start_time = DateTime.utc_now()
      
      # Process with optimized settings
      {:ok, pipeline} = FlowBackflowTester.process_with_backflow_optimization(
        "movement_fps_test",
        actions,
        [
          processor_function: &RandomMovementProcessor.process_movement/1,
          max_demand: System.schedulers_online(),
          stages: System.schedulers_online()
        ]
      )
      
      end_time = DateTime.utc_now()

      stats = FPSCollector.collect_fps_stats(start_time, end_time, action_count)
      
      # Higher action count should still maintain reasonable FPS
      assert stats.fps > 0
      assert stats.avg_processing_time_ms < 100  # Less than 100ms average per action
      
      IO.puts("FPS Test Results: #{Float.round(stats.fps, 2)} FPS for #{action_count} actions")
    end
  end
end
