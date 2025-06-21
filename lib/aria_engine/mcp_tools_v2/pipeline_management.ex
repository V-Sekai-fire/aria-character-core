# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPToolsV2.PipelineManagement do
  @moduledoc """
  Pipeline management tools for MCP interface.
  
  Handles pipeline creation, configuration, status monitoring, and lifecycle management.
  """

  require Logger
  alias AriaEngine.Membrane.PipelineManager

  @type pipeline_config :: %{
          topology: atom(),
          elements: [map()],
          connections: [map()],
          supervision_strategy: atom()
        }

  @type pipeline_status :: %{
          status: String.t(),
          pipeline_id: String.t(),
          message: String.t()
        }

  @doc """
  Configure and create a new Membrane pipeline with specified topology and elements.
  """
  @spec handle_configure_pipeline_layout(map()) :: map()
  def handle_configure_pipeline_layout(params) do
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

  @doc """
  Validate and setup configuration for pipeline elements.
  """
  @spec handle_setup_element_config(map()) :: map()
  def handle_setup_element_config(params) do
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

  @doc """
  Start a new planning pipeline with predefined topology.
  """
  @spec handle_start_planning_pipeline(map()) :: map()
  def handle_start_planning_pipeline(params) do
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

  @doc """
  Stop an active planning pipeline.
  """
  @spec handle_stop_planning_pipeline(map()) :: map()
  def handle_stop_planning_pipeline(params) do
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

  @doc """
  Get detailed status information for a specific pipeline.
  """
  @spec handle_get_pipeline_status(map()) :: map()
  def handle_get_pipeline_status(params) do
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

  @doc """
  Get overall metrics for the pipeline manager.
  """
  @spec handle_get_pipeline_metrics(map()) :: map()
  def handle_get_pipeline_metrics(_params) do
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

  @doc """
  List all currently active pipelines.
  """
  @spec handle_list_active_pipelines(map()) :: map()
  def handle_list_active_pipelines(_params) do
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

  @doc """
  Send a request to a specific active pipeline.
  """
  @spec handle_send_pipeline_request(map()) :: map()
  def handle_send_pipeline_request(params) do
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

  @spec parse_elements([map()]) :: [map()]
  defp parse_elements(elements) do
    Enum.map(elements, fn element ->
      %{
        type: String.to_atom(element["type"]),
        id: String.to_atom(element["id"]),
        config: element["config"] || %{}
      }
    end)
  end

  @spec parse_connections([map()]) :: [map()]
  defp parse_connections(connections) do
    Enum.map(connections, fn conn ->
      %{
        from: {String.to_atom(conn["from"]["element"]), String.to_atom(conn["from"]["pad"])},
        to: {String.to_atom(conn["to"]["element"]), String.to_atom(conn["to"]["pad"])}
      }
    end)
  end

  @spec parse_pipeline_pid(String.t()) :: {:ok, pid()} | {:error, String.t()}
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

  @spec validate_element_config(String.t(), map()) :: :ok | {:error, String.t()}
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

  @spec validate_mcp_source_config(map()) :: :ok
  defp validate_mcp_source_config(_config), do: :ok

  @spec validate_echo_filter_config(map()) :: :ok
  defp validate_echo_filter_config(_config), do: :ok

  @spec validate_schedule_filter_config(map()) :: :ok
  defp validate_schedule_filter_config(_config), do: :ok

  @spec validate_response_filter_config(map()) :: :ok
  defp validate_response_filter_config(_config), do: :ok

  @spec validate_mcp_sink_config(map()) :: :ok
  defp validate_mcp_sink_config(_config), do: :ok
end
