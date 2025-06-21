defmodule AriaEngine.MCP.Tools.ScheduleActivities do
  @moduledoc """
  Hermes MCP tool component for scheduling activities.
  """

  use Hermes.Server.Component,
    type: :tool,
    name: "schedule_activities",
    version: "2.0.0",
    description: "Schedule activities using Membrane pipeline architecture with multiple strategy options"

  def __mcp_raw_schema__ do
    %{
      "type" => "object",
      "properties" => %{
        "schedule_name" => %{
          "type" => "string",
          "description" => "Name for the schedule (REQUIRED)"
        },
        "activities" => %{
          "type" => "array",
          "description" => "List of activities to schedule",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{
                "type" => "string",
                "description" => "Unique activity identifier (REQUIRED)"
              },
              "name" => %{
                "type" => "string",
                "description" => "Human-readable activity name"
              },
              "duration" => %{
                "oneOf" => [
                  %{
                    "type" => "string",
                    "description" => "ISO 8601 duration string (e.g., 'PT2H30M')"
                  },
                  %{
                    "type" => "object",
                    "properties" => %{
                      "start" => %{
                        "type" => "string",
                        "description" => "Start datetime (ISO 8601)"
                      },
                      "end" => %{
                        "type" => "string",
                        "description" => "End datetime (ISO 8601)"
                      }
                    },
                    "description" => "Time interval with start/end (can be open-ended)"
                  }
                ],
                "description" => "Activity duration (REQUIRED)"
              },
              "dependencies" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "List of activity IDs this depends on"
              },
              "required_capabilities" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Required entity capabilities"
              },
              "required_resources" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Required resource IDs"
              },
              "participants" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Entity IDs participating in this activity"
              },
              "type" => %{
                "type" => "string",
                "description" => "Activity type classification"
              }
            },
            "required" => ["id", "duration"]
          }
        },
        "entities" => %{
          "type" => "array",
          "description" => "Entities with capabilities and availability",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string"},
              "type" => %{"type" => "string"},
              "capabilities" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              },
              "availability" => %{
                "oneOf" => [
                  %{"type" => "string"},
                  %{"type" => "object"}
                ],
                "description" => "Entity availability using duration format"
              },
              "current_activity" => %{"type" => "string"},
              "resources_held" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              },
              "metadata" => %{"type" => "object"}
            }
          }
        },
        "resources" => %{
          "type" => "object",
          "description" => "Available resources with capacity management",
          "additionalProperties" => %{
            "type" => "object",
            "properties" => %{
              "type" => %{"type" => "string"},
              "capacity" => %{"type" => "number"},
              "current_usage" => %{"type" => "number"},
              "constraints" => %{"type" => "object"},
              "availability_schedule" => %{
                "type" => "array",
                "items" => %{"type" => "object"}
              },
              "metadata" => %{"type" => "object"}
            }
          }
        },
        "constraints" => %{
          "type" => "object",
          "description" => "Scheduling constraints and limits",
          "properties" => %{
            "max_concurrent_activities" => %{"type" => "number"},
            "require_resources" => %{"type" => "boolean"}
          }
        },
        "simulation_options" => %{
          "type" => "object",
          "description" => "Simulation and execution options",
          "properties" => %{
            "simulation_mode" => %{
              "type" => "boolean",
              "description" => "Run in simulation mode for prediction"
            },
            "verbose" => %{
              "type" => "number",
              "description" => "Logging verbosity level (0-3)"
            },
            "log_activities" => %{
              "type" => "boolean",
              "description" => "Track activity execution events"
            }
          }
        },
        "resource_management" => %{
          "type" => "object",
          "description" => "Resource allocation and conflict management",
          "properties" => %{
            "check_capacity" => %{
              "type" => "boolean",
              "description" => "Validate resource capacity limits"
            },
            "auto_allocate" => %{
              "type" => "boolean",
              "description" => "Automatically allocate resources"
            },
            "conflict_detection" => %{
              "type" => "boolean",
              "description" => "Detect resource conflicts"
            }
          }
        },
        "pipeline_topology" => %{
          "type" => "string",
          "enum" => ["echo_pipeline", "full_pipeline"],
          "default" => "full_pipeline",
          "description" => "Pipeline topology to use for processing"
        }
      },
      "required" => ["schedule_name", "activities"]
    }
  end

  @impl true
  def execute(params, _context) do
    AriaEngine.MCPToolsV2.schedule_activities(params)
  end
end
