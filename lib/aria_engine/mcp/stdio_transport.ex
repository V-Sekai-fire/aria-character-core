# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.StdioTransport do
  @moduledoc """
  Stdio transport for MCP server communication with VSCode.
  
  Handles JSON-RPC protocol over stdin/stdout for Model Context Protocol
  communication with external clients like VSCode MCP extensions.
  """
  
  use GenServer
  require Logger
  
  alias AriaEngine.MCP.Server
  
  defstruct [:server_pid, :buffer]
  
  ## Public API
  
  @doc """
  Start the stdio transport for MCP communication.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end
  
  @doc """
  Start stdio loop for VSCode MCP client connection.
  """
  def start_stdio_loop do
    {:ok, pid} = start_link()
    stdio_loop(pid)
  end
  
  ## GenServer Callbacks
  
  @impl true
  def init(_opts) do
    # Start the MCP server
    {:ok, server_pid} = Server.start_link([])
    
    state = %__MODULE__{
      server_pid: server_pid,
      buffer: ""
    }
    
    Logger.info("MCP Stdio Transport started")
    {:ok, state}
  end
  
  @impl true
  def handle_info({:stdio_input, line}, state) do
    case Jason.decode(line) do
      {:ok, request} ->
        case handle_mcp_request(request, state.server_pid) do
          nil -> 
            # No response needed (e.g., for notifications)
            :ok
          response ->
            IO.puts(Jason.encode!(response))
        end
        
      {:error, reason} ->
        Logger.warning("Failed to decode JSON: #{inspect(reason)}")
        error_response = %{
          jsonrpc: "2.0",
          error: %{code: -32700, message: "Parse error"},
          id: nil
        }
        IO.puts(Jason.encode!(error_response))
    end
    
    {:noreply, state}
  end
  
  ## Private Functions
  
  defp stdio_loop(transport_pid) do
    case IO.gets("") do
      :eof -> 
        Logger.info("MCP Stdio Transport: EOF received, shutting down")
        :ok
        
      line when is_binary(line) ->
        trimmed = String.trim(line)
        unless trimmed == "" do
          send(transport_pid, {:stdio_input, trimmed})
        end
        stdio_loop(transport_pid)
        
      error ->
        Logger.error("MCP Stdio Transport: Unexpected input: #{inspect(error)}")
        stdio_loop(transport_pid)
    end
  end
  
  defp handle_mcp_request(%{"method" => "initialize"} = request, server_pid) do
    # Get server capabilities
    capabilities = get_server_capabilities(server_pid)
    
    %{
      jsonrpc: "2.0",
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: capabilities,
        serverInfo: %{
          name: "Aria Engine Temporal Scheduler",
          version: "1.0.0"
        }
      },
      id: Map.get(request, "id")
    }
  end
  
  defp handle_mcp_request(%{"method" => "tools/list"} = request, server_pid) do
    tools = get_server_tools(server_pid)
    
    %{
      jsonrpc: "2.0",
      result: %{tools: tools},
      id: Map.get(request, "id")
    }
  end
  
  defp handle_mcp_request(%{"method" => "tools/call", "params" => params} = request, server_pid) do
    tool_name = Map.get(params, "name")
    tool_arguments = Map.get(params, "arguments", %{})
    
    result = case tool_name do
      "schedule_activities" ->
        execute_tool(server_pid, tool_name, tool_arguments)
      _ ->
        %{error: "Unknown tool: #{tool_name}"}
    end
    
    %{
      jsonrpc: "2.0",
      result: %{content: [%{type: "text", text: Jason.encode!(result)}]},
      id: Map.get(request, "id")
    }
  end
  
  defp handle_mcp_request(%{"method" => "notifications/initialized"}, _server_pid) do
    # Client has finished initialization
    Logger.info("MCP client initialized")
    # No response needed for notifications
    nil
  end
  
  defp handle_mcp_request(request, _server_pid) do
    Logger.warning("Unknown MCP method: #{inspect(request)}")
    
    %{
      jsonrpc: "2.0",
      error: %{code: -32601, message: "Method not found"},
      id: Map.get(request, "id")
    }
  end
  
  defp get_server_capabilities(server_pid) do
    GenServer.call(server_pid, :get_capabilities)
  end
  
  defp get_server_tools(server_pid) do
    GenServer.call(server_pid, :get_tools)
  end
  
  defp execute_tool(server_pid, "schedule_activities", arguments) do
    # Execute the tool through the MCP server
    case GenServer.call(server_pid, {:execute_tool, "schedule_activities", arguments}) do
      {:ok, result} -> result
      {:error, reason} -> %{error: reason}
    end
  rescue
    e ->
      Logger.error("Tool execution failed: #{Exception.message(e)}")
      %{error: "Tool execution failed: #{Exception.message(e)}"}
  end
end
