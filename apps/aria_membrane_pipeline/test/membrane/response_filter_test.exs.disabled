# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.ResponseFilterTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.ResponseFilter
  alias AriaEngine.Membrane.Format.{PlanningResult, MCPResponse}
  alias Membrane.Buffer

  describe "ResponseFilter initialization" do
    test "initializes with default options" do
      # Test basic initialization
      assert {[], _state} =
               ResponseFilter.handle_init(nil, %{
                 telemetry_prefix: [:aria_engine, :membrane, :response_filter]
               })
    end

    test "initializes with custom options" do
      # Test initialization with custom options
      assert {[], state} =
               ResponseFilter.handle_init(nil, %{
                 telemetry_prefix: [:test, :response_filter]
               })

      assert state.telemetry_prefix == [:test, :response_filter]
      assert state.processed_count == 0
      assert state.success_transforms == 0
      assert state.error_transforms == 0
    end
  end

  describe "PlanningResult → MCPResponse transformation" do
    test "transforms successful PlanningResult to MCPResponse" do
      # Create successful PlanningResult
      planning_result = %PlanningResult{
        status: :success,
        result: %{
          actions: [
            %{id: "action_1", type: "start", timestamp: 0},
            %{id: "action_2", type: "process", timestamp: 100}
          ],
          timeline: %{start: 0, end: 200, duration: 200},
          resources: %{"cpu" => "50%"},
          metadata: %{planning_method: "hybrid"}
        },
        execution_metadata: %{
          executed_at: DateTime.utc_now(),
          coordinator_version: "v2"
        },
        request_id: "planning_req_123",
        performance_metrics: %{execution_time_ms: 150}
      }

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: planning_result}

      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "success"
      assert response.request_id == "planning_req_123"
      assert response.error_details == nil

      # Verify schedule formatting
      assert response.schedule["activities"] |> length() == 2
      assert response.schedule["timeline"]["start"] == 0
      assert response.schedule["timeline"]["end"] == 200
      assert response.schedule["resources"]["cpu"] == "50%"
      assert response.schedule["metadata"]["planning_method"] == "hybrid"

      # Verify response metadata
      assert response.response_metadata.execution_time_ms == 150
      assert response.response_metadata.transformation_source == "response_filter"
      assert Map.has_key?(response.response_metadata, :planning_metadata)

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 1
      assert new_state.error_transforms == 0
    end

    test "transforms error PlanningResult to MCPResponse" do
      # Create error PlanningResult
      planning_result = %PlanningResult{
        status: :error,
        result: nil,
        execution_metadata: %{
          error_reason: "Planning timeout exceeded",
          executed_at: DateTime.utc_now()
        },
        request_id: "planning_error_456",
        performance_metrics: %{execution_time_ms: 5000}
      }

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: planning_result}

      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "error"
      assert response.request_id == "planning_error_456"
      assert response.schedule == nil
      assert response.error_details == "Planning timeout exceeded"

      # Verify response metadata
      assert response.response_metadata.execution_time_ms == 5000
      assert response.response_metadata.transformation_source == "response_filter"

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 0
      assert new_state.error_transforms == 1
    end

    test "handles PlanningResult with minimal plan data" do
      # Create PlanningResult with minimal plan structure
      planning_result = %PlanningResult{
        status: :success,
        # Minimal plan
        result: %{actions: []},
        execution_metadata: %{},
        request_id: "minimal_req_789",
        performance_metrics: %{execution_time_ms: 25}
      }

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: planning_result}

      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "success"
      assert response.request_id == "minimal_req_789"
      assert response.schedule["activities"] == []
      assert response.schedule["timeline"] == %{}
      assert response.schedule["resources"] == %{}

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 1
    end

    test "handles PlanningResult with unexpected plan format" do
      # Create PlanningResult with unexpected plan format
      planning_result = %PlanningResult{
        status: :success,
        # Not a map
        result: "unexpected_string_format",
        execution_metadata: %{},
        request_id: "unexpected_req_999",
        performance_metrics: %{execution_time_ms: 10}
      }

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: planning_result}

      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output (should handle gracefully)
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "success"
      assert response.request_id == "unexpected_req_999"
      assert response.schedule["activities"] == []
      assert response.schedule["metadata"]["error"] == "Unable to format plan result"

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 1
    end

    test "handles PlanningResult with unknown status" do
      # Create PlanningResult with unknown status
      planning_result = %PlanningResult{
        status: :unknown_status,
        result: nil,
        execution_metadata: %{},
        request_id: "unknown_status_req",
        performance_metrics: %{execution_time_ms: 5}
      }

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer
      buffer = %Buffer{payload: planning_result}

      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output (should default to error)
      assert %Buffer{payload: %MCPResponse{} = response} = output_buffer
      assert response.status == "error"
      assert response.request_id == "unknown_status_req"
      assert response.schedule == nil
      assert response.error_details == "Unexpected planning result status: unknown_status"

      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 0
      assert new_state.error_transforms == 1
    end
  end

  describe "unsupported payload types" do
    test "handles unsupported payload gracefully" do
      unsupported_payload = %{some: "random", data: 123}

      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process buffer with unsupported payload
      buffer = %Buffer{payload: unsupported_payload}

      # Should handle gracefully and pass through unchanged
      {[buffer: {:output, output_buffer}], new_state} =
        ResponseFilter.handle_buffer(:input, buffer, nil, state)

      # Verify output is unchanged
      assert %Buffer{payload: ^unsupported_payload} = output_buffer

      # Verify state updates (processed but no transforms)
      assert new_state.processed_count == 1
      assert new_state.success_transforms == 0
      assert new_state.error_transforms == 0
    end
  end

  describe "statistics and monitoring" do
    test "calculates success rate correctly" do
      # Initialize filter state
      {[], state} =
        ResponseFilter.handle_init(nil, %{
          telemetry_prefix: [:test, :response_filter]
        })

      # Process successful result
      success_result = %PlanningResult{
        status: :success,
        result: %{actions: []},
        execution_metadata: %{},
        request_id: "success_req",
        performance_metrics: %{execution_time_ms: 100}
      }

      buffer1 = %Buffer{payload: success_result}
      {[buffer: {:output, _}], state2} = ResponseFilter.handle_buffer(:input, buffer1, nil, state)

      # Process error result
      error_result = %PlanningResult{
        status: :error,
        result: nil,
        execution_metadata: %{error_reason: "Test error"},
        request_id: "error_req",
        performance_metrics: %{execution_time_ms: 50}
      }

      buffer2 = %Buffer{payload: error_result}

      {[buffer: {:output, _}], final_state} =
        ResponseFilter.handle_buffer(:input, buffer2, nil, state2)

      # Verify final state
      assert final_state.processed_count == 2
      assert final_state.success_transforms == 1
      assert final_state.error_transforms == 1
    end
  end
end
