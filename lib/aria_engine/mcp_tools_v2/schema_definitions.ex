# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPToolsV2.SchemaDefinitions do
  @moduledoc """
  Input schema definitions for MCP tools.
  
  Provides JSON schema definitions for all MCP tool input parameters.
  """

  @doc """
  Get input schema for configure_pipeline_layout tool.
  """
  @spec get_configure_pipeline_layout_schema() :: map()
  def get_configure_pipeline_layout_schema do
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

  @doc """
  Get input schema for setup_element_config tool.
  """
  @spec get_setup_element_config_schema() :: map()
  def get_setup_element_config_schema do
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

  @doc """
  Get input schema for start_planning_pipeline tool.
  """
  @spec get_start_planning_pipeline_schema() :: map()
  def get_start_planning_pipeline_schema do
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

  @doc """
  Get input schema for stop_planning_pipeline tool.
  """
  @spec get_stop_planning_pipeline_schema() :: map()
  def get_stop_planning_pipeline_schema do
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

  @doc """
  Get input schema for get_pipeline_status tool.
  """
  @spec get_get_pipeline_status_schema() :: map()
  def get_get_pipeline_status_schema do
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

  @doc """
  Get input schema for get_pipeline_metrics tool.
  """
  @spec get_get_pipeline_metrics_schema() :: map()
  def get_get_pipeline_metrics_schema do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  @doc """
  Get input schema for schedule_activities tool.
  """
  @spec get_schedule_activities_schema() :: map()
  def get_schedule_activities_schema do
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

  @doc """
  Get input schema for list_active_pipelines tool.
  """
  @spec get_list_active_pipelines_schema() :: map()
  def get_list_active_pipelines_schema do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  @doc """
  Get input schema for validate_scheduling_solutions tool.
  """
  @spec get_validate_scheduling_solutions_schema() :: map()
  def get_validate_scheduling_solutions_schema do
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

  @doc """
  Get input schema for send_pipeline_request tool.
  """
  @spec get_send_pipeline_request_schema() :: map()
  def get_send_pipeline_request_schema do
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
end
