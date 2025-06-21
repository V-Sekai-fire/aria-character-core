#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Membrane Pipeline End-to-End Demonstration
# Shows MCPSource → ScheduleFilter → MCPSink pipeline working with real MCP data

Mix.install([
  {:jason, "~> 1.4"}
])

# Add the project lib path so we can use our modules
Code.append_path("lib")

# Configure Logger for the demonstration
Logger.configure(level: :info)

defmodule MembraneDemo do
  @moduledoc """
  Demonstration script for the generic Membrane-based MCP processing pipeline.
  
  This script shows how to:
  1. Set up a complete generic MCP processing pipeline with ScheduleFilter
  2. Send various MCP tool requests through the pipeline
  3. Monitor processing results and telemetry
  4. Handle different types of MCP requests (schedule_activities and others)
  
  Run with: `elixir scripts/membrane_pipeline_demo.exs`
  """

  use Membrane.Pipeline

  require Logger

  alias AriaEngine.Membrane.{MCPSource, MCPSink, ScheduleFilter}
  alias AriaEngine.Membrane.Format.{MCPRequest, MCPResponse}

  @impl true
  def handle_init(_ctx, _opts) do
    Logger.info("Starting Generic MCP Pipeline Demo")
    
    # Define the pipeline topology with generic MCPSource and ScheduleFilter
    spec = [
      child(:mcp_source, MCPSource)
      |> child(:schedule_filter, ScheduleFilter)
      |> child(:mcp_sink, MCPSink)
    ]
    
    {[spec: spec], %{demo_requests: create_demo_requests()}}
  end

  @impl true
  def handle_child_notification({:sink_processed, result}, :mcp_sink, _ctx, state) do
    Logger.info("Pipeline processed result: #{inspect(result, pretty: true)}")
    {[], state}
  end

  @impl true
  def handle_child_notification(notification, child, _ctx, state) do
    Logger.debug("Received notification from #{child}: #{inspect(notification)}")
    {[], state}
  end

  # Send demo requests after pipeline is ready
  @impl true
  def handle_info(:send_demo_requests, _ctx, state) do
    Logger.info("Sending demo MCP requests...")
    
    Enum.each(state.demo_requests, fn {name, request_type, request_data} ->
      Logger.info("Sending #{name} request (#{request_type})")
      
      case request_type do
        :tool_call ->
          {tool_name, parameters, metadata} = request_data
          send_child_message(:mcp_source, {:mcp_tool_call, tool_name, parameters, metadata})
          
        :legacy ->
          send_child_message(:mcp_source, {:mcp_request, request_data})
      end
      
      Process.sleep(200)  # Small delay between requests
    end)
    
    # Schedule pipeline shutdown after processing
    Process.send_after(self(), :shutdown_demo, 3000)
    
    {[], state}
  end

  @impl true
  def handle_info(:shutdown_demo, _ctx, state) do
    Logger.info("Demo completed, shutting down pipeline")
    {[terminate: :normal], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.debug("Received unknown message: #{inspect(msg)}")
    {[], state}
  end

  # ==================== DEMO REQUEST CREATION ====================

  defp create_demo_requests do
    [
      {"Basic Schedule (New Format)", :tool_call, create_basic_schedule_tool_call()},
      {"Complex Schedule (Legacy Format)", :legacy, create_complex_schedule_request()},
      {"Non-Schedule Tool Call", :tool_call, create_non_schedule_tool_call()},
      {"Invalid Schedule", :legacy, create_invalid_schedule_request()},
      {"Empty Schedule", :tool_call, create_empty_schedule_tool_call()},
      {"Unknown Tool", :tool_call, create_unknown_tool_call()}
    ]
  end

  defp create_basic_schedule_tool_call do
    tool_name = "schedule_activities"
    
    parameters = %{
      "schedule_name" => "basic_demo_schedule",
      "activities" => [
        %{
          "id" => "activity_1",
          "name" => "Morning Meeting",
          "duration" => %{
            "start" => "2025-06-20T09:00:00Z",
            "end" => "2025-06-20T10:00:00Z"
          },
          "resources" => ["conference_room_a"],
          "participants" => ["alice", "bob"]
        },
        %{
          "id" => "activity_2", 
          "name" => "Project Work",
          "duration" => %{
            "start" => "2025-06-20T10:30:00Z",
            "end" => "2025-06-20T12:00:00Z"
          },
          "resources" => ["workstation_1"],
          "participants" => ["alice"]
        }
      ],
      "entities" => [
        %{"id" => "alice", "type" => "person", "availability" => "full_time"},
        %{"id" => "bob", "type" => "person", "availability" => "part_time"},
        %{"id" => "conference_room_a", "type" => "resource", "capacity" => 10},
        %{"id" => "workstation_1", "type" => "resource", "capacity" => 1}
      ],
      "resources" => %{
        "conference_room_a" => %{"type" => "room", "capacity" => 10},
        "workstation_1" => %{"type" => "desk", "capacity" => 1}
      },
      "constraints" => %{
        "max_concurrent_activities" => 5,
        "require_resources" => true
      }
    }
    
    metadata = %{
      "source" => "demo_script",
      "format_version" => "1.0"
    }
    
    {tool_name, parameters, metadata}
  end

  defp create_non_schedule_tool_call do
    tool_name = "configure_pipeline"
    
    parameters = %{
      "pipeline_config" => %{
        "topology" => "linear",
        "elements" => ["source", "filter", "sink"],
        "buffer_size" => 1000
      },
      "optimization" => "throughput"
    }
    
    metadata = %{
      "source" => "demo_script",
      "tool_type" => "configuration"
    }
    
    {tool_name, parameters, metadata}
  end

  defp create_empty_schedule_tool_call do
    tool_name = "schedule_activities"
    
    parameters = %{
      "schedule_name" => "empty_demo_schedule",
      "activities" => [],
      "entities" => [],
      "resources" => %{},
      "constraints" => %{}
    }
    
    metadata = %{
      "source" => "demo_script",
      "test_case" => "empty_schedule"
    }
    
    {tool_name, parameters, metadata}
  end

  defp create_unknown_tool_call do
    tool_name = "unknown_tool"
    
    parameters = %{
      "some_param" => "some_value",
      "another_param" => 42
    }
    
    metadata = %{
      "source" => "demo_script",
      "test_case" => "unknown_tool"
    }
    
    {tool_name, parameters, metadata}
  end

  defp create_complex_schedule_request do
    %{
      "schedule_name" => "complex_demo_schedule",
      "activities" => [
        %{
          "id" => "complex_1",
          "name" => "Multi-Resource Activity",
          "duration" => %{
            "start" => "2025-06-20T14:00:00Z",
            "end" => "2025-06-20T16:00:00Z"
          },
          "resources" => ["conference_room_b", "projector_1", "laptop_1"],
          "participants" => ["alice", "bob", "charlie"],
          "constraints" => %{
            "requires_all_resources" => true,
            "priority" => "high"
          }
        },
        %{
          "id" => "complex_2",
          "name" => "Flexible Duration Activity",
          "duration" => %{
            "start" => "2025-06-20T16:30:00Z",
            "end" => "2025-06-20T18:00:00Z"
          },
          "resources" => ["workstation_2"],
          "participants" => ["charlie"],
          "constraints" => %{
            "can_extend" => true,
            "max_extension" => "30m"
          }
        }
      ],
      "entities" => [
        %{"id" => "alice", "type" => "person", "skills" => ["management", "planning"]},
        %{"id" => "bob", "type" => "person", "skills" => ["development", "testing"]},
        %{"id" => "charlie", "type" => "person", "skills" => ["design", "research"]},
        %{"id" => "conference_room_b", "type" => "resource", "features" => ["projector", "whiteboard"]},
        %{"id" => "projector_1", "type" => "equipment", "status" => "available"},
        %{"id" => "laptop_1", "type" => "equipment", "status" => "available"},
        %{"id" => "workstation_2", "type" => "resource", "location" => "building_a"}
      ],
      "resources" => %{
        "conference_room_b" => %{"type" => "room", "capacity" => 15, "features" => ["av_equipment"]},
        "projector_1" => %{"type" => "equipment", "portable" => true},
        "laptop_1" => %{"type" => "equipment", "specs" => "high_performance"},
        "workstation_2" => %{"type" => "desk", "ergonomic" => true}
      },
      "constraints" => %{
        "optimize_for" => "resource_utilization",
        "allow_overlaps" => false,
        "buffer_time" => "15m"
      }
    }
  end

  defp create_invalid_schedule_request do
    %{
      "schedule_name" => "invalid_demo_schedule",
      "activities" => [
        %{
          "id" => "invalid_1",
          "name" => "Missing Duration Activity",
          # Missing duration field
          "resources" => ["nonexistent_room"],
          "participants" => ["unknown_person"]
        }
      ],
      "entities" => [
        # Missing required fields
        %{"id" => "incomplete_entity"}
      ],
      "resources" => %{
        # Invalid resource definition
        "bad_resource" => "not_a_map"
      },
      "constraints" => %{
        "invalid_constraint" => "unsupported_value"
      }
    }
  end
end

# ==================== DEMO EXECUTION ====================

defmodule DemoRunner do
  @moduledoc """
  Runner for the generic Membrane pipeline demo.
  """

  require Logger

  def run do
    Logger.info("=== Generic Membrane MCP Pipeline Demo ===")
    
    # Start the pipeline
    {:ok, supervisor_pid, pipeline_pid} = Membrane.Testing.Pipeline.start_link(MembraneDemo)
    
    Logger.info("Pipeline started with PID: #{inspect(pipeline_pid)}")
    
    # Wait a moment for pipeline to initialize
    Process.sleep(500)
    
    # Send demo requests
    send(pipeline_pid, :send_demo_requests)
    
    # Monitor the pipeline
    monitor_ref = Process.monitor(pipeline_pid)
    
    receive do
      {:DOWN, ^monitor_ref, :process, ^pipeline_pid, reason} ->
        Logger.info("Pipeline terminated with reason: #{inspect(reason)}")
    after
      15_000 ->
        Logger.warning("Pipeline demo timeout, terminating...")
        Membrane.Testing.Pipeline.terminate(pipeline_pid)
    end
    
    Logger.info("=== Demo Complete ===")
  end
end

# Run the demo if this script is executed directly
if __ENV__.file == Path.absname(__ENV__.file) do
  DemoRunner.run()
end
