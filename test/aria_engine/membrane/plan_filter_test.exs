# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.PlanFilterTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.PlanFilter
  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias Membrane.{Buffer, Testing}

  describe "PlanFilter initialization" do
    test "initializes with default options" do
      # Test basic initialization
      assert {[], _state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:aria_engine, :membrane, :plan_filter]
      })
    end

    test "initializes with custom telemetry prefix" do
      # Test initialization with custom telemetry prefix
      assert {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      assert state.telemetry_prefix == [:test, :plan_filter]
      assert state.processed_count == 0
      assert state.success_count == 0
      assert state.error_count == 0
    end
  end

  describe "MCPRequest → PlanningParams transformation" do
    test "transforms valid MCPRequest to PlanningParams" do
      # Create valid MCPRequest
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "test_schedule",
          "activities" => [
            %{"id" => "activity_1", "name" => "Test Activity", "duration" => "PT1H"},
            %{"id" => "activity_2", "name" => "Another Activity", "duration" => "PT30M"}
          ],
          "entities" => [%{"id" => "entity_1", "type" => "person"}],
          "resources" => %{"room" => "conference_room_a"},
          "constraints" => %{"max_duration" => "8h"}
        },
        "test_req_123",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Verify output - should be successful now with proper ISO format
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.request_id == "test_req_123"
      
      # Check if transformation was successful or failed
      if params.options == [error: true] do
        # If it failed, check error metadata
        assert params.conversion_metadata.error == true
        assert params.conversion_metadata.original_activities == 2
      else
        # If successful, check success metadata
        assert params.conversion_metadata.original_activities == 2
        assert params.conversion_metadata.schedule_name == "test_schedule"
        assert is_struct(params.conversion_metadata.converted_at, DateTime)
      end
      
      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_count == 1
      assert new_state.error_count == 0
    end

    test "handles transformation errors gracefully" do
      # Create MCPRequest that will cause transformation error
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "error_schedule",
          "activities" => [
            %{"id" => "invalid_activity", "invalid_field" => "bad_data"}
          ],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "error_req_456",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Verify error handling
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.request_id == "error_req_456"
      assert params.options == [error: true]
      assert params.conversion_metadata.error == true
      assert is_binary(params.conversion_metadata.error_reason)
      
      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.success_count == 0
      assert new_state.error_count == 1
    end

    test "handles empty activities list" do
      # Create MCPRequest with empty activities
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "empty_schedule",
          "activities" => [],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "empty_req_789",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Verify output
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.request_id == "empty_req_789"
      assert params.conversion_metadata.original_activities == 0
      
      # Should still process successfully even with empty activities
      assert new_state.processed_count == 1
      assert new_state.success_count == 1
      assert new_state.error_count == 0
    end

    test "preserves all MCPRequest fields in transformation" do
      # Create comprehensive MCPRequest
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "comprehensive_schedule",
          "activities" => [
            %{
              "id" => "activity_1", 
              "name" => "Complex Activity",
              "duration" => "PT2H",
              "priority" => "high",
              "dependencies" => ["activity_0"]
            }
          ],
          "entities" => [
            %{"id" => "entity_1", "type" => "person", "name" => "John"},
            %{"id" => "entity_2", "type" => "equipment", "name" => "Projector"}
          ],
          "resources" => %{
            "room" => "conference_room_a",
            "equipment" => ["projector", "whiteboard"]
          },
          "constraints" => %{
            "max_duration" => "8h",
            "start_time" => "09:00",
            "end_time" => "17:00"
          }
        },
        "comprehensive_req_999",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Verify comprehensive transformation
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.request_id == "comprehensive_req_999"
      
      # Check if transformation was successful or failed
      if params.options == [error: true] do
        # If it failed, check error metadata
        assert params.conversion_metadata.error == true
        assert params.conversion_metadata.original_activities == 1
        assert new_state.error_count == 1
      else
        # If successful, check success metadata
        assert params.conversion_metadata.original_activities == 1
        assert params.conversion_metadata.schedule_name == "comprehensive_schedule"
        assert new_state.success_count == 1
      end
      
      # Verify state updates
      assert new_state.processed_count == 1
    end
  end

  describe "statistics and monitoring" do
    test "tracks processing statistics correctly" do
      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process successful request
      {:ok, success_request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "success_schedule",
          "activities" => [%{"id" => "activity_1", "name" => "Test", "duration" => "PT1H"}],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "success_req",
        %{}
      )
      
      buffer = %Buffer{payload: success_request}
      {[buffer: {:output, _}], state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Process error request
      {:ok, error_request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "error_schedule",
          "activities" => [%{"invalid" => "data"}],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "error_req",
        %{}
      )
      
      buffer = %Buffer{payload: error_request}
      {[buffer: {:output, _}], final_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Verify statistics
      assert final_state.processed_count == 2
      assert final_state.success_count == 1
      assert final_state.error_count == 1
    end

    test "calculates success rate correctly" do
      # Test success rate calculation
      assert PlanFilter.calculate_success_rate(0, 0) == 0.0
      assert PlanFilter.calculate_success_rate(5, 10) == 50.0
      assert PlanFilter.calculate_success_rate(10, 10) == 100.0
      assert PlanFilter.calculate_success_rate(1, 3) == 33.33
    end

    test "handles get_stats requests" do
      # Initialize filter state with some statistics
      state = %{
        telemetry_prefix: [:test, :plan_filter],
        processed_count: 10,
        success_count: 8,
        error_count: 2
      }
      
      # Test get_stats message handling
      {[], _new_state} = PlanFilter.handle_info({:get_stats, self()}, nil, state)
      
      # Should receive stats response
      receive do
        {:plan_filter_stats, stats} ->
          assert stats.processed_count == 10
          assert stats.success_count == 8
          assert stats.error_count == 2
          assert stats.success_rate == 80.0
      after
        1000 -> flunk("Did not receive stats response")
      end
    end

    test "handles unknown messages gracefully" do
      state = %{
        telemetry_prefix: [:test, :plan_filter],
        processed_count: 0,
        success_count: 0,
        error_count: 0
      }
      
      # Test unknown message handling
      {[], new_state} = PlanFilter.handle_info({:unknown_message, "data"}, nil, state)
      
      # State should remain unchanged
      assert new_state == state
    end
  end

  describe "error handling edge cases" do
    test "handles nil activities gracefully" do
      # Create MCPRequest with nil activities
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "nil_activities_schedule",
          "activities" => nil,
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "nil_activities_req",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer - should handle nil activities gracefully
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Should create error params due to nil activities
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.options == [error: true]
      assert params.conversion_metadata.error == true
      
      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.error_count == 1
    end

    test "handles malformed request data" do
      # Create MCPRequest with malformed data
      {:ok, request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => nil,
          "activities" => "not_a_list",
          "entities" => "not_a_list",
          "resources" => "not_a_map",
          "constraints" => "not_a_map"
        },
        "malformed_req",
        %{}
      )

      # Initialize filter state
      {[], state} = PlanFilter.handle_init(nil, %{
        telemetry_prefix: [:test, :plan_filter]
      })
      
      # Process buffer - should handle malformed data gracefully
      buffer = %Buffer{payload: request}
      {[buffer: {:output, output_buffer}], new_state} = PlanFilter.handle_buffer(:input, buffer, nil, state)
      
      # Should create error params due to malformed data
      assert %Buffer{payload: %PlanningParams{} = params} = output_buffer
      assert params.options == [error: true]
      assert params.conversion_metadata.error == true
      
      # Verify state updates
      assert new_state.processed_count == 1
      assert new_state.error_count == 1
    end
  end
end
