# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMembranePipeline do
  @moduledoc """
  Pipeline processing system using Membrane Framework for streaming data transformation and validation.

  AriaMembranePipeline provides a comprehensive pipeline processing layer built on the Membrane Framework.
  It handles streaming data transformation, validation, and coordination between different components
  of the Aria system.

  ## Core Components

  - `AriaMembranePipeline.PipelineManager` - Orchestrates complex data processing workflows
  - `AriaMembranePipeline.FormatTransformerFilter` - Converts between different data formats
  - `AriaMembranePipeline.ValidationPipelineFilter` - Ensures data integrity and constraint satisfaction
  - `AriaMembranePipeline.MCPSource` - Model Context Protocol data source
  - `AriaMembranePipeline.MCPSink` - Model Context Protocol data sink
  - `AriaMembranePipeline.PlannerFilter` - Planning system integration
  - `AriaMembranePipeline.MinizincSolverFilter` - Constraint solver integration

  ## Usage

      # Create and start a validation pipeline
      pipeline = AriaMembranePipeline.create_validation_pipeline(config)
      AriaMembranePipeline.start_pipeline(pipeline)

      # Process data through pipeline
      result = AriaMembranePipeline.process_data(pipeline, input_data)
  """

  alias AriaMembranePipeline.PipelineManager

  @doc "Creates a new validation pipeline with the given configuration."
  def create_validation_pipeline(config \\ %{}) do
    PipelineManager.create_validation_pipeline(config)
  end

  @doc "Starts a pipeline for processing."
  def start_pipeline(pipeline) do
    PipelineManager.start_pipeline(pipeline)
  end

  @doc "Processes data through the specified pipeline."
  def process_data(pipeline, data) do
    PipelineManager.process_data(pipeline, data)
  end

  @doc "Stops a running pipeline."
  def stop_pipeline(pipeline) do
    PipelineManager.stop_pipeline(pipeline)
  end
end
