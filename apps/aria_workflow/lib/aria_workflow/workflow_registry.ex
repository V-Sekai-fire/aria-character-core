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

  # Core workflows for basic operations
  @hardcoded_workflows %{
    "basic_timing" => %{
      goals: [
        {"timing_system", "commands", "enabled"},
        {"timezone_info", "system", "captured"},
        {"execution_log", "operations", "created"}
      ],
      tasks: [
        {"get_current_time", &AriaWorkflow.Tasks.BasicTiming.get_current_time/2},
        {"get_timezone_info", &AriaWorkflow.Tasks.BasicTiming.get_timezone_info/2},
        {"start_timer", &AriaWorkflow.Tasks.BasicTiming.start_timer/2},
        {"stop_timer", &AriaWorkflow.Tasks.BasicTiming.stop_timer/2},
        {"log_execution", &AriaWorkflow.Tasks.BasicTiming.log_execution/2}
      ],
      methods: [
        {"time_command_execution", &AriaWorkflow.Methods.BasicTiming.time_command_execution/2},
        {"generate_timing_report", &AriaWorkflow.Methods.BasicTiming.generate_timing_report/2}
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