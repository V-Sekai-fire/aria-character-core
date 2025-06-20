# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.MCPSink do
  @moduledoc """
  A Membrane sink element that delivers MCP responses via message passing.
  
  This element receives MCPResponse structs and sends them as messages to a target process.
  Designed for testing and integration scenarios where responses need to be delivered
  to a specific process for handling.
  """

  use Membrane.Sink

  alias AriaEngine.Membrane.Format.MCPResponse

  def_input_pad :input, accepted_format: _any

  @impl true
  def handle_init(_ctx, opts) do
    state = %{
      target_pid: opts[:target_pid] || self(),
      telemetry_prefix: opts[:telemetry_prefix] || [:aria_engine, :membrane, :mcp_sink],
      messages_sent: 0,
      send_failures: 0
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    case buffer.payload do
      %MCPResponse{} = response ->
        # Send message to target process
        case send_message_safely(state.target_pid, response) do
          :ok ->
            # Update state with successful send
            new_state = %{state | messages_sent: state.messages_sent + 1}
            emit_telemetry(state.telemetry_prefix, :message_sent, %{request_id: response.request_id})
            {[], new_state}
          
          :error ->
            # Update state with failed send
            new_state = %{state | send_failures: state.send_failures + 1}
            emit_telemetry(state.telemetry_prefix, :send_failure, %{request_id: response.request_id})
            {[], new_state}
        end
      
      _other ->
        # Ignore malformed payloads
        {[], state}
    end
  end

  # Private helper functions

  defp send_message_safely(target_pid, response) do
    if Process.alive?(target_pid) do
      try do
        send(target_pid, {:mcp_response, response.request_id, response})
        :ok
      rescue
        _error -> :error
      catch
        _error -> :error
      end
    else
      :error
    end
  end

  defp emit_telemetry(prefix, event, metadata) do
    :telemetry.execute(prefix ++ [event], %{count: 1}, metadata)
  end
end
