# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPEngine do
  @moduledoc """
  Generic Standard Operating Procedure (SOP) execution engine using goal-task-network planning.

  This module provides a meta-framework for creating and executing SOPs as goal-task networks,
  where each SOP is defined as a collection of goals, tasks, and methods that can be planned
  and executed by the Aria Engine planner.

  ## Architecture Integration
  
  This service operates as part of the Orchestration Layer (Boot Fourth) and depends on:
  - `aria_security` (secrets management)
  - `aria_data` (SOP persistence) 
  - `aria_queue` (background execution)
  - Other orchestrated services

  ## SOP Structure

  An SOP consists of:
  - **Goals**: Desired end states (using AriaEngine.Multigoal)
  - **Tasks**: Atomic operations that can be executed
  - **Methods**: Compound operations that decompose into sub-goals/tasks
  - **Documentation**: Heredoc strings containing human-readable procedures
  - **Metadata**: Version, approval, contacts, etc.

  ## Example Usage

  ```elixir
  # Define an SOP
  sop = AriaWorkflow.SOPEngine.define_sop("performance_tracing", %{
    goals: [
      {"service_status", "openbao", "running"},
      {"monitoring", "commands", "traced"}
    ],
    tasks: [
      {"check_service_status", &AriaWorkflow.Tasks.check_service_status/2},
      {"enable_tracing", &AriaWorkflow.Tasks.enable_tracing/2}
    ],
    methods: [
      {"monitor_openbao", &AriaWorkflow.Methods.monitor_openbao/2}
    ],
    documentation: %{
      overview: "Performance monitoring procedures...",
      procedures: "Standard procedures for...",
      troubleshooting: "When things go wrong..."
    }
  })

  # Execute the SOP
  {:ok, plan} = AriaWorkflow.SOPEngine.plan_sop(sop, initial_state)
  :ok = AriaWorkflow.SOPEngine.execute_plan(plan)
  ```
  """

  alias AriaWorkflow.{Planner}
  alias AriaWorkflow.{SOPDefinition, SOPExecution, SOPRegistry}

  require Logger

  @type sop_id :: String.t()
  @type goal_spec :: {String.t(), String.t(), String.t()}
  @type task_spec :: {String.t(), function()}
  @type method_spec :: {String.t(), function()}
  @type documentation :: %{atom() => String.t()}
  @type metadata :: %{atom() => term()}

  @type sop_definition :: %{
    goals: [goal_spec()],
    tasks: [task_spec()],
    methods: [method_spec()],
    documentation: documentation(),
    metadata: metadata()
  }

  @doc """
  Defines a new SOP with goals, tasks, methods, and documentation.
  """
  @spec define_sop(sop_id(), sop_definition()) :: SOPDefinition.t()
  def define_sop(sop_id, definition) do
    SOPDefinition.new(sop_id, definition)
  end

  @doc """
  Registers an SOP in the global registry for reuse.
  Note: Uses hard-coded registry since aria_data is not online.
  """
  @spec register_sop(SOPDefinition.t()) :: :ok | {:error, term()}
  def register_sop(%SOPDefinition{} = sop) do
    SOPRegistry.register(sop)
  end

  @doc """
  Retrieves a registered SOP by ID.
  Note: Checks built-in SOPs first, then registry.
  """
  @spec get_sop(sop_id()) :: {:ok, SOPDefinition.t()} | {:error, :not_found}
  @spec get_sop(sop_id(), keyword()) :: {:ok, SOPDefinition.t()} | {:error, :not_found}
  def get_sop(sop_id, opts \\ []) do
    SOPRegistry.get(sop_id, opts)
  end

  @doc """
  Lists all registered SOPs.
  Note: Includes built-in SOPs.
  """
  @spec list_sops() :: [SOPDefinition.t()]
  @spec list_sops(keyword()) :: [SOPDefinition.t()]
  def list_sops(opts \\ []) do
    SOPRegistry.list_all(opts)
  end

  @doc """
  Plans the execution of an SOP using the Aria Engine planner.
  
  This converts the SOP goals into a multigoal and uses the planning engine
  to create an execution plan.
  """
  @spec plan_sop(SOPDefinition.t(), map()) :: 
    {:ok, SOPExecution.t()} | {:error, term()}
  def plan_sop(%SOPDefinition{} = sop, initial_state) do
    with {:ok, multigoal} <- SOPDefinition.to_multigoal(sop),
         {:ok, plan} <- Planner.plan(initial_state, multigoal) do
      execution = SOPExecution.new(sop, plan, initial_state)
      {:ok, execution}
    else
      error -> error
    end
  end

  @doc """
  Executes a planned SOP, optionally in the background via aria_queue.
  """
  @spec execute_plan(SOPExecution.t(), keyword()) :: 
    :ok | {:ok, reference()} | {:error, term()}
  def execute_plan(%SOPExecution{} = execution, opts \\ []) do
    background = Keyword.get(opts, :background, false)
    
    if background do
      # Queue the execution as a background job
      job_args = %{execution: execution, opts: opts}
      {:ok, _job} = Oban.insert(AriaWorkflow.Jobs.SOPExecutionJob.new(job_args))
    else
      # Execute synchronously
      do_execute_plan(execution)
    end
  end

  @doc """
  Validates an SOP definition for completeness and correctness.
  """
  @spec validate_sop(SOPDefinition.t()) :: :ok | {:error, [String.t()]}
  def validate_sop(%SOPDefinition{} = sop) do
    SOPDefinition.validate(sop)
  end

  @doc """
  Gets the current execution status of an SOP.
  """
  @spec get_execution_status(reference()) :: 
    {:ok, SOPExecution.status()} | {:error, :not_found}
  def get_execution_status(execution_ref) do
    SOPExecution.get_status(execution_ref)
  end

  @doc """
  Monitors SOP execution progress.
  """
  @spec monitor_execution(reference(), function()) :: :ok
  def monitor_execution(execution_ref, callback_fn) do
    SOPExecution.monitor(execution_ref, callback_fn)
  end

  # Private implementation

  defp do_execute_plan(%SOPExecution{plan: plan} = execution) do
    Logger.info("Starting SOP execution: #{execution.sop.id}")
    
    try do
      result = execute_plan_steps(plan, execution)
      Logger.info("SOP execution completed: #{execution.sop.id}")
      result
    rescue
      error ->
        Logger.error("SOP execution failed: #{execution.sop.id}, error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp execute_plan_steps([], _execution), do: :ok
  
  defp execute_plan_steps([step | remaining_steps], execution) do
    case execute_step(step, execution) do
      :ok -> execute_plan_steps(remaining_steps, execution)
      {:error, _} = error -> error
    end
  end

  defp execute_step({:task, task_name, args}, execution) do
    case SOPDefinition.get_task(execution.sop, task_name) do
      {:ok, task_fn} -> 
        Logger.debug("Executing task: #{task_name}")
        apply(task_fn, [execution.current_state, args])
      
      {:error, _} = error -> 
        Logger.error("Task not found: #{task_name}")
        error
    end
  end

  defp execute_step({:method, method_name, args}, execution) do
    case SOPDefinition.get_method(execution.sop, method_name) do
      {:ok, method_fn} ->
        Logger.debug("Executing method: #{method_name}")
        apply(method_fn, [execution.current_state, args])
      
      {:error, _} = error ->
        Logger.error("Method not found: #{method_name}")
        error
    end
  end
end
