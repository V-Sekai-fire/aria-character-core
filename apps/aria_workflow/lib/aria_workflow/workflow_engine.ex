# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowEngine do
  @moduledoc """
  Workflow execution engine using AriaEngine for goal-task-network planning.

  This module provides a meta-framework for creating and executing workflows as goal-task networks,
  where each workflow is defined as a collection of goals, tasks, and methods that can be planned
  and executed by the AriaEngine planner with OpenTelemetry-inspired tracing.

  ## Architecture Integration

  This service operates as part of the Orchestration Layer and depends on:
  - `aria_engine` (planning and goal reasoning)
  - `aria_security` (secrets management)
  - `aria_data` (workflow persistence)
  - `aria_queue` (background execution)

  ## Workflow Structure

  A workflow consists of:
  - **Goals**: Desired end states (using AriaEngine.Multigoal)
  - **Tasks**: Atomic operations that can be executed
  - **Methods**: Compound operations that decompose into sub-goals/tasks
  - **Documentation**: Human-readable procedures
  - **Metadata**: Version, approval, contacts, etc.
  - **Spans**: OpenTelemetry-inspired tracing for execution monitoring

  ## Example Usage

  ```elixir
  # Define a workflow
  workflow = AriaWorkflow.WorkflowEngine.define_workflow("performance_monitoring", %{
    goals: [
      {"monitoring", "commands", "traced"}
    ],
    tasks: [
      {"check_service_status", &AriaWorkflow.Tasks.check_service_status/2},
      {"enable_tracing", &AriaWorkflow.Tasks.enable_tracing/2}
    ],
    methods: [
      {"monitor_service", &AriaWorkflow.Methods.monitor_service/2}
    ],
    documentation: %{
      overview: "Performance monitoring procedures...",
      procedures: "Standard procedures for...",
      troubleshooting: "When things go wrong..."
    }
  })

  # Execute the workflow
  {:ok, plan} = AriaWorkflow.WorkflowEngine.plan_workflow(workflow, initial_state)
  :ok = AriaWorkflow.WorkflowEngine.execute_plan(plan)
  ```
  """

  alias AriaEngine.{State, Multigoal}
  alias AriaWorkflow.{WorkflowDefinition, WorkflowExecution, WorkflowRegistry, Span}

  require Logger

  @type workflow_id :: String.t()
  @type goal_spec :: {String.t(), String.t(), String.t()}
  @type task_spec :: {String.t(), function()}
  @type method_spec :: {String.t(), function()}
  @type documentation :: %{atom() => String.t()}
  @type metadata :: %{atom() => term()}

  @type workflow_definition :: %{
    goals: [goal_spec()],
    tasks: [task_spec()],
    methods: [method_spec()],
    documentation: documentation(),
    metadata: metadata()
  }

  @doc """
  Creates a new workflow definition and registers it.
  """
  @spec define_workflow(workflow_id(), workflow_definition()) ::
    {:ok, WorkflowDefinition.t()} | {:error, term()}
  def define_workflow(workflow_id, definition) do
    workflow = WorkflowDefinition.new(workflow_id, definition)

    case WorkflowDefinition.validate(workflow) do
      :ok ->
        :ok = WorkflowRegistry.register(workflow)
        {:ok, workflow}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets a workflow definition by ID.
  """
  @spec get_workflow(workflow_id(), keyword()) ::
    {:ok, WorkflowDefinition.t()} | {:error, :not_found}
  def get_workflow(workflow_id, opts \\ []) do
    WorkflowRegistry.get_workflow(workflow_id, opts)
  end

  @doc """
  Lists all available workflows.
  """
  @spec list_workflows(keyword()) :: [WorkflowDefinition.t()]
  def list_workflows(opts \\ []) do
    WorkflowRegistry.list_all(opts)
  end

  @doc """
  Plans the execution of a workflow using AriaEngine.

  This converts the workflow goals into a multigoal and uses AriaEngine's planning
  capabilities to create an execution plan with proper span tracking.
  """
  @spec plan_workflow(WorkflowDefinition.t(), State.t()) ::
    {:ok, WorkflowExecution.t()} | {:error, term()}
  def plan_workflow(%WorkflowDefinition{} = workflow, initial_state) do
    # Create planning span
    planning_span = Span.new("workflow.planning", [
      kind: :internal,
      attributes: %{
        "workflow.id" => workflow.id
      }
    ])

    try do
      # Convert workflow goals to multigoal
      with {:ok, multigoal} <- WorkflowDefinition.to_multigoal(workflow),
           {:ok, plan} <- create_simple_plan(initial_state, multigoal) do

        # Create execution with successful planning
        execution = WorkflowExecution.new(workflow, plan, initial_state)
        finished_span = Span.finish(planning_span, status: :ok)

        Logger.info("Successfully planned workflow: #{workflow.id}")
        {:ok, execution}
      else
        error ->
          failed_span = planning_span
          |> Span.add_event("planning.failed", %{"error" => inspect(error)})
          |> Span.finish(status: :error)

          Logger.error("Failed to plan workflow #{workflow.id}: #{inspect(error)}")
          error
      end
    rescue
      exception ->
        failed_span = planning_span
        |> Span.record_exception(exception)
        |> Span.finish(status: :error)

        Logger.error("Exception during workflow planning: #{Exception.message(exception)}")
        {:error, exception}
    end
  end

  @doc """
  Executes a planned workflow, optionally in the background.
  """
  @spec execute_plan(WorkflowExecution.t(), keyword()) ::
    :ok | {:error, term()}
  def execute_plan(%WorkflowExecution{} = execution, opts \\ []) do
    background? = Keyword.get(opts, :background, false)

    if background? do
      # Queue for background execution
      Logger.info("Queueing workflow #{execution.workflow_id} for background execution")
      # TODO: Integrate with aria_queue when available
      {:error, :background_execution_not_implemented}
    else
      # Execute synchronously
      execute_workflow_sync(execution)
    end
  end

  @doc """
  Gets the status of a workflow execution.
  """
  @spec get_execution_status(reference()) ::
    {:ok, WorkflowExecution.t()} | {:error, :not_found}
  def get_execution_status(execution_ref) do
    # TODO: Integrate with execution registry when available
    {:error, :not_implemented}
  end

  @doc """
  Monitors workflow execution with a callback function.
  """
  @spec monitor_execution(reference(), function()) :: :ok
  def monitor_execution(execution_ref, callback_fn) do
    # TODO: Integrate with execution registry when available
    Logger.warn("Workflow execution monitoring not yet implemented")
    :ok
  end

  # Private functions

  defp create_simple_plan(initial_state, %Multigoal{} = multigoal) do
    # Simple planning implementation until AriaEngine integration is complete
    goals = Multigoal.get_goals(multigoal)

    steps = goals
    |> Enum.with_index()
    |> Enum.map(fn {{predicate, subject, object}, index} ->
      %{
        id: "step_#{index + 1}",
        action: predicate,
        target: subject,
        params: object,
        status: :pending
      }
    end)

    plan = %{
      initial_state: initial_state,
      steps: steps,
      status: :planned,
      created_at: DateTime.utc_now()
    }

    {:ok, plan}
  end

  defp execute_workflow_sync(%WorkflowExecution{} = execution) do
    Logger.info("Starting synchronous execution of workflow: #{execution.workflow_id}")

    started_execution = WorkflowExecution.start(execution)

    try do
      # Execute each step with span tracking
      final_execution = Enum.reduce(started_execution.steps, started_execution, fn step, acc_execution ->
        execute_step(acc_execution, step)
      end)

      completed_execution = WorkflowExecution.complete(final_execution)

      Logger.info("Workflow execution completed successfully")
      Logger.debug("Execution trace:\n#{WorkflowExecution.get_trace_log(completed_execution)}")

      :ok
    rescue
      exception ->
        failed_execution = WorkflowExecution.fail(started_execution, exception)
        Logger.error("Workflow execution failed: #{Exception.message(exception)}")
        Logger.debug("Execution trace:\n#{WorkflowExecution.get_trace_log(failed_execution)}")
        {:error, exception}
    end
  end

  defp execute_step(%WorkflowExecution{} = execution, step) do
    step_name = step[:action] || "unknown_step"
    step_type = "task"  # Simplified for now

    {execution_with_span, step_span} = WorkflowExecution.start_step_span(execution, step_type, step_name)

    Logger.debug("Executing step: #{step_name}")

    try do
      # Simulate step execution
      :timer.sleep(10)  # Brief delay to simulate work

      # Update progress and finish span
      updated_execution = execution_with_span
      |> WorkflowExecution.update_progress(step_name)
      |> WorkflowExecution.finish_step_span(step_span, status: :ok)

      Logger.debug("Step completed: #{step_name}")
      updated_execution
    rescue
      exception ->
        failed_span = Span.record_exception(step_span, exception)

        execution_with_span
        |> WorkflowExecution.finish_step_span(failed_span, status: :error)
        |> then(fn exec ->
          Logger.error("Step failed: #{step_name} - #{Exception.message(exception)}")
          raise exception
        end)
    end
  end
end
