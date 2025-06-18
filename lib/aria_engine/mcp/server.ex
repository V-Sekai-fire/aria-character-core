# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCP.Server do
  @moduledoc """
  Aria Engine MCP Server using Hermes framework.
  
  Provides temporal scheduling and planning capabilities through the Model Context Protocol.
  Integrates with the hybrid temporal planner to provide sophisticated scheduling solutions.
  """
  
  use Hermes.Server,
    name: "Aria Engine Temporal Scheduler",
    version: "1.0.0",
    capabilities: [:tools]
  
  # Register our scheduling tool
  component AriaEngine.MCP.Tools.ScheduleActivities
  
  @impl Hermes.Server.Behaviour
  def init(_arg, frame) do
    {:ok, frame}
  end
  
  @impl Hermes.Server.Behaviour
  def handle_notification(_notification, frame) do
    {:noreply, frame}
  end
end
