# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.Format.PlanningResult do
  @moduledoc """
  Format for planning results in Membrane pipelines.
  """

  @type t :: %__MODULE__{
    status: :success | :error,
    result: any(),
    results: any(),
    request_id: String.t(),
    execution_metadata: map(),
    performance_metrics: map()
  }

  defstruct [
    :status,
    :result,
    :results,
    :request_id,
    :execution_metadata,
    :performance_metrics
  ]

  @doc """
  Creates a success planning result.
  """
  def success(result, request_id, metadata \\ %{}, performance \\ %{}) do
    %__MODULE__{
      status: :success,
      result: result,
      results: result,
      request_id: request_id,
      execution_metadata: metadata,
      performance_metrics: performance
    }
  end


  @doc """
  Creates an error planning result.
  """
  def error(reason, request_id) do
    %__MODULE__{
      status: :error,
      result: reason,
      results: reason,
      request_id: request_id,
      execution_metadata: %{},
      performance_metrics: %{}
    }
  end

  @doc """
  Creates an error planning result with metadata.
  """
  def error(reason, request_id, metadata) do
    %__MODULE__{
      status: :error,
      result: reason,
      results: reason,
      request_id: request_id,
      execution_metadata: metadata,
      performance_metrics: %{}
    }
  end
end
