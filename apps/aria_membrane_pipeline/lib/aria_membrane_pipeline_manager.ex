# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMembranePipeline.PipelineManager do
  @moduledoc """
  Public API wrapper for Membrane.PipelineManager.

  This module provides a clean public interface while delegating to the internal
  Membrane.PipelineManager implementation.
  """

  # Delegate all functions to Membrane.PipelineManager
  defdelegate start_link(opts \\ []), to: Membrane.PipelineManager
  defdelegate create_pipeline(config), to: Membrane.PipelineManager
  defdelegate create_testing_pipeline(topology \\ :echo_pipeline), to: Membrane.PipelineManager
  defdelegate configure_pipeline_topology(pipeline_pid, config), to: Membrane.PipelineManager
  defdelegate get_pipeline_status(pipeline_pid), to: Membrane.PipelineManager
  defdelegate list_active_pipelines(), to: Membrane.PipelineManager
  defdelegate stop_pipeline(pipeline_pid), to: Membrane.PipelineManager
  defdelegate send_request_to_pipeline(pipeline_pid, mcp_params), to: Membrane.PipelineManager
  defdelegate get_manager_stats(), to: Membrane.PipelineManager

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
