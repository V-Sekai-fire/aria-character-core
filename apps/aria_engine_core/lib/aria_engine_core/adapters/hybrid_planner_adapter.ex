# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Adapters.HybridPlannerAdapter do
  @moduledoc """
  Adapter implementation for AriaHybridPlanner.Core.

  This adapter implements the PlannerBehaviour by wrapping calls to the
  AriaHybridPlanner.Core module. It provides a clean interface for dependency
  injection while maintaining compatibility with the existing hybrid planner.

  ## Usage

  This adapter is the default implementation used in production:

      # Direct usage (not recommended)
      coordinator = HybridPlannerAdapter.new_coordinator()
      {:ok, plan} = HybridPlannerAdapter.plan(coordinator, domain, state, goals)

      # Preferred usage through dependency injection
      # Configure in config/prod.exs:
      # config :aria_engine_core, planner_adapter: AriaEngineCore.Adapters.HybridPlannerAdapter

  ## Error Handling

  This adapter translates any exceptions from AriaHybridPlanner.Core into
  standardized `{:error, reason}` tuples for consistent error handling.
  """

  @behaviour AriaEngineCore.Behaviours.PlannerBehaviour

  require Logger
  alias AriaHybridPlanner.Core, as: HybridCore

  @impl AriaEngineCore.Behaviours.PlannerBehaviour
  def new_coordinator do
    Logger.debug("Creating new hybrid planner coordinator")

    try do
      HybridCore.new_coordinator()
    rescue
      error ->
        Logger.error("Failed to create hybrid coordinator: #{inspect(error)}")
        reraise error, __STACKTRACE__
    end
  end

  @impl AriaEngineCore.Behaviours.PlannerBehaviour
  def plan(coordinator, domain, state, goals) do
    Logger.debug("Starting hybrid planning for #{length(goals)} goals")

    try do
      case HybridCore.plan(coordinator, domain, state, goals) do
        {:ok, plan} ->
          Logger.debug("Hybrid planning completed successfully")
          {:ok, plan}
        {:error, reason} ->
          Logger.warn("Hybrid planning failed: #{inspect(reason)}")
          {:error, reason}
        other ->
          Logger.error("Unexpected hybrid planning result: #{inspect(other)}")
          {:error, :unexpected_planning_result}
      end
    rescue
      error ->
        Logger.error("Hybrid planning error: #{inspect(error)}")
        {:error, :planning_exception}
    end
  end

  @impl AriaEngineCore.Behaviours.PlannerBehaviour
  def execute(coordinator, domain, state, plan) do
    Logger.debug("Starting hybrid plan execution")

    try do
      case HybridCore.execute(coordinator, domain, state, plan) do
        {:ok, final_state} ->
          Logger.debug("Hybrid execution completed successfully")
          {:ok, final_state}
        {:error, reason} ->
          Logger.warn("Hybrid execution failed: #{inspect(reason)}")
          {:error, reason}
        other ->
          Logger.error("Unexpected hybrid execution result: #{inspect(other)}")
          {:error, :unexpected_execution_result}
      end
    rescue
      error ->
        Logger.error("Hybrid execution error: #{inspect(error)}")
        {:error, :execution_exception}
    end
  end
end
