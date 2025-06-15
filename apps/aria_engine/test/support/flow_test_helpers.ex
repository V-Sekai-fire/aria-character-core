# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Test.FlowTestHelpers do
  @moduledoc """
  Test support modules for Flow-based processing tests.
  
  These modules provide reusable test functionality for Flow backflow,
  convergence, and parallel processing tests.
  """

  defmodule FlowBackflowTester do
    @moduledoc """
    Flow-based backflow testing that replaces Membrane functionality.
    
    Implements the same backflow optimization concepts but using our
    centralized Flow processor in AriaQueue.
    """

    def create_backflow_pipeline(name, opts \\ []) do
      AriaQueue.FlowBackflow.create_pipeline(name, opts)
    end

    def create_element(name, element_type, opts \\ []) do
      AriaQueue.FlowBackflow.create_element(name, element_type, opts)
    end

    def start_element(name, opts \\ []) do
      AriaQueue.FlowBackflow.start_element(name, opts)
    end

    def link_elements(source_element, source_pad, sink_element, sink_pad) do
      AriaQueue.FlowBackflow.link_elements(source_element, source_pad, sink_element, sink_pad)
    end

    def send_buffer(element_name, pad_name, buffer) do
      AriaQueue.FlowBackflow.send_buffer(element_name, pad_name, buffer)
    end

    def process_with_backflow_optimization(pipeline_name, actions, processing_opts \\ []) do
      # This is a helper function that combines multiple AriaQueue.FlowBackflow calls
      with {:ok, pipeline} <- create_backflow_pipeline(pipeline_name, processing_opts),
           {:ok, _source} <- create_element("#{pipeline_name}_source", :source, [data: actions]),
           {:ok, _processor} <- create_element("#{pipeline_name}_processor", :filter, processing_opts),
           {:ok, _sink} <- create_element("#{pipeline_name}_sink", :sink, []),
           :ok <- link_elements("#{pipeline_name}_source", :output, "#{pipeline_name}_processor", :input),
           :ok <- link_elements("#{pipeline_name}_processor", :output, "#{pipeline_name}_sink", :input) do
        # Start processing
        start_element("#{pipeline_name}_source")
        {:ok, pipeline}
      else
        error -> error
      end
    end
  end

  defmodule FlowConvergenceResultCollector do
    @moduledoc """
    Flow-based convergence collector that aggregates results hierarchically.
    
    This replaces the Membrane ConvergenceResultCollector with equivalent functionality
    using our Flow-based system.
    """
    
    def collect_convergence_results(flow_result, core_count) do
      results = Map.get(flow_result, :results, [])
      
      %{
        total_processed: length(results),
        core_count: core_count,
        convergence_efficiency: calculate_convergence_efficiency(results, core_count),
        hierarchical_structure: build_hierarchical_structure(results)
      }
    end

    defp calculate_convergence_efficiency(results, core_count) do
      if length(results) > 0 and core_count > 0 do
        length(results) / core_count
      else
        0.0
      end
    end

    defp build_hierarchical_structure(results) do
      results
      |> Enum.chunk_every(2)
      |> Enum.map(&merge_results/1)
    end

    defp merge_results([single]), do: single
    defp merge_results([left, right]) do
      %{
        combined: true,
        left: left,
        right: right,
        merged_value: Map.get(left, :value, 0) + Map.get(right, :value, 0)
      }
    end
  end

  defmodule FlowBackflowResultCollector do
    @moduledoc """
    Collects and aggregates results from Flow backflow processing.
    """
    
    def collect_results(pipeline_results, batch_size \\ 100) do
      results = 
        pipeline_results
        |> Enum.flat_map(&extract_results/1)
        |> Enum.chunk_every(batch_size)
        |> Enum.map(&process_batch/1)

      %{
        total_batches: length(results),
        batch_size: batch_size,
        results: results,
        summary: summarize_results(results)
      }
    end

    defp extract_results(result) when is_map(result) do
      Map.get(result, :items, [result])
    end
    defp extract_results(result), do: [result]

    defp process_batch(batch) do
      %{
        count: length(batch),
        processed_at: DateTime.utc_now(),
        items: batch
      }
    end

    defp summarize_results(results) do
      total_items = Enum.sum(Enum.map(results, & &1.count))
      
      %{
        total_items: total_items,
        batch_count: length(results),
        avg_batch_size: if(length(results) > 0, do: total_items / length(results), else: 0)
      }
    end
  end

  defmodule RandomMovementProcessor do
    @moduledoc """
    Processes random movement actions for testing parallel efficiency.
    """

    def process_movement(action) do
      # Simulate processing time
      :timer.sleep(1)
      
      %{
        original: action,
        processed_at: DateTime.utc_now(),
        result: %{
          x: Map.get(action, :x, 0) + :rand.uniform(10) - 5,
          y: Map.get(action, :y, 0) + :rand.uniform(10) - 5,
          velocity: :rand.uniform(100) / 10
        }
      }
    end

    def generate_movement_actions(count) do
      1..count
      |> Enum.map(fn i ->
        %{
          id: i,
          type: :movement,
          x: :rand.uniform(1000),
          y: :rand.uniform(1000),
          timestamp: DateTime.utc_now()
        }
      end)
    end
  end

  defmodule FPSCollector do
    @moduledoc """
    Collects frame processing statistics for performance testing.
    """

    def collect_fps_stats(start_time, end_time, processed_count) do
      duration_ms = DateTime.diff(end_time, start_time, :millisecond)
      
      %{
        start_time: start_time,
        end_time: end_time,
        duration_ms: duration_ms,
        processed_count: processed_count,
        fps: if(duration_ms > 0, do: processed_count * 1000 / duration_ms, else: 0),
        avg_processing_time_ms: if(processed_count > 0, do: duration_ms / processed_count, else: 0)
      }
    end

    def format_fps_report(stats) do
      """
      FPS Performance Report:
      - Duration: #{stats.duration_ms}ms
      - Processed: #{stats.processed_count} items
      - FPS: #{Float.round(stats.fps, 2)}
      - Avg Processing Time: #{Float.round(stats.avg_processing_time_ms, 2)}ms/item
      """
    end
  end
end
