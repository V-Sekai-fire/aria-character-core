# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.PlanningResult do
  @moduledoc """
  Migration tool with serial number: A25W007RESP

  Decode: mix migrate.decode_serial A25W007RESP
  """

  @serial_number "A25W007RESP"

  @moduledoc """
  Membrane format for planning execution results.

  This format represents the results from planning execution by the
  HybridCoordinator. It includes the planning status, result data,
  execution metadata, and performance metrics.
  """

  defstruct [
    :status,
    :result,
    :execution_metadata,
    :request_id,
    :performance_metrics
  ]

  @type status :: :success | :failure | :error

  @type t :: %__MODULE__{
          status: status(),
          result: term(),
          execution_metadata: map(),
          request_id: String.t(),
          performance_metrics: map()
        }

  @doc """
  Validates a planning result format structure.

  ## Examples

      iex> result = %AriaEngine.Membrane.Format.PlanningResult{
      ...>   status: :success,
      ...>   result: %{},
      ...>   execution_metadata: %{},
      ...>   request_id: "req_123",
      ...>   performance_metrics: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.PlanningResult.valid?(result)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = result) do
    result.status in [:success, :failure, :error] and
      is_map(result.execution_metadata) and
      is_binary(result.request_id) and
      is_map(result.performance_metrics)
  end

  def valid?(_), do: false

  @doc """
  Creates a successful planning result.

  ## Examples

      iex> plan = %{actions: []}
      iex> metadata = %{executed_at: DateTime.utc_now()}
      iex> metrics = %{execution_time_ms: 100}
      iex> result = AriaEngine.Membrane.Format.PlanningResult.success(
      ...>   plan, "req_123", metadata, metrics
      ...> )
      iex> result.status
      :success
  """
  @spec success(term(), String.t(), map(), map()) :: t()
  def success(plan_result, request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :success,
      result: plan_result,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Creates a failed planning result.

  ## Examples

      iex> metadata = %{failure_reason: "No solution found"}
      iex> metrics = %{execution_time_ms: 50}
      iex> result = AriaEngine.Membrane.Format.PlanningResult.failure(
      ...>   "req_123", metadata, metrics
      ...> )
      iex> result.status
      :failure
  """
  @spec failure(String.t(), map(), map()) :: t()
  def failure(request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :failure,
      result: nil,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Creates an error planning result.

  ## Examples

      iex> metadata = %{error_reason: "Invalid domain"}
      iex> metrics = %{execution_time_ms: 10}
      iex> result = AriaEngine.Membrane.Format.PlanningResult.error(
      ...>   "req_123", metadata, metrics
      ...> )
      iex> result.status
      :error
  """
  @spec error(String.t(), map(), map()) :: t()
  def error(request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :error,
      result: nil,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Creates a planning result from HybridCoordinator execution.

  ## Examples

      iex> start_time = System.monotonic_time(:microsecond)
      iex> result = AriaEngine.Membrane.Format.PlanningResult.from_execution(
      ...>   {:ok, %{plan: []}}, "req_123", start_time
      ...> )
      iex> result.status
      :success
  """
  @spec from_execution({:ok, term()} | {:error, term()}, String.t(), integer()) :: t()
  def from_execution({:ok, plan_result}, request_id, start_time) do
    execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

    success(
      plan_result,
      request_id,
      %{executed_at: DateTime.utc_now()},
      %{execution_time_ms: execution_time_ms}
    )
  end

  def from_execution({:error, reason}, request_id, start_time) do
    execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

    error(
      request_id,
      %{error_reason: reason},
      %{execution_time_ms: execution_time_ms}
    )
  end

  @doc """
  Checks if the planning result represents a successful execution.

  ## Examples

      iex> result = AriaEngine.Membrane.Format.PlanningResult.success(
      ...>   %{}, "req_123", %{}, %{}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.success?(result)
      true
  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: :success}), do: true
  def success?(_), do: false

  @doc """
  Gets the error reason from error planning results.

  ## Examples

      iex> result = AriaEngine.Membrane.Format.PlanningResult.error(
      ...>   "req_123", %{error_reason: "test error"}, %{}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.error_reason(result)
      "test error"
  """
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{execution_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc """
  Gets the execution time in milliseconds.

  ## Examples

      iex> result = AriaEngine.Membrane.Format.PlanningResult.success(
      ...>   %{}, "req_123", %{}, %{execution_time_ms: 150}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.execution_time_ms(result)
      150
  """
  @spec execution_time_ms(t()) :: integer() | nil
  def execution_time_ms(%__MODULE__{performance_metrics: metrics}) do
    Map.get(metrics, :execution_time_ms)
  end

  @doc """
  Converts planning result to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = result) do
    %{
      "status" => Atom.to_string(result.status),
      "result" => if(result.result, do: inspect(result.result), else: nil),
      "execution_metadata" => result.execution_metadata,
      "request_id" => result.request_id,
      "performance_metrics" => result.performance_metrics
    }
  end
end
