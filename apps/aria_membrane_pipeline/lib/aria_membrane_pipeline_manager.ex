# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMembranePipeline.PipelineManager do
  @moduledoc """
  Public API wrapper for AriaEngine.Membrane.PipelineManager.

  This module provides a clean public interface while delegating to the internal
  AriaEngine.Membrane.PipelineManager implementation.
  """

  # Delegate all functions to AriaEngine.Membrane.PipelineManager
  defdelegate start_link(opts \\ []), to: AriaEngine.Membrane.PipelineManager
  defdelegate create_pipeline(config), to: AriaEngine.Membrane.PipelineManager
  defdelegate create_testing_pipeline(topology \\ :echo_pipeline), to: AriaEngine.Membrane.PipelineManager
  defdelegate configure_pipeline_topology(pipeline_pid, config), to: AriaEngine.Membrane.PipelineManager
  defdelegate get_pipeline_status(pipeline_pid), to: AriaEngine.Membrane.PipelineManager
  defdelegate list_active_pipelines(), to: AriaEngine.Membrane.PipelineManager
  defdelegate stop_pipeline(pipeline_pid), to: AriaEngine.Membrane.PipelineManager
  defdelegate send_request_to_pipeline(pipeline_pid, mcp_params), to: AriaEngine.Membrane.PipelineManager
  defdelegate get_manager_stats(), to: AriaEngine.Membrane.PipelineManager

  # Convenience functions for the main AriaMembranePipeline module
  def create_validation_pipeline(config) do
    create_pipeline(config)
  end

  def start_pipeline(pipeline) do
    # Pipeline is already started when created, so just return success
    {:ok, pipeline}
  end

  def process_data(pipeline, data) do
    # Send data to the pipeline
    send_request_to_pipeline(pipeline, data)
  end
end
