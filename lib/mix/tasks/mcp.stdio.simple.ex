# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Stdio.Simple do
  @moduledoc """
  Simple MCP server implementation for stdio transport.
  
  This is a minimal, working MCP server that properly handles the protocol
  without external framework dependencies.
  """

  use Mix.Task
  require Logger

  @shortdoc "Start simple MCP server in stdio mode"

  @impl Mix.Task
  def run(_args) do
    # Ensure all required applications are started
    {:ok, _} = Application.ensure_all_started(:logger)
    {:ok, _} = Application.ensure_all_started(:jason)
    {:ok, _} = Application.ensure_all_started(:aria_character_core)

    # Configure logger to write to stderr to avoid interfering with MCP protocol
    Logger.configure(level: :info)
    
    # Write startup message to stderr
    IO.puts(:stderr, "Starting simple Aria Engine MCP server in stdio mode...")
    IO.puts(:stderr, "Server ready for MCP client connections")
    IO.puts(:stderr, "PID: #{inspect(self())}")

    # Start the simple MCP server loop
    server_loop()
  end

  defp server_loop do
    case IO.gets("") do
      :eof ->
        IO.puts(:stderr, "MCP server: EOF received, shutting down")
        :ok

      {:error, reason} ->
        IO.puts(:stderr, "MCP server: IO error: #{inspect(reason)}")
        :error

      line when is_binary(line) ->
        IO.puts(:stderr, "MCP server: Received line: #{String.trim(line)}")
        line
        |> String.trim()
        |> handle_request()
        |> case do
          :continue -> server_loop()
        end
    end
  end

  defp handle_request("") do
    # Empty line, continue
    :continue
  end

  defp handle_request(line) do
    try do
      request = Jason.decode!(line)
      response = process_request(request)
      
      if response do
        IO.puts(Jason.encode!(response))
      end
      
      :continue
    rescue
      e ->
        Logger.error("MCP server: Error processing request: #{Exception.message(e)}")
        error_response = %{
          jsonrpc: "2.0",
          id: nil,
          error: %{
            code: -32700,
            message: "Parse error"
          }
        }
        IO.puts(Jason.encode!(error_response))
        :continue
    end
  end

  defp process_request(%{"method" => "initialize", "id" => id, "params" => _params}) do
    IO.puts(:stderr, "MCP server: Received initialize request")
    
    %{
      jsonrpc: "2.0",
      id: id,
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
  end

  defp process_request(%{"method" => "initialized", "params" => _params}) do
    Logger.info("MCP server: Received initialized notification")
    # No response for notifications
    nil
  end

  defp process_request(%{"method" => "tools/list", "id" => id}) do
    Logger.info("MCP server: Received tools/list request")
    
    tools = AriaEngine.MCPTools.get_all_tools()

    %{
      jsonrpc: "2.0",
      id: id,
      result: %{
        tools: tools
      }
    }
  end

  defp process_request(%{"method" => "tools/call", "id" => id, "params" => %{"name" => tool_name, "arguments" => args}}) do
    Logger.info("MCP server: Received #{tool_name} tool call")
    
    try do
      result = AriaEngine.MCPTools.handle_tool_call(tool_name, args)
      
      %{
        jsonrpc: "2.0",
        id: id,
        result: %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(result)
            }
          ]
        }
      }
    rescue
      e ->
        Logger.error("MCP server: Tool call failed: #{Exception.message(e)}")
        
        %{
          jsonrpc: "2.0",
          id: id,
          error: %{
            code: -32603,
            message: "Internal error",
            data: %{error: Exception.message(e)}
          }
        }
    end
  end

  defp process_request(%{"method" => method, "id" => id}) do
    Logger.warning("MCP server: Unknown method: #{method}")
    
    %{
      jsonrpc: "2.0",
      id: id,
      error: %{
        code: -32601,
        message: "Method not found"
      }
    }
  end

  defp process_request(%{"method" => method}) do
    Logger.info("MCP server: Received notification: #{method}")
    # No response for notifications
    nil
  end

  defp process_request(request) do
    Logger.warning("MCP server: Invalid request format: #{inspect(request)}")
    
    %{
      jsonrpc: "2.0",
      id: nil,
      error: %{
        code: -32600,
        message: "Invalid Request"
      }
    }
  end

end
