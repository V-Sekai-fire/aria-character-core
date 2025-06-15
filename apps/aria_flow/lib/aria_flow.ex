# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow do
  @moduledoc """
  AriaFlow provides stream processing with Membrane-style elements and backflow control.
  
  This module implements stream processing concepts like pads, filters, buffers, and
  demand-driven processing. The key abstraction is **backflow** - the ability for
  downstream components to signal demand upstream, enabling efficient pull-based
  processing.
  
  ## Core Concepts
  
  - **Elements**: Processing units with input/output pads (source, filter, sink)
  - **Pads**: Connection points that support push or pull flow control
  - **Backflow**: Demand-driven processing where downstream elements signal upstream
  - **Pipelines**: Connected graphs of elements that process data streams
  
  ## Flow Control Modes
  
  - **Pull Mode** (`:pull`): Elements request data when ready (demand-driven)
  - **Push Mode** (`:push`): Elements send data immediately when available
  
  ## Examples
  
      # Create a processing pipeline
      {:ok, _} = AriaFlow.create_pipeline("my_pipeline", concurrency: 8)
      
      # Process data with demand-driven backflow control
      result = AriaFlow.process_with_backflow("my_pipeline", data, 
        source_fn: &my_source/1,
        filter_fn: &my_filter/1,
        sink_fn: &my_sink/1
      )
      
      # Create Membrane-style elements with pull/push pads
      {:ok, _} = AriaFlow.create_element("processor", :filter, 
        input_pads: [%AriaFlow.ElementPad{
          name: :input, 
          type: :input, 
          flow_control: :pull,
          demand_size: 100
        }],
        output_pads: [%AriaFlow.ElementPad{
          name: :output, 
          type: :output, 
          flow_control: :push
        }]
      )
  """

  alias AriaFlow.{FlowProcessor, Element}

  # Main API functions that delegate to the backflow processor
  
  @doc """
  Create a Flow-based processing pipeline.
  """
  defdelegate create_pipeline(name, opts \\ []), to: FlowProcessor
  
  @doc """
  Process data with backflow (demand-driven) control.
  """
  defdelegate process_with_backflow(pipeline_name, data, opts \\ []), to: FlowProcessor
  
  @doc """
  Process data with GPU-style hierarchical convergence.
  """
  defdelegate process_with_convergence(pipeline_name, data, opts \\ []), to: FlowProcessor
  
  @doc """
  Create a Membrane-style element with pads.
  """
  defdelegate create_element(name, element_type, opts \\ []), to: FlowProcessor
  
  @doc """
  Link two element pads together.
  """
  defdelegate link_elements(source_element, source_pad, sink_element, sink_pad), to: FlowProcessor
  
  @doc """
  Send buffer to element's input pad.
  """
  defdelegate send_buffer(element_name, pad_name, buffer), to: FlowProcessor
  
  @doc """
  Handle demand from downstream element.
  """
  defdelegate handle_demand(element_name, pad_name, demand_size), to: FlowProcessor
  
  @doc """
  Signal backpressure or demand to the pipeline.
  """
  defdelegate signal_backflow(pipeline_name, signal_type, metadata \\ %{}), to: FlowProcessor
  
  # Element-related API that delegates to Element module
  
  @doc """
  Start a Membrane-style element process.
  """
  defdelegate start_element(name, opts \\ []), to: FlowProcessor
  
  @doc """
  Process buffer through element.
  """
  defdelegate process_buffer(element_name, pad_name, buffer), to: Element

  @doc """
  Process items using GPU convergence principles for high-performance parallel processing.
  
  This delegates to AriaFlow.GpuConvergenceProcessor to provide GPU-inspired processing
  with backflow, work stealing, and demand-driven execution.
  
  ## Options
  - `:batch_size` - Override automatic batch size calculation
  - `:stages` - Override automatic core count detection
  - `:work_stealing` - Enable/disable work stealing (default: true)
  
  ## Examples
  
      # Process actions in parallel with GPU convergence
      result = AriaFlow.process_batch(actions, &process_action/1)
      
      # Process with custom options
      result = AriaFlow.process_batch(items, &processor/1, 
        stages: 4, 
        batch_size: 128
      )
  """
  def process_batch(items, processor_fn, opts \\ []) do
    AriaFlow.GpuConvergenceProcessor.process_batch(items, processor_fn, opts)
  end

  @doc """
  Get GPU convergence processing metrics.
  
  Returns metrics about parallel processing performance, including convergence
  efficiency, throughput, and resource utilization.
  """
  def get_processing_metrics do
    AriaFlow.GpuConvergenceProcessor.get_metrics()
  end
end
