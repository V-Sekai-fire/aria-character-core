# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.MCPRequest do
  @moduledoc """
  Membrane format for MCP (Model Context Protocol) requests.
  
  This format represents a standardized MCP request that can flow through
  the Membrane pipeline for processing by various filters and elements.
  """

  @derive Jason.Encoder
  defstruct [
    :request_id,
    :tool_name,
    :parameters,
    :metadata,
    :timestamp,
    :version
  ]

  @type t :: %__MODULE__{
    request_id: String.t(),
    tool_name: String.t(),
    parameters: map(),
    metadata: map(),
    timestamp: DateTime.t(),
    version: String.t()
  }

  @doc """
  Creates an MCPRequest from a tool call.
  """
  @spec from_tool_call(String.t(), map(), String.t(), map()) :: {:ok, t()} | {:error, String.t()}
  def from_tool_call(tool_name, parameters, request_id, metadata \\ %{}) do
    if is_binary(tool_name) and is_map(parameters) and is_binary(request_id) do
      request = %__MODULE__{
        request_id: request_id,
        tool_name: tool_name,
        parameters: parameters,
        metadata: metadata,
        timestamp: DateTime.utc_now(),
        version: "2.0.0"
      }
      {:ok, request}
    else
      {:error, "Invalid parameters for MCPRequest"}
    end
  end

  @doc """
  Creates an MCPRequest from legacy MCP parameters.
  """
  @spec from_mcp_params(map(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_mcp_params(mcp_params, request_id) do
    # Try to detect tool name from parameters
    tool_name = detect_tool_name(mcp_params)
    
    request = %__MODULE__{
      request_id: request_id,
      tool_name: tool_name,
      parameters: mcp_params,
      metadata: %{legacy_format: true},
      timestamp: DateTime.utc_now(),
      version: "2.0.0"
    }
    {:ok, request}
  end

  defp detect_tool_name(params) do
    cond do
      Map.has_key?(params, "schedule_name") -> "schedule_activities"
      Map.has_key?(params, "activities") -> "schedule_activities"
      true -> "unknown_tool"
    end
  end
end
