defmodule AriaEngine.MCP.Tools.GetPipelineStatus do
  @moduledoc """
  Hermes MCP tool component for getting pipeline status.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "get_pipeline_status",
    version: "2.0.0",
    description: "Get detailed status information for a specific pipeline"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "pipeline_id" => %{
          "type" => "string",
          "description" => "ID of the pipeline to check"
        }
      },
      "required" => ["pipeline_id"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:get_pipeline_status, params)
  end
end
