defmodule AriaEngine.MCP.Tools.StopPlanningPipeline do
  @moduledoc """
  Hermes MCP tool component for stopping a planning pipeline.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "stop_planning_pipeline",
    version: "2.0.0",
    description: "Stop an active planning pipeline"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "pipeline_id" => %{
          "type" => "string",
          "description" => "ID of the pipeline to stop"
        }
      },
      "required" => ["pipeline_id"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:stop_planning_pipeline, params)
  end
end
