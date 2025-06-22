# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Aria.Pipeline do
  @moduledoc """
  Manage AriaEngine processing pipelines.

  ## Usage

      mix aria.pipeline start --topology echo_pipeline
      mix aria.pipeline status --id <pipeline_id>
      mix aria.pipeline list
      mix aria.pipeline stop --id <pipeline_id>
      mix aria.pipeline --help

  ## Commands

    * `start` - Start a new pipeline
    * `stop` - Stop an existing pipeline
    * `status` - Get pipeline status
    * `list` - List all active pipelines
    * `send` - Send request to pipeline
    * `metrics` - Get pipeline manager metrics

  ## Options

    * `--topology` - Pipeline topology (echo_pipeline, full_pipeline)
    * `--id` - Pipeline ID for operations
    * `--request` - JSON request data for send command
    * `--config` - Configuration file for custom pipelines
    * `--help` - Show this help

  ## Examples

      # Start an echo pipeline
      mix aria.pipeline start --topology echo_pipeline

      # List all active pipelines
      mix aria.pipeline list

      # Get pipeline status
      mix aria.pipeline status --id "#PID<0.123.0>"

      # Send request to pipeline
      mix aria.pipeline send --id "#PID<0.123.0>" --request '{"test": "data"}'

      # Stop a pipeline
      mix aria.pipeline stop --id "#PID<0.123.0>"
  """

  use Mix.Task
  require Logger

  @shortdoc "Manage AriaEngine processing pipelines"

  @switches [
    topology: :string,
    id: :string,
    request: :string,
    config: :string,
    help: :boolean
  ]

  @aliases [
    t: :topology,
    i: :id,
    r: :request,
    c: :config,
    h: :help
  ]

  def run(args) do
    {opts, argv, _errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    end

    # Start the application
    Mix.Task.run("app.start")

    case argv do
      ["start"] ->
        handle_start_pipeline(opts)

      ["stop"] ->
        handle_stop_pipeline(opts)

      ["status"] ->
        handle_pipeline_status(opts)

      ["list"] ->
        handle_list_pipelines(opts)

      ["send"] ->
        handle_send_request(opts)

      ["metrics"] ->
        handle_pipeline_metrics(opts)

      [] ->
        Mix.shell().error("Error: Command required")
        Mix.shell().info("Use --help for usage information")
        System.halt(1)

      [unknown] ->
        Mix.shell().error("Error: Unknown command '#{unknown}'")
        Mix.shell().info("Use --help for usage information")
        System.halt(1)
    end
  end

  defp handle_start_pipeline(opts) do
    topology = opts[:topology] || "echo_pipeline"
    topology_atom = String.to_atom(topology)

    Mix.shell().info("🚀 Starting pipeline with topology: #{topology}")

    case AriaEngine.Membrane.PipelineManager.create_testing_pipeline(topology_atom) do
      {:ok, pipeline_pid} ->
        Mix.shell().info("✅ Pipeline started successfully")
        Mix.shell().info("Pipeline ID: #{inspect(pipeline_pid)}")
        Mix.shell().info("Topology: #{topology}")

      {:error, reason} ->
        Mix.shell().error("❌ Failed to start pipeline: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp handle_stop_pipeline(opts) do
    unless opts[:id] do
      Mix.shell().error("Error: --id is required for stop command")
      System.halt(1)
    end

    pipeline_id = opts[:id]
    Mix.shell().info("🛑 Stopping pipeline: #{pipeline_id}")

    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        case AriaEngine.Membrane.PipelineManager.stop_pipeline(pipeline_pid) do
          :ok ->
            Mix.shell().info("✅ Pipeline stopped successfully")

          {:error, reason} ->
            Mix.shell().error("❌ Failed to stop pipeline: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        Mix.shell().error("❌ Invalid pipeline ID: #{reason}")
        System.halt(1)
    end
  end

  defp handle_pipeline_status(opts) do
    unless opts[:id] do
      Mix.shell().error("Error: --id is required for status command")
      System.halt(1)
    end

    pipeline_id = opts[:id]
    Mix.shell().info("📊 Getting status for pipeline: #{pipeline_id}")

    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        status = AriaEngine.Membrane.PipelineManager.get_pipeline_status(pipeline_pid)

        case status do
          %{error: error} ->
            Mix.shell().error("❌ Error getting status: #{error}")

          _ ->
            Mix.shell().info("✅ Pipeline Status:")
            Mix.shell().info("  ID: #{status.id}")
            Mix.shell().info("  Topology: #{status.topology}")
            Mix.shell().info("  Status: #{status.status}")
            Mix.shell().info("  Created: #{DateTime.to_iso8601(status.created_at)}")
            Mix.shell().info("  Request Count: #{status.request_count}")
            Mix.shell().info("  Uptime: #{status.uptime_seconds}s")
            Mix.shell().info("  Elements: #{status.element_count}")
        end

      {:error, reason} ->
        Mix.shell().error("❌ Invalid pipeline ID: #{reason}")
        System.halt(1)
    end
  end

  defp handle_list_pipelines(_opts) do
    Mix.shell().info("📋 Listing active pipelines...")

    pipelines = AriaEngine.Membrane.PipelineManager.list_active_pipelines()

    if length(pipelines) == 0 do
      Mix.shell().info("No active pipelines found")
    else
      Mix.shell().info("Found #{length(pipelines)} active pipeline(s):")

      Enum.each(pipelines, fn pipeline ->
        Mix.shell().info("")
        Mix.shell().info("  Pipeline ID: #{pipeline.id}")
        Mix.shell().info("  PID: #{inspect(pipeline.pid)}")
        Mix.shell().info("  Topology: #{pipeline.topology}")
        Mix.shell().info("  Status: #{pipeline.status}")
        Mix.shell().info("  Created: #{DateTime.to_iso8601(pipeline.created_at)}")
        Mix.shell().info("  Requests: #{pipeline.request_count}")
      end)
    end
  end

  defp handle_send_request(opts) do
    unless opts[:id] do
      Mix.shell().error("Error: --id is required for send command")
      System.halt(1)
    end

    unless opts[:request] do
      Mix.shell().error("Error: --request is required for send command")
      System.halt(1)
    end

    pipeline_id = opts[:id]
    request_json = opts[:request]

    Mix.shell().info("📤 Sending request to pipeline: #{pipeline_id}")

    # Parse request JSON
    request_params =
      case Jason.decode(request_json) do
        {:ok, data} ->
          data

        {:error, reason} ->
          Mix.shell().error("❌ Invalid JSON in request: #{inspect(reason)}")
          System.halt(1)
      end

    case parse_pipeline_pid(pipeline_id) do
      {:ok, pipeline_pid} ->
        case AriaEngine.Membrane.PipelineManager.send_request_to_pipeline(
               pipeline_pid,
               request_params
             ) do
          :ok ->
            Mix.shell().info("✅ Request sent successfully")

          {:error, reason} ->
            Mix.shell().error("❌ Failed to send request: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        Mix.shell().error("❌ Invalid pipeline ID: #{reason}")
        System.halt(1)
    end
  end

  defp handle_pipeline_metrics(_opts) do
    Mix.shell().info("📈 Getting pipeline manager metrics...")

    stats = AriaEngine.Membrane.PipelineManager.get_manager_stats()

    Mix.shell().info("✅ Pipeline Manager Metrics:")
    Mix.shell().info("  Active Pipelines: #{stats.active_pipeline_count}")
    Mix.shell().info("  Total Created: #{stats.total_pipelines_created}")

    if length(stats.pipeline_ids) > 0 do
      Mix.shell().info("  Pipeline IDs:")

      Enum.each(stats.pipeline_ids, fn id ->
        Mix.shell().info("    - #{id}")
      end)
    else
      Mix.shell().info("  No active pipelines")
    end
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
end
