# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowExecution do
  @moduledoc """
  [DEPRECATED] Use AriaEngine.DomainDefinition instead.

  This module is being replaced by AriaEngine.DomainDefinition which unifies
  domain capabilities with execution state and span-based tracing.

  The key insight is that span-based tracing IS just todo execution tracking:
  - Spans = Todo items being executed
  - Span hierarchy = Todo dependencies
  - Span context = State flow through execution
  - Trace = Complete todo execution path

  AriaEngine.DomainDefinition provides this functionality more elegantly by
  treating todo execution as the trace itself, eliminating redundant infrastructure.

  This module represents an executing instance of a workflow with span-based tracing.
  Use AriaEngine.DomainDefinition for new code.
  """

  alias AriaEngine.State
  alias AriaWorkflow.{WorkflowDefinition, Span}

  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type execution_step :: {:task | :method, String.t(), term()}

  @type t :: %__MODULE__{
    id: reference(),
    workflow_id: String.t(),
    workflow: WorkflowDefinition.t(),
    plan: map(),
    steps: list(),
    initial_state: State.t(),
    current_state: State.t(),
    status: status(),
    started_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil,
    error: term() | nil,
    progress: %{
      total_steps: non_neg_integer(),
      completed_steps: non_neg_integer(),
      current_step: String.t() | nil
    },
    root_span: Span.t(),
    current_span: Span.t() | nil,
    spans: [Span.t()]
  }

  defstruct [
    :id,
    :workflow_id,
    :workflow,
    :plan,
    :steps,
    :initial_state,
    :current_state,
    status: :pending,
    started_at: nil,
    completed_at: nil,
    error: nil,
    progress: %{
      total_steps: 0,
      completed_steps: 0,
      current_step: nil
    },
    root_span: nil,
    current_span: nil,
    spans: []
  ]

  @doc """
  Creates a new workflow execution instance.
  """
  @spec new(WorkflowDefinition.t(), map(), State.t()) :: t()
  def new(%WorkflowDefinition{id: workflow_id} = workflow, plan, initial_state) do
    execution_id = make_ref()

    # Extract steps from the plan
    steps = case plan do
      %{steps: plan_steps} -> plan_steps
      _ -> []
    end

    # Create root span for the entire workflow execution
    root_span = Span.new("workflow:#{workflow_id}", [
      kind: :server,
      attributes: %{
        "workflow.id" => workflow_id,
        "workflow.execution_id" => inspect(execution_id),
        "workflow.total_steps" => length(steps)
      }
    ])

    %__MODULE__{
      id: execution_id,
      workflow_id: workflow_id,
      workflow: workflow,
      plan: plan,
      steps: steps,
      initial_state: initial_state,
      current_state: initial_state,
      progress: %{
        total_steps: length(steps),
        completed_steps: 0,
        current_step: nil
      },
      root_span: root_span,
      current_span: root_span,
      spans: [root_span]
    }
  end

  @doc """
  Starts the execution, updating status and timestamp.
  """
  @spec start(t()) :: t()
  def start(%__MODULE__{root_span: root_span} = execution) do
    updated_span = Span.add_event(root_span, "workflow.start")

    %{execution |
      status: :executing,
      started_at: DateTime.utc_now(),
      root_span: updated_span,
      current_span: updated_span,
      spans: update_span_in_list(execution.spans, updated_span)
    }
  end

  @doc """
  Completes the execution successfully.
  """
  @spec complete(t()) :: t()
  def complete(%__MODULE__{root_span: root_span} = execution) do
    completed_span = root_span
    |> Span.add_event("workflow.complete")
    |> Span.finish(status: :ok)

    %{execution |
      status: :completed,
      completed_at: DateTime.utc_now(),
      root_span: completed_span,
      current_span: nil,
      spans: update_span_in_list(execution.spans, completed_span)
    }
  end

  @doc """
  Fails the execution with an error.
  """
  @spec fail(t(), term()) :: t()
  def fail(%__MODULE__{root_span: root_span} = execution, error) do
    failed_span = root_span
    |> Span.add_event("workflow.fail", %{"error" => inspect(error)})
    |> Span.set_attribute("error", true)
    |> Span.finish(status: :error)

    %{execution |
      status: :failed,
      completed_at: DateTime.utc_now(),
      error: error,
      root_span: failed_span,
      current_span: nil,
      spans: update_span_in_list(execution.spans, failed_span)
    }
  end

  @doc """
  Starts a new span for a step execution.
  """
  @spec start_step_span(t(), String.t(), String.t()) :: {t(), Span.t()}
  def start_step_span(%__MODULE__{current_span: parent_span} = execution, step_type, step_name) do
    step_span = Span.create_child(parent_span, "#{step_type}:#{step_name}", [
      kind: :internal,
      attributes: %{
        "step.type" => step_type,
        "step.name" => step_name,
        "workflow.id" => execution.workflow_id
      }
    ])

    updated_execution = %{execution |
      current_span: step_span,
      spans: [step_span | execution.spans]
    }

    {updated_execution, step_span}
  end

  @doc """
  Finishes a step span and returns to parent.
  """
  @spec finish_step_span(t(), Span.t(), keyword()) :: t()
  def finish_step_span(%__MODULE__{root_span: root_span} = execution, step_span, opts \\ []) do
    finished_span = Span.finish(step_span, opts)

    %{execution |
      current_span: root_span,
      spans: update_span_in_list(execution.spans, finished_span)
    }
  end

  @doc """
  Updates progress information.
  """
  @spec update_progress(t(), String.t() | nil) :: t()
  def update_progress(%__MODULE__{progress: progress} = execution, current_step) do
    new_progress = case current_step do
      nil -> progress
      step_name ->
        %{progress |
          completed_steps: progress.completed_steps + 1,
          current_step: step_name
        }
    end

    %{execution | progress: new_progress}
  end

  @doc """
  Updates the current state.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(%__MODULE__{} = execution, new_state) do
    %{execution | current_state: new_state}
  end

  @doc """
  Gets all completed spans.
  """
  @spec get_completed_spans(t()) :: [Span.t()]
  def get_completed_spans(%__MODULE__{spans: spans}) do
    Enum.filter(spans, fn span -> span.end_time != nil end)
  end

  @doc """
  Gets the trace as a formatted string for logging.
  """
  @spec get_trace_log(t()) :: String.t()
  def get_trace_log(%__MODULE__{spans: spans}) do
    spans
    |> Enum.reverse()
    |> Enum.map(&Span.to_log_format/1)
    |> Enum.join("\n")
  end

  @doc """
  Gets execution summary with timing information.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%__MODULE__{} = execution) do
    total_duration = case execution.root_span.duration_us do
      nil -> nil
      us -> us
    end

    completed_spans = get_completed_spans(execution)
    step_count = length(completed_spans) - 1  # Exclude root span

    %{
      workflow_id: execution.workflow_id,
      execution_id: execution.id,
      status: execution.status,
      started_at: execution.started_at,
      completed_at: execution.completed_at,
      total_duration_us: total_duration,
      total_steps: execution.progress.total_steps,
      completed_steps: execution.progress.completed_steps,
      step_spans: step_count,
      trace_id: execution.root_span.trace_id
    }
  end

  # Private helpers

  defp update_span_in_list(spans, updated_span) do
    Enum.map(spans, fn span ->
      if span.span_id == updated_span.span_id do
        updated_span
      else
        span
      end
    end)
  end
end
