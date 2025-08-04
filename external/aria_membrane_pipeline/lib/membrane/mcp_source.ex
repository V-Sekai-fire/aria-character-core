# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.MCPSource do
  @moduledoc """
  Production Membrane Source element that receives any MCP tool requests.

  This element acts as the universal entry point for all MCP tool calls,
  converting them to a standardized MCPRequest format for downstream processing.
  It supports any MCP tool, not just schedule_activities.

  ## Features

  - Receives any MCP tool requests from existing MCP tools
  - Converts raw MCP parameters to generic MCPRequest format
  - Generates unique request IDs for tracking
  - Supports both new tool_call format and legacy parameter format
  - Provides proper Membrane flow control and backpressure
  - Emits comprehensive telemetry for monitoring
  - Tool-agnostic design for maximum flexibility

  ## Supported Input Formats

  **New Format (Recommended):**
  ```elixir
  {:mcp_tool_call, "schedule_activities", %{"schedule_name" => "test"}, %{}}
  ```

  **Legacy Format (Backward Compatibility):**
  ```elixir
  {:mcp_request, %{"schedule_name" => "test", "activities" => []}}
  ```

  ## Usage

      # In a pipeline spec
      children = [
        child(:mcp_source, MCPSource)
        |> child(:schedule_filter, ScheduleFilter)  # For schedule_activities
        |> child(:planner_sink, PlannerSink)
        |> child(:mcp_sink, MCPSink)
      ]

      # Send new format MCP tool call
      Membrane.Pipeline.notify_child(pipeline, :mcp_source,
        {:mcp_tool_call, "schedule_activities", params, metadata})

      # Send legacy format (auto-detected)
      Membrane.Pipeline.notify_child(pipeline, :mcp_source,
        {:mcp_request, legacy_params})
  """
  use Membrane.Source
  require Logger
  alias Membrane.Format.MCPRequest
  alias Membrane.Buffer
  def_output_pad(:output, accepted_format: MCPRequest, flow_control: :manual)

  def_options(
    request_queue: [
      spec: :queue.queue(),
      default: :queue.new(),
      description: "Internal queue for managing MCP requests"
    ],
    pipeline_config: [
      spec: map(),
      default: %{},
      description: "Pipeline topology and element configuration"
    ],
    max_queue_size: [
      spec: pos_integer(),
      default: 100,
      description: "Maximum number of queued requests before backpressure"
    ],
    telemetry_prefix: [
      spec: [atom()],
      default: [:aria_engine, :membrane, :mcp_source],
      description: "Telemetry event prefix for monitoring"
    ]
  )

  @typedoc "Internal state of the MCPSource element"
  @type state :: %{
          request_queue: :queue.queue(),
          pipeline_config: map(),
          max_queue_size: pos_integer(),
          request_counter: non_neg_integer(),
          active_pipelines: map(),
          telemetry_prefix: [atom()],
          processed_count: non_neg_integer(),
          error_count: non_neg_integer(),
          queue_size: non_neg_integer(),
          demand: non_neg_integer()
        }
  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      request_queue: opts.request_queue,
      pipeline_config: opts.pipeline_config,
      max_queue_size: opts.max_queue_size,
      request_counter: 0,
      active_pipelines: %{},
      telemetry_prefix: opts.telemetry_prefix,
      processed_count: 0,
      error_count: 0,
      queue_size: 0,
      demand: 0
    }

    Logger.info("MCPSource initialized with max_queue_size: #{opts.max_queue_size}")
    emit_telemetry(state.telemetry_prefix, :initialized, %{max_queue_size: opts.max_queue_size})
    {[], state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    Logger.debug("MCPSource received demand for #{size} buffers")
    new_state = %{state | demand: state.demand + size}
    {actions, final_state} = send_queued_buffers(new_state)
    {actions, final_state}
  end

  @impl true
  def handle_info({:mcp_tool_call, tool_name, parameters, metadata}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    case handle_mcp_tool_call(tool_name, parameters, metadata, state) do
      {:ok, mcp_request, new_state} ->
        if new_state.demand > 0 do
          buffer = %Buffer{payload: mcp_request}

          emit_telemetry(state.telemetry_prefix, :tool_call_processed, %{
            request_id: mcp_request.request_id,
            tool_name: tool_name,
            processing_time: System.monotonic_time(:microsecond) - start_time,
            queue_size: new_state.queue_size
          })

          updated_state = %{
            new_state
            | processed_count: new_state.processed_count + 1,
              demand: new_state.demand - 1
          }

          {[buffer: {:output, buffer}], updated_state}
        else
          queued_state = %{
            new_state
            | request_queue: :queue.in(mcp_request, new_state.request_queue),
              queue_size: new_state.queue_size + 1
          }

          {[], queued_state}
        end

      {:error, reason, new_state} ->
        Logger.warning("MCPSource tool call processing failed: #{reason}")

        emit_telemetry(state.telemetry_prefix, :tool_call_error, %{
          tool_name: tool_name,
          error_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        updated_state = %{new_state | error_count: new_state.error_count + 1}
        {[], updated_state}

      {:queue_full, new_state} ->
        Logger.warning("MCPSource queue full, dropping tool call")

        emit_telemetry(state.telemetry_prefix, :queue_full, %{
          tool_name: tool_name,
          queue_size: new_state.queue_size,
          max_queue_size: new_state.max_queue_size
        })

        {[], new_state}
    end
  end

  @impl true
  def handle_info({:mcp_request, mcp_params}, _ctx, state) do
    start_time = System.monotonic_time(:microsecond)

    case handle_mcp_request(mcp_params, state) do
      {:ok, mcp_request, new_state} ->
        if new_state.demand > 0 do
          buffer = %Buffer{payload: mcp_request}

          emit_telemetry(state.telemetry_prefix, :request_processed, %{
            request_id: mcp_request.request_id,
            processing_time: System.monotonic_time(:microsecond) - start_time,
            queue_size: new_state.queue_size
          })

          updated_state = %{
            new_state
            | processed_count: new_state.processed_count + 1,
              demand: new_state.demand - 1
          }

          {[buffer: {:output, buffer}], updated_state}
        else
          queued_state = %{
            new_state
            | request_queue: :queue.in(mcp_request, new_state.request_queue),
              queue_size: new_state.queue_size + 1
          }

          {[], queued_state}
        end

      {:error, reason, new_state} ->
        Logger.warning("MCPSource request processing failed: #{reason}")

        emit_telemetry(state.telemetry_prefix, :request_error, %{
          error_reason: reason,
          processing_time: System.monotonic_time(:microsecond) - start_time
        })

        updated_state = %{new_state | error_count: new_state.error_count + 1}
        {[], updated_state}

      {:queue_full, new_state} ->
        Logger.warning("MCPSource queue full, dropping request")

        emit_telemetry(state.telemetry_prefix, :queue_full, %{
          queue_size: new_state.queue_size,
          max_queue_size: new_state.max_queue_size
        })

        {[], new_state}
    end
  end

  @impl true
  def handle_info({:configure_pipeline, config}, _ctx, state) do
    Logger.info("MCPSource pipeline configuration updated")

    emit_telemetry(state.telemetry_prefix, :pipeline_configured, %{
      topology: Map.get(config, :topology, :unknown),
      element_count: length(Map.get(config, :elements, []))
    })

    new_state = %{state | pipeline_config: config}
    {[], new_state}
  end

  @impl true
  def handle_info({:get_status, from}, _ctx, state) do
    status = %{
      processed_count: state.processed_count,
      error_count: state.error_count,
      queue_size: state.queue_size,
      max_queue_size: state.max_queue_size,
      pipeline_config: state.pipeline_config,
      active_pipelines: map_size(state.active_pipelines),
      demand: state.demand
    }

    send(from, {:mcp_source_status, status})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("MCPSource received unknown message: #{inspect(msg)}")
    {[], state}
  end

  defp send_queued_buffers(state) when state.demand == 0 do
    {[], state}
  end

  defp send_queued_buffers(state) do
    case :queue.out(state.request_queue) do
      {{:value, mcp_request}, remaining_queue} ->
        buffer = %Buffer{payload: mcp_request}

        new_state = %{
          state
          | request_queue: remaining_queue,
            queue_size: state.queue_size - 1,
            demand: state.demand - 1,
            processed_count: state.processed_count + 1
        }

        emit_telemetry(state.telemetry_prefix, :request_processed, %{
          request_id: mcp_request.request_id,
          processing_time: 0,
          queue_size: new_state.queue_size
        })

        {more_actions, final_state} = send_queued_buffers(new_state)
        {[buffer: {:output, buffer}] ++ more_actions, final_state}

      {:empty, _} ->
        {[], state}
    end
  end

  defp handle_mcp_tool_call(tool_name, parameters, metadata, state) do
    cond do
      state.queue_size >= state.max_queue_size ->
        {:queue_full, state}

      not is_binary(tool_name) ->
        {:error, "Tool name must be a string", state}

      not is_map(parameters) ->
        {:error, "Parameters must be a map", state}

      not is_map(metadata) ->
        {:error, "Metadata must be a map", state}

      true ->
        case create_mcp_request_from_tool_call(tool_name, parameters, metadata, state) do
          {:ok, mcp_request} ->
            new_state = %{state | request_counter: state.request_counter + 1}
            {:ok, mcp_request, new_state}

          {:error, reason} ->
            {:error, reason, state}
        end
    end
  end

  defp handle_mcp_request(mcp_params, state) do
    cond do
      state.queue_size >= state.max_queue_size ->
        {:queue_full, state}

      not is_map(mcp_params) ->
        {:error, "Invalid MCP parameters format", state}

      true ->
        {:ok, mcp_request} = create_mcp_request(mcp_params, state)
        new_state = %{state | request_counter: state.request_counter + 1}
        {:ok, mcp_request, new_state}
    end
  end

  defp create_mcp_request_from_tool_call(tool_name, parameters, metadata, state) do
    request_id = generate_request_id(state.request_counter)

    case MCPRequest.from_tool_call(tool_name, parameters, request_id, metadata) do
      {:ok, mcp_request} -> {:ok, mcp_request}
      {:error, reason} -> {:error, "Failed to create MCPRequest from tool call: #{reason}"}
    end
  end

  defp create_mcp_request(mcp_params, state) do
    request_id = generate_request_id(state.request_counter)
    {:ok, mcp_request} = MCPRequest.from_mcp_params(mcp_params, request_id)
    {:ok, mcp_request}
  end

  defp generate_request_id(counter) do
    timestamp = System.system_time(:millisecond)
    "mcp_req_#{timestamp}_#{counter}"
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end

  @doc "Gets the current status and metrics of the MCPSource element.\n\nThis function should be called from outside the pipeline to get status.\n\n## Parameters\n\n- `pipeline_pid` - PID of the pipeline containing the MCPSource\n- `source_name` - Name of the MCPSource element in the pipeline (default: :mcp_source)\n- `timeout` - Timeout in milliseconds (default: 5000)\n\n## Returns\n\nMap containing current status information or error.\n"
  @spec get_status(pid(), atom(), timeout()) :: map()
  def get_status(pipeline_pid, source_name \\ :mcp_source, timeout \\ 5000) do
    case Membrane.Testing.Pipeline.get_child_pid(pipeline_pid, source_name) do
      {:ok, source_pid} ->
        send(source_pid, {:get_status, self()})

        receive do
          {:mcp_source_status, status} -> status
        after
          timeout -> %{error: "Timeout waiting for status"}
        end

      {:error, reason} ->
        %{error: "Failed to get source PID: #{inspect(reason)}"}
    end
  end
end
