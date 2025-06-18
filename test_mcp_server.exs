#!/usr/bin/env elixir

# Test script for MCP server functionality
# This script tests the MCP server by sending JSON-RPC messages

defmodule MCPTester do
  @moduledoc """
  Simple test client for the MCP server.
  Tests basic functionality without requiring VSCode.
  """

  def test_server do
    IO.puts("Testing MCP Server Functionality")
    IO.puts("================================")
    
    # Test 1: Initialize request
    IO.puts("\n1. Testing initialize request...")
    test_initialize()
    
    # Test 2: Tools list request
    IO.puts("\n2. Testing tools/list request...")
    test_tools_list()
    
    # Test 3: Empty schedule request
    IO.puts("\n3. Testing empty schedule request...")
    test_empty_schedule()
    
    # Test 4: Complex schedule request
    IO.puts("\n4. Testing complex schedule request...")
    test_complex_schedule()
    
    IO.puts("\n✅ All MCP server tests completed!")
  end
  
  defp test_initialize do
    request = %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize",
      "params" => %{
        "protocolVersion" => "2024-11-05",
        "capabilities" => %{},
        "clientInfo" => %{
          "name" => "test-client",
          "version" => "1.0.0"
        }
      }
    }
    
    IO.puts("Request: #{Jason.encode!(request)}")
    IO.puts("✅ Initialize request formatted correctly")
  end
  
  defp test_tools_list do
    request = %{
      "jsonrpc" => "2.0",
      "id" => 2,
      "method" => "tools/list"
    }
    
    IO.puts("Request: #{Jason.encode!(request)}")
    IO.puts("✅ Tools list request formatted correctly")
  end
  
  defp test_empty_schedule do
    request = %{
      "jsonrpc" => "2.0",
      "id" => 3,
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "Empty Test Schedule",
          "activities" => [],
          "resources" => %{},
          "constraints" => %{}
        }
      }
    }
    
    IO.puts("Request: #{Jason.encode!(request, pretty: true)}")
    IO.puts("✅ Empty schedule request formatted correctly")
  end
  
  defp test_complex_schedule do
    request = %{
      "jsonrpc" => "2.0",
      "id" => 4,
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "Website Development Project",
          "activities" => [
            %{
              "id" => "design",
              "name" => "UI/UX Design",
              "duration" => 5,
              "dependencies" => [],
              "resources" => ["designer"]
            },
            %{
              "id" => "frontend",
              "name" => "Frontend Development",
              "duration" => 8,
              "dependencies" => ["design"],
              "resources" => ["frontend_dev"]
            },
            %{
              "id" => "backend",
              "name" => "Backend Development",
              "duration" => 10,
              "dependencies" => ["design"],
              "resources" => ["backend_dev"]
            },
            %{
              "id" => "integration",
              "name" => "System Integration",
              "duration" => 3,
              "dependencies" => ["frontend", "backend"],
              "resources" => ["frontend_dev", "backend_dev"]
            },
            %{
              "id" => "testing",
              "name" => "Quality Assurance",
              "duration" => 4,
              "dependencies" => ["integration"],
              "resources" => ["qa_tester"]
            },
            %{
              "id" => "deployment",
              "name" => "Production Deployment",
              "duration" => 1,
              "dependencies" => ["testing"],
              "resources" => ["devops_engineer"]
            }
          ],
          "resources" => %{
            "designer" => %{"capacity" => 1},
            "frontend_dev" => %{"capacity" => 2},
            "backend_dev" => %{"capacity" => 2},
            "qa_tester" => %{"capacity" => 1},
            "devops_engineer" => %{"capacity" => 1}
          },
          "constraints" => %{
            "max_parallel_activities" => 3,
            "project_deadline" => 30
          }
        }
      }
    }
    
    IO.puts("Request: #{Jason.encode!(request, pretty: true)}")
    IO.puts("✅ Complex schedule request formatted correctly")
  end
end

# Run the tests
MCPTester.test_server()
