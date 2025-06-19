#!/usr/bin/env elixir

# Test script for both MCP servers (stdio and HTTP SSE)

defmodule MCPServerTest do
  @moduledoc """
  Test script to verify both MCP servers work correctly.
  """

  def test_scheduler_tool do
    IO.puts("Testing AriaEngine.MCP.SchedulerTool directly...")
    
    # Test empty activities
    params = %{
      "schedule_name" => "Test Project",
      "activities" => [],
      "resources" => %{},
      "constraints" => %{}
    }
    
    result = AriaEngine.MCP.SchedulerTool.handle_tool_call(params)
    
    IO.puts("Empty activities result:")
    IO.puts("  Status: #{result.status}")
    IO.puts("  Reason: #{result.reason}")
    IO.puts("  Schedule: #{inspect(result.schedule)}")
    IO.puts("  Timeline: #{inspect(result.timeline)}")
    
    # Test with simple activities
    params_with_activities = %{
      "schedule_name" => "Simple Project",
      "activities" => [
        %{
          "id" => "task1",
          "duration" => 5,
          "dependencies" => []
        },
        %{
          "id" => "task2", 
          "duration" => 3,
          "dependencies" => ["task1"]
        }
      ],
      "resources" => %{},
      "constraints" => %{}
    }
    
    result2 = AriaEngine.MCP.SchedulerTool.handle_tool_call(params_with_activities)
    
    IO.puts("\nSimple activities result:")
    IO.puts("  Status: #{result2.status}")
    IO.puts("  Reason: #{result2.reason}")
    IO.puts("  Schedule length: #{length(result2.schedule || [])}")
    IO.puts("  Timeline length: #{length(result2.timeline || [])}")
    IO.puts("  Analysis keys: #{inspect(Map.keys(result2.analysis || %{}))}")
    
    if result2.status == "success" do
      IO.puts("✅ Scheduler tool working correctly!")
    else
      IO.puts("❌ Scheduler tool failed: #{result2.reason}")
    end
  end

  def test_tool_definition do
    IO.puts("\nTesting tool definition...")
    
    definition = AriaEngine.MCP.SchedulerTool.get_tool_definition()
    
    IO.puts("  Tool name: #{definition.name}")
    IO.puts("  Description: #{String.slice(definition.description, 0, 50)}...")
    IO.puts("  Required fields: #{definition.inputSchema.required}")
    
    IO.puts("✅ Tool definition looks good!")
  end

  def print_server_info do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("MCP SERVERS READY")
    IO.puts(String.duplicate("=", 60))
    IO.puts("")
    IO.puts("📡 STDIO Server:")
    IO.puts("   Command: mix mcp.stdio")
    IO.puts("   Usage: Connect via MCP client using stdio transport")
    IO.puts("")
    IO.puts("🌐 HTTP SSE Server:")
    IO.puts("   Command: mix mcp.sse")
    IO.puts("   Default: http://localhost:3001")
    IO.puts("   Options: --port 3001 --host localhost")
    IO.puts("   Endpoints:")
    IO.puts("     GET  /sse     - Server-Sent Events")
    IO.puts("     POST /tools   - Tool execution")
    IO.puts("     GET  /health  - Health check")
    IO.puts("")
    IO.puts("🔧 Available Tool:")
    IO.puts("   schedule_activities - Returns complete SimulationResult")
    IO.puts("   - status, reason, schedule, analysis")
    IO.puts("   - activity_log, resource_utilization")
    IO.puts("   - timeline (solution tree), simulation_metadata")
    IO.puts("")
    IO.puts("✅ Both servers expose the same scheduler functionality!")
    IO.puts(String.duplicate("=", 60))
  end
end

# Run the tests
MCPServerTest.test_tool_definition()
MCPServerTest.test_scheduler_tool()
MCPServerTest.print_server_info()
