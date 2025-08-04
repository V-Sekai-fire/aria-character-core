# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMembranePipeline do
  @moduledoc """
  Pipeline processing system using Membrane Framework for streaming data transformation and validation.

  AriaMembranePipeline provides a comprehensive pipeline processing layer built on the Membrane Framework.
  It handles streaming data transformation, validation, and coordination between different components
  of the Aria system.

  ## Core Components

  - `AriaMembranePipeline.PipelineManager` - Orchestrates complex data processing workflows
  - `AriaMembranePipeline.FormatTransformerFilter` - Converts between different data formats
  - `AriaMembranePipeline.MCPSource` - Model Context Protocol data source
  - `AriaMembranePipeline.MCPSink` - Model Context Protocol data sink
  - `AriaMembranePipeline.PlannerFilter` - Planning system integration
  - `AriaMembranePipeline.MinizincSolverFilter` - Constraint solver integration

  ## Usage

      # Create and start a pipeline
      pipeline = AriaMembranePipeline.create_pipeline(config)
      AriaMembranePipeline.start_pipeline(pipeline)

      # Process data through pipeline
      result = AriaMembranePipeline.process_data(pipeline, input_data)
  """

# Type definitions
  @type pipeline :: term()
  @type config :: map()
  @type data :: term()
  @type result :: {:ok, term()} | {:error, String.t()}
end
