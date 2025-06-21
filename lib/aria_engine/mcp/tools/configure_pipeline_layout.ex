defmodule AriaEngine.MCP.Tools.ConfigurePipelineLayout do
  @moduledoc """
  Hermes MCP tool component for configuring a Membrane pipeline layout.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "configure_pipeline_layout",
    version: "2.0.0",
    description: "Configure and create a new Membrane pipeline with specified topology and elements"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "topology" => %{
          "type" => "string",
          "enum" => ["linear", "parallel", "multi_strategy", "custom"],
          "description" => "Pipeline topology type"
        },
        "elements" => %{
          "type" => "array",
          "description" => "Pipeline elements configuration",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "type" => %{"type" => "string"},
              "id" => %{"type" => "string"},
              "config" => %{"type" => "object"}
            }
          }
        },
        "connections" => %{
          "type" => "array",
          "description" => "Element connections",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "from" => %{
                "type" => "object",
                "properties" => %{
                  "element" => %{"type" => "string"},
                  "pad" => %{"type" => "string"}
                }
              },
              "to" => %{
                "type" => "object",
                "properties" => %{
                  "element" => %{"type" => "string"},
                  "pad" => %{"type" => "string"}
                }
              }
            }
          }
        },
        "supervision_strategy" => %{
          "type" => "string",
          "enum" => ["one_for_one", "one_for_all", "rest_for_one"],
          "default" => "one_for_one"
        }
      },
      "required" => ["topology"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.handle_tool_call(:configure_pipeline_layout, params)
  end
end
