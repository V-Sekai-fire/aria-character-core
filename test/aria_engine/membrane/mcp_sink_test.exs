# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.MCPSinkTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.MCPSink
  alias AriaEngine.Membrane.Format.MCPResponse
  alias Membrane.Buffer

  describe "MCPSink initialization" do
    test "initializes with target_pid option" do
      test_pid = self()

      # Test basic initialization
      assert {[], state} = MCPSink.handle_init(nil, %{target_pid: test_pid})
      assert state.target_pid == test_pid
    end

    test "initializes with default options" do
      test_pid = self()

      assert {[], state} =
               MCPSink.handle_init(nil, %{
                 target_pid: test_pid,
                 telemetry_prefix: [:aria_engine, :membrane, :mcp_sink]
               })

      assert state.target_pid == test_pid
      assert state.telemetry_prefix == [:aria_engine, :membrane, :mcp_sink]
    end
  end

  describe "MCPResponse message delivery" do
    test "delivers MCP response via message passing to target process" do
      # Arrange: Create a test process to receive messages
      test_pid = self()

      # Create MCPResponse payload
      response_payload = %MCPResponse{
        request_id: "test-123",
        status: "success",
        schedule: %{
          "activities" => [],
          "timeline" => %{},
          "resources" => %{}
        },
        error_details: nil,
        response_metadata: %{
          processed_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }
      }

      # Initialize sink state
      {[], state} = MCPSink.handle_init(nil, %{target_pid: test_pid})

      # Process buffer
      buffer = %Buffer{payload: response_payload}
      {[], new_state} = MCPSink.handle_buffer(:input, buffer, nil, state)

      # Assert: Should receive message with response
      assert_receive {:mcp_response, "test-123", ^response_payload}, 1000

      # Verify state updates
      assert new_state.messages_sent == 1
    end

    test "handles multiple responses in sequence" do
      # Arrange
      test_pid = self()

      response1 = %MCPResponse{
        request_id: "req-1",
        status: "success",
        schedule: %{"activities" => ["activity-1"]},
        error_details: nil,
        response_metadata: %{}
      }

      response2 = %MCPResponse{
        request_id: "req-2",
        status: "success",
        schedule: %{"activities" => ["activity-2"]},
        error_details: nil,
        response_metadata: %{}
      }

      # Initialize sink state
      {[], state} = MCPSink.handle_init(nil, %{target_pid: test_pid})

      # Process first buffer
      buffer1 = %Buffer{payload: response1}
      {[], state2} = MCPSink.handle_buffer(:input, buffer1, nil, state)

      # Process second buffer
      buffer2 = %Buffer{payload: response2}
      {[], state3} = MCPSink.handle_buffer(:input, buffer2, nil, state2)

      # Assert: Should receive both messages in order
      assert_receive {:mcp_response, "req-1", ^response1}, 1000
      assert_receive {:mcp_response, "req-2", ^response2}, 1000

      # Verify state updates
      assert state3.messages_sent == 2
    end

    test "handles error responses gracefully" do
      # Arrange
      test_pid = self()

      error_response = %MCPResponse{
        request_id: "error-123",
        status: "error",
        schedule: nil,
        error_details: "Invalid input parameters",
        response_metadata: %{}
      }

      # Initialize sink state
      {[], state} = MCPSink.handle_init(nil, %{target_pid: test_pid})

      # Process buffer
      buffer = %Buffer{payload: error_response}
      {[], new_state} = MCPSink.handle_buffer(:input, buffer, nil, state)

      # Assert: Should receive error response
      assert_receive {:mcp_response, "error-123", ^error_response}, 1000

      # Verify state updates
      assert new_state.messages_sent == 1
    end

    test "ignores malformed payloads without crashing" do
      # Arrange
      test_pid = self()

      # Malformed payload (not MCPResponse struct)
      malformed_payload = %{not_a_response: "invalid"}

      # Initialize sink state
      {[], state} = MCPSink.handle_init(nil, %{target_pid: test_pid})

      # Process buffer with malformed payload
      buffer = %Buffer{payload: malformed_payload}
      {[], new_state} = MCPSink.handle_buffer(:input, buffer, nil, state)

      # Assert: Should not receive any message for malformed payload
      refute_receive {:mcp_response, _, _}, 500

      # Verify state updates (no message sent)
      assert new_state.messages_sent == 0
    end

    test "handles target process being down gracefully" do
      # Arrange: Create a process and then kill it
      {:ok, target_pid} = Task.start(fn -> :timer.sleep(100) end)
      Process.exit(target_pid, :kill)
      # Ensure process is dead
      :timer.sleep(50)

      response = %MCPResponse{
        request_id: "dead-target",
        status: "success",
        schedule: %{},
        error_details: nil,
        response_metadata: %{}
      }

      # Initialize sink state with dead process
      {[], state} = MCPSink.handle_init(nil, %{target_pid: target_pid})

      # Process buffer - should not crash
      buffer = %Buffer{payload: response}
      {[], new_state} = MCPSink.handle_buffer(:input, buffer, nil, state)

      # Verify state updates (message attempted but failed)
      assert new_state.messages_sent == 0
      assert new_state.send_failures == 1
    end
  end
end
