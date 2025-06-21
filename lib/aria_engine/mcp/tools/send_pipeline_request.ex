defmodule AriaEngine.MCP.Tools.SendPipelineRequest do
  @moduledoc """
  Hermes MCP tool component for sending a request to a specific active pipeline.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "send_pipeline_request",
    version: "2.0.0",
    description: "Send a request to a specific active pipeline"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "pipeline_id" => %{
          "type" => "string",
          "description" => "ID of the target pipeline"
        },
        "request" => %{
          "type" => "object",
          "description" => "Request parameters to send to the pipeline"
        }
      },
      "required" => ["pipeline_id", "request"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:send_pipeline_request, params)
  end
end
