# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.WebTransport do
  @moduledoc """
  Web transport for MCP server communication via HTTP.
  
  Provides a REST API interface for the Model Context Protocol server,
  allowing external clients to interact with Aria Engine's temporal
  scheduling capabilities over HTTP.
  """
  
  use Plug.Router
  require Logger
  
  alias AriaEngine.MCP.Server
  
  plug Plug.Logger
  plug CORSPlug
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :assign_server_pid
  plug :dispatch
  
  ## Public API
  
  @doc """
  Start the web transport server.
  """
  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 4000)
    
    # Start the MCP server
    {:ok, server_pid} = Server.start_link([])
    
    # Store server_pid in Application environment for global access
    Application.put_env(:aria_character_core, :mcp_server_pid, server_pid)
    
    Logger.info("Starting Aria Engine MCP Web Transport on port #{port}")
    
    # Start Cowboy and return the result
    case Plug.Cowboy.http(__MODULE__, [], port: port) do
      {:ok, cowboy_pid} ->
        Logger.info("Cowboy HTTP server started on port #{port}")
        {:ok, cowboy_pid}
      {:error, reason} ->
        Logger.error("Failed to start Cowboy HTTP server: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  ## Routes
  
  # SSE endpoint for MCP protocol communication (must be early to avoid catch-all)
  get "/mcp/sse" do
    server_pid = conn.assigns.server_pid
    
    conn
    |> put_resp_content_type("text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("access-control-allow-origin", "*")
    |> send_chunked(200)
    |> handle_sse_connection(server_pid)
  end
  
  get "/" do
    response = %{
      name: "Aria Engine MCP Server",
      version: "1.0.0",
      description: "Temporal scheduling and planning via Model Context Protocol",
      endpoints: %{
        capabilities: "GET /capabilities",
        tools: "GET /tools",
        schedule_activities: "POST /tools/schedule_activities",
        tool_call: "POST /tools/call"
      },
      documentation: "See /tools for available tools and their schemas"
    }
    
    send_json_response(conn, 200, response)
  end
  
  get "/capabilities" do
    server_pid = conn.assigns.server_pid
    capabilities = GenServer.call(server_pid, :get_capabilities)
    
    response = %{
      protocolVersion: "2024-11-05",
      capabilities: capabilities,
      serverInfo: %{
        name: "Aria Engine Temporal Scheduler",
        version: "1.0.0"
      }
    }
    
    send_json_response(conn, 200, response)
  end
  
  get "/tools" do
    server_pid = conn.assigns.server_pid
    tools = GenServer.call(server_pid, :get_tools)
    
    response = %{tools: tools}
    send_json_response(conn, 200, response)
  end
  
  post "/tools/schedule_activities" do
    server_pid = conn.assigns.server_pid
    
    case execute_tool(server_pid, "schedule_activities", conn.body_params) do
      {:ok, result} ->
        send_json_response(conn, 200, result)
      {:error, reason} ->
        send_json_response(conn, 400, %{error: reason})
    end
  end
  
  post "/tools/call" do
    server_pid = conn.assigns.server_pid
    
    tool_name = Map.get(conn.body_params, "name")
    tool_arguments = Map.get(conn.body_params, "arguments", %{})
    
    case tool_name do
      nil ->
        send_json_response(conn, 400, %{error: "Missing 'name' parameter"})
      
      name ->
        case execute_tool(server_pid, name, tool_arguments) do
          {:ok, result} ->
            send_json_response(conn, 200, result)
          {:error, reason} ->
            send_json_response(conn, 400, %{error: reason})
        end
    end
  end
  
  # Health check endpoint
  get "/health" do
    send_json_response(conn, 200, %{status: "healthy", timestamp: DateTime.utc_now()})
  end
  
  # Catch-all for unmatched routes
  match _ do
    send_json_response(conn, 404, %{error: "Not found"})
  end
  
  ## Private Functions
  
  defp assign_server_pid(conn, _opts) do
    server_pid = Application.get_env(:aria_character_core, :mcp_server_pid)
    assign(conn, :server_pid, server_pid)
  end
  
  defp execute_tool(server_pid, tool_name, arguments) do
    case GenServer.call(server_pid, {:execute_tool, tool_name, arguments}) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  rescue
    e ->
      Logger.error("Tool execution failed: #{Exception.message(e)}")
      {:error, "Tool execution failed: #{Exception.message(e)}"}
  end
  
  defp send_json_response(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
  
  defp handle_sse_connection(conn, server_pid) do
    # Send initial capabilities as SSE event
    capabilities = GenServer.call(server_pid, :get_capabilities)
    
    init_message = %{
      jsonrpc: "2.0",
      method: "initialize",
      params: %{
        protocolVersion: "2024-11-05",
        capabilities: capabilities,
        serverInfo: %{
          name: "Aria Engine Temporal Scheduler",
          version: "1.0.0"
        }
      }
    }
    
    # Send initialization message
    send_sse_event(conn, "message", init_message)
    
    # Keep connection alive and handle incoming messages
    keep_alive_loop(conn, server_pid)
  end
  
  defp send_sse_event(conn, event_type, data) do
    event_data = Jason.encode!(data)
    sse_message = "event: #{event_type}\ndata: #{event_data}\n\n"
    
    case chunk(conn, sse_message) do
      {:ok, conn} -> conn
      {:error, _reason} -> conn
    end
  end
  
  defp keep_alive_loop(conn, server_pid) do
    # Send periodic heartbeat to keep connection alive
    receive do
      :stop -> conn
    after
      30_000 ->
        # Send heartbeat every 30 seconds
        heartbeat = %{
          jsonrpc: "2.0",
          method: "ping",
          params: %{timestamp: DateTime.utc_now()}
        }
        
        conn = send_sse_event(conn, "ping", heartbeat)
        keep_alive_loop(conn, server_pid)
    end
  end
end
