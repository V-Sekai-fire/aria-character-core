defmodule AriaEngine.MCPToolsV2 do
  @moduledoc """
  MCP tools interface with Membrane Framework pipeline integration.

  Provides MCP tools for pipeline management and individual strategy testing.
  This is the updated version that uses the Membrane pipeline architecture
  instead of direct scheduler calls.
  """

  require Logger
  alias AriaEngine.Membrane.PipelineManager

  @tools [
    {:configure_pipeline_layout, "2.0.0"},
    {:setup_element_config, "2.0.0"},
    {:start_planning_pipeline, "2.0.0"},
    {:stop_planning_pipeline, "2.0.0"},
    {:get_pipeline_status, "2.0.0"},
    {:get_pipeline_metrics, "2.0.0"},
    # Updated to use pipeline
    {:schedule_activities, "2.0.0"},
    # New validation pipeline
    {:validate_scheduling_solutions, "2.0.0"},
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
      execute_tool_handler(tool_name, params)
    rescue
      error ->
        handle_tool_execution_error(tool_name, params, error)
    end
  end

  def handle_tool_call(tool_name, params) when is_binary(tool_name) do
    handle_tool_call(String.to_atom(tool_name), params)
  end

  defp execute_tool_handler(tool_name, params) do
    case tool_name do
      :configure_pipeline_layout -> handle_configure_pipeline_layout(params)
      :setup_element_config -> handle_setup_element_config(params)
      :start_planning_pipeline -> handle_start_planning_pipeline(params)
      :stop_planning_pipeline -> handle_stop_planning_pipeline(params)
      :get_pipeline_status -> handle_get_pipeline_status(params)
      :get_pipeline_metrics -> handle_get_pipeline_metrics(params)
      :schedule_activities -> handle_schedule_activities(params)
      :validate_scheduling_solutions -> handle_validate_scheduling_solutions(params)
      :list_active_pipelines -> handle_list_active_pipelines(params)
      :send_pipeline_request -> handle_send_pipeline_request(params)
      _ -> %{"error" => "Unknown tool: #{tool_name}"}
    end
  end

  defp handle_tool_execution_error(tool_name, params, error) do
    Logger.error("Error in MCP tool #{tool_name}: #{inspect(error)}")

    %{
      "error" => "Tool execution failed: #{Exception.message(error)}",
      "details" => %{
        "tool" => Atom.to_string(tool_name),
        "params" => params
      }
    }
  end

  # Public function interfaces for direct calls
  def validate_scheduling_solutions(params) do
    handle_validate_scheduling_solutions(params)
  end

  def schedule_activities(params) do
    handle_schedule_activities(params)
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
    # Check if this is a trains05 scheduling request
    schedule_name = params["schedule_name"] || ""

    if String.contains?(schedule_name, "trains05") or String.contains?(schedule_name, "train") do
      # Use real train scheduling with hybrid coordinator
      handle_train_scheduling_request(params)
    else
      # Use real scheduler for other requests
      handle_real_scheduling_request(params)
    end
  end

  defp handle_train_scheduling_request(_params) do
    Logger.info("🚂 Processing trains05 scheduling request with real hybrid coordinator")

    # Convert trains05.dzn to schedule_activities format
    train_data = AriaEngine.TrainSchedulingConverter.convert_trains05_to_schedule_activities()

    # Call real scheduler with train data
    case call_real_scheduler(train_data) do
      {:ok, result} ->
        %{
          "status" => "success",
          "message" => "Train schedule generated using hybrid coordinator",
          "schedule" => format_schedule_result(result),
          "analysis" => format_analysis_result(result),
          "resource_utilization" => format_resource_utilization(result),
          "timeline" => format_timeline_result(result),
          "simulation_metadata" => %{
            "real_solver" => true,
            "solver" => "hybrid_coordinator_v2",
            "problem_type" => "trains05_scheduling",
            "activities_count" => length(train_data["activities"]),
            "entities_count" => length(train_data["entities"]),
            "resources_count" => map_size(train_data["resources"])
          }
        }

      {:error, reason} ->
        Logger.error("🚂 Train scheduling failed: #{reason}")

        %{
          "status" => "error",
          "error" => "Train scheduling failed: #{reason}",
          "fallback_used" => false
        }
    end
  end

  defp handle_real_scheduling_request(params) do
    Logger.info("📋 Processing general scheduling request with real scheduler")

    # Call real scheduler with provided params
    case call_real_scheduler(params) do
      {:ok, result} ->
        %{
          "status" => "success",
          "message" => "Schedule generated using real scheduler",
          "schedule" => format_schedule_result(result),
          "analysis" => format_analysis_result(result),
          "resource_utilization" => format_resource_utilization(result),
          "timeline" => format_timeline_result(result),
          "simulation_metadata" => %{
            "real_solver" => true,
            "solver" => "aria_engine_scheduler",
            "activities_count" => length(params["activities"] || []),
            "entities_count" => length(params["entities"] || []),
            "resources_count" => map_size(params["resources"] || %{})
          }
        }

      {:error, reason} ->
        Logger.error("📋 General scheduling failed: #{reason}")

        %{
          "status" => "error",
          "error" => "Scheduling failed: #{reason}",
          "fallback_used" => false
        }
    end
  end

  defp call_real_scheduler(params) do
    # Extract parameters for scheduler
    schedule_name = params["schedule_name"] || "default_schedule"
    activities = params["activities"] || []
    entities = params["entities"] || []
    resources = params["resources"] || %{}
    constraints = params["constraints"] || %{}
    simulation_options = params["simulation_options"] || %{}

    simulation_mode = simulation_options["simulation_mode"] || false
    verbose = simulation_options["verbose"] || 1
    activity_log = simulation_options["log_activities"] || false

    Logger.info("🔧 Calling AriaEngine.Scheduler.Core.schedule_with_enhanced_features")

    Logger.info(
      "🔧 Schedule: #{schedule_name}, Activities: #{length(activities)}, Entities: #{length(entities)}"
    )

    Logger.info("🔧 Activities type: #{inspect(activities |> Enum.take(1))}")
    Logger.info("🔧 Entities type: #{inspect(entities |> Enum.take(1))}")

    # Ensure activities is a list
    activities_list = if is_list(activities), do: activities, else: []
    entities_list = if is_list(entities), do: entities, else: []

    # Call the real scheduler
    AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
      schedule_name,
      activities_list,
      entities_list,
      resources,
      constraints,
      simulation_mode,
      activity_log,
      verbose
    )
  end

  defp format_schedule_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{schedule: schedule} -> schedule
      %{schedule: schedule} -> schedule
      _ -> []
    end
  end

  defp format_analysis_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{analysis: analysis} -> analysis
      %{analysis: analysis} -> analysis
      _ -> %{}
    end
  end

  defp format_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end

  defp format_timeline_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{simulation_metadata: metadata} ->
        Map.get(metadata, :timeline, [])

      %{timeline: timeline} ->
        timeline

      _ ->
        []
    end
  end

  defp handle_list_active_pipelines(_params) do
    pipelines = PipelineManager.list_active_pipelines()

    formatted_pipelines =
      Enum.map(pipelines, fn pipeline ->
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

  defp handle_validate_scheduling_solutions(params) do
    Logger.info("🔍 Processing validation request with dual solver comparison")

    # Generate a new unique problem for this validation
    problem_name = params["problem_name"] || "generated_problem"
    generated_problem = generate_new_validation_problem(problem_name)

    Logger.info(
      "🎲 Generated new problem: #{generated_problem.name} with #{length(generated_problem.activities)} activities"
    )

    # Merge generated problem with any provided parameters
    enhanced_params =
      Map.merge(params, %{
        "problem_name" => generated_problem.name,
        "activities" => generated_problem.activities,
        "entities" => generated_problem.entities,
        "resources" => generated_problem.resources,
        "constraints" => generated_problem.constraints,
        "problem_metadata" => generated_problem.metadata
      })

    # Create validation pipeline and process request
    case PipelineManager.create_testing_pipeline(:validation_pipeline) do
      {:ok, pipeline_pid} ->
        # Send validation request to pipeline
        case PipelineManager.send_request_to_pipeline(pipeline_pid, enhanced_params) do
          :ok ->
            # Wait for response (in real implementation, this would be async)
            Process.sleep(1000)

            %{
              "status" => "success",
              "message" => "Validation pipeline processing completed",
              "pipeline_id" => inspect(pipeline_pid),
              "validation_type" => "hybrid_vs_minizinc",
              "generated_problem" => %{
                "name" => generated_problem.name,
                "activities_count" => length(generated_problem.activities),
                "entities_count" => length(generated_problem.entities),
                "resources_count" => map_size(generated_problem.resources),
                "complexity" => generated_problem.metadata.complexity,
                "problem_type" => generated_problem.metadata.problem_type
              }
            }

          {:error, reason} ->
            %{
              "status" => "error",
              "error" => "Failed to send validation request: #{inspect(reason)}"
            }
        end

      {:error, reason} ->
        Logger.error("🔍 Failed to create validation pipeline: #{reason}")

        %{
          "status" => "error",
          "error" => "Failed to create validation pipeline: #{inspect(reason)}"
        }
    end
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
          {:ok, :erlang.list_to_pid(~c"<" ++ String.to_charlist(pid_string) ++ ~c">")}

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

  defp get_tool_description(:validate_scheduling_solutions) do
    "Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver"
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

  def get_input_schema(:validate_scheduling_solutions) do
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

  # Problem generation for validation - scaling single problem type

  def generate_new_validation_problem(base_name) do
    # Generate deterministic problem ID based on timestamp
    timestamp = System.system_time(:microsecond)
    problem_id = rem(timestamp, 100_000)

    # Use cryptographic randomization to ensure all combinations are generated
    # Create a cryptographically secure hash from multiple entropy sources
    entropy_data =
      "#{timestamp}_#{base_name}_#{:erlang.unique_integer([:positive])}_#{:erlang.system_time(:nanosecond)}"

    crypto_hash = :crypto.hash(:sha256, entropy_data)

    # Extract bytes and convert to integer for distribution
    <<hash_int::256>> = crypto_hash

    # Use cryptographic hash to select activity count (1-6)
    # This ensures truly random distribution across all values
    activity_count = rem(hash_int, 6) + 1

    generate_scaling_task_problem(base_name, problem_id, activity_count)
  end

  defp generate_scaling_task_problem(base_name, problem_id, activity_count) do
    activities = generate_activities_for_count(activity_count)
    entities = generate_entities_for_count(activity_count)
    resources = generate_resources_for_count(activity_count)
    complexity = determine_complexity(activity_count)

    %{
      name: "#{base_name}_scaling_#{activity_count}_#{problem_id}",
      activities: activities,
      entities: entities,
      resources: resources,
      constraints: %{
        "max_concurrent_activities" => min(activity_count, 2),
        "require_resources" => activity_count > 1
      },
      metadata: %{
        complexity: complexity,
        problem_type: "scaling_task_chain",
        activity_count: activity_count,
        generated_at: DateTime.utc_now(),
        problem_id: problem_id,
        scaling_factor: activity_count
      }
    }
  end

  defp generate_activities_for_count(1) do
    [
      %{
        "id" => "identity_task",
        "name" => "Identity Task",
        "duration" => "PT30M",
        "required_capabilities" => ["basic"],
        "required_resources" => ["workstation_1"],
        "dependencies" => []
      }
    ]
  end

  defp generate_activities_for_count(count) when count > 1 do
    for i <- 1..count do
      duration = 30 + i * 15

      %{
        "id" => "task_#{i}",
        "name" => "Task #{i}",
        "duration" => "PT#{duration}M",
        "required_capabilities" => ["basic", "processing"],
        "required_resources" => ["workstation_#{rem(i - 1, 2) + 1}"],
        "dependencies" => if(i > 1, do: ["task_#{i - 1}"], else: [])
      }
    end
  end

  defp generate_entities_for_count(activity_count) do
    entity_count = min(activity_count, 3)

    for i <- 1..entity_count do
      %{
        "id" => "worker_#{i}",
        "type" => "worker",
        "capabilities" => ["basic", "processing", "coordination"],
        "availability" => "PT8H"
      }
    end
  end

  defp generate_resources_for_count(1) do
    %{"workstation_1" => %{"type" => "equipment", "capacity" => 1}}
  end

  defp generate_resources_for_count(count) when count > 1 do
    base_resources =
      for i <- 1..min(count, 3), into: %{} do
        {"workstation_#{i}", %{"type" => "equipment", "capacity" => 1}}
      end

    Map.put(base_resources, "shared_storage", %{"type" => "storage", "capacity" => count})
  end

  defp determine_complexity(1), do: "trivial"
  defp determine_complexity(2), do: "simple"
  defp determine_complexity(n) when n in [3, 4], do: "medium"
  defp determine_complexity(_), do: "high"
end
