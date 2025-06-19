# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Sse do
  @moduledoc """
  Start Aria Engine MCP server in SSE mode for web client integration.

  This task starts the Model Context Protocol server using Server-Sent Events (SSE)
  transport over HTTP, providing real-time communication capabilities for web clients.

  ## Usage

      mix mcp.sse
      mix mcp.sse --port 4000

  The server will run indefinitely, serving SSE connections on the specified port.
  This provides real-time bidirectional communication that can be accessed by web
  browsers and other HTTP clients that support Server-Sent Events.

  ## Available Endpoints

  - GET /mcp/sse              - SSE endpoint for MCP protocol communication
  - GET /health               - Health check endpoint

  ## Example Usage

      # Start server on default port 4000
      mix mcp.sse

      # Start server on custom port
      mix mcp.sse --port 8080

      # Test SSE connection with curl
      curl -N -H "Accept: text/event-stream" http://localhost:4000/mcp/sse

      # Health check
      curl http://localhost:4000/health

  ## Web Client Integration

  JavaScript example for connecting to the SSE endpoint:

      const eventSource = new EventSource('http://localhost:4000/mcp/sse');
      
      eventSource.onmessage = function(event) {
        const data = JSON.parse(event.data);
        console.log('MCP message:', data);
      };

  Note: This server provides MCP infrastructure without any tools registered,
  serving as a foundation for future tool additions.
  """

  use Mix.Task

  require Logger

  @shortdoc "Start MCP server in SSE mode for web clients"

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

    # Start Hermes MCP application
    {:ok, _} = Application.ensure_all_started(:hermes_mcp)

    # Start the Hermes registry
    {:ok, _registry_pid} = Registry.start_link(keys: :unique, name: Hermes.Server.Registry)

    Logger.info("Starting Aria Engine MCP server in SSE mode...")
    Logger.info("Server will be available at http://localhost:#{port}")
    Logger.info("Available endpoints:")
    Logger.info("  GET  /mcp/sse              - SSE endpoint for MCP protocol")
    Logger.info("  GET  /health               - Health check")
    Logger.info("Note: No tools currently registered - this is a foundation server")

    # Start the Hermes MCP server with SSE transport
    case Hermes.Server.start_link(
      AriaEngine.MCP.HermesServer,
      :ok,
      transport: {:sse, port: port, start: true}
    ) do
      {:ok, _pid} ->
        Logger.info("MCP SSE Server started successfully")
        # Keep the process alive
        Process.sleep(:infinity)

      {:error, reason} ->
        Logger.error("Failed to start MCP SSE Server: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
