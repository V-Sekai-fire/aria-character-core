defmodule AriaEngine.Membrane.MCPScheduleFilter do
  @moduledoc "Membrane Filter element that processes MCP requests and prepares them for schedule processing.\n\nThis filter sits at the beginning of the schedule processing pipeline and handles:\n1. Initial MCP request validation\n2. Request routing and filtering\n3. Format normalization for downstream processing\n4. Request metadata enrichment\n\n## Pipeline Position\n\n```\nMCPSource → MCPScheduleFilter → SchedulePlannerFilter → PlannerFilter → PlannerMCPFilter → MCPSink\n```\n\nThe MCPScheduleFilter acts as the entry point for MCP requests into the scheduling pipeline,\nensuring only valid schedule-related requests proceed to downstream processing.\n\n## Features\n\n- Validates incoming MCP request format\n- Filters for schedule-related tool calls\n- Enriches requests with processing metadata\n- Provides request routing and rejection capabilities\n- Comprehensive telemetry for request processing\n\n## Usage\n\n    # In a pipeline spec\n    children = [\n      child(:mcp_source, MCPSource)\n      |> child(:mcp_schedule_filter, MCPScheduleFilter)\n      |> child(:schedule_planner_filter, SchedulePlannerFilter)\n      |> child(:planner_filter, PlannerFilter)\n      |> child(:planner_mcp_filter, PlannerMCPFilter)\n      |> child(:mcp_sink, MCPSink)\n    ]\n"
  use Membrane.Filter
  require Logger
  alias AriaEngine.Membrane.Format.MCPRequest
  alias Membrane.Buffer
  def_input_pad(:input, accepted_format: MCPRequest, flow_control: :auto)
  def_output_pad(:output, accepted_format: MCPRequest, flow_control: :auto)

  def_options(
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :mcp_schedule_filter],
      description: "Telemetry event prefix for monitoring"
    ],
    allowed_tools: [
      spec: [String.t()],
      default: ["schedule_activities"],
      description: "List of allowed tool names to process"
    ],
    strict_filtering: [
      spec: boolean(),
      default: true,
      description: "Whether to strictly filter non-allowed tools"
    ],
    enrich_metadata: [
      spec: boolean(),
      default: true,
      description: "Whether to enrich requests with processing metadata"
    ]
  )

  @typedoc "Internal state of the MCPScheduleFilter element"
  @type state :: %{
          telemetry_prefix: [atom()],
          allowed_tools: [String.t()],
          strict_filtering: boolean(),
          enrich_metadata: boolean(),
          processed_count: non_neg_integer(),
          accepted_count: non_neg_integer(),
          rejected_count: non_neg_integer(),
          error_count: non_neg_integer()
        }
  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      telemetry_prefix: opts.telemetry_prefix,
      allowed_tools: opts.allowed_tools,
      strict_filtering: opts.strict_filtering,
      enrich_metadata: opts.enrich_metadata,
      processed_count: 0,
      accepted_count: 0,
      rejected_count: 0,
      error_count: 0
    }

    Logger.info(
      "MCPScheduleFilter initialized with allowed_tools: #{inspect(opts.allowed_tools)}"
    )

    emit_telemetry(state.telemetry_prefix, :initialized, %{
      allowed_tools: opts.allowed_tools,
      strict_filtering: opts.strict_filtering,
      enrich_metadata: opts.enrich_metadata
    })

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: mcp_request}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    case process_mcp_request(mcp_request, state) do
      {:ok, processed_request} ->
        emit_telemetry(state.telemetry_prefix, :request_accepted, %{
          request_id: mcp_request.request_id,
          tool_name: mcp_request.tool_name,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        output_buffer = %Buffer{payload: processed_request}

        new_state = %{
          state
          | processed_count: state.processed_count + 1,
            accepted_count: state.accepted_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:reject, reason} ->
        Logger.info("MCPScheduleFilter rejected request: #{reason}")

        emit_telemetry(state.telemetry_prefix, :request_rejected, %{
          request_id: mcp_request.request_id,
          tool_name: mcp_request.tool_name,
          rejection_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        rejection_request = create_rejection_request(mcp_request, reason)
        output_buffer = %Buffer{payload: rejection_request}

        new_state = %{
          state
          | processed_count: state.processed_count + 1,
            rejected_count: state.rejected_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}

      {:error, reason} ->
        Logger.warning("MCPScheduleFilter processing error: #{reason}")

        emit_telemetry(state.telemetry_prefix, :processing_error, %{
          request_id: mcp_request.request_id,
          tool_name: mcp_request.tool_name,
          error_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        error_request = create_error_request(mcp_request, reason)
        output_buffer = %Buffer{payload: error_request}

        new_state = %{
          state
          | processed_count: state.processed_count + 1,
            error_count: state.error_count + 1
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      processed_count: state.processed_count,
      accepted_count: state.accepted_count,
      rejected_count: state.rejected_count,
      error_count: state.error_count,
      acceptance_rate: calculate_acceptance_rate(state.accepted_count, state.processed_count),
      allowed_tools: state.allowed_tools,
      strict_filtering: state.strict_filtering
    }

    send(from, {:mcp_schedule_filter_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("MCPScheduleFilter received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp process_mcp_request(%MCPRequest{} = request, state) do
    with :ok <- validate_request_format(request),
         :ok <-
           check_tool_allowed(request.tool_name, state.allowed_tools, state.strict_filtering),
         {:ok, enriched_request} <- maybe_enrich_metadata(request, state.enrich_metadata) do
      {:ok, enriched_request}
    else
      {:error, reason} -> {:error, reason}
      {:reject, reason} -> {:reject, reason}
    end
  end

  defp validate_request_format(%MCPRequest{} = request) do
    cond do
      is_nil(request.request_id) or request.request_id == "" ->
        {:error, "Missing or empty request_id"}

      is_nil(request.tool_name) or request.tool_name == "" ->
        {:error, "Missing or empty tool_name"}

      not is_map(request.parameters) ->
        {:error, "Invalid parameters format - must be a map"}

      true ->
        :ok
    end
  end

  defp check_tool_allowed(tool_name, allowed_tools, strict_filtering) do
    if tool_name in allowed_tools do
      :ok
    else
      if strict_filtering do
        {:reject, "Tool '#{tool_name}' not allowed in schedule processing pipeline"}
      else
        :ok
      end
    end
  end

  defp maybe_enrich_metadata(%MCPRequest{} = request, true) do
    enriched_metadata =
      Map.merge(request.metadata || %{}, %{
        mcp_schedule_filter: %{
          processed_at: DateTime.utc_now(),
          filter_version: "1.0.0",
          pipeline_stage: "mcp_schedule_entry"
        }
      })

    enriched_request = %{request | metadata: enriched_metadata}
    {:ok, enriched_request}
  end

  defp maybe_enrich_metadata(%MCPRequest{} = request, false) do
    {:ok, request}
  end

  defp create_rejection_request(%MCPRequest{} = original_request, reason) do
    %MCPRequest{
      request_id: original_request.request_id,
      tool_name: original_request.tool_name,
      parameters: original_request.parameters,
      timestamp: original_request.timestamp,
      metadata:
        Map.merge(original_request.metadata || %{}, %{
          mcp_schedule_filter: %{
            status: :rejected,
            rejection_reason: reason,
            processed_at: DateTime.utc_now()
          }
        })
    }
  end

  defp create_error_request(%MCPRequest{} = original_request, reason) do
    %MCPRequest{
      request_id: original_request.request_id,
      tool_name: original_request.tool_name,
      parameters: original_request.parameters,
      timestamp: original_request.timestamp,
      metadata:
        Map.merge(original_request.metadata || %{}, %{
          mcp_schedule_filter: %{
            status: :error,
            error_reason: reason,
            processed_at: DateTime.utc_now()
          }
        })
    }
  end

  defp calculate_acceptance_rate(_accepted, 0) do
    0.0
  end

  defp calculate_acceptance_rate(accepted, total) do
    accepted / total * 100.0
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current processing statistics of the MCPScheduleFilter element.\n\n## Parameters\n\n- `filter_pid` - PID of the MCPScheduleFilter element\n- `timeout` - Timeout in milliseconds (default: 5000)\n\n## Returns\n\nMap containing current statistics or error.\n"
  @spec get_stats(pid(), timeout()) :: map()
  def get_stats(filter_pid, timeout \\ 5000) do
    send(filter_pid, {:get_stats, self()})

    receive do
      {:mcp_schedule_filter_stats, stats} -> stats
    after
      timeout -> %{error: "Timeout waiting for stats"}
    end
  end

  @doc "Validates that a tool name is allowed for schedule processing.\n\nThis is useful for testing tool filtering logic independently.\n"
  @spec tool_allowed?(String.t(), [String.t()]) :: boolean()
  def tool_allowed?(tool_name, allowed_tools)
      when is_binary(tool_name) and is_list(allowed_tools) do
    tool_name in allowed_tools
  end

  def tool_allowed?(_, _) do
    false
  end
end