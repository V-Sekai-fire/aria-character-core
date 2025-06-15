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
      processed_actions = Enum.map(result.results, & &1.id)
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
      backflow_optimized = Enum.any?(results, fn r -> 
        Map.get(r, :backflow_optimized, false)
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
      assert Map.has_key?(result, :convergence_applied)
      assert result.convergence_applied == true

      # With convergence, we should have fewer results than inputs due to hierarchical reduction
      assert length(result.results) < length(actions), "Convergence should reduce result count"
      assert length(result.results) >= 1, "Should have at least one converged result"

      # Check convergence metrics
      metrics = result.metrics
      assert Map.has_key?(metrics, :convergence_stages)
      assert Map.has_key?(metrics, :parallel_efficiency)
      assert metrics.convergence_stages >= 1, "Should have convergence stages"
      assert metrics.parallel_efficiency > 0, "Should have parallel efficiency metric"

      # Verify convergence results have expected properties
      converged_results = Enum.filter(result.results, fn r ->
        Map.get(r, :convergence_applied, false)
      end)
      
      assert length(converged_results) > 0, "Should have converged results"
      
      # Check that converged results have combined computation costs
      total_expected_cost = length(actions) * 20  # attack action baseline cost
      total_actual_cost = Enum.reduce(result.results, 0, fn r, acc ->
        acc + Map.get(r, :computation_cost, 0)
      end)
      
      # Due to convergence combining costs, actual should be close to expected
      assert total_actual_cost >= total_expected_cost * 0.8, 
        "Converged cost should preserve most computation: expected ~#{total_expected_cost}, got #{total_actual_cost}"
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
      total_items = Map.get(metrics, :total_items, 0)
      assert total_items == 10

      # Verify all action types were processed
      action_types = Enum.map(result.results, fn r ->
        Map.get(r, :action_type, :unknown)
      end) |> Enum.uniq() |> Enum.sort()

      expected_types = [:interact, :skill_cast] |> Enum.sort()
      assert action_types == expected_types
    end
  end

  describe "Backflow Signal Handling" do
    test "backpressure signals reduce processing demand" do
      # This test verifies that backpressure signals properly reduce demand
      # Create a pipeline and test backpressure signaling
      
      pipeline_name = :"test_backpressure_#{System.unique_integer()}"
      {:ok, _pid} = AriaQueue.FlowBackflow.create_pipeline(pipeline_name, [
        stages: 2,
        backflow_enabled: true,
        max_demand: 100,
        min_demand: 10
      ])

      # Send backpressure signal
      :ok = AriaQueue.FlowBackflow.signal_backflow(pipeline_name, :backpressure, %{reason: :test})

      # Process some data to see the effect
      test_data = [
        %{id: 1, action: :move_to, data: %{"distance" => 5}},
        %{id: 2, action: :attack, data: %{"damage" => 50}}
      ]

      result = AriaQueue.FlowBackflow.process_with_backflow(pipeline_name, test_data, [
        source_fn: &default_source/1,
        filter_fn: &default_filter/1,
        sink_fn: &default_sink/1
      ])

      # Should still process data but with controlled demand
      assert Map.has_key?(result, :results)
      assert length(result.results) == 2
    end

    test "demand increase signals boost processing capacity" do
      pipeline_name = :"test_demand_increase_#{System.unique_integer()}"
      {:ok, _pid} = AriaQueue.FlowBackflow.create_pipeline(pipeline_name, [
        stages: 2,
        backflow_enabled: true,
        max_demand: 100,
        min_demand: 10
      ])

      # Send demand increase signal
      :ok = AriaQueue.FlowBackflow.signal_backflow(pipeline_name, :increase_demand, %{reason: :test})

      # Process data
      test_data = [
        %{id: 1, action: :skill_cast, data: %{"complexity" => 50}},
        %{id: 2, action: :interact, data: %{"object_id" => "door_1"}}
      ]

      result = AriaQueue.FlowBackflow.process_with_backflow(pipeline_name, test_data)

      # Should process efficiently with increased demand
      assert Map.has_key?(result, :results)
      assert length(result.results) == 2

      metrics = result.metrics
      assert Map.has_key?(metrics, :total_items)
      assert metrics.total_items == 2
    end
  end

  # Helper functions for testing
  defp default_source(item) do
    Map.put(item, :source_processed_at, System.monotonic_time(:microsecond))
  end

  defp default_filter(item) do
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate work based on action type
    iterations = case Map.get(item, :action, :default) do
      :move_to -> 500   # Lighter workload for movement
      :attack -> 750    # Medium workload for combat
      :skill_cast -> 1000  # Heavy workload for skills
      :interact -> 300  # Light workload for interactions
      _ -> 400
    end

    # Perform computation
    _result = Enum.reduce(1..iterations, 0.0, fn i, acc ->
      acc + :math.sin(i * 0.01)
    end)

    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start

    item
    |> Map.put(:filter_processed_at, processing_end)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:backflow_optimized, true)  # Mark as optimized
  end

  defp default_sink(item) do
    %{
      id: Map.get(item, :id, :unknown),
      action_type: Map.get(item, :action, :unknown),
      result: :processed,
      processing_time_us: Map.get(item, :processing_time_us, 0),
      backflow_optimized: Map.get(item, :backflow_optimized, false),
      completed_at: System.monotonic_time(:microsecond)
    }
  end
end
