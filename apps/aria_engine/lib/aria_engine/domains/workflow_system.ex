# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domains.WorkflowSystem do
  @moduledoc """
  Workflow system domain that integrates AriaEngine planning with AriaWorkflow execution.

  This domain provides actions and methods for managing workflow lifecycles,
  including planning, execution, monitoring, and error handling.
  """

  require Logger
  alias AriaEngine.{Domain, Actions, State}

  @doc """
  Creates a workflow system domain with integrated actions.
  """
  def create_domain do
    Domain.new("workflow_system")
    |> Domain.add_actions(%{
      execute_workflow_command: &execute_workflow_command/2,
      trace_workflow_execution: &trace_workflow_execution/2,
      monitor_workflow_progress: &monitor_workflow_progress/2,
      execute_command: &Actions.execute_command/2,
      echo: &Actions.echo/2,
      wait: &Actions.wait/2
    })
    |> Domain.add_task_methods("execute_workflow", [
      &execute_workflow_with_monitoring/2,
      &execute_workflow_simple/2
    ])
    |> Domain.add_task_methods("debug_workflow", [
      &debug_with_tracing/2,
      &debug_with_logging/2
    ])
    |> Domain.add_unigoal_method("workflow_completed", &ensure_workflow_completed/2)
    |> Domain.add_unigoal_method("command_executed", &ensure_command_executed/2)
  end

  # Action implementations for workflow operations

  @doc """
  Execute a workflow command using the workflow engine.
  [DEPRECATED] This function uses deprecated WorkflowRegistry/WorkflowEngine.
  Use AriaEngine.DomainDefinition instead.
  """
  def execute_workflow_command(state, [workflow_id | _workflow_args]) do
    Logger.warning("execute_workflow_command is deprecated. Use AriaEngine.DomainDefinition instead.")

    # Simplified implementation that just logs the attempt
    state
    |> State.set_object("workflow_result", workflow_id, "deprecated")
    |> State.set_object("workflow_message", workflow_id, "Use DomainDefinition instead")
  end

  @doc """
  Trace workflow execution with detailed logging.
  """
  def trace_workflow_execution(state, [workflow_id]) do
    case State.get_object(state, "workflow_execution", workflow_id) do
      nil ->
        Logger.warning("No execution found for workflow: #{workflow_id}")
        false

      execution ->
        # Extract trace information
        trace_log = if is_map(execution) && Map.has_key?(execution, :spans) do
          execution.spans
          |> Enum.map(fn span ->
            "Span: #{span.name} (#{span.duration_ms || 0}ms)"
          end)
          |> Enum.join("; ")
        else
          "No trace data available"
        end

        state
        |> State.set_object("workflow_trace", workflow_id, trace_log)
    end
  end

  @doc """
  Monitor workflow progress and report status.
  """
  def monitor_workflow_progress(state, [workflow_id]) do
    case State.get_object(state, "workflow_execution", workflow_id) do
      nil ->
        state
        |> State.set_object("workflow_status", workflow_id, "not_found")

      execution ->
        status = if is_map(execution) && Map.has_key?(execution, :status) do
          execution.status
        else
          "unknown"
        end

        state
        |> State.set_object("workflow_status", workflow_id, status)
    end
  end

  # Task methods that decompose workflow operations

  @doc """
  Execute workflow with comprehensive monitoring.
  """
  def execute_workflow_with_monitoring(_state, [workflow_id]) do
    [
      {:echo, ["Starting workflow: #{workflow_id}"]},
      {:execute_workflow_command, [workflow_id]},
      {:trace_workflow_execution, [workflow_id]},
      {:monitor_workflow_progress, [workflow_id]},
      {:echo, ["Workflow completed: #{workflow_id}"]}
    ]
  end

  @doc """
  Execute workflow with minimal overhead.
  """
  def execute_workflow_simple(_state, [workflow_id]) do
    [
      {:execute_workflow_command, [workflow_id]}
    ]
  end

  @doc """
  Debug workflow with detailed tracing.
  """
  def debug_with_tracing(_state, [workflow_id]) do
    [
      {:echo, ["Debugging workflow: #{workflow_id}"]},
      {:execute_workflow_command, [workflow_id]},
      {:trace_workflow_execution, [workflow_id]},
      {:echo, ["Debug trace completed for: #{workflow_id}"]}
    ]
  end

  @doc """
  Debug workflow with enhanced logging.
  """
  def debug_with_logging(_state, [workflow_id]) do
    [
      {:echo, ["Starting debug session for: #{workflow_id}"]},
      {:execute_workflow_command, [workflow_id]},
      {:monitor_workflow_progress, [workflow_id]},
      {:echo, ["Debug session completed for: #{workflow_id}"]}
    ]
  end

  # Unigoal methods for achieving workflow states

  @doc """
  Ensure a workflow is completed successfully.
  """
  def ensure_workflow_completed(state, [predicate, subject, object]) do
    if predicate == "workflow_completed" and object == true do
      case State.get_object(state, "workflow_result", subject) do
        "success" -> []  # Already completed
        _ -> [
          {"execute_workflow", [subject]}
        ]
      end
    else
      false
    end
  end

  @doc """
  Ensure a command is executed.
  """
  def ensure_command_executed(state, [predicate, subject, object]) do
    if predicate == "command_executed" and object == true do
      case State.get_object(state, "last_command", "command") do
        ^subject -> []  # Command already executed
        _ -> [
          {:execute_command, [subject]}
        ]
      end
    else
      false
    end
  end

  # Task methods for workflow operations

  @doc """
  Execute a traced command with monitoring.
  """
  def execute_traced_command(_state, [command, args, workflow_id]) do
    [
      {:execute_command, [command, args, %{
        timeout: 60_000,
        env: %{"WORKFLOW_ID" => workflow_id},
        fail_on_error: false
      }]}
    ]
  end

  @doc """
  Deploy a service with standard deployment steps.
  """
  def deploy_service(_state, [service_name]) do
    [
      {:echo, ["Deploying service: #{service_name}"]},
      {:execute_command, ["docker", "build", "-t", service_name, "."]},
      {:execute_command, ["docker", "push", service_name]},
      {:echo, ["Service #{service_name} deployed successfully"]}
    ]
  end

  @doc """
  Run database migrations.
  """
  def run_migrations(_state, []) do
    [
      {:echo, ["Running database migrations"]},
      {:execute_command, ["mix", "ecto.migrate"]},
      {:echo, ["Database migrations completed"]}
    ]
  end

  @doc """
  Set up development environment.
  """
  def setup_dev_environment(_state, [project_path]) do
    [
      {:echo, ["Setting up development environment at #{project_path}"]},
      {:execute_command, ["mix", "deps.get"]},
      {:execute_command, ["mix", "compile"]},
      {:echo, ["Development environment setup complete"]}
    ]
  end

  def setup_dev_environment(_state, [project_path, services]) when is_list(services) do
    docker_commands = Enum.map(services, fn service ->
      {:execute_command, ["docker", ["run", "-d", "--name", service, service], %{}]}
    end)

    [
      {:create_directory, [project_path, %{parents: true}]},
      {:execute_command, ["git", ["init"], %{working_dir: project_path}]}
    ] ++ docker_commands
  end

  @doc """
  Run tests with coverage analysis.
  """
  def run_tests_with_coverage(_state, []) do
    [
      {:execute_command, ["mix", "test", "--cover"]},
      {:execute_command, ["mix", "coveralls.html"]}
    ]
  end

  def run_tests_with_coverage(_state, [project_path]) do
    [
      {:echo, ["Running tests with coverage in #{project_path}"]},
      {:execute_command, ["mix", "test", "--cover"]},
      {:echo, ["Test coverage analysis complete"]}
    ]
  end

  def run_tests_with_coverage(_state, [project_path, _test_command]) do
    [
      {:execute_command, ["mix", ["test", "--cover"], %{
        working_dir: project_path,
        env: %{"MIX_ENV" => "test"}
      }]},
      {:execute_command, ["mix", ["coveralls.html"], %{
        working_dir: project_path,
        fail_on_error: false
      }]}
    ]
  end

  @doc """
  Build and package the application.
  """
  def build_and_package(_state, [app_name]) do
    [
      {:echo, ["Building and packaging #{app_name}"]},
      {:execute_command, ["mix", "release", app_name]},
      {:echo, ["Application #{app_name} built and packaged"]}
    ]
  end

  def build_and_package(_state, [project_path, package_format]) do
    case package_format do
      "docker" ->
        project_name = Path.basename(project_path)
        [
          {:execute_command, ["docker", ["build", "-t", "#{project_name}:latest", "."], %{
            working_dir: project_path
          }]}
        ]
      "release" ->
        [
          {:execute_command, ["mix", ["deps.get"], %{working_dir: project_path}]},
          {:execute_command, ["mix", ["compile"], %{working_dir: project_path}]},
          {:execute_command, ["mix", ["release"], %{
            working_dir: project_path,
            env: %{"MIX_ENV" => "prod"}
          }]}
        ]
      _ ->
        [
          {:execute_command, ["mix", "release"]}
        ]
    end
  end

  @doc """
  Monitor system health with basic checks.
  """
  def monitor_system_health(_state, []) do
    [
      {:execute_command, ["ps", "aux"]},
      {:execute_command, ["df", "-h"]}
    ]
  end

  def monitor_system_health(_state, [services]) when is_list(services) do
    service_checks = Enum.map(services, fn service ->
      {:echo, ["Checking service: #{service}"]}
    end)

    service_checks ++ [
      {:execute_command, ["ps", "aux"]},
      {:execute_command, ["df", "-h"]},
      {:echo, ["System health check complete for services: #{Enum.join(services, ", ")}"]}
    ]
  end

  def monitor_system_health(_state, [services, health_checks]) when is_list(services) and is_map(health_checks) do
    Enum.map(services, fn service ->
      case Map.get(health_checks, service) do
        %{"type" => "http", "url" => url} ->
          {:execute_command, ["curl", ["-f", "-s", url], %{}]}
        %{"type" => "tcp", "host" => host, "port" => port} ->
          {:execute_command, ["nc", ["-z", host, to_string(port)], %{}]}
        _ ->
          {:execute_command, ["echo", ["No health check defined for #{service}"], %{}]}
      end
    end)
  end

  @doc """
  Backup system data to specified location.
  """
  def backup_system_data(_state, [backup_path]) do
    [
      {:echo, ["Backing up system data to #{backup_path}"]},
      {:execute_command, ["tar", "-czf", backup_path, "/var/lib/data"]},
      {:echo, ["System data backup complete"]}
    ]
  end

  @doc """
  Restore system data from backup.
  """
  def restore_system_data(_state, [backup_path]) do
    [
      {:echo, ["Restoring system data from #{backup_path}"]},
      {:execute_command, ["tar", "-xzf", backup_path, "-C", "/var/lib"]},
      {:echo, ["System data restoration complete"]}
    ]
  end
end
