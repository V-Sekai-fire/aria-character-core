defmodule AriaEngine.MCP.Tools.SetupElementConfig do
  @moduledoc """
  Hermes MCP tool component for setting up pipeline element configuration.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "setup_element_config",
    version: "2.0.0",
    description: "Validate and setup configuration for pipeline elements"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "element_type" => %{
          "type" => "string",
          "enum" => ["MCPSource", "EchoFilter", "ScheduleFilter", "ResponseFilter", "MCPSink"],
          "description" => "Type of pipeline element"
        },
        "config" => %{
          "type" => "object",
          "description" => "Element-specific configuration"
        }
      },
      "required" => ["element_type"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:setup_element_config, params)
  end
end
