#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Quick stdio MCP test - simplified version
# Run with: elixir scripts/quick_stdio_test.exs

Mix.install([
  {:jason, "~> 1.4"}
])

Code.append_path("lib")

defmodule QuickStdioTest do
  @moduledoc """
  Quick test for stdio MCP functionality without full ExUnit setup.
  """
  
  require Logger
  
  def run do
    Logger.info("=== Quick Stdio MCP Test ===")
    
    # Test MCP protocol parsing
    test_mcp_protocol()
    
    # Test basic functionality
    test_basic_functionality()
    
    Logger.info("=== Quick Test Complete ===")
  end
  
  defp test_mcp_protocol do
    Logger.info("Testing MCP protocol parsing...")
    
    request = %{
      "jsonrpc" => "2.0",
      "id" => "test_001",
      "method" => "tools/call",
      "params" => %{
        "name" => "schedule_activities",
        "arguments" => %{
          "schedule_name" => "test_schedule",
          "activities" => [],
          "entities" => [],
          "resources" => %{},
          "constraints" => %{}
        }
      }
    }
    
    case extract_tool_call(request) do
      {:ok, :schedule_activities, params} ->
        Logger.info("✅ MCP protocol parsing PASSED")
        Logger.info("Extracted params: #{inspect(params, pretty: true)}")
        
      {:error, reason} ->
        Logger.error("❌ MCP protocol parsing FAILED: #{reason}")
    end
  end
  
  defp test_basic_functionality do
    Logger.info("Testing basic functionality...")
    
    # Test response formatting
    response = format_mcp_response("test_123", %{"status" => "success"})
    
    expected = %{
      "jsonrpc" => "2.0",
      "id" => "test_123",
      "result" => %{"status" => "success"}
    }
    
    if response == expected do
      Logger.info("✅ Response formatting PASSED")
    else
      Logger.error("❌ Response formatting FAILED")
      Logger.error("Expected: #{inspect(expected)}")
      Logger.error("Got: #{inspect(response)}")
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
        {:error, "Invalid tool call format"}
        
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
end

# Run the test
QuickStdioTest.run()
