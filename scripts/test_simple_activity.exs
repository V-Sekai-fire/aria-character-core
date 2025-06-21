#!/usr/bin/env elixir

# Simple test with a minimal, properly formatted activity
Mix.install([
  {:jason, "~> 1.4"}
])

defmodule SimpleActivityTest do
  require Logger

  def run do
    Logger.info("=== Simple Activity Test ===")
    
    # Test with a minimal, properly formatted activity
    request = %{
      "id" => "simple_test_001",
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "simple_test",
          "activities" => [
            %{
              "id" => "meeting_1",
              "name" => "Team Standup",
              "duration" => %{
                "start" => "2025-06-21T09:00:00Z",
                "end" => "2025-06-21T09:30:00Z"
              },
              "participants" => ["alice"],
              "resources" => ["room_1"]
            }
          ],
          "entities" => [
            %{
              "id" => "alice",
              "type" => "person",
              "availability" => "full_time"
            }
          ],
          "resources" => %{
            "room_1" => %{
              "type" => "meeting_room",
              "capacity" => 4
            }
          },
          "constraints" => %{
            "max_concurrent_activities" => 3,
            "require_resources" => true
          }
        }
      }
    }
    
    Logger.info("Request: #{Jason.encode!(request, pretty: true)}")
    
    # Test the MCP tools directly
    try do
      Logger.info("Testing AriaEngine.MCPToolsV2.handle_tool_call/2...")
      
      params = request["params"]["arguments"]
      result = AriaEngine.MCPToolsV2.handle_tool_call(:schedule_activities, params)
      
      Logger.info("Result: #{inspect(result, pretty: true)}")
      
      case result do
        %{"status" => "processing"} = response ->
          Logger.info("✅ SUCCESS: Got processing response")
          Logger.info("Response keys: #{inspect(Map.keys(response))}")
          
          if Map.has_key?(response, "schedule") do
            Logger.info("✅ Schedule field present")
          else
            Logger.warning("⚠️  No schedule field in response")
          end
          
          if Map.has_key?(response, "pipeline_id") do
            Logger.info("✅ Pipeline ID present: #{response["pipeline_id"]}")
          end
          
        %{"status" => "error"} = response ->
          Logger.error("❌ ERROR: #{response["error"]}")
          
        other ->
          Logger.warning("⚠️  Unexpected result format: #{inspect(other)}")
      end
      
    rescue
      error ->
        Logger.error("❌ EXCEPTION: #{inspect(error)}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
    end
    
    Logger.info("=== Test Complete ===")
  end
end

SimpleActivityTest.run()
