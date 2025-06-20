# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.MCPResponse do
  @moduledoc """
  Membrane format for MCP-formatted responses.
  
  This format represents the final MCP-compatible response that will be
  sent back to the MCP client. It includes the status, schedule data,
  error details, and response metadata.
  """

  defstruct [
    :status,
    :schedule,
    :error_details,
    :request_id,
    :response_metadata
  ]

  @type t :: %__MODULE__{
    status: String.t(),
    schedule: map() | nil,
    error_details: String.t() | nil,
    request_id: String.t(),
    response_metadata: map()
  }

  @doc """
  Validates an MCP response format structure.
  
  ## Examples
  
      iex> response = %AriaEngine.Membrane.Format.MCPResponse{
      ...>   status: "success",
      ...>   schedule: %{},
      ...>   error_details: nil,
      ...>   request_id: "req_123",
      ...>   response_metadata: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.MCPResponse.valid?(response)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = response) do
    is_binary(response.status) and
    (is_map(response.schedule) or is_nil(response.schedule)) and
    (is_binary(response.error_details) or is_nil(response.error_details)) and
    is_binary(response.request_id) and
    is_map(response.response_metadata)
  end

  def valid?(_), do: false

  @doc """
  Creates a successful MCP response.
  
  ## Examples
  
      iex> schedule = %{"activities" => [], "timeline" => %{}}
      iex> metadata = %{formatted_at: DateTime.utc_now()}
      iex> response = AriaEngine.Membrane.Format.MCPResponse.success(
      ...>   schedule, "req_123", metadata
      ...> )
      iex> response.status
      "success"
  """
  @spec success(map(), String.t(), map()) :: t()
  def success(schedule, request_id, response_metadata) do
    %__MODULE__{
      status: "success",
      schedule: schedule,
      error_details: nil,
      request_id: request_id,
      response_metadata: Map.merge(response_metadata, %{
        formatted_at: DateTime.utc_now()
      })
    }
  end

  @doc """
  Creates an error MCP response.
  
  ## Examples
  
      iex> metadata = %{formatted_at: DateTime.utc_now()}
      iex> response = AriaEngine.Membrane.Format.MCPResponse.error(
      ...>   "Planning failed", "req_123", metadata
      ...> )
      iex> response.status
      "error"
  """
  @spec error(String.t(), String.t(), map()) :: t()
  def error(error_details, request_id, response_metadata) do
    %__MODULE__{
      status: "error",
      schedule: nil,
      error_details: error_details,
      request_id: request_id,
      response_metadata: Map.merge(response_metadata, %{
        formatted_at: DateTime.utc_now()
      })
    }
  end

  @doc """
  Creates an MCP response from a planning result.
  
  ## Examples
  
      iex> planning_result = %AriaEngine.Membrane.Format.PlanningResult{
      ...>   status: :success,
      ...>   result: %{plan: []},
      ...>   execution_metadata: %{},
      ...>   request_id: "req_123",
      ...>   performance_metrics: %{execution_time_ms: 100}
      ...> }
      iex> response = AriaEngine.Membrane.Format.MCPResponse.from_planning_result(planning_result)
      iex> response.status
      "success"
  """
  @spec from_planning_result(AriaEngine.Membrane.Format.PlanningResult.t()) :: t()
  def from_planning_result(%AriaEngine.Membrane.Format.PlanningResult{status: :success} = result) do
    schedule = format_schedule(result.result)
    
    response_metadata = %{
      formatted_at: DateTime.utc_now(),
      execution_time_ms: Map.get(result.performance_metrics, :execution_time_ms),
      coordinator_metadata: result.execution_metadata
    }
    
    success(schedule, result.request_id, response_metadata)
  end

  def from_planning_result(%AriaEngine.Membrane.Format.PlanningResult{status: status} = result) 
      when status in [:error, :failure] do
    error_details = get_error_details(result)
    
    response_metadata = %{
      formatted_at: DateTime.utc_now(),
      execution_time_ms: Map.get(result.performance_metrics, :execution_time_ms)
    }
    
    error(error_details, result.request_id, response_metadata)
  end

  @doc """
  Checks if the MCP response represents a successful result.
  
  ## Examples
  
      iex> response = AriaEngine.Membrane.Format.MCPResponse.success(
      ...>   %{}, "req_123", %{}
      ...> )
      iex> AriaEngine.Membrane.Format.MCPResponse.success?(response)
      true
  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: "success"}), do: true
  def success?(_), do: false

  @doc """
  Gets the execution time from response metadata.
  
  ## Examples
  
      iex> metadata = %{execution_time_ms: 150}
      iex> response = AriaEngine.Membrane.Format.MCPResponse.success(
      ...>   %{}, "req_123", metadata
      ...> )
      iex> AriaEngine.Membrane.Format.MCPResponse.execution_time_ms(response)
      150
  """
  @spec execution_time_ms(t()) :: integer() | nil
  def execution_time_ms(%__MODULE__{response_metadata: metadata}) do
    Map.get(metadata, :execution_time_ms)
  end

  @doc """
  Converts MCP response to a map for MCP protocol serialization.
  """
  @spec to_mcp_map(t()) :: map()
  def to_mcp_map(%__MODULE__{} = response) do
    base_response = %{
      "status" => response.status,
      "request_id" => response.request_id
    }

    case response.status do
      "success" ->
        Map.put(base_response, "schedule", response.schedule)
      
      "error" ->
        Map.put(base_response, "error", response.error_details)
      
      _ ->
        base_response
    end
  end

  @doc """
  Converts MCP response to a map for serialization including metadata.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = response) do
    %{
      "status" => response.status,
      "schedule" => response.schedule,
      "error_details" => response.error_details,
      "request_id" => response.request_id,
      "response_metadata" => response.response_metadata
    }
  end

  # Private helper functions

  defp format_schedule(plan_result) when is_map(plan_result) do
    %{
      "activities" => extract_activities(plan_result),
      "timeline" => extract_timeline(plan_result),
      "resources" => extract_resource_usage(plan_result)
    }
  end

  defp format_schedule(_), do: %{"activities" => [], "timeline" => %{}, "resources" => %{}}

  defp extract_activities(plan_result) do
    # Extract activities from plan result
    # This would integrate with existing MCPTools formatting logic
    case Map.get(plan_result, :plan) do
      plan when is_list(plan) -> 
        Enum.map(plan, fn action ->
          %{
            "name" => Map.get(action, :name, "unknown"),
            "start_time" => Map.get(action, :start_time),
            "end_time" => Map.get(action, :end_time),
            "parameters" => Map.get(action, :parameters, %{})
          }
        end)
      _ -> []
    end
  end

  defp extract_timeline(plan_result) do
    # Extract timeline information from plan result
    case Map.get(plan_result, :timeline) do
      timeline when is_map(timeline) -> timeline
      _ -> %{}
    end
  end

  defp extract_resource_usage(plan_result) do
    # Extract resource usage from plan result
    case Map.get(plan_result, :resources) do
      resources when is_map(resources) -> resources
      _ -> %{}
    end
  end

  defp get_error_details(%AriaEngine.Membrane.Format.PlanningResult{execution_metadata: metadata}) do
    Map.get(metadata, :error_reason) || 
    Map.get(metadata, :failure_reason) || 
    "Unknown planning error"
  end
end
