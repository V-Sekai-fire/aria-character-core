# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.FormatTransformerFilterTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.FormatTransformerFilter
  alias AriaEngine.Membrane.Format.{MCPRequest, MCPResponse, PlanningParams, PlanningResult}
  alias Membrane.{Buffer}

  describe "FormatTransformerFilter initialization" do
    test "initializes with default options" do
      # Test basic initialization
      assert {[], _state} =
               FormatTransformerFilter.handle_init(nil, %{
                 mock_scenario: :success,
                 processing_delay_ms: 0,
                 output_format: :auto,
                 telemetry_prefix: [:aria_engine, :membrane, :format_transformer_filter]
               })
    end

    test "initializes with custom options" do
      # Test initialization with custom options
      assert {[], state} =
               FormatTransformerFilter.handle_init(nil, %{
                 mock_scenario: :error,
                 processing_delay_ms: 100,
                 output_format: :auto,
                 telemetry_prefix: [:test, :format_transformer_filter]
               })

      assert state.mock_scenario == :error
      assert state.processing_delay_ms == 100
      assert state.telemetry_prefix == [:test, :format_transformer_filter]
    end
  end

  describe "MCPRequest → MCPResponse transformation" do
    test "transforms MCPRequest to successful MCPResponse" do
      # Create MCPRequest using the correct format
      {:ok, request} =
        MCPRequest.from_tool_call(
          "schedule_activities",
          %{
            "schedule_name" => "test_schedule",
            "activities" => [
              %{"id" => "activity_1", "name" => "Test Activity"},
              %{"id" => "activity_2", "name" => "Another Activity"}
            ],
            "entities" => [%{"id" => "entity_1", "type" => "person"}],
            "resources" => %{"room" => "conference_room_a"},
            "constraints" => %{"max_duration" => "8h"}
          },
          "test_req_123",
          %{}
        )

      # Initialize filter state
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :success,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: request}

      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "success"
      assert response.request_id == "test_req_123"
      assert response.error_details == nil
      assert response.schedule["schedule_name"] == "test_schedule"
      assert length(response.schedule["activities"]) == 2
      assert response.response_metadata.mock == true
      assert response.response_metadata.scenario == :success

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.mcp_transforms == 1
    end

    test "transforms MCPRequest to error MCPResponse" do
      {:ok, request} =
        MCPRequest.from_tool_call(
          "schedule_activities",
          %{
            "schedule_name" => "error_schedule",
            "activities" => [],
            "entities" => [],
            "resources" => %{},
            "constraints" => %{}
          },
          "error_req_456",
          %{}
        )

      # Initialize filter state with error scenario
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :error,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: request}

      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "error"
      assert response.request_id == "error_req_456"
      assert response.schedule == nil
      assert response.error_details == "Mock error scenario for testing"
      assert response.response_metadata.scenario == :error

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.mcp_transforms == 1
    end

    test "transforms MCPRequest to timeout MCPResponse" do
      {:ok, request} =
        MCPRequest.from_tool_call(
          "schedule_activities",
          %{
            "schedule_name" => "timeout_schedule",
            "activities" => [],
            "entities" => [],
            "resources" => %{},
            "constraints" => %{}
          },
          "timeout_req_789",
          %{}
        )

      # Initialize filter state with timeout scenario
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :timeout,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: request}

      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "timeout"
      assert response.request_id == "timeout_req_789"
      assert response.schedule == nil
      assert response.error_details == "Mock timeout scenario for testing"
      assert response.response_metadata.scenario == :timeout

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.mcp_transforms == 1
    end
  end

  describe "PlanningParams → PlanningResult transformation" do
    test "transforms PlanningParams to successful PlanningResult" do
      params = %PlanningParams{
        # Mock domain
        domain: nil,
        # Mock state
        state: nil,
        goals: [
          {:achieve, {:scheduled, "activity_1"}},
          {:achieve, {:scheduled, "activity_2"}}
        ],
        options: [],
        request_id: "planning_req_123",
        conversion_metadata: %{
          converted_at: DateTime.utc_now(),
          original_activities: 2
        }
      }

      # Initialize filter state
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :success,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: params}

      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.status == :success
      assert result.request_id == "planning_req_123"
      assert result.result.actions |> length() == 3
      assert result.execution_metadata.mock == true
      assert result.execution_metadata.scenario == :success

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.planning_transforms == 1
    end

    test "transforms PlanningParams to error PlanningResult" do
      params = %PlanningParams{
        domain: nil,
        state: nil,
        goals: [],
        options: [],
        request_id: "planning_error_456",
        conversion_metadata: %{converted_at: DateTime.utc_now()}
      }

      # Initialize filter state with error scenario
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :error,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: params}

      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %PlanningResult{} = result} = output_buffer
      assert result.status == :error
      assert result.request_id == "planning_error_456"
      assert result.result == nil
      assert result.execution_metadata.error_reason == "Mock planning error for testing"
      assert result.execution_metadata.scenario == :error

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.planning_transforms == 1
    end
  end

  describe "unsupported payload types" do
    test "handles unsupported payload gracefully" do
      unsupported_payload = %{some: "random", data: 123}

      # Initialize filter state
      {[], state} =
        FormatTransformerFilter.handle_init(nil, %{
          mock_scenario: :success,
          processing_delay_ms: 0,
          output_format: :auto,
          telemetry_prefix: [:test, :format_transformer_filter]
        })

      # Process buffer with unsupported payload
      buffer = %Buffer{payload: unsupported_payload}

      # Should handle gracefully and pass through unchanged
      {[buffer: {:output, output_buffer}], new_state} =
        FormatTransformerFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output is unchanged
      assert %Buffer{payload: ^unsupported_payload} = output_buffer

      # Verify state updates (processed but no transforms)
      assert new_state.processed_count == 1
      assert new_state.mcp_transforms == 0
      assert new_state.planning_transforms == 0
    end
  end
end
