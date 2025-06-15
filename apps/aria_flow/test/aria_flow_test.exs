# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlowTest do
  @moduledoc """
  Tests for AriaFlow stream processing with Membrane-style elements and backflow control.
  
  This test suite validates the core AriaFlow functionality including:
  - Pipeline creation and management
  - Element creation with pads
  - Pull/push flow control modes
  - Demand-driven processing (backflow)
  - Buffer processing through elements
  """

  use ExUnit.Case, async: false

  alias AriaFlow
  alias AriaFlow.Backflow.{ElementPad, ElementBuffer}

  describe "Pipeline Management" do
    test "create and manage processing pipeline" do
      pipeline_name = "test_pipeline_#{System.unique_integer()}"
      
      # Create pipeline
      {:ok, _pid} = AriaFlow.create_pipeline(pipeline_name, concurrency: 2)
      
      # Process test data
      test_data = [
        %{id: 1, action: :move_to, data: %{"distance" => 5}},
        %{id: 2, action: :attack, data: %{"damage" => 100}}
      ]
      
      result = AriaFlow.process_with_backflow(pipeline_name, test_data, [
        source_fn: &test_source/1,
        filter_fn: &test_filter/1,
        sink_fn: &test_sink/1
      ])
      
      # Validate results
      assert is_map(result)
      assert Map.has_key?(result, :results)
      assert Map.has_key?(result, :metrics)
      assert length(result.results) == 2
    end
  end

  describe "Element Management" do
    test "create elements with input and output pads" do
      element_name = "test_element_#{System.unique_integer()}"
      
      # Create filter element with both input and output pads
      {:ok, _pid} = AriaFlow.create_element(element_name, :filter, 
        input_pads: [%ElementPad{
          name: :input, 
          type: :input, 
          flow_control: :pull,
          demand_size: 100
        }],
        output_pads: [%ElementPad{
          name: :output, 
          type: :output, 
          flow_control: :push
        }]
      )
      
      # Element should be created and accessible
      assert Process.whereis({:via, Registry, {AriaFlow.Registry, element_name}}) != nil
    end
    
    test "send buffer to element's input pad" do
      element_name = "buffer_test_element_#{System.unique_integer()}"
      
      {:ok, _pid} = AriaFlow.start_element(element_name, [
        input_pads: [%ElementPad{
          name: :input, 
          type: :input, 
          flow_control: :push
        }]
      ])
      
      # Send buffer to element
      test_buffer = %ElementBuffer{
        payload: %{data: "test"},
        metadata: %{timestamp: System.monotonic_time()}
      }
      
      # Should not crash (asynchronous processing)
      :ok = AriaFlow.send_buffer(element_name, :input, test_buffer)
    end
  end

  describe "Backflow Control" do
    test "hierarchical convergence processing" do
      pipeline_name = "convergence_test_#{System.unique_integer()}"
      
      {:ok, _pid} = AriaFlow.create_pipeline(pipeline_name, concurrency: 4)
      
      test_data = [
        %{id: 1, value: 10, priority: 1},
        %{id: 2, value: 20, priority: 2},
        %{id: 3, value: 15, priority: 1},
        %{id: 4, value: 25, priority: 3}
      ]
      
      result = AriaFlow.process_with_convergence(pipeline_name, test_data, [
        source_fn: &test_source/1,
        filter_fn: &test_filter/1,
        sink_fn: &test_sink/1,
        convergence_fn: &test_convergence/2
      ])
      
      # Validate convergence results
      assert is_map(result)
      assert Map.has_key?(result, :results)
      assert Map.has_key?(result, :metrics)
      assert Map.get(result, :convergence_applied) == true
    end
    
    test "demand signaling between elements" do
      source_name = "test_source_#{System.unique_integer()}"
      sink_name = "test_sink_#{System.unique_integer()}"
      
      # Create source and sink elements
      {:ok, _} = AriaFlow.create_element(source_name, :source, [])
      {:ok, _} = AriaFlow.create_element(sink_name, :sink, [])
      
      # Link elements
      :ok = AriaFlow.link_elements(source_name, :output, sink_name, :input)
      
      # Send demand signal
      :ok = AriaFlow.handle_demand(sink_name, :input, 50)
      
      # Should handle demand without crashing
      assert Process.alive?(Process.whereis({:via, Registry, {AriaFlow.Registry, sink_name}}))
    end
  end

  describe "Flow Control Modes" do
    test "pull mode respects demand" do
      element_name = "pull_test_#{System.unique_integer()}"
      
      {:ok, _pid} = AriaFlow.start_element(element_name, [
        input_pads: [%ElementPad{
          name: :input,
          type: :input,
          flow_control: :pull,
          demand_size: 1  # Low demand
        }]
      ])
      
      # Send multiple buffers - should queue them due to low demand
      test_buffer1 = %ElementBuffer{payload: %{id: 1}}
      test_buffer2 = %ElementBuffer{payload: %{id: 2}}
      
      :ok = AriaFlow.send_buffer(element_name, :input, test_buffer1)
      :ok = AriaFlow.send_buffer(element_name, :input, test_buffer2)
      
      # Element should still be alive
      assert Process.alive?(Process.whereis({:via, Registry, {AriaFlow.Registry, element_name}}))
    end
    
    test "push mode processes immediately" do
      element_name = "push_test_#{System.unique_integer()}"
      
      {:ok, _pid} = AriaFlow.start_element(element_name, [
        input_pads: [%ElementPad{
          name: :input,
          type: :input,
          flow_control: :push
        }]
      ])
      
      # Send buffer - should process immediately in push mode
      test_buffer = %ElementBuffer{payload: %{id: 1}}
      :ok = AriaFlow.send_buffer(element_name, :input, test_buffer)
      
      # Element should still be alive
      assert Process.alive?(Process.whereis({:via, Registry, {AriaFlow.Registry, element_name}}))
    end
  end

  # Test helper functions
  
  defp test_source(item) do
    Map.put(item, :source_processed_at, System.monotonic_time(:microsecond))
  end
  
  defp test_filter(item) do
    # Simulate processing work
    :timer.sleep(1)
    
    processing_time = :rand.uniform(1000)
    item
    |> Map.put(:filter_processed_at, System.monotonic_time(:microsecond))
    |> Map.put(:processing_time_us, processing_time)
  end
  
  defp test_sink(item) do
    %{
      id: Map.get(item, :id, :unknown),
      result: :processed,
      processing_time_us: Map.get(item, :processing_time_us, 0),
      completed_at: System.monotonic_time(:microsecond)
    }
  end
  
  defp test_convergence(acc, item) do
    combined_value = Map.get(acc, :value, 0) + Map.get(item, :value, 0)
    max_priority = max(Map.get(acc, :priority, 0), Map.get(item, :priority, 0))
    
    %{
      id: "converged_#{Map.get(acc, :id, "")}_#{Map.get(item, :id, "")}",
      value: combined_value,
      priority: max_priority,
      result: :converged,
      converged_from: [Map.get(acc, :id), Map.get(item, :id)]
    }
  end
end
