#!/usr/bin/env elixir

# Quick edge case tests for scheduling activities
Mix.install([{:jason, "~> 1.4"}])

defmodule QuickEdgeCaseTest do
  def run do
    IO.puts "=== Edge Case Tests for Schedule Activities ==="
    
    # Test 1: Missing duration
    test_missing_duration()
    
    # Test 2: Invalid time format
    test_invalid_time_format()
    
    # Test 3: Overlapping activities
    test_overlapping_activities()
    
    # Test 4: Resource conflicts
    test_resource_conflicts()
    
    # Test 5: Empty activities list
    test_empty_activities()
    
    # Test 6: Malformed JSON structure
    test_malformed_structure()
    
    IO.puts "=== Edge Case Tests Complete ==="
  end
  
  defp test_missing_duration do
    IO.puts "\n--- Test 1: Missing Duration Field ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_1",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
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
        }
      }
    }
    
    IO.puts "Request with missing duration:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should fail validation or return error"
  end
  
  defp test_invalid_time_format do
    IO.puts "\n--- Test 2: Invalid Time Format ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_2",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
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
        }
      }
    }
    
    IO.puts "Request with invalid time format:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should fail time parsing or return error"
  end
  
  defp test_overlapping_activities do
    IO.puts "\n--- Test 3: Overlapping Activities ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_3",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
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
        }
      }
    }
    
    IO.puts "Request with overlapping activities:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should detect conflict or handle gracefully"
  end
  
  defp test_resource_conflicts do
    IO.puts "\n--- Test 4: Resource Over-allocation ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_4",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
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
        }
      }
    }
    
    IO.puts "Request with resource over-allocation:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should detect capacity violation"
  end
  
  defp test_empty_activities do
    IO.puts "\n--- Test 5: Empty Activities List ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_5",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "empty_test",
          "activities" => [],  # Empty list
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        }
      }
    }
    
    IO.puts "Request with empty activities:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should handle gracefully, return empty schedule"
  end
  
  defp test_malformed_structure do
    IO.puts "\n--- Test 6: Malformed Structure ---"
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "edge_test_6",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "malformed_test",
          "activities" => "not_an_array",  # Should be array
          "entities" => %{"wrong" => "structure"},  # Should be array
          "resources" => [],  # Should be object
          "constraints" => "not_an_object"  # Should be object
        }
      }
    }
    
    IO.puts "Request with malformed structure:"
    IO.puts Jason.encode!(request, pretty: true)
    IO.puts "Expected: Should fail schema validation"
  end
end

QuickEdgeCaseTest.run()
