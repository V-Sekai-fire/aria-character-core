# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Membrane.Format.MCPResponse do
  @moduledoc """
  Format definition for MCP (Model Context Protocol) responses flowing through the pipeline.

  This format represents the final response that will be sent back to MCP tools
  after processing through the planning pipeline.
  """

  @type t :: %__MODULE__{
          content: list(),
          status: :success | :error,
          request_id: String.t(),
          timestamp: DateTime.t(),
          error_details: map() | nil
        }

  defstruct [
    :content,
    :status,
    :request_id,
    :timestamp,
    :error_details
  ]

  @doc """
  Creates a new successful MCPResponse format struct.
  """
  @spec success(list(), String.t()) :: t()
  def success(content, request_id) do
    %__MODULE__{
      content: content,
      status: :success,
      request_id: request_id,
      timestamp: DateTime.utc_now(),
      error_details: nil
    }
  end

  @doc """
  Creates a new error MCPResponse format struct.
  """
  @spec error(map(), String.t()) :: t()
  def error(error_details, request_id) do
    %__MODULE__{
      content: [],
      status: :error,
      request_id: request_id,
      timestamp: DateTime.utc_now(),
      error_details: error_details
    }
  end

  @doc """
  Validates that the MCPResponse has all required fields.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = response) do
    not is_nil(response.content) and
      not is_nil(response.status) and
      not is_nil(response.request_id) and
      not is_nil(response.timestamp) and
      response.status in [:success, :error]
  end
end
