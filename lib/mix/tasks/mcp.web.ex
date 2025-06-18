# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Web do
  @moduledoc """
  Start Aria Engine MCP server in web mode for HTTP API access.
  
  This task starts the Model Context Protocol server using HTTP transport,
  providing a REST API interface for temporal scheduling and planning.
  
  ## Usage
  
      mix mcp.web
      mix mcp.web --port 4000
  
  The server will run indefinitely, serving HTTP requests on the specified port.
  This provides a REST API interface that can be accessed by any HTTP client.
  
  ## Available Endpoints
  
  - GET /                     - Server information and available endpoints
  - GET /capabilities         - MCP server capabilities
  - GET /tools               - List available tools and their schemas
  - POST /tools/schedule_activities - Execute scheduling tool directly
  - POST /tools/call         - Generic tool execution endpoint
  - GET /health              - Health check endpoint
  
  ## Example Usage
  
      # Start server on default port 4000
      mix mcp.web
      
      # Start server on custom port
      mix mcp.web --port 8080
      
      # Test with curl
      curl http://localhost:4000/tools
      
      # Execute scheduling tool
      curl -X POST http://localhost:4000/tools/schedule_activities \\
        -H "Content-Type: application/json" \\
        -d '{"schedule_name": "test", "activities": []}'
  """
  
  use Mix.Task
  
  require Logger
  
  @shortdoc "Start MCP server in web mode for HTTP API access"
  
  @impl Mix.Task
  def run(args) do
    # Parse command line arguments
    {opts, _args, _invalid} = OptionParser.parse(args, 
      switches: [port: :integer],
      aliases: [p: :port]
    )
    
    port = Keyword.get(opts, :port, 4000)
    
    # Ensure the application is started
    Mix.Task.run("app.start")
    
    Logger.info("Starting Aria Engine MCP server in web mode...")
    Logger.info("Server will be available at http://localhost:#{port}")
    Logger.info("Available endpoints:")
    Logger.info("  GET  /                     - Server information")
    Logger.info("  GET  /capabilities         - MCP capabilities")
    Logger.info("  GET  /tools               - Available tools")
    Logger.info("  POST /tools/schedule_activities - Execute scheduling")
    Logger.info("  POST /tools/call          - Generic tool execution")
    Logger.info("  GET  /health              - Health check")
    
    # Start the web transport
    case AriaEngine.MCP.WebTransport.start_link(port: port) do
      {:ok, _pid} ->
        Logger.info("MCP Web Transport started successfully")
        # Keep the process alive
        Process.sleep(:infinity)
        
      {:error, reason} ->
        Logger.error("Failed to start MCP Web Transport: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
