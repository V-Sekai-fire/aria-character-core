# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.MCPSink do
  @moduledoc """
  Production Membrane Sink element for MCP responses.

  This sink receives processed MCP responses and can store them,
  log them, or forward them to external systems.
  """
  use Membrane.Sink
  require Logger
  alias Membrane.Format.MCPResponse
  def_input_pad(:input, accepted_format: MCPResponse, flow_control: :manual, demand_unit: :buffers)

  def_options(
    storage_mode: [
      spec: :memory | :log | :callback,
      default: :log,
      description: "How to handle received responses"
    ],
    callback_pid: [
      spec: pid() | nil,
      default: nil,
      description: "PID to send responses to when using callback mode"
    ],
    max_stored_responses: [
      spec: pos_integer(),
      default: 100,
      description: "Maximum number of responses to store in memory"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      storage_mode: opts.storage_mode,
      callback_pid: opts.callback_pid,
      max_stored_responses: opts.max_stored_responses,
      stored_responses: [],
      response_count: 0
    }

    Logger.info("MCPSink initialized with storage_mode: #{opts.storage_mode}")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    response = buffer.payload

    case state.storage_mode do
      :memory ->
        handle_memory_storage(response, state)

      :log ->
        handle_log_storage(response, state)

      :callback ->
        handle_callback_storage(response, state)

      _ ->
        Logger.warning("Unknown storage mode: #{state.storage_mode}")
        {[], state}
    end
  end

  defp handle_memory_storage(response, state) do
    new_responses = [response | state.stored_responses] |> Enum.take(state.max_stored_responses)

    new_state = %{
      state
      | stored_responses: new_responses,
        response_count: state.response_count + 1
    }

    Logger.debug(
      "Stored response in memory (#{length(new_responses)}/#{state.max_stored_responses})"
    )

    {[], new_state}
  end

  defp handle_log_storage(response, state) do
    Logger.info("MCPSink received response: #{inspect(response, limit: :infinity)}")
    new_state = %{state | response_count: state.response_count + 1}
    {[], new_state}
  end

  defp handle_callback_storage(response, state) do
    if state.callback_pid do
      send(state.callback_pid, {:mcp_response, response})
      Logger.debug("Sent response to callback PID: #{inspect(state.callback_pid)}")
    else
      Logger.warning("Callback mode enabled but no callback_pid provided")
    end

    new_state = %{state | response_count: state.response_count + 1}
    {[], new_state}
  end

  @doc "Gets stored responses from the sink (only works with memory storage mode).\n"
  @spec get_stored_responses(pid()) :: [map()]
  def get_stored_responses(sink_pid) do
    send(sink_pid, {:get_responses, self()})

    receive do
      {:responses, responses} -> responses
    after
      5000 -> []
    end
  end

  @impl true
  def handle_info({:get_responses, from}, _ctx, state) do
    send(from, {:responses, state.stored_responses})
    {[], state}
  end

  @impl true
  def handle_info({:get_stats, from}, _ctx, state) do
    stats = %{
      storage_mode: state.storage_mode,
      response_count: state.response_count,
      stored_count: length(state.stored_responses),
      max_stored: state.max_stored_responses
    }

    send(from, {:sink_stats, stats})
    {[], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("MCPSink received unknown message: #{inspect(msg)}")
    {[], state}
  end
end
