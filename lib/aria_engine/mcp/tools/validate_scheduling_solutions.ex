defmodule AriaEngine.MCP.Tools.ValidateSchedulingSolutions do
  @moduledoc """
  Hermes MCP tool component for validating scheduling solutions.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "validate_scheduling_solutions",
    version: "2.0.0",
    description: "Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "problem_name" => %{
          "type" => "string",
          "description" => "Name of the scheduling problem to validate"
        },
        "activities" => %{
          "type" => "array",
          "description" => "Activities to schedule for validation",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string"},
              "duration" => %{"type" => "number"},
              "dependencies" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              }
            },
            "required" => ["id", "duration"]
          }
        },
        "resources" => %{
          "type" => "object",
          "description" => "Available resources for scheduling"
        },
        "constraints" => %{
          "type" => "object",
          "description" => "Scheduling constraints to validate"
        },
        "validation_options" => %{
          "type" => "object",
          "description" => "Validation-specific options",
          "properties" => %{
            "timeout_seconds" => %{
              "type" => "number",
              "description" => "Maximum time for each solver"
            },
            "compare_solutions" => %{
              "type" => "boolean",
              "description" => "Compare solution quality between solvers"
            },
            "detailed_analysis" => %{
              "type" => "boolean",
              "description" => "Include detailed solver analysis"
            }
          }
        }
      },
      "required" => ["problem_name"]
    }
  end

  def execute(params, _context) do
    AriaEngine.MCPToolsV2.validate_scheduling_solutions(params)
  end
end
