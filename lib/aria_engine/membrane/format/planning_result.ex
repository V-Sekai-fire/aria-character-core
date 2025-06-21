# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.PlanningResult do
  @moduledoc """
  Membrane format for planning execution results.
  
  This format represents the result of planning execution, including
  the status, result data, execution metadata, and performance metrics.
  """

  defstruct [
    :status,
    :result,
    :execution_metadata,
    :request_id,
    :performance_metrics
  ]

  @type status :: :success | :error | :timeout
  
  @type t :: %__MODULE__{
    status: status(),
    result: term() | nil,
    execution_metadata: map(),
    request_id: String.t(),
    performance_metrics: map()
  }

  @doc """
  Validates a planning result format structure.
  
  ## Examples
  
      iex> result = %AriaEngine.Membrane.Format.PlanningResult{
      ...>   status: :success,
      ...>   result: %{plan: []},
      ...>   execution_metadata: %{},
      ...>   request_id: "req_123",
      ...>   performance_metrics: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.PlanningResult.valid?(result)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = result) do
    result.status in [:success, :error, :timeout] and
    is_binary(result.request_id) and
    is_map(result.execution_metadata) and
    is_map(result.performance_metrics)
  end

  def valid?(_), do: false

  @doc """
  Creates a successful planning result.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.success(
      ...>   %{plan: []}, "req_123", %{}, %{}
      ...> )
      iex> result.status
      :success
  """
  @spec success(term(), String.t(), map(), map()) :: t()
  def success(result_data, request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :success,
      result: result_data,
      execution_metadata: execution_metadata,
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Creates an error planning result.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.error(
      ...>   "Planning failed", "req_123", %{}, %{}
      ...> )
      iex> result.status
      :error
  """
  @spec error(String.t(), String.t(), map(), map()) :: t()
  def error(error_reason, request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :error,
      result: nil,
      execution_metadata: Map.put(execution_metadata, :error_reason, error_reason),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Creates a timeout planning result.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.timeout(
      ...>   "req_123", %{}, %{}
      ...> )
      iex> result.status
      :timeout
  """
  @spec timeout(String.t(), map(), map()) :: t()
  def timeout(request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :timeout,
      result: nil,
      execution_metadata: Map.put(execution_metadata, :error_reason, "Planning execution timeout"),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc """
  Checks if the planning result represents a successful execution.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.success(
      ...>   %{plan: []}, "req_123", %{}, %{}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.success?(result)
      true
  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: :success}), do: true
  def success?(_), do: false

  @doc """
  Checks if the planning result represents an error.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.error(
      ...>   "test error", "req_123", %{}, %{}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.error?(result)
      true
  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{status: :error}), do: true
  def error?(_), do: false

  @doc """
  Gets the error reason from error planning result.
  
  ## Examples
  
      iex> result = AriaEngine.Membrane.Format.PlanningResult.error(
      ...>   "test error", "req_123", %{}, %{}
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningResult.error_reason(result)
      "test error"
  """
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{execution_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc """
  Converts planning result to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = result) do
    %{
      "status" => result.status,
      "result" => result.result,
      "execution_metadata" => result.execution_metadata,
      "request_id" => result.request_id,
      "performance_metrics" => result.performance_metrics
    }
  end
end
