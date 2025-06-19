# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Stdio do
  @moduledoc """
  Start Aria Engine MCP server in stdio mode for VSCode integration.
  
  This task starts the Model Context Protocol server using stdin/stdout
  communication, which is required for VSCode MCP client integration.
  
  ## Usage
  
      mix mcp.stdio
  
  The server will run indefinitely, processing MCP requests from stdin
  and sending responses to stdout. This is typically used by VSCode
  or other MCP clients that communicate via stdio transport.
  
  ## VSCode Configuration
  
  Add this to your VSCode settings.json:
  
      {
        "mcp.servers": {
          "aria-scheduler": {
            "command": "mix",
            "args": ["mcp.stdio"],
            "cwd": "/path/to/aria-character-core"
          }
        }
      }
  """
  
  use Mix.Task
  
  require Logger
  
  @shortdoc "Start MCP server in stdio mode for VSCode"
  
  @impl Mix.Task
  def run(_args) do
    # Ensure the application is started
    Mix.Task.run("app.start")
    
    # Start Hermes MCP application
    {:ok, _} = Application.ensure_all_started(:hermes_mcp)
    
    # Start the Hermes registry
    {:ok, _registry_pid} = Registry.start_link(keys: :unique, name: Hermes.Server.Registry)
    
    Logger.info("Starting Aria Engine MCP server in stdio mode...")
    Logger.info("Server ready for VSCode MCP client connection")
    
    # Start the Hermes MCP server with stdio transport
    {:ok, _pid} = Hermes.Server.start_link(
      AriaEngine.MCP.HermesServer,
      :ok,
      transport: :stdio
    )
    
    # Keep the process alive
    Process.sleep(:infinity)
  end
end
