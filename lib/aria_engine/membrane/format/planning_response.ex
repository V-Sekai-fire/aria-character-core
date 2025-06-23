defmodule AriaEngine.Membrane.Format.PlanningResult do
  @moduledoc "Membrane format for planning execution results.\n\nThis format represents the results from planning execution by the\nHybridCoordinator. It includes the planning status, result data,\nexecution metadata, and performance metrics.\n"
  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W016RESP"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  defstruct [:status, :result, :execution_metadata, :request_id, :performance_metrics]
  @type status :: :success | :failure | :error
  @type t :: %__MODULE__{
          status: status(),
          result: term(),
          execution_metadata: map(),
          request_id: String.t(),
          performance_metrics: map()
        }
  @doc "Validates a planning result format structure.\n\n## Examples\n\n    iex> result = %AriaEngine.Membrane.Format.PlanningResult{\n    ...>   status: :success,\n    ...>   result: %{},\n    ...>   execution_metadata: %{},\n    ...>   request_id: \"req_123\",\n    ...>   performance_metrics: %{}\n    ...> }\n    iex> AriaEngine.Membrane.Format.PlanningResult.valid?(result)\n    true\n"
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = result) do
    result.status in [:success, :failure, :error] and is_map(result.execution_metadata) and
      is_binary(result.request_id) and is_map(result.performance_metrics)
  end

  def valid?(_) do
    false
  end

  @doc "Creates a successful planning result.\n\n## Examples\n\n    iex> plan = %{actions: []}\n    iex> metadata = %{executed_at: DateTime.utc_now()}\n    iex> metrics = %{execution_time_ms: 100}\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.success(\n    ...>   plan, \"req_123\", metadata, metrics\n    ...> )\n    iex> result.status\n    :success\n"
  @spec success(term(), String.t(), map(), map()) :: t()
  def success(plan_result, request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :success,
      result: plan_result,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc "Creates a failed planning result.\n\n## Examples\n\n    iex> metadata = %{failure_reason: \"No solution found\"}\n    iex> metrics = %{execution_time_ms: 50}\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.failure(\n    ...>   \"req_123\", metadata, metrics\n    ...> )\n    iex> result.status\n    :failure\n"
  @spec failure(String.t(), map(), map()) :: t()
  def failure(request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :failure,
      result: nil,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc "Creates an error planning result.\n\n## Examples\n\n    iex> metadata = %{error_reason: \"Invalid domain\"}\n    iex> metrics = %{execution_time_ms: 10}\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.error(\n    ...>   \"req_123\", metadata, metrics\n    ...> )\n    iex> result.status\n    :error\n"
  @spec error(String.t(), map(), map()) :: t()
  def error(request_id, execution_metadata, performance_metrics) do
    %__MODULE__{
      status: :error,
      result: nil,
      execution_metadata:
        Map.merge(execution_metadata, %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        }),
      request_id: request_id,
      performance_metrics: performance_metrics
    }
  end

  @doc "Creates a planning result from HybridCoordinator execution.\n\n## Examples\n\n    iex> start_time = System.monotonic_time(:microsecond)\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.from_execution(\n    ...>   {:ok, %{plan: []}}, \"req_123\", start_time\n    ...> )\n    iex> result.status\n    :success\n"
  @spec from_execution({:ok, term()} | {:error, term()}, String.t(), integer()) :: t()
  def from_execution({:ok, plan_result}, request_id, start_time) do
    execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

    success(
      plan_result,
      request_id,
      %{executed_at: DateTime.utc_now()},
      %{execution_time_ms: execution_time_ms}
    )
  end

  def from_execution({:error, reason}, request_id, start_time) do
    execution_time_ms = div(System.monotonic_time(:microsecond) - start_time, 1000)

    error(
      request_id,
      %{error_reason: reason},
      %{execution_time_ms: execution_time_ms}
    )
  end

  @doc "Checks if the planning result represents a successful execution.\n\n## Examples\n\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.success(\n    ...>   %{}, \"req_123\", %{}, %{}\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningResult.success?(result)\n    true\n"
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{status: :success}) do
    true
  end

  def success?(_) do
    false
  end

  @doc "Gets the error reason from error planning results.\n\n## Examples\n\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.error(\n    ...>   \"req_123\", %{error_reason: \"test error\"}, %{}\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningResult.error_reason(result)\n    \"test error\"\n"
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{execution_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc "Gets the execution time in milliseconds.\n\n## Examples\n\n    iex> result = AriaEngine.Membrane.Format.PlanningResult.success(\n    ...>   %{}, \"req_123\", %{}, %{execution_time_ms: 150}\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningResult.execution_time_ms(result)\n    150\n"
  @spec execution_time_ms(t()) :: integer() | nil
  def execution_time_ms(%__MODULE__{performance_metrics: metrics}) do
    Map.get(metrics, :execution_time_ms)
  end

  @doc "Converts planning result to a map for serialization.\n"
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = result) do
    %{
      "status" => Atom.to_string(result.status),
      "result" =>
        if result.result do
          inspect(result.result)
        else
          nil
        end,
      "execution_metadata" => result.execution_metadata,
      "request_id" => result.request_id,
      "performance_metrics" => result.performance_metrics
    }
  end
end