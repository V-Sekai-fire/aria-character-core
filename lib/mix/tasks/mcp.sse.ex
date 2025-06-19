# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Sse do
  @moduledoc """
  HTTP Server-Sent Events MCP server implementation.
  
  This provides MCP functionality over HTTP with Server-Sent Events for real-time
  communication. Supports CORS for web client access.
  """

  use Mix.Task
  require Logger

  @shortdoc "Start MCP server in HTTP SSE mode"

  @impl Mix.Task
  def run(args) do
    # Parse command line arguments
    {opts, _, _} = OptionParser.parse(args,
      switches: [port: :integer, host: :string],
      aliases: [p: :port, h: :host]
    )

    port = Keyword.get(opts, :port, 3001)
    host = Keyword.get(opts, :host, "localhost")

    # Ensure all required applications are started
    {:ok, _} = Application.ensure_all_started(:logger)
    {:ok, _} = Application.ensure_all_started(:jason)
    {:ok, _} = Application.ensure_all_started(:plug_cowboy)
    {:ok, _} = Application.ensure_all_started(:cors_plug)
    {:ok, _} = Application.ensure_all_started(:aria_character_core)

    Logger.info("Starting Aria Engine MCP server in HTTP SSE mode...")
    Logger.info("Server will be available at http://#{host}:#{port}")
    Logger.info("PID: #{inspect(self())}")

    # Start the HTTP server
    {:ok, _} = Plug.Cowboy.http(AriaEngine.MCP.SSEServer, [], 
      port: port, 
      ip: parse_host(host)
    )

    Logger.info("MCP SSE server started successfully on http://#{host}:#{port}")
    Logger.info("Available endpoints:")
    Logger.info("  GET  /sse     - Server-Sent Events endpoint")
    Logger.info("  POST /tools   - Tool execution endpoint")
    Logger.info("  GET  /health  - Health check endpoint")

    # Keep the server running
    Process.sleep(:infinity)
  end

  defp parse_host("localhost"), do: {127, 0, 0, 1}
  defp parse_host("0.0.0.0"), do: {0, 0, 0, 0}
  defp parse_host(host) when is_binary(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, ip} -> ip
      {:error, _} -> {127, 0, 0, 1}
    end
  end
end

defmodule AriaEngine.MCP.SSEServer do
  @moduledoc """
  HTTP Server-Sent Events MCP server using Plug.
  
  Provides MCP functionality over HTTP with SSE for real-time updates.
  """

  use Plug.Router
  require Logger

  plug CORSPlug, origin: "*"
  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  # Health check endpoint
  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{
      status: "healthy",
      server: "aria-scheduler-mcp",
      version: "1.0.0",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }))
  end

  # Server-Sent Events endpoint for MCP protocol
  get "/sse" do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_chunked(200)
    |> handle_sse_connection()
  end

  # Tool execution endpoint
  post "/tools" do
    case conn.body_params do
      %{"method" => "tools/call", "params" => %{"name" => "schedule_activities", "arguments" => args}} ->
        handle_tool_call(conn, args)
      
      %{"method" => "tools/list"} ->
        handle_tools_list(conn)
      
      %{"method" => "initialize"} ->
        handle_initialize(conn)
      
      _ ->
        send_error_response(conn, 400, "Invalid request format")
    end
  end

  # Handle preflight CORS requests
  options _ do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(200, "")
  end

  # Catch-all for unmatched routes
  match _ do
    send_resp(conn, 404, Jason.encode!(%{
      error: "Not found",
      message: "Available endpoints: GET /sse, POST /tools, GET /health"
    }))
  end

  # Private functions

  defp handle_sse_connection(conn) do
    Logger.info("SSE connection established")
    
    # Send initial connection message
    send_sse_event(conn, "connected", %{
      message: "MCP SSE connection established",
      server: "aria-scheduler-mcp",
      capabilities: %{
        tools: %{
          schedule_activities: true
        }
      }
    })

    # Keep connection alive and handle any incoming data
    maintain_sse_connection(conn)
  end

  defp maintain_sse_connection(conn) do
    # Send periodic heartbeat
    :timer.sleep(30_000)
    case send_sse_event(conn, "heartbeat", %{timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}) do
      {:ok, conn} -> maintain_sse_connection(conn)
      {:error, _} -> 
        Logger.info("SSE connection closed")
        conn
    end
  end

  defp send_sse_event(conn, event_type, data) do
    event_data = "event: #{event_type}\ndata: #{Jason.encode!(data)}\n\n"
    case chunk(conn, event_data) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> 
        Logger.warning("Failed to send SSE event: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_tool_call(conn, args) do
    Logger.info("Received schedule_activities tool call via HTTP")
    
    try do
      result = AriaEngine.MCP.SchedulerTool.handle_tool_call(args)
      
      response = %{
        jsonrpc: "2.0",
        id: Map.get(conn.body_params, "id", nil),
        result: %{
          content: [
            %{
              type: "text",
              text: Jason.encode!(result)
            }
          ]
        }
      }
      
      send_json_response(conn, 200, response)
    rescue
      e ->
        Logger.error("Tool call failed: #{Exception.message(e)}")
        send_error_response(conn, 500, "Tool execution failed: #{Exception.message(e)}")
    end
  end

  defp handle_tools_list(conn) do
    Logger.info("Received tools/list request via HTTP")
    
    tools = [
      AriaEngine.MCP.SchedulerTool.get_tool_definition()
    ]

    response = %{
      jsonrpc: "2.0",
      id: Map.get(conn.body_params, "id", nil),
      result: %{
        tools: tools
      }
    }

    send_json_response(conn, 200, response)
  end

  defp handle_initialize(conn) do
    Logger.info("Received initialize request via HTTP")
    
    response = %{
      jsonrpc: "2.0",
      id: Map.get(conn.body_params, "id", nil),
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

    send_json_response(conn, 200, response)
  end

  defp send_json_response(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp send_error_response(conn, status, message) do
    error_response = %{
      jsonrpc: "2.0",
      id: Map.get(conn.body_params, "id", nil),
      error: %{
        code: status,
        message: message
      }
    }
    
    send_json_response(conn, status, error_response)
  end
end
