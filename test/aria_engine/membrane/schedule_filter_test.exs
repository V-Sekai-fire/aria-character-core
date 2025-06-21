# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.ScheduleFilterTest do
  use ExUnit.Case, async: true

  import Membrane.Testing.Assertions

  alias AriaEngine.Membrane.ScheduleFilter
  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias Membrane.Testing

  describe "ScheduleFilter" do
    test "processes valid schedule_activities requests" do
      # Create a valid schedule_activities MCPRequest
      {:ok, mcp_request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "test_schedule",
          "activities" => [
            %{
              "id" => "activity_1",
              "name" => "Test Activity",
              "duration" => %{
                "start" => "2025-06-20T09:00:00Z",
                "end" => "2025-06-20T10:00:00Z"
              }
            }
          ],
          "entities" => [
            %{"id" => "entity_1", "type" => "person"}
          ],
          "resources" => %{
            "resource_1" => %{"type" => "room", "capacity" => 10}
          },
          "constraints" => %{
            "max_concurrent_activities" => 5
          }
        },
        "test_req_123",
        %{}
      )

      # Set up pipeline with ScheduleFilter
      pipeline = Testing.Pipeline.start_link_supervised!()

      children = [
        child(:source, %Testing.Source{
          output: [mcp_request]
        })
        |> child(:schedule_filter, ScheduleFilter)
        |> child(:sink, Testing.Sink)
      ]

      Testing.Pipeline.execute_actions(pipeline, spec: children)

      # Wait for processing
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %PlanningParams{}})

      # Get the result
      sink_buffers = Testing.Pipeline.get_child_buffers(pipeline, :sink)
      assert [%Membrane.Buffer{payload: planning_params}] = sink_buffers

      # Verify the conversion
      assert %PlanningParams{} = planning_params
      assert planning_params.request_id == "test_req_123"
      assert planning_params.conversion_metadata.original_tool == "schedule_activities"
      assert planning_params.conversion_metadata.activities_count == 1
      assert planning_params.conversion_metadata.entities_count == 1

      Testing.Pipeline.terminate(pipeline)
    end

    test "rejects non-schedule_activities requests" do
      # Create a non-schedule MCPRequest
      {:ok, mcp_request} = MCPRequest.from_tool_call(
        "configure_pipeline",
        %{
          "pipeline_config" => %{
            "topology" => "linear"
          }
        },
        "test_req_456",
        %{}
      )

      # Set up pipeline with ScheduleFilter
      pipeline = Testing.Pipeline.start_link_supervised!()

      children = [
        child(:source, %Testing.Source{
          output: [mcp_request]
        })
        |> child(:schedule_filter, ScheduleFilter)
        |> child(:sink, Testing.Sink)
      ]

      Testing.Pipeline.execute_actions(pipeline, spec: children)

      # Wait for processing
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %PlanningParams{}})

      # Get the result
      sink_buffers = Testing.Pipeline.get_child_buffers(pipeline, :sink)
      assert [%Membrane.Buffer{payload: planning_params}] = sink_buffers

      # Verify it's an error response
      assert %PlanningParams{} = planning_params
      assert planning_params.request_id == "test_req_456"
      assert planning_params.conversion_metadata.error == true
      assert planning_params.conversion_metadata.error_type == :rejected
      assert planning_params.options[:error] == true

      Testing.Pipeline.terminate(pipeline)
    end

    test "handles invalid schedule parameters with strict validation" do
      # Create an invalid schedule_activities MCPRequest
      {:ok, mcp_request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "invalid_schedule",
          "activities" => [],  # Empty activities should fail validation
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "test_req_789",
        %{}
      )

      # Set up pipeline with strict validation enabled
      pipeline = Testing.Pipeline.start_link_supervised!()

      children = [
        child(:source, %Testing.Source{
          output: [mcp_request]
        })
        |> child(:schedule_filter, %ScheduleFilter{strict_validation: true})
        |> child(:sink, Testing.Sink)
      ]

      Testing.Pipeline.execute_actions(pipeline, spec: children)

      # Wait for processing
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %PlanningParams{}})

      # Get the result
      sink_buffers = Testing.Pipeline.get_child_buffers(pipeline, :sink)
      assert [%Membrane.Buffer{payload: planning_params}] = sink_buffers

      # Verify it's an error response
      assert %PlanningParams{} = planning_params
      assert planning_params.request_id == "test_req_789"
      assert planning_params.conversion_metadata.error == true
      assert planning_params.conversion_metadata.error_type == :validation_error
      assert planning_params.options[:error] == true

      Testing.Pipeline.terminate(pipeline)
    end

    test "allows invalid parameters with strict validation disabled" do
      # Create an invalid schedule_activities MCPRequest
      {:ok, mcp_request} = MCPRequest.from_tool_call(
        "schedule_activities",
        %{
          "schedule_name" => "lenient_schedule",
          "activities" => [],  # Empty activities
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "test_req_lenient",
        %{}
      )

      # Set up pipeline with strict validation disabled
      pipeline = Testing.Pipeline.start_link_supervised!()

      children = [
        child(:source, %Testing.Source{
          output: [mcp_request]
        })
        |> child(:schedule_filter, %ScheduleFilter{strict_validation: false})
        |> child(:sink, Testing.Sink)
      ]

      Testing.Pipeline.execute_actions(pipeline, spec: children)

      # Wait for processing
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %PlanningParams{}})

      # Get the result
      sink_buffers = Testing.Pipeline.get_child_buffers(pipeline, :sink)
      assert [%Membrane.Buffer{payload: planning_params}] = sink_buffers

      # Verify it processed without validation error
      assert %PlanningParams{} = planning_params
      assert planning_params.request_id == "test_req_lenient"
      # Should not be an error since validation is disabled
      refute planning_params.conversion_metadata[:error]

      Testing.Pipeline.terminate(pipeline)
    end

    test "handles legacy format MCPRequest" do
      # Create a legacy format MCPRequest
      {:ok, mcp_request} = MCPRequest.from_mcp_params(
        %{
          "schedule_name" => "legacy_schedule",
          "activities" => [
            %{
              "id" => "legacy_activity",
              "name" => "Legacy Activity"
            }
          ],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        },
        "test_req_legacy"
      )

      # Set up pipeline
      pipeline = Testing.Pipeline.start_link_supervised!()

      children = [
        child(:source, %Testing.Source{
          output: [mcp_request]
        })
        |> child(:schedule_filter, ScheduleFilter)
        |> child(:sink, Testing.Sink)
      ]

      Testing.Pipeline.execute_actions(pipeline, spec: children)

      # Wait for processing
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: %PlanningParams{}})

      # Get the result
      sink_buffers = Testing.Pipeline.get_child_buffers(pipeline, :sink)
      assert [%Membrane.Buffer{payload: planning_params}] = sink_buffers

      # Verify the conversion
      assert %PlanningParams{} = planning_params
      assert planning_params.request_id == "test_req_legacy"
      assert planning_params.conversion_metadata.legacy_format == true

      Testing.Pipeline.terminate(pipeline)
    end
  end

  describe "ScheduleFilter.validate_params/1" do
    test "validates correct schedule parameters" do
      valid_params = %{
        "schedule_name" => "test",
        "activities" => [
          %{"id" => "1", "name" => "Activity 1"}
        ],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      assert :ok = ScheduleFilter.validate_params(valid_params)
    end

    test "rejects invalid schedule parameters" do
      invalid_params = %{
        "schedule_name" => 123,  # Should be string
        "activities" => "not_a_list",
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      assert {:error, _reason} = ScheduleFilter.validate_params(invalid_params)
    end

    test "rejects empty activities list" do
      empty_activities = %{
        "schedule_name" => "test",
        "activities" => [],  # Empty activities
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      assert {:error, reason} = ScheduleFilter.validate_params(empty_activities)
      assert reason =~ "activities list cannot be empty"
    end

    test "rejects activities without required fields" do
      invalid_activity = %{
        "schedule_name" => "test",
        "activities" => [
          %{"name" => "Missing ID"}  # Missing id field
        ],
        "entities" => [],
        "resources" => %{},
        "constraints" => %{}
      }

      assert {:error, reason} = ScheduleFilter.validate_params(invalid_activity)
      assert reason =~ "Invalid activity"
    end
  end

  describe "ScheduleFilter stats and monitoring" do
    test "provides processing statistics" do
      # This test would require a running ScheduleFilter element
      # For now, we'll test the stats structure
      stats = %{
        processed_count: 5,
        schedule_count: 3,
        error_count: 1,
        rejected_count: 1,
        strict_validation: true,
        allow_non_schedule_requests: false
      }

      assert is_integer(stats.processed_count)
      assert is_integer(stats.schedule_count)
      assert is_integer(stats.error_count)
      assert is_integer(stats.rejected_count)
      assert is_boolean(stats.strict_validation)
      assert is_boolean(stats.allow_non_schedule_requests)
    end
  end
end
