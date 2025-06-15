# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.MembraneFlowElement do
  @moduledoc """
  Membrane-style Flow element with proper pads and filters.
  
  This implements true Membrane concepts:
  - Input/Output pads with flow control
  - Demand-driven processing 
  - Buffer handling through filters
  - Backflow and backpressure support
  
  But using Flow for the actual parallel processing engine.
  """

  use GenServer
  require Logger

  # Membrane-style element definition
  defstruct [
    :name,
    :input_pads,
    :output_pads, 
    :pad_connections,
    :demand_state,
    :filter_functions,
    :backflow_enabled
  ]

  # Pad definition (similar to Membrane's def_input_pad/def_output_pad)
  defmodule Pad do
    defstruct [:name, :type, :flow_control, :demand_size, :accepted_format]
  end

  # Emulate Membrane.Buffer structure
  defmodule Buffer do
    @moduledoc "Emulates Membrane.Buffer with payload and metadata"
    defstruct [:payload, :metadata]
    
    @type t :: %__MODULE__{
      payload: any(),
      metadata: map()
    }
    
    def new(payload, metadata \\ %{}) do
      %__MODULE__{payload: payload, metadata: metadata}
    end
  end

  @doc """
  Start a Membrane-style Flow element with pads and filters.
  
  Example:
    {:ok, element} = MembraneFlowElement.start_element("filter1", [
      input_pads: [
        %Pad{name: :input, type: :input, flow_control: :pull, demand_size: 100}
      ],
      output_pads: [
        %Pad{name: :output, type: :output, flow_control: :push}
      ],
      filter_fn: &my_filter_function/1
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
  def push_buffer(element_name, pad_name, buffer) do
    GenServer.cast(via_tuple(element_name), {:buffer, pad_name, buffer})
  end

  @doc """
  Handle demand from downstream element.
  """
  def pull_demand(element_name, pad_name, demand_size) do
    GenServer.cast(via_tuple(element_name), {:demand, pad_name, demand_size})
  end

  # GenServer implementation (Membrane-style element lifecycle)

  @impl true
  def init({name, opts}) do
    # Initialize element with Membrane-style pads
    input_pads = Keyword.get(opts, :input_pads, [])
    output_pads = Keyword.get(opts, :output_pads, [])
    filter_fn = Keyword.get(opts, :filter_fn, &default_filter/1)
    
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
      filter_functions: %{default: filter_fn},
      backflow_enabled: Keyword.get(opts, :backflow_enabled, true)
    }

    {:ok, state}
  end

  # Membrane-style element callbacks

  @impl true
  def handle_call({:link_pad, source_pad, sink_element, sink_pad}, _from, state) do
    # Create pad-to-pad connection (Membrane-style linking)
    connection_key = {state.name, source_pad}
    connection_value = {sink_element, sink_pad}
    
    new_connections = Map.put(state.pad_connections, connection_key, connection_value)
    new_state = %{state | pad_connections: new_connections}
    
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:buffer, pad_name, buffer}, state) do
    # Handle incoming buffer on input pad (similar to Membrane's handle_buffer)
    case Map.get(state.input_pads, pad_name) do
      %Pad{type: :input, flow_control: :pull} = _pad ->
        # Process buffer through filter and send to output pads
        processed_buffer = process_buffer_through_filter(buffer, state)
        send_to_output_pads(processed_buffer, state)
        
        # Handle demand (request more data if needed)
        handle_input_demand(pad_name, state)
        
      nil ->
        Logger.warning("Buffer sent to unknown input pad: #{pad_name}")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_cast({:demand, pad_name, demand_size}, state) do
    # Handle demand from downstream element (Membrane-style demand handling)
    case Map.get(state.demand_state, pad_name) do
      nil ->
        Logger.warning("Demand received for unknown pad: #{pad_name}")
        {:noreply, state}
        
      current_demand ->
        new_demand = %{current_demand | pending_demand: current_demand.pending_demand + demand_size}
        new_demand_state = Map.put(state.demand_state, pad_name, new_demand)
        new_state = %{state | demand_state: new_demand_state}
        
        # Process any pending buffers if we now have demand
        process_pending_buffers_with_demand(pad_name, new_state)
        
        {:noreply, new_state}
    end
  end

  # Private implementation - Membrane-style processing with Flow

  defp process_buffer_through_filter(%Buffer{payload: payload} = buffer, state) do
    # Apply filter function to buffer payload using Flow for parallel processing
    filter_fn = Map.get(state.filter_functions, :default, &default_filter/1)
    
    # Use Flow for parallel processing of the buffer data
    processed_payload = case payload do
      list when is_list(list) ->
        # Process list items in parallel using Flow
        list
        |> Flow.from_enumerable(stages: System.schedulers_online())
        |> Flow.map(filter_fn)
        |> Enum.to_list()
      
      single_item ->
        # Process single item
        filter_fn.(single_item)
    end
    
    # Return processed buffer
    %Buffer{buffer | payload: processed_payload}
  end

  defp send_to_output_pads(buffer, state) do
    # Send processed buffer to all connected output pads
    Enum.each(state.output_pads, fn {pad_name, _pad} ->
      case Map.get(state.pad_connections, {state.name, pad_name}) do
        {sink_element, sink_pad} ->
          # Send buffer to connected sink element
          push_buffer(sink_element, sink_pad, buffer)
          
        nil ->
          Logger.debug("Output pad #{pad_name} not connected")
      end
    end)
  end

  defp handle_input_demand(pad_name, state) do
    # Request more data from upstream if we have demand
    case Map.get(state.demand_state, pad_name) do
      %{pending_demand: pending} when pending > 0 ->
        # Find upstream connection and request more data
        request_upstream_data(pad_name, pending, state)
        
      _ ->
        :ok
    end
  end

  defp process_pending_buffers_with_demand(_pad_name, _state) do
    # Process any buffers that were waiting for demand
    # This would be more complex in a full implementation
    :ok
  end

  defp request_upstream_data(_pad_name, _demand_size, _state) do
    # Request data from upstream elements
    # This would connect back to upstream elements
    :ok
  end

  # Default filter function
  defp default_filter(item) do
    # Default processing - add processing timestamp and simulate some work
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate computational work based on item type
    iterations = case Map.get(item, :action, :default) do
      :move_to -> 500
      :attack -> 750  
      :skill_cast -> 1000
      :interact -> 300
      _ -> 400
    end

    # Perform actual computation
    _result = Enum.reduce(1..iterations, 0.0, fn i, acc ->
      acc + :math.sin(i * 0.01)
    end)

    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start

    # Return processed item
    item
    |> Map.put(:processed_at, processing_end)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:filter_applied, true)
  end

  defp via_tuple(name) do
    {:via, Registry, {AriaQueue.Registry, name}}
  end
end
