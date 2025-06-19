# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.HermesServerTest do
  use ExUnit.Case, async: true
  
  alias AriaEngine.MCP.HermesServer
  
  describe "tools/list request" do
    test "returns schedule_activities tool" do
      {:ok, response} = HermesServer.handle_request("tools/list", %{})
      
      assert %{tools: tools} = response
      assert length(tools) == 1
      
      tool = List.first(tools)
      assert tool.name == "schedule_activities"
      assert is_binary(tool.description)
      assert is_map(tool.inputSchema)
    end
  end
  
  describe "tools/call request" do
    test "handles schedule_activities tool call with empty activities" do
      params = %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "Test Project",
          "activities" => [],
          "resources" => %{},
          "constraints" => %{}
        }
      }
      
      {:ok, response} = HermesServer.handle_request("tools/call", params)
      
      assert %{content: content} = response
      assert is_list(content)
      assert length(content) == 1
      
      text_content = List.first(content)
      assert text_content.type == "text"
      
      # Parse the JSON response
      result = Jason.decode!(text_content.text)
      assert result["status"] == "success"
      assert result["schedule"] == []
      assert is_map(result["analysis"])
    end
    
    test "handles schedule_activities tool call with simple activities" do
      params = %{
        "name" => "schedule_activities",
        "arguments" => %{
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
      }
      
      {:ok, response} = HermesServer.handle_request("tools/call", params)
      
      assert %{content: content} = response
      text_content = List.first(content)
      
      result = Jason.decode!(text_content.text)
      assert result["status"] == "success"
      assert is_list(result["schedule"])
      assert is_map(result["analysis"])
    end
    
    test "handles unknown tool call" do
      params = %{
        "name" => "unknown_tool",
        "arguments" => %{}
      }
      
      {:error, error} = HermesServer.handle_request("tools/call", params)
      
      assert error.code == -32601
      assert error.message == "Tool not found"
      assert error.data.tool_name == "unknown_tool"
      assert "schedule_activities" in error.data.available_tools
    end
    
    test "handles invalid tool call parameters" do
      params = %{
        "name" => "schedule_activities",
        "arguments" => %{
          # Missing required schedule_name
          "activities" => []
        }
      }
      
      {:ok, response} = HermesServer.handle_request("tools/call", params)
      
      text_content = List.first(response.content)
      result = Jason.decode!(text_content.text)
      
      assert result["status"] == "error"
      assert result["reason"] =~ "schedule_name is required"
    end
  end
  
  describe "unknown request" do
    test "returns method not found error" do
      {:error, error} = HermesServer.handle_request("unknown/method", %{})
      
      assert error.code == -32601
      assert error.message == "Method not found"
    end
  end
end
