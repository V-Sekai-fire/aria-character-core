#!/usr/bin/env elixir

# Comprehensive edge case testing with actual system responses
Mix.install([
  {:jason, "~> 1.4"},
  {:membrane_core, "~> 1.0"}
])

# Add the project lib path so we can use our modules
Code.append_path("lib")

# Configure Logger for the test
require Logger
Logger.configure(level: :info)

# Compile necessary modules (from stdio test)
files_to_compile = [
  "lib/aria_engine/membrane/format/planning_response.ex",
  "lib/aria_engine/membrane/format/planning_request.ex", 
  "lib/aria_engine/membrane/format/planning_params.ex",
  "lib/aria_engine/membrane/format/planning_result.ex",
  "lib/aria_engine/membrane/format/mcp_request.ex",
  "lib/aria_engine/membrane/format/mcp_response.ex",
  "lib/aria_engine/membrane/mcp_source.ex",
  "lib/aria_engine/membrane/mcp_sink.ex",
  "lib/aria_engine/membrane/plan_filter.ex",
  "lib/aria_engine/membrane/planner_filter.ex",
  "lib/aria_engine/membrane/format_transformer_filter.ex",
  "lib/aria_engine/membrane/pipeline_manager.ex"
]

Enum.each(files_to_compile, fn file ->
  if File.exists?(file) do
    try do
      Code.compile_file(file)
    rescue
      error ->
        Logger.warning("⚠️  Failed to compile #{file}: #{inspect(error)}")
    end
  end
end)

# Try to compile MCPToolsV2
mcp_tools_available = try do
  Code.compile_file("lib/aria_engine/mcp_tools_v2.ex")
  true
rescue
  error ->
    Logger.warning("Could not compile MCPToolsV2: #{inspect(error)}")
    false
end

defmodule EdgeCaseResponseTest do
  @moduledoc """
  Tests edge cases by actually sending them through the MCP system and analyzing responses.
  """

  require Logger
  alias AriaEngine.MCPToolsV2
  alias AriaEngine.Membrane.PipelineManager

  def run_all_tests() do
    Logger.info("=== Edge Case Response Testing ===")
    Logger.info("Testing actual system responses to problematic inputs")
    
    # Start the pipeline manager
    start_pipeline_manager()
    
    # Run each edge case test and capture responses
    test_missing_duration()
    test_invalid_time_format()
    test_overlapping_activities()
    test_resource_conflicts()
    test_empty_activities()
    test_malformed_structure()
    test_extreme_values()
    test_unicode_and_special_chars()
    
    Logger.info("=== Edge Case Testing Complete ===")
  end

  defp start_pipeline_manager() do
    case GenServer.start_link(PipelineManager, [], name: PipelineManager) do
      {:ok, _pid} ->
        Logger.info("✅ Pipeline manager started")
        
      {:error, {:already_started, _pid}} ->
        Logger.info("✅ Pipeline manager already running")
        
      {:error, reason} ->
        Logger.error("❌ Failed to start pipeline manager: #{inspect(reason)}")
    end
  end

  defp test_missing_duration() do
    Logger.info("\n🧪 TEST 1: Missing Duration Field")
    
    request = create_mcp_request("edge_test_1", %{
      "schedule_name" => "missing_duration_test",
      "activities" => [
        %{
          "id" => "broken_activity",
          "name" => "Activity Without Duration"
          # Missing required duration field
        }
      ],
      "entities" => [],
      "resources" => %{},
      "constraints" => %{}
    })
    
    response = send_mcp_request(request)
    analyze_response("Missing Duration", response, [
      "Should return error about missing duration",
      "Should not crash the system",
      "Should provide helpful error message"
    ])
  end

  defp test_invalid_time_format() do
    Logger.info("\n🧪 TEST 2: Invalid Time Format")
    
    request = create_mcp_request("edge_test_2", %{
      "schedule_name" => "invalid_time_test",
      "activities" => [
        %{
          "id" => "bad_time_activity",
          "name" => "Activity With Bad Time",
          "duration" => %{
            "start" => "not-a-valid-time",
            "end" => "2025-13-45T99:99:99Z"  # Invalid date/time
          }
        }
      ],
      "entities" => [],
      "resources" => %{},
      "constraints" => %{}
    })
    
    response = send_mcp_request(request)
    analyze_response("Invalid Time Format", response, [
      "Should return error about invalid time format",
      "Should not crash during time parsing",
      "Should handle gracefully"
    ])
  end

  defp test_overlapping_activities() do
    Logger.info("\n🧪 TEST 3: Overlapping Activities")
    
    request = create_mcp_request("edge_test_3", %{
      "schedule_name" => "overlap_test",
      "activities" => [
        %{
          "id" => "activity_1",
          "name" => "First Meeting",
          "duration" => %{
            "start" => "2025-06-21T09:00:00Z",
            "end" => "2025-06-21T11:00:00Z"
          },
          "participants" => ["alice"],
          "resources" => ["room_1"]
        },
        %{
          "id" => "activity_2", 
          "name" => "Overlapping Meeting",
          "duration" => %{
            "start" => "2025-06-21T10:00:00Z",  # Overlaps with activity_1
            "end" => "2025-06-21T12:00:00Z"
          },
          "participants" => ["alice"],  # Same person
          "resources" => ["room_1"]     # Same room
        }
      ],
      "entities" => [
        %{"id" => "alice", "type" => "person", "availability" => "full_time"}
      ],
      "resources" => %{
        "room_1" => %{"type" => "meeting_room", "capacity" => 4}
      },
      "constraints" => %{
        "max_concurrent_activities" => 1,
        "require_resources" => true
      }
    })
    
    response = send_mcp_request(request)
    analyze_response("Overlapping Activities", response, [
      "Should detect scheduling conflict",
      "Should either reject or resolve conflicts",
      "Should provide conflict details"
    ])
  end

  defp test_resource_conflicts() do
    Logger.info("\n🧪 TEST 4: Resource Over-allocation")
    
    request = create_mcp_request("edge_test_4", %{
      "schedule_name" => "resource_conflict_test",
      "activities" => [
        %{
          "id" => "big_meeting",
          "name" => "Large Team Meeting",
          "duration" => %{
            "start" => "2025-06-21T09:00:00Z",
            "end" => "2025-06-21T10:00:00Z"
          },
          "participants" => ["alice", "bob", "charlie", "diana", "eve"],
          "resources" => ["small_room"]
        }
      ],
      "entities" => [
        %{"id" => "alice", "type" => "person"},
        %{"id" => "bob", "type" => "person"},
        %{"id" => "charlie", "type" => "person"},
        %{"id" => "diana", "type" => "person"},
        %{"id" => "eve", "type" => "person"}
      ],
      "resources" => %{
        "small_room" => %{"type" => "meeting_room", "capacity" => 2}  # Too small!
      },
      "constraints" => %{
        "require_resources" => true
      }
    })
    
    response = send_mcp_request(request)
    analyze_response("Resource Over-allocation", response, [
      "Should detect capacity violation",
      "Should reject or suggest alternatives",
      "Should not allow impossible scheduling"
    ])
  end

  defp test_empty_activities() do
    Logger.info("\n🧪 TEST 5: Empty Activities List")
    
    request = create_mcp_request("edge_test_5", %{
      "schedule_name" => "empty_test",
      "activities" => [],  # Empty list
      "entities" => [],
      "resources" => %{},
      "constraints" => %{}
    })
    
    response = send_mcp_request(request)
    analyze_response("Empty Activities", response, [
      "Should handle gracefully",
      "Should return empty but valid schedule",
      "Should not error on empty input"
    ])
  end

  defp test_malformed_structure() do
    Logger.info("\n🧪 TEST 6: Malformed Structure")
    
    request = create_mcp_request("edge_test_6", %{
      "schedule_name" => "malformed_test",
      "activities" => "not_an_array",  # Should be array
      "entities" => %{"wrong" => "structure"},  # Should be array
      "resources" => [],  # Should be object
      "constraints" => "not_an_object"  # Should be object
    })
    
    response = send_mcp_request(request)
    analyze_response("Malformed Structure", response, [
      "Should fail schema validation",
      "Should return clear error message",
      "Should not crash on bad input"
    ])
  end

  defp test_extreme_values() do
    Logger.info("\n🧪 TEST 7: Extreme Values")
    
    request = create_mcp_request("edge_test_7", %{
      "schedule_name" => "extreme_test",
      "activities" => [
        %{
          "id" => "extreme_activity",
          "name" => "Activity with extreme duration",
          "duration" => %{
            "start" => "1900-01-01T00:00:00Z",  # Very old date
            "end" => "2100-12-31T23:59:59Z"    # Very future date
          },
          "participants" => Enum.map(1..1000, &"person_#{&1}"),  # 1000 participants
          "resources" => Enum.map(1..100, &"resource_#{&1}")     # 100 resources
        }
      ],
      "entities" => Enum.map(1..1000, &%{"id" => "person_#{&1}", "type" => "person"}),
      "resources" => Enum.into(1..100, %{}, &{"resource_#{&1}", %{"type" => "room", "capacity" => 1}}),
      "constraints" => %{
        "max_concurrent_activities" => 999999,
        "require_resources" => true
      }
    })
    
    response = send_mcp_request(request)
    analyze_response("Extreme Values", response, [
      "Should handle large datasets",
      "Should not timeout or crash",
      "Should process or reject gracefully"
    ])
  end

  defp test_unicode_and_special_chars() do
    Logger.info("\n🧪 TEST 8: Unicode and Special Characters")
    
    request = create_mcp_request("edge_test_8", %{
      "schedule_name" => "unicode_test_🚀",
      "activities" => [
        %{
          "id" => "unicode_activity_🎯",
          "name" => "Meeting with émojis 🎉 and spëcial chars ñ",
          "duration" => %{
            "start" => "2025-06-21T09:00:00Z",
            "end" => "2025-06-21T10:00:00Z"
          },
          "participants" => ["alice_🦄", "bob_🔥"],
          "resources" => ["room_🏢"]
        }
      ],
      "entities" => [
        %{"id" => "alice_🦄", "type" => "person"},
        %{"id" => "bob_🔥", "type" => "person"}
      ],
      "resources" => %{
        "room_🏢" => %{"type" => "meeting_room", "capacity" => 10}
      },
      "constraints" => %{}
    })
    
    response = send_mcp_request(request)
    analyze_response("Unicode and Special Characters", response, [
      "Should handle Unicode correctly",
      "Should preserve special characters",
      "Should not corrupt data"
    ])
  end

  defp create_mcp_request(id, arguments) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => arguments
      }
    }
  end

  defp send_mcp_request(mcp_request) do
    try do
      case extract_tool_call(mcp_request) do
        {:ok, tool_name, params} ->
          enhanced_params = Map.put(params, "pipeline_topology", "plan_transform_pipeline")
          result = MCPToolsV2.handle_tool_call(tool_name, enhanced_params)
          format_mcp_response(mcp_request["id"], result)
          
        {:error, reason} ->
          format_mcp_error_response(mcp_request["id"], reason)
      end
    rescue
      error ->
        Logger.error("Exception during MCP request: #{inspect(error)}")
        format_mcp_error_response(
          Map.get(mcp_request, "id", "unknown"), 
          "Internal error: #{Exception.message(error)}"
        )
    end
  end

  defp extract_tool_call(mcp_request) do
    case mcp_request do
      %{
        "method" => "tools/call",
        "params" => %{
          "name" => tool_name,
          "arguments" => arguments
        }
      } when is_binary(tool_name) and is_map(arguments) ->
        {:ok, String.to_atom(tool_name), arguments}
        
      %{"method" => "tools/call"} ->
        {:error, "Invalid tool call format - missing name or arguments"}
        
      %{"method" => method} ->
        {:error, "Unsupported MCP method: #{method}"}
        
      _ ->
        {:error, "Invalid MCP request format"}
    end
  end

  defp format_mcp_response(request_id, result) do
    %{
      "jsonrpc" => "2.0",
      "id" => request_id,
      "result" => result
    }
  end

  defp format_mcp_error_response(request_id, error_message) do
    %{
      "jsonrpc" => "2.0",
      "id" => request_id,
      "error" => %{
        "code" => -32603,
        "message" => "Internal error",
        "data" => error_message
      }
    }
  end

  defp analyze_response(test_name, response, expectations) do
    Logger.info("📊 RESPONSE ANALYSIS: #{test_name}")
    Logger.info("Response: #{Jason.encode!(response, pretty: true)}")
    
    # Check if it's an error response
    if Map.has_key?(response, "error") do
      Logger.info("❌ ERROR RESPONSE:")
      Logger.info("  Code: #{response["error"]["code"]}")
      Logger.info("  Message: #{response["error"]["message"]}")
      Logger.info("  Data: #{inspect(response["error"]["data"])}")
    else
      Logger.info("✅ SUCCESS RESPONSE:")
      result = response["result"]
      Logger.info("  Status: #{Map.get(result, "status", "unknown")}")
      Logger.info("  Message: #{Map.get(result, "message", "no message")}")
      
      if Map.has_key?(result, "schedule") do
        schedule_count = length(Map.get(result, "schedule", []))
        Logger.info("  Schedule items: #{schedule_count}")
      end
      
      if Map.has_key?(result, "pipeline_id") do
        Logger.info("  Pipeline ID: #{result["pipeline_id"]}")
      end
    end
    
    Logger.info("📋 EXPECTATIONS:")
    Enum.each(expectations, fn expectation ->
      Logger.info("  - #{expectation}")
    end)
    
    Logger.info("---")
  end
end

# Run the tests
EdgeCaseResponseTest.run_all_tests()
