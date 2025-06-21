defmodule AriaEngine.MCP.Tools.ListActivePipelines do
  @moduledoc """
  Hermes MCP tool component for listing active pipelines.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "list_active_pipelines",
    version: "2.0.0",
    description: "List all currently active pipelines"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:list_active_pipelines, params)
  end
end
