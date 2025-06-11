# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPExecution do
  @moduledoc """
  Represents an executing instance of an SOP.

  This module tracks the execution state, progress, and results of an SOP
  as it runs through the planning and execution phases.
  """

  alias AriaWorkflow.SOPDefinition

  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type execution_step :: {:task | :method, String.t(), term()}
  @type execution_plan :: [execution_step()]

  @type t :: %__MODULE__{
    id: reference(),
    sop_id: String.t(),
    sop: SOPDefinition.t(),
    plan: execution_plan(),
    steps: list(),
    initial_state: map(),
    current_state: map(),
    status: status(),
    started_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil,
    error: term() | nil,
    progress: %{
      total_steps: non_neg_integer(),
      completed_steps: non_neg_integer(),
      current_step: String.t() | nil
    }
  }

  defstruct [
    :id,
    :sop_id,
    :sop,
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
    }
  ]

  @doc """
  Creates a new SOP execution instance.
  """
  @spec new(SOPDefinition.t(), execution_plan(), map()) :: t()
  def new(%SOPDefinition{id: sop_id} = sop, plan, initial_state) do
    execution_id = make_ref()
    
    # Extract steps from the plan
    steps = case plan do
      %{steps: plan_steps} -> plan_steps
      _ -> []
    end
    
    %__MODULE__{
      id: execution_id,
      sop_id: sop_id,
      sop: sop,
      plan: plan,
      steps: steps,
      initial_state: initial_state,
      current_state: initial_state,
      progress: %{
        total_steps: length(steps),
        completed_steps: 0,
        current_step: nil
      }
    }
  end

  @doc """
  Starts the execution, updating status and timestamp.
  """
  @spec start(t()) :: t()
  def start(%__MODULE__{} = execution) do
    %{execution |
      status: :executing,
      started_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the execution progress.
  """
  @spec update_progress(t(), String.t()) :: t()
  def update_progress(%__MODULE__{progress: progress} = execution, current_step) do
    new_progress = %{progress |
      completed_steps: progress.completed_steps + 1,
      current_step: current_step
    }
    
    %{execution | progress: new_progress}
  end

  @doc """
  Updates the current state during execution.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(%__MODULE__{} = execution, new_state) do
    %{execution | current_state: new_state}
  end

  @doc """
  Marks the execution as completed successfully.
  """
  @spec complete(t()) :: t()
  def complete(%__MODULE__{} = execution) do
    %{execution |
      status: :completed,
      completed_at: DateTime.utc_now()
    }
  end

  @doc """
  Marks the execution as failed with an error.
  """
  @spec fail(t(), term()) :: t()
  def fail(%__MODULE__{} = execution, error) do
    %{execution |
      status: :failed,
      completed_at: DateTime.utc_now(),
      error: error
    }
  end

  @doc """
  Cancels the execution.
  """
  @spec cancel(t(), String.t() | nil) :: t()
  def cancel(%__MODULE__{} = execution, reason \\ nil) do
    %{execution |
      status: :cancelled,
      completed_at: DateTime.utc_now(),
      error: reason
    }
  end

  @doc """
  Gets the current status of the execution.
  """
  @spec get_status(reference()) :: {:ok, status()} | {:error, :not_found}
  def get_status(execution_ref) do
    # In a real implementation, this would look up the execution
    # from a registry or database
    case AriaWorkflow.ExecutionRegistry.get(execution_ref) do
      {:ok, execution} -> {:ok, execution.status}
      error -> error
    end
  end

  @doc """
  Monitors execution progress by registering a callback.
  """
  @spec monitor(reference(), function()) :: :ok
  def monitor(execution_ref, callback_fn) do
    AriaWorkflow.ExecutionRegistry.monitor(execution_ref, callback_fn)
  end

  @doc """
  Calculates the completion percentage.
  """
  @spec completion_percentage(t()) :: float()
  def completion_percentage(%__MODULE__{progress: progress}) do
    if progress.total_steps == 0 do
      0.0
    else
      progress.completed_steps / progress.total_steps * 100.0
    end
  end

  @doc """
  Gets a human-readable status summary.
  """
  @spec status_summary(t()) :: String.t()
  def status_summary(%__MODULE__{} = execution) do
    percentage = completion_percentage(execution) |> Float.round(1)
    current_step = execution.progress.current_step || "None"
    
    case execution.status do
      :pending -> "Pending execution"
      :planning -> "Planning execution steps"
      :executing -> "Executing (#{percentage}%) - Current: #{current_step}"
      :completed -> "Completed successfully (100%)"
      :failed -> "Failed at step: #{current_step} - Error: #{inspect(execution.error)}"
      :cancelled -> "Cancelled - Reason: #{inspect(execution.error)}"
    end
  end

  @doc """
  Gets the execution duration if started.
  """
  @spec duration(t()) :: {:ok, integer()} | {:error, :not_started}
  def duration(%__MODULE__{started_at: nil}), do: {:error, :not_started}
  
  def duration(%__MODULE__{started_at: started_at, completed_at: nil}) do
    duration_ms = DateTime.diff(DateTime.utc_now(), started_at, :millisecond)
    {:ok, duration_ms}
  end
  
  def duration(%__MODULE__{started_at: started_at, completed_at: completed_at}) do
    duration_ms = DateTime.diff(completed_at, started_at, :millisecond)
    {:ok, duration_ms}
  end

  @doc """
  Serializes execution state for persistence or transmission.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = execution) do
    %{
      id: execution.id,
      sop_id: execution.sop.id,
      status: execution.status,
      started_at: execution.started_at,
      completed_at: execution.completed_at,
      error: execution.error,
      progress: execution.progress
    }
  end

  @doc """
  Gets execution logs/events for debugging and monitoring.
  """
  @spec get_logs(t()) :: [map()]
  def get_logs(%__MODULE__{} = execution) do
    # In a real implementation, this would retrieve execution logs
    # from a logging system or database
    [
      %{
        timestamp: execution.started_at,
        level: :info,
        message: "SOP execution started: #{execution.sop.id}"
      }
    ]
  end
end
