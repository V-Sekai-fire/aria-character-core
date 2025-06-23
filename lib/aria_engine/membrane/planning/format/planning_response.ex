# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.Format.PlanningResponse do
  @moduledoc """
  Membrane format for planning responses from the unified planning system.

  This format represents the output from the planning bin, containing
  planning results, execution metadata, performance metrics, and
  strategy information for asynchronous planning operations.

  Follows the unified action specification from ADR-134 with standardized
  action formats and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W026PRES"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  defstruct [
    :status,
    :result,
    :strategy_used,
    :execution_metadata,
    :performance_metrics,
    :fallback_attempts,
    :request_id,
    :error_reason,
    :warnings
  ]

  @type status :: :success | :error | :partial | :timeout | :cancelled

  @type unified_action :: %{
    name: atom(),
    duration: String.t() | nil,
    start: String.t() | nil,
    end: String.t() | nil,
    requires_entities: [entity_requirement()],
    description: String.t(),
    metadata: map()
  }

  @type entity_requirement :: %{
    type: String.t(),
    capabilities: [atom()],
    optional?: boolean()
  }

  @type plan_result :: %{
    actions: [unified_action()],
    timeline: [timeline_event()],
    resource_allocation: map(),
    validation_status: :valid | :invalid | :unknown
  }

  @type timeline_event :: %{
    time: String.t(),
    event_type: :action_start | :action_end | :resource_allocation | :constraint_check,
    action_id: String.t() | nil,
    description: String.t(),
    metadata: map()
  }

  @type fallback_attempt :: %{
    strategy: atom(),
    reason: String.t(),
    execution_time_ms: non_neg_integer(),
    error: String.t() | nil
  }

  @type t :: %__MODULE__{
          status: status(),
          result: plan_result() | nil,
          strategy_used: atom() | nil,
          execution_metadata: map(),
          performance_metrics: map(),
          fallback_attempts: [fallback_attempt()],
          request_id: String.t(),
          error_reason: String.t() | nil,
          warnings: [String.t()]
        }

  @doc """
  Creates a successful planning response.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.success(
      ...>   %{actions: [], timeline: [], resource_allocation: %{}, validation_status: :valid},
      ...>   :hybrid_coordinator,
      ...>   "req_123",
      ...>   %{execution_time_ms: 1500}
      ...> )
      iex> response.status
      :success

  """
  @spec success(plan_result(), atom(), String.t(), map(), keyword()) :: t()
  def success(result, strategy_used, request_id, performance_metrics, opts \\ []) do
    %__MODULE__{
      status: :success,
      result: result,
      strategy_used: strategy_used,
      execution_metadata: Keyword.get(opts, :execution_metadata, %{
        completed_at: DateTime.utc_now(),
        planner_version: "v2.0"
      }),
      performance_metrics: performance_metrics,
      fallback_attempts: Keyword.get(opts, :fallback_attempts, []),
      request_id: request_id,
      error_reason: nil,
      warnings: Keyword.get(opts, :warnings, [])
    }
  end

  @doc """
  Creates an error planning response.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.error(
      ...>   "Planning failed: insufficient resources",
      ...>   "req_123",
      ...>   %{execution_time_ms: 500}
      ...> )
      iex> response.status
      :error

  """
  @spec error(String.t(), String.t(), map(), keyword()) :: t()
  def error(error_reason, request_id, performance_metrics, opts \\ []) do
    %__MODULE__{
      status: :error,
      result: nil,
      strategy_used: Keyword.get(opts, :strategy_used),
      execution_metadata: Keyword.get(opts, :execution_metadata, %{
        failed_at: DateTime.utc_now(),
        planner_version: "v2.0"
      }),
      performance_metrics: performance_metrics,
      fallback_attempts: Keyword.get(opts, :fallback_attempts, []),
      request_id: request_id,
      error_reason: error_reason,
      warnings: Keyword.get(opts, :warnings, [])
    }
  end

  @doc """
  Creates a partial planning response for incomplete results.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.partial(
      ...>   %{actions: [], timeline: [], resource_allocation: %{}, validation_status: :unknown},
      ...>   :hybrid_coordinator,
      ...>   "req_123",
      ...>   %{execution_time_ms: 2000},
      ...>   warnings: ["Some goals could not be achieved"]
      ...> )
      iex> response.status
      :partial

  """
  @spec partial(plan_result(), atom(), String.t(), map(), keyword()) :: t()
  def partial(result, strategy_used, request_id, performance_metrics, opts \\ []) do
    %__MODULE__{
      status: :partial,
      result: result,
      strategy_used: strategy_used,
      execution_metadata: Keyword.get(opts, :execution_metadata, %{
        completed_at: DateTime.utc_now(),
        planner_version: "v2.0",
        partial_reason: "Some goals could not be achieved"
      }),
      performance_metrics: performance_metrics,
      fallback_attempts: Keyword.get(opts, :fallback_attempts, []),
      request_id: request_id,
      error_reason: nil,
      warnings: Keyword.get(opts, :warnings, [])
    }
  end

  @doc """
  Creates a timeout planning response.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.timeout(
      ...>   "req_123",
      ...>   %{execution_time_ms: 30000}
      ...> )
      iex> response.status
      :timeout

  """
  @spec timeout(String.t(), map(), keyword()) :: t()
  def timeout(request_id, performance_metrics, opts \\ []) do
    %__MODULE__{
      status: :timeout,
      result: nil,
      strategy_used: Keyword.get(opts, :strategy_used),
      execution_metadata: Keyword.get(opts, :execution_metadata, %{
        timeout_at: DateTime.utc_now(),
        planner_version: "v2.0"
      }),
      performance_metrics: performance_metrics,
      fallback_attempts: Keyword.get(opts, :fallback_attempts, []),
      request_id: request_id,
      error_reason: "Planning operation timed out",
      warnings: Keyword.get(opts, :warnings, [])
    }
  end

  @doc """
  Validates a planning response structure.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.success(
      ...>   %{actions: [], timeline: [], resource_allocation: %{}, validation_status: :valid},
      ...>   :hybrid_coordinator,
      ...>   "req_123",
      ...>   %{execution_time_ms: 1500}
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningResponse.valid?(response)
      true

  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = response) do
    valid_status?(response.status) and
      is_binary(response.request_id) and
      is_map(response.execution_metadata) and
      is_map(response.performance_metrics) and
      is_list(response.fallback_attempts) and
      is_list(response.warnings) and
      valid_result_for_status?(response.status, response.result)
  end

  def valid?(_), do: false

  @doc """
  Checks if the planning response represents a successful result.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.success(
      ...>   %{actions: [], timeline: [], resource_allocation: %{}, validation_status: :valid},
      ...>   :hybrid_coordinator,
      ...>   "req_123",
      ...>   %{execution_time_ms: 1500}
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningResponse.success?(response)
      true

  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: :success}), do: true
  def success?(_), do: false

  @doc """
  Checks if the planning response represents an error.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.error(
      ...>   "Planning failed",
      ...>   "req_123",
      ...>   %{execution_time_ms: 500}
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningResponse.error?(response)
      true

  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{status: :error}), do: true
  def error?(_), do: false

  @doc """
  Converts planning response to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = response) do
    %{
      "status" => response.status,
      "result" => response.result,
      "strategy_used" => response.strategy_used,
      "execution_metadata" => response.execution_metadata,
      "performance_metrics" => response.performance_metrics,
      "fallback_attempts" => response.fallback_attempts,
      "request_id" => response.request_id,
      "error_reason" => response.error_reason,
      "warnings" => response.warnings
    }
  end

  @doc """
  Extracts execution time from performance metrics.

  ## Examples

      iex> response = AriaEngine.Membrane.Planning.Format.PlanningResponse.success(
      ...>   %{actions: [], timeline: [], resource_allocation: %{}, validation_status: :valid},
      ...>   :hybrid_coordinator,
      ...>   "req_123",
      ...>   %{execution_time_ms: 1500}
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningResponse.execution_time_ms(response)
      1500

  """
  @spec execution_time_ms(t()) :: non_neg_integer()
  def execution_time_ms(%__MODULE__{performance_metrics: metrics}) do
    Map.get(metrics, :execution_time_ms, 0)
  end

  # Private functions

  defp valid_status?(status) do
    status in [:success, :error, :partial, :timeout, :cancelled]
  end

  defp valid_result_for_status?(:success, result) when is_map(result), do: true
  defp valid_result_for_status?(:partial, result) when is_map(result), do: true
  defp valid_result_for_status?(:error, nil), do: true
  defp valid_result_for_status?(:timeout, nil), do: true
  defp valid_result_for_status?(:cancelled, nil), do: true
  defp valid_result_for_status?(_, _), do: false
end
