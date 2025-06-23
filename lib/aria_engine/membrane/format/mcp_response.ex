defmodule AriaEngine.Membrane.Format.MCPResponse do
  @moduledoc "Membrane format for MCP-formatted responses.\n\nThis format represents the final MCP-compatible response that will be\nsent back to the MCP client. It includes the status, schedule data,\nerror details, and response metadata.\n"
  defstruct [:status, :schedule, :error_details, :request_id, :response_metadata]

  @type t :: %__MODULE__{
          status: String.t(),
          schedule: map() | nil,
          error_details: String.t() | nil,
          request_id: String.t(),
          response_metadata: map()
        }
  @doc "Validates an MCP response format structure.\n\n## Examples\n\n    iex> response = %AriaEngine.Membrane.Format.MCPResponse{\n    ...>   status: \"success\",\n    ...>   schedule: %{},\n    ...>   error_details: nil,\n    ...>   request_id: \"req_123\",\n    ...>   response_metadata: %{}\n    ...> }\n    iex> AriaEngine.Membrane.Format.MCPResponse.valid?(response)\n    true\n"
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = response) do
    is_binary(response.status) and (is_map(response.schedule) or is_nil(response.schedule)) and
      (is_binary(response.error_details) or is_nil(response.error_details)) and
      is_binary(response.request_id) and is_map(response.response_metadata)
  end

  def valid?(_) do
    false
  end

  @doc "Creates a successful MCP response.\n\n## Examples\n\n    iex> schedule = %{\"activities\" => [], \"timeline\" => %{}}\n    iex> metadata = %{formatted_at: DateTime.utc_now()}\n    iex> response = AriaEngine.Membrane.Format.MCPResponse.success(\n    ...>   schedule, \"req_123\", metadata\n    ...> )\n    iex> response.status\n    \"success\"\n"
  @spec success(map(), String.t(), map()) :: t()
  def success(schedule, request_id, response_metadata) do
    %__MODULE__{
      status: "success",
      schedule: schedule,
      error_details: nil,
      request_id: request_id,
      response_metadata: Map.merge(response_metadata, %{formatted_at: DateTime.utc_now()})
    }
  end

  @doc "Creates an error MCP response.\n\n## Examples\n\n    iex> metadata = %{formatted_at: DateTime.utc_now()}\n    iex> response = AriaEngine.Membrane.Format.MCPResponse.error(\n    ...>   \"Planning failed\", \"req_123\", metadata\n    ...> )\n    iex> response.status\n    \"error\"\n"
  @spec error(String.t(), String.t(), map()) :: t()
  def error(error_details, request_id, response_metadata) do
    %__MODULE__{
      status: "error",
      schedule: nil,
      error_details: error_details,
      request_id: request_id,
      response_metadata: Map.merge(response_metadata, %{formatted_at: DateTime.utc_now()})
    }
  end

  @doc "Creates an MCP response from a planning result.\n\n## Examples\n\n    iex> planning_result = %AriaEngine.Membrane.Format.PlanningResult{\n    ...>   status: :success,\n    ...>   result: %{plan: []},\n    ...>   execution_metadata: %{},\n    ...>   request_id: \"req_123\",\n    ...>   performance_metrics: %{execution_time_ms: 100}\n    ...> }\n    iex> response = AriaEngine.Membrane.Format.MCPResponse.from_planning_result(planning_result)\n    iex> response.status\n    \"success\"\n"
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

  @doc "Checks if the MCP response represents a successful result.\n\n## Examples\n\n    iex> response = AriaEngine.Membrane.Format.MCPResponse.success(\n    ...>   %{}, \"req_123\", %{}\n    ...> )\n    iex> AriaEngine.Membrane.Format.MCPResponse.success?(response)\n    true\n"
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: "success"}) do
    true
  end

  def success?(_) do
    false
  end

  @doc "Gets the execution time from response metadata.\n\n## Examples\n\n    iex> metadata = %{execution_time_ms: 150}\n    iex> response = AriaEngine.Membrane.Format.MCPResponse.success(\n    ...>   %{}, \"req_123\", metadata\n    ...> )\n    iex> AriaEngine.Membrane.Format.MCPResponse.execution_time_ms(response)\n    150\n"
  @spec execution_time_ms(t()) :: integer() | nil
  def execution_time_ms(%__MODULE__{response_metadata: metadata}) do
    Map.get(metadata, :execution_time_ms)
  end

  @doc "Converts MCP response to a map for MCP protocol serialization.\n"
  @spec to_mcp_map(t()) :: map()
  def to_mcp_map(%__MODULE__{} = response) do
    base_response = %{"status" => response.status, "request_id" => response.request_id}

    case response.status do
      "success" -> Map.put(base_response, "schedule", response.schedule)
      "error" -> Map.put(base_response, "error", response.error_details)
      _ -> base_response
    end
  end

  @doc "Converts MCP response to a map for serialization including metadata.\n"
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

  defp format_schedule(plan_result) when is_map(plan_result) do
    %{
      "activities" => extract_activities(plan_result),
      "timeline" => extract_timeline(plan_result),
      "resources" => extract_resource_usage(plan_result)
    }
  end

  defp format_schedule(_) do
    %{"activities" => [], "timeline" => %{}, "resources" => %{}}
  end

  defp extract_activities(plan_result) do
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

      _ ->
        []
    end
  end

  defp extract_timeline(plan_result) do
    case Map.get(plan_result, :timeline) do
      timeline when is_map(timeline) -> timeline
      _ -> %{}
    end
  end

  defp extract_resource_usage(plan_result) do
    case Map.get(plan_result, :resources) do
      resources when is_map(resources) -> resources
      _ -> %{}
    end
  end

  defp get_error_details(%AriaEngine.Membrane.Format.PlanningResult{execution_metadata: metadata}) do
    Map.get(metadata, :error_reason) || Map.get(metadata, :failure_reason) ||
      "Unknown planning error"
  end
end