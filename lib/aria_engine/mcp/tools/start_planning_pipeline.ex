defmodule AriaEngine.MCP.Tools.StartPlanningPipeline do
  @moduledoc """
  Hermes MCP tool component for starting a planning pipeline.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "start_planning_pipeline",
    version: "2.0.0",
    description: "Start a new planning pipeline with predefined topology"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "topology" => %{
          "type" => "string",
          "enum" => ["echo_pipeline", "full_pipeline"],
          "default" => "echo_pipeline",
          "description" => "Predefined pipeline topology"
        }
      }
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:start_planning_pipeline, params)
  end
end
