# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.HermesServer do
  @moduledoc """
  Aria Engine MCP Server using Hermes MCP framework.
  
  Provides temporal scheduling and planning capabilities through the Model Context Protocol
  using the Hermes MCP framework for proper protocol compliance and SSE transport support.
  """
  
  use Hermes.Server,
    name: "Aria Engine Temporal Scheduler",
    version: "1.0.0",
    capabilities: [:tools]
  
  require Logger
  
  # Register the schedule activities tool component
  component AriaEngine.MCP.Tools.ScheduleActivities
  
  @doc """
  Start the Hermes MCP server.
  """
  def start_link(opts \\ []) do
    Hermes.Server.start_link(__MODULE__, :ok, opts)
  end
  
  @impl true
  def init(:ok, frame) do
    Logger.info("Aria Engine Hermes MCP Server started")
    {:ok, frame}
  end
  
  @impl true
  def handle_notification(_notification, frame) do
    # Handle MCP notifications - for now just acknowledge
    {:noreply, frame}
  end
end
