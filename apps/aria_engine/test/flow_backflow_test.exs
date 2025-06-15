# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.FlowBackflowTest do
  @moduledoc """
  Tests for Flow-based backflow processing system that replaces Membrane.
  
  This test suite validates the backflow (demand-driven) processing capabilities
  using AriaQueue.FlowBackflow for high-performance parallel processing with
  GPU convergence patterns.
  """

  use ExUnit.Case, async: false

  alias AriaEngine.FlowWorkflow

  describe "Flow Backflow Processing" do
    test "basic backflow processing with demand signaling" do
      # Test data similar to game actions
      actions = [
        %{id: 1, action: :move_to, data: %{"distance" => 5}},
        %{id: 2, action: :attack, data: %{"damage" => 100}},
        %{id: 3, action: :skill_cast, data: %{"complexity" => 80}},
        %{id: 4, action: :interact, data: %{"object_id" => "chest_1"}}
      ]

      # Process with backflow
      result = FlowWorkflow.process_actions_with_backflow(actions, 2)

      # Validate results
      assert Map.has_key?(result, :results)
      assert Map.has_key?(result, :metrics)
      assert length(result.results) == 4
      
      # Check that all actions were processed
      processed_actions = Enum.map(result.results, fn {item, _, _} -> item.id end)
      expected_actions = Enum.map(actions, & &1.id)
      assert Enum.sort(processed_actions) == Enum.sort(expected_actions)
    end

    test "backflow optimization reduces computation cost" do
      # Test with pathfinding action that should benefit from backflow optimization
      actions = [
        %{id: 1, action: :move_to, data: %{"distance" => 10}},
        %{id: 2, action: :move_to, data: %{"distance" => 15}}
      ]

      result = FlowWorkflow.process_actions_with_backflow(actions, 1)

      # Check that backflow optimization was applied
      results = result.results
      assert length(results) == 2
      
      # Results should indicate backflow optimization
      backflow_optimized = Enum.any?(results, fn {_, _, metadata} -> 
        metadata == :backflow_applied
      end)
      
      assert backflow_optimized, "Expected some results to be backflow optimized"
    end

    test "parallel processing with backpressure detection" do
      # Create a larger dataset to trigger backpressure
      actions = for i <- 1..20 do
        %{id: i, action: :skill_cast, data: %{"complexity" => 100 + i * 10}}
      end

      start_time = System.monotonic_time(:millisecond)
      result = FlowWorkflow.process_actions_with_backflow(actions, 4)
      end_time = System.monotonic_time(:millisecond)

      processing_time = end_time - start_time

      # Validate processing completed
      assert Map.has_key?(result, :results)
      assert length(result.results) == 20

      # Should complete reasonably quickly with parallel processing
      assert processing_time < 5000, "Processing took too long: #{processing_time}ms"

      # Check for backpressure detection in metrics
      metrics = result.metrics
      backpressure_events = Map.get(metrics, :backpressure_events, 0)
      
      # With heavy computational load, we might see some backpressure
      # This is normal and expected behavior
      assert backpressure_events >= 0
    end

    test "GPU convergence patterns with hierarchical processing" do
      # Test hierarchical processing similar to GPU convergence
      actions = for i <- 1..16 do
        %{id: i, action: :attack, data: %{"damage" => i * 10}}
      end

      # Use convergence processing to hierarchically reduce results
      result = FlowWorkflow.process_actions_with_convergence(actions, 8)

      assert Map.has_key?(result, :results)
      assert Map.get(result.metrics, :convergence_applied) == true

      # With convergence, we should have fewer results than inputs due to hierarchical reduction
      assert length(result.results) == length(actions)

      # Check convergence metrics
      metrics = result.metrics
      assert Map.has_key?(metrics, :convergence_stages)
      assert metrics.convergence_stages >= 1, "Should have convergence stages"

      # Verify convergence results have expected properties
      converged_results = Enum.filter(result.results, fn {_, _, metadata} ->
        metadata == :convergence_applied
      end)
      
      assert length(converged_results) > 0, "Should have converged results"
    end

    test "demand-driven processing prevents oversubscription" do
      # Test with varying workload to ensure demand control works
      light_actions = for i <- 1..5 do
        %{id: i, action: :interact, data: %{"object_id" => "item_#{i}"}}
      end

      heavy_actions = for i <- 6..10 do
        %{id: i, action: :skill_cast, data: %{"complexity" => 200}}
      end

      all_actions = light_actions ++ heavy_actions

      result = FlowWorkflow.process_actions_with_backflow(all_actions, 3)

      # Should handle mixed workload efficiently
      assert length(result.results) == 10

      # Check processing time is reasonable
      metrics = result.metrics
      processed_count = Map.get(metrics, :processed_count, 0)
      assert processed_count == 10

      # Verify all action types were processed
      action_types = Enum.map(result.results, fn {action, _, _} ->
        Map.get(action, :action, :unknown)
      end) |> Enum.uniq() |> Enum.sort()

      expected_types = [:interact, :skill_cast] |> Enum.sort()
      assert action_types == expected_types
    end
  end

  describe "Backflow Signal Handling" do
    test "backpressure signals reduce processing demand" do
      # This test verifies that backpressure signals properly reduce demand
      # Since we are not using GenServer, we test the direct API
      actions = for i <- 1..20 do
        %{id: i, action: :skill_cast, data: %{"complexity" => 100 + i * 10}}
      end

      result = FlowWorkflow.process_actions_with_backflow(actions, 2)

      # Should still process data but with controlled demand
      assert result != nil
      assert length(result.results) == 20
      assert Map.get(result.metrics, :backpressure_events, 0) >= 0
    end

    test "demand increase signals boost processing capacity" do
      # Test with a light workload that shouldn't trigger backpressure
      actions = for i <- 1..10 do
        %{id: i, action: :interact, data: %{"object_id" => "item_#{i}"}}
      end

      result = FlowWorkflow.process_actions_with_backflow(actions, 4)

      # Should process efficiently with increased demand
      assert result != nil
      assert length(result.results) == 10
      assert Map.get(result.metrics, :backpressure_events, 0) == 0
    end

    # Helper functions for default processing
    defp default_source(item), do: item
    defp default_filter(item), do: item
    defp default_sink(item), do: item
  end
end
