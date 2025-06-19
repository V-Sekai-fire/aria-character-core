# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.HermesServer do
  @moduledoc """
  Aria Engine MCP Server using Hermes MCP framework.

  Provides temporal scheduling and planning capabilities through the Model Context Protocol
  using Hermes MCP framework for proper protocol compliance with stdio and SSE transport support.

  This server provides the `schedule_activities` tool that exposes AriaEngine's comprehensive
  scheduling capabilities to external MCP clients.

  ## Supported Tools

  - **schedule_activities**: Schedule activities using hybrid temporal planner with entity/resource management

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

  @impl true
  def init(:ok, frame) do
    Logger.info("Aria Engine MCP Server started with schedule_activities tool")
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
    # Return the list of available tools
    tools = [AriaEngine.MCP.SchedulerTool.get_tool_definition()]
    {:ok, %{tools: tools}}
  end

  @impl true
  def handle_request("tools/call", %{"name" => "schedule_activities", "arguments" => params}) do
    Logger.info("MCP Server: Handling schedule_activities tool call")
    
    try do
      result = AriaEngine.MCP.SchedulerTool.handle_tool_call(params)
      {:ok, %{content: [%{type: "text", text: Jason.encode!(result)}]}}
    rescue
      e ->
        error_msg = "Tool call failed: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, %{
          code: -32603,
          message: "Internal error",
          data: %{error: error_msg}
        }}
    end
  end

  @impl true
  def handle_request("tools/call", %{"name" => tool_name}) do
    Logger.warning("MCP Server: Unknown tool call: #{tool_name}")
    {:error, %{
      code: -32601,
      message: "Tool not found",
      data: %{tool_name: tool_name, available_tools: ["schedule_activities"]}
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
