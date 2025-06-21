# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.MCPRequest do
  @moduledoc """
  Generic Membrane format for any MCP tool request.
  
  This format represents incoming MCP requests that can be processed
  through various pipeline configurations. It supports any MCP tool
  call with flexible parameters and metadata for tracking and telemetry.
  """

  defstruct [
    :tool_name,
    :parameters,
    :request_id,
    :timestamp,
    :metadata
  ]

  @type t :: %__MODULE__{
    tool_name: String.t(),
    parameters: map(),
    request_id: String.t(),
    timestamp: DateTime.t(),
    metadata: map()
  }

  @doc """
  Validates a generic MCP request format structure.
  
  ## Examples
  
      iex> request = %AriaEngine.Membrane.Format.MCPRequest{
      ...>   tool_name: "schedule_activities",
      ...>   parameters: %{"schedule_name" => "test"},
      ...>   request_id: "req_123",
      ...>   timestamp: DateTime.utc_now(),
      ...>   metadata: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.MCPRequest.valid?(request)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    is_binary(request.tool_name) and
    is_map(request.parameters) and
    is_binary(request.request_id) and
    is_struct(request.timestamp, DateTime) and
    is_map(request.metadata)
  end

  def valid?(_), do: false

  @doc """
  Creates a new generic MCP request from tool name and parameters.
  
  ## Examples
  
      iex> params = %{"schedule_name" => "test", "activities" => []}
      iex> {:ok, request} = AriaEngine.Membrane.Format.MCPRequest.from_tool_call("schedule_activities", params, "req_123")
      iex> request.tool_name
      "schedule_activities"
      iex> request.parameters["schedule_name"]
      "test"
  """
  @spec from_tool_call(String.t(), map(), String.t(), map()) :: {:ok, t()} | {:error, String.t()}
  def from_tool_call(tool_name, parameters, request_id, metadata \\ %{}) 
      when is_binary(tool_name) and is_map(parameters) and is_binary(request_id) and is_map(metadata) do
    
    request = %__MODULE__{
      tool_name: tool_name,
      parameters: parameters,
      request_id: request_id,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }

    if valid?(request) do
      {:ok, request}
    else
      {:error, "Invalid MCP request parameters"}
    end
  end

  def from_tool_call(_, _, _, _), do: {:error, "Invalid parameters"}

  @doc """
  Creates a new MCP request from legacy MCP parameters (backward compatibility).
  
  This function provides backward compatibility for existing schedule_activities
  calls that don't specify a tool_name.
  
  ## Examples
  
      iex> params = %{
      ...>   "schedule_name" => "test_schedule",
      ...>   "activities" => [],
      ...>   "entities" => [],
      ...>   "resources" => %{},
      ...>   "constraints" => %{}
      ...> }
      iex> {:ok, request} = AriaEngine.Membrane.Format.MCPRequest.from_mcp_params(params, "req_123")
      iex> request.tool_name
      "schedule_activities"
  """
  @spec from_mcp_params(map(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_mcp_params(mcp_params, request_id) when is_map(mcp_params) and is_binary(request_id) do
    # Detect tool type from parameters
    tool_name = detect_tool_name(mcp_params)
    
    request = %__MODULE__{
      tool_name: tool_name,
      parameters: mcp_params,
      request_id: request_id,
      timestamp: DateTime.utc_now(),
      metadata: %{legacy_format: true}
    }

    if valid?(request) do
      {:ok, request}
    else
      {:error, "Invalid MCP request parameters"}
    end
  end

  def from_mcp_params(_, _), do: {:error, "Invalid parameters"}

  @doc """
  Detects the tool name from legacy MCP parameters.
  
  This provides backward compatibility by analyzing the parameter structure
  to determine which MCP tool is being called.
  """
  @spec detect_tool_name(map()) :: String.t()
  def detect_tool_name(params) when is_map(params) do
    cond do
      # schedule_activities detection
      Map.has_key?(params, "schedule_name") or 
      Map.has_key?(params, "activities") or
      Map.has_key?(params, "entities") ->
        "schedule_activities"
      
      # Add other tool detections here as needed
      Map.has_key?(params, "pipeline_config") ->
        "configure_pipeline"
      
      Map.has_key?(params, "element_type") ->
        "setup_element_config"
      
      # Default fallback
      true ->
        "unknown_tool"
    end
  end

  @doc """
  Checks if this request is for a specific tool.
  
  ## Examples
  
      iex> request = %AriaEngine.Membrane.Format.MCPRequest{
      ...>   tool_name: "schedule_activities",
      ...>   parameters: %{},
      ...>   request_id: "req_123",
      ...>   timestamp: DateTime.utc_now(),
      ...>   metadata: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.MCPRequest.is_tool?(request, "schedule_activities")
      true
      iex> AriaEngine.Membrane.Format.MCPRequest.is_tool?(request, "other_tool")
      false
  """
  @spec is_tool?(t(), String.t()) :: boolean()
  def is_tool?(%__MODULE__{tool_name: tool_name}, target_tool) when is_binary(target_tool) do
    tool_name == target_tool
  end

  def is_tool?(_, _), do: false

  @doc """
  Extracts parameters for a specific tool, with validation.
  
  ## Examples
  
      iex> request = %AriaEngine.Membrane.Format.MCPRequest{
      ...>   tool_name: "schedule_activities",
      ...>   parameters: %{"schedule_name" => "test"},
      ...>   request_id: "req_123",
      ...>   timestamp: DateTime.utc_now(),
      ...>   metadata: %{}
      ...> }
      iex> {:ok, params} = AriaEngine.Membrane.Format.MCPRequest.get_tool_params(request, "schedule_activities")
      iex> params["schedule_name"]
      "test"
  """
  @spec get_tool_params(t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_tool_params(%__MODULE__{tool_name: tool_name, parameters: params}, target_tool) 
      when tool_name == target_tool do
    {:ok, params}
  end

  def get_tool_params(%__MODULE__{tool_name: tool_name}, target_tool) do
    {:error, "Request is for tool '#{tool_name}', not '#{target_tool}'"}
  end

  def get_tool_params(_, _), do: {:error, "Invalid request format"}

  @doc """
  Converts the MCP request back to a map format for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    %{
      "tool_name" => request.tool_name,
      "parameters" => request.parameters,
      "request_id" => request.request_id,
      "timestamp" => DateTime.to_iso8601(request.timestamp),
      "metadata" => request.metadata
    }
  end

  @doc """
  Converts to legacy schedule_activities format for backward compatibility.
  
  This is useful when interfacing with existing code that expects the old format.
  """
  @spec to_legacy_schedule_params(t()) :: {:ok, map()} | {:error, String.t()}
  def to_legacy_schedule_params(%__MODULE__{tool_name: "schedule_activities", parameters: params}) do
    legacy_params = %{
      "schedule_name" => params["schedule_name"],
      "activities" => params["activities"] || [],
      "entities" => params["entities"] || [],
      "resources" => params["resources"] || %{},
      "constraints" => params["constraints"] || %{}
    }
    
    {:ok, legacy_params}
  end

  def to_legacy_schedule_params(%__MODULE__{tool_name: tool_name}) do
    {:error, "Cannot convert '#{tool_name}' request to legacy schedule format"}
  end

  def to_legacy_schedule_params(_), do: {:error, "Invalid request format"}
end
