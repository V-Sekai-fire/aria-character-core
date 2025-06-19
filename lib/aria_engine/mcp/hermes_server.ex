# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.HermesServer do
  @moduledoc """
  Aria Engine MCP Server using Hermes MCP framework.

  Provides temporal scheduling and planning capabilities through the Model Context Protocol
  using Hermes MCP framework for proper protocol compliance with stdio and SSE transport support.

  This server provides the MCP infrastructure without any tools registered, serving as a
  foundation for future tool additions.

  ## Supported Transports

  - **stdio**: For VSCode MCP client integration
  - **sse**: For web clients and real-time communication

  ## Usage

      # Start with stdio transport (for VSCode)
      mix mcp.stdio

      # Start with SSE transport (for web clients)  
      mix mcp.sse
  """

  use Hermes.Server,
    name: "Aria Engine Temporal Scheduler",
    version: "1.0.0",
    capabilities: [:tools]

  require Logger

  # No tools registered - this is a tool-free MCP server foundation

  @impl true
  def init(:ok, frame) do
    Logger.info("Aria Engine MCP Server started (no tools registered)")
    Logger.info("Server ready for MCP client connections")
    {:ok, frame}
  end

  @impl true
  def handle_notification(_notification, frame) do
    # Handle MCP notifications - for now just acknowledge
    {:noreply, frame}
  end

  @impl true
  def handle_request("tools/list", _params) do
    # Return empty tools list since no tools are registered
    {:ok, %{tools: []}}
  end

  @impl true
  def handle_request("tools/call", _params) do
    # No tools available to call
    {:error, %{
      code: -32601,
      message: "No tools registered",
      data: %{available_tools: []}
    }}
  end

  @impl true
  def handle_request(_method, _params) do
    # Handle unknown methods
    {:error, %{
      code: -32601,
      message: "Method not found"
    }}
  end
end
