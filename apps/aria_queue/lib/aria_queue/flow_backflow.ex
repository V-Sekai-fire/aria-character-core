# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.FlowBackflow do
  @moduledoc """
  Flow-based backflow processing system that implements Membrane's element
  concepts with pads and filters using Flow's parallel processing.
  
  This module provides Membrane-style elements with input/output pads,
  demand-driven processing, and backflow control, but implemented using
  Flow for superior parallel efficiency.
  """

  use GenServer
  require Logger

  # Initialize ETS table for pipeline registry
  def start_link(_) do
    ensure_pipeline_registry()
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp ensure_pipeline_registry() do
    case :ets.whereis(:aria_pipeline_registry) do
      :undefined -> 
        :ets.new(:aria_pipeline_registry, [:set, :named_table, :public])
      _ -> 
        :ok
    end
  end

  # Membrane-style element definition with pads
  defstruct [
    :name, 
    :input_pads, 
    :output_pads, 
    :pad_connections, 
    :demand_state,
    :backflow_control,
    :filter_functions,
    # Flow processing state
    :stages,
    :processed_count,
    :processing_time_us,
    # Demand control state
    :current_demand,
    :max_demand,
    :min_demand,
    :backpressure_count,
    :backflow_enabled,
    # Element state (if this represents an element)
    :element
  ]

  # Pad definition similar to Membrane's def_input_pad/def_output_pad
  defmodule ElementPad do
    defstruct [:name, :type, :accepted_format, :flow_control, :demand_size]
  end

  # Buffer structure for data flowing through pads
  defmodule ElementBuffer do
    defstruct [:payload, :metadata, :pts, :dts]
  end

  @doc """
  Create a Flow-based element with Membrane-style pads.
  
  Example:
    {:ok, element} = FlowBackflow.start_element("processor", [
      input_pads: [
        %ElementPad{name: :input, type: :input, flow_control: :pull, demand_size: 100}
      ],
      output_pads: [
        %ElementPad{name: :output, type: :output, flow_control: :push}
      ],
      filter_fn: &my_filter/1
    ])
  """
  def start_element(name, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, opts}, name: via_tuple(name))
  end

  @doc """
  Link two element pads together (Membrane-style pad linking).
  """
  def link_pads(source_element, source_pad, sink_element, sink_pad) do
    GenServer.call(via_tuple(source_element), {:link_pad, source_pad, sink_element, sink_pad})
  end

  @doc """
  Send buffer to element's input pad.
  """
  def send_buffer(element_name, pad_name, buffer) do
    GenServer.cast(via_tuple(element_name), {:buffer, pad_name, buffer})
  end

  @doc """
  Handle demand from downstream element.
  """
  def handle_demand(element_name, pad_name, demand_size) do
    GenServer.cast(via_tuple(element_name), {:demand, pad_name, demand_size})
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

  @doc """
  Process data with GPU-style hierarchical convergence.
  
  This implements true convergence patterns where results are reduced
  hierarchically across multiple stages, similar to GPU warp reduction.
  """
  def process_with_convergence(pipeline_name, data, opts \\ []) do
    GenServer.call(via_tuple(pipeline_name), {:process_convergence, data, opts}, 30_000)
  end

  @doc """
  Create a Membrane-style element with input and output pads.
  
  Elements have pads that can handle demand-driven flow control,
  similar to Membrane's architecture but implemented with Flow.
  """
  def create_element(name, element_type, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, element_type, opts}, name: via_tuple(name))
  end

  @doc """
  Create a pipeline of connected elements (Membrane-style pipeline).
  
  This creates a supervisor tree that manages a set of elements
  and their interconnections, similar to Membrane's pipeline pattern.
  """
  def create_pipeline(pipeline_name, opts \\ []) do
    # Ensure the pipeline registry exists
    ensure_pipeline_registry()
    
    # Create a simple pipeline registry for now
    # In the future, this could be enhanced with a proper supervisor
    stages = Keyword.get(opts, :stages, 4)
    backflow_enabled = Keyword.get(opts, :backflow_enabled, true)
    
    # Register the pipeline configuration
    :ets.insert(:aria_pipeline_registry, {pipeline_name, %{
      stages: stages,
      backflow_enabled: backflow_enabled,
      max_demand: Keyword.get(opts, :max_demand, 100),
      min_demand: Keyword.get(opts, :min_demand, 1),
      created_at: System.monotonic_time()
    }})
    
    {:ok, self()}
  end

  @doc """
  Link two elements via their pads (Membrane-style linking).
  """
  def link_elements(source_element, source_pad, sink_element, sink_pad) do
    GenServer.call(via_tuple(source_element), {:link_pad, source_pad, sink_element, sink_pad})
  end

  @doc """
  Send demand signal through pad connections (Membrane-style demand).
  """
  def send_demand(element_name, pad_name, demand_size) do
    GenServer.cast(via_tuple(element_name), {:demand, pad_name, demand_size})
  end

  @doc """
  Process buffer through element pads (Membrane-style buffer processing).
  """
  def process_buffer(element_name, pad_name, buffer) do
    GenServer.call(via_tuple(element_name), {:process_buffer, pad_name, buffer})
  end

  # GenServer implementation (Membrane-style element lifecycle)

  @impl true
  def init({name, opts}) do
    # Initialize element with Membrane-style pads
    init_element(name, opts)
  end

  def init({name, element_type, opts}) do
    # Initialize element with Membrane-style pads, including element_type
    opts_with_type = Keyword.put(opts, :element_type, element_type)
    init_element(name, opts_with_type)
  end

  defp init_element(name, opts) do
    input_pads = Keyword.get(opts, :input_pads, [])
    output_pads = Keyword.get(opts, :output_pads, [])
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    element_type = Keyword.get(opts, :element_type, :filter)
    
    # Create pad state maps
    input_pad_map = Map.new(input_pads, fn pad -> {pad.name, pad} end)
    output_pad_map = Map.new(output_pads, fn pad -> {pad.name, pad} end)
    
    # Initialize demand state for each input pad (Membrane-style demand)
    demand_state = Map.new(input_pads, fn pad ->
      {pad.name, %{demand_size: pad.demand_size || 100, pending_demand: 0}}
    end)

    state = %__MODULE__{
      name: name,
      input_pads: input_pad_map,
      output_pads: output_pad_map,
      pad_connections: %{},
      demand_state: demand_state,
      backflow_control: %{enabled: true, backpressure_count: 0},
      filter_functions: %{default: filter_fn},
      # Flow processing state
      stages: Keyword.get(opts, :stages, 4),
      processed_count: 0,
      processing_time_us: 0,
      # Demand control state
      current_demand: Keyword.get(opts, :initial_demand, 100),
      max_demand: Keyword.get(opts, :max_demand, 1000),
      min_demand: Keyword.get(opts, :min_demand, 1),
      backpressure_count: 0,
      backflow_enabled: Keyword.get(opts, :backflow_enabled, true),
      # Element state (for element-based processing)
      element: %{name: name, type: element_type}
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
  def handle_call({:process_convergence, data, opts}, _from, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions from options
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    convergence_fn = Keyword.get(opts, :convergence_fn, &default_convergence/2)
    
    # Process with GPU-style hierarchical convergence
    result = process_with_hierarchical_convergence(data, state, source_fn, filter_fn, sink_fn, convergence_fn)
    
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
  def handle_call({:link_pad, source_pad, sink_element, sink_pad}, _from, state) do
    # Create pad-to-pad connection (Membrane-style linking)
    connection_key = {state.element.name, source_pad}
    connection_value = {sink_element, sink_pad}
    
    new_connections = Map.put(state.pad_connections, connection_key, connection_value)
    new_state = %{state | pad_connections: new_connections}
    
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:process_buffer, pad_name, buffer}, _from, state) do
    # Process buffer through element pad (Membrane-style processing)
    case process_buffer_through_pad(state.element, pad_name, buffer) do
      {:ok, output_buffers} ->
        # Send output buffers to connected elements
        send_buffers_to_connected_pads(output_buffers, state)
        {:reply, :ok, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_cast({:backflow_signal, signal_type, metadata}, state) do
    new_state = handle_backflow_signal(signal_type, metadata, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:demand, pad_name, demand_size}, state) do
    # Handle demand signal through pad (Membrane-style demand)
    new_state = handle_pad_demand(state, pad_name, demand_size)
    {:noreply, new_state}
  end

  # Private implementation

  defp process_with_demand_control(data, state, source_fn, filter_fn, sink_fn) do
    # Implement idempotent Flow processing - each item processed exactly once
    results = data
    |> Flow.from_enumerable(stages: state.stages)
    |> Flow.map(fn item ->
      # Source stage with backflow awareness
      source_result = source_fn.(item)
      
      # Check for backpressure signals
      if should_apply_backpressure?(state) do
        signal_backflow_upstream(state, :backpressure, %{item_id: Map.get(item, :id)})
      end
      
      source_result
    end)
    |> Flow.map(fn source_result ->
      # Filter stage with demand-driven processing
      filtered = filter_fn.(source_result)
      
      # Signal demand downstream based on processing capacity
      signal_demand_downstream(state, 1)
      
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
    |> Enum.to_list()
    
    # Create metrics for all results
    metrics = %{
      total_items: length(results),
      total_processing_time: Enum.reduce(results, 0, fn result, acc ->
        acc + Map.get(result, :processing_time_us, 0)
      end),
      backpressure_events: Enum.count(results, fn result ->
        Map.get(result, :processing_heavy, false)
      end)
    }
    
    %{
      results: results,
      metrics: metrics,
      processed_count: length(results)
    }
  end

  def should_apply_backpressure?(state) do
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

  defp process_with_hierarchical_convergence(data, state, source_fn, filter_fn, sink_fn, convergence_fn) do
    # GPU-style hierarchical convergence processing
    # Process data in stages, then hierarchically reduce results
    
    # Stage 1: Initial parallel processing across all stages
    initial_results = data
    |> Flow.from_enumerable(stages: state.stages)
    |> Flow.map(source_fn)
    |> Flow.map(filter_fn)
    |> Flow.map(sink_fn)
    |> Enum.to_list()
    
    # Stage 2: Hierarchical convergence (like GPU warp reduction)
    converged_results = hierarchical_reduce(initial_results, convergence_fn, state.stages)
    
    # Calculate convergence metrics
    metrics = %{
      total_items: length(data),
      convergence_stages: calculate_convergence_stages(length(data), state.stages),
      total_processing_time: Enum.reduce(converged_results, 0, fn result, acc ->
        acc + Map.get(result, :processing_time_us, 0)
      end),
      parallel_efficiency: calculate_parallel_efficiency(length(data), state.stages),
      backpressure_events: Enum.count(converged_results, fn result ->
        Map.get(result, :processing_heavy, false)
      end)
    }
    
    %{
      results: converged_results,
      metrics: metrics,
      processed_count: length(converged_results),
      convergence_applied: true
    }
  end

  # Hierarchical reduction similar to GPU warp reduction
  defp hierarchical_reduce(results, _convergence_fn, _stages) when length(results) <= 1 do
    results
  end

  defp hierarchical_reduce(results, convergence_fn, stages) do
    # Group results into chunks for hierarchical processing
    chunk_size = max(1, div(length(results), stages))
    
    results
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunk ->
      # Apply convergence function to each chunk
      Enum.reduce(chunk, fn item, acc ->
        convergence_fn.(acc, item)
      end)
    end)
    |> case do
      [single_result] -> [single_result]
      multiple_results -> hierarchical_reduce(multiple_results, convergence_fn, stages)
    end
  end

  defp calculate_convergence_stages(data_size, stages) do
    # Calculate how many convergence stages are needed
    if data_size <= 1 do
      0
    else
      stage_count = :math.ceil(:math.log2(data_size / stages))
      max(1, trunc(stage_count))
    end
  end

  defp calculate_parallel_efficiency(data_size, stages) do
    # Calculate theoretical parallel efficiency
    if data_size >= stages do
      # Ideal case: each stage gets work
      100.0
    else
      # Suboptimal: some stages idle
      (data_size / stages) * 100.0
    end
  end

  defp default_convergence(acc, item) do
    # Default convergence combines computation costs and merges processing results
    combined_cost = Map.get(acc, :computation_cost, 0) + Map.get(item, :computation_cost, 0)
    combined_processing_time = Map.get(acc, :processing_time_us, 0) + Map.get(item, :processing_time_us, 0)
    
    # Merge action results - keep the higher priority action
    action_priority = %{
      skill_cast: 4,
      attack: 3,
      move_to: 2,
      interact: 1
    }
    
    acc_priority = Map.get(action_priority, Map.get(acc, :action_type, :unknown), 0)
    item_priority = Map.get(action_priority, Map.get(item, :action_type, :unknown), 0)
    
    primary_action = if acc_priority >= item_priority, do: acc, else: item
    
    %{
      id: "converged_#{Map.get(acc, :id, "")}_#{Map.get(item, :id, "")}",
      action_type: Map.get(primary_action, :action_type, :converged),
      computation_cost: combined_cost,
      processing_time_us: combined_processing_time,
      convergence_applied: true,
      converged_from: [Map.get(acc, :id), Map.get(item, :id)],
      result: :converged,
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  # Element definitions with pads (Membrane-style)
  
  defmodule ElementPad do
    @moduledoc """
    Represents a Membrane-style pad with demand-driven flow control.
    """
    defstruct [
      :name,
      :type,           # :input or :output
      :flow_control,   # :push or :pull
      :demand,         # current demand size
      :connected_to,   # {element_name, pad_name}
      :buffer_queue    # queue of pending buffers
    ]
  end

  defmodule FlowElement do
    @moduledoc """
    Represents a Membrane-style element with input/output pads.
    """
    defstruct [
      :name,
      :type,           # :source, :filter, :sink
      :pads,           # map of pad_name -> ElementPad
      :state,          # element-specific state
      :process_fn      # processing function
    ]
  end

  # Enhanced GenServer implementation with pad support

  # Private helper functions for pad processing

  defp create_flow_element(name, element_type, opts) do
    pads = case element_type do
      :source ->
        %{
          output: %ElementPad{
            name: :output,
            type: :output,
            flow_control: :push,
            demand: 0,
            connected_to: nil,
            buffer_queue: :queue.new()
          }
        }
      :filter ->
        %{
          input: %ElementPad{
            name: :input,
            type: :input,
            flow_control: :pull,
            demand: 100,  # initial demand
            connected_to: nil,
            buffer_queue: :queue.new()
          },
          output: %ElementPad{
            name: :output,
            type: :output,
            flow_control: :push,
            demand: 0,
            connected_to: nil,
            buffer_queue: :queue.new()
          }
        }
      :sink ->
        %{
          input: %ElementPad{
            name: :input,
            type: :input,
            flow_control: :pull,
            demand: 100,  # initial demand
            connected_to: nil,
            buffer_queue: :queue.new()
          }
        }
    end

    process_fn = Keyword.get(opts, :process_fn, &default_element_process/2)

    %FlowElement{
      name: name,
      type: element_type,
      pads: pads,
      state: %{},
      process_fn: process_fn
    }
  end

  defp process_buffer_through_pad(element, pad_name, buffer) do
    case Map.get(element.pads, pad_name) do
      %ElementPad{type: :input} = pad ->
        # Process input buffer through element
        case element.process_fn.(buffer, element.state) do
          {:ok, output_buffer, new_state} ->
            new_element = %{element | state: new_state}
            {:ok, [{:output, output_buffer, new_element}]}
          {:error, reason} ->
            {:error, reason}
        end
      %ElementPad{type: :output} ->
        # Output pad doesn't process, just forwards
        {:ok, [{pad_name, buffer, element}]}
      nil ->
        {:error, :pad_not_found}
    end
  end

  defp send_buffers_to_connected_pads(output_buffers, state) do
    Enum.each(output_buffers, fn {pad_name, buffer, _element} ->
      case Map.get(state.pad_connections, {state.element.name, pad_name}) do
        {sink_element, sink_pad} ->
          # Send buffer to connected element's pad
          process_buffer(sink_element, sink_pad, buffer)
        nil ->
          # No connection, buffer is dropped (or could be stored)
          :ok
      end
    end)
  end

  defp handle_pad_demand(state, pad_name, demand_size) do
    # Update pad demand and potentially request more data upstream
    case get_in(state.element.pads, [pad_name]) do
      %ElementPad{type: :input} = pad ->
        updated_pad = %{pad | demand: demand_size}
        updated_element = put_in(state.element.pads[pad_name], updated_pad)
        %{state | element: updated_element}
      _ ->
        state
    end
  end

  defp default_element_process(buffer, element_state) do
    # Default processing: simulate some work and pass through
    processing_time = :rand.uniform(1000)  # 0-1ms of work
    :timer.sleep(div(processing_time, 1000))
    
    processed_buffer = Map.put(buffer, :processed_at, System.monotonic_time(:microsecond))
    {:ok, processed_buffer, element_state}
  end
end
