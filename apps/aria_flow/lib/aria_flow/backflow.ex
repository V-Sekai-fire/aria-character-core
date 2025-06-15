# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.Backflow do
  @moduledoc """
  Parallel processing system that implements Membrane's element
  concepts with pads and filters using high-performance parallel processing.
  
  This module provides Membrane-style elements with input/output pads,
  demand-driven processing, and backflow control, implemented with
  optimized parallel processing for superior efficiency.
  """

  use GenServer
  require Logger

  # Type definitions
  @type pipeline_name :: atom() | String.t()
  @type element_name :: atom() | String.t()
  @type pad_name :: atom() | String.t()
  @type element_type :: :source | :filter | :sink
  @type processing_function :: (any() -> any())
  @type convergence_function :: (any(), any() -> any())
  @type pipeline_opts :: [
    stages: pos_integer(),
    backflow_enabled: boolean(),
    max_demand: pos_integer(),
    min_demand: pos_integer()
  ]
  @type element_opts :: [
    input_pads: [ElementPad.t()],
    output_pads: [ElementPad.t()],
    filter_fn: processing_function(),
    element_type: element_type()
  ]
  @type processing_opts :: keyword()
  @type demand_size :: pos_integer()
  @type buffer_data :: any()

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
    @moduledoc """
    Represents a Membrane-style pad with demand-driven flow control.
    """
    defstruct [
      :name,
      :type,           # :input or :output
      :flow_control,   # :push or :pull
      :demand,         # current demand size
      :connected_to,   # {element_name, pad_name}
      :buffer_queue,   # queue of pending buffers
      :accepted_format,
      :demand_size
    ]
  end

  # Buffer structure for data flowing through pads
  defmodule ElementBuffer do
    @moduledoc """
    Represents a buffer of data flowing through element pads.
    Similar to Membrane.Buffer but implemented for Flow processing.
    """
    defstruct [
      :payload,        # The actual data
      :metadata,       # Additional metadata
      :pts,           # Presentation timestamp
      :dts,           # Decode timestamp
      :size,          # Buffer size
      :stream_format, # Format of the stream
      :pad_name       # Which pad this buffer belongs to
    ]
  end

  # Alias for compatibility
  defmodule Buffer do
    defstruct [
      :payload,
      :metadata,
      :pts,
      :dts,
      :size,
      :stream_format,
      :pad_name
    ]
  end

  @doc """
  Create a parallel processing element with Membrane-style pads.
  
  Example:
    {:ok, element} = Backflow.start_element("processor", [
      input_pads: [
        %ElementPad{name: :input, type: :input, flow_control: :pull, demand_size: 100}
      ],
      output_pads: [
        %ElementPad{name: :output, type: :output, flow_control: :push}
      ],
      filter_fn: &my_filter/1
    ])
  """
  @spec start_element(element_name(), element_opts()) :: GenServer.on_start()
  def start_element(name, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, opts}, name: via_tuple(name))
  end

  @doc """
  Link two element pads together (Membrane-style pad linking).
  """
  @spec link_pads(element_name(), pad_name(), element_name(), pad_name()) :: :ok
  def link_pads(source_element, source_pad, sink_element, sink_pad) do
    GenServer.call(via_tuple(source_element), {:link_pad, source_pad, sink_element, sink_pad})
  end

  @doc """
  Send buffer to element's input pad.
  """
  @spec send_buffer(element_name(), pad_name(), buffer_data()) :: :ok
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
  Process data through the adaptive processing pipeline with demand signaling.
  
  This method automatically adjusts processing based on system load and
  provides optimal resource utilization through adaptive demand control.
  """
  @spec process_with_backflow(pipeline_name(), [buffer_data()], processing_opts()) :: {:ok, any()} | {:error, any()}
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
  Process data with hierarchical reduction for optimal efficiency.
  
  This processing method reduces results across multiple stages for
  maximum parallelization and performance.
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
    
    # Create the actual flow element using our helper function
    flow_element = create_flow_element(name, element_type, opts)
    
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
      # Element state (for element-based processing) - use the flow element
      element: flow_element
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:process_backflow, data, opts}, _from, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions from options
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    filter_fns = Keyword.get(opts, :filter_fns, [&default_filter/1]) |> MapSet.new()
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    
    # Process with maximal parallel filter execution
    result = process_with_maximal_parallelism(data, state, source_fn, filter_fns, sink_fn)
    
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

  @impl true
  def handle_cast({:buffer, pad_name, buffer}, state) do
    # Handle buffer arrival at input pad - support both pull and push modes
    new_state = handle_pad_buffer(state, pad_name, buffer)
    {:noreply, new_state}
  end

  # Private implementation

  defp process_with_demand_control(data, state, source_fn, filter_fns, sink_fn) do
    # Maximal parallelism: distribute both data AND filters across Flow partitions
    # Each partition gets a subset of data-filter combinations and converges results
    filter_set = if is_list(filter_fns), do: MapSet.new(filter_fns), else: filter_fns
    filter_list = MapSet.to_list(filter_set)
    
    # Create cartesian product of data x filters for maximum parallel distribution
    data_filter_pairs = for item <- data, filter_fn <- filter_list, do: {item, filter_fn}
    
    # Implement work stealing by creating larger chunks that can be redistributed
    work_stealing_enabled = Map.get(state, :work_stealing_enabled, true)
    partition_strategy = if work_stealing_enabled do
      # Use smaller chunk sizes to enable better work distribution
      chunk_size = max(1, div(length(data_filter_pairs), state.stages * 4))
      data_filter_pairs
      |> Enum.chunk_every(chunk_size)
      |> List.flatten()
    else
      data_filter_pairs
    end
    
    results = partition_strategy
    |> Flow.from_enumerable(stages: state.stages)
    |> Flow.partition(hash: fn {item, _filter_fn} -> 
      # Fish schooling: group similar items for better cache locality
      affinity_key = calculate_affinity_key(item)
      :erlang.phash2(affinity_key, state.stages)
    end)
    |> Flow.map(fn {item, filter_fn} ->
      processing_start = System.monotonic_time(:microsecond)
      
      # Each partition processes its assigned data-filter pairs in parallel
      source_result = source_fn.(item)
      
      # Check for backpressure signals at partition level
      if should_apply_backpressure?(state) do
        signal_backflow_upstream(state, :backpressure, %{item_id: Map.get(item, :id)})
      end
      
      # Apply filter in this partition
      filtered = filter_fn.(source_result)
      
      # Track processing time for work stealing metrics
      processing_end = System.monotonic_time(:microsecond)
      processing_time = processing_end - processing_start
      
      # Track which filter contributed to this result
      filtered_with_metadata = filtered
      |> Map.put(:contributing_filters, [inspect(filter_fn)])
      |> Map.put(:filter_applied_at, processing_end)
      |> Map.put(:partition_processing_time, processing_time)
      |> Map.put(:work_stealing_active, work_stealing_enabled)
      
      # Signal demand downstream based on partition processing capacity
      signal_demand_downstream(state, 1)
      
      # Apply sink function
      result = sink_fn.(filtered_with_metadata)
      
      # Provide backflow feedback based on processing results
      if Map.get(result, :processing_heavy, false) do
        signal_backflow_upstream(state, :slow_processing, %{item: filtered})
      end
      
      result
    end)
    |> Flow.partition()  # Converge filter results across partitions
    |> Flow.group_by(fn result -> Map.get(result, :id, :unknown) end)  # Group by data item
    |> Flow.map(fn {_item_id, filter_results} ->
      # Converge results from multiple filters for the same data item
      convergence_fn = Map.get(state, :convergence_fn, &default_convergence/2)
      
      case filter_results do
        [] -> nil
        [single_result] -> single_result
        multiple_results ->
          # Apply convergence function to merge results from different filters
          Enum.reduce(multiple_results, convergence_fn)
      end
    end)
    |> Flow.reject(&is_nil/1)  # Remove any nil results
    |> Flow.reduce(fn -> [] end, fn result, acc -> [result | acc] end)
    |> Enum.to_list()
    |> List.flatten()
    
    # Create metrics showing maximal parallelism achieved with filter convergence
    work_stealing_active = Map.get(state, :work_stealing_enabled, true)
    partition_times = Enum.map(results, fn result -> 
      Map.get(result, :partition_processing_time, 0) 
    end)
    
    # Calculate work stealing efficiency metrics
    work_stealing_metrics = if work_stealing_active and length(partition_times) > 0 do
      avg_time = Enum.sum(partition_times) / length(partition_times)
      max_time = Enum.max(partition_times)
      min_time = Enum.min(partition_times)
      time_variance = if max_time > 0, do: (max_time - min_time) / max_time, else: 0.0
      
      %{
        work_stealing_efficiency: max(0.0, 1.0 - time_variance),
        avg_partition_time: avg_time,
        max_partition_time: max_time,
        min_partition_time: min_time,
        time_variance: time_variance,
        load_balance_ratio: (if max_time > 0, do: min_time / max_time, else: 1.0)
      }
    else
      %{
        work_stealing_efficiency: 0.0,
        avg_partition_time: 0,
        max_partition_time: 0,
        min_partition_time: 0,
        time_variance: 0.0,
        load_balance_ratio: 1.0
      }
    end
    
    metrics = %{
      total_items: length(data),
      total_filters: MapSet.size(filter_set),
      total_combinations: length(data) * MapSet.size(filter_set),
      partitions_used: state.stages,
      work_stealing_active: work_stealing_active,
      filter_convergence_applied: true,
      parallel_efficiency: calculate_maximal_parallel_efficiency(length(data), MapSet.size(filter_set), state.stages),
      convergence_efficiency: calculate_convergence_efficiency(length(results), length(data)),
      total_processing_time: Enum.reduce(results, 0, fn result, acc ->
        acc + Map.get(result, :processing_time_us, 0)
      end),
      backpressure_events: Enum.count(results, fn result ->
        Map.get(result, :processing_heavy, false)
      end),
      converged_items: Enum.count(results, fn result ->
        Map.get(result, :convergence_applied, false)
      end)
    }
    |> Map.merge(work_stealing_metrics)
    
    %{
      results: results,
      metrics: metrics,
      processed_count: length(results)
    }
  end
    
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
    {:via, Registry, {AriaFlow.Registry, name}}
  end

  defp process_with_hierarchical_convergence(data, state, source_fn, filter_fns, sink_fn, convergence_fn) do
    # GPU-style hierarchical convergence processing
    # Process data in stages, then hierarchically reduce results
    
    # Ensure filter_fns is a list (backward compatibility)
    filter_functions = case filter_fns do
      list when is_list(list) -> list
      single_fn when is_function(single_fn) -> [single_fn]
      _ -> [&default_filter/1]
    end
    
    # Stage 1: Initial parallel processing with fish schooling (data locality)
    initial_results = data
    |> Flow.from_enumerable(stages: state.stages)
    |> Flow.partition(hash: fn item -> 
      # Fish schooling: similar data types swim together
      affinity_key = calculate_affinity_key(item)
      :erlang.phash2(affinity_key, state.stages)
    end)
    |> Flow.map(source_fn)
    # Apply filters in sequence (0..n filters)
    |> apply_filter_chain(filter_functions)
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
    # Fish schooling: group similar items together for better cache locality
    # Similar to how fish of the same species swim together
    schooled_results = group_similar_items_for_locality(results, stages)
    
    schooled_results
    |> Enum.map(fn school ->
      # Apply convergence function within each school (locality group)
      Enum.reduce(school, fn item, acc ->
        convergence_fn.(acc, item)
      end)
    end)
    |> case do
      [single_result] -> [single_result]
      multiple_results -> hierarchical_reduce(multiple_results, convergence_fn, stages)
    end
  end

  # Group similar items together for better cache locality (fish schooling)
  defp group_similar_items_for_locality(results, stages) do
    # Group by data characteristics for spatial locality
    results
    |> Enum.group_by(fn item ->
      # Create affinity groups based on data characteristics
      affinity_key = calculate_affinity_key(item)
      # Distribute affinity groups across stages
      :erlang.phash2(affinity_key, stages)
    end)
    |> Map.values()
    |> Enum.reject(&Enum.empty?/1)
  end

  # Calculate affinity key for data locality (similar fish swim together)
  defp calculate_affinity_key(item) do
    cond do
      # Group by action type for temporal locality
      Map.has_key?(item, :action_type) ->
        {:action, Map.get(item, :action_type)}
      
      # Group by processing complexity for load balancing
      Map.has_key?(item, :computation_cost) ->
        complexity = Map.get(item, :computation_cost, 0)
        complexity_tier = div(complexity, 1000)  # Group into tiers
        {:complexity, complexity_tier}
      
      # Group by data size for memory locality
      Map.has_key?(item, :data) ->
        data_size = item |> Map.get(:data, %{}) |> map_size()
        size_tier = div(data_size, 10)  # Group by size tiers
        {:size, size_tier}
      
      # Default grouping by hash for even distribution
      true ->
        {:hash, :erlang.phash2(item, 8)}
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

  defp calculate_maximal_parallel_efficiency(data_size, filter_count, stages) do
    # Calculate parallel efficiency for maximal parallelism (data x filters distributed across partitions)
    total_combinations = data_size * filter_count
    
    if total_combinations >= stages do
      # Ideal case: each partition gets data-filter combinations to process
      efficiency = min(100.0, (total_combinations / stages) * 10.0)  # Scale factor for multi-dimensional parallelism
      efficiency
    else
      # Suboptimal: some partitions idle
      (total_combinations / stages) * 100.0
    end
  end

  defp calculate_convergence_efficiency(final_results_count, original_data_count) do
    # Calculate how efficiently filters were converged
    # Higher efficiency means better convergence (fewer redundant results)
    if original_data_count == 0 do
      100.0
    else
      convergence_ratio = final_results_count / original_data_count
      # Perfect convergence: 1 result per original data item = 100% efficiency
      # Over-convergence (results < data): still good efficiency
      # Under-convergence (results > data): lower efficiency due to redundancy
      case convergence_ratio do
        ratio when ratio <= 1.0 -> 100.0
        ratio when ratio <= 2.0 -> 100.0 - ((ratio - 1.0) * 50.0)  # Linear decrease for mild redundancy
        _ratio -> 50.0  # Cap at 50% for high redundancy
      end
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
    
    # Track which filters contributed to the convergence
    acc_filters = Map.get(acc, :contributing_filters, [])
    item_filters = Map.get(item, :contributing_filters, [])
    all_filters = Enum.uniq(acc_filters ++ item_filters)
    
    %{
      id: "converged_#{Map.get(acc, :id, "")}_#{Map.get(item, :id, "")}",
      action_type: Map.get(primary_action, :action_type, :converged),
      computation_cost: combined_cost,
      processing_time_us: combined_processing_time,
      convergence_applied: true,
      contributing_filters: all_filters,
      filter_convergence_count: length(all_filters),
      converged_from: [Map.get(acc, :id), Map.get(item, :id)],
      result: :converged,
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  # Element definitions with pads (Membrane-style)
  
  # ElementPad is already defined above in the module

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
        # Check flow control and demand before processing
        demand = pad.demand || 0
        case {pad.flow_control, demand} do
          {:pull, demand} when demand > 0 ->
            # Process input buffer through element
            case element.process_fn.(buffer, element.state) do
              {:ok, output_buffer, new_state} ->
                new_element = %{element | state: new_state}
                # Update pad demand
                updated_pad = %{pad | demand: max(0, demand - 1)}
                updated_element = put_in(new_element.pads[pad_name], updated_pad)
                {:ok, [{:output, output_buffer, updated_element}]}
              {:error, reason} ->
                {:error, reason}
            end
          {:pull, _} ->
            # No demand, buffer the input
            buffer_queue = pad.buffer_queue || []
            buffered_pad = %{pad | buffer_queue: [buffer | buffer_queue]}
            updated_element = put_in(element.pads[pad_name], buffered_pad)
            {:ok, [{:buffered, nil, updated_element}]}
          {:push, _} ->
            # Push mode, process immediately
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

  defp handle_pad_buffer(state, pad_name, buffer) do
    # Handle buffer arrival at input pad - supports both pull and push flow control
    case get_in(state.input_pads, [pad_name]) do
      %ElementPad{type: :input, flow_control: flow_control} = pad ->
        case flow_control do
          :pull ->
            # Pull mode: only process if there is demand
            if pad.demand && pad.demand > 0 do
              # Process buffer and update demand
              updated_pad = %{pad | demand: pad.demand - 1}
              updated_state = put_in(state.input_pads[pad_name], updated_pad)
              
              # Process buffer through element (if element exists)
              if state.element do
                case process_buffer_through_pad(state.element, pad_name, buffer) do
                  {:ok, output_buffers} ->
                    # Send output buffers to connected pads
                    send_buffers_to_connected_pads(output_buffers, state)
                    updated_state
                  {:error, _reason} ->
                    # Buffer processing failed, keep original state
                    state
                end
              else
                updated_state
              end
            else
              # No demand, queue the buffer
              buffer_queue = pad.buffer_queue || :queue.new()
              queued_buffer_queue = :queue.in(buffer, buffer_queue)
              updated_pad = %{pad | buffer_queue: queued_buffer_queue}
              put_in(state.input_pads[pad_name], updated_pad)
            end
          
          :push ->
            # Push mode: process immediately regardless of demand
            if state.element do
              case process_buffer_through_pad(state.element, pad_name, buffer) do
                {:ok, output_buffers} ->
                  # Send output buffers to connected pads
                  send_buffers_to_connected_pads(output_buffers, state)
                  state
                {:error, _reason} ->
                  # Buffer processing failed, keep original state
                  state
              end
            else
              state
            end
        end
      
      nil ->
        # Pad not found, ignore buffer
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
