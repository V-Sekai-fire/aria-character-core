# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.HermesSse do
  @moduledoc """
  Start Aria Engine MCP server using Hermes MCP framework with SSE transport.
  
  This task starts the Hermes-based MCP server with Server-Sent Events (SSE) transport
  for proper integration with Cline and other MCP clients that expect SSE endpoints.
  
  ## Usage
  
      mix mcp.hermes_sse [--port PORT] [--host HOST]
  
  ## Options
  
    * `--port` - Port to bind the SSE server (default: 8000)
    * `--host` - Host to bind the server (default: "localhost")
  
  ## Examples
  
      # Start with default settings (localhost:8000)
      mix mcp.hermes_sse
      
      # Start on custom port
      mix mcp.hermes_sse --port 8080
      
      # Start on all interfaces
      mix mcp.hermes_sse --host 0.0.0.0 --port 8000
  
  The server will be available at http://HOST:PORT/sse for SSE connections.
  """
  
  use Mix.Task
  require Logger
  
  @shortdoc "Start Aria Engine MCP server with Hermes SSE transport"
  
  @impl Mix.Task
  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args,
      strict: [port: :integer, host: :string],
      aliases: [p: :port, h: :host]
    )
    
    port = Keyword.get(opts, :port, 8000)
    host = Keyword.get(opts, :host, "localhost")
    
    Logger.info("Starting Aria Engine MCP Server with Hermes SSE transport")
    Logger.info("Server will be available at http://#{host}:#{port}")
    
    # Start the application if not already started
    {:ok, _} = Application.ensure_all_started(:aria_character_core)
    
    # Add Hermes Server Registry to supervision tree if not already started
    children = [
      Hermes.Server.Registry,
      {AriaEngine.MCP.HermesServer, transport: {:sse, port: port, host: host, path: "/"}}
    ]
    
    opts = [strategy: :one_for_one, name: AriaEngine.MCP.HermesSupervisor]
    
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Hermes MCP Server started successfully")
        Logger.info("SSE endpoint: http://#{host}:#{port}")
        Logger.info("Press Ctrl+C to stop the server")
        
        # Keep the task running
        Process.monitor(pid)
        receive do
          {:DOWN, _ref, :process, ^pid, reason} ->
            Logger.error("Hermes MCP Server stopped: #{inspect(reason)}")
            System.halt(1)
        end
        
      {:error, {:already_started, _pid}} ->
        Logger.info("Hermes MCP Server already running")
        Logger.info("SSE endpoint: http://#{host}:#{port}/sse")
        
        # Keep the task running
        Process.sleep(:infinity)
        
      {:error, reason} ->
        Logger.error("Failed to start Hermes MCP Server: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
