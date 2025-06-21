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

  # Register Hermes tool components
  component AriaEngine.MCP.Tools.ScheduleActivities
  component AriaEngine.MCP.Tools.ValidateSchedulingSolutions
  component AriaEngine.MCP.Tools.ConfigurePipelineLayout
  component AriaEngine.MCP.Tools.SetupElementConfig
  component AriaEngine.MCP.Tools.StartPlanningPipeline
  component AriaEngine.MCP.Tools.StopPlanningPipeline
  component AriaEngine.MCP.Tools.GetPipelineStatus
  component AriaEngine.MCP.Tools.GetPipelineMetrics
  component AriaEngine.MCP.Tools.ListActivePipelines
  component AriaEngine.MCP.Tools.SendPipelineRequest

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
  def handle_request(request, state) do
    Logger.warning("Unknown method: #{request["method"]}")
    {:error, Hermes.MCP.Error.protocol(:method_not_found, %{method: request["method"]}), state}
  end

  @impl true
  def handle_notification(notification, state) do
    Logger.debug("Received notification: #{inspect(notification)}")
    {:noreply, state}
  end
end
