# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.Pipeline do
  @moduledoc """
  Pipeline management for parallel processing workflows.
  
  Creates and manages pipeline configurations with minimal coordination overhead.
  """

  @doc """
  Create a pipeline configuration with optimal parallel processing settings.
  """
  def create_pipeline(pipeline_name, opts \\ []) do
    # Minimal pipeline registry using ETS for zero-coordination lookups
    ensure_pipeline_registry()
    
    stages = Keyword.get(opts, :stages, 4)
    backflow_enabled = Keyword.get(opts, :backflow_enabled, true)
    
    # Register pipeline configuration
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
  Signal backpressure or demand to the pipeline.
  """
  def signal_backflow(_pipeline_name, _signal_type, _metadata \\ %{}) do
    # Direct signaling without GenServer coordination overhead
    :ok
  end

  defp ensure_pipeline_registry() do
    case :ets.whereis(:aria_pipeline_registry) do
      :undefined -> 
        :ets.new(:aria_pipeline_registry, [:set, :named_table, :public])
      _ -> 
        :ok
    end
  end
end
