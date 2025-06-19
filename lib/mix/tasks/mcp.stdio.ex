# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Mcp.Stdio do
  @moduledoc """
  Start AriaEngine MCP server using Hermes framework with STDIO transport.
  
  This task starts the MCP server that exposes AriaEngine's scheduling and
  planning capabilities through the Model Context Protocol using STDIO transport.
  """

  use Mix.Task
  require Logger

  @shortdoc "Start AriaEngine MCP server in STDIO mode using Hermes"

  @impl Mix.Task
  def run(_args) do
    # Ensure all required applications are started
    {:ok, _} = Application.ensure_all_started(:logger)
    {:ok, _} = Application.ensure_all_started(:jason)
    {:ok, _} = Application.ensure_all_started(:hermes_mcp)
    {:ok, _} = Application.ensure_all_started(:aria_character_core)

    # Configure logger to write to stderr to avoid interfering with MCP protocol
    Logger.configure(level: :info)
    
    # Write startup message to stderr
    IO.puts(:stderr, "Starting AriaEngine MCP server with Hermes framework in STDIO mode...")
    IO.puts(:stderr, "Server ready for MCP client connections")
    IO.puts(:stderr, "PID: #{inspect(self())}")

    # Start the Hermes MCP server with STDIO transport
    server_opts = [
      transport: {:stdio, []}
    ]

    case AriaEngine.MCP.HermesServer.start_link(server_opts) do
      {:ok, server_pid} ->
        IO.puts(:stderr, "Hermes MCP server started successfully with PID: #{inspect(server_pid)}")
        
        # Keep the task running
        Process.monitor(server_pid)
        wait_for_server(server_pid)
        
      {:error, reason} ->
        IO.puts(:stderr, "Failed to start Hermes MCP server: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp wait_for_server(server_pid) do
    receive do
      {:DOWN, _ref, :process, ^server_pid, reason} ->
        IO.puts(:stderr, "MCP server terminated: #{inspect(reason)}")
        :ok
    end
  end
end
