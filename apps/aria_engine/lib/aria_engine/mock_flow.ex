# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MockFlow do
  @moduledoc """
  Simple mock implementation of FlowBehaviour for testing aria_engine
  without requiring a complete AriaFlow implementation.
  
  This provides just enough functionality to make tests pass while
  allowing aria_engine development to proceed independently.
  """
  
  @behaviour AriaFlow.Behaviour

  @impl true
  def create_pipeline(_name, _opts) do
    # Return a fake PID for testing
    {:ok, self()}
  end

  @impl true
  def process_with_backflow(_pipeline, actions, _opts) do
    # Simple mock processing that returns the expected structure
    results = Enum.map(actions, fn action ->
      {action, {:processed, action}, :backflow_applied}
    end)
    
    %{
      results: results,
      metrics: %{
        processed_count: length(actions),
        total_items: length(actions),
        backpressure_events: 0,
        backflow_optimized: true,
        processing_time_us: 100.0,
        core_count: System.schedulers_online()
      }
    }
  end

  @impl true
  def process_with_convergence(_pipeline, actions, _opts) do
    # Simple mock processing that returns the expected structure
    results = Enum.map(actions, fn action ->
      {action, {:processed, action}, :convergence_applied}
    end)
    
    %{
      results: results,
      metrics: %{
        processed_count: length(actions),
        convergence_applied: true,
        total_items: length(actions),
        total_processing_time: 100,  # Mock processing time
        convergence_stages: 1,
        backflow_optimized: true,
        backpressure_events: 0,
        processing_time_us: 100.0,
        core_count: System.schedulers_online()
      }
    }
  end

  @impl true
  def create_element(_name, _type, _opts) do
    {:ok, self()}
  end

  @impl true
  def start_element(_name, _opts) do
    :ok
  end

  @impl true
  def link_elements(_source_element, _source_pad, _sink_element, _sink_pad) do
    :ok
  end

  @impl true
  def send_buffer(_element_name, _pad_name, _buffer) do
    :ok
  end
end
