# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.Format.MCPRequest do
  @moduledoc """
  Format definition for MCP (Model Context Protocol) requests flowing through the pipeline.

  This format represents incoming requests from MCP tools that need to be processed
  by the planning pipeline.
  """

  @type t :: %__MODULE__{
          tool_name: String.t(),
          arguments: map(),
          request_id: String.t(),
          timestamp: DateTime.t()
        }

  defstruct [
    :tool_name,
    :arguments,
    :request_id,
    :timestamp
  ]

  @doc """
  Creates a new MCPRequest format struct.

  ## Examples

      iex> Membrane.Format.MCPRequest.new("schedule_activities", %{}, "req-123")
      %Membrane.Format.MCPRequest{
        tool_name: "schedule_activities",
        arguments: %{},
        request_id: "req-123",
        timestamp: ~U[2025-06-28 15:27:00Z]
      }
  """
  @spec new(String.t(), map(), String.t()) :: t()
  def new(tool_name, arguments, request_id) do
    %__MODULE__{
      tool_name: tool_name,
      arguments: arguments,
      request_id: request_id,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Creates an MCPRequest from a tool call format.
  """
  @spec from_tool_call(String.t(), map(), String.t(), map()) :: {:ok, t()} | {:error, String.t()}
  def from_tool_call(tool_name, parameters, request_id, _metadata) do
    if valid_tool_call_params?(tool_name, parameters, request_id) do
      request = %__MODULE__{
        tool_name: tool_name,
        arguments: parameters,
        request_id: request_id,
        timestamp: DateTime.utc_now()
      }
      {:ok, request}
    else
      {:error, "Invalid tool call parameters"}
    end
  end

  @doc """
  Creates an MCPRequest from legacy MCP parameters format.
  """
  @spec from_mcp_params(map(), String.t()) :: {:ok, t()}
  def from_mcp_params(mcp_params, request_id) do
    # Extract tool name from parameters or default to "legacy_request"
    tool_name = Map.get(mcp_params, "tool_name", "legacy_request")

    request = %__MODULE__{
      tool_name: tool_name,
      arguments: mcp_params,
      request_id: request_id,
      timestamp: DateTime.utc_now()
    }
    {:ok, request}
  end

  @doc """
  Validates that the MCPRequest has all required fields.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    not is_nil(request.tool_name) and
      not is_nil(request.arguments) and
      not is_nil(request.request_id) and
      not is_nil(request.timestamp)
  end

  defp valid_tool_call_params?(tool_name, parameters, request_id) do
    is_binary(tool_name) and is_map(parameters) and is_binary(request_id)
  end
end
