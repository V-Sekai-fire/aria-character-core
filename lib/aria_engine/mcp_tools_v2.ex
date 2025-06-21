defmodule AriaEngine.MCPToolsV2 do
  @moduledoc """
  MCP tools interface with Membrane Framework pipeline integration.
  
  Provides MCP tools for pipeline management and individual strategy testing.
  This is the updated version that uses the Membrane pipeline architecture
  instead of direct scheduler calls.
  """

  require Logger
  alias AriaEngine.Membrane.{PipelineManager, MCPSource}

  @tools [
    {:configure_pipeline_layout, "2.0.0"},
    {:setup_element_config, "2.0.0"},
    {:start_planning_pipeline, "2.0.0"},
    {:stop_planning_pipeline, "2.0.0"},
    {:get_pipeline_status, "2.0.0"},
    {:get_pipeline_metrics, "2.0.0"},
    {:schedule_activities, "2.0.0"},  # Updated to use pipeline
    {:list_active_pipelines, "2.0.0"},
    {:send_pipeline_request, "2.0.0"}
  ]

  @spec get_tools() :: [map()]
  def get_tools() do
    Enum.map(@tools, fn {name, version} ->
      %{
        "name" => Atom.to_string(name),
        "version" => version,
        "description" => get_tool_description(name),
        "inputSchema" => get_input_schema(name)
      }
    end)
  end

  @spec handle_tool_call(atom(), map()) :: map()
  def handle_tool_call(tool_name, params) when is_atom(tool_name) do
    Logger.info("MCP tool call: #{tool_name} with params: #{inspect(params)}")
    
    try do
      case tool_name do
        :configure_pipeline_layout -> handle_configure_pipeline_layout(params)
        :setup_element_config -> handle_setup_element_config(params)
        :start_planning_pipeline -> handle_start_planning_pipeline(params)
        :stop_planning_pipeline -> handle_stop_planning_pipeline(params)
        :get_pipeline_status -> handle_get_pipeline_status(params)
        :get_pipeline_metrics -> handle_get_pipeline_metrics(params)
        :schedule_activities -> handle_schedule_activities(params)
        :list_active_pipelines -> handle_list_active_pipelines(params)
        :send_pipeline_request -> handle_send_pipeline_request(params)
        _ -> %{"error" => "Unknown tool: #{tool_name}"}
      end
    rescue
      error ->
        Logger.error("Error in MCP tool #{tool_name}: #{inspect(error)}")
        %{
          "error" => "Tool execution failed: #{Exception.message(error)}",
          "details" => %{
            "tool" => Atom.to_string(tool_name),
            "params" => params
          }
        }
    end
  end

  def handle_tool_call(tool_name, params) when is_binary(tool_name) do
    handle_tool_call(String.to_atom(tool_name), params)
  end

  # Tool handlers

  defp handle_configure_pipeline_layout(params) do
    topology = String.to_atom(params["topology"] || "linear")
    elements = params["elements"] || []
    connections = params["connections"] || []

    config = %{
      topology: topology,
      elements: parse_elements(elements),
      connections: parse_connections(connections),
      supervision_strategy: String.to_atom(params["supervision_strategy"] || "one_for_one")
    }

    case PipelineManager.create_pipeline(config) do
      {:ok, pipeline_pid} ->
        %{
          "status" => "success",
          "pipeline_id" => inspect(pipeline_pid),
          "config" => %{
            "topology" => Atom.to_string(topology),
            "element_count" => length(elements),
            "connection_count" => length(connections)
          }
        }

      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Failed to create pipeline: #{inspect(reason)}"
        }
    end
  end

  defp handle_setup_element_config(params) do
    element_type = params["element_type"]
    element_config = params["config"] || %{}

    # Validate element configuration
    case validate_element_config(element_type, element_config) do
      :ok ->
        %{
          "status" => "success",
          "element_type" => element_type,
          "config" => element_config,
          "validation" => "passed"
        }

      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Invalid element configuration: #{reason}"
        }
    end
  end

  defp handle_start_planning_pipeline(params) do
    topology = String.to_atom(params["topology"] || "echo_pipeline")
    
    case PipelineManager.create_testing_pipeline(topology) do
      {:ok, pipeline_pid} ->
        %{
          "status" => "success",
          "pipeline_id" => inspect(pipeline_pid),
          "topology" => Atom.to_string(topology),
          "message" => "Planning pipeline started successfully"
        }

      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Failed to start pipeline: #{inspect(reason)}"
        }
    end
  end

  defp handle_stop_planning_pipeline(params) do
    pipeline_id = params["pipeline_id"]
    
    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        case PipelineManager.stop_pipeline(pipeline_pid) do
          :ok ->
            %{
              "status" => "success",
              "pipeline_id" => pipeline_id,
              "message" => "Pipeline stopped successfully"
            }
            
          {:error, reason} ->
            %{
              "status" => "error",
              "error" => "Failed to stop pipeline: #{inspect(reason)}"
            }
        end
        
      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Invalid pipeline ID: #{reason}"
        }
    end
  end

  defp handle_get_pipeline_status(params) do
    pipeline_id = params["pipeline_id"]
    
    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        status = PipelineManager.get_pipeline_status(pipeline_pid)
        
        case status do
          %{error: _} ->
            %{
              "status" => "error",
              "error" => status.error
            }
            
          _ ->
            %{
              "status" => "success",
              "pipeline_status" => %{
                "id" => status.id,
                "topology" => Atom.to_string(status.topology),
                "status" => Atom.to_string(status.status),
                "created_at" => DateTime.to_iso8601(status.created_at),
                "request_count" => status.request_count,
                "uptime_seconds" => status.uptime_seconds,
                "element_count" => status.element_count
              }
            }
        end
        
      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Invalid pipeline ID: #{reason}"
        }
    end
  end

  defp handle_get_pipeline_metrics(_params) do
    stats = PipelineManager.get_manager_stats()
    
    %{
      "status" => "success",
      "metrics" => %{
        "active_pipeline_count" => stats.active_pipeline_count,
        "total_pipelines_created" => stats.total_pipelines_created,
        "pipeline_ids" => stats.pipeline_ids
      }
    }
  end

  defp handle_schedule_activities(params) do
    # Updated to use Membrane pipeline instead of direct scheduler call
    topology = String.to_atom(params["pipeline_topology"] || "full_pipeline")
    
    case PipelineManager.create_testing_pipeline(topology) do
      {:ok, pipeline_pid} ->
        # Send MCP request through pipeline
        case PipelineManager.send_request_to_pipeline(pipeline_pid, params) do
          :ok ->
            %{
              "status" => "processing",
              "pipeline_id" => inspect(pipeline_pid),
              "topology" => Atom.to_string(topology),
              "message" => "Request sent to Membrane pipeline for processing",
              "schedule" => [],  # Will be populated by pipeline response
              "analysis" => %{},
              "resource_utilization" => %{},
              "timeline" => [],
              "simulation_metadata" => %{
                "pipeline_based" => true,
                "topology" => topology
              }
            }
            
          {:error, reason} ->
            %{
              "status" => "error",
              "error" => "Failed to send request to pipeline: #{inspect(reason)}"
            }
        end

      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Failed to create pipeline: #{inspect(reason)}"
        }
    end
  end

  defp handle_list_active_pipelines(_params) do
    pipelines = PipelineManager.list_active_pipelines()
    
    formatted_pipelines = Enum.map(pipelines, fn pipeline ->
      %{
        "id" => pipeline.id,
        "pid" => inspect(pipeline.pid),
        "topology" => Atom.to_string(pipeline.topology),
        "status" => Atom.to_string(pipeline.status),
        "created_at" => DateTime.to_iso8601(pipeline.created_at),
        "request_count" => pipeline.request_count
      }
    end)
    
    %{
      "status" => "success",
      "pipelines" => formatted_pipelines,
      "count" => length(formatted_pipelines)
    }
  end

  defp handle_send_pipeline_request(params) do
    pipeline_id = params["pipeline_id"]
    request_params = params["request"] || %{}
    
    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        case PipelineManager.send_request_to_pipeline(pipeline_pid, request_params) do
          :ok ->
            %{
              "status" => "success",
              "pipeline_id" => pipeline_id,
              "message" => "Request sent successfully"
            }
            
          {:error, reason} ->
            %{
              "status" => "error",
              "error" => "Failed to send request: #{inspect(reason)}"
            }
        end
        
      {:error, reason} ->
        %{
          "status" => "error",
          "error" => "Invalid pipeline ID: #{reason}"
        }
    end
  end

  # Helper functions

  defp parse_elements(elements) do
    Enum.map(elements, fn element ->
      %{
        type: String.to_atom(element["type"]),
        id: String.to_atom(element["id"]),
        config: element["config"] || %{}
      }
    end)
  end

  defp parse_connections(connections) do
    Enum.map(connections, fn conn ->
      %{
        from: {String.to_atom(conn["from"]["element"]), String.to_atom(conn["from"]["pad"])},
        to: {String.to_atom(conn["to"]["element"]), String.to_atom(conn["to"]["pad"])}
      }
    end)
  end

  defp parse_pipeline_pid(pipeline_id) when is_binary(pipeline_id) do
    try do
      # Parse PID from string representation
      case Regex.run(~r/#PID<(.+)>/, pipeline_id) do
        [_, pid_string] ->
          # This is a simplified approach - in production you'd want
          # a more robust PID tracking system
          {:ok, :erlang.list_to_pid('<' ++ String.to_charlist(pid_string) ++ '>')}
          
        nil ->
          {:error, "Invalid PID format"}
      end
    rescue
      _ ->
        {:error, "Failed to parse PID"}
    end
  end

  defp parse_pipeline_pid(_), do: {:error, "Pipeline ID must be a string"}

  defp validate_element_config(element_type, config) do
    case element_type do
      "MCPSource" -> validate_mcp_source_config(config)
      "EchoFilter" -> validate_echo_filter_config(config)
      "ScheduleFilter" -> validate_schedule_filter_config(config)
      "ResponseFilter" -> validate_response_filter_config(config)
      "MCPSink" -> validate_mcp_sink_config(config)
      _ -> {:error, "Unknown element type: #{element_type}"}
    end
  end

  defp validate_mcp_source_config(_config), do: :ok
  defp validate_echo_filter_config(_config), do: :ok
  defp validate_schedule_filter_config(_config), do: :ok
  defp validate_response_filter_config(_config), do: :ok
  defp validate_mcp_sink_config(_config), do: :ok

  # Tool descriptions

  defp get_tool_description(:configure_pipeline_layout) do
    "Configure and create a new Membrane pipeline with specified topology and elements"
  end

  defp get_tool_description(:setup_element_config) do
    "Validate and setup configuration for pipeline elements"
  end

  defp get_tool_description(:start_planning_pipeline) do
    "Start a new planning pipeline with predefined topology"
  end

  defp get_tool_description(:stop_planning_pipeline) do
    "Stop an active planning pipeline"
  end

  defp get_tool_description(:get_pipeline_status) do
    "Get detailed status information for a specific pipeline"
  end

  defp get_tool_description(:get_pipeline_metrics) do
    "Get overall metrics for the pipeline manager"
  end

  defp get_tool_description(:schedule_activities) do
    "Schedule activities using Membrane pipeline architecture with multiple strategy options"
  end

  defp get_tool_description(:list_active_pipelines) do
    "List all currently active pipelines"
  end

  defp get_tool_description(:send_pipeline_request) do
    "Send a request to a specific active pipeline"
  end

  # Input schemas

  def get_input_schema(:configure_pipeline_layout) do
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

  def get_input_schema(:setup_element_config) do
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

  def get_input_schema(:start_planning_pipeline) do
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

  def get_input_schema(:stop_planning_pipeline) do
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

  def get_input_schema(:get_pipeline_status) do
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

  def get_input_schema(:get_pipeline_metrics) do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  def get_input_schema(:schedule_activities) do
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

  def get_input_schema(:list_active_pipelines) do
    %{
      "type" => "object",
      "properties" => %{},
      "description" => "No parameters required"
    }
  end

  def get_input_schema(:send_pipeline_request) do
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
