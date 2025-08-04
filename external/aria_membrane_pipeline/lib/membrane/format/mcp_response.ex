# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.Format.MCPResponse do
  @moduledoc """
  Format for MCP responses in Membrane pipelines.
  """

  @type t :: %__MODULE__{
    status: :success | :error,
    result: any(),
    request_id: String.t(),
    error_reason: String.t() | nil,
    conversion_metadata: map(),
    execution_metadata: map(),
    processing_time: float()
  }

  defstruct [
    :status,
    :result,
    :request_id,
    :error_reason,
    :conversion_metadata,
    :execution_metadata,
    :processing_time
  ]

  @doc """
  Creates a success response.
  """
  def success(result, request_id) do
    %__MODULE__{
      status: :success,
      result: result,
      request_id: request_id,
      error_reason: nil,
      conversion_metadata: %{},
      execution_metadata: %{},
      processing_time: 0.0
    }
  end

  @doc """
  Creates a success MCP response with metadata.
  """
  def success(result, request_id, metadata) do
    %__MODULE__{
      status: :success,
      result: result,
      request_id: request_id,
      error_reason: nil,
      conversion_metadata: metadata,
      execution_metadata: %{},
      processing_time: 0.0
    }
  end

  @doc """
  Creates an error MCP response.
  """
  def error(reason, request_id) do
    %__MODULE__{
      status: :error,
      result: nil,
      request_id: request_id,
      error_reason: reason,
      conversion_metadata: %{},
      execution_metadata: %{},
      processing_time: 0.0
    }
  end
end
