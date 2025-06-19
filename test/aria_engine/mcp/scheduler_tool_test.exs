# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.SchedulerToolTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.MCP.SchedulerTool
  
  describe "get_tool_definition/0" do
    test "returns valid tool definition" do
      definition = SchedulerTool.get_tool_definition()
      
      assert definition.name == "schedule_activities"
      assert is_binary(definition.description)
      assert is_map(definition.inputSchema)
      
      # Check required properties
      properties = definition.inputSchema.properties
      assert Map.has_key?(properties, :schedule_name)
      assert Map.has_key?(properties, :activities)
      
      # Check required fields
      required = definition.inputSchema.required
      assert "schedule_name" in required
      assert "activities" in required
    end
  end
  
  describe "handle_tool_call/1" do
    test "handles empty activities list successfully" do
      params = %{
        "schedule_name" => "Empty Project",
        "activities" => [],
        "resources" => %{},
        "constraints" => %{}
      }
      
      result = SchedulerTool.handle_tool_call(params)
      
      assert result.status == "success"
      assert result.reason =~ "Empty plan"
      assert result.schedule == []
      assert is_map(result.analysis)
    end
    
    test "handles simple activity list" do
      params = %{
        "schedule_name" => "Simple Project",
        "activities" => [
          %{
            "id" => "task1",
            "duration" => 5,
            "dependencies" => []
          }
        ],
        "resources" => %{},
        "constraints" => %{}
      }
      
      result = SchedulerTool.handle_tool_call(params)
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert is_map(result.analysis)
    end
    
    test "handles missing schedule_name" do
      params = %{
        "activities" => [],
        "resources" => %{},
        "constraints" => %{}
      }
      
      result = SchedulerTool.handle_tool_call(params)
      
      assert result.status == "error"
      assert result.reason =~ "schedule_name is required"
    end
    
    test "handles invalid schedule_name type" do
      params = %{
        "schedule_name" => 123,
        "activities" => [],
        "resources" => %{},
        "constraints" => %{}
      }
      
      result = SchedulerTool.handle_tool_call(params)
      
      assert result.status == "error"
      assert result.reason =~ "schedule_name is required and must be a string"
    end
    
    test "handles complex scheduling with resources" do
      params = %{
        "schedule_name" => "Complex Project",
        "activities" => [
          %{
            "id" => "design",
            "duration" => 5,
            "dependencies" => [],
            "required_resources" => ["designer"]
          },
          %{
            "id" => "develop",
            "duration" => 10,
            "dependencies" => ["design"],
            "required_resources" => ["developer"]
          }
        ],
        "resources" => %{
          "designer" => %{
            "type" => "human",
            "capacity" => 1,
            "current_usage" => 0
          },
          "developer" => %{
            "type" => "human", 
            "capacity" => 2,
            "current_usage" => 0
          }
        },
        "constraints" => %{
          "max_duration" => 20
        }
      }
      
      result = SchedulerTool.handle_tool_call(params)
      
      assert result.status == "success"
      assert is_list(result.schedule)
      assert is_map(result.analysis)
      assert Map.has_key?(result.analysis, "schedule_name")
    end
  end
end
