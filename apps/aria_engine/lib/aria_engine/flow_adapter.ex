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
  Starts a new Flow process.
  """
  def start_link(opts) do
    AriaEngine.Flow.start_link(opts)
  end

  @doc """
  Returns the child spec for the Flow.
  """
  def child_spec(opts) do
    AriaEngine.Flow.child_spec(opts)
  end
end
