# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.FlowBackflow do
  @moduledoc """
  Flow-based backflow processing system that implements Membrane's demand-driven
  concepts but with Flow's superior parallel efficiency.
  
  Backflow allows downstream processors to signal their processing capacity
  and demand upstream, preventing oversubscription and enabling GPU-style
  convergence patterns.
  """

  use GenServer
  require Logger

  defstruct [:name, :source_stage, :filter_stage, :sink_stage, :backflow_control]

  @doc """
  Create a Flow pipeline with backflow control.
  
  The backflow system allows downstream stages to signal processing capacity
  and demand upstream, similar to Membrane's demand-driven processing but
  using Flow's efficient parallel processing.
  """
  def create_pipeline(name, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, opts}, name: via_tuple(name))
  end

  @doc """
  Process data through the backflow pipeline with demand signaling.
  """
  def process_with_backflow(pipeline_name, data, opts \\ []) do
    GenServer.call(via_tuple(pipeline_name), {:process_backflow, data, opts}, 30_000)
  end

  @doc """
  Signal backpressure or demand to the pipeline.
  """
  def signal_backflow(pipeline_name, signal_type, metadata \\ %{}) do
    GenServer.cast(via_tuple(pipeline_name), {:backflow_signal, signal_type, metadata})
  end

  # GenServer implementation

  @impl true
  def init({name, opts}) do
    stages = Keyword.get(opts, :stages, System.schedulers_online())
    max_demand = Keyword.get(opts, :max_demand, 1000)
    min_demand = Keyword.get(opts, :min_demand, 100)

    state = %{
      name: name,
      stages: stages,
      max_demand: max_demand,
      min_demand: min_demand,
      current_demand: max_demand,
      backpressure_count: 0,
      processed_count: 0,
      processing_time_us: 0,
      backflow_enabled: Keyword.get(opts, :backflow_enabled, true)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:process_backflow, data, opts}, _from, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions from options
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    
    # Process with backflow-controlled Flow pipeline
    result = process_with_demand_control(data, state, source_fn, filter_fn, sink_fn)
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    new_state = %{
      state |
      processed_count: state.processed_count + length(data),
      processing_time_us: state.processing_time_us + processing_time
    }
    
    {:reply, result, new_state}
  end

  @impl true
  def handle_cast({:backflow_signal, signal_type, metadata}, state) do
    new_state = handle_backflow_signal(signal_type, metadata, state)
    {:noreply, new_state}
  end

  # Private implementation

  defp process_with_demand_control(data, state, source_fn, filter_fn, sink_fn) do
    # Implement GPU convergence-style processing with backflow
    chunk_size = calculate_chunk_size(state.current_demand, length(data))
    
    data
    |> Enum.chunk_every(chunk_size)
    |> Flow.from_enumerable(stages: state.stages)
    |> Flow.map(fn chunk ->
      # Source stage with backflow awareness
      source_result = Enum.map(chunk, source_fn)
      
      # Check for backpressure signals
      if should_apply_backpressure?(state) do
        signal_backflow_upstream(state, :backpressure, %{chunk_size: length(chunk)})
      end
      
      source_result
    end)
    |> Flow.flat_map(fn source_results ->
      # Filter stage with demand-driven processing
      filtered = Enum.map(source_results, filter_fn)
      
      # Signal demand downstream based on processing capacity
      signal_demand_downstream(state, length(filtered))
      
      filtered
    end)
    |> Flow.map(fn filtered_item ->
      # Sink stage with convergence feedback
      result = sink_fn.(filtered_item)
      
      # Provide backflow feedback based on processing results
      if Map.get(result, :processing_heavy, false) do
        signal_backflow_upstream(state, :slow_processing, %{item: filtered_item})
      end
      
      result
    end)
    |> Flow.partition()
    |> Flow.reduce(fn -> %{results: [], metrics: %{}} end, fn item, acc ->
      %{
        results: [item | acc.results],
        metrics: update_processing_metrics(acc.metrics, item)
      }
    end)
    |> Enum.to_list()
    |> aggregate_results()
  end

  defp calculate_chunk_size(current_demand, data_length) do
    base_chunk = div(data_length, current_demand)
    max(1, min(base_chunk, 100))  # Keep chunks reasonable
  end

  defp should_apply_backpressure?(state) do
    state.backpressure_count > state.max_demand * 0.8
  end

  defp signal_backflow_upstream(state, signal_type, metadata) do
    if state.backflow_enabled do
      Logger.debug("Backflow signal: #{signal_type}, metadata: #{inspect(metadata)}")
    end
  end

  defp signal_demand_downstream(state, processed_count) do
    if state.backflow_enabled do
      demand_ratio = processed_count / state.max_demand
      Logger.debug("Demand signal: #{demand_ratio} (processed: #{processed_count})")
    end
  end

  defp update_processing_metrics(metrics, item) do
    processing_time = Map.get(item, :processing_time_us, 1000)
    
    %{
      total_items: Map.get(metrics, :total_items, 0) + 1,
      total_processing_time: Map.get(metrics, :total_processing_time, 0) + processing_time,
      backpressure_events: Map.get(metrics, :backpressure_events, 0) + if(Map.get(item, :backpressure_detected, false), do: 1, else: 0)
    }
  end

  defp aggregate_results([]), do: %{results: [], metrics: %{}}
  defp aggregate_results(flow_results) do
    # Handle different formats that might come from Flow.reduce
    normalized_results = Enum.map(flow_results, fn
      %{results: results, metrics: metrics} -> %{results: results, metrics: metrics}
      {:metrics, metrics} -> %{results: [], metrics: metrics}
      other -> %{results: [other], metrics: %{}}
    end)
    
    all_results = Enum.flat_map(normalized_results, & &1.results)
    
    combined_metrics = Enum.reduce(normalized_results, %{}, fn flow_result, acc ->
      metrics = flow_result.metrics
      %{
        total_items: Map.get(acc, :total_items, 0) + Map.get(metrics, :total_items, 0),
        total_processing_time: Map.get(acc, :total_processing_time, 0) + Map.get(metrics, :total_processing_time, 0),
        backpressure_events: Map.get(acc, :backpressure_events, 0) + Map.get(metrics, :backpressure_events, 0)
      }
    end)
    
    %{
      results: Enum.reverse(all_results),
      metrics: combined_metrics,
      processed_count: length(all_results)
    }
  end

  defp handle_backflow_signal(:backpressure, _metadata, state) do
    # Reduce demand when backpressure is detected
    new_demand = max(state.min_demand, div(state.current_demand, 2))
    %{state | current_demand: new_demand, backpressure_count: state.backpressure_count + 1}
  end

  defp handle_backflow_signal(:increase_demand, _metadata, state) do
    # Increase demand when capacity is available
    new_demand = min(state.max_demand, state.current_demand * 2)
    %{state | current_demand: new_demand}
  end

  defp handle_backflow_signal(_signal_type, _metadata, state) do
    state
  end

  # Default processing functions

  defp default_source(item) do
    # Default source processing - pass through with timestamp
    Map.put(item, :source_processed_at, System.monotonic_time(:microsecond))
  end

  defp default_filter(item) do
    # Default filter processing - simulate some computational work
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate work based on item type
    iterations = case Map.get(item, :action, :default) do
      :move_to -> 1000
      :attack -> 1500  
      :skill_cast -> 2000
      _ -> 800
    end
    
    # Perform actual computation
    _result = Enum.reduce(1..iterations, 0.0, fn i, acc ->
      acc + :math.sin(i * 0.01) + :math.cos(i * 0.02)
    end)
    
    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start
    
    item
    |> Map.put(:filter_processed_at, processing_end)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:processing_heavy, processing_time > 5000)  # Mark as heavy if > 5ms
  end

  defp default_sink(item) do
    # Default sink processing - finalize and return
    %{
      id: Map.get(item, :id, :unknown),
      result: :processed,
      processing_time_us: Map.get(item, :processing_time_us, 0),
      backpressure_detected: Map.get(item, :processing_heavy, false),
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  defp via_tuple(name) do
    {:via, Registry, {AriaQueue.Registry, name}}
  end
end
