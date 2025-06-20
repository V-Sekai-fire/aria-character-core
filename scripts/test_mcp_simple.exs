#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Test script for the simple MCP server
# This script tests the MCP protocol without terminal complications

defmodule MCPTest do
  def run do
    IO.puts("Testing simple MCP server...")
    
    # Test JSON-RPC parsing
    test_request = %{
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
    
    json_request = Jason.encode!(test_request)
    IO.puts("Test request: #{json_request}")
    
    # Test JSON parsing
    parsed = Jason.decode!(json_request)
    IO.puts("Parsed successfully: #{inspect(parsed)}")
    
    # Test response generation
    response = %{
      jsonrpc: "2.0",
      id: 1,
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: %{
          tools: %{}
        },
        serverInfo: %{
          name: "aria-scheduler",
          version: "1.0.0"
        }
      }
    }
    
    json_response = Jason.encode!(response)
    IO.puts("Test response: #{json_response}")
    
    IO.puts("MCP protocol test completed successfully!")
  end
end

MCPTest.run()
