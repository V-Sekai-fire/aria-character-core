# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.FlowPipeline do
  @moduledoc """
  High-performance Flow-based pipeline system implementing source, filter, sink pattern.
  
  Replaces Membrane's slow coordination with Flow's efficient parallel processing
  while maintaining the conceptual pipeline model. Uses GPU convergence concepts
  with backflow-based processing and work stealing.
  """

  @doc """
  Create a pipeline with source, filters, and sink operations.
  
  ## Pipeline Stages
  - **Source**: Generates or provides input data
  - **Filters**: Transform data through processing stages  
  - **Sink**: Consumes final output and produces results
  
  ## GPU Convergence Features
  - Backflow-based processing for demand-driven work
  - Work stealing across available cores
  - Convergence detection for completion
  """
  def create_pipeline(source, filters, sink, opts \\ []) do
    core_count = Keyword.get(opts, :stages, System.schedulers_online())
    
    %{
      source: source,
      filters: filters,
      sink: sink,
      stages: core_count,
      demand_driven: Keyword.get(opts, :demand_driven, true)
    }
  end

  @doc """
  Execute a pipeline with GPU convergence-style processing.
  
  Uses Flow's efficient parallel processing with work stealing and
  demand-driven backflow to achieve GPU-like convergence behavior.
  """
  def execute_pipeline(pipeline) do
    start_time = System.monotonic_time(:microsecond)
    
    # Source stage - generate initial work items
    initial_data = case pipeline.source do
      {:generator, count, generator_fn} -> 
        generate_work_items(count, generator_fn)
      {:data, items} -> 
        items
      source_fn when is_function(source_fn) -> 
        source_fn.()
    end

    # Pipeline processing with Flow
    results = initial_data
    |> Flow.from_enumerable(stages: pipeline.stages)
    |> apply_filters(pipeline.filters)
    |> apply_sink(pipeline.sink)
    |> Flow.partition()
    |> Flow.reduce(fn -> [] end, fn item, acc -> [item | acc] end)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.reverse()

    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time

    %{
      results: results,
      processed_count: length(results),
      processing_time_us: processing_time,
      processing_time_ms: processing_time / 1000,
      stages: pipeline.stages,
      throughput_items_per_sec: length(results) / (processing_time / 1_000_000)
    }
  end

  @doc """
  GPU convergence test with backflow processing and work stealing.
  
  Simulates GPU-style convergence where work is distributed across cores
  with demand-driven processing and automatic work stealing.
  """
  def gpu_convergence_test(work_count, core_count \\ System.schedulers_online()) do
    # Create convergence-style pipeline
    pipeline = create_pipeline(
      {:generator, work_count, &generate_convergence_work/1},
      [
        &convergence_filter_stage_1/1,
        &convergence_filter_stage_2/1,
        &convergence_filter_stage_3/1
      ],
      &convergence_sink/1,
      stages: core_count,
      demand_driven: true
    )

    execute_pipeline(pipeline)
  end

  # Private helper functions

  defp generate_work_items(count, generator_fn) do
    for i <- 1..count do
      generator_fn.(i)
    end
  end

  defp apply_filters(flow, filters) do
    Enum.reduce(filters, flow, fn filter, acc_flow ->
      Flow.map(acc_flow, filter)
    end)
  end

  defp apply_sink(flow, sink) do
    Flow.map(flow, sink)
  end

  # GPU Convergence simulation functions

  defp generate_convergence_work(id) do
    %{
      id: id,
      data: :rand.uniform(1000),
      x: :rand.uniform(100),
      y: :rand.uniform(100),
      convergence_state: :initial
    }
  end

  defp convergence_filter_stage_1(work_item) do
    # Simulate GPU-style parallel computation stage 1
    distance = :math.sqrt(work_item.x * work_item.x + work_item.y * work_item.y)
    
    %{work_item | 
      data: work_item.data + round(distance),
      convergence_state: :stage_1_complete
    }
  end

  defp convergence_filter_stage_2(work_item) do
    # Simulate GPU-style parallel computation stage 2
    normalized = work_item.data / 1000.0
    
    %{work_item | 
      data: round(normalized * 500),
      convergence_state: :stage_2_complete
    }
  end

  defp convergence_filter_stage_3(work_item) do
    # Simulate GPU-style parallel computation stage 3 (convergence)
    final_value = work_item.data * 2 + work_item.x + work_item.y
    
    %{work_item | 
      data: final_value,
      convergence_state: :converged
    }
  end

  defp convergence_sink(work_item) do
    # Final processing stage - simulate sink operation
    %{
      id: work_item.id,
      final_result: work_item.data,
      converged: work_item.convergence_state == :converged
    }
  end
end
