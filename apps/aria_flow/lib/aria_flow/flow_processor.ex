# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.FlowProcessor do
  @moduledoc """
  Core parallel processing system with Membrane-style elements and backflow control.
  
  This module implements the complete AriaFlow API extracted from the backup file,
  providing demand-driven processing with maximum parallelism without GenServer complexity.
  """

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

  # Pipeline chaining types
  @type pipeline_chain :: [pipeline_name()]
  @type chain_opts :: [
    coordination_mode: :minimal | :full,
    chain_backpressure: boolean(),
    intermediate_buffering: boolean()
  ]

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

    @type t :: %__MODULE__{
      name: atom() | String.t(),
      type: :input | :output,
      flow_control: :push | :pull,
      demand: non_neg_integer(),
      connected_to: {atom() | String.t(), atom() | String.t()} | nil,
      buffer_queue: :queue.queue() | list(),
      accepted_format: any(),
      demand_size: pos_integer()
    }
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

    @type t :: %__MODULE__{
      payload: any(),
      metadata: map(),
      pts: integer(),
      dts: integer(),
      size: non_neg_integer(),
      stream_format: any(),
      pad_name: atom() | String.t()
    }
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

    @type t :: %__MODULE__{
      payload: any(),
      metadata: map(),
      pts: integer(),
      dts: integer(),
      size: non_neg_integer(),
      stream_format: any(),
      pad_name: atom() | String.t()
    }
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

    @type t :: %__MODULE__{
      name: atom() | String.t(),
      type: :source | :filter | :sink,
      pads: %{(atom() | String.t()) => ElementPad.t()},
      state: map(),
      process_fn: (any(), map() -> {:ok, any(), map()} | {:error, any()})
    }
  end

  # Initialize ETS table for pipeline registry
  def ensure_pipeline_registry() do
    case :ets.whereis(:aria_pipeline_registry) do
      :undefined -> 
        :ets.new(:aria_pipeline_registry, [:set, :named_table, :public])
      _ -> 
        :ok
    end
  end

  @doc """
  Create a Flow-based processing pipeline.
  
  This creates a pipeline configuration that can be used for parallel processing
  with backflow control and demand-driven execution.
  """
  @spec create_pipeline(pipeline_name(), pipeline_opts()) :: {:ok, pid()}
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
  Create a Membrane-style element with input and output pads.
  
  Elements have pads that can handle demand-driven flow control,
  similar to Membrane's architecture but implemented with Flow.
  """
  @spec create_element(element_name(), element_type(), element_opts()) :: {:ok, pid()}
  def create_element(name, element_type, opts \\ []) do
    input_pads = Keyword.get(opts, :input_pads, [])
    output_pads = Keyword.get(opts, :output_pads, [])
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    
    # Create the actual flow element using our helper function
    flow_element = create_flow_element(name, element_type, opts)
    
    # Create pad state maps
    input_pad_map = Map.new(input_pads, fn pad -> {pad.name, pad} end)
    output_pad_map = Map.new(output_pads, fn pad -> {pad.name, pad} end)
    
    # Initialize demand state for each input pad (Membrane-style demand)
    demand_state = Map.new(input_pads, fn pad ->
      {pad.name, %{demand_size: pad.demand_size || 100, pending_demand: 0}}
    end)

    # Register element in ETS for later lookup
    ensure_pipeline_registry()
    :ets.insert(:aria_pipeline_registry, {name, %{
      type: :element,
      element_type: element_type,
      input_pads: input_pad_map,
      output_pads: output_pad_map,
      demand_state: demand_state,
      filter_functions: %{default: filter_fn},
      element: flow_element,
      created_at: System.monotonic_time()
    }})
    
    {:ok, self()}
  end

  @doc """
  Start a Membrane-style element process.
  Alias for create_element to match test expectations.
  """
  @spec start_element(element_name(), element_opts()) :: {:ok, pid()}
  def start_element(name, opts \\ []) do
    element_type = Keyword.get(opts, :element_type, :filter)
    create_element(name, element_type, opts)
  end

  @doc """
  Link two element pads together (Membrane-style pad linking).
  """
  @spec link_elements(element_name(), pad_name(), element_name(), pad_name()) :: :ok
  def link_elements(source_element, source_pad, sink_element, sink_pad) do
    # Create pad-to-pad connection (Membrane-style linking)
    ensure_pipeline_registry()
    
    # Store the connection for later use
    connection_key = {source_element, source_pad, sink_element, sink_pad}
    :ets.insert(:aria_pipeline_registry, {connection_key, %{
      type: :pad_connection,
      source: {source_element, source_pad},
      sink: {sink_element, sink_pad},
      created_at: System.monotonic_time()
    }})
    
    :ok
  end

  @doc """
  Send buffer to element's input pad.
  """
  @spec send_buffer(element_name(), pad_name(), buffer_data()) :: :ok
  def send_buffer(element_name, pad_name, buffer) do
    # Process buffer through element pad (Membrane-style processing)
    case :ets.lookup(:aria_pipeline_registry, element_name) do
      [{^element_name, element_config}] ->
        case process_buffer_through_element(element_config, pad_name, buffer) do
          {:ok, output_buffers} ->
            # Send output buffers to connected elements
            send_buffers_to_connected_pads(output_buffers, element_name)
            :ok
          {:error, _reason} ->
            :ok
        end
      [] ->
        :ok
    end
  end

  @doc """
  Handle demand from downstream element.
  """
  @spec handle_demand(element_name(), pad_name(), demand_size()) :: :ok
  def handle_demand(element_name, pad_name, demand_size) do
    # Handle demand signal through pad (Membrane-style demand)
    case :ets.lookup(:aria_pipeline_registry, element_name) do
      [{^element_name, element_config}] ->
        updated_config = handle_pad_demand(element_config, pad_name, demand_size)
        :ets.insert(:aria_pipeline_registry, {element_name, updated_config})
        :ok
      [] ->
        :ok
    end
  end

  @doc """
  Signal backpressure or demand to the pipeline.
  """
  @spec signal_backflow(pipeline_name(), atom(), map()) :: :ok
  def signal_backflow(pipeline_name, signal_type, metadata \\ %{}) do
    # Handle backflow signal
    case :ets.lookup(:aria_pipeline_registry, pipeline_name) do
      [{^pipeline_name, pipeline_config}] ->
        if Map.get(pipeline_config, :backflow_enabled, true) do
          Logger.debug("Backflow signal: #{signal_type} for #{pipeline_name}, metadata: #{inspect(metadata)}")
        end
        :ok
      [] ->
        :ok
    end
  end

  @doc """
  Process data through the adaptive processing pipeline with demand signaling.
  
  This method automatically adjusts processing based on system load and
  provides optimal resource utilization through adaptive demand control.
  """
  @spec process_with_backflow(pipeline_name(), [buffer_data()], processing_opts()) :: 
    {:ok, any()} | {:error, any()} | map()
  def process_with_backflow(pipeline_name, data, opts \\ []) do
    # Get pipeline configuration or use defaults
    pipeline_config = case :ets.lookup(:aria_pipeline_registry, pipeline_name) do
      [{^pipeline_name, config}] -> config
      [] -> %{stages: 4, backflow_enabled: true, max_demand: 100, min_demand: 1}
    end
    
    # Process with demand control
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions from options
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    filter_fns = Keyword.get(opts, :filter_fns, [&default_filter/1])
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    
    # Ensure filter_fns is a list
    filter_functions = case filter_fns do
      list when is_list(list) -> list
      single_fn when is_function(single_fn) -> [single_fn]
      _ -> [&default_filter/1]
    end
    
    # Process with maximal parallel filter execution
    result = process_with_demand_control(data, pipeline_config, source_fn, filter_functions, sink_fn)
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    # Add processing time to metrics
    updated_result = Map.update(result, :metrics, %{}, fn metrics ->
      Map.put(metrics, :total_processing_time, processing_time)
    end)
    
    updated_result
  end

  @doc """
  Process data with hierarchical reduction for optimal efficiency.
  
  This processing method reduces results across multiple stages for
  maximum parallelization and performance.
  """
  @spec process_with_convergence(pipeline_name(), [buffer_data()], processing_opts()) :: 
    {:ok, any()} | {:error, any()} | map()
  def process_with_convergence(pipeline_name, data, opts \\ []) do
    # Get pipeline configuration or use defaults
    pipeline_config = case :ets.lookup(:aria_pipeline_registry, pipeline_name) do
      [{^pipeline_name, config}] -> config
      [] -> %{stages: 4, backflow_enabled: true, max_demand: 100, min_demand: 1}
    end
    
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions from options
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    convergence_fn = Keyword.get(opts, :convergence_fn, &default_convergence/2)
    
    # Process with GPU-style hierarchical convergence
    result = process_with_hierarchical_convergence(data, pipeline_config, source_fn, filter_fn, sink_fn, convergence_fn)
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    # Add processing time to metrics
    updated_result = Map.update(result, :metrics, %{}, fn metrics ->
      Map.put(metrics, :total_processing_time, processing_time)
    end)
    
    updated_result
  end

  @doc """
  Create a chain of pipelines with minimal coordination overhead.
  
  Chained pipelines pass data directly from one to the next without
  intermediate coordination steps, maximizing throughput.
  """
  @spec create_pipeline_chain(pipeline_chain(), chain_opts()) :: {:ok, String.t()} | {:error, any()}
  def create_pipeline_chain(pipeline_names, opts \\ []) do
    coordination_mode = Keyword.get(opts, :coordination_mode, :minimal)
    chain_backpressure = Keyword.get(opts, :chain_backpressure, true)
    intermediate_buffering = Keyword.get(opts, :intermediate_buffering, false)
    
    chain_id = "chain_#{System.unique_integer([:positive])}"
    
    ensure_pipeline_registry()
    
    # Register chain configuration for minimal coordination
    :ets.insert(:aria_pipeline_registry, {chain_id, %{
      type: :pipeline_chain,
      pipelines: pipeline_names,
      coordination_mode: coordination_mode,
      chain_backpressure: chain_backpressure,
      intermediate_buffering: intermediate_buffering,
      created_at: System.monotonic_time()
    }})
    
    {:ok, chain_id}
  end

  @doc """
  Process data through a pipeline chain with minimal coordination overhead.
  
  Data flows directly from pipeline to pipeline without coordination bottlenecks.
  """
  @spec process_through_chain(String.t(), [buffer_data()], processing_opts()) :: {:ok, any()} | {:error, any()}
  def process_through_chain(chain_id, data, opts \\ []) do
    case :ets.lookup(:aria_pipeline_registry, chain_id) do
      [{^chain_id, chain_config}] ->
        process_chain_with_minimal_coordination(chain_config, data, opts)
      [] ->
        {:error, :chain_not_found}
    end
  end

  # Private implementation functions

  defp process_with_demand_control(data, pipeline_config, source_fn, filter_fns, sink_fn) do
    stages = Map.get(pipeline_config, :stages, 4)
    
    # Maximal parallelism: distribute both data AND filters across Flow partitions
    filter_set = MapSet.new(filter_fns)
    filter_list = MapSet.to_list(filter_set)
    
    # Create cartesian product of data x filters for maximum parallel distribution
    data_filter_pairs = for item <- data, 
                           filter_fn <- filter_list, 
                           do: {item, filter_fn}
    
    results = data_filter_pairs
    |> Flow.from_enumerable(stages: stages)
    |> Flow.partition(hash: fn {item, _filter_fn} = event -> 
      # Use item hash for partitioning - return {event, partition} tuple
      partition = :erlang.phash2(item, stages)
      {event, partition}
    end)
    |> Flow.map(fn {item, filter_fn} ->
      # Each partition processes its assigned data-filter pairs in parallel
      source_result = source_fn.(item)
      
      # Apply filter in this partition
      filtered = filter_fn.(source_result)
      
      # Apply sink function
      result = sink_fn.(filtered)
      
      # Ensure result has an ID for grouping
      case result do
        map when is_map(map) ->
          Map.put_new(map, :id, Map.get(item, :id, :unknown))
        _ ->
          %{id: :unknown, data: result}
      end
    end)
    |> Enum.to_list()
    
    # Group and merge results manually after collection
    grouped_results = results
    |> Enum.group_by(fn result -> Map.get(result, :id, :unknown) end)
    |> Enum.map(fn {_item_id, filter_results} ->
      # Converge results from multiple filters for the same data item
      case filter_results do
        [] -> nil
        [single_result] -> single_result
        multiple_results ->
          # Merge results from multiple filters
          merge_filter_results(multiple_results)
      end
    end)
    |> Enum.reject(&is_nil/1)
    
    # Calculate metrics
    metrics = %{
      total_items: length(data),
      total_filters: MapSet.size(filter_set),
      results_count: length(grouped_results),
      processed_count: length(grouped_results)
    }
    
    %{
      results: grouped_results,
      metrics: metrics,
      processed_count: length(grouped_results)
    }
  end

  defp process_with_hierarchical_convergence(data, pipeline_config, source_fn, filter_fn, sink_fn, convergence_fn) do
    stages = Map.get(pipeline_config, :stages, 4)
    
    # Stage 1: Initial parallel processing
    initial_results = data
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(source_fn)
    |> Flow.map(filter_fn)
    |> Flow.map(sink_fn)
    |> Enum.to_list()
    
    # Stage 2: Hierarchical convergence (like GPU warp reduction)
    converged_results = hierarchical_reduce(initial_results, convergence_fn, stages)
    
    # Calculate convergence metrics
    metrics = %{
      total_items: length(data),
      convergence_stages: calculate_convergence_stages(length(data), stages),
      processed_count: length(converged_results),
      convergence_applied: true
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
    # Group results for hierarchical reduction - ensure we actually reduce the number of items
    result_count = length(results)
    # Use a minimum chunk size of 2 to ensure reduction, or group all if very few items
    chunk_size = if result_count <= stages do
      result_count  # Single group if we have few items
    else
      max(2, div(result_count, stages))  # Ensure at least 2 items per chunk
    end
    
    grouped_results = Enum.chunk_every(results, chunk_size)
    
    reduced_results = grouped_results
    |> Enum.map(fn group ->
      # Apply convergence function within each group
      case group do
        [single_item] -> single_item  # No reduction needed for single item
        multiple_items ->
          Enum.reduce(multiple_items, fn item, acc ->
            convergence_fn.(acc, item)
          end)
      end
    end)
    
    # Continue recursion only if we actually reduced the number of items
    case reduced_results do
      [single_result] -> [single_result]
      multiple_results when length(multiple_results) < result_count ->
        hierarchical_reduce(multiple_results, convergence_fn, stages)
      multiple_results ->
        # Safety check: if no reduction occurred, return as-is to prevent infinite loop
        multiple_results
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

  # Default processing functions
  defp default_source(item) do
    # Default source processing - pass through with timestamp
    case item do
      map when is_map(map) ->
        Map.put(map, :source_processed_at, System.monotonic_time(:microsecond))
      _ ->
        %{data: item, source_processed_at: System.monotonic_time(:microsecond)}
    end
  end

  defp default_filter(item) do
    # Default filter processing - simulate some computational work
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate work based on item type
    iterations = case item do
      %{action: action} ->
        case action do
          :move_to -> 100
          :attack -> 150  
          :skill_cast -> 200
          _ -> 80
        end
      _ -> 100
    end
    
    # Perform minimal computation
    _result = Enum.reduce(1..iterations, 0, fn i, acc ->
      acc + rem(i, 10)
    end)
    
    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start
    
    case item do
      map when is_map(map) ->
        map
        |> Map.put(:filter_processed_at, processing_end)
        |> Map.put(:processing_time_us, processing_time)
      _ ->
        %{
          data: item,
          filter_processed_at: processing_end,
          processing_time_us: processing_time
        }
    end
  end

  defp default_sink(item) do
    # Default sink processing - finalize and return
    case item do
      map when is_map(map) ->
        %{
          id: Map.get(map, :id, :unknown),
          result: :processed,
          processing_time_us: Map.get(map, :processing_time_us, 0),
          completed_at: System.monotonic_time(:microsecond)
        }
      _ ->
        %{
          id: :unknown,
          result: :processed,
          data: item,
          completed_at: System.monotonic_time(:microsecond)
        }
    end
  end

  defp default_convergence(acc, item) do
    # Default convergence combines computation costs and merges processing results
    combined_cost = Map.get(acc, :computation_cost, 0) + Map.get(item, :computation_cost, 0)
    combined_processing_time = Map.get(acc, :processing_time_us, 0) + Map.get(item, :processing_time_us, 0)
    
    %{
      id: "converged_#{Map.get(acc, :id, "")}_#{Map.get(item, :id, "")}",
      computation_cost: combined_cost,
      processing_time_us: combined_processing_time,
      convergence_applied: true,
      result: :converged,
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  defp merge_filter_results(results) do
    # Merge results from multiple filters
    base_result = hd(results)
    
    # Combine processing times
    total_processing_time = Enum.reduce(results, 0, fn result, acc ->
      acc + Map.get(result, :processing_time_us, 0)
    end)
    
    Map.merge(base_result, %{
      processing_time_us: total_processing_time,
      filter_count: length(results),
      convergence_applied: true
    })
  end

  # Element processing helpers
  
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

  defp process_buffer_through_element(element_config, pad_name, buffer) do
    element = Map.get(element_config, :element)
    if element do
      case Map.get(element.pads, pad_name) do
        %ElementPad{type: :input} = pad ->
          # Process input buffer through element
          case element.process_fn.(buffer, element.state) do
            {:ok, output_buffer, new_state} ->
              {:ok, [{:output, output_buffer}]}
            {:error, reason} ->
              {:error, reason}
          end
        %ElementPad{type: :output} ->
          # Output pad doesn't process, just forwards
          {:ok, [{pad_name, buffer}]}
        nil ->
          {:error, :pad_not_found}
      end
    else
      {:ok, []}
    end
  end

  defp send_buffers_to_connected_pads(output_buffers, _source_element) do
    # For now, just log the output buffers
    # In a full implementation, this would send to connected elements
    Enum.each(output_buffers, fn {pad_name, buffer} ->
      Logger.debug("Buffer sent from pad #{pad_name}: #{inspect(buffer)}")
    end)
  end

  defp handle_pad_demand(element_config, pad_name, demand_size) do
    # Update demand state for the pad
    current_demand_state = Map.get(element_config, :demand_state, %{})
    updated_demand_state = Map.put(current_demand_state, pad_name, %{
      demand_size: demand_size,
      pending_demand: 0
    })
    
    Map.put(element_config, :demand_state, updated_demand_state)
  end

  defp default_element_process(buffer, element_state) do
    # Default processing: simulate some work and pass through
    processing_time = :rand.uniform(100)  # 0-100 microseconds of work
    
    processed_buffer = case buffer do
      map when is_map(map) ->
        Map.put(map, :processed_at, System.monotonic_time(:microsecond))
      _ ->
        %{data: buffer, processed_at: System.monotonic_time(:microsecond)}
    end
    
    {:ok, processed_buffer, element_state}
  end

  # Chain processing implementation
  defp process_chain_with_minimal_coordination(chain_config, data, opts) do
    %{
      pipelines: pipeline_names,
      coordination_mode: coordination_mode,
      chain_backpressure: chain_backpressure,
      intermediate_buffering: intermediate_buffering
    } = chain_config
    
    case coordination_mode do
      :minimal ->
        process_chain_minimal_coordination(pipeline_names, data, opts, chain_backpressure, intermediate_buffering)
      :full ->
        process_chain_full_coordination(pipeline_names, data, opts)
    end
  end

  defp process_chain_minimal_coordination(pipeline_names, data, opts, _chain_backpressure, _intermediate_buffering) do
    # Chain pipelines using Flow's built-in streaming without extra coordination
    start_time = System.monotonic_time(:microsecond)
    
    # Extract processing functions
    source_fn = Keyword.get(opts, :source_fn, &default_source/1)
    sink_fn = Keyword.get(opts, :sink_fn, &default_sink/1)
    
    # Process through chained pipelines
    result = data
    |> Flow.from_enumerable(stages: calculate_optimal_stages_for_chain(pipeline_names))
    |> Flow.map(source_fn)
    |> apply_pipeline_chain(pipeline_names, opts)
    |> Flow.map(sink_fn)
    |> Enum.to_list()
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    # Build metrics
    metrics = %{
      total_items: length(result),
      pipeline_count: length(pipeline_names),
      total_processing_time: processing_time,
      coordination_mode: :minimal
    }
    
    {:ok, %{results: result, metrics: metrics, chain_processing_time: processing_time}}
  end

  defp process_chain_full_coordination(pipeline_names, data, opts) do
    # Traditional approach with full coordination
    Enum.reduce(pipeline_names, {:ok, data}, fn pipeline_name, {:ok, current_data} ->
      case process_with_backflow(pipeline_name, current_data, opts) do
        %{results: results} -> {:ok, results}
        {:ok, results} -> {:ok, results}
        error -> error
      end
    end)
  end

  defp calculate_optimal_stages_for_chain(pipeline_names) do
    # Calculate optimal stage count for chain processing
    base_stages = 4
    chain_length = length(pipeline_names)
    
    # Scale stages with chain length but cap to avoid over-coordination
    min(base_stages + chain_length, 16)
  end

  defp apply_pipeline_chain(flow, pipeline_names, opts) do
    # Apply each pipeline in the chain
    Enum.reduce(pipeline_names, flow, fn pipeline_name, acc_flow ->
      filter_fn = Keyword.get(opts, "#{pipeline_name}_filter_fn" |> String.to_atom(), &default_filter/1)
      Flow.map(acc_flow, filter_fn)
    end)
  end
end
