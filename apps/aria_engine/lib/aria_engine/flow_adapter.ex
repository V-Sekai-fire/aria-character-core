# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.FlowAdapter do
  @moduledoc """
  Flow processing adapter that provides a unified interface for stream processing
  with explicit flow control and convergence options.
  
  ## Flow Control Modes
  
  Users can choose between two fundamental flow control mechanisms:
  
  - **Push Mode** (`:push`): Elements send data immediately when available
  - **Pull Mode** (`:pull`): Elements request data when ready (demand-driven)
  
  ## Convergence Options
  
  Convergence processing can be enabled for performance optimization:
  
  - **Convergence Enabled** (`:convergence` option): Apply convergence patterns for better performance
  - **Standard Processing**: Regular flow processing without convergence optimizations
  
  ## Design Philosophy
  
  - **Expose Essential Controls**: Push/pull and convergence are configurable options
  - **Mock Implementation**: Convergence is exposed but unimplemented in this mock
  - **Consistent Results**: Same logical output regardless of configuration
  - **Clear Interface**: Explicit options without auto-configuration
  """

  @doc """
  Creates a processing pipeline with explicitly specified flow control mode.
  
  ## Required Options
  
  - `:flow_control` - `:push` or `:pull` (REQUIRED)
  - `:stages` - Number of processing stages (REQUIRED)
  
  ## Optional Settings
  
  - `:demand_size` - Buffer size for pull mode (required for pull mode)
  - `:max_demand` - Maximum demand for pull mode (optional, defaults to 2x demand_size)
  - `:convergence` - Enable convergence processing (optional, defaults to false)
  
  ## Examples
  
      # Create a pull-based pipeline with convergence
      {:ok, config} = FlowAdapter.create_pipeline("data_pipeline", 
        flow_control: :pull, 
        stages: 4, 
        demand_size: 50,
        convergence: true
      )
      
      # Create a push-based pipeline without convergence
      {:ok, config} = FlowAdapter.create_pipeline("fast_pipeline", 
        flow_control: :push, 
        stages: 8,
        convergence: false
      )
  """
  def create_pipeline(name, opts) when is_list(opts) do
    flow_control = Keyword.fetch!(opts, :flow_control)
    stages = Keyword.fetch!(opts, :stages)
    convergence = Keyword.get(opts, :convergence, false)
    
    config = case flow_control do
      :pull ->
        demand_size = Keyword.fetch!(opts, :demand_size)
        max_demand = Keyword.get(opts, :max_demand, demand_size * 2)
        
        %{
          name: name,
          flow_control: :pull,
          stages: stages,
          demand_size: demand_size,
          max_demand: max_demand,
          convergence: convergence
        }
      
      :push ->
        %{
          name: name,
          flow_control: :push,
          stages: stages,
          convergence: convergence
        }
      
      _ ->
        raise ArgumentError, "flow_control must be :push or :pull, got: #{inspect(flow_control)}"
    end
    
    {:ok, config}
  end

  @doc """
  Process data through a configured pipeline using its specified flow control.
  
  This function uses the flow control mode specified during pipeline creation.
  Convergence processing is exposed as an option but unimplemented in this mock.
  """
  def process_data(config, data) do
    # In a real implementation, this would use the config to dispatch
    # to a running Flow process. For now, we just simulate the work.
    IO.puts("Processing data with config: #{inspect(config)}")
    {:ok, data}
  end

  @doc """
  Process a collection of STN segments in parallel using the configured pipeline.
  
  This provides STN-specific parallel processing using the Flow adapter,
  ensuring consistent performance characteristics and avoiding direct
  Task.async_stream usage in STN operations.
  
  ## Parameters
  
  - `config` - Pipeline configuration from create_pipeline/2
  - `segments` - Collection of STN segments to process
  - `processing_fn` - Function to apply to each segment (e.g., &apply_pc2/1)
  
  ## Examples
  
      {:ok, config} = FlowAdapter.create_pipeline("stn_parallel", 
        flow_control: :pull, 
        stages: 4, 
        demand_size: 8,
        convergence: true
      )
      
      processed_segments = FlowAdapter.process_stn_segments(config, segments, &apply_pc2/1)
  """
  def process_stn_segments(config, segments, processing_fn) when is_list(segments) and is_function(processing_fn, 1) do
    # Use the configured flow control and stages for parallel processing
    max_concurrency = config.stages
    
    # For now, simulate Flow-based processing using Task.async_stream
    # In a real implementation, this would use Flow with the configured parameters
    segments
    |> Task.async_stream(processing_fn, max_concurrency: max_concurrency)
    |> Enum.map(fn {:ok, result} -> result end)
  end

  @doc """
  Process multiple STN operations in parallel using boolean composition.
  
  This handles parallel composition of STN boolean operations (and, or, union)
  using the Flow adapter for consistent performance characteristics.
  
  ## Parameters
  
  - `config` - Pipeline configuration from create_pipeline/2
  - `stn_operations` - List of {stn1, stn2, operation} tuples
  - `composition_fn` - Function to compose STN pairs (e.g., &union/2, &and/2)
  
  ## Examples
  
      operations = [{stn1, stn2, :union}, {stn3, stn4, :and}]
      results = FlowAdapter.process_stn_compositions(config, operations, &union/2)
  """
  def process_stn_compositions(config, stn_operations, composition_fn) when is_list(stn_operations) and is_function(composition_fn, 2) do
    # Use the configured flow control for parallel composition
    max_concurrency = config.stages
    
    # Process STN compositions in parallel
    stn_operations
    |> Task.async_stream(fn {stn1, stn2, _operation} -> 
         composition_fn.(stn1, stn2)
       end, max_concurrency: max_concurrency)
    |> Enum.map(fn {:ok, result} -> result end)
  end
end
