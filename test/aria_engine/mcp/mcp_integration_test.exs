# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.IntegrationTest do
  use ExUnit.Case, async: false
  
  alias AriaEngine.MCP.Server
  
  require Logger
  
  describe "MCP Server Integration" do
    test "server starts and registers tools correctly" do
      {:ok, server_pid} = Server.start_link([])
      
      # Test tool execution
      empty_request = %{
        "schedule_name" => "Test Empty Schedule",
        "activities" => [],
        "resources" => %{},
        "constraints" => %{}
      }
      
      {:ok, result} = GenServer.call(server_pid, {:execute_tool, "schedule_activities", empty_request})
      
      assert result["status"] == "success"
      assert result["reason"] == "Empty plan successfully generated - valid solution for empty todo list"
      assert result["schedule"] == []
      assert result["analysis"]["activities_analyzed"] == 0
      assert result["analysis"]["empty_plan_reason"] == "Empty todo list results in empty plan (valid solution)"
      
      GenServer.stop(server_pid)
    end
    
    test "handles complex scheduling request" do
      {:ok, server_pid} = Server.start_link([])
      
      complex_request = %{
        "schedule_name" => "Website Launch",
        "activities" => [
          %{
            "id" => "design",
            "name" => "Design Phase",
            "duration" => 5,
            "dependencies" => [],
            "resources" => ["designer"]
          },
          %{
            "id" => "develop",
            "name" => "Development Phase", 
            "duration" => 10,
            "dependencies" => ["design"],
            "resources" => ["developer"]
          },
          %{
            "id" => "test",
            "name" => "Testing Phase",
            "duration" => 3,
            "dependencies" => ["develop"],
            "resources" => ["tester"]
          }
        ],
        "resources" => %{
          "designer" => %{"capacity" => 1},
          "developer" => %{"capacity" => 2},
          "tester" => %{"capacity" => 1}
        },
        "constraints" => %{}
      }
      
      {:ok, result} = GenServer.call(server_pid, {:execute_tool, "schedule_activities", complex_request})
      
      assert result["status"] == "success"
      assert result["analysis"]["activities_analyzed"] == 3
      assert result["analysis"]["dependencies_found"] == 2
      assert result["analysis"]["schedule_name"] == "Website Launch"
      
      GenServer.stop(server_pid)
    end
    
    test "detects resource conflicts" do
      {:ok, server_pid} = Server.start_link([])
      
      conflict_request = %{
        "schedule_name" => "Resource Conflict Test",
        "activities" => [
          %{
            "id" => "task1",
            "name" => "Task 1",
            "duration" => 5,
            "dependencies" => [],
            "resources" => ["shared_resource"]
          },
          %{
            "id" => "task2", 
            "name" => "Task 2",
            "duration" => 3,
            "dependencies" => [],
            "resources" => ["shared_resource"]
          }
        ],
        "resources" => %{
          "shared_resource" => %{"capacity" => 1}
        }
      }
      
      {:ok, result} = GenServer.call(server_pid, {:execute_tool, "schedule_activities", conflict_request})
      
      assert result["status"] == "success"
      assert result["analysis"]["resource_conflicts"] == 1
      assert "Resource allocation conflicts detected" in result["analysis"]["issues"]
      
      GenServer.stop(server_pid)
    end
    
    test "handles invalid tool requests" do
      {:ok, server_pid} = Server.start_link([])
      
      {:error, reason} = GenServer.call(server_pid, {:execute_tool, "nonexistent_tool", %{}})
      
      assert reason == "Unknown tool: nonexistent_tool"
      
      GenServer.stop(server_pid)
    end
  end
  
  describe "Hermes MCP Integration" do
    @tag timeout: 5000
    test "Hermes server starts successfully" do
      # Start the Hermes application and registry first
      {:ok, _} = Application.ensure_all_started(:hermes_mcp)
      {:ok, _registry_pid} = Registry.start_link(keys: :unique, name: Hermes.Server.Registry)
      
      # Test that the Hermes server can start (this validates the Hermes integration)
      # We don't test the full protocol here since that's handled by Hermes framework
      assert {:ok, _pid} = AriaEngine.MCP.HermesServer.start_link([transport: :stdio])
    end
  end
  
  describe "ADR-097 Compliance" do
    test "empty activities return successful empty plan" do
      {:ok, server_pid} = Server.start_link([])
      
      empty_request = %{
        "schedule_name" => "ADR-097 Empty Test",
        "activities" => [],
        "resources" => %{},
        "constraints" => %{}
      }
      
      {:ok, result} = GenServer.call(server_pid, {:execute_tool, "schedule_activities", empty_request})
      
      # Verify ADR-097 requirements
      assert result["status"] == "success", "Empty activities should return success, not error"
      assert result["schedule"] == [], "Empty activities should return empty schedule"
      assert result["analysis"]["activities_analyzed"] == 0
      assert result["analysis"]["hybrid_planner_used"] == true
      assert String.contains?(result["reason"], "Empty plan successfully generated")
      assert String.contains?(result["analysis"]["empty_plan_reason"], "Empty todo list results in empty plan")
      
      GenServer.stop(server_pid)
    end
    
    test "response schema matches ADR specification" do
      {:ok, server_pid} = Server.start_link([])
      
      test_request = %{
        "schedule_name" => "Schema Test",
        "activities" => [
          %{
            "id" => "test_task",
            "name" => "Test Task",
            "duration" => 1,
            "dependencies" => []
          }
        ]
      }
      
      {:ok, result} = GenServer.call(server_pid, {:execute_tool, "schedule_activities", test_request})
      
      # Verify response schema from ADR-097
      assert Map.has_key?(result, "status")
      assert Map.has_key?(result, "reason")
      assert Map.has_key?(result, "schedule")
      assert Map.has_key?(result, "analysis")
      
      # Verify analysis structure
      analysis = result["analysis"]
      assert Map.has_key?(analysis, "schedule_name")
      assert Map.has_key?(analysis, "method")
      assert Map.has_key?(analysis, "activities_analyzed")
      assert Map.has_key?(analysis, "hybrid_planner_used")
      
      assert analysis["method"] == "Critical Path Method (CPM)"
      assert analysis["hybrid_planner_used"] == true
      
      GenServer.stop(server_pid)
    end
  end
end
