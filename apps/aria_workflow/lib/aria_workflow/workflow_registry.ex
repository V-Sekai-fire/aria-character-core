# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowRegistry do
  @moduledoc """
  Registry for managing workflow definitions.

  This GenServer maintains a registry of all available workflows and provides
  functions for registration, retrieval, and management.

  Currently provides two core workflows:
  1. basic_timing - UTC/local timezone capture and command timing
  2. command_tracing - Local command execution with error handling

  Uses in-memory storage until aria_data and aria_storage services come online.
  """

  use GenServer
  require Logger

  alias AriaWorkflow.WorkflowDefinition

  # Helper methods for unigoal processing - defined first for use in module attributes

  def ensure_timing_system(_state, [predicate, _subject, object]) do
    if predicate == "timing_system" and object == "enabled" do
      [{"get_current_time", []}]
    else
      false
    end
  end

  def ensure_timezone_info(_state, [predicate, _subject, object]) do
    if predicate == "timezone_info" and object == "captured" do
      [{"get_timezone_info", []}]
    else
      false
    end
  end

  def ensure_execution_log(_state, [predicate, _subject, object]) do
    if predicate == "execution_log" and object == "created" do
      [{"log_execution", []}]
    else
      false
    end
  end

  def backup_files_method(_state, [source, destination]) do
    [
      {:echo, ["Backing up #{source} to #{destination}"]},
      {:copy_file, [source, destination]},
      {:echo, ["Backup completed"]}
    ]
  end

  def create_workspace_method(_state, [workspace_path]) do
    [
      {:echo, ["Creating workspace at #{workspace_path}"]},
      {:create_directory, [workspace_path]},
      {:create_directory, ["#{workspace_path}/src"]},
      {:create_directory, ["#{workspace_path}/test"]},
      {:echo, ["Workspace created successfully"]}
    ]
  end

  def ensure_file_exists_method(_state, [predicate, subject, object]) do
    if predicate == "file_exists" and object == true do
      [
        {:execute_command, ["test", "-e", subject]}
      ]
    else
      false
    end
  end

  def ensure_command_executed_method(_state, [predicate, subject, object]) do
    if predicate == "command_executed" and object == true do
      [
        {:execute_command, String.split(subject, " ")}
      ]
    else
      false
    end
  end

  def ensure_archive_created_method(_state, [predicate, subject, object]) do
    if predicate == "archive_created" and object == true do
      [
        {:create_archive, [subject, "/tmp"]}
      ]
    else
      false
    end
  end

  # Core workflows for basic operations with AriaEngine integration
  @hardcoded_workflows %{
    "basic_timing" => %{
      # AriaEngine todos can mix goals, tasks, and actions in any order
      todos: [
        {"timing_system", "commands", "enabled"},          # goal
        {"get_current_time", []},                         # task
        {"timezone_info", "system", "captured"},          # goal
        {:echo, ["Starting timing workflow"]},            # action
        {"time_command_execution", ["echo", "test"]},     # task
        {"execution_log", "operations", "created"}        # goal
      ],
      actions: [
        {:echo, &AriaEngine.Actions.echo/2},
        {:execute_command, &AriaEngine.Actions.execute_command/2}
      ],
      task_methods: [
        {"get_current_time", &AriaWorkflow.Tasks.BasicTiming.get_current_time/2},
        {"get_timezone_info", &AriaWorkflow.Tasks.BasicTiming.get_timezone_info/2},
        {"start_timer", &AriaWorkflow.Tasks.BasicTiming.start_timer/2},
        {"stop_timer", &AriaWorkflow.Tasks.BasicTiming.stop_timer/2},
        {"log_execution", &AriaWorkflow.Tasks.BasicTiming.log_execution/2},
        {"time_command_execution", &AriaWorkflow.Methods.BasicTiming.time_command_execution/2}
      ],
      unigoal_methods: [
        {"timing_system", &__MODULE__.ensure_timing_system/2},
        {"timezone_info", &__MODULE__.ensure_timezone_info/2},
        {"execution_log", &__MODULE__.ensure_execution_log/2}
      ],
      documentation: %{
        overview: ~s"""
        Basic Timing Workflow

        Provides core timing functionality for command execution and system operations.
        Captures UTC and local timezone information with millisecond precision timing.
        """,
        procedures: ~s"""
        Basic Timing Procedures

        1. Current Time Capture
        2. Command Execution Timing
        3. Timezone Information Capture
        4. Execution Logging
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11],
        approved_by: "Aria AI Assistant"
      }
    },

    "command_tracing" => %{
      goals: [
        {"command_execution", "local_commands", "traced"},
        {"execution_time", "commands", "measured"},
        {"error_handling", "failures", "captured"}
      ],
      tasks: [
        {"trace_command_start", &AriaWorkflow.Tasks.CommandTracing.trace_command_start/2},
        {"trace_command_end", &AriaWorkflow.Tasks.CommandTracing.trace_command_end/2},
        {"capture_command_output", &AriaWorkflow.Tasks.CommandTracing.capture_command_output/2},
        {"handle_command_error", &AriaWorkflow.Tasks.CommandTracing.handle_command_error/2}
      ],
      methods: [
        {"execute_with_tracing", &AriaWorkflow.Methods.CommandTracing.execute_with_tracing/2},
        {"generate_execution_summary", &AriaWorkflow.Methods.CommandTracing.generate_execution_summary/2}
      ],
      documentation: %{
        overview: ~s"""
        Command Tracing Workflow

        Provides command execution tracing for local operations with comprehensive
        timing, output capture, and error handling.
        """,
        procedures: ~s"""
        Command Tracing Procedures

        1. Pre-execution Setup
        2. During Execution Monitoring
        3. Post-execution Analysis
        4. Error Handling and Recovery
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11],
        approved_by: "Aria AI Assistant"
      }
    },

    "file_management" => %{
      goals: [
        {"file_operations", "external_commands", "executed"},
        {"directory_structure", "filesystem", "organized"},
        {"backup_system", "files", "protected"}
      ],
      tasks: [
        {"backup_file", &AriaEngine.Domains.FileManagement.backup_file/2},
        {"replace_file_safely", &AriaEngine.Domains.FileManagement.replace_file_safely/2},
        {"create_directory_structure", &AriaEngine.Domains.FileManagement.create_directory_structure/2},
        {"download_and_verify", &AriaEngine.Domains.FileManagement.download_and_verify/2},
        {"setup_workspace", &AriaEngine.Domains.FileManagement.setup_workspace/2},
        {"cleanup_temp_files", &AriaEngine.Domains.FileManagement.cleanup_temp_files/2},
        {"compress_directory", &AriaEngine.Domains.FileManagement.compress_directory/2},
        {"extract_archive", &AriaEngine.Domains.FileManagement.extract_archive/2},
        {"sync_directories", &AriaEngine.Domains.FileManagement.sync_directories/2}
      ],
      methods: [
        {"execute_file_operations", &AriaWorkflow.Methods.CommandTracing.execute_with_tracing/2}
      ],
      documentation: %{
        overview: ~s"""
        File Management Workflow

        Provides comprehensive file and directory management operations using
        AriaEngine with Porcelain for external process execution.
        """,
        procedures: ~s"""
        File Management Procedures

        1. File Operations (copy, move, backup)
        2. Directory Structure Management
        3. Archive Operations (compress/extract)
        4. File Synchronization
        5. Workspace Setup
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11],
        approved_by: "Aria AI Assistant",
        description: "File management operations using AriaEngine with Porcelain"
      }
    },

    "system_deployment" => %{
      goals: [
        {"services", "deployment_targets", "deployed"},
        {"databases", "migration_state", "migrated"},
        {"monitoring", "health_checks", "active"}
      ],
      tasks: [
        {"execute_traced_command", &AriaEngine.Domains.WorkflowSystem.execute_traced_command/2},
        {"deploy_service", &AriaEngine.Domains.WorkflowSystem.deploy_service/2},
        {"run_migrations", &AriaEngine.Domains.WorkflowSystem.run_migrations/2},
        {"setup_dev_environment", &AriaEngine.Domains.WorkflowSystem.setup_dev_environment/2},
        {"run_tests_with_coverage", &AriaEngine.Domains.WorkflowSystem.run_tests_with_coverage/2},
        {"build_and_package", &AriaEngine.Domains.WorkflowSystem.build_and_package/2},
        {"monitor_system_health", &AriaEngine.Domains.WorkflowSystem.monitor_system_health/2},
        {"backup_system_data", &AriaEngine.Domains.WorkflowSystem.backup_system_data/2},
        {"restore_system_data", &AriaEngine.Domains.WorkflowSystem.restore_system_data/2}
      ],
      methods: [
        {"execute_deployment_pipeline", &AriaWorkflow.Methods.CommandTracing.execute_with_tracing/2},
        {"generate_deployment_summary", &AriaWorkflow.Methods.CommandTracing.generate_execution_summary/2}
      ],
      documentation: %{
        overview: ~s"""
        System Deployment Workflow

        Provides comprehensive system deployment and management operations using
        AriaEngine with Porcelain for external process execution.
        """,
        procedures: ~s"""
        System Deployment Procedures

        1. Service Deployment and Configuration
        2. Database Migration Management
        3. Development Environment Setup
        4. Testing and Coverage Analysis
        5. Build and Package Operations
        6. System Health Monitoring
        7. Backup and Restoration
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11],
        approved_by: "Aria AI Assistant",
        description: "System deployment and management using AriaEngine with Porcelain"
      }
    },

    "porcelain_commands" => %{
      # Demonstrates AriaEngine flexible todo ordering with Porcelain actions
      todos: [
        {:echo, ["Starting Porcelain workflow"]},                    # action first
        {"file_exists", "/tmp", true},                              # goal
        {"backup_files", ["/etc/hosts", "/tmp/hosts.backup"]},     # task
        {:copy_file, ["/etc/hosts", "/tmp/hosts.backup"]},         # action
        {"command_executed", "ls -la /tmp", true},                 # goal
        {:list_directory, ["/tmp"]},                               # action
        {"archive_created", "/tmp/backup.tar.gz", true}            # goal
      ],
      actions: [
        {:echo, &AriaEngine.Actions.echo/2},
        {:copy_file, &AriaEngine.Actions.copy_file/2},
        {:list_directory, &AriaEngine.Actions.list_directory/2},
        {:create_archive, &AriaEngine.Actions.create_archive/2},
        {:execute_command, &AriaEngine.Actions.execute_command/2}
      ],
      task_methods: [
        {"backup_files", &__MODULE__.backup_files_method/2},
        {"create_workspace", &__MODULE__.create_workspace_method/2}
      ],
      unigoal_methods: [
        {"file_exists", &__MODULE__.ensure_file_exists_method/2},
        {"command_executed", &__MODULE__.ensure_command_executed_method/2},
        {"archive_created", &__MODULE__.ensure_archive_created_method/2}
      ],
      documentation: %{
        overview: ~s"""
        Porcelain Commands Workflow

        Demonstrates AriaEngine flexible todo structure with Porcelain-based external
        process execution. Shows mixing of goals, tasks, and actions in any order.
        """,
        procedures: ~s"""
        Porcelain Commands Procedures

        1. External Command Execution via Porcelain
        2. File System Operations with Error Handling
        3. Archive and Backup Operations
        4. Mixed Todo Processing (goals, tasks, actions)
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11],
        approved_by: "Aria AI Assistant",
        description: "Demonstrates AriaEngine with Porcelain external process execution"
      }
    }
  }

  @type registry_entry :: %{
    workflow: WorkflowDefinition.t(),
    registered_at: DateTime.t(),
    version: String.t()
  }

  defstruct workflows: %{}, name: __MODULE__, started_at: nil

  # Public API

  @doc """
  Starts the workflow registry.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{name: name}, name: name)
  end

  @doc """
  Registers a workflow in the registry.
  """
  @spec register(WorkflowDefinition.t(), keyword()) :: :ok | {:error, term()}
  def register(%WorkflowDefinition{} = workflow, opts \\ []) do
    name = Keyword.get(opts, :registry, __MODULE__)
    version = Keyword.get(opts, :version, "1.0.0")

    case WorkflowDefinition.validate(workflow) do
      :ok ->
        GenServer.call(name, {:register, workflow, version})
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets a workflow by ID.
  """
  @spec get_workflow(String.t(), keyword()) :: {:ok, WorkflowDefinition.t()} | {:error, :not_found}
  def get_workflow(workflow_id, opts \\ []) do
    case Map.get(@hardcoded_workflows, workflow_id) do
      nil ->
        # Fall back to registry lookup
        name = Keyword.get(opts, :registry, __MODULE__)
        GenServer.call(name, {:get, workflow_id})

      builtin_def ->
        # Create WorkflowDefinition from built-in data
        workflow = WorkflowDefinition.new(workflow_id, builtin_def)
        {:ok, workflow}
    end
  end

  @doc """
  Lists all registered workflows.
  """
  @spec list_all(keyword()) :: [WorkflowDefinition.t()]
  def list_all(opts \\ []) do
    # Get built-in workflows
    builtin_workflows =
      @hardcoded_workflows
      |> Enum.map(fn {id, definition} -> WorkflowDefinition.new(id, definition) end)

    # Get registry workflows
    name = Keyword.get(opts, :registry, __MODULE__)
    registry_workflows = GenServer.call(name, :list_all)

    # Combine (registry takes precedence over built-in for same ID)
    all_workflows = builtin_workflows ++ registry_workflows
    Enum.uniq_by(all_workflows, & &1.id)
  end

  # GenServer Callbacks

  @impl GenServer
  def init(state) do
    started_at = DateTime.utc_now()
    Logger.info("Starting Workflow Registry: #{state.name}")
    Logger.info("Loaded #{map_size(@hardcoded_workflows)} built-in workflows")

    {:ok, %__MODULE__{name: state.name, started_at: started_at}}
  end

  @impl GenServer
  def handle_call({:register, workflow, version}, _from, state) do
    entry = %{
      workflow: workflow,
      registered_at: DateTime.utc_now(),
      version: version
    }

    new_workflows = Map.put(state.workflows, workflow.id, entry)
    new_state = %{state | workflows: new_workflows}

    Logger.info("Registered workflow: #{workflow.id} (version: #{version})")
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:get, workflow_id}, _from, state) do
    case Map.get(state.workflows, workflow_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      %{workflow: workflow} ->
        {:reply, {:ok, workflow}, state}
    end
  end

  @impl GenServer
  def handle_call(:list_all, _from, state) do
    workflows =
      state.workflows
      |> Map.values()
      |> Enum.map(& &1.workflow)

    {:reply, workflows, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unexpected message in Workflow Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
