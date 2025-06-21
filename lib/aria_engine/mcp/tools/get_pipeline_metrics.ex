defmodule AriaEngine.MCP.Tools.GetPipelineMetrics do
  @moduledoc """
  Hermes MCP tool component for getting pipeline metrics.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "get_pipeline_metrics",
    version: "2.0.0",
    description: "Get overall metrics for the pipeline manager"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:get_pipeline_metrics, params)
  end
end
