# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.HermesServer do
  @moduledoc """
  Hermes MCP server implementation for AriaEngine.
  
  This module provides a MCP server using the Hermes framework that exposes
  AriaEngine's scheduling and planning capabilities through MCP tools.
  """

  use Hermes.Server,
    name: "aria-engine",
    version: "1.0.0",
    capabilities: [:tools]

  alias Hermes.MCP.Error
  require Logger

  def start_link(opts \\ []) do
    Hermes.Server.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok, frame) do
    Logger.info("AriaEngine Hermes MCP server initialized")
    {:ok, frame}
  end

  @impl true
  def handle_request(%{"method" => "tools/list"} = _request, state) do
    Logger.info("Listing available MCP tools")
    
    tools = AriaEngine.MCPTools.get_all_tools()
    
    response = %{"tools" => tools}
    {:reply, response, state}
  end

  @impl true
  def handle_request(
    %{"method" => "tools/call", "params" => %{"name" => tool_name, "arguments" => arguments}} = _request,
    state
  ) do
    Logger.info("Calling tool: #{tool_name} with args: #{inspect(arguments)}")
    
    try do
      result = AriaEngine.MCPTools.handle_tool_call(tool_name, arguments)
      
      # Format the result as MCP content
      response = %{
        "content" => [
          %{
            "type" => "text",
            "text" => Jason.encode!(result, pretty: true)
          }
        ],
        "isError" => false
      }
      
      {:reply, response, state}
    rescue
      e ->
        Logger.error("Tool call failed: #{Exception.message(e)}")
        
        {:error, Error.execution("Tool execution failed: #{Exception.message(e)}"), state}
    end
  end

  @impl true
  def handle_request(request, state) do
    Logger.warning("Unknown method: #{request["method"]}")
    {:error, Error.protocol(:method_not_found, %{method: request["method"]}), state}
  end

  @impl true
  def handle_notification(notification, state) do
    Logger.debug("Received notification: #{inspect(notification)}")
    {:noreply, state}
  end
end
