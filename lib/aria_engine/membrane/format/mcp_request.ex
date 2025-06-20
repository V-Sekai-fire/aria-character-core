# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.MCPRequest do
  @moduledoc """
  Membrane format for MCP schedule_activities requests.
  
  This format represents incoming MCP requests that need to be processed
  through the planning pipeline. It includes all necessary data for
  schedule planning along with metadata for tracking and telemetry.
  """

  defstruct [
    :schedule_name,
    :activities,
    :entities,
    :resources,
    :constraints,
    :request_id,
    :timestamp
  ]

  @type t :: %__MODULE__{
    schedule_name: String.t(),
    activities: [map()],
    entities: [map()],
    resources: map(),
    constraints: map(),
    request_id: String.t(),
    timestamp: DateTime.t()
  }

  @doc """
  Validates an MCP request format structure.
  
  ## Examples
  
      iex> request = %AriaEngine.Membrane.Format.MCPRequest{
      ...>   schedule_name: "test_schedule",
      ...>   activities: [],
      ...>   entities: [],
      ...>   resources: %{},
      ...>   constraints: %{},
      ...>   request_id: "req_123",
      ...>   timestamp: DateTime.utc_now()
      ...> }
      iex> AriaEngine.Membrane.Format.MCPRequest.valid?(request)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    is_binary(request.schedule_name) and
    is_list(request.activities) and
    is_list(request.entities) and
    is_map(request.resources) and
    is_map(request.constraints) and
    is_binary(request.request_id) and
    is_struct(request.timestamp, DateTime)
  end

  def valid?(_), do: false

  @doc """
  Creates a new MCP request from raw MCP parameters.
  
  ## Examples
  
      iex> params = %{
      ...>   "schedule_name" => "test_schedule",
      ...>   "activities" => [],
      ...>   "entities" => [],
      ...>   "resources" => %{},
      ...>   "constraints" => %{}
      ...> }
      iex> {:ok, request} = AriaEngine.Membrane.Format.MCPRequest.from_mcp_params(params, "req_123")
      iex> request.schedule_name
      "test_schedule"
  """
  @spec from_mcp_params(map(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_mcp_params(mcp_params, request_id) when is_map(mcp_params) and is_binary(request_id) do
    request = %__MODULE__{
      schedule_name: mcp_params["schedule_name"],
      activities: mcp_params["activities"] || [],
      entities: mcp_params["entities"] || [],
      resources: mcp_params["resources"] || %{},
      constraints: mcp_params["constraints"] || %{},
      request_id: request_id,
      timestamp: DateTime.utc_now()
    }

    if valid?(request) do
      {:ok, request}
    else
      {:error, "Invalid MCP request parameters"}
    end
  end

  def from_mcp_params(_, _), do: {:error, "Invalid parameters"}

  @doc """
  Converts the MCP request back to a map format for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    %{
      "schedule_name" => request.schedule_name,
      "activities" => request.activities,
      "entities" => request.entities,
      "resources" => request.resources,
      "constraints" => request.constraints,
      "request_id" => request.request_id,
      "timestamp" => DateTime.to_iso8601(request.timestamp)
    }
  end
end
