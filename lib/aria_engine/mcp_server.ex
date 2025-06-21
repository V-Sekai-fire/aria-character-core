# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPServer do
  @moduledoc """
  Standalone MCP server for AriaEngine that can be run independently.
  
  This module provides a simple way to start the MCP server without
  requiring the full application supervision tree.
  """

  require Logger

  def start() do
    Logger.info("Starting AriaEngine MCP Server...")
    
    # Start the Hermes MCP application if not already started
    case Application.ensure_all_started(:hermes_mcp) do
      {:ok, _} -> 
        Logger.info("Hermes MCP application started successfully")
      {:error, reason} -> 
        Logger.error("Failed to start Hermes MCP application: #{inspect(reason)}")
        System.halt(1)
    end

    # Start our MCP server
    case AriaEngine.MCP.HermesServer.start_link([]) do
      {:ok, pid} ->
        Logger.info("AriaEngine MCP Server started with PID: #{inspect(pid)}")
        
        # Keep the process alive
        Process.monitor(pid)
        wait_for_shutdown()
        
      {:error, reason} ->
        Logger.error("Failed to start AriaEngine MCP Server: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp wait_for_shutdown() do
    receive do
      {:DOWN, _ref, :process, _pid, reason} ->
        Logger.info("MCP Server stopped: #{inspect(reason)}")
        System.halt(0)
      
      _ ->
        wait_for_shutdown()
    end
  end
end
